--
-- PostgreSQL database dump
--

-- Dumped from database version 15.6 (Debian 15.6-0+deb12u1)
-- Dumped by pg_dump version 15.6 (Debian 15.6-0+deb12u1)

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
-- Name: vppr(numeric, numeric); Type: FUNCTION; Schema: public; Owner: vppr_cli
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


ALTER FUNCTION public.vppr(place numeric, numplayers numeric) OWNER TO vppr_cli;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: event; Type: TABLE; Schema: public; Owner: vppr_cli
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


ALTER TABLE public.event OWNER TO vppr_cli;

--
-- Name: event_ext; Type: VIEW; Schema: public; Owner: vppr_cli
--

CREATE VIEW public.event_ext AS
SELECT
    NULL::integer AS id,
    NULL::bigint AS players,
    NULL::numeric AS year,
    NULL::numeric AS month;


ALTER TABLE public.event_ext OWNER TO vppr_cli;

--
-- Name: event_id_seq; Type: SEQUENCE; Schema: public; Owner: vppr_cli
--

CREATE SEQUENCE public.event_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.event_id_seq OWNER TO vppr_cli;

--
-- Name: event_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vppr_cli
--

ALTER SEQUENCE public.event_id_seq OWNED BY public.event.id;


--
-- Name: result; Type: TABLE; Schema: public; Owner: vppr_cli
--

CREATE TABLE public.result (
    id integer NOT NULL,
    event_id integer NOT NULL,
    place numeric(5,3) NOT NULL,
    player_id integer
);


ALTER TABLE public.result OWNER TO vppr_cli;

--
-- Name: event_players; Type: VIEW; Schema: public; Owner: vppr_cli
--

CREATE VIEW public.event_players AS
 SELECT result.event_id AS id,
    count(result.event_id) AS players
   FROM public.result
  GROUP BY result.event_id;


ALTER TABLE public.event_players OWNER TO vppr_cli;

--
-- Name: event_year; Type: VIEW; Schema: public; Owner: vppr_cli
--

CREATE VIEW public.event_year AS
 SELECT event.id,
    EXTRACT(year FROM event.date) AS year
   FROM public.event;


ALTER TABLE public.event_year OWNER TO vppr_cli;

--
-- Name: player; Type: TABLE; Schema: public; Owner: vppr_cli
--

CREATE TABLE public.player (
    id integer NOT NULL,
    ifpa_id numeric,
    name text NOT NULL
);


ALTER TABLE public.player OWNER TO vppr_cli;

--
-- Name: mdstandings; Type: VIEW; Schema: public; Owner: vppr_cli
--

CREATE VIEW public.mdstandings AS
 SELECT x.year,
    p.id AS playerid,
    p.name AS player,
    count(r.player_id) AS events,
    count(r.place) FILTER (WHERE (r.place = (1)::numeric)) AS wins,
    avg(public.vppr(r.place, (x.players)::numeric)) AS average,
    sum(public.vppr(r.place, (x.players)::numeric)) AS vpprs
   FROM (((public.player p
     JOIN public.result r ON ((p.id = r.player_id)))
     JOIN public.event e ON ((r.event_id = e.id)))
     JOIN public.event_ext x ON ((r.event_id = x.id)))
  WHERE ((e.ignored IS NOT TRUE) AND (x.month <> (12)::numeric) AND (e.name ~~ '%Moon Dog%'::text))
  GROUP BY x.year, p.id, p.name
  ORDER BY x.year DESC, (sum(public.vppr(r.place, (x.players)::numeric))) DESC;


ALTER TABLE public.mdstandings OWNER TO vppr_cli;

--
-- Name: player_id_seq; Type: SEQUENCE; Schema: public; Owner: vppr_cli
--

CREATE SEQUENCE public.player_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.player_id_seq OWNER TO vppr_cli;

--
-- Name: player_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vppr_cli
--

ALTER SEQUENCE public.player_id_seq OWNED BY public.player.id;


--
-- Name: result_id_seq; Type: SEQUENCE; Schema: public; Owner: vppr_cli
--

CREATE SEQUENCE public.result_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.result_id_seq OWNER TO vppr_cli;

--
-- Name: result_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vppr_cli
--

ALTER SEQUENCE public.result_id_seq OWNED BY public.result.id;


--
-- Name: seconds; Type: VIEW; Schema: public; Owner: vppr_cli
--

CREATE VIEW public.seconds AS
 SELECT x.year,
    p.name,
    count(p.name) AS count
   FROM public.result r,
    public.event_ext x,
    public.player p
  WHERE ((r.event_id = x.id) AND (r.player_id = p.id) AND (r.place = (2)::numeric))
  GROUP BY x.year, p.name
  ORDER BY x.year DESC, (count(p.name)) DESC;


ALTER TABLE public.seconds OWNER TO vppr_cli;

--
-- Name: standings; Type: VIEW; Schema: public; Owner: vppr_cli
--

CREATE VIEW public.standings AS
 SELECT x.year,
    p.id AS playerid,
    p.name AS player,
    count(r.player_id) AS events,
    count(r.place) FILTER (WHERE (r.place = (1)::numeric)) AS wins,
    avg(public.vppr(r.place, (x.players)::numeric)) AS average,
    sum(public.vppr(r.place, (x.players)::numeric)) AS vpprs
   FROM (((public.player p
     JOIN public.result r ON ((p.id = r.player_id)))
     JOIN public.event e ON ((r.event_id = e.id)))
     JOIN public.event_ext x ON ((r.event_id = x.id)))
  WHERE ((e.ignored IS NOT TRUE) AND (x.month <> (12)::numeric))
  GROUP BY x.year, p.id, p.name
  ORDER BY x.year DESC, (sum(public.vppr(r.place, (x.players)::numeric))) DESC;


ALTER TABLE public.standings OWNER TO vppr_cli;

--
-- Name: event id; Type: DEFAULT; Schema: public; Owner: vppr_cli
--

ALTER TABLE ONLY public.event ALTER COLUMN id SET DEFAULT nextval('public.event_id_seq'::regclass);


--
-- Name: player id; Type: DEFAULT; Schema: public; Owner: vppr_cli
--

ALTER TABLE ONLY public.player ALTER COLUMN id SET DEFAULT nextval('public.player_id_seq'::regclass);


--
-- Name: result id; Type: DEFAULT; Schema: public; Owner: vppr_cli
--

ALTER TABLE ONLY public.result ALTER COLUMN id SET DEFAULT nextval('public.result_id_seq'::regclass);


--
-- Name: event event_pkey; Type: CONSTRAINT; Schema: public; Owner: vppr_cli
--

ALTER TABLE ONLY public.event
    ADD CONSTRAINT event_pkey PRIMARY KEY (id);


--
-- Name: player player_ifpa_id_key; Type: CONSTRAINT; Schema: public; Owner: vppr_cli
--

ALTER TABLE ONLY public.player
    ADD CONSTRAINT player_ifpa_id_key UNIQUE (ifpa_id);


--
-- Name: player player_pkey; Type: CONSTRAINT; Schema: public; Owner: vppr_cli
--

ALTER TABLE ONLY public.player
    ADD CONSTRAINT player_pkey PRIMARY KEY (id);


--
-- Name: result result_pkey; Type: CONSTRAINT; Schema: public; Owner: vppr_cli
--

ALTER TABLE ONLY public.result
    ADD CONSTRAINT result_pkey PRIMARY KEY (id);


--
-- Name: event un_ifpa_id; Type: CONSTRAINT; Schema: public; Owner: vppr_cli
--

ALTER TABLE ONLY public.event
    ADD CONSTRAINT un_ifpa_id UNIQUE (ifpa_id);


--
-- Name: event_ext _RETURN; Type: RULE; Schema: public; Owner: vppr_cli
--

CREATE OR REPLACE VIEW public.event_ext AS
 SELECT e.id,
    count(r.event_id) AS players,
    EXTRACT(year FROM e.date) AS year,
    EXTRACT(month FROM e.date) AS month
   FROM (public.event e
     JOIN public.result r ON ((e.id = r.event_id)))
  WHERE (e.ignored IS NOT TRUE)
  GROUP BY e.id;


--
-- Name: result fk_event; Type: FK CONSTRAINT; Schema: public; Owner: vppr_cli
--

ALTER TABLE ONLY public.result
    ADD CONSTRAINT fk_event FOREIGN KEY (event_id) REFERENCES public.event(id);


--
-- Name: result fk_player_id; Type: FK CONSTRAINT; Schema: public; Owner: vppr_cli
--

ALTER TABLE ONLY public.result
    ADD CONSTRAINT fk_player_id FOREIGN KEY (player_id) REFERENCES public.player(id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO aclark;


--
-- Name: TABLE event; Type: ACL; Schema: public; Owner: vppr_cli
--

GRANT SELECT ON TABLE public.event TO vppr_web;
GRANT ALL ON TABLE public.event TO aclark;


--
-- Name: TABLE event_ext; Type: ACL; Schema: public; Owner: vppr_cli
--

GRANT SELECT ON TABLE public.event_ext TO vppr_web;


--
-- Name: SEQUENCE event_id_seq; Type: ACL; Schema: public; Owner: vppr_cli
--

GRANT SELECT ON SEQUENCE public.event_id_seq TO vppr_web;
GRANT ALL ON SEQUENCE public.event_id_seq TO aclark;


--
-- Name: TABLE result; Type: ACL; Schema: public; Owner: vppr_cli
--

GRANT SELECT ON TABLE public.result TO vppr_web;
GRANT ALL ON TABLE public.result TO aclark;


--
-- Name: TABLE player; Type: ACL; Schema: public; Owner: vppr_cli
--

GRANT SELECT ON TABLE public.player TO vppr_web;


--
-- Name: TABLE mdstandings; Type: ACL; Schema: public; Owner: vppr_cli
--

GRANT SELECT ON TABLE public.mdstandings TO vppr_web;


--
-- Name: SEQUENCE result_id_seq; Type: ACL; Schema: public; Owner: vppr_cli
--

GRANT SELECT ON SEQUENCE public.result_id_seq TO vppr_web;
GRANT ALL ON SEQUENCE public.result_id_seq TO aclark;


--
-- Name: TABLE standings; Type: ACL; Schema: public; Owner: vppr_cli
--

GRANT SELECT ON TABLE public.standings TO vppr_web;


--
-- PostgreSQL database dump complete
--

