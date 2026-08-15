-- Verifies recalc_season_from / recalc_season_game_type_from (20260816110000):
-- after create_match / update_match_score / delete_match run their narrow,
-- boundary-scoped replay, the result must be byte-identical to running a
-- full recalc_season / recalc_season_game_type from scratch on the same
-- season — for player_ratings, player_game_type_ratings, and every
-- match_players row (not just the ones at/after the boundary).
--
--   ./scripts/db.sh -f supabase/tests/incremental_recalc_check.sql
--
-- Self-contained — creates its own throwaway competition. Everything happens
-- inside a transaction that is rolled back.

begin;

create or replace function pg_temp.act_as(p_user uuid, p_anonymous boolean default false)
returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object(
    'sub', p_user, 'role', 'authenticated', 'is_anonymous', p_anonymous
  )::text, true);
end;
$$;

create function pg_temp.hash_ratings(p_season_id uuid)
returns text language sql as $$
  select md5(coalesce(string_agg(
    player_id::text || ':' || rating::text || ':' || played
      || ':' || wins || ':' || losses || ':' || draws,
    ',' order by player_id
  ), ''))
  from public.player_ratings where season_id = p_season_id;
$$;

create function pg_temp.hash_type_ratings(p_season_id uuid, p_game_type public.game_type)
returns text language sql as $$
  select md5(coalesce(string_agg(
    player_id::text || ':' || rating::text || ':' || played
      || ':' || wins || ':' || losses || ':' || draws,
    ',' order by player_id
  ), ''))
  from public.player_game_type_ratings
  where season_id = p_season_id and game_type = p_game_type;
$$;

create function pg_temp.hash_match_players(p_season_id uuid)
returns text language sql as $$
  select md5(coalesce(string_agg(
    mp.match_id::text || ':' || mp.player_id::text || ':' || mp.rating_before
      || ':' || mp.rating_after || ':' || mp.rating_delta || ':' || mp.outcome::text
      || ':' || coalesce(mp.type_rating_before::text, 'null')
      || ':' || coalesce(mp.type_rating_after::text, 'null')
      || ':' || coalesce(mp.type_rating_delta::text, 'null'),
    ',' order by mp.match_id, mp.player_id
  ), ''))
  from public.match_players mp
  join public.matches m on m.id = mp.match_id
  where m.season_id = p_season_id;
$$;

-- The load-bearing assertion: whatever the incremental write RPCs just did,
-- a from-scratch full recalc of the same season must land on exactly the
-- same numbers. If it doesn't, the boundary logic is wrong.
create function pg_temp.assert_matches_full_rebuild(p_season_id uuid, p_label text)
returns void language plpgsql as $$
declare
  v_ratings_before      text;
  v_match_players_before text;
  v_gt                   public.game_type;
  v_type_before          jsonb := '{}'::jsonb;
  v_type_after           text;
begin
  v_ratings_before := pg_temp.hash_ratings(p_season_id);
  v_match_players_before := pg_temp.hash_match_players(p_season_id);
  for v_gt in select distinct game_type from public.matches where season_id = p_season_id loop
    v_type_before := v_type_before
      || jsonb_build_object(v_gt::text, pg_temp.hash_type_ratings(p_season_id, v_gt));
  end loop;

  perform public.recalc_season(p_season_id);
  for v_gt in select distinct game_type from public.matches where season_id = p_season_id loop
    perform public.recalc_season_game_type(p_season_id, v_gt);
  end loop;

  assert pg_temp.hash_ratings(p_season_id) = v_ratings_before,
    format('[%s] player_ratings diverged from a full rebuild', p_label);
  assert pg_temp.hash_match_players(p_season_id) = v_match_players_before,
    format('[%s] match_players diverged from a full rebuild', p_label);

  for v_gt in select distinct game_type from public.matches where season_id = p_season_id loop
    v_type_after := pg_temp.hash_type_ratings(p_season_id, v_gt);
    assert v_type_after = (v_type_before ->> v_gt::text),
      format('[%s] player_game_type_ratings (%s) diverged from a full rebuild', p_label, v_gt);
  end loop;
end;
$$;

do $$
declare
  v_owner  constant uuid := '77777777-7777-7777-7777-777777777777';
  v_comp   public.competitions;
  v_season uuid;
  v_p1 uuid;
  v_p2 uuid;
  v_p3 uuid;
  v_p4 uuid;
  v_m2 uuid;
  v_m3 uuid;
  v_base timestamptz := date_trunc('day', now()) - interval '10 days';
begin
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data, is_anonymous
  )
  values (
    v_owner, '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    'incremental-check-owner@keepscore.test', '', now(), now(), now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Owner"}'::jsonb, false
  );

  perform pg_temp.act_as(v_owner);

  v_comp := public.create_competition('Incremental check', 'monthly');
  v_p1 := (select id from public.players where competition_id = v_comp.id);
  v_p2 := (public.add_dummy_player(v_comp.id, 'P2')).id;
  v_p3 := (public.add_dummy_player(v_comp.id, 'P3')).id;
  v_p4 := (public.add_dummy_player(v_comp.id, 'P4')).id;

  -- Six matches, mixing 1v1 and 2v2, all created in order — this already
  -- exercises create_match's new unconditional recalc_season_from path for
  -- the ordinary (non-back-dated) case.
  perform public.create_match(v_comp.id, array[v_p1], array[v_p2], 21, 15, v_base);
  v_m2 := public.create_match(v_comp.id, array[v_p3], array[v_p4], 21, 18, v_base + interval '1 day');
  v_m3 := public.create_match(v_comp.id, array[v_p1], array[v_p3], 21, 10, v_base + interval '2 days');
  perform public.create_match(v_comp.id, array[v_p2], array[v_p4], 15, 21, v_base + interval '3 days');
  perform public.create_match(v_comp.id, array[v_p1, v_p2], array[v_p3, v_p4], 21, 19, v_base + interval '4 days');
  perform public.create_match(v_comp.id, array[v_p1], array[v_p4], 21, 12, v_base + interval '5 days');

  select id into v_season
    from public.seasons
   where competition_id = v_comp.id
   order by starts_at desc
   limit 1;

  perform pg_temp.assert_matches_full_rebuild(v_season, 'after six ordinary create_match calls');

  -- A back-dated insert: lands between the 1st and 2nd match, so create_match
  -- must ripple the replay forward through everything after it.
  perform public.create_match(
    v_comp.id, array[v_p2], array[v_p3], 5, 21, v_base + interval '12 hours'
  );
  perform pg_temp.assert_matches_full_rebuild(v_season, 'after a back-dated create_match');

  -- Editing the score of an EARLY match (m3, third of what's now seven) —
  -- the boundary is the middle of the season, not its start.
  perform public.update_match_score(v_m3, 8, 21);
  perform pg_temp.assert_matches_full_rebuild(v_season, 'after update_match_score on an early match');

  -- Deleting a match that isn't the last one played.
  perform public.delete_match(v_m2);
  perform pg_temp.assert_matches_full_rebuild(v_season, 'after delete_match on a non-final match');

  -- Moving a match to a different season entirely — both seasons must end
  -- up correct independently.
  declare
    v_moved_match uuid;
    v_next_season uuid;
  begin
    v_moved_match := public.create_match(
      v_comp.id, array[v_p1], array[v_p2], 21, 9, v_base + interval '6 days'
    );
    perform public.update_match_score(
      v_moved_match, 21, 17, v_base + interval '45 days'
    );

    select id into v_next_season
      from public.seasons
     where competition_id = v_comp.id and starts_at > (
       select starts_at from public.seasons where id = v_season
     )
     order by starts_at
     limit 1;

    perform pg_temp.assert_matches_full_rebuild(v_season, 'old season after a cross-season move');
    perform pg_temp.assert_matches_full_rebuild(v_next_season, 'new season after a cross-season move');
  end;

  raise notice 'incremental recalc check OK — matches a from-scratch full rebuild at every step';
end;
$$;

rollback;
