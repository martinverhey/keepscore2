-- Verifies that apply_match_ratings / apply_match_type_rating (20260815170000)
-- actually skip no-op writes: replaying a season that hasn't changed must
-- rewrite zero rows in matches and match_players, not just leave the final
-- values correct.
--
--   ./scripts/db.sh -f supabase/tests/no_op_recalc_check.sql
--
-- Self-contained — creates its own throwaway competition rather than reusing
-- the live seed's, so it doesn't depend on what else has been played there.
-- Everything happens inside a transaction that is rolled back.

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
  v_owner  constant uuid := '66666666-6666-6666-6666-666666666666';
  v_comp   public.competitions;
  v_season uuid;
  v_p1     uuid;
  v_p2     uuid;
  v_p3     uuid;
  v_gt     public.game_type;
  v_matches_total   integer;
  v_matches_touched integer;
  v_mp_total   integer;
  v_mp_touched integer;
  v_before_hash text;
  v_after_hash  text;
begin
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data, is_anonymous
  )
  values (
    v_owner, '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    'noop-check-owner@keepscore.test', '', now(), now(), now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Owner"}'::jsonb, false
  );

  perform pg_temp.act_as(v_owner);

  v_comp := public.create_competition('No-op check', 'monthly');
  v_p1 := (select id from public.players where competition_id = v_comp.id);
  v_p2 := (public.add_dummy_player(v_comp.id, 'P2')).id;
  v_p3 := (public.add_dummy_player(v_comp.id, 'P3')).id;

  -- A handful of matches across two game types, including a mixed-size one,
  -- so the replay below exercises both apply_match_ratings and
  -- apply_match_type_rating for more than one game_type.
  perform public.create_match(v_comp.id, array[v_p1], array[v_p2], 21, 15, now() - interval '3 days');
  perform public.create_match(v_comp.id, array[v_p2], array[v_p3], 21, 18, now() - interval '2 days');
  perform public.create_match(v_comp.id, array[v_p1], array[v_p3], 21, 10, now() - interval '1 day');
  perform public.create_match(v_comp.id, array[v_p1, v_p2], array[v_p3], 21, 19, now());

  select id into v_season
    from public.seasons
   where competition_id = v_comp.id
   order by starts_at desc
   limit 1;

  select md5(string_agg(player_id::text || ':' || rating::text, ',' order by player_id))
    into v_before_hash
    from public.player_ratings
   where season_id = v_season;

  create temp table xmin_before_matches as
    select id, xmin as old_xmin from public.matches where season_id = v_season;
  create temp table xmin_before_mp as
    select match_id, player_id, xmin as old_xmin
      from public.match_players
     where match_id in (select id from public.matches where season_id = v_season);

  -- Replaying an already-consistent season must be a pure no-op at the
  -- storage level, not just arrive at the same final numbers.
  perform public.recalc_season(v_season);
  for v_gt in select distinct game_type from public.matches where season_id = v_season loop
    perform public.recalc_season_game_type(v_season, v_gt);
  end loop;

  select md5(string_agg(player_id::text || ':' || rating::text, ',' order by player_id))
    into v_after_hash
    from public.player_ratings
   where season_id = v_season;

  assert v_before_hash = v_after_hash,
    format('recalc must not change ratings: before=%s after=%s', v_before_hash, v_after_hash);

  select count(*) into v_matches_total from xmin_before_matches;
  select count(*) into v_matches_touched
    from public.matches m
    join xmin_before_matches b on b.id = m.id
   where m.xmin <> b.old_xmin;
  assert v_matches_touched = 0,
    format('recalc of an unchanged season rewrote %s/%s matches rows, expected 0',
           v_matches_touched, v_matches_total);

  select count(*) into v_mp_total from xmin_before_mp;
  select count(*) into v_mp_touched
    from public.match_players mp
    join xmin_before_mp b on b.match_id = mp.match_id and b.player_id = mp.player_id
   where mp.xmin <> b.old_xmin;
  assert v_mp_touched = 0,
    format('recalc of an unchanged season rewrote %s/%s match_players rows, expected 0',
           v_mp_touched, v_mp_total);

  raise notice 'no-op recalc check OK — % matches, % match_players rows, 0 rewritten',
    v_matches_total, v_mp_total;
end;
$$;

rollback;
