drop policy if exists matches_select_member on public.matches;

create policy matches_select_member
  on public.matches for select to authenticated
  using (public.is_member(competition_id));
