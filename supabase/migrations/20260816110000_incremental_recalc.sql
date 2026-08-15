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

-- ---------------------------------------------------------------------------
-- recalc_season_from
-- ---------------------------------------------------------------------------

create function public.recalc_season_from(
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

revoke all on function public.recalc_season_from(uuid, timestamptz, uuid)
  from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- recalc_season_game_type_from — same trick, per-type track.
-- ---------------------------------------------------------------------------

create function public.recalc_season_game_type_from(
  p_season_id      uuid,
  p_game_type      public.game_type,
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
  delete from public.player_game_type_ratings
   where season_id = p_season_id and game_type = p_game_type;

  insert into public.player_game_type_ratings
    (season_id, game_type, player_id, rating, played, wins, losses, draws)
  select
    p_season_id,
    p_game_type,
    latest.player_id,
    latest.type_rating_after,
    counts.played,
    counts.wins,
    counts.losses,
    counts.draws
  from (
    select distinct on (mp.player_id)
      mp.player_id,
      mp.type_rating_after
      from public.match_players mp
      join public.matches m on m.id = mp.match_id
     where m.season_id = p_season_id
       and m.game_type = p_game_type
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
       and m.game_type = p_game_type
       and (m.played_at, m.id) < (p_from_played_at, p_from_id)
     group by mp.player_id
  ) counts on counts.player_id = latest.player_id;

  for v_match_id in
    select id from public.matches
     where season_id = p_season_id
       and game_type = p_game_type
       and (played_at, id) >= (p_from_played_at, p_from_id)
     order by played_at, id
  loop
    perform public.apply_match_type_rating(v_match_id);
  end loop;
end;
$$;

revoke all on function
  public.recalc_season_game_type_from(uuid, public.game_type, timestamptz, uuid)
from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- create_match — a single recalc_season_from call, boundary = the new
-- match's own position, replaces the old "apply once, then conditionally
-- recalc everything if back-dated" split: the boundary loop already covers
-- both the common case (nothing after it — loop touches just this one
-- match) and the back-dated case (ripples forward) the same way.
-- ---------------------------------------------------------------------------

create or replace function public.create_match(
  p_competition_id uuid,
  p_team_a         uuid[],
  p_team_b         uuid[],
  p_score_a        integer,
  p_score_b        integer,
  p_played_at      timestamptz default now()
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_comp       public.competitions;
  v_season_id  uuid;
  v_match_id   uuid;
  v_game_type  public.game_type;
  v_all        uuid[];
begin
  if not public.is_registered() then
    raise exception 'Create an account to create matches' using errcode = 'P0001';
  end if;
  if not public.is_member(p_competition_id) then
    raise exception 'You are not in this competition' using errcode = 'P0001';
  end if;

  select * into strict v_comp
    from public.competitions where id = p_competition_id;

  if coalesce(array_length(p_team_a, 1), 0) = 0
     or coalesce(array_length(p_team_b, 1), 0) = 0 then
    raise exception 'Both teams need at least one player' using errcode = 'P0001';
  end if;

  if p_score_a < 0 or p_score_b < 0 then
    raise exception 'Scores cannot be negative' using errcode = 'P0001';
  end if;

  if p_score_a = p_score_b and not v_comp.allow_draws then
    raise exception 'This competition does not allow draws' using errcode = 'P0001';
  end if;

  v_all := p_team_a || p_team_b;

  -- Catches both a duplicate within one team and a player listed on both.
  if (select count(distinct x) from unnest(v_all) x) <> array_length(v_all, 1) then
    raise exception 'A player can only appear once in a match'
      using errcode = 'P0001';
  end if;

  if exists (
    select 1 from unnest(v_all) x
     where not exists (
       select 1 from public.players p
        where p.id = x and p.competition_id = p_competition_id and p.is_active
     )
  ) then
    raise exception 'All players must be active members of this competition'
      using errcode = 'P0001';
  end if;

  v_season_id := public.ensure_season(p_competition_id, p_played_at);

  -- Rating and game_type columns are placeholders; apply_match_ratings fills
  -- them in below.
  insert into public.matches (
    competition_id, season_id, played_at,
    team_a_score, team_b_score, team_a_rating, team_b_rating, game_type, created_by
  )
  values (
    p_competition_id, v_season_id, p_played_at,
    p_score_a, p_score_b, 0, 0, 'mixed', auth.uid()
  )
  returning id into v_match_id;

  insert into public.match_players
    (match_id, player_id, team, rating_before, rating_after, rating_delta, outcome)
  -- The enum needs an explicit cast: in a UNION branch an untyped literal is
  -- resolved as text before it reaches the column.
  select v_match_id, x, 'a'::public.match_team, 0, 0, 0, 'draw'::public.match_outcome
    from unnest(p_team_a) x
  union all
  select v_match_id, x, 'b'::public.match_team, 0, 0, 0, 'draw'::public.match_outcome
    from unnest(p_team_b) x;

  perform public.recalc_season_from(v_season_id, p_played_at, v_match_id);

  select game_type into v_game_type from public.matches where id = v_match_id;
  perform public.recalc_season_game_type_from(
    v_season_id, v_game_type, p_played_at, v_match_id
  );

  return v_match_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- update_match_score — boundary is the earlier of the match's old and new
-- position (same match id either way, so the tuple comparison reduces to
-- comparing played_at). A season change needs both seasons replayed from
-- this match's position in each of them.
-- ---------------------------------------------------------------------------

create or replace function public.update_match_score(
  p_match_id  uuid,
  p_score_a   integer,
  p_score_b   integer,
  p_played_at timestamptz default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_match          public.matches;
  v_comp           public.competitions;
  v_new_season     uuid;
  v_new_played_at  timestamptz;
  v_boundary       timestamptz;
begin
  select * into v_match from public.matches where id = p_match_id;
  if not found then
    raise exception 'Match not found' using errcode = 'P0001';
  end if;

  if not public.is_registered()
     or not (v_match.created_by = auth.uid()
             or public.is_owner(v_match.competition_id)) then
    raise exception 'Only the person who logged this match, or the competition owner, can change it'
      using errcode = 'P0001';
  end if;

  select * into strict v_comp
    from public.competitions where id = v_match.competition_id;

  if p_score_a < 0 or p_score_b < 0 then
    raise exception 'Scores cannot be negative' using errcode = 'P0001';
  end if;
  if p_score_a = p_score_b and not v_comp.allow_draws then
    raise exception 'This competition does not allow draws' using errcode = 'P0001';
  end if;

  v_new_played_at := coalesce(p_played_at, v_match.played_at);

  -- Moving a match in time can move it into a different season entirely.
  v_new_season := case
    when p_played_at is null then v_match.season_id
    else public.ensure_season(v_match.competition_id, p_played_at)
  end;

  update public.matches
     set team_a_score = p_score_a,
         team_b_score = p_score_b,
         played_at    = v_new_played_at,
         season_id    = v_new_season
   where id = p_match_id;

  if v_new_season = v_match.season_id then
    -- Same match id either side, so the tuple boundary comparison reduces to
    -- the earlier of the two timestamps: whichever position moves first is
    -- where anything downstream could start differing.
    v_boundary := least(v_match.played_at, v_new_played_at);
    perform public.recalc_season_from(v_match.season_id, v_boundary, p_match_id);
    -- A score edit never touches the roster, so game_type is unchanged.
    perform public.recalc_season_game_type_from(
      v_match.season_id, v_match.game_type, v_boundary, p_match_id
    );
  else
    perform public.recalc_season_from(
      v_match.season_id, v_match.played_at, p_match_id
    );
    perform public.recalc_season_game_type_from(
      v_match.season_id, v_match.game_type, v_match.played_at, p_match_id
    );
    perform public.recalc_season_from(v_new_season, v_new_played_at, p_match_id);
    perform public.recalc_season_game_type_from(
      v_new_season, v_match.game_type, v_new_played_at, p_match_id
    );
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- delete_match — boundary is the deleted match's own (now-vacated) position.
-- ---------------------------------------------------------------------------

create or replace function public.delete_match(p_match_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_match public.matches;
begin
  select * into v_match from public.matches where id = p_match_id;
  if not found then
    raise exception 'Match not found' using errcode = 'P0001';
  end if;

  if not public.is_registered()
     or not (v_match.created_by = auth.uid()
             or public.is_owner(v_match.competition_id)) then
    raise exception 'Only the person who logged this match, or the competition owner, can remove it'
      using errcode = 'P0001';
  end if;

  delete from public.matches where id = p_match_id;

  perform public.recalc_season_from(
    v_match.season_id, v_match.played_at, v_match.id
  );
  perform public.recalc_season_game_type_from(
    v_match.season_id, v_match.game_type, v_match.played_at, v_match.id
  );
end;
$$;

revoke all on function
  public.create_match(uuid, uuid[], uuid[], integer, integer, timestamptz),
  public.update_match_score(uuid, integer, integer, timestamptz),
  public.delete_match(uuid)
from public, anon, authenticated;

grant execute on function
  public.create_match(uuid, uuid[], uuid[], integer, integer, timestamptz),
  public.update_match_score(uuid, integer, integer, timestamptz),
  public.delete_match(uuid)
to authenticated;
