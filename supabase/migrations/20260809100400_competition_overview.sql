-- Read model for the competitions list.
--
-- security_invoker keeps the caller's RLS in force, so this returns exactly
-- the competitions the user is a member of — the same rule as the base table,
-- expressed once.

create view public.competition_overview
with (security_invoker = true) as
select
  c.*,
  (select count(*)
     from public.players p
    where p.competition_id = c.id
      and p.is_active)                       as player_count,
  (select count(*)
     from public.matches m
    where m.competition_id = c.id)           as match_count,
  (select max(m.played_at)
     from public.matches m
    where m.competition_id = c.id)           as last_played_at,
  -- Which player row is *me* in this competition. The match form needs it to
  -- preselect the current user, and the roster to mark "you".
  (select p.id
     from public.players p
    where p.competition_id = c.id
      and p.user_id = auth.uid())            as my_player_id
from public.competitions c;

grant select on public.competition_overview to authenticated;
