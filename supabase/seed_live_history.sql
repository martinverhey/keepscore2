-- One-off, idempotent backfill of season history for the live "Office Table
-- Tennis" demo competition (join code HDHS39), so season_history /
-- player_medals / a season-crossing streak have something to show. There is
-- no local Supabase instance for this project (assets/.env always points at
-- the live ref), so unlike seed.sql this targets the live project directly:
--
--   ./scripts/db.sh -f supabase/seed_live_history.sql
--
-- Safe to re-run: it no-ops once the competition already has more than one
-- season.

do $$
declare
  v_comp      public.competitions;
  v_players   uuid[];
  v_when      timestamptz;
  v_i         integer;
  v_month_offset integer;
begin
  select * into v_comp from public.competitions where join_code = 'HDHS39';
  if not found then
    raise notice 'No competition with join code HDHS39 — nothing to do';
    return;
  end if;

  if (select count(*) from public.seasons where competition_id = v_comp.id) > 1 then
    raise notice 'Office Table Tennis already has season history — skipping';
    return;
  end if;

  select array_agg(id order by created_at, id)
    into v_players
    from public.players where competition_id = v_comp.id;

  if array_length(v_players, 1) < 5 then
    raise notice 'Expected at least 5 players, found %  — skipping', array_length(v_players, 1);
    return;
  end if;

  -- Impersonate the owner, the same way seed.sql does, so this goes through
  -- the same authorisation checks create_match enforces for real clients.
  perform set_config('request.jwt.claims', json_build_object(
    'sub', v_comp.owner_id, 'role', 'authenticated', 'is_anonymous', false
  )::text, true);

  for v_month_offset in -2..-1 loop
    v_when := date_trunc('month', now()) + (v_month_offset || ' months')::interval
              + interval '2 days';

    for v_i in 1..12 loop
      if v_i % 4 = 0 then
        perform public.create_match(
          v_comp.id,
          array[v_players[1], v_players[2]],
          array[v_players[3], v_players[4]],
          21, 15 + (v_i % 5),
          v_when
        );
      elsif v_i % 5 = 0 then
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

  perform set_config('request.jwt.claims', null, true);

  raise notice 'Seeded 2 prior seasons of history for %', v_comp.name;
end;
$$;
