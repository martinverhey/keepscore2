-- Select only. Every write goes through start_tournament /
-- set_tournament_result / cancel_tournament, which are security definer --
-- the same arrangement matches has.

drop policy if exists tournaments_select_member on public.tournaments;

create policy tournaments_select_member
  on public.tournaments for select to authenticated
  using (public.is_member(competition_id));
