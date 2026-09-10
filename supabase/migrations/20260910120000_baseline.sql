-- Squashed baseline for the public schema.
--
-- Structural DDL only: types, tables, constraints, indexes, row-level security,
-- replica identity and the realtime publication. Everything that Postgres can
-- CREATE OR REPLACE — functions, views, triggers, policies — lives in
-- supabase/schema/ and is re-applied wholesale by scripts/db.sh --apply-schema,
-- so this file is not where those are defined or changed.
--
-- It is a squash of migrations 20260809100000 .. 20260907100000, generated from
-- the live project's own catalog, and it is byte-verified against it. Applying
-- it to an empty database reproduces the schema those 32 files built.
--
-- One-time data backfills from those migrations are deliberately NOT replayed
-- here (profiles from auth.users, matches.game_type, match_players.outcome, and
-- two game-type recalc loops whose functions no longer exist). They ran once
-- against real rows; a fresh database has nothing for them to touch.

CREATE TYPE public.game_type AS ENUM (
    '1v1',
    '2v2',
    '3v3',
    '4v4',
    'mixed'
);

CREATE TYPE public.match_outcome AS ENUM (
    'win',
    'loss',
    'draw'
);

CREATE TYPE public.match_team AS ENUM (
    'a',
    'b'
);

CREATE TYPE public.season_length AS ENUM (
    'monthly',
    'quarterly',
    'yearly'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

CREATE TABLE public.players (
    competition_id uuid NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    display_name text NOT NULL,
    user_id uuid,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT players_display_name_check CHECK (((char_length(btrim(display_name)) >= 1) AND (char_length(btrim(display_name)) <= 60)))
);

CREATE TABLE public.competitions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    join_code text NOT NULL,
    name text NOT NULL,
    owner_id uuid NOT NULL,
    season_length public.season_length DEFAULT 'monthly'::public.season_length NOT NULL,
    timezone text DEFAULT 'Europe/Amsterdam'::text NOT NULL,
    starting_rating integer DEFAULT 1000 NOT NULL,
    k_factor integer DEFAULT 32 NOT NULL,
    mov_enabled boolean DEFAULT true NOT NULL,
    mov_cap numeric(4,2) DEFAULT 2.50 NOT NULL,
    allow_draws boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT competitions_join_code_check CHECK ((join_code ~ '^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{6}$'::text)),
    CONSTRAINT competitions_k_factor_check CHECK (((k_factor >= 1) AND (k_factor <= 200))),
    CONSTRAINT competitions_mov_cap_check CHECK (((mov_cap >= 1.00) AND (mov_cap <= 5.00))),
    CONSTRAINT competitions_name_check CHECK (((char_length(btrim(name)) >= 1) AND (char_length(btrim(name)) <= 60))),
    CONSTRAINT competitions_starting_rating_check CHECK (((starting_rating >= 100) AND (starting_rating <= 5000)))
);

CREATE TABLE public.matches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    competition_id uuid NOT NULL,
    season_id uuid NOT NULL,
    played_at timestamp with time zone DEFAULT now() NOT NULL,
    team_a_score integer NOT NULL,
    team_b_score integer NOT NULL,
    team_a_rating numeric(8,2) NOT NULL,
    team_b_rating numeric(8,2) NOT NULL,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    game_type public.game_type NOT NULL,
    CONSTRAINT matches_team_a_score_check CHECK ((team_a_score >= 0)),
    CONSTRAINT matches_team_b_score_check CHECK ((team_b_score >= 0))
);

ALTER TABLE ONLY public.matches REPLICA IDENTITY FULL;

CREATE TABLE public.seasons (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    competition_id uuid NOT NULL,
    starts_at timestamp with time zone NOT NULL,
    ends_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT seasons_check CHECK ((ends_at > starts_at))
);

CREATE TABLE public.player_ratings (
    season_id uuid NOT NULL,
    player_id uuid NOT NULL,
    rating numeric(8,2) NOT NULL,
    played integer DEFAULT 0 NOT NULL,
    wins integer DEFAULT 0 NOT NULL,
    losses integer DEFAULT 0 NOT NULL,
    draws integer DEFAULT 0 NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public.match_players (
    match_id uuid NOT NULL,
    player_id uuid NOT NULL,
    team public.match_team NOT NULL,
    rating_before numeric(8,2) NOT NULL,
    rating_after numeric(8,2) NOT NULL,
    rating_delta numeric(8,2) NOT NULL,
    outcome public.match_outcome NOT NULL
);

CREATE TABLE public.profiles (
    id uuid NOT NULL,
    display_name text NOT NULL,
    avatar_url text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT profiles_display_name_check CHECK (((char_length(btrim(display_name)) >= 1) AND (char_length(btrim(display_name)) <= 60)))
);

ALTER TABLE ONLY public.competitions
    ADD CONSTRAINT competitions_join_code_key UNIQUE (join_code);

ALTER TABLE ONLY public.competitions
    ADD CONSTRAINT competitions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.match_players
    ADD CONSTRAINT match_players_pkey PRIMARY KEY (match_id, player_id);

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.player_ratings
    ADD CONSTRAINT player_ratings_pkey PRIMARY KEY (season_id, player_id);

ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.seasons
    ADD CONSTRAINT seasons_competition_id_starts_at_key UNIQUE (competition_id, starts_at);

ALTER TABLE ONLY public.seasons
    ADD CONSTRAINT seasons_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.competitions
    ADD CONSTRAINT competitions_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.profiles(id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.match_players
    ADD CONSTRAINT match_players_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.match_players
    ADD CONSTRAINT match_players_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.players(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_competition_id_fkey FOREIGN KEY (competition_id) REFERENCES public.competitions(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_season_id_fkey FOREIGN KEY (season_id) REFERENCES public.seasons(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.player_ratings
    ADD CONSTRAINT player_ratings_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.players(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.player_ratings
    ADD CONSTRAINT player_ratings_season_id_fkey FOREIGN KEY (season_id) REFERENCES public.seasons(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_competition_id_fkey FOREIGN KEY (competition_id) REFERENCES public.competitions(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.seasons
    ADD CONSTRAINT seasons_competition_id_fkey FOREIGN KEY (competition_id) REFERENCES public.competitions(id) ON DELETE CASCADE;

CREATE INDEX match_players_player_idx ON public.match_players USING btree (player_id);

CREATE INDEX matches_competition_played_idx ON public.matches USING btree (competition_id, played_at DESC, id DESC);

CREATE INDEX matches_season_played_idx ON public.matches USING btree (season_id, played_at, id);

CREATE INDEX player_ratings_leaderboard_idx ON public.player_ratings USING btree (season_id, rating DESC);

CREATE UNIQUE INDEX players_competition_id_display_name_key ON public.players USING btree (competition_id, lower(btrim(display_name)));

CREATE INDEX players_competition_idx ON public.players USING btree (competition_id);

CREATE UNIQUE INDEX players_competition_user_key ON public.players USING btree (competition_id, user_id) WHERE (user_id IS NOT NULL);

CREATE INDEX players_user_idx ON public.players USING btree (user_id) WHERE (user_id IS NOT NULL);

CREATE INDEX seasons_competition_range_idx ON public.seasons USING btree (competition_id, starts_at DESC);

ALTER TABLE public.competitions ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.match_players ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.player_ratings ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.players ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.seasons ENABLE ROW LEVEL SECURITY;

COMMENT ON COLUMN public.competitions.join_code IS 'Six characters from a Crockford-style alphabet — no 0/O/1/I — so a code read aloud is unambiguous.';

COMMENT ON TABLE public.profiles IS 'One row per auth user, created automatically on sign-up.';

alter publication supabase_realtime add table public.matches;
alter publication supabase_realtime add table public.player_ratings;
alter publication supabase_realtime add table public.players;
