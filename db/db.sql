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


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: event; Type: TABLE; Schema: public; Owner: vppr_cli
--

CREATE TABLE public.event (
    id serial primary key,
    date date NOT NULL,
    ignored boolean,
    ifpa_id integer,
    matchplay_q_id integer,
    matchplay_f_id integer,
    name text NOT NULL
);


--
-- Name: result; Type: TABLE; Schema: public; Owner: vppr_cli
--

CREATE TABLE public.result (
    id serial primary key,
    event_id integer NOT NULL,
    place numeric(5,3) NOT NULL,
    player text NOT NULL
);


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

