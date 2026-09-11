-- Verifies the tournament RPCs (schema/10_functions/start_tournament.sql,
-- set_tournament_result.sql, cancel_tournament.sql): the seeding rule, the
-- byes, how a winner advances, and the invariant the whole feature rests on --
-- a bracket never moves an Elo rating.
--
--   ./scripts/db.sh -f supabase/tests/tournament_check.sql
--
-- Self-contained — creates its own throwaway competition, and rolls back.

begin;

create or replace function pg_temp.act_as(p_user uuid, p_anonymous boolean default false)
returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object(
    'sub', p_user, 'role', 'authenticated', 'is_anonymous', p_anonymous
  )::text, true);
end;
$$;

create or replace function pg_temp.make_user(p_id uuid, p_email text, p_anonymous boolean default false)
returns void language plpgsql as $$
begin
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data, is_anonymous
  )
  values (
    p_id, '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    p_email, '', now(), now(), now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Tournament check"}'::jsonb, p_anonymous
  );
end;
$$;

do $$
declare
  v_owner     constant uuid := '77777777-7777-7777-7777-777777777777';
  v_outsider  constant uuid := '77777777-7777-7777-7777-777777777778';
  v_guest     constant uuid := '77777777-7777-7777-7777-777777777779';
  v_comp      public.competitions;
  v_season    uuid;
  v_p1 uuid; v_p2 uuid; v_p3 uuid; v_p4 uuid; v_p5 uuid; v_p6 uuid;
  v_tournament uuid;
  v_second     uuid;
  v_match      public.tournament_matches;
  v_row        public.tournament_matches;
  v_count      integer;
  v_denied     boolean;
  v_ratings_before text;
  v_ratings_after  text;
  v_matches_before integer;
  v_matches_after  integer;
  v_trophies   integer;
begin
  perform pg_temp.make_user(v_owner, 'tournament-owner@keepscore.test');
  perform pg_temp.make_user(v_outsider, 'tournament-outsider@keepscore.test');
  perform pg_temp.make_user(v_guest, 'tournament-guest@keepscore.test', true);

  perform pg_temp.act_as(v_owner);

  v_comp := public.create_competition('Tournament check', 'monthly');
  v_p1 := (select id from public.players where competition_id = v_comp.id);
  v_p2 := (public.add_dummy_player(v_comp.id, 'P2')).id;
  v_p3 := (public.add_dummy_player(v_comp.id, 'P3')).id;
  v_p4 := (public.add_dummy_player(v_comp.id, 'P4')).id;
  v_p5 := (public.add_dummy_player(v_comp.id, 'P5')).id;
  v_p6 := (public.add_dummy_player(v_comp.id, 'P6')).id;

  -- Distinct ratings, so the seeding order is not a tie-break coin flip.
  v_season := public.ensure_season(v_comp.id, now());
  insert into public.player_ratings (season_id, player_id, rating)
  values (v_season, v_p1, 1300), (v_season, v_p2, 1200), (v_season, v_p3, 1100),
         (v_season, v_p4, 1000), (v_season, v_p5,  900), (v_season, v_p6,  800);

  select md5(string_agg(player_id::text || ':' || rating::text, ',' order by player_id))
    into v_ratings_before
    from public.player_ratings where season_id = v_season;
  select count(*) into v_matches_before
    from public.matches where competition_id = v_comp.id;

  ----------------------------------------------------------------- seeding --

  v_tournament := public.start_tournament(
    v_comp.id, array[v_p1, v_p2, v_p3, v_p4, v_p5, v_p6]
  );

  assert (select size from public.tournaments where id = v_tournament) = 8,
    'six players must pad up to an eight bracket';

  select count(*) into v_count
    from public.tournament_matches where tournament_id = v_tournament;
  assert v_count = 7, format('an eight bracket holds 4+2+1 slots, got %s', v_count);

  select * into v_row from public.tournament_matches
   where tournament_id = v_tournament and round = 1 and slot = 0;
  assert v_row.player_a_id = v_p1 and v_row.player_b_id is null,
    'the top seed gets the first bye';
  assert v_row.winner_player_id = v_p1, 'a bye is decided when it is drawn';

  select * into v_row from public.tournament_matches
   where tournament_id = v_tournament and round = 1 and slot = 1;
  assert v_row.player_a_id = v_p2 and v_row.player_b_id is null,
    'the second seed gets the second bye';

  select * into v_row from public.tournament_matches
   where tournament_id = v_tournament and round = 1 and slot = 2;
  assert v_row.player_a_id = v_p3 and v_row.player_b_id = v_p4,
    'the remaining seeds pair adjacently, closest ratings first';

  select * into v_row from public.tournament_matches
   where tournament_id = v_tournament and round = 1 and slot = 3;
  assert v_row.player_a_id = v_p5 and v_row.player_b_id = v_p6,
    'the last pair is the two lowest seeds';

  select * into v_row from public.tournament_matches
   where tournament_id = v_tournament and round = 2 and slot = 0;
  assert v_row.player_a_id = v_p1 and v_row.player_b_id = v_p2,
    'both byes advance into the same round-two slot, on the right sides';

  --------------------------------------------------------------- refusals --

  v_denied := false;
  begin
    v_second := public.start_tournament(v_comp.id, array[v_p1, v_p2]);
  exception when others then v_denied := true;
  end;
  assert v_denied, 'a second active tournament must be refused';

  select * into v_match from public.tournament_matches
   where tournament_id = v_tournament and round = 1 and slot = 2;

  v_denied := false;
  begin
    perform public.set_tournament_result(v_match.id, 11, 11);
  exception when others then v_denied := true;
  end;
  assert v_denied, 'a bracket match must not end in a draw';

  v_denied := false;
  begin
    perform public.set_tournament_result(v_match.id, -1, 5);
  exception when others then v_denied := true;
  end;
  assert v_denied, 'a negative score must be refused';

  v_denied := false;
  begin
    perform public.set_tournament_result(
      (select id from public.tournament_matches
        where tournament_id = v_tournament and round = 3 and slot = 0), 21, 10
    );
  exception when others then v_denied := true;
  end;
  assert v_denied, 'a slot with no players yet must not be scorable';

  perform pg_temp.act_as(v_outsider);
  v_denied := false;
  begin
    perform public.set_tournament_result(v_match.id, 21, 10);
  exception when others then v_denied := true;
  end;
  assert v_denied, 'a non-member must not enter a tournament score';

  perform pg_temp.act_as(v_guest, true);
  v_denied := false;
  begin
    v_second := public.start_tournament(v_comp.id, array[v_p1, v_p2]);
  exception when others then v_denied := true;
  end;
  assert v_denied, 'a guest must not start a tournament';

  perform pg_temp.act_as(v_owner);

  -------------------------------------------------------------- advancing --

  perform public.set_tournament_result(v_match.id, 21, 15);

  select * into v_row from public.tournament_matches
   where tournament_id = v_tournament and round = 2 and slot = 1;
  assert v_row.player_a_id = v_p3,
    'an even slot advances into the A side of its parent';

  perform public.set_tournament_result(
    (select id from public.tournament_matches
      where tournament_id = v_tournament and round = 1 and slot = 3), 10, 21
  );

  select * into v_row from public.tournament_matches
   where tournament_id = v_tournament and round = 2 and slot = 1;
  assert v_row.player_b_id = v_p6,
    'an odd slot advances into the B side of its parent';

  perform public.set_tournament_result(
    (select id from public.tournament_matches
      where tournament_id = v_tournament and round = 2 and slot = 0), 15, 21
  );
  perform public.set_tournament_result(
    (select id from public.tournament_matches
      where tournament_id = v_tournament and round = 2 and slot = 1), 21, 18
  );

  -- Re-scoring a match whose follow-up is already played would orphan the
  -- bracket, but only if it flips the winner.
  v_denied := false;
  begin
    perform public.set_tournament_result(v_match.id, 15, 21);
  exception when others then v_denied := true;
  end;
  assert v_denied, 'flipping a winner under a played match must be refused';

  perform public.set_tournament_result(v_match.id, 21, 19);
  assert (select score_b from public.tournament_matches where id = v_match.id) = 19,
    'correcting a score without flipping the winner must still be allowed';

  ---------------------------------------------------------------- the win --

  select * into v_row from public.tournament_matches
   where tournament_id = v_tournament and round = 3 and slot = 0;
  assert v_row.player_a_id = v_p2 and v_row.player_b_id = v_p3,
    'the final holds both semi-final winners';

  perform public.set_tournament_result(v_row.id, 18, 21);

  select * into v_row from public.tournament_matches
   where tournament_id = v_tournament and round = 3 and slot = 0;
  assert (select status from public.tournaments where id = v_tournament) = 'completed',
    'the final completes the tournament';
  assert (select winner_player_id from public.tournaments where id = v_tournament) = v_p3,
    'the champion is the winner of the final';

  select trophies into v_trophies
    from public.player_trophies
   where season_id = v_season and player_id = v_p3;
  assert v_trophies = 1, format('the champion has one trophy, got %s', v_trophies);

  select trophies into v_trophies
    from public.leaderboard
   where season_id = v_season and player_id = v_p3;
  assert v_trophies = 1, 'the leaderboard carries the trophy count';

  select trophies into v_trophies
    from public.leaderboard
   where season_id = v_season and player_id = v_p1;
  assert v_trophies = 0, 'a player who won nothing has no trophies';

  -------------------------------------------------- nothing else moved at all --

  select md5(string_agg(player_id::text || ':' || rating::text, ',' order by player_id))
    into v_ratings_after
    from public.player_ratings where season_id = v_season;
  assert v_ratings_before = v_ratings_after,
    'a tournament must not move a single Elo rating';

  select count(*) into v_matches_after
    from public.matches where competition_id = v_comp.id;
  assert v_matches_before = v_matches_after,
    'a tournament must not write anything into matches';

  ------------------------------------------------------------- cancelling --

  v_second := public.start_tournament(v_comp.id, array[v_p1, v_p2, v_p3]);
  assert (select size from public.tournaments where id = v_second) = 4,
    'three players pad up to a four bracket';
  assert (select count(*) from public.tournament_matches
           where tournament_id = v_second and round = 1 and player_b_id is null) = 1,
    'three players leave exactly one bye';

  perform pg_temp.act_as(v_outsider);
  v_denied := false;
  begin
    perform public.cancel_tournament(v_second);
  exception when others then v_denied := true;
  end;
  assert v_denied, 'only the starter or the owner can cancel a tournament';

  perform pg_temp.act_as(v_owner);
  perform public.cancel_tournament(v_second);
  assert not exists (select 1 from public.tournaments where id = v_second),
    'cancelling removes the tournament';
  assert not exists (select 1 from public.tournament_matches where tournament_id = v_second),
    'cancelling cascades to its matches';

  raise notice 'tournament check OK — seeding, byes, advancing, trophy, no Elo movement';
end;
$$;

rollback;
