-- Verifies that a claimed player's name is theirs alone, and that the guard
-- costs the owner nothing else.
--
--   ./scripts/db.sh -f supabase/tests/player_rename_guard_check.sql
--
-- Everything happens inside a transaction that is rolled back.
--
-- The distinction being protected: this is the one player write that is
-- refused with an *exception* rather than by matching no rows. RLS still
-- admits the owner's UPDATE — the trigger is what stops it — so the client
-- sees a P0001 message, not the silent PermissionFailure path that
-- players_check.sql covers.

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
  v_comp    public.competitions;
  v_owner   uuid;
  v_joiner  constant uuid := '55555555-5555-5555-5555-555555555555';
  v_claimed uuid;
  v_dummy   public.players;
  v_own     uuid;
  v_n       integer;
  v_denied  boolean;
begin
  select c.* into v_comp
    from public.competitions c
   where exists (
     select 1 from public.players p
      where p.competition_id = c.id
        and p.user_id is not null
        and p.user_id <> c.owner_id
   )
   limit 1;
  v_owner := v_comp.owner_id;

  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data, is_anonymous
  ) values (
    v_joiner, '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated', 'joiner@keepscore.test', '',
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Joiner"}'::jsonb, false
  ) on conflict (id) do nothing;

  set local role authenticated;
  perform pg_temp.act_as(v_owner);

  -- -------------------------------------------------------------------
  -- Owner: everything except renaming someone else's claimed row
  -- -------------------------------------------------------------------
  v_dummy := public.add_dummy_player(v_comp.id, 'Guarded Placeholder');

  with updated as (
    update public.players set display_name = 'Guarded Placeholder 2'
     where id = v_dummy.id returning 1
  ) select count(*) into v_n from updated;
  assert v_n = 1, 'the owner should still rename an unclaimed player';

  select p.id into v_own from public.players p
   where p.competition_id = v_comp.id and p.user_id = v_owner;

  with updated as (
    update public.players set display_name = 'Owner Renamed'
     where id = v_own returning 1
  ) select count(*) into v_n from updated;
  assert v_n = 1, 'the owner should still rename their own player';

  select p.id into v_claimed from public.players p
   where p.competition_id = v_comp.id
     and p.user_id is not null and p.user_id <> v_owner
   limit 1;

  v_denied := false;
  begin
    update public.players set display_name = 'Hijacked' where id = v_claimed;
  exception when others then v_denied := true;
  end;
  assert v_denied, 'the owner must not rename a claimed player';

  with updated as (
    update public.players set is_active = false
     where id = v_claimed returning 1
  ) select count(*) into v_n from updated;
  assert v_n = 1, 'the owner should still deactivate a claimed player';

  with updated as (
    update public.players set is_active = true
     where id = v_claimed returning 1
  ) select count(*) into v_n from updated;
  assert v_n = 1, 'the owner should still restore a claimed player';

  -- -------------------------------------------------------------------
  -- Claiming a placeholder still names it, and the claimer owns that name
  -- -------------------------------------------------------------------
  perform pg_temp.act_as(v_joiner);
  perform public.join_competition(v_comp.join_code, 'Joiner Name', v_dummy.id);

  with updated as (
    update public.players set display_name = 'Joiner Renamed'
     where id = v_dummy.id returning 1
  ) select count(*) into v_n from updated;
  assert v_n = 1, 'a member should still rename themselves after claiming';
end;
$$;

rollback;
