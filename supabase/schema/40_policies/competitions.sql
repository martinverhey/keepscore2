drop policy if exists competitions_delete_owner on public.competitions;

create policy competitions_delete_owner
  on public.competitions for delete to authenticated
  using (owner_id = auth.uid() and public.is_registered());

drop policy if exists competitions_select_member on public.competitions;

create policy competitions_select_member
  on public.competitions for select to authenticated
  using (public.is_member(id));

drop policy if exists competitions_update_owner on public.competitions;

create policy competitions_update_owner
  on public.competitions for update to authenticated
  using (owner_id = auth.uid() and public.is_registered())
  with check (owner_id = auth.uid());
