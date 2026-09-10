drop policy if exists player_ratings_select_member on public.player_ratings;

create policy player_ratings_select_member
  on public.player_ratings for select to authenticated
  using (
    exists (
      select 1 from public.seasons s
       where s.id = season_id and public.is_member(s.competition_id)
    )
  );
