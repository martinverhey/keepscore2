-- Verifies the tournament RPCs (schema/10_functions/start_tournament.sql,
-- set_tournament_result.sql, cancel_tournament.sql): the seeding rule, the
-- field sizes a bracket accepts, how a winner advances, and the invariant the
-- whole feature rests on -- a bracket never moves an Elo rating.
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
  v_p7 uuid; v_p8 uuid;
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
  v_field      integer;
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
  v_p7 := (public.add_dummy_player(v_comp.id, 'P7')).id;
  v_p8 := (public.add_dummy_player(v_comp.id, 'P8')).id;

  -- Distinct ratings, so the seeding order is not a tie-break coin flip.
  v_season := public.ensure_season(v_comp.id, now());
  insert into public.player_ratings (season_id, player_id, rating)
  values (v_season, v_p1, 1300), (v_season, v_p2, 1200), (v_season, v_p3, 1100),
         (v_season, v_p4, 1000), (v_season, v_p5,  900), (v_season, v_p6,  800),
         (v_season, v_p7,  700), (v_season, v_p8,  600);

  select md5(string_agg(player_id::text || ':' || rating::text, ',' order by player_id))
    into v_ratings_before
    from public.player_ratings where season_id = v_season;
  select count(*) into v_matches_before
    from public.matches where competition_id = v_comp.id;

  ----------------------------------------------------------------- seeding --

  v_tournament := public.start_tournament(
    v_comp.id, array[v_p1, v_p2, v_p3, v_p4, v_p5, v_p6, v_p7, v_p8]
  );

  assert (select size from public.tournaments where id = v_tournament) = 8,
    'the size is the field itself';

  select count(*) into v_count
    from public.tournament_matches where tournament_id = v_tournament;
  assert v_count = 7, format('an eight bracket holds 4+2+1 slots, got %s', v_count);

  assert not exists (
    select 1 from public.tournament_matches
     where tournament_id = v_tournament and player_b_id is null and round = 1
  ), 'a power-of-two field leaves no byes at all';

  select * into v_row from public.tournament_matches
   where tournament_id = v_tournament and round = 1 and slot = 0;
  assert v_row.player_a_id = v_p1 and v_row.player_b_id = v_p2,
    'the seeds pair adjacently, closest ratings first';

  select * into v_row from public.tournament_matches
   where tournament_id = v_tournament and round = 1 and slot = 3;
  assert v_row.player_a_id = v_p7 and v_row.player_b_id = v_p8,
    'the last pair is the two lowest seeds';

  --------------------------------------------------------------- refusals --

  v_denied := false;
  begin
    v_second := public.start_tournament(v_comp.id, array[v_p1, v_p2]);
  exception when others then v_denied := true;
  end;
  assert v_denied, 'a second active tournament must be refused';

  select * into v_match from public.tournament_matches
   where tournament_id = v_tournament and round = 1 and slot = 0;

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
   where tournament_id = v_tournament and round = 2 and slot = 0;
  assert v_row.player_a_id = v_p1,
    'an even slot advances into the A side of its parent';

  perform public.set_tournament_result(
    (select id from public.tournament_matches
      where tournament_id = v_tournament and round = 1 and slot = 1), 10, 21
  );

  select * into v_row from public.tournament_matches
   where tournament_id = v_tournament and round = 2 and slot = 0;
  assert v_row.player_b_id = v_p4,
    'an odd slot advances into the B side of its parent';

  perform public.set_tournament_result(
    (select id from public.tournament_matches
      where tournament_id = v_tournament and round = 1 and slot = 2), 21, 15
  );
  perform public.set_tournament_result(
    (select id from public.tournament_matches
      where tournament_id = v_tournament and round = 1 and slot = 3), 10, 21
  );
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
  assert v_row.player_a_id = v_p4 and v_row.player_b_id = v_p5,
    'the final holds both semi-final winners';

  perform public.set_tournament_result(v_row.id, 18, 21);

  assert (select status from public.tournaments where id = v_tournament) = 'completed',
    'the final completes the tournament';
  assert (select winner_player_id from public.tournaments where id = v_tournament) = v_p5,
    'the champion is the winner of the final';

  select trophies into v_trophies
    from public.player_trophies
   where season_id = v_season and player_id = v_p5;
  assert v_trophies = 1, format('the champion has one trophy, got %s', v_trophies);

  select trophies into v_trophies
    from public.leaderboard
   where season_id = v_season and player_id = v_p5;
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

  -------------------------------------------------------- the field size --

  foreach v_field in array array[1, 3, 5, 6, 7] loop
    v_denied := false;
    begin
      v_second := public.start_tournament(
        v_comp.id,
        (array[v_p1, v_p2, v_p3, v_p4, v_p5, v_p6, v_p7, v_p8])[1:v_field]
      );
    exception when others then v_denied := true;
    end;
    assert v_denied,
      format('%s players is not a bracket and must be refused', v_field);
  end loop;

  ------------------------------------------------------------- cancelling --

  v_second := public.start_tournament(v_comp.id, array[v_p1, v_p2, v_p3, v_p4]);
  assert (select size from public.tournaments where id = v_second) = 4,
    'four players make a four bracket';
  assert (select count(*) from public.tournament_matches
           where tournament_id = v_second) = 3,
    'a four bracket holds 2+1 slots';

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

  raise notice 'tournament check OK — seeding, field size, advancing, trophy, no Elo movement';
end;
$$;

rollback;
