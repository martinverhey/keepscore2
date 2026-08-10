-- Verifies the policies in 0003_rls.sql from the client's point of view.
--
-- Run against a database that has been seeded:  scripts/db.sh -f supabase/tests/rls_check.sql
-- Everything happens inside a transaction that is rolled back, so this leaves
-- no trace.

begin;

create or replace function pg_temp.act_as(p_user uuid, p_anonymous boolean default false)
returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object(
    'sub', p_user, 'role', 'authenticated', 'is_anonymous', p_anonymous
  )::text, true);
end;
$$;

do $$
declare
  v_owner    constant uuid := '11111111-1111-1111-1111-111111111111';
  v_guest    constant uuid := '22222222-2222-2222-2222-222222222222';
  v_outsider uuid;
  v_comp     public.competitions;
  v_n        integer;
  v_denied   boolean;
  v_player   uuid;
begin
  select * into v_comp from public.competitions limit 1;

  -- A real account that is not in the competition.
  select id into v_outsider from auth.users
   where id not in (v_owner, v_guest) limit 1;

  set local role authenticated;

  -- ---------------------------------------------------------------------
  -- Member sees the competition
  -- ---------------------------------------------------------------------
  perform pg_temp.act_as(v_owner);

  select count(*) into v_n from public.competitions;
  assert v_n = 1, format('owner should see 1 competition, saw %s', v_n);

  select count(*) into v_n from public.leaderboard;
  assert v_n = 5, format('owner should see 5 leaderboard rows, saw %s', v_n);

  select count(*) into v_n from public.match_feed;
  assert v_n > 0, 'owner should see the match feed';

  -- ---------------------------------------------------------------------
  -- Outsider sees nothing at all
  -- ---------------------------------------------------------------------
  if v_outsider is not null then
    perform pg_temp.act_as(v_outsider);

    select count(*) into v_n from public.competitions;
    assert v_n = 0, format('outsider should see no competitions, saw %s', v_n);

    select count(*) into v_n from public.leaderboard;
    assert v_n = 0, format('outsider should see no leaderboard, saw %s', v_n);

    select count(*) into v_n from public.matches;
    assert v_n = 0, format('outsider should see no matches, saw %s', v_n);

    select count(*) into v_n from public.players;
    assert v_n = 0, format('outsider should see no players, saw %s', v_n);
  end if;

  -- ---------------------------------------------------------------------
  -- Direct writes are impossible even for a member
  -- ---------------------------------------------------------------------
  perform pg_temp.act_as(v_owner);
  select id into v_player from public.players limit 1;

  v_denied := false;
  begin
    insert into public.matches (competition_id, season_id, team_a_score,
                                team_b_score, team_a_rating, team_b_rating)
    values (v_comp.id, (select id from public.seasons limit 1), 21, 0, 1000, 1000);
  exception when others then v_denied := true;
  end;
  assert v_denied, 'a member must not be able to INSERT into matches directly';

  v_denied := false;
  begin
    update public.player_ratings set rating = 9999;
  exception when others then v_denied := true;
  end;
  assert v_denied, 'nobody may hand-edit player_ratings';

  -- The column grant is what stops an owner reassigning a player to themselves.
  v_denied := false;
  begin
    update public.players set user_id = v_owner where id = v_player;
  exception when others then v_denied := true;
  end;
  assert v_denied, 'user_id must not be writable directly';

  -- …but renaming a player is allowed for the owner.
  update public.players set display_name = display_name where id = v_player;

  -- ---------------------------------------------------------------------
  -- Guests read but never write
  -- ---------------------------------------------------------------------
  perform pg_temp.act_as(v_guest, true);

  select count(*) into v_n from public.leaderboard;
  assert v_n = 5, format('guest should still see the leaderboard, saw %s', v_n);

  v_denied := false;
  begin
    perform public.create_competition('Guest competition');
  exception when others then v_denied := true;
  end;
  assert v_denied, 'a guest must not create a competition';

  v_denied := false;
  begin
    perform public.add_dummy_player(v_comp.id, 'Ghost');
  exception when others then v_denied := true;
  end;
  assert v_denied, 'a guest must not add players';

  raise notice 'RLS checks OK';
end;
$$;

rollback;
