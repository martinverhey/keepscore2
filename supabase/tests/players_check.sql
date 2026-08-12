-- Verifies the roster and settings paths the app takes in step 5, from the
-- client's point of view rather than as postgres.
--
--   ./scripts/db.sh -f supabase/tests/players_check.sql
--
-- Everything happens inside a transaction that is rolled back.
--
-- The load-bearing assertion is the one about row counts: a policy-blocked
-- UPDATE is *not* an error in Postgres, it simply matches nothing. The
-- repository turns that silence into a PermissionFailure via maybeSingle(),
-- and this file is what proves the premise.

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
  v_owner   constant uuid := '11111111-1111-1111-1111-111111111111';
  v_guest   constant uuid := '22222222-2222-2222-2222-222222222222';
  v_member  constant uuid := '33333333-3333-3333-3333-333333333333';
  v_other   constant uuid := '44444444-4444-4444-4444-444444444444';
  v_comp    public.competitions;
  v_added   public.players;
  v_target  uuid;
  v_mine    uuid;
  v_n       integer;
  v_denied  boolean;
begin
  select * into v_comp from public.competitions limit 1;

  -- Two more *registered* accounts. The seed's "friend" is anonymous, and
  -- the interesting non-owner cases need people who are not.
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data, is_anonymous
  )
  values
    (v_member, '00000000-0000-0000-0000-000000000000',
     'authenticated', 'authenticated',
     'member@keepscore.test', '', now(), now(), now(),
     '{"provider":"email","providers":["email"]}'::jsonb,
     '{"full_name":"Member"}'::jsonb, false),
    (v_other, '00000000-0000-0000-0000-000000000000',
     'authenticated', 'authenticated',
     'other@keepscore.test', '', now(), now(), now(),
     '{"provider":"email","providers":["email"]}'::jsonb,
     '{"full_name":"Other"}'::jsonb, false)
  on conflict (id) do nothing;

  set local role authenticated;

  perform pg_temp.act_as(v_member);
  perform public.join_competition(v_comp.join_code, 'Member');

  -- -------------------------------------------------------------------
  -- competition_overview, filtered by id — what the detail page loads
  -- -------------------------------------------------------------------
  perform pg_temp.act_as(v_owner);

  select count(*) into v_n
    from public.competition_overview where id = v_comp.id;
  assert v_n = 1, format('owner should see their competition by id, saw %s', v_n);

  select my_player_id into v_mine
    from public.competition_overview where id = v_comp.id;
  assert v_mine is not null, 'the owner''s own player row should come back with it';

  -- -------------------------------------------------------------------
  -- Owner: add, rename, deactivate
  -- -------------------------------------------------------------------
  v_added := public.add_dummy_player(v_comp.id, 'Pieter');
  assert v_added.user_id is null, 'a new placeholder must be unclaimed';
  assert v_added.is_active, 'a new placeholder must be active';

  with updated as (
    update public.players set display_name = 'Pieter K.'
     where id = v_added.id returning 1
  ) select count(*) into v_n from updated;
  assert v_n = 1, 'the owner should be able to rename any player';

  with updated as (
    update public.players set is_active = false
     where id = v_added.id returning 1
  ) select count(*) into v_n from updated;
  assert v_n = 1, 'the owner should be able to deactivate a player';

  -- Removed players drop out of the leaderboard but keep their row.
  select count(*) into v_n
    from public.leaderboard where player_id = v_added.id;
  assert v_n = 0, 'a deactivated player should leave the leaderboard';

  with updated as (
    update public.players set is_active = true
     where id = v_added.id returning 1
  ) select count(*) into v_n from updated;
  assert v_n = 1, 'the owner should be able to bring a player back';

  -- Display names are unique per competition, case- and space-insensitive.
  v_denied := false;
  begin
    perform public.add_dummy_player(v_comp.id, '  pieter k.  ');
  exception when others then v_denied := true;
  end;
  assert v_denied,
    'add_dummy_player must reject a name already used in the competition';

  -- -------------------------------------------------------------------
  -- Registered non-owner: own row only, and refused *silently*
  -- -------------------------------------------------------------------
  perform pg_temp.act_as(v_member);

  select id into v_target
    from public.players
   where competition_id = v_comp.id and id <> v_added.id
     and (user_id is distinct from v_member)
   limit 1;

  with updated as (
    update public.players set display_name = 'Hijacked'
     where id = v_target returning 1
  ) select count(*) into v_n from updated;
  assert v_n = 0,
    'a member renaming someone else must match no rows (not raise)';

  select id into v_mine
    from public.players
   where competition_id = v_comp.id and user_id = v_member;

  with updated as (
    update public.players set display_name = 'Member B'
     where id = v_mine returning 1
  ) select count(*) into v_n from updated;
  assert v_n = 1, 'a member should be able to rename themselves';

  -- Settings are the owner's alone, and again this is silence, not an error.
  with updated as (
    update public.competitions set k_factor = 64
     where id = v_comp.id returning 1
  ) select count(*) into v_n from updated;
  assert v_n = 0,
    'a non-owner changing settings must match no rows (not raise)';

  -- -------------------------------------------------------------------
  -- Guest: reads the roster, changes nothing
  -- -------------------------------------------------------------------
  perform pg_temp.act_as(v_guest, true);

  select count(*) into v_n
    from public.players where competition_id = v_comp.id;
  assert v_n > 0, 'a guest should still read the roster';

  select id into v_mine
    from public.players
   where competition_id = v_comp.id and user_id = v_guest;

  with updated as (
    update public.players set display_name = 'Guesty'
     where id = v_mine returning 1
  ) select count(*) into v_n from updated;
  assert v_n = 0, 'a guest must not rename even their own player';

  -- -------------------------------------------------------------------
  -- Owner: the settings write the app actually sends
  -- -------------------------------------------------------------------
  perform pg_temp.act_as(v_owner);

  with updated as (
    update public.competitions
       set name          = 'Office Ping Pong',
           season_length = 'quarterly',
           k_factor      = 24,
           mov_enabled   = false,
           mov_cap       = 1.80,
           allow_draws   = false
     where id = v_comp.id returning 1
  ) select count(*) into v_n from updated;
  assert v_n = 1, 'the owner should be able to save every settings column';

  -- Out-of-range values are a check violation (23514), which the client maps
  -- to a ValidationFailure rather than a generic error.
  v_denied := false;
  begin
    update public.competitions set k_factor = 500 where id = v_comp.id;
  exception when check_violation then v_denied := true;
  end;
  assert v_denied, 'k_factor must stay range-checked in the database';

  -- The columns the app must never be able to reach.
  v_denied := false;
  begin
    update public.competitions set owner_id = v_member where id = v_comp.id;
  exception when others then v_denied := true;
  end;
  assert v_denied, 'owner_id must not be writable from a client';

  v_denied := false;
  begin
    update public.competitions set join_code = 'AAAAAA' where id = v_comp.id;
  exception when others then v_denied := true;
  end;
  assert v_denied, 'join_code must not be writable from a client';

  -- -------------------------------------------------------------------
  -- A second registered account joining as a brand new player
  -- -------------------------------------------------------------------
  perform pg_temp.act_as(v_other);

  v_denied := false;
  begin
    perform public.join_competition(v_comp.join_code, ' member b ');
  exception when others then v_denied := true;
  end;
  assert v_denied,
    'join_competition must reject a display name already used in the competition';

  raise notice 'Player + settings checks OK';
end;
$$;

rollback;
