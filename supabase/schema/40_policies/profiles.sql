drop policy if exists profiles_select_self_or_shared on public.profiles;

create policy profiles_select_self_or_shared
  on public.profiles for select to authenticated
  using (id = auth.uid() or public.shares_competition(id));

drop policy if exists profiles_update_self on public.profiles;

create policy profiles_update_self
  on public.profiles for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());
