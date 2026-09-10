drop policy if exists players_select_member on public.players;

create policy players_select_member
  on public.players for select to authenticated
  using (public.is_member(competition_id));

-- Renaming or deactivating a player: the owner for anyone, or a member for
-- their own row. The column grant in 90_grants.sql is what stops user_id
-- being touched.
drop policy if exists players_update_owner_or_self on public.players;

create policy players_update_owner_or_self
  on public.players for update to authenticated
  using (
    public.is_registered()
    and (public.is_owner(competition_id) or user_id = auth.uid())
  )
  with check (
    public.is_owner(competition_id) or user_id = auth.uid()
  );
