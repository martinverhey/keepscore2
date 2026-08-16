-- KeepScore 2 — rating engine and write API.
--
-- Every write the app performs goes through a SECURITY DEFINER function in
-- this file. The tables themselves grant no direct INSERT/UPDATE/DELETE
-- (see 0003_rls.sql), so validation cannot be bypassed by talking to PostgREST
-- directly, and a match plus its participants plus their ratings always land
-- in one transaction.

-- ---------------------------------------------------------------------------
-- Authorisation helpers
-- ---------------------------------------------------------------------------

create function public.is_registered()
returns boolean
language sql
stable
set search_path = ''
as $$
  select auth.uid() is not null
     and coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false;
$$;

comment on function public.is_registered() is
  'True for a signed-in user with a real account. Guests (anonymous sign-in) are excluded: they may join and read, never create.';

-- SECURITY DEFINER so calling it from a policy on players does not recurse
-- back into that same policy.
create function public.is_member(p_competition_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.players
     where competition_id = p_competition_id
       and user_id = auth.uid()
  );
$$;

create function public.is_owner(p_competition_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.competitions
     where id = p_competition_id
       and owner_id = auth.uid()
  );
$$;

-- ---------------------------------------------------------------------------
-- Elo
-- ---------------------------------------------------------------------------

create function public.elo_delta(
  p_rating_a    numeric,
  p_rating_b    numeric,
  p_score_a     integer,
  p_score_b     integer,
  p_k           integer,
  p_mov_enabled boolean,
  p_mov_cap     numeric
)
returns numeric
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_expected_a  numeric;
  v_actual_a    numeric;
  v_margin      integer;
  v_mov         numeric := 1.0;
  v_winner_edge numeric;
begin
  v_expected_a := 1.0 / (1.0 + power(10.0, (p_rating_b - p_rating_a) / 400.0));

  v_actual_a := case
    when p_score_a > p_score_b then 1.0
    when p_score_a < p_score_b then 0.0
    else 0.5
  end;

  v_margin := abs(p_score_a - p_score_b);

  if p_mov_enabled and v_margin > 0 then
    -- How much stronger the winner already was. Without this damper a
    -- dominant player who keeps winning big runs away with the ladder,
    -- because Elo's self-correction is exactly what the multiplier scales up.
    v_winner_edge := greatest(
      0,
      case when v_actual_a = 1.0
           then p_rating_a - p_rating_b
           else p_rating_b - p_rating_a
      end
    );

    -- ln(margin+1)/ln(2): a 1-point win scores 1.0, 3 points 2.0, 7 points 3.0.
    v_mov := (ln(v_margin + 1) / ln(2.0)) * (2.2 / (0.001 * v_winner_edge + 2.2));
    v_mov := least(p_mov_cap, greatest(1.0, v_mov));
  end if;

  return round(p_k * v_mov * (v_actual_a - v_expected_a), 2);
end;
$$;

comment on function public.elo_delta is
  'Rating change for team A. Zero-sum: team B moves by the negation. Mirrored in Dart by EloCalculator, and the two are tested against the same fixtures.';

-- ---------------------------------------------------------------------------
-- Seasons
-- ---------------------------------------------------------------------------

create function public.season_bounds(
  p_at       timestamptz,
  p_length   public.season_length,
  p_timezone text
)
returns table (starts_at timestamptz, ends_at timestamptz)
language plpgsql
stable
set search_path = ''
as $$
declare
  v_local       timestamp;
  v_unit        text;
  v_step        interval;
  v_start_local timestamp;
begin
  -- Seasons are calendar-aligned in the competition's own timezone, so
  -- "this month" means what the members think it means.
  v_local := p_at at time zone p_timezone;

  v_unit := case p_length
    when 'monthly'   then 'month'
    when 'quarterly' then 'quarter'
    when 'yearly'    then 'year'
  end;

  -- date_trunc understands 'quarter'; the interval type does not.
  v_step := case p_length
    when 'monthly'   then interval '1 month'
    when 'quarterly' then interval '3 months'
    when 'yearly'    then interval '1 year'
  end;

  v_start_local := date_trunc(v_unit, v_local);

  starts_at := v_start_local at time zone p_timezone;
  ends_at   := (v_start_local + v_step) at time zone p_timezone;
  return next;
end;
$$;

create function public.ensure_season(p_competition_id uuid, p_at timestamptz)
returns uuid
language plpgsql
set search_path = ''
as $$
declare
  v_comp   public.competitions;
  v_bounds record;
  v_id     uuid;
begin
  select * into v_comp from public.competitions where id = p_competition_id;
  if not found then
    raise exception 'Competition not found' using errcode = 'P0001';
  end if;

  select * into v_bounds
    from public.season_bounds(p_at, v_comp.season_length, v_comp.timezone);

  select id into v_id
    from public.seasons
   where competition_id = p_competition_id
     and starts_at = v_bounds.starts_at;

  if v_id is null then
    insert into public.seasons (competition_id, starts_at, ends_at)
    values (p_competition_id, v_bounds.starts_at, v_bounds.ends_at)
    on conflict (competition_id, starts_at) do update
      set ends_at = excluded.ends_at
    returning id into v_id;
  end if;

  return v_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Rating application
-- ---------------------------------------------------------------------------

-- Applies one match on top of the current leaderboard. The match row and its
-- match_players rows (with team assignments) must already exist; rating
-- columns are overwritten here.
--
-- Shared by create_match and recalc_season, which is what guarantees an
-- incrementally-built season and a replayed one produce identical numbers.
create function public.apply_match_ratings(p_match_id uuid)
returns void
language plpgsql
set search_path = ''
as $$
declare
  v_match     public.matches;
  v_comp      public.competitions;
  v_rating_a  numeric;
  v_rating_b  numeric;
  v_count_a   integer;
  v_count_b   integer;
  v_delta_a   numeric;
  v_outcome_a integer;
begin
  select * into strict v_match from public.matches where id = p_match_id;
  select * into strict v_comp
    from public.competitions where id = v_match.competition_id;

  update public.match_players mp
     set rating_before = coalesce(
           (select pr.rating
              from public.player_ratings pr
             where pr.player_id = mp.player_id
               and pr.season_id = v_match.season_id),
           v_comp.starting_rating
         )
   where mp.match_id = p_match_id;

  select avg(rating_before), count(*) into v_rating_a, v_count_a
    from public.match_players where match_id = p_match_id and team = 'a';
  select avg(rating_before), count(*) into v_rating_b, v_count_b
    from public.match_players where match_id = p_match_id and team = 'b';

  if coalesce(v_count_a, 0) = 0 or coalesce(v_count_b, 0) = 0 then
    raise exception 'Both teams need at least one player' using errcode = 'P0001';
  end if;

  -- Team rating is the mean of its members, and every member takes the same
  -- delta.
  v_delta_a := public.elo_delta(
    v_rating_a, v_rating_b,
    v_match.team_a_score, v_match.team_b_score,
    v_comp.k_factor, v_comp.mov_enabled, v_comp.mov_cap
  );

  v_outcome_a := case
    when v_match.team_a_score > v_match.team_b_score then 1
    when v_match.team_a_score < v_match.team_b_score then -1
    else 0
  end;

  update public.match_players
     set rating_delta = case when team = 'a' then v_delta_a else -v_delta_a end,
         rating_after = rating_before
                        + case when team = 'a' then v_delta_a else -v_delta_a end
   where match_id = p_match_id;

  update public.matches
     set team_a_rating = round(v_rating_a, 2),
         team_b_rating = round(v_rating_b, 2)
   where id = p_match_id;

  insert into public.player_ratings as pr
    (season_id, player_id, rating, played, wins, losses, draws)
  select v_match.season_id,
         mp.player_id,
         mp.rating_after,
         1,
         case when o.res = 1 then 1 else 0 end,
         case when o.res = -1 then 1 else 0 end,
         case when o.res = 0 then 1 else 0 end
    from public.match_players mp
    cross join lateral (
      select case when mp.team = 'a' then v_outcome_a else -v_outcome_a end as res
    ) o
   where mp.match_id = p_match_id
  on conflict (season_id, player_id) do update
     set rating     = excluded.rating,
         played     = pr.played + 1,
         wins       = pr.wins + excluded.wins,
         losses     = pr.losses + excluded.losses,
         draws      = pr.draws + excluded.draws,
         updated_at = now();
end;
$$;

-- Rebuilds a season from its matches. This is the source of truth for
-- correctness after any edit or delete — cheaper to replay a season than to
-- invert an Elo chain.
create function public.recalc_season(p_season_id uuid)
returns void
language plpgsql
set search_path = ''
as $$
declare
  v_match_id uuid;
begin
  delete from public.player_ratings where season_id = p_season_id;

  for v_match_id in
    select id from public.matches
     where season_id = p_season_id
     order by played_at, id
  loop
    perform public.apply_match_ratings(v_match_id);
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- Competition write API
-- ---------------------------------------------------------------------------

create function public.generate_join_code()
returns text
language plpgsql
volatile
set search_path = ''
as $$
declare
  v_alphabet constant text := '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  v_code     text;
  v_i        integer;
begin
  for _attempt in 1..20 loop
    v_code := '';
    for v_i in 1..6 loop
      v_code := v_code
        || substr(v_alphabet, 1 + floor(random() * length(v_alphabet))::integer, 1);
    end loop;
    if not exists (select 1 from public.competitions where join_code = v_code) then
      return v_code;
    end if;
  end loop;
  raise exception 'Could not allocate a unique join code' using errcode = 'P0001';
end;
$$;

create function public.create_competition(
  p_name          text,
  p_season_length public.season_length default 'monthly',
  p_timezone      text default 'Europe/Amsterdam',
  p_display_name  text default null
)
returns public.competitions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_comp public.competitions;
  v_name text;
begin
  if not public.is_registered() then
    raise exception 'Create an account to start a competition'
      using errcode = 'P0001';
  end if;

  insert into public.competitions (join_code, name, owner_id, season_length, timezone)
  values (public.generate_join_code(), btrim(p_name), auth.uid(), p_season_length, p_timezone)
  returning * into v_comp;

  select coalesce(nullif(btrim(p_display_name), ''), p.display_name)
    into v_name
    from public.profiles p where p.id = auth.uid();

  -- The owner is a player in their own competition.
  insert into public.players (competition_id, display_name, user_id)
  values (v_comp.id, coalesce(v_name, 'Player'), auth.uid());

  return v_comp;
end;
$$;

create function public.add_dummy_player(p_competition_id uuid, p_display_name text)
returns public.players
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_player public.players;
begin
  if not public.is_registered() then
    raise exception 'Create an account to add players' using errcode = 'P0001';
  end if;
  if not public.is_owner(p_competition_id) then
    raise exception 'Only the competition owner can add players'
      using errcode = 'P0001';
  end if;

  insert into public.players (competition_id, display_name, user_id)
  values (p_competition_id, btrim(p_display_name), null)
  returning * into v_player;

  return v_player;
end;
$$;

-- Lets the join screen show what you are about to join, and which placeholder
-- players are free to claim, without granting read access to the whole
-- competition first.
create function public.preview_competition(p_join_code text)
returns table (
  competition_id uuid,
  name           text,
  owner_name     text,
  player_count   integer,
  already_member boolean,
  unclaimed      jsonb
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_comp public.competitions;
begin
  if auth.uid() is null then
    raise exception 'Sign in first' using errcode = 'P0001';
  end if;

  select * into v_comp
    from public.competitions
   where join_code = upper(btrim(p_join_code));

  if not found then
    raise exception 'No competition with that code' using errcode = 'P0001';
  end if;

  competition_id := v_comp.id;
  name           := v_comp.name;
  already_member := public.is_member(v_comp.id);

  select p.display_name into owner_name
    from public.profiles p where p.id = v_comp.owner_id;

  -- Every column here must be table-qualified: the OUT parameters share names
  -- with columns on players, and an unqualified reference is ambiguous.
  select count(*)::integer into player_count
    from public.players p
   where p.competition_id = v_comp.id and p.is_active;

  select coalesce(
           jsonb_agg(jsonb_build_object('id', p.id, 'display_name', p.display_name)
                     order by p.display_name),
           '[]'::jsonb)
    into unclaimed
    from public.players p
   where p.competition_id = v_comp.id
     and p.user_id is null
     and p.is_active;

  return next;
end;
$$;

-- Guests are deliberately allowed here: joining is how an anonymous user gets
-- read access to anything at all.
create function public.join_competition(
  p_join_code       text,
  p_display_name    text default null,
  p_claim_player_id uuid default null
)
returns public.players
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_comp   public.competitions;
  v_player public.players;
  v_name   text;
begin
  if auth.uid() is null then
    raise exception 'Sign in first' using errcode = 'P0001';
  end if;

  select * into v_comp
    from public.competitions
   where join_code = upper(btrim(p_join_code));

  if not found then
    raise exception 'No competition with that code' using errcode = 'P0001';
  end if;

  select * into v_player
    from public.players
   where competition_id = v_comp.id and user_id = auth.uid();

  if found then
    return v_player;
  end if;

  select coalesce(nullif(btrim(p_display_name), ''), p.display_name)
    into v_name
    from public.profiles p where p.id = auth.uid();

  if p_claim_player_id is not null then
    -- Claiming inherits the placeholder's rating and match history: the
    -- player row keeps its id, so nothing downstream has to be rewritten.
    update public.players
       set user_id = auth.uid(),
           display_name = coalesce(nullif(btrim(p_display_name), ''), display_name)
     where id = p_claim_player_id
       and competition_id = v_comp.id
       and user_id is null
       and is_active
    returning * into v_player;

    if not found then
      raise exception 'That player has already been claimed'
        using errcode = 'P0001';
    end if;
  else
    insert into public.players (competition_id, display_name, user_id)
    values (v_comp.id, coalesce(v_name, 'Player'), auth.uid())
    returning * into v_player;
  end if;

  return v_player;
end;
$$;

-- ---------------------------------------------------------------------------
-- Match write API
-- ---------------------------------------------------------------------------

create function public.create_match(
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
  v_comp      public.competitions;
  v_season_id uuid;
  v_match_id  uuid;
  v_all       uuid[];
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

  -- Rating columns are placeholders; apply_match_ratings fills them in below.
  insert into public.matches (
    competition_id, season_id, played_at,
    team_a_score, team_b_score, team_a_rating, team_b_rating, created_by
  )
  values (
    p_competition_id, v_season_id, p_played_at,
    p_score_a, p_score_b, 0, 0, auth.uid()
  )
  returning id into v_match_id;

  insert into public.match_players
    (match_id, player_id, team, rating_before, rating_after, rating_delta)
  -- The enum needs an explicit cast: in a UNION branch an untyped literal is
  -- resolved as text before it reaches the column.
  select v_match_id, x, 'a'::public.match_team, 0, 0, 0 from unnest(p_team_a) x
  union all
  select v_match_id, x, 'b'::public.match_team, 0, 0, 0 from unnest(p_team_b) x;

  perform public.apply_match_ratings(v_match_id);

  -- A back-dated match lands in the middle of the season's history, so the
  -- rest of it has to be replayed on top.
  if exists (
    select 1 from public.matches
     where season_id = v_season_id
       and (played_at, id) > (p_played_at, v_match_id)
  ) then
    perform public.recalc_season(v_season_id);
  end if;

  return v_match_id;
end;
$$;

create function public.delete_match(p_match_id uuid)
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
  perform public.recalc_season(v_match.season_id);
end;
$$;

create function public.update_match_score(
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
  v_match      public.matches;
  v_comp       public.competitions;
  v_new_season uuid;
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

  -- Moving a match in time can move it into a different season entirely.
  v_new_season := case
    when p_played_at is null then v_match.season_id
    else public.ensure_season(v_match.competition_id, p_played_at)
  end;

  update public.matches
     set team_a_score = p_score_a,
         team_b_score = p_score_b,
         played_at    = coalesce(p_played_at, played_at),
         season_id    = v_new_season
   where id = p_match_id;

  perform public.recalc_season(v_match.season_id);
  if v_new_season <> v_match.season_id then
    perform public.recalc_season(v_new_season);
  end if;
end;
$$;

-- To edit a roster, delete the match and log it again — rewriting team
-- membership in place would need the same replay anyway.
