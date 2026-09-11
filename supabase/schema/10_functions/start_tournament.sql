-- start_tournament — seeds a single-elimination bracket and writes every round
-- of it up front, so the bracket has a shape before a single score exists.
--
-- Seeding rule: players are ordered by their current rating, and the pairing
-- is *adjacent* rather than the usual 1-v-N — the two closest-rated players
-- meet in round one. Padding up to a power of two hands the byes to the top
-- seeds: the first v_byes slots hold one player each, and the remaining seeds
-- pair off below them. A bye is resolved immediately, so round two opens with
-- those players already in it.
--
-- Nothing here touches matches/match_players/player_ratings. A bracket result
-- is not an Elo result.

create or replace function public.start_tournament(
  p_competition_id uuid,
  p_player_ids     uuid[]
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_comp          public.competitions;
  v_count         integer;
  v_size          integer;
  v_byes          integer;
  v_rounds        integer;
  v_season_id     uuid;
  v_tournament_id uuid;
  v_seeds         uuid[];
  v_round         integer;
  v_slot          integer;
  v_seed          integer;
  v_player_a      uuid;
  v_player_b      uuid;
  v_bye           record;
begin
  if not public.is_registered() then
    raise exception 'Create an account to start a tournament' using errcode = 'P0001';
  end if;
  if not public.is_member(p_competition_id) then
    raise exception 'You are not in this competition' using errcode = 'P0001';
  end if;

  select * into strict v_comp
    from public.competitions where id = p_competition_id;

  v_count := coalesce(array_length(p_player_ids, 1), 0);

  if v_count < 2 then
    raise exception 'Pick at least two players' using errcode = 'P0001';
  end if;
  if v_count > 16 then
    raise exception 'A tournament holds at most 16 players' using errcode = 'P0001';
  end if;

  if (select count(distinct x) from unnest(p_player_ids) x) <> v_count then
    raise exception 'A player can only appear once in a tournament'
      using errcode = 'P0001';
  end if;

  if exists (
    select 1 from unnest(p_player_ids) x
     where not exists (
       select 1 from public.players p
        where p.id = x and p.competition_id = p_competition_id and p.is_active
     )
  ) then
    raise exception 'All players must be active members of this competition'
      using errcode = 'P0001';
  end if;

  if exists (
    select 1 from public.tournaments t
     where t.competition_id = p_competition_id
       and t.status = 'active'
  ) then
    raise exception 'This competition already has a tournament running'
      using errcode = 'P0001';
  end if;

  v_season_id := public.ensure_season(p_competition_id, now());

  -- Smallest power of two that holds them all: 2, 4, 8 or 16.
  v_size := 2;
  while v_size < v_count loop
    v_size := v_size * 2;
  end loop;
  v_byes := v_size - v_count;

  v_rounds := 0;
  while power(2, v_rounds)::integer < v_size loop
    v_rounds := v_rounds + 1;
  end loop;

  -- Highest rating first, tie-broken the way leaderboard_base ranks.
  select array_agg(ranked.id order by ranked.rating desc, ranked.wins desc,
                   ranked.display_name asc)
    into v_seeds
    from (
      select p.id,
             coalesce(pr.rating, v_comp.starting_rating) as rating,
             coalesce(pr.wins, 0)                        as wins,
             p.display_name
        from public.players p
        left join public.player_ratings pr
          on pr.player_id = p.id
         and pr.season_id = v_season_id
       where p.id = any (p_player_ids)
    ) ranked;

  insert into public.tournaments
    (competition_id, season_id, size, created_by)
  values
    (p_competition_id, v_season_id, v_size, auth.uid())
  returning id into v_tournament_id;

  for v_slot in 0 .. (v_size / 2) - 1 loop
    if v_slot < v_byes then
      v_player_a := v_seeds[v_slot + 1];
      v_player_b := null;
    else
      v_seed := v_byes + 2 * (v_slot - v_byes);
      v_player_a := v_seeds[v_seed + 1];
      v_player_b := v_seeds[v_seed + 2];
    end if;

    insert into public.tournament_matches
      (tournament_id, round, slot, player_a_id, player_b_id)
    values
      (v_tournament_id, 1, v_slot, v_player_a, v_player_b);
  end loop;

  for v_round in 2 .. v_rounds loop
    for v_slot in 0 .. (v_size / power(2, v_round)::integer) - 1 loop
      insert into public.tournament_matches (tournament_id, round, slot)
      values (v_tournament_id, v_round, v_slot);
    end loop;
  end loop;

  -- A bye is decided the moment it is drawn. Two byes can feed the same
  -- round-two slot (five players in an eight bracket), which fills it with two
  -- real players -- so one pass is always enough and nothing cascades.
  for v_bye in
    select tm.slot, tm.player_a_id
      from public.tournament_matches tm
     where tm.tournament_id = v_tournament_id
       and tm.round = 1
       and tm.player_b_id is null
       and tm.player_a_id is not null
  loop
    update public.tournament_matches
       set winner_player_id = v_bye.player_a_id
     where tournament_id = v_tournament_id
       and round = 1
       and slot = v_bye.slot;

    if v_rounds >= 2 then
      update public.tournament_matches
         set player_a_id = case when v_bye.slot % 2 = 0
                                then v_bye.player_a_id else player_a_id end,
             player_b_id = case when v_bye.slot % 2 = 1
                                then v_bye.player_a_id else player_b_id end
       where tournament_id = v_tournament_id
         and round = 2
         and slot = v_bye.slot / 2;
    end if;
  end loop;

  return v_tournament_id;
end;
$$;

revoke all on function public.start_tournament(p_competition_id uuid, p_player_ids uuid[]) from public, anon, authenticated;
grant execute on function public.start_tournament(p_competition_id uuid, p_player_ids uuid[]) to authenticated;
