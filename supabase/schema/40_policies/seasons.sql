-- seasons / matches / ratings — read-only to clients
drop policy if exists seasons_select_member on public.seasons;

create policy seasons_select_member
  on public.seasons for select to authenticated
  using (public.is_member(competition_id));
