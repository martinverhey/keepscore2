-- Everything about one competition, as the app sees it.
--
--   scripts/local-db.sh comp HDHS39
--   scripts/local-db.sh psql -v code=HDHS39 -f supabase/inspect/competition.sql
--
-- The set_config line is what makes this work. public.leaderboard calls
-- player_streak and player_today_delta, both of which check membership through
-- auth.uid(), so a plain superuser session gets "You are not in this
-- competition" rather than rows. Impersonating any claimed member of this
-- competition is enough — the view returns the whole ladder, not just them.

\set QUIET on
select set_config('request.jwt.claim.sub',
  (select p.user_id::text
     from public.players p
     join public.competitions c on c.id = p.competition_id
    where c.join_code = :'code' and p.user_id is not null
    limit 1), false) \gset
\set QUIET off

\echo ''
\echo '── competition ──────────────────────────────────────────────'
select c.name, c.join_code, c.season_length, c.timezone,
       c.starting_rating, c.k_factor, c.mov_enabled, c.mov_cap, c.allow_draws,
       pr.display_name as owner
  from public.competitions c
  left join public.profiles pr on pr.id = c.owner_id
 where c.join_code = :'code' \gx

\echo '── seasons (most recent first) ──────────────────────────────'
-- ends_at is exclusive, and both bounds are midnight in the competition's
-- timezone, so the raw dates read a day/month wide. The app labels a season
-- off its midpoint for exactly this reason; the -1 day here is the same trick.
select s.starts_at::date as starts,
       (s.ends_at - interval '1 day')::date as ends_inclusive,
       count(m.id) as matches,
       (now() >= s.starts_at and now() < s.ends_at) as is_current,
       s.id as season_id
  from public.competitions c
  join public.seasons s on s.competition_id = c.id
  left join public.matches m on m.season_id = s.id
 where c.join_code = :'code'
 group by s.id, s.starts_at, s.ends_at
 order by s.starts_at desc;

\echo '── leaderboard, latest season that has matches ──────────────'
select l.rank, l.display_name, l.rating::int as rating,
       l.played, l.wins, l.losses, l.draws,
       l.streak_type, l.streak_count, l.today_delta::int as today,
       l.is_claimed, l.is_owner
  from public.leaderboard l
  join public.competitions c on c.id = l.competition_id
 where c.join_code = :'code'
   and l.season_id = (select s.id
                        from public.seasons s
                        join public.matches m on m.season_id = s.id
                       where s.competition_id = c.id
                       group by s.id, s.starts_at
                       order by s.starts_at desc
                       limit 1)
 order by l.rank;

\echo '── last 10 matches ──────────────────────────────────────────'
select f.played_at::date as played, f.game_type,
       (select string_agg(x->>'display_name', ' + ')
          from jsonb_array_elements(f.team_a) x) as team_a,
       f.team_a_score || ' – ' || f.team_b_score as score,
       (select string_agg(x->>'display_name', ' + ')
          from jsonb_array_elements(f.team_b) x) as team_b
  from public.match_feed f
  join public.competitions c on c.id = f.competition_id
 where c.join_code = :'code'
 order by f.played_at desc, f.id desc
 limit 10;
