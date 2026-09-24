drop policy if exists tournament_matches_select_member on public.tournament_matches;

create policy tournament_matches_select_member
  on public.tournament_matches for select to authenticated
  using (
    exists (
      select 1
        from public.tournaments t
       where t.id = tournament_id
         and public.is_member(t.competition_id)
    )
  );
