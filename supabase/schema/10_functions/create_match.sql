-- Guests are refused here, not by RLS: this is security definer, so the
-- is_registered() check at the top is the only thing standing between an
-- anonymous session and a written match. The rating work is handed to
-- recalc_season_from rather than done inline, so a back-dated match replays
-- the season from its own position instead of appending to the end.

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

  return v_match_id;
end;
$$;

revoke all on function public.create_match(p_competition_id uuid, p_team_a uuid[], p_team_b uuid[], p_score_a integer, p_score_b integer, p_played_at timestamp with time zone) from public, anon, authenticated;
grant execute on function public.create_match(p_competition_id uuid, p_team_a uuid[], p_team_b uuid[], p_score_a integer, p_score_b integer, p_played_at timestamp with time zone) to authenticated;
