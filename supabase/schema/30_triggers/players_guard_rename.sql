drop trigger if exists players_guard_rename on players;

create trigger players_guard_rename
  before update on public.players
  for each row
  execute function public.guard_player_rename();
