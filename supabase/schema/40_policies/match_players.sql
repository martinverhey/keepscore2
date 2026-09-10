drop policy if exists match_players_select_member on public.match_players;

create policy match_players_select_member
  on public.match_players for select to authenticated
  using (
    exists (
      select 1 from public.matches m
       where m.id = match_id and public.is_member(m.competition_id)
    )
  );
