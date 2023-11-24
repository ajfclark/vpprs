--
-- PostgreSQL database dump
--

-- Dumped from database version 15.5 (Debian 15.5-0+deb12u1)
-- Dumped by pg_dump version 15.5 (Debian 15.5-0+deb12u1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: vppr(numeric, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.vppr(place numeric, numplayers numeric) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    maxVppr integer := 50;
BEGIN
    IF numPlayers >= 50 THEN
        IF numPlayers >= 75 THEN
            maxVppr = 100;
        ELSE
            maxVppr = 75;
        END IF;
    END IF;
    IF place=1 THEN
        RETURN maxVppr::numeric;
    ELSE
        RETURN (maxVppr * 0.92 - 1) * (((numPlayers - place + 1) / numPlayers) ^ 2) + 1;
    END IF;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: event; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.event (
    id integer NOT NULL,
    date date NOT NULL,
    ignored boolean DEFAULT false NOT NULL,
    ifpa_id integer,
    matchplay_q_id integer,
    matchplay_f_id integer,
    name text NOT NULL
);


--
-- Name: event_ext; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.event_ext AS
SELECT
    NULL::integer AS id,
    NULL::bigint AS players,
    NULL::numeric AS year;


--
-- Name: event_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.event_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: event_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.event_id_seq OWNED BY public.event.id;


--
-- Name: result; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.result (
    id integer NOT NULL,
    event_id integer NOT NULL,
    place numeric(5,3) NOT NULL,
    player_id integer
);


--
-- Name: event_players; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.event_players AS
 SELECT result.event_id AS id,
    count(result.event_id) AS players
   FROM public.result
  GROUP BY result.event_id;


--
-- Name: event_year; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.event_year AS
 SELECT event.id,
    EXTRACT(year FROM event.date) AS year
   FROM public.event;


--
-- Name: player; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.player (
    id integer NOT NULL,
    ifpa_id numeric,
    name text NOT NULL
);


--
-- Name: player_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.player_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: player_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.player_id_seq OWNED BY public.player.id;


--
-- Name: result_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.result_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: result_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.result_id_seq OWNED BY public.result.id;


--
-- Name: standings; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.standings AS
 SELECT x.year,
    p.name AS player,
    count(r.player_id) AS events,
    count(r.place) FILTER (WHERE (r.place = (1)::numeric)) AS wins,
    avg(public.vppr(r.place, (x.players)::numeric)) AS average,
    sum(public.vppr(r.place, (x.players)::numeric)) AS vpprs
   FROM (((public.player p
     JOIN public.result r ON ((p.id = r.player_id)))
     JOIN public.event e ON ((r.event_id = e.id)))
     JOIN public.event_ext x ON ((r.event_id = x.id)))
  WHERE (e.ignored IS NOT TRUE)
  GROUP BY x.year, p.name
  ORDER BY x.year DESC, (sum(public.vppr(r.place, (x.players)::numeric))) DESC;


--
-- Name: event id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event ALTER COLUMN id SET DEFAULT nextval('public.event_id_seq'::regclass);


--
-- Name: player id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player ALTER COLUMN id SET DEFAULT nextval('public.player_id_seq'::regclass);


--
-- Name: result id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.result ALTER COLUMN id SET DEFAULT nextval('public.result_id_seq'::regclass);


--
-- Name: event event_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event
    ADD CONSTRAINT event_pkey PRIMARY KEY (id);


--
-- Name: player player_ifpa_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player
    ADD CONSTRAINT player_ifpa_id_key UNIQUE (ifpa_id);


--
-- Name: player player_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player
    ADD CONSTRAINT player_pkey PRIMARY KEY (id);


--
-- Name: result result_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.result
    ADD CONSTRAINT result_pkey PRIMARY KEY (id);


--
-- Name: event un_ifpa_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event
    ADD CONSTRAINT un_ifpa_id UNIQUE (ifpa_id);


--
-- Name: event_ext _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.event_ext AS
 SELECT e.id,
    count(r.event_id) AS players,
    EXTRACT(year FROM e.date) AS year
   FROM (public.event e
     JOIN public.result r ON ((e.id = r.event_id)))
  WHERE (e.ignored IS NOT TRUE)
  GROUP BY e.id;


--
-- Name: result fk_event; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.result
    ADD CONSTRAINT fk_event FOREIGN KEY (event_id) REFERENCES public.event(id);


--
-- Name: result fk_player_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.result
    ADD CONSTRAINT fk_player_id FOREIGN KEY (player_id) REFERENCES public.player(id);


--
-- PostgreSQL database dump complete
--

