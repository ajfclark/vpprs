--
-- PostgreSQL database dump
--

-- Dumped from database version 15.3 (Debian 15.3-0+deb12u1)
-- Dumped by pg_dump version 15.3 (Debian 15.3-0+deb12u1)

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
    ifpa_id integer,
    matchplay_q_id integer,
    matchplay_f_id integer,
    name text NOT NULL,
    ignored boolean
);


ALTER TABLE public.event OWNER TO vppr_cli;

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
    player text NOT NULL
);


ALTER TABLE public.result OWNER TO vppr_cli;

--
-- Name: event_players; Type: VIEW; Schema: public; Owner: vppr_cli
--

CREATE VIEW public.event_players AS
 SELECT r.event_id AS id,
    count(r.event_id) AS players,
    EXTRACT(year FROM e.date) AS year
   FROM public.result r,
    public.event e
  WHERE (r.event_id = e.id)
  GROUP BY r.event_id, (EXTRACT(year FROM e.date));


ALTER TABLE public.event_players OWNER TO vppr_cli;

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
-- Name: standings; Type: VIEW; Schema: public; Owner: vppr_cli
--

CREATE VIEW public.standings AS
 SELECT r.player,
    count(r.player) AS events,
    count(r.place) FILTER (WHERE (r.place = (1)::numeric)) AS wins,
    avg(public.vppr(r.place, (p.players)::numeric)) AS average,
    sum(public.vppr(r.place, (p.players)::numeric)) AS vpprs
   FROM (public.result r
     JOIN ( SELECT result.event_id,
            count(result.event_id) AS players
           FROM public.result
          GROUP BY result.event_id) p ON ((r.event_id = p.event_id)))
  GROUP BY r.player
  ORDER BY (sum(public.vppr(r.place, (p.players)::numeric))) DESC;


ALTER TABLE public.standings OWNER TO vppr_cli;

--
-- Name: event id; Type: DEFAULT; Schema: public; Owner: vppr_cli
--

ALTER TABLE ONLY public.event ALTER COLUMN id SET DEFAULT nextval('public.event_id_seq'::regclass);


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
-- Name: result fk_event; Type: FK CONSTRAINT; Schema: public; Owner: vppr_cli
--

ALTER TABLE ONLY public.result
    ADD CONSTRAINT fk_event FOREIGN KEY (event_id) REFERENCES public.event(id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO vppr_cli;


--
-- Name: TABLE event; Type: ACL; Schema: public; Owner: vppr_cli
--

GRANT SELECT ON TABLE public.event TO vppr_web;


--
-- Name: TABLE result; Type: ACL; Schema: public; Owner: vppr_cli
--

GRANT SELECT ON TABLE public.result TO vppr_web;


--
-- Name: TABLE event_players; Type: ACL; Schema: public; Owner: vppr_cli
--

GRANT SELECT ON TABLE public.event_players TO vppr_web;


--
-- Name: TABLE standings; Type: ACL; Schema: public; Owner: vppr_cli
--

GRANT SELECT ON TABLE public.standings TO vppr_web;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: vppr_cli
--

ALTER DEFAULT PRIVILEGES FOR ROLE vppr_cli IN SCHEMA public GRANT SELECT ON SEQUENCES  TO vppr_web;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: vppr_cli
--

ALTER DEFAULT PRIVILEGES FOR ROLE vppr_cli IN SCHEMA public GRANT SELECT ON TABLES  TO vppr_web;


--
-- PostgreSQL database dump complete
--

