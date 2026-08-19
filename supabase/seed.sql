-- KeepScore 2 — local seed and self-check. Runs on `supabase db reset`.
--
-- Beyond giving the app something to render, this file is the main safety net
-- for the rating engine: it builds a season one match at a time, then replays
-- it with recalc_season() and asserts the two agree. If an incremental write
-- and a full replay ever diverge, edits and deletes silently corrupt history.

-- ---------------------------------------------------------------------------
-- Part 1 — elo_delta fixtures
--
-- These same numbers are asserted in Dart against EloCalculator
-- (test/features/match/elo_calculator_test.dart), which is what keeps the
-- client-side preview honest.
-- ---------------------------------------------------------------------------

do $$
declare
  v_k        constant integer := 32;
  v_cap      constant numeric := 2.5;
  v_delta    numeric;
begin
  -- Even players, one-point win: multiplier is exactly 1, so this is plain Elo.
  assert public.elo_delta(1000, 1000, 10, 9, v_k, true, v_cap) = 16.00,
    'even 1-point win should be +16';

  assert public.elo_delta(1000, 1000, 9, 10, v_k, true, v_cap) = -16.00,
    'even 1-point loss should be -16';

  -- A draw ignores the margin entirely and, between equals, moves nothing.
  assert public.elo_delta(1000, 1000, 5, 5, v_k, true, v_cap) = 0.00,
    'even draw should be 0';

  -- ln(11)/ln(2) ≈ 3.46, above the cap, so the blowout clamps at 2.5 * K/2.
  assert public.elo_delta(1000, 1000, 10, 0, v_k, true, v_cap) = 40.00,
    'even blowout should clamp to +40';

  -- With MOV off, margin stops mattering.
  assert public.elo_delta(1000, 1000, 10, 0, v_k, false, v_cap) = 16.00,
    'MOV disabled should ignore the margin';

  -- The favourite winning by 2 gains less than an even player would, both
  -- because expected score is higher and because the damper trims the
  -- multiplier.
  v_delta := public.elo_delta(1200, 1000, 11, 9, v_k, true, v_cap);
  assert abs(v_delta - 11.17) < 0.02,
    format('favourite winning by 2 should be ≈ +11.17, got %s', v_delta);

  -- The underdog winning the same match gains far more.
  v_delta := public.elo_delta(1000, 1200, 11, 9, v_k, true, v_cap);
  assert v_delta > 30, format('underdog win should be large, got %s', v_delta);

  -- Zero-sum in every direction: what one side gains, the other loses.
  assert public.elo_delta(1350, 990, 21, 13, v_k, true, v_cap)
       = -public.elo_delta(990, 1350, 13, 21, v_k, true, v_cap),
    'elo_delta must be antisymmetric';

  raise notice 'elo_delta fixtures OK';
end;
$$;

-- ---------------------------------------------------------------------------
-- Part 2 — demo competition
-- ---------------------------------------------------------------------------

do $$
declare
  v_owner_id  constant uuid := '11111111-1111-1111-1111-111111111111';
  v_friend_id constant uuid := '22222222-2222-2222-2222-222222222222';
  v_comp      public.competitions;
  v_players   uuid[];
  v_season_id uuid;
  v_before    jsonb;
  v_after     jsonb;
  v_result    record;
  v_name      text;
  v_when      timestamptz;
  v_i         integer;
  v_month_offset integer;
begin
  -- Two real accounts. handle_new_user() fills in public.profiles.
  foreach v_name in array array['owner', 'friend'] loop
    insert into auth.users (
      id, instance_id, aud, role, email, encrypted_password,
      email_confirmed_at, created_at, updated_at,
      raw_app_meta_data, raw_user_meta_data, is_anonymous
    )
    values (
      case v_name when 'owner' then v_owner_id else v_friend_id end,
      '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated',
      v_name || '@keepscore.test', '',
      now(), now(), now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      jsonb_build_object('full_name', initcap(v_name)),
      false
    )
    on conflict (id) do nothing;
  end loop;

  -- Act as the owner for the rest of this block, so every RPC below goes
  -- through the same authorisation checks the app will hit.
  perform set_config('request.jwt.claims', json_build_object(
    'sub', v_owner_id, 'role', 'authenticated', 'is_anonymous', false
  )::text, true);

  v_comp := public.create_competition('Office Table Tennis', 'monthly', 'Europe/Amsterdam', 'Marieke');

  -- Four placeholders alongside the owner: exactly the "I'll add my
  -- colleagues myself" flow.
  foreach v_name in array array['Bram', 'Sanne', 'Joost', 'Fleur'] loop
    perform public.add_dummy_player(v_comp.id, v_name);
  end loop;

  -- Deterministic ordering so the assertions below are reproducible.
  select array_agg(id order by created_at, id)
    into v_players
    from public.players where competition_id = v_comp.id;

  -- A spread of shapes: 1v1s, a 2v2, a draw and a blowout, back-dated across
  -- three months so season_history / player_medals / a streak that survives
  -- a season boundary all have something to show, not just the current month.
  for v_month_offset in -2..0 loop
    v_when := date_trunc('month', now()) + (v_month_offset || ' months')::interval
              + interval '2 days';

    for v_i in 1..12 loop
      if v_i % 4 = 0 then
        -- 2v2
        perform public.create_match(
          v_comp.id,
          array[v_players[1], v_players[2]],
          array[v_players[3], v_players[4]],
          21, 15 + (v_i % 5),
          v_when
        );
      elsif v_i % 5 = 0 then
        -- draw
        perform public.create_match(
          v_comp.id,
          array[v_players[2]], array[v_players[5]],
          11, 11, v_when
        );
      else
        perform public.create_match(
          v_comp.id,
          array[v_players[1 + (v_i % 5)]],
          array[v_players[1 + ((v_i + 2) % 5)]],
          21, 21 - (1 + (v_i * 3) % 18),
          v_when
        );
      end if;
      v_when := v_when + interval '19 hours';
    end loop;
  end loop;

  select id into v_season_id
    from public.seasons where competition_id = v_comp.id
   order by starts_at desc limit 1;

  -- Part 3 — incremental vs replayed must agree exactly.
  select jsonb_agg(t order by t->>'player_id') into v_before
    from (
      select to_jsonb(pr) - 'updated_at' as t
        from public.player_ratings pr where season_id = v_season_id
    ) s;

  perform public.recalc_season(v_season_id);

  select jsonb_agg(t order by t->>'player_id') into v_after
    from (
      select to_jsonb(pr) - 'updated_at' as t
        from public.player_ratings pr where season_id = v_season_id
    ) s;

  assert v_before = v_after,
    E'recalc_season diverged from the incremental result.\nbefore: '
    || v_before::text || E'\nafter:  ' || v_after::text;

  -- Ratings are zero-sum, so the field must still average the starting rating.
  select round(avg(rating), 2) as avg_rating, count(*) as n
    into v_result
    from public.player_ratings where season_id = v_season_id;

  assert abs(v_result.avg_rating - v_comp.starting_rating) < 0.5,
    format('ratings should stay zero-sum around %s, got %s',
           v_comp.starting_rating, v_result.avg_rating);

  -- Deleting a mid-season match must leave a consistent season behind.
  declare
    v_victim uuid;
    v_total  numeric;
  begin
    select id into v_victim
      from public.matches where season_id = v_season_id
     order by played_at limit 1 offset 3;

    perform public.delete_match(v_victim);

    select round(avg(rating), 2) into v_total
      from public.player_ratings where season_id = v_season_id;

    assert abs(v_total - v_comp.starting_rating) < 0.5,
      format('after delete + recalc the field should still average %s, got %s',
             v_comp.starting_rating, v_total);
  end;

  -- Part 4 — a guest joins and claims a placeholder.
  perform set_config('request.jwt.claims', json_build_object(
    'sub', v_friend_id, 'role', 'authenticated', 'is_anonymous', true
  )::text, true);

  declare
    v_claimable uuid;
    v_joined    public.players;
    v_denied    boolean := false;
  begin
    select id into v_claimable
      from public.players
     where competition_id = v_comp.id and user_id is null
     order by display_name limit 1;

    v_joined := public.join_competition(v_comp.join_code, 'Friend', v_claimable);
    assert v_joined.id = v_claimable, 'claiming should keep the placeholder row';
    assert v_joined.user_id = v_friend_id, 'claim should attach the guest';

    -- …and a guest still cannot log a match.
    begin
      perform public.create_match(
        v_comp.id, array[v_players[1]], array[v_players[2]], 21, 10, now()
      );
    exception when others then
      v_denied := true;
    end;
    assert v_denied, 'an anonymous user must not be able to create a match';
  end;

  perform set_config('request.jwt.claims', null, true);

  raise notice 'Seeded competition % with join code %', v_comp.name, v_comp.join_code;
end;
$$;
