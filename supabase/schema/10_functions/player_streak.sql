-- Stat functions — each had an optional trailing p_game_type param added.
-- create or replace cannot narrow a signature, so these are dropped and
-- recreated at the two-argument shape they had before that param existed.
--
-- player_streak and player_today_delta are created as new (2-arg) overloads
-- alongside their still-live 3-arg originals first, since `leaderboard` has
-- a hard view dependency on the 3-arg versions — the view is repointed at
-- the new overloads right after both exist, and only then are the 3-arg
-- originals dropped, further down.

create or replace function public.player_streak(
  p_season_id  uuid,
  p_player_id  uuid
)
returns table (streak_type text, streak_count integer)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_competition_id uuid;
  v_count          integer := 0;
  v_type           text;
  rec              record;
begin
  select competition_id into v_competition_id
    from public.players where id = p_player_id;
  if v_competition_id is null then
    raise exception 'Player not found' using errcode = 'P0001';
  end if;

  if not public.is_member(v_competition_id) then
    raise exception 'You are not in this competition' using errcode = 'P0001';
  end if;

  for rec in
    select mp.outcome
      from public.match_players mp
      join public.matches m on m.id = mp.match_id
     where mp.player_id = p_player_id
       and m.season_id = p_season_id
     order by m.played_at desc, m.id desc
  loop
    if v_count = 0 then
      if rec.outcome = 'draw' then
        exit;
      end if;
      v_type := rec.outcome::text;
      v_count := 1;
    elsif rec.outcome::text = v_type then
      v_count := v_count + 1;
    else
      exit;
    end if;
  end loop;

  streak_type := coalesce(v_type, 'none');
  streak_count := v_count;
  return next;
end;
$$;

revoke all on function public.player_streak(p_season_id uuid, p_player_id uuid) from public, anon, authenticated;
grant execute on function public.player_streak(p_season_id uuid, p_player_id uuid) to authenticated;
