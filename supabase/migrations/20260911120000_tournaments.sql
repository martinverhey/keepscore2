-- Tournaments — a single-elimination bracket over players already on the
-- roster. Deliberately a track of its own: nothing here writes matches,
-- match_players or player_ratings, so a bracket result never moves an Elo
-- rating and never reaches the Matches feed.

create type public.tournament_status as enum ('active', 'completed');

create table public.tournaments (
    id uuid default gen_random_uuid() not null,
    competition_id uuid not null,
    season_id uuid not null,
    size integer not null,
    status public.tournament_status default 'active'::public.tournament_status not null,
    winner_player_id uuid,
    created_by uuid,
    created_at timestamp with time zone default now() not null,
    completed_at timestamp with time zone,
    constraint tournaments_size_check check ((size = ANY (ARRAY[2, 4, 8, 16])))
);

create table public.tournament_matches (
    id uuid default gen_random_uuid() not null,
    tournament_id uuid not null,
    round integer not null,
    slot integer not null,
    player_a_id uuid,
    player_b_id uuid,
    score_a integer,
    score_b integer,
    winner_player_id uuid,
    played_at timestamp with time zone,
    constraint tournament_matches_round_check check ((round >= 1)),
    constraint tournament_matches_slot_check check ((slot >= 0)),
    constraint tournament_matches_score_a_check check (((score_a is null) or (score_a >= 0))),
    constraint tournament_matches_score_b_check check (((score_b is null) or (score_b >= 0)))
);

alter table only public.tournaments
    add constraint tournaments_pkey primary key (id);

alter table only public.tournament_matches
    add constraint tournament_matches_pkey primary key (id);

alter table only public.tournaments
    add constraint tournaments_competition_id_fkey
    foreign key (competition_id) references public.competitions(id) on delete cascade;

alter table only public.tournaments
    add constraint tournaments_season_id_fkey
    foreign key (season_id) references public.seasons(id) on delete cascade;

alter table only public.tournaments
    add constraint tournaments_winner_player_id_fkey
    foreign key (winner_player_id) references public.players(id) on delete set null;

alter table only public.tournament_matches
    add constraint tournament_matches_tournament_id_fkey
    foreign key (tournament_id) references public.tournaments(id) on delete cascade;

alter table only public.tournament_matches
    add constraint tournament_matches_player_a_id_fkey
    foreign key (player_a_id) references public.players(id) on delete set null;

alter table only public.tournament_matches
    add constraint tournament_matches_player_b_id_fkey
    foreign key (player_b_id) references public.players(id) on delete set null;

alter table only public.tournament_matches
    add constraint tournament_matches_position_key unique (tournament_id, round, slot);

-- One running tournament per competition. start_tournament checks this too,
-- with a readable message; the index is what makes two concurrent calls
-- unable to both win.
create unique index tournaments_one_active_per_competition
    on public.tournaments (competition_id)
    where (status = 'active'::public.tournament_status);

create index tournaments_competition_id_idx on public.tournaments (competition_id);
create index tournaments_season_winner_idx
    on public.tournaments (season_id, winner_player_id)
    where (status = 'completed'::public.tournament_status);
create index tournament_matches_tournament_id_idx
    on public.tournament_matches (tournament_id);

-- Realtime delivers only the primary key in a delete payload under the default
-- replica identity, so a cancelled tournament would reach subscribers with no
-- competition_id to filter on. Same reason matches carries this.
alter table only public.tournaments replica identity full;
alter table only public.tournament_matches replica identity full;

alter table public.tournaments enable row level security;
alter table public.tournament_matches enable row level security;

alter publication supabase_realtime add table public.tournaments;
alter publication supabase_realtime add table public.tournament_matches;
