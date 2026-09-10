-- KeepScore 2 — replay only from the affected point forward, not the whole
-- season.
--
-- recalc_season / recalc_season_game_type always replayed every match in a
-- season, on every edit, delete, or back-dated insert — even a score
-- correction on the newest match of a 200-match season replayed all 200.
-- Editing/deleting never affects anything BEFORE the changed match in play
-- order (played_at, id) — only that match and whatever comes after it can
-- have a different outcome. recalc_season_from / recalc_season_game_type_from
-- exploit that: seed player_ratings / player_game_type_ratings with each
-- player's state as of the last match strictly before the boundary (their
-- rating_after / type_rating_after and cumulative played/wins/losses/draws
-- up to that point — the only historical record available, since
-- player_ratings itself only ever stores the current total), then replay
-- only matches at or after the boundary.
--
-- recalc_season / recalc_season_game_type themselves are untouched — they
-- stay available as a genuine full-rebuild primitive (supabase/seed.sql's
-- incremental-build-equals-replay invariant exercises them directly), but
-- create_match / update_match_score / delete_match now call the *_from
-- versions with the narrowest boundary each write actually needs.

create or replace function public.recalc_season_from(
  p_season_id      uuid,
  p_from_played_at timestamptz,
  p_from_id        uuid
)
returns void
language plpgsql
set search_path = ''
as $$
declare
  v_match_id uuid;
begin
  delete from public.player_ratings where season_id = p_season_id;

  insert into public.player_ratings
    (season_id, player_id, rating, played, wins, losses, draws)
  select
    p_season_id,
    latest.player_id,
    latest.rating_after,
    counts.played,
    counts.wins,
    counts.losses,
    counts.draws
  from (
    select distinct on (mp.player_id)
      mp.player_id,
      mp.rating_after
      from public.match_players mp
      join public.matches m on m.id = mp.match_id
     where m.season_id = p_season_id
       and (m.played_at, m.id) < (p_from_played_at, p_from_id)
     order by mp.player_id, m.played_at desc, m.id desc
  ) latest
  join (
    select
      mp.player_id,
      count(*)::integer                                    as played,
      count(*) filter (where mp.outcome = 'win')::integer   as wins,
      count(*) filter (where mp.outcome = 'loss')::integer  as losses,
      count(*) filter (where mp.outcome = 'draw')::integer  as draws
      from public.match_players mp
      join public.matches m on m.id = mp.match_id
     where m.season_id = p_season_id
       and (m.played_at, m.id) < (p_from_played_at, p_from_id)
     group by mp.player_id
  ) counts on counts.player_id = latest.player_id;

  for v_match_id in
    select id from public.matches
     where season_id = p_season_id
       and (played_at, id) >= (p_from_played_at, p_from_id)
     order by played_at, id
  loop
    perform public.apply_match_ratings(v_match_id);
  end loop;
end;
$$;

revoke all on function public.recalc_season_from(p_season_id uuid, p_from_played_at timestamp with time zone, p_from_id uuid) from public, anon, authenticated;
