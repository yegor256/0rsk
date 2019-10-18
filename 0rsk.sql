--
-- PostgreSQL database dump
--

-- Dumped from database version 11.5 (Ubuntu 11.5-1.pgdg16.04+1)
-- Dumped by pg_dump version 11.5

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
-- Name: ptype; Type: TYPE; Schema: public; Owner: amtiotumrffdbe
--

CREATE TYPE public.ptype AS ENUM (
    'Cause',
    'Risk',
    'Effect',
    'Plan'
);


ALTER TYPE public.ptype OWNER TO amtiotumrffdbe;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: cause; Type: TABLE; Schema: public; Owner: amtiotumrffdbe
--

CREATE TABLE public.cause (
    id integer NOT NULL,
    emoji character(1) DEFAULT '💾'::bpchar NOT NULL
);


ALTER TABLE public.cause OWNER TO amtiotumrffdbe;

--
-- Name: databasechangelog; Type: TABLE; Schema: public; Owner: amtiotumrffdbe
--

CREATE TABLE public.databasechangelog (
    id character varying(255) NOT NULL,
    author character varying(255) NOT NULL,
    filename character varying(255) NOT NULL,
    dateexecuted timestamp without time zone NOT NULL,
    orderexecuted integer NOT NULL,
    exectype character varying(10) NOT NULL,
    md5sum character varying(35),
    description character varying(255),
    comments character varying(255),
    tag character varying(255),
    liquibase character varying(20)
);


ALTER TABLE public.databasechangelog OWNER TO amtiotumrffdbe;

--
-- Name: databasechangeloglock; Type: TABLE; Schema: public; Owner: amtiotumrffdbe
--

CREATE TABLE public.databasechangeloglock (
    id integer NOT NULL,
    locked boolean NOT NULL,
    lockgranted timestamp without time zone,
    lockedby character varying(255)
);


ALTER TABLE public.databasechangeloglock OWNER TO amtiotumrffdbe;

--
-- Name: effect; Type: TABLE; Schema: public; Owner: amtiotumrffdbe
--

CREATE TABLE public.effect (
    id integer NOT NULL,
    impact integer DEFAULT 4 NOT NULL,
    positive boolean DEFAULT false NOT NULL,
    CONSTRAINT effect_impact_check CHECK ((impact >= 1)),
    CONSTRAINT effect_impact_check1 CHECK ((impact <= 9))
);


ALTER TABLE public.effect OWNER TO amtiotumrffdbe;

--
-- Name: part; Type: TABLE; Schema: public; Owner: amtiotumrffdbe
--

CREATE TABLE public.part (
    id integer NOT NULL,
    project integer NOT NULL,
    type public.ptype NOT NULL,
    text character varying(160) NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT part_text_check CHECK (((text)::text <> ''::text))
);


ALTER TABLE public.part OWNER TO amtiotumrffdbe;

--
-- Name: part_id_seq; Type: SEQUENCE; Schema: public; Owner: amtiotumrffdbe
--

CREATE SEQUENCE public.part_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.part_id_seq OWNER TO amtiotumrffdbe;

--
-- Name: part_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: amtiotumrffdbe
--

ALTER SEQUENCE public.part_id_seq OWNED BY public.part.id;


--
-- Name: plan; Type: TABLE; Schema: public; Owner: amtiotumrffdbe
--

CREATE TABLE public.plan (
    id integer NOT NULL,
    part integer NOT NULL,
    schedule character varying(32) DEFAULT 'weekly'::character varying NOT NULL,
    completed timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT plan_schedule_check CHECK (((schedule)::text <> ''::text))
);


ALTER TABLE public.plan OWNER TO amtiotumrffdbe;

--
-- Name: project; Type: TABLE; Schema: public; Owner: amtiotumrffdbe
--

CREATE TABLE public.project (
    id integer NOT NULL,
    login character varying(64) NOT NULL,
    title character varying(64) NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.project OWNER TO amtiotumrffdbe;

--
-- Name: project_id_seq; Type: SEQUENCE; Schema: public; Owner: amtiotumrffdbe
--

CREATE SEQUENCE public.project_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.project_id_seq OWNER TO amtiotumrffdbe;

--
-- Name: project_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: amtiotumrffdbe
--

ALTER SEQUENCE public.project_id_seq OWNED BY public.project.id;


--
-- Name: risk; Type: TABLE; Schema: public; Owner: amtiotumrffdbe
--

CREATE TABLE public.risk (
    id integer NOT NULL,
    probability integer DEFAULT 4 NOT NULL,
    CONSTRAINT risk_probability_check CHECK ((probability >= 1)),
    CONSTRAINT risk_probability_check1 CHECK ((probability <= 9))
);


ALTER TABLE public.risk OWNER TO amtiotumrffdbe;

--
-- Name: task; Type: TABLE; Schema: public; Owner: amtiotumrffdbe
--

CREATE TABLE public.task (
    id integer NOT NULL,
    plan integer NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.task OWNER TO amtiotumrffdbe;

--
-- Name: task_id_seq; Type: SEQUENCE; Schema: public; Owner: amtiotumrffdbe
--

CREATE SEQUENCE public.task_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.task_id_seq OWNER TO amtiotumrffdbe;

--
-- Name: task_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: amtiotumrffdbe
--

ALTER SEQUENCE public.task_id_seq OWNED BY public.task.id;


--
-- Name: telechat; Type: TABLE; Schema: public; Owner: amtiotumrffdbe
--

CREATE TABLE public.telechat (
    id integer NOT NULL,
    login character varying(64) NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    recent text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.telechat OWNER TO amtiotumrffdbe;

--
-- Name: telechat_id_seq; Type: SEQUENCE; Schema: public; Owner: amtiotumrffdbe
--

CREATE SEQUENCE public.telechat_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.telechat_id_seq OWNER TO amtiotumrffdbe;

--
-- Name: telechat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: amtiotumrffdbe
--

ALTER SEQUENCE public.telechat_id_seq OWNED BY public.telechat.id;


--
-- Name: teleping; Type: TABLE; Schema: public; Owner: amtiotumrffdbe
--

CREATE TABLE public.teleping (
    id integer NOT NULL,
    task integer NOT NULL,
    telechat integer NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.teleping OWNER TO amtiotumrffdbe;

--
-- Name: teleping_id_seq; Type: SEQUENCE; Schema: public; Owner: amtiotumrffdbe
--

CREATE SEQUENCE public.teleping_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.teleping_id_seq OWNER TO amtiotumrffdbe;

--
-- Name: teleping_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: amtiotumrffdbe
--

ALTER SEQUENCE public.teleping_id_seq OWNED BY public.teleping.id;


--
-- Name: triple; Type: TABLE; Schema: public; Owner: amtiotumrffdbe
--

CREATE TABLE public.triple (
    id integer NOT NULL,
    cause integer NOT NULL,
    risk integer NOT NULL,
    effect integer NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.triple OWNER TO amtiotumrffdbe;

--
-- Name: triple_id_seq; Type: SEQUENCE; Schema: public; Owner: amtiotumrffdbe
--

CREATE SEQUENCE public.triple_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.triple_id_seq OWNER TO amtiotumrffdbe;

--
-- Name: triple_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: amtiotumrffdbe
--

ALTER SEQUENCE public.triple_id_seq OWNED BY public.triple.id;


--
-- Name: part id; Type: DEFAULT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.part ALTER COLUMN id SET DEFAULT nextval('public.part_id_seq'::regclass);


--
-- Name: project id; Type: DEFAULT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.project ALTER COLUMN id SET DEFAULT nextval('public.project_id_seq'::regclass);


--
-- Name: task id; Type: DEFAULT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.task ALTER COLUMN id SET DEFAULT nextval('public.task_id_seq'::regclass);


--
-- Name: telechat id; Type: DEFAULT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.telechat ALTER COLUMN id SET DEFAULT nextval('public.telechat_id_seq'::regclass);


--
-- Name: teleping id; Type: DEFAULT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.teleping ALTER COLUMN id SET DEFAULT nextval('public.teleping_id_seq'::regclass);


--
-- Name: triple id; Type: DEFAULT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.triple ALTER COLUMN id SET DEFAULT nextval('public.triple_id_seq'::regclass);


--
-- Data for Name: cause; Type: TABLE DATA; Schema: public; Owner: amtiotumrffdbe
--

COPY public.cause (id, emoji) FROM stdin;
249	💾
385	💾
389	💾
444	💾
536	📦
79	💰
115	💰
4	💰
500	💰
76	💰
504	💰
131	💰
89	💰
255	🤵
370	🌿
191	🌿
528	📦
109	🌿
690	🤵
134	🌿
353	🌿
540	📦
489	🌿
599	9
378	🌿
418	🌿
587	9
139	🌿
97	🌿
184	🌿
356	🌿
127	🌿
741	🤵
322	🌿
361	🌿
611	💰
347	🌿
344	🌿
167	🌿
286	🌿
313	🌿
421	🌿
112	🌿
334	🌿
336	🌿
358	🌿
271	🌿
376	🌿
325	🌿
106	🌿
318	🌿
615	💰
619	💰
103	🌿
341	🌿
350	🌿
367	🌿
405	🌿
329	🌿
331	🌿
339	🌿
265	🌿
397	🍅
461	🍅
171	🍅
178	🍅
174	🍅
146	🍅
160	🌿
485	🏢
481	🏢
59	🏢
53	🏢
82	🏢
22	🏢
229	🏢
62	📦
17	🏢
41	🏢
623	💰
14	🏢
122	🐒
65	🍋
626	2
454	🌾
157	📚
556	📚
118	🐒
238	🌾
28	🐷
150	🌿
56	📦
1	🏢
290	🏢
211	🌾
465	💰
630	💰
562	🍅
565	🌿
569	🌿
300	🌿
294	🌿
316	🌿
364	🌿
374	🌿
415	🌿
308	🌿
515	🌿
411	🌿
575	🌾
427	🌿
578	💰
723	🏢
695	🤵
220	🌿
596	1
637	💰
641	💾
644	📦
650	💰
653	💾
703	🤵
50	🏢
199	🌿
666	💾
31	💰
100	🌿
670	💰
678	💾
754	💰
684	💾
757	💰
713	💰
719	💰
9	📦
758	🤵
727	🌿
730	🌿
733	🤵
761	💰
764	💰
767	💰
381	📦
769	🌿
771	🌿
777	💰
782	💰
796	💰
833	💰
836	9
846	💰
857	💰
861	💰
865	💰
873	💾
\.


--
-- Data for Name: databasechangelog; Type: TABLE DATA; Schema: public; Owner: amtiotumrffdbe
--

COPY public.databasechangelog (id, author, filename, dateexecuted, orderexecuted, exectype, md5sum, description, comments, tag, liquibase) FROM stdin;
001	yegor256	001-initial-schema.xml	2019-04-16 13:41:33.363661	1	EXECUTED	7:689f3b348b6e0e26605fa0594af9dc1e	sql (x8)		\N	3.2.2
002	yegor256	001-initial-schema.xml	2019-04-17 10:04:46.09696	2	EXECUTED	7:51fdd0df83ff26b0e7a2a749eb0ec35b	sql		\N	3.2.2
003	yegor256	001-initial-schema.xml	2019-04-29 14:10:17.369312	3	EXECUTED	7:f2f87925ddf0be6468934b2bbe168593	sql (x2)		\N	3.2.2
004	yegor256	001-initial-schema.xml	2019-04-29 14:10:20.185029	4	EXECUTED	7:85cd311ea6f40deea6c7fe4f4adf2a96	sql (x8)		\N	3.2.2
005	yegor256	001-initial-schema.xml	2019-04-30 05:12:01.717844	5	EXECUTED	7:ebca10bff291c1e60979d89c1cc17a46	sql		\N	3.2.2
006	yegor256	001-initial-schema.xml	2019-04-30 05:12:02.489339	6	EXECUTED	7:e1081e929cbbd0249cc2493b216b61c9	sql (x2)		\N	3.2.2
007	yegor256	001-initial-schema.xml	2019-04-30 08:50:30.229208	7	EXECUTED	7:aaa3b2e7b7963e90703b0ea55cf795da	sql		\N	3.2.2
008	yegor256	001-initial-schema.xml	2019-05-01 06:25:49.275967	8	EXECUTED	7:206e7bbee4554f2a9af716c9d0a85135	sql (x3)		\N	3.2.2
009	yegor256	001-initial-schema.xml	2019-05-13 08:17:34.497045	9	EXECUTED	7:1dac511a8d6eb740b35b7fbbc06f21bb	sql		\N	3.2.2
010	yegor256	001-initial-schema.xml	2019-05-21 08:37:09.562719	10	EXECUTED	7:9742b67b974fdad6edc2cdeb2f497226	sql		\N	3.2.2
011	yegor256	001-initial-schema.xml	2019-05-29 08:42:16.549098	11	EXECUTED	7:62675ba9a0a287c8ba5de4c6499eeccb	sql		\N	3.2.2
012	yegor256	001-initial-schema.xml	2019-05-29 15:13:07.929807	12	EXECUTED	7:4cd4ca0b72890d7e1ead4b46598948fc	sql (x3)		\N	3.2.2
013	yegor256	001-initial-schema.xml	2019-07-07 19:30:28.981976	13	EXECUTED	7:4ad90487399ce1ae8a96cae4e8f6a1a7	sql		\N	3.2.2
\.


--
-- Data for Name: databasechangeloglock; Type: TABLE DATA; Schema: public; Owner: amtiotumrffdbe
--

COPY public.databasechangeloglock (id, locked, lockgranted, lockedby) FROM stdin;
1	f	\N	\N
\.


--
-- Data for Name: effect; Type: TABLE DATA; Schema: public; Owner: amtiotumrffdbe
--

COPY public.effect (id, impact, positive) FROM stdin;
95	6	f
148	6	f
13	6	f
154	6	f
19	8	f
162	9	f
35	6	f
43	6	f
49	8	f
632	9	f
93	6	f
471	6	f
114	2	f
201	4	f
129	5	f
44	6	f
204	5	f
225	6	t
231	2	f
387	6	f
234	4	t
248	4	t
251	5	t
391	2	t
394	5	t
446	8	f
310	8	t
16	6	f
320	4	t
124	6	f
40	8	f
67	6	f
530	6	f
6	6	f
413	6	t
521	5	f
75	8	f
639	6	f
547	8	f
105	6	f
58	5	f
315	5	t
692	6	f
159	6	f
756	5	f
429	6	t
81	6	f
152	8	f
117	5	f
120	4	f
37	6	f
524	8	f
502	5	f
580	6	f
78	6	f
99	6	f
506	5	f
240	6	t
133	4	f
186	6	f
91	5	f
257	6	f
30	8	f
372	6	f
193	6	f
47	4	f
222	8	t
279	5	t
111	6	f
108	5	f
760	5	f
267	4	t
3	8	f
399	6	t
463	6	t
292	1	f
173	8	t
180	5	t
176	4	t
218	6	t
213	8	t
652	6	f
423	4	t
189	6	f
467	6	f
487	4	f
483	6	f
61	6	f
55	8	f
589	6	f
564	6	t
729	5	t
24	6	f
567	8	t
283	8	t
11	6	f
21	4	f
571	6	t
305	6	t
296	5	f
598	5	f
601	6	f
694	9	f
613	4	f
617	5	f
621	9	f
625	5	f
628	5	f
668	4	f
697	9	f
197	5	f
52	5	f
732	5	t
675	4	f
207	6	f
672	6	f
686	4	f
735	6	f
102	6	f
517	5	t
715	2	f
721	5	f
743	9	f
763	9	f
346	5	f
746	6	f
70	9	f
33	6	f
766	5	f
64	8	f
773	8	t
779	5	f
784	8	f
84	5	f
798	5	f
835	5	f
838	6	f
848	8	f
854	6	f
859	9	f
863	6	f
867	5	t
\.


--
-- Data for Name: part; Type: TABLE DATA; Schema: public; Owner: amtiotumrffdbe
--

COPY public.part (id, project, type, text, created) FROM stdin;
7	1	Risk	The server may send Bitcoins out by mistake	2019-04-29 14:21:53.952151+00
8	1	Risk	Public Bitcoin keys may be lost by the server	2019-04-29 14:23:28.821396+00
12	1	Risk	Laptop may be lost or stolen and data may be exposed	2019-04-29 14:42:27.73139+00
13	1	Effect	Will take too long to restore passwords, accounts, files	2019-04-29 14:42:27.747871+00
18	1	Risk	Heroku may lock the account for spam	2019-04-29 14:45:56.981813+00
19	1	Effect	Many websites will be down for a long time	2019-04-29 14:45:56.986341+00
34	1	Risk	Bitcoin rate may have a long-term fall	2019-04-29 14:56:25.318882+00
35	1	Effect	Zold will lose its value and market reputation	2019-04-29 14:56:25.323379+00
43	1	Effect	Rultor will stop working	2019-04-29 15:13:45.629909+00
44	1	Effect	ThreeCopies will stop making backups	2019-04-29 15:14:57.462123+00
48	1	Risk	I may be kidnapped to get a ransom	2019-04-29 15:17:22.989721+00
49	1	Effect	All Bitcoin assets will be lost	2019-04-29 15:17:22.994467+00
68	1	Plan	Write and publish Junior Objects	2019-04-29 15:39:55.596001+00
86	1	Plan	Promote trainings	2019-04-29 15:55:20.618155+00
147	1	Risk	They may ban/remove our thread there	2019-04-30 04:16:11.395376+00
148	1	Effect	Our reputation in crypto community will be damaged	2019-04-30 04:16:11.412217+00
92	1	Risk	My identity may be exposed by mistake	2019-04-29 16:05:02.957432+00
93	1	Effect	I may be questioned what is my connection to all of it	2019-04-29 16:05:03.100492+00
149	1	Plan	Review WHOIS information of all domains	2019-04-30 05:08:51.093231+00
96	1	Plan	Invent a certification mechanism and give masters to volunteers	2019-04-29 16:08:22.61116+00
5	1	Risk	Public Bitcoin keys may be stolen from PostgreSQL	2019-04-29 14:21:16.008373+00
6	1	Effect	Public Bitcoin assets will be lost	2019-04-29 14:21:16.013239+00
22	1	Cause	AWS	2019-04-29 14:47:47.936823+00
58	1	Effect	It will take time to restore the MongoDB hosting somewhere else	2019-04-29 15:24:33.455714+00
84	1	Effect	Some websites will stop working correctly	2019-04-29 15:49:45.043202+00
69	1	Risk	Zerocracy may not scale up	2019-04-29 15:42:55.043134+00
70	1	Effect	The idea will die	2019-04-29 15:42:55.15067+00
31	1	Cause	There is cash shortage	2019-04-29 14:52:19.499751+00
79	1	Cause	Lloyds Bank	2019-04-29 15:47:46.388203+00
80	1	Risk	I may lose money due to monthly fees	2019-04-29 15:47:46.392932+00
81	1	Effect	Lloyds account will be lost entirely	2019-04-29 15:47:46.397431+00
36	1	Risk	BTC may have short-term down spikes	2019-04-29 14:57:22.34162+00
37	1	Effect	Zerocracy will lose money due to exchange rate differences	2019-04-29 14:57:22.347625+00
76	1	Cause	Wells Fargo	2019-04-29 15:46:37.822795+00
77	1	Risk	They may close the account for some reason	2019-04-29 15:46:37.827885+00
78	1	Effect	Some money may be lost	2019-04-29 15:46:37.833416+00
134	1	Cause	0crat.com	2019-04-29 17:28:09.549894+00
97	1	Cause	0pdd.com	2019-04-29 16:10:14.177373+00
98	1	Risk	Due to lack of support it may lose the market	2019-04-29 16:10:14.190647+00
59	1	Cause	PayPal	2019-04-29 15:25:41.490815+00
60	1	Risk	PayPal may find out about Zold and terminate our account	2019-04-29 15:25:41.494712+00
61	1	Effect	We won't be able to send out PayPal anymore	2019-04-29 15:25:41.498136+00
53	1	Cause	Stripe	2019-04-29 15:21:39.203753+00
54	1	Risk	Stripe may close our account	2019-04-29 15:21:39.207805+00
55	1	Effect	We won't be able to accept cards anymore, many projects will stop paying us	2019-04-29 15:21:39.211425+00
82	1	Cause	SSL certificates at ssls.com	2019-04-29 15:49:45.015241+00
83	1	Risk	SSL certificates may expire	2019-04-29 15:49:45.024887+00
56	1	Cause	MongoDB data: two EC2 servers	2019-04-29 15:24:33.447975+00
23	1	Risk	AWS may become too expensive	2019-04-29 14:47:47.94129+00
24	1	Effect	Some money will be lost and it's not clear where to migrate	2019-04-29 14:47:47.945783+00
11	1	Effect	Serious delay in work and some data losses	2019-04-29 14:24:37.218711+00
62	1	Cause	zerocracy/home	2019-04-29 15:28:05.748928+00
17	1	Cause	Heroku	2019-04-29 14:45:56.977248+00
20	1	Risk	Heroku may become too expensive	2019-04-29 14:46:56.789921+00
21	1	Effect	Some money will be lost and migration will take too long	2019-04-29 14:46:56.794525+00
41	1	Cause	Contabo	2019-04-29 15:13:45.620811+00
42	1	Risk	Contabo server may shut down accidentally	2019-04-29 15:13:45.625482+00
15	1	Risk	GMail account may be hacked	2019-04-29 14:44:25.020147+00
9	1	Cause	Laptop	2019-04-29 14:24:37.209958+00
39	1	Risk	I may have not enough time to develop it	2019-04-29 15:02:14.722463+00
14	1	Cause	GMail/Google	2019-04-29 14:44:24.989454+00
40	1	Effect	Zold won't be supported by the community and will die	2019-04-29 15:02:14.727443+00
65	1	Cause	Alt	2019-04-29 15:29:40.478935+00
66	1	Risk	The modem can be found	2019-04-29 15:29:40.483279+00
67	1	Effect	It will be proven that the traffic is mine	2019-04-29 15:29:40.486922+00
74	1	Risk	We may be accused of illegal financial activities	2019-04-29 15:45:39.042826+00
75	1	Effect	I may have personal legal issues	2019-04-29 15:45:40.580361+00
28	1	Cause	There is YMB history	2019-04-29 14:50:35.037617+00
29	1	Risk	It may become visible and re-published	2019-04-29 14:50:35.042113+00
30	1	Effect	SH may blacklist ZC resources too	2019-04-29 14:50:35.050706+00
46	1	Risk	DigitalOcean may shut master nodes down b/c of mining	2019-04-29 15:16:29.272637+00
47	1	Effect	I will have to create new nodes somewhere, which will take time	2019-04-29 15:16:29.276163+00
50	1	Cause	HostGator	2019-04-29 15:19:46.697554+00
51	1	Risk	HostGator may go down for some time	2019-04-29 15:19:46.702526+00
1	1	Cause	GoDaddy	2019-04-29 14:14:59.65781+00
2	1	Risk	GoDaddy account may be locked or closed	2019-04-29 14:14:59.674567+00
3	1	Effect	All sites will be down for a long time	2019-04-29 14:14:59.690862+00
32	1	Risk	I may run out of personal money	2019-04-29 14:52:19.505403+00
33	1	Effect	Personal performance problems and travel rearrangements	2019-04-29 14:52:19.51218+00
16	1	Effect	Personal data will be lost, contacts, access to accounts	2019-04-29 14:44:25.028075+00
10	1	Risk	My SDD may break	2019-04-29 14:24:37.214569+00
63	1	Risk	The access to all secret files may be exposed by some mistake	2019-04-29 15:28:05.752747+00
64	1	Effect	It will take a lot of time to revoke all credentials	2019-04-29 15:28:05.756311+00
52	1	Effect	Mika will be out-of-service for some time	2019-04-29 15:19:46.706446+00
128	1	Risk	Wring may stop working correctly without maintenance	2019-04-29 17:20:24.486186+00
113	1	Risk	AWS SES account may have problems with spam	2019-04-29 16:17:02.267429+00
114	1	Effect	I will have to move to some other SMTP service	2019-04-29 16:17:02.279112+00
125	1	Plan	Review AWS monthly bill and minimize it	2019-04-29 17:16:45.814745+00
126	1	Plan	Review monthly bill and optimize it	2019-04-29 17:18:11.546157+00
129	1	Effect	My connection with GitHub community will be broken	2019-04-29 17:20:24.496969+00
130	1	Plan	Review Lloyds account and optimize it	2019-04-29 17:21:42.593472+00
137	1	Plan	Review all backups	2019-04-29 17:33:59.153381+00
138	1	Plan	Time machine full backup	2019-04-29 17:34:34.514764+00
142	1	Plan	Full body exam	2019-04-29 18:00:18.030928+00
143	1	Plan	Cleanup the laptop, remove unnecessary files	2019-04-29 18:05:10.221654+00
144	1	Plan	Review the code base, issues and PRs	2019-04-29 18:42:23.054357+00
94	1	Risk	Some old friend may blackmail me	2019-04-29 16:07:09.920218+00
95	1	Effect	I will have to pay	2019-04-29 16:07:09.927684+00
153	1	Risk	Some serious bugs on production may show up	2019-04-30 06:40:02.358129+00
154	1	Effect	The stability of 0crat and some other websites may be lost	2019-04-30 06:40:02.363088+00
156	1	Plan	Review Sentry.io and fix most critical bugs 	2019-04-30 06:40:49.677214+00
161	1	Risk	Sensitive data may be lost/exposed	2019-04-30 08:03:31.267807+00
162	1	Effect	There will be serious problems with confidentiality	2019-04-30 08:03:31.272+00
163	1	Plan	Perform security review of source code and data	2019-04-30 08:04:26.844296+00
166	1	Plan	Review the quality of wring.io repo, tickets, bugs	2019-04-30 08:07:37.018322+00
140	1	Risk	Without maintenance it may lose its market	2019-04-29 17:35:52.893345+00
183	1	Plan	Make improvements and additional tracking	2019-04-30 12:37:33.78388+00
187	1	Plan	Review 0rsk functionality and make improvements	2019-04-30 12:47:48.771813+00
190	1	Plan	Review mailanes.com code base and make improvements	2019-04-30 12:49:20.49976+00
194	1	Plan	Review soalition.com features and make improvements	2019-04-30 12:50:32.552496+00
195	1	Plan	Review jare.io source code and refresh it	2019-04-30 12:51:09.388134+00
103	1	Cause	ReHTTP.net	2019-04-29 16:12:39.260074+00
99	1	Effect	The reputation of PDD will suffer	2019-04-29 16:10:14.196569+00
122	1	Cause	I'm a human	2019-04-29 16:46:31.622885+00
115	1	Cause	UkrSibBank	2019-04-29 16:31:38.718464+00
116	1	Risk	I may lose all of it if I don't use it	2019-04-29 16:31:38.725901+00
117	1	Effect	There are $1K, which will be lost	2019-04-29 16:31:38.732375+00
131	1	Cause	Chase Bank	2019-04-29 17:25:32.785239+00
132	1	Risk	They may close or block the account	2019-04-29 17:25:32.79722+00
133	1	Effect	Some cash will be lost there	2019-04-29 17:25:32.808265+00
89	1	Cause	BoV	2019-04-29 16:04:02.356338+00
90	1	Risk	I may lose it if I don't manage it	2019-04-29 16:04:02.559752+00
91	1	Effect	The money will be lost (around $3K)	2019-04-29 16:04:02.915886+00
191	1	Cause	Soalition.com	2019-04-30 12:50:16.904866+00
193	1	Effect	There will be missed opportunities with elegantobjects community	2019-04-30 12:50:16.913569+00
102	1	Effect	There will be financial losses and service outage	2019-04-29 16:11:08.487997+00
100	1	Cause	Jare.io	2019-04-29 16:11:08.47555+00
109	1	Cause	SixNines.io	2019-04-29 16:14:30.846299+00
110	1	Risk	If not supported, it may only ruin my reputation	2019-04-29 16:14:30.859207+00
111	1	Effect	Customers will complain and may even ask for refunds	2019-04-29 16:14:30.870463+00
108	1	Effect	A lot of data may be exposed to losses	2019-04-29 16:13:43.475891+00
151	1	Risk	Zold may be hacked and stolen	2019-04-30 06:37:19.995663+00
152	1	Effect	The reputation of the project will be ruined	2019-04-30 06:37:20.000714+00
139	1	Cause	Rultor.com	2019-04-29 17:35:52.88133+00
185	1	Risk	The 0rsk system may have bugs or lack of features	2019-04-30 12:46:24.841748+00
186	1	Effect	The effectiveness of risk management will be low	2019-04-30 12:46:24.860322+00
127	1	Cause	Wring.io	2019-04-29 17:20:24.476367+00
167	1	Cause	yegor256/hoc	2019-04-30 09:03:35.332166+00
168	1	Risk	It may become a popular tool/metric for software projects	2019-04-30 09:03:35.339106+00
112	1	Cause	Mailanes.com	2019-04-29 16:17:02.260389+00
189	1	Effect	Mailing lists won't work as effectively as they can	2019-04-30 12:49:04.916974+00
106	1	Cause	ThreeCopies.com	2019-04-29 16:13:43.464295+00
107	1	Risk	It may stop making backup copies for some reason	2019-04-29 16:13:43.46994+00
104	1	Risk	Due to lack of support it may go out of service eventually	2019-04-29 16:12:39.265571+00
105	1	Effect	Zerocrat and Rultor will have to be reconfigured, in many places	2019-04-29 16:12:39.271737+00
171	1	Cause	Telegram channel/groups	2019-04-30 09:11:18.97513+00
172	1	Risk	They may become very popular	2019-04-30 09:11:18.99168+00
173	1	Effect	They will generate a serious flow of clients	2019-04-30 09:11:19.012075+00
178	1	Cause	Instagram @yegor256	2019-04-30 09:20:20.168496+00
179	1	Risk	Instagram may attract 50K+ followers	2019-04-30 09:20:20.173358+00
180	1	Effect	Instagram will become a lead generator	2019-04-30 09:20:20.177675+00
174	1	Cause	Twitter @yegor256	2019-04-30 09:18:40.263679+00
175	1	Risk	The account may gain 50K+ followers	2019-04-30 09:18:40.269541+00
176	1	Effect	Twitter will become a lead generator for me	2019-04-30 09:18:40.274956+00
146	1	Cause	Bitcointalk.org	2019-04-30 04:16:11.374122+00
160	1	Cause	Curiost.com	2019-04-30 08:03:31.263367+00
123	1	Risk	I may have health issues	2019-04-29 16:46:31.628095+00
124	1	Effect	Work performance will slow down	2019-04-29 16:46:31.636228+00
157	1	Cause	TechnoPark Corp.	2019-04-30 08:00:52.680173+00
158	1	Risk	There could be problems with IRS	2019-04-30 08:00:52.697983+00
159	1	Effect	Bank accounts will be locked and some money may be lost	2019-04-30 08:00:52.757929+00
118	1	Cause	I live in Moscow	2019-04-29 16:32:50.022393+00
119	1	Risk	There could be legal issues due to my immigration status	2019-04-29 16:32:50.028287+00
120	1	Effect	I may have to pay some fines	2019-04-29 16:32:50.036463+00
150	1	Cause	Zold	2019-04-30 06:37:19.981522+00
200	1	Risk	Shift-M podcast may die	2019-04-30 12:54:54.147209+00
201	1	Effect	Everything I invested into Shift-M will be wasted	2019-04-30 12:54:54.150541+00
202	1	Plan	Send 5 invitations to Shift-M podcast	2019-04-30 12:55:27.319241+00
203	1	Risk	OOP webinars may die	2019-04-30 12:57:06.046197+00
204	1	Effect	A large part of OOP video audience will be lost	2019-04-30 12:57:06.050839+00
205	1	Plan	Plan the next webinar	2019-04-30 12:57:25.064674+00
208	1	Plan	Write a new blog post	2019-04-30 12:58:40.633139+00
209	1	Plan	Spend two hours for blog promotion	2019-04-30 12:59:01.743652+00
210	1	Plan	Spend two hours on blog tuning and SEO optimization	2019-04-30 12:59:17.869407+00
214	1	Plan	Review and update my art accounts	2019-04-30 13:13:58.218903+00
215	1	Plan	Paint a new picture	2019-04-30 13:14:15.492867+00
216	1	Plan	Update buffer.com and make sure it promotes the blog effectively	2019-04-30 13:20:02.960942+00
223	1	Plan	Actively develop 0dmx	2019-04-30 13:36:00.489549+00
224	1	Risk	The 0rsk system may become popular on the market	2019-04-30 14:05:53.122383+00
225	1	Effect	0rsk may seriously help Zerocracy in management	2019-04-30 14:05:53.129545+00
247	1	Risk	Rultor may become a popular tool for programmers	2019-04-30 14:52:47.023+00
230	1	Risk	My repositories may get too old and unorganized	2019-04-30 14:14:17.159123+00
231	1	Effect	My public image as open source activist will suffer	2019-04-30 14:14:17.165435+00
232	1	Plan	Review the entire GitHub account and polish it	2019-04-30 14:14:33.758215+00
182	1	Risk	WTS may have bugs	2019-04-30 12:37:10.401153+00
233	1	Risk	I may get more followers and stars	2019-04-30 14:16:34.613303+00
234	1	Effect	GitHub will become a lead generator for me personally	2019-04-30 14:16:34.627921+00
237	1	Plan	Polish and promote one GitHub repo from my collection	2019-04-30 14:21:03.109311+00
242	1	Plan	Mail all known publishers	2019-04-30 14:27:31.110314+00
243	1	Plan	Update Twitter Ads for EO and CA	2019-04-30 14:32:03.259022+00
245	1	Plan	Push all translators of EO	2019-04-30 14:35:45.237003+00
248	1	Effect	Rultor may attract developers to me and Zerocracy	2019-04-30 14:52:47.029303+00
249	9	Cause	dsadsada	2019-04-30 14:55:51.356989+00
250	9	Risk	dsadsadas	2019-04-30 14:55:51.364232+00
251	9	Effect	dasdsa	2019-04-30 14:55:51.370451+00
254	1	Plan	Alt plan	2019-04-30 15:35:31.210799+00
258	1	Plan	Delete Telegram chat history with Max	2019-04-30 15:58:08.12732+00
259	1	Plan	Review Zold code base and fix critical bugs	2019-05-01 04:53:52.24186+00
262	1	Plan	Review ReHTTP and make sure it works as intended	2019-05-01 05:08:28.806928+00
264	1	Plan	Find an architect to maintain Rultor	2019-05-01 05:17:05.345507+00
333	1	Plan	Go through the repo, push it forward a bit, invite contributors	2019-05-02 08:09:04.424329+00
275	1	Plan	Polish Takes repository and check how things are going there	2019-05-01 06:00:38.711804+00
277	1	Plan	Share it on HN, Reddit, Changelog, etc.	2019-05-01 06:02:11.160696+00
289	1	Plan	Polish Tacit repo and make sure it's on track	2019-05-01 17:50:43.608627+00
293	1	Plan	Check Dasheroo and make sure all metrics are valid	2019-05-02 06:26:04.17418+00
278	1	Risk	Wring may become a popular tool for freelancers	2019-05-01 06:24:53.767869+00
255	1	Cause	Max	2019-04-30 15:57:50.427634+00
256	1	Risk	His business may get into legal troubles	2019-04-30 15:57:50.43496+00
257	1	Effect	I may have serious reputation losses	2019-04-30 15:57:50.441501+00
221	1	Risk	0dmx may gain 100K followers	2019-04-30 13:35:47.518455+00
222	1	Effect	0dmx will become a serious lead generator for all projects	2019-04-30 13:35:47.524242+00
196	1	Risk	I may lose track of finances and other stats	2019-04-30 12:52:09.340342+00
199	1	Cause	Blog	2019-04-30 12:54:54.143423+00
184	1	Cause	0rsk.com	2019-04-30 12:46:24.821499+00
279	1	Effect	I will be known as Wring creator	2019-05-01 06:24:53.774215+00
206	1	Risk	Blog traffic may go down	2019-04-30 12:58:13.655662+00
207	1	Effect	Most of what I invested into the blog will be lost	2019-04-30 12:58:13.659422+00
220	1	Cause	0dmx.com	2019-04-30 13:35:47.511928+00
334	1	Cause	yegor256/rumble	2019-05-02 08:10:33.558298+00
271	1	Cause	Takes.org	2019-05-01 05:52:28.107922+00
272	1	Risk	Takes may become a very popular Java web framework	2019-05-01 05:52:28.11376+00
318	1	Cause	elegantobjects.org	2019-05-02 07:55:28.878405+00
265	1	Cause	Qulice.com	2019-05-01 05:17:44.555323+00
266	1	Risk	Qulice may become a leading static analyzer for Java world	2019-05-01 05:17:44.560226+00
267	1	Effect	I will get additional popularity in Java	2019-05-01 05:17:44.565566+00
217	1	Risk	Very popular and large thread may help Zold grow	2019-04-30 13:29:23.675649+00
218	1	Effect	The thread will become a lead generator	2019-04-30 13:29:23.68266+00
229	1	Cause	GitHub	2019-04-30 14:14:17.151149+00
282	1	Risk	I may get a long-term contract with them	2019-05-01 16:55:34.389574+00
283	1	Effect	A contract with GitHub will solve my temporary cash problems	2019-05-01 16:55:34.396041+00
238	1	Cause	My books	2019-04-30 14:22:34.924823+00
239	1	Risk	The books may become very popular	2019-04-30 14:22:34.937186+00
240	1	Effect	The books will become the source of income + reputation	2019-04-30 14:22:34.942833+00
290	1	Cause	Dasheroo	2019-05-02 06:25:42.211418+00
291	1	Risk	Dasheroo may disconnect and start showing wrong numbers	2019-05-02 06:25:42.224508+00
292	1	Effect	Dasheero may become useless	2019-05-02 06:25:42.232288+00
211	1	Cause	Paintings	2019-04-30 13:13:39.084729+00
212	1	Risk	My paintings may become very popular and expensive	2019-04-30 13:13:39.088707+00
213	1	Effect	Selling paintings will generate good income	2019-04-30 13:13:39.092316+00
197	1	Effect	The entire business of Zerocracy will suffer	2019-04-30 12:52:09.346867+00
297	1	Plan	Check SeedRamp legal status and put all documents in place	2019-05-02 07:21:28.515146+00
299	1	Plan	Review SeedRamp website and refresh it	2019-05-02 07:23:33.640953+00
355	1	Plan	Refresh the repo, see what can be done, try to make a simple app	2019-05-02 08:54:10.361704+00
303	1	Plan	Review jPeek repo, see how it's going	2019-05-02 07:32:20.499496+00
349	1	Plan	Review the repo, polish and address all issues	2019-05-02 08:50:46.770887+00
306	1	Plan	Send one article to one conference about jPeek	2019-05-02 07:33:41.718781+00
307	1	Plan	Fill up Buffer	2019-05-02 07:34:30.297135+00
311	1	Plan	Write a russian blog post	2019-05-02 07:36:13.396218+00
312	1	Plan	Check Sozidanie website, refresh it with some news	2019-05-02 07:36:29.618057+00
321	1	Plan	Check the site, refresh it, tweet about it, invite people to join	2019-05-02 07:55:44.717957+00
324	1	Plan	Check the repo, update, fix bugs, publish it where it fits	2019-05-02 07:57:10.699477+00
327	1	Plan	Refresh it, make some changes, publish it where it fits	2019-05-02 07:58:50.074108+00
328	1	Risk	It may become popular on the market	2019-05-02 08:00:01.711101+00
338	1	Plan	Polish it and post where it fits	2019-05-02 08:11:44.597018+00
343	1	Plan	Polish the gem and post it where it fits	2019-05-02 08:13:55.970661+00
301	1	Risk	The project may die without my attention	2019-05-02 07:32:07.374872+00
352	1	Plan	Polish the repo, make it better, post it where it fits	2019-05-02 08:52:39.492188+00
360	1	Plan	Polish the repo and promote it a bit	2019-05-02 09:04:56.193932+00
363	1	Plan	Polish xcop and promote in the community	2019-05-02 09:20:51.881855+00
369	1	Plan	Review it, improve and post it somewhere	2019-05-02 09:24:25.495263+00
373	1	Plan	Refresh xdsd.org and make it look fresh	2019-05-02 09:31:42.334959+00
383	1	Plan	Remove unnecessary photos, apps, notes from my iPhone	2019-05-03 04:02:15.64996+00
384	1	Plan	Check how find-my-phone works	2019-05-03 04:02:58.420175+00
385	10	Cause	Cause	2019-05-03 07:10:46.51876+00
386	10	Risk	Risk	2019-05-03 07:10:46.526196+00
387	10	Effect	Effect	2019-05-03 07:10:46.53331+00
388	10	Plan	Ugh	2019-05-03 07:11:14.027197+00
389	11	Cause	Cause:	2019-05-03 08:55:05.549898+00
390	11	Risk	Risk:	2019-05-03 08:55:06.020507+00
391	11	Effect	Effect:	2019-05-03 08:55:06.475296+00
392	11	Plan	Plan:	2019-05-03 08:55:35.354641+00
371	1	Risk	If not supported it will get rusty	2019-05-02 09:31:27.820791+00
295	1	Risk	I may have problems with IRS if not reported correctly	2019-05-02 07:21:09.237279+00
298	1	Risk	The website may get too old and expired	2019-05-02 07:22:05.652956+00
309	1	Risk	Sozidanie may become a popular political unit	2019-05-02 07:35:59.737421+00
353	1	Cause	eolang.org	2019-05-02 08:53:52.920478+00
354	1	Risk	The language idea may be lost and expired	2019-05-02 08:53:52.92452+00
378	1	Cause	Netbout.com	2019-05-02 09:36:33.931493+00
375	1	Risk	Without attention it will get too rusty	2019-05-02 09:35:07.184119+00
308	1	Cause	Sozidanie.org.ua	2019-05-02 07:35:59.656896+00
356	1	Cause	yegor256/threads	2019-05-02 08:56:36.463138+00
379	1	Risk	Without attention it will be gone	2019-05-02 09:36:33.937737+00
365	1	Risk	Due to lack of support it may get out of the market	2019-05-02 09:22:52.681359+00
381	1	Cause	iPhone	2019-05-03 03:59:38.040823+00
344	1	Cause	s3auth.com	2019-05-02 08:15:10.779915+00
357	1	Risk	This gem may become pretty popular	2019-05-02 08:56:36.477414+00
322	1	Cause	yegor256/sibit	2019-05-02 07:56:51.237701+00
323	1	Risk	The library may become pretty popular among Bitcoin developers	2019-05-02 07:56:51.244258+00
361	1	Cause	yegor256/xcop	2019-05-02 09:13:31.69206+00
362	1	Risk	The gem may become popular for XML authors	2019-05-02 09:13:31.705126+00
317	1	Risk	Cactoos may become very popular in Java community	2019-05-02 07:51:12.463195+00
364	1	Cause	Xembly.org	2019-05-02 09:22:52.676303+00
347	1	Cause	yegor256/pdd	2019-05-02 08:50:31.003129+00
286	1	Cause	Tacit CSS	2019-05-01 17:50:21.338786+00
345	1	Risk	Without support s3auth may lose its market	2019-05-02 08:15:10.784926+00
325	1	Cause	yegor256/iri	2019-05-02 07:58:30.782714+00
287	1	Risk	Tacit framework may become even more popular	2019-05-01 17:50:21.347085+00
313	1	Cause	yegor256/pgtk	2019-05-02 07:46:01.311696+00
314	1	Risk	The pgtk repo may become popular among Ruby developers	2019-05-02 07:46:01.319408+00
421	1	Cause	Bibrarian.com	2019-05-03 20:40:07.319205+00
335	1	Risk	This command line tool may become popular	2019-05-02 08:10:33.565282+00
336	1	Cause	yegor256/zache	2019-05-02 08:11:32.19778+00
337	1	Risk	This caching gem may become popular	2019-05-02 08:11:32.201999+00
358	1	Cause	yegor256/backtrace	2019-05-02 08:57:21.548261+00
359	1	Risk	The gem may find its users	2019-05-02 08:57:21.552496+00
376	1	Cause	yegor256/jekyll-github-deploy	2019-05-02 09:36:02.53831+00
377	1	Risk	It may become more popular among Jekyll bloggers	2019-05-02 09:36:02.544123+00
316	1	Cause	Cactoos.org	2019-05-02 07:51:12.45508+00
326	1	Risk	The library may become popular in Ruby community	2019-05-02 07:58:30.788878+00
319	1	Risk	It may become popular	2019-05-02 07:55:28.884234+00
320	1	Effect	This will help me sell books and will increase my popularity	2019-05-02 07:55:28.890726+00
341	1	Cause	yegor256/futex	2019-05-02 08:13:46.71392+00
342	1	Risk	Futex may be a useful gem for others	2019-05-02 08:13:46.718083+00
350	1	Cause	yegor256/total	2019-05-02 08:51:20.243454+00
351	1	Risk	The Gem may become rather popular for web devs	2019-05-02 08:51:20.249358+00
367	1	Cause	yegor256/dynamo-archive	2019-05-02 09:24:13.369828+00
368	1	Risk	Its popularity may even grow higher	2019-05-02 09:24:13.375329+00
329	1	Cause	yegor256/syncem	2019-05-02 08:00:27.775171+00
330	1	Risk	The gem may become popular	2019-05-02 08:00:27.78097+00
331	1	Cause	yegor256/jpages	2019-05-02 08:08:44.48158+00
339	1	Cause	yegor256/glogin	2019-05-02 08:12:59.403073+00
340	1	Risk	It may become useful for other developers	2019-05-02 08:12:59.407344+00
304	1	Risk	I may publish some articles about jPeek	2019-05-02 07:33:27.640576+00
305	1	Effect	I may get a pretty good scientific reputation from jPeek	2019-05-02 07:33:27.646764+00
294	1	Cause	SeedRamp.com	2019-05-02 07:21:09.176309+00
374	1	Cause	Requs.org	2019-05-02 09:35:07.177453+00
310	1	Effect	It may help me grow my reputation	2019-05-02 07:35:59.830565+00
346	1	Effect	My investments of time and efforts will be lost	2019-05-02 08:15:10.789885+00
300	1	Cause	jPeek.com	2019-05-02 07:32:07.367937+00
296	1	Effect	Everything I invested into SR will be wasted	2019-05-02 07:21:12.534023+00
382	1	Risk	The phone may be lost, stolen, or broken	2019-05-03 03:59:38.055701+00
393	1	Risk	0crat may start growing organically	2019-05-03 14:09:41.039222+00
395	1	Plan	Review all projects and talk to all ARCs	2019-05-03 14:09:58.89393+00
396	1	Plan	Review all tickets, policy, website, polish the system	2019-05-03 14:10:24.083379+00
401	1	Risk	Zold emission may grow	2019-05-03 18:13:54.948933+00
394	1	Effect	Zerocracy will get investments faster	2019-05-03 14:09:41.059579+00
403	1	Plan	Review all recent jobs and fix bugs	2019-05-03 18:37:10.518854+00
407	1	Plan	Polish it and promote where it's possible	2019-05-03 20:22:01.221641+00
410	1	Plan	And captcha and let people add whatever they want	2019-05-03 20:23:17.821944+00
417	1	Plan	Review phpRack repo and site and refresh it	2019-05-03 20:36:39.146146+00
420	1	Plan	Check the status of phandom.org and refresh it	2019-05-03 20:37:44.028804+00
424	1	Plan	Check how things are going in Bibrarian and get it back on its feet	2019-05-03 20:40:30.260475+00
425	1	Plan	prepare and publish a scientific article about Zold (use WP as template)	2019-05-03 20:50:08.343881+00
434	1	Plan	Check yegor256/elegantobjects repo and refresh it	2019-05-03 21:03:24.086029+00
435	1	Plan	Check codeahead.org website, refresh it	2019-05-03 21:03:44.664349+00
436	1	Plan	Meditate	2019-05-04 03:07:10.006157+00
437	1	Plan	Make a vacation for 5 days	2019-05-04 03:07:27.257291+00
439	1	Plan	Cleanup histories of WhatsApp, Viber, Telegram	2019-05-04 04:05:57.444638+00
444	13	Cause	blah	2019-05-05 05:49:44.780334+00
445	13	Risk	high risk	2019-05-05 05:49:44.791134+00
446	13	Effect	the effect	2019-05-05 05:49:44.799983+00
447	13	Plan	do this and that	2019-05-05 05:50:18.740929+00
448	1	Plan	Check Wring and answer all questions	2019-05-05 06:49:42.285904+00
451	1	Plan	Review all messages in Slack and react	2019-05-05 07:06:59.909164+00
452	1	Plan	Record a new video for vlog	2019-05-05 08:54:44.655191+00
453	1	Plan	Review S3 backup, make sure it's up to date	2019-05-05 09:17:56.114612+00
456	1	Plan	Check my status with pmi.org and submit some PDUs	2019-05-05 09:23:27.039168+00
458	1	Plan	Check my status with ACM.org	2019-05-05 09:26:00.166184+00
459	1	Plan	Check my status with IEEE.org	2019-05-05 09:26:09.015964+00
460	1	Plan	Post a new Sunday Twitter poll	2019-05-05 09:40:43.252914+00
472	1	Plan	Check PIA VPN account and make sure it's paid	2019-05-05 16:25:40.91739+00
473	1	Plan	Review Telegram chat and improve it	2019-05-05 17:55:01.657106+00
476	1	Plan	Review the content of /code and archive what's not needed there	2019-05-05 20:51:52.045422+00
477	1	Plan	Check the flutter mobile app and suggest improvements	2019-05-05 20:52:47.534552+00
484	1	Plan	Check Papertrail logs	2019-05-07 06:32:21.448017+00
466	1	Risk	Coinbase may close the account for any reason	2019-05-05 13:34:48.010479+00
467	1	Effect	WTS will not be able to buy BTC anymore	2019-05-05 13:34:48.015014+00
418	1	Cause	phandom.org	2019-05-03 20:37:30.819518+00
419	1	Risk	The project may get rusty if not supported	2019-05-03 20:37:30.823681+00
416	1	Risk	phpRack may get rusty if not supported	2019-05-03 20:36:25.140542+00
422	1	Risk	Bibrarian may become popular and useful in combination with 0dmx	2019-05-03 20:40:07.324011+00
423	1	Effect	Bibrarian by itself will become popular and useful	2019-05-03 20:40:07.327997+00
428	1	Risk	Kickdown may become popular among bloggers	2019-05-03 20:52:10.743614+00
411	1	Cause	Thindeck.com	2019-05-03 20:35:24.320781+00
405	1	Cause	yegor256/colorizejs	2019-05-03 20:21:49.43549+00
429	1	Effect	It may help with marketing, together with 0dmx	2019-05-03 20:52:10.748206+00
315	1	Effect	I will be known as an open source contributor	2019-05-02 07:46:01.326863+00
412	1	Risk	Thindeck project may become popular	2019-05-03 20:35:24.325782+00
413	1	Effect	Thinkdeck may be profitable and investable	2019-05-03 20:35:24.330371+00
427	1	Cause	Kickdown.io	2019-05-03 20:52:10.739269+00
415	1	Cause	phpRack.com	2019-05-03 20:36:25.13589+00
406	1	Risk	This simple JS lib may become popular	2019-05-03 20:21:49.440905+00
397	1	Cause	YouTube @yegor256	2019-05-03 17:53:01.55083+00
398	1	Risk	YouTube may gain 20K subscribers	2019-05-03 17:53:01.563599+00
399	1	Effect	YouTube will become a lead generator	2019-05-03 17:53:01.569975+00
461	1	Cause	Zerocracy Social Accounts	2019-05-05 09:42:14.762491+00
462	1	Risk	They may gain 10K+ followers each	2019-05-05 09:42:14.766854+00
485	1	Cause	Quickbooks	2019-05-07 08:22:23.355336+00
486	1	Risk	The account may get flooded with unprocessed data	2019-05-07 08:22:23.366075+00
481	1	Cause	PaperTrail	2019-05-07 06:32:02.647085+00
482	1	Risk	They may become useless without monitoring	2019-05-07 06:32:02.687108+00
483	1	Effect	Stability of pet projects will be lost	2019-05-07 06:32:02.697351+00
471	1	Effect	VPN will stop working	2019-05-05 16:25:18.790398+00
454	1	Cause	Certifications	2019-05-05 09:23:11.276399+00
455	1	Risk	Some of certificates may expire	2019-05-05 09:23:11.281876+00
465	1	Cause	Coinbase.com	2019-05-05 13:34:48.005563+00
488	1	Plan	Check QuickBooks and make sure it's up to date	2019-05-07 08:22:37.903164+00
491	1	Plan	Review stateful.co and make sure it works as expected	2019-05-07 14:24:52.244114+00
492	1	Plan	Promote it and update	2019-05-07 14:26:07.022279+00
493	1	Plan	Check the repo, refresh it, and promote as much as possible	2019-05-07 14:30:51.58499+00
494	1	Plan	Check the project, the repo, the resources consumed by AWS	2019-05-07 14:31:26.855409+00
495	1	Plan	Go through the forum and reply here and there, to increase my reputation	2019-05-07 14:32:14.01461+00
496	1	Plan	Refresh the gem and promote it as much as possible	2019-05-07 14:32:29.752842+00
497	1	Plan	Refresh it and promote in the community	2019-05-07 14:32:40.976436+00
498	1	Plan	Update the repo and the entire idea	2019-05-07 14:39:45.929002+00
503	1	Plan	Check Privatbank status and Kyivstar too	2019-05-08 06:56:47.239948+00
507	1	Plan	Check the status of the account and MTS too	2019-05-08 07:05:20.328205+00
508	1	Plan	Check the status of MongoDB EC2 instance	2019-05-08 13:14:38.760004+00
513	1	Plan	Make sure I submit to OOP/software conferences regularly	2019-05-10 07:36:24.054085+00
514	1	Plan	Check how Amazon ads are doing	2019-05-10 07:37:36.342459+00
463	1	Effect	Social media will become a lead generator for Zerocracy	2019-05-05 09:42:14.771915+00
540	1	Cause	MySQL data: mika	2019-05-13 06:39:01.585458+00
541	1	Risk	MySQL data may be technically corrupted or lost	2019-05-13 06:39:01.590428+00
518	1	Plan	Check what's going on there and make some steps forward	2019-05-12 05:45:14.351765+00
519	1	Plan	Ask more OOP and software engineering people to review books	2019-05-12 16:50:51.416263+00
520	1	Risk	There could be security breaches	2019-05-12 21:09:25.984896+00
543	1	Plan	Make sure ThreeCopies backup MySQL correctly	2019-05-13 06:39:46.688157+00
522	1	Plan	Review 0rsk for potential security issues	2019-05-12 21:09:42.587587+00
523	1	Risk	Rultor sources may have a bug and access to zerocracy/home will be exposed	2019-05-13 06:08:31.278729+00
544	1	Plan	Check the status of Dropbox, Google Drive, and iCloud, clean up the data there	2019-05-13 06:41:44.10576+00
525	1	Plan	Review the sources of rultor for this security concern	2019-05-13 06:08:57.308867+00
348	1	Risk	The PDD command line tool may loose its market	2019-05-02 08:50:31.010532+00
527	1	Plan	Go through all resources I deploy via Rultor and check their logs	2019-05-13 06:14:57.975032+00
545	1	Plan	Archive what doesn't need to be on the laptop, to the S3 storage	2019-05-13 06:42:20.238783+00
531	1	Plan	Make sure ThreeCopies backup them all daily	2019-05-13 06:24:52.998194+00
504	1	Cause	Sberbank	2019-05-08 06:59:17.257527+00
532	1	Risk	Pgsql data may be stolen	2019-05-13 06:25:41.941057+00
546	1	Risk	Cold Bitcoin keys may be lost	2019-05-13 06:43:46.410322+00
533	1	Plan	Rotate passwords on all Pgsql instances	2019-05-13 06:26:14.868917+00
534	1	Plan	Block access from public Internet, except Rultor and local Heroku network	2019-05-13 06:26:46.303183+00
535	1	Plan	Check the source code for any suspicious activity	2019-05-13 06:28:14.023013+00
530	1	Effect	It will take time to restore them, or business may suffer if not restored	2019-05-13 06:24:24.011158+00
537	1	Risk	AWS keys may be stolen	2019-05-13 06:35:43.879664+00
521	1	Effect	Sensitive data will be lost	2019-05-12 21:09:25.992659+00
528	1	Cause	PostgreSQL: 0rsk, 0crat, mailanes, soalition, wts	2019-05-13 06:24:23.961714+00
538	1	Plan	Check what is inside IAM and remove unnecessary users	2019-05-13 06:36:04.380082+00
539	1	Plan	Remove unnecessary data from S3	2019-05-13 06:37:33.284333+00
549	1	Risk	MongoDB data may be stolen	2019-05-13 06:47:32.222585+00
547	1	Effect	Serious financial losses	2019-05-13 06:43:46.414802+00
548	1	Plan	Check where they are and make sure they are safe	2019-05-13 06:44:03.265503+00
57	1	Risk	The relay AWS server may go down for any reason	2019-04-29 15:24:33.452127+00
550	1	Plan	Make sure only Heroku servers may connect to AWS Mongo	2019-05-13 06:48:00.535498+00
487	1	Effect	It will be difficult to get it back on track	2019-05-07 08:22:23.376465+00
553	1	Plan	Go through the R1+R2 circles and refresh contacts	2019-05-13 08:09:26.757876+00
4	1	Cause	Bitcoins	2019-04-29 14:21:16.003565+00
500	1	Cause	Privatbank	2019-05-08 06:56:27.691485+00
501	1	Risk	Access may be lost if Kyivstar stops working	2019-05-08 06:56:32.222799+00
502	1	Effect	I will no access to the money there	2019-05-08 06:56:32.40269+00
505	1	Risk	Access may be lost if MTS phone is lost	2019-05-08 06:59:17.262882+00
506	1	Effect	I will have no access to the money	2019-05-08 06:59:17.267419+00
370	1	Cause	xdsd.org	2019-05-02 09:31:27.813843+00
372	1	Effect	The reputation of Zerocracy will suffer	2019-05-02 09:31:27.826986+00
192	1	Risk	The soalition.com may not achieve its goals	2019-04-30 12:50:16.909311+00
489	1	Cause	Stateful.co	2019-05-07 14:24:32.778007+00
490	1	Risk	The project may die if not supported	2019-05-07 14:24:32.790796+00
526	1	Risk	Rultor logs may expose credentials to the public	2019-05-13 06:14:33.880552+00
524	1	Effect	Some credentials will be lost and maybe some data	2019-05-13 06:08:31.287335+00
188	1	Risk	Mail delivery may have hidden issues or lacking functionality	2019-04-30 12:49:04.912308+00
516	1	Risk	It may become popular if properly developed	2019-05-12 05:45:00.092063+00
517	1	Effect	I may get some leads from there	2019-05-12 05:45:00.099538+00
536	1	Cause	S3 data	2019-05-13 06:35:43.868061+00
332	1	Risk	This experiment may turn into a real web framework	2019-05-02 08:08:44.486408+00
555	1	Plan	Polish it and promote for the Ruby community	2019-05-13 12:53:43.784993+00
556	1	Cause	SeedRamp LLC	2019-05-13 13:24:44.861519+00
557	1	Risk	I may loose the company if not filed correctly	2019-05-13 13:24:44.866083+00
558	1	Plan	Check how the LLC is doing	2019-05-13 13:24:56.876254+00
560	1	Plan	Invent a certification mechanism and give masters to some volunteers	2019-05-13 13:30:51.401069+00
561	1	Plan	Create a similar account at cex.io or similar trader	2019-05-13 13:33:30.252162+00
564	1	Effect	Facebook will become a lead generator	2019-05-13 13:35:25.924757+00
515	1	Cause	ThePMP.com	2019-05-12 05:45:00.084125+00
563	1	Risk	It may gain 50K followers	2019-05-13 13:35:25.920783+00
529	1	Risk	Pgsql data may be lost/corrupted, due to technical error	2019-05-13 06:24:23.978882+00
562	1	Cause	Facebook @yegor256	2019-05-13 13:35:25.915932+00
565	1	Cause	BL blog	2019-05-13 14:17:35.327757+00
566	1	Risk	It may become popular on its market	2019-05-13 14:17:35.334551+00
567	1	Effect	It will help me write a book later and sell it	2019-05-13 14:17:35.339459+00
568	1	Plan	Write a new BL blog post	2019-05-13 14:17:48.378592+00
569	1	Cause	RU Blog	2019-05-13 14:18:32.609384+00
570	1	Risk	It may become rather popular in Russian market	2019-05-13 14:18:32.614598+00
571	1	Effect	It may help in the future, in a potential political game	2019-05-13 14:18:32.619361+00
572	1	Plan	Write a new RU blog post	2019-05-13 14:18:41.933487+00
573	1	Plan	Write a new blog post for Zold blog	2019-05-13 14:19:36.824668+00
574	1	Plan	Write a new blog post for ZC blog	2019-05-13 14:20:05.224446+00
575	1	Cause	Patents	2019-05-13 14:26:59.088273+00
576	1	Risk	They may be lost if not renewed	2019-05-13 14:26:59.092369+00
577	1	Plan	Check how my USPTO patent applications are doing	2019-05-13 14:27:16.204464+00
578	15	Cause	131313213	2019-05-14 07:05:44.251015+00
579	15	Risk	489494894	2019-05-14 07:05:44.25708+00
580	15	Effect	4656565656565656565656565	2019-05-14 07:05:44.261258+00
644	1	Cause	DynamoDB	2019-05-15 07:23:17.507591+00
645	1	Risk	DynamoDB may be lost, stolen or corrupted	2019-05-15 07:23:17.511542+00
782	65	Cause	cause	2019-06-07 14:37:31.510308+00
783	65	Risk	risk	2019-06-07 14:37:31.522111+00
784	65	Effect	fail epic	2019-06-07 14:37:31.530331+00
588	18	Risk	Les projets pourraient manqué de ressources techniques	2019-05-14 09:39:16.550932+00
593	21	Plan	Confirm the dataset is created biweekly	2019-05-14 11:55:25.652061+00
596	22	Cause	C	2019-05-14 12:31:27.089546+00
597	22	Risk	R	2019-05-14 12:31:27.094176+00
598	22	Effect	E	2019-05-14 12:31:27.09851+00
611	24	Cause	Daisy needs too many walks	2019-05-14 14:19:57.792364+00
612	24	Risk	Brian is taken away to walk Daisy	2019-05-14 14:19:57.797079+00
613	24	Effect	Work doesn't get done	2019-05-14 14:19:57.802234+00
599	18	Cause	Le Run/Monitoring des instances n'est pas industrialisé	2019-05-14 12:49:37.876005+00
600	18	Risk	Les services clients pourraient être interrompus à notre insu	2019-05-14 12:49:37.880707+00
601	18	Effect	Les démos et les versions Lite vont devenir inaccessibles	2019-05-14 12:49:37.884753+00
602	18	Plan	Mettre en place une infrastructure pérenne de Run/Monitoring 	2019-05-14 12:52:47.147624+00
604	18	Plan	Etre capable de relancer les services dès qu'un problème est détecté	2019-05-14 12:56:19.03024+00
605	18	Plan	Mettre en place des alertes pour tester l'état des services	2019-05-14 12:59:03.324229+00
589	18	Effect	Les dates de livraisons ne sont pas tenues	2019-05-14 09:39:16.554671+00
587	18	Cause	L'équipe tech est sous dimensionnée	2019-05-14 09:39:16.546385+00
614	24	Plan	Hire dog walker	2019-05-14 14:20:16.256178+00
615	25	Cause	lkjdlf	2019-05-14 15:00:51.278428+00
616	25	Risk	fsasf	2019-05-14 15:00:51.283213+00
617	25	Effect	sdfgdfgdf	2019-05-14 15:00:51.286941+00
618	25	Plan	fdsfa	2019-05-14 15:01:09.160996+00
619	26	Cause	Деградация к8с	2019-05-14 15:39:07.782903+00
620	26	Risk	Недоступность сервисов	2019-05-14 15:39:07.787735+00
621	26	Effect	Клиенты не могут приобрести услуги и не могут подать объявление	2019-05-14 15:39:07.792388+00
622	1	Plan	Check how master nodes are doing, in their VPS	2019-05-14 15:54:29.593008+00
623	27	Cause	A new cause	2019-05-14 16:04:36.224773+00
624	27	Risk	A new Risk	2019-05-14 16:04:36.229324+00
625	27	Effect	A new risk	2019-05-14 16:04:36.233549+00
626	30	Cause	WE	2019-05-14 19:55:09.693374+00
627	30	Risk	2	2019-05-14 19:55:09.697734+00
628	30	Effect	3	2019-05-14 19:55:09.702485+00
629	30	Plan	do it	2019-05-14 19:55:28.033921+00
630	31	Cause	The API dead	2019-05-15 04:28:01.702985+00
631	31	Risk	Not work	2019-05-15 04:28:01.707884+00
632	31	Effect	Dead	2019-05-15 04:28:01.711821+00
633	31	Plan	Sync	2019-05-15 04:28:20.16712+00
653	4	Cause	javascript:/*--></title></style></textarea></script></xmp><svg/onload='+/"/+/onmouseover=1/+/[*/[]/+alert(1)//'>	2019-05-15 08:48:11.415612+00
637	34	Cause	Phuc is doing migrating serialize library from Moxy to Jackson for the REST facade	2019-05-15 07:14:32.058751+00
638	34	Risk	The changes may break the current working functions	2019-05-15 07:14:32.063593+00
639	34	Effect	More bugs appear in July release	2019-05-15 07:14:32.067367+00
640	34	Plan	Ensure all integration tests are working with regresstion test	2019-05-15 07:15:16.470873+00
641	35	Cause	1	2019-05-15 07:19:48.144389+00
643	1	Plan	Make sure ThreeCopies does its job with DynamoDB tables	2019-05-15 07:21:30.351384+00
646	1	Plan	Rotate a few AWS passwords	2019-05-15 07:23:35.750098+00
647	1	Plan	Check how ThreeCopies are doing backups of DynamoDB	2019-05-15 07:23:49.115147+00
651	38	Risk	aafsdfbdsf	2019-05-15 08:47:40.00401+00
652	38	Effect	aafbsdbfdsb	2019-05-15 08:47:40.013027+00
650	38	Cause	cvxcvbas	2019-05-15 08:47:39.994264+00
667	38	Risk	sadf	2019-05-15 08:54:58.139523+00
668	38	Effect	asdfasd	2019-05-15 08:54:58.14866+00
663	4	Plan	 javascript:/*--></title></style></textarea></script></xmp><svg/onload='+/"/+/onmouseover=1/+/[*/[]/+alert(1)//'>	2019-05-15 08:52:54.753628+00
665	4	Plan	 javascript:/*--></title></style></textarea></script></xmp><svg/onload='+/"/+/onmouseover=1/+/[*/[]/+alert(3)//'>	2019-05-15 08:53:12.304451+00
666	38	Cause	asdf	2019-05-15 08:54:57.9981+00
669	1	Plan	Try to restore its twitter account @sxnns	2019-05-15 14:04:13.645858+00
671	40	Risk	Some other payment processor may present a better deal	2019-05-15 21:19:00.297697+00
672	40	Effect	We won't be able to lower our costs	2019-05-15 21:19:00.304988+00
685	4	Risk	sdg09j	2019-05-16 08:00:19.325043+00
693	41	Risk	Members may quit	2019-05-16 10:12:24.701384+00
674	40	Risk	Some clients may want to use other payment processor than other clients	2019-05-15 21:30:52.646964+00
675	40	Effect	Some clients will be unhappy that they must use one specific payment processor	2019-05-15 21:30:52.652529+00
670	40	Cause	The project is designed to work with only one payment processor API	2019-05-15 21:19:00.291875+00
676	40	Plan	Abstract payment processing tasks and make the current implementation swappable with others	2019-05-15 21:34:54.213982+00
677	40	Plan	Allow to configure multiple payment processors and to assign them to clients, also allow to mark one of them as default	2019-05-15 21:38:42.584302+00
678	4	Cause	1123123	2019-05-16 07:59:35.29927+00
679	4	Risk	123	2019-05-16 07:59:35.303943+00
745	1	Risk	Twitter may ban our app(s)	2019-05-26 04:57:33.794677+00
686	4	Effect	-9jdf-j	2019-05-16 08:00:19.393922+00
684	4	Cause	gwehbij09	2019-05-16 08:00:19.247294+00
746	1	Effect	We will lose everything we invested into Twitter actors	2019-05-26 04:57:33.804285+00
691	41	Risk	launch may be delayed after 2019	2019-05-16 10:10:45.32266+00
692	41	Effect	Alternatives will appear	2019-05-16 10:10:45.327458+00
690	41	Cause	dev takes too long	2019-05-16 10:10:45.317637+00
694	41	Effect	Project will be un jeopardy	2019-05-16 10:12:24.705982+00
695	43	Cause	Using 0rsk	2019-05-16 11:06:27.566424+00
696	43	Risk	Shuts Down	2019-05-16 11:06:27.571192+00
697	43	Effect	Lose all risks	2019-05-16 11:06:27.575324+00
699	1	Plan	Submit more of them to GitHub marketplace	2019-05-16 13:01:29.189754+00
701	1	Plan	Check how Rafael is doing	2019-05-16 19:58:34.85584+00
702	1	Plan	Check Little Snitch configuration	2019-05-17 05:27:46.991657+00
703	1	Cause	@g4s8	2019-05-17 06:03:24.24588+00
704	1	Risk	He may steal customers and work with them directly	2019-05-17 06:03:24.251931+00
705	1	Plan	Fix comments counter for Disqus	2019-05-19 07:23:18.771739+00
101	1	Risk	It may drain AWS resources out (too much traffic)	2019-04-29 16:11:08.481926+00
706	1	Risk	It may become a popular CDN for small projects	2019-05-19 07:47:21.022824+00
707	1	Plan	Find and add additional SMS sending provider	2019-05-19 10:40:06.957885+00
708	1	Plan	Promote regular software reviews	2019-05-19 19:09:49.455156+00
713	47	Cause	the data you enter is stored in our database	2019-05-21 13:09:50.524309+00
714	47	Risk	your information will be exposed to hackers	2019-05-21 13:09:50.533046+00
715	47	Effect	don't disclose sensitive facts here	2019-05-21 13:09:50.540697+00
716	47	Plan	validate post for secrets 	2019-05-21 13:10:54.316074+00
717	1	Plan	Add 4 projects there	2019-05-21 16:25:13.482258+00
718	1	Plan	Extend Terms of User in WTS with legal clauses, explaining where we stand	2019-05-22 06:40:36.492518+00
719	48	Cause	Phonenumber & birthdate	2019-05-22 13:40:21.554963+00
720	48	Risk	customer may do a typo in birthdate	2019-05-22 13:40:21.573394+00
721	48	Effect	will create another customer	2019-05-22 13:40:21.588011+00
722	48	Plan	make an error message	2019-05-22 13:42:25.601276+00
725	1	Plan	Check all Travis builds and fix two of them	2019-05-22 17:11:39.10182+00
726	1	Plan	Turn of nightli.es and switch to Travis feature	2019-05-22 17:12:10.28527+00
727	1	Cause	ilks.org	2019-05-22 18:45:35.249423+00
728	1	Risk	It may become an interesting project	2019-05-22 18:45:35.258806+00
729	1	Effect	It may become a lead generator	2019-05-22 18:45:35.265083+00
730	1	Cause	adybo.com	2019-05-22 18:46:03.533182+00
731	1	Risk	Adybo may become an interesting project	2019-05-22 18:46:03.546648+00
732	1	Effect	It may generate some cash	2019-05-22 18:46:03.555818+00
733	1	Cause	Noah	2019-05-22 18:53:44.693202+00
734	1	Risk	He may cause legal and media problems	2019-05-22 18:53:44.706651+00
735	1	Effect	I may lose a lot of equity and reputation	2019-05-22 18:53:44.715554+00
736	1	Plan	Check how Joseph Tacosik works and ping him with corrections	2019-05-23 05:00:02.271613+00
738	1	Plan	Check how it's doing, talk to the ARC	2019-05-23 07:21:01.185263+00
740	1	Plan	Check Sibit, make sure we get new APIs on board	2019-05-23 07:36:23.023658+00
741	51	Cause	Работаю над проектом	2019-05-23 17:28:15.512362+00
742	51	Risk	Интерес к проекту может пропасть, до его завершения	2019-05-23 17:28:16.00841+00
743	51	Effect	Проект не будет завершен.	2019-05-23 17:28:16.570578+00
744	51	Plan	Выполнять по одной задаче каждый день.	2019-05-23 17:30:36.124973+00
723	1	Cause	Travis	2019-05-22 17:09:10.93128+00
724	1	Risk	Travis builds may become useless if not checked regularly	2019-05-22 17:09:10.974485+00
751	1	Plan	Clean it up, removing all unnecessary emails and making Inbox empty	2019-05-26 06:25:56.582407+00
752	1	Plan	Promote my Telegram, somehow	2019-05-28 07:04:12.214709+00
754	59	Cause	wat	2019-05-29 11:27:00.831805+00
758	16	Cause	cause1	2019-05-29 12:32:11.285778+00
759	16	Risk	risk1	2019-05-29 12:32:11.292141+00
757	59	Cause	asd	2019-05-29 11:27:35.859676+00
755	59	Risk	dingen	2019-05-29 11:27:00.844144+00
756	59	Effect	a	2019-05-29 11:27:00.851675+00
760	16	Effect	effect1	2019-05-29 12:32:11.296661+00
761	60	Cause	we are monitoring systems with potentially high voltages	2019-05-29 13:02:19.790671+00
762	60	Risk	Someone gets injured or killed	2019-05-29 13:02:19.799925+00
763	60	Effect	Legal prosecution.	2019-05-29 13:02:19.804931+00
764	61	Cause	Cause test	2019-05-29 14:20:54.186+00
768	1	Plan	Review awesome-risks, add some lines, promote it	2019-05-29 15:51:12.257811+00
767	61	Cause	Cause Test 2	2019-05-29 14:21:41.206393+00
765	61	Risk	Risk Test	2019-05-29 14:20:54.19069+00
766	61	Effect	Effect Test	2019-05-29 14:20:54.194455+00
769	1	Cause	JCabi libs	2019-05-29 16:51:02.513937+00
770	1	Risk	They may be even more popular	2019-05-29 16:51:02.539352+00
772	1	Risk	It may become a popular dating service	2019-05-29 16:51:48.587086+00
774	1	Plan	Add SSL	2019-05-29 19:28:11.657854+00
771	1	Cause	Aintshy.com	2019-05-29 16:51:48.579481+00
773	1	Effect	May turn into a successful business	2019-05-29 16:51:48.592809+00
776	1	Plan	Add SSL to 0pdd	2019-05-29 19:28:47.306875+00
777	62	Cause	ss	2019-05-30 02:33:31.746542+00
778	62	Risk	sdas	2019-05-30 02:33:31.760078+00
779	62	Effect	adasd	2019-05-30 02:33:31.769804+00
780	62	Plan	asdsadsa	2019-05-30 02:33:46.549341+00
781	1	Plan	Publish to GitHub Marketplace	2019-05-30 17:17:54.375289+00
785	1	Plan	Migrate from Make to Arara	2019-06-13 07:04:45.990031+00
786	1	Plan	Add Elegant Objects promotion to all open source projects of mine	2019-06-14 12:39:08.19885+00
861	117	Cause	Stripe account	2019-08-27 12:45:28.670062+00
862	117	Risk	They may lock our account	2019-08-27 12:45:28.678214+00
863	117	Effect	We will loose the money	2019-08-27 12:45:28.685982+00
791	1	Plan	File Florida report and pay $150	2019-06-15 05:31:06.223099+00
792	1	Plan	Update resume on key job sites: hh, monster, indeed, stackoverflow	2019-06-17 19:15:21.17082+00
794	1	Plan	Update the KPI reporting and make it look richer	2019-06-17 19:17:16.128183+00
795	1	Plan	Make sure Bitcointalk thread is promoted	2019-06-21 08:41:29.507395+00
796	70	Cause	The data you enter is stored in our database	2019-06-23 17:51:33.981809+00
797	70	Risk	it may be hacked	2019-06-23 17:51:33.993425+00
798	70	Effect	your information will be exposed to hackers	2019-06-23 17:51:33.999705+00
799	70	Plan	don't disclose sensitive facts here	2019-06-23 20:23:49.505221+00
801	70	Plan	once don't disclose sensitive facts here	2019-06-23 20:24:34.344539+00
832	1	Plan	Check how Amazon Associates is doine	2019-06-27 15:54:55.861861+00
833	107	Cause	dsfdsf	2019-07-04 05:35:01.829349+00
834	107	Risk	fdsf	2019-07-04 05:35:01.841243+00
835	107	Effect	dsfds	2019-07-04 05:35:01.850218+00
864	1	Plan	Migrate to Dokku	2019-09-03 16:53:41.468579+00
865	119	Cause	dsf	2019-09-06 13:06:57.894107+00
839	18	Plan	Travailler avec une agence de design pour revoir le produit dans son ensemble	2019-07-05 09:20:54.809256+00
840	18	Plan	Fournir une démo dont l'interface utilisateur aura été peaufiner	2019-07-05 09:22:22.901741+00
866	119	Risk	sdffd	2019-09-06 13:06:57.907238+00
867	119	Effect	sdfsdfds	2019-09-06 13:06:57.914573+00
841	18	Plan	Travailler avec un sous-traitant pour industrialiser le Run/Monitoring	2019-07-05 09:33:26.437274+00
836	18	Cause	L'interface utilisateur de notre produit est insatisfaisante	2019-07-05 09:18:36.665334+00
837	18	Risk	Les prospects pourraient montrer peu d'intérêt pour notre produit	2019-07-05 09:18:36.685962+00
838	18	Effect	Nos commerciaux vont avoir du mal à transformer nos prospects en clients	2019-07-05 09:18:36.696289+00
843	18	Plan	Améliorer le design et l’interface de notre produit	2019-07-19 12:49:48.446168+00
845	18	Plan	Anticiper et négocier avec le client un report de la livraison	2019-07-19 13:03:41.39803+00
846	18	Cause	La transformation des données du client consomme beaucoup de ressources	2019-07-19 13:14:46.8199+00
847	18	Risk	L’équipe projet perd du temps sur une tâche laborieuse	2019-07-19 13:14:46.826291+00
848	18	Effect	Le projet n’est pas rentable	2019-07-19 13:14:46.832253+00
849	18	Plan	Optimiser notre processus de traitement des données 	2019-07-19 13:15:13.383209+00
850	18	Plan	Utiliser des outils du marché pour améliorer la productivité	2019-07-19 13:15:32.233504+00
851	18	Plan	Améliorer nos specifications et exigences sur les données fournies par le client	2019-07-19 13:16:22.737262+00
853	18	Risk	Les développeurs pourraient avoir trop de projets en //	2019-07-31 15:05:14.625312+00
854	18	Effect	Les développeurs font s'épuiser à passer d'un projet à l'autre	2019-07-31 15:05:14.633418+00
855	18	Plan	Lancer le recrutement d'un développeur pour traiter les sujets DevOps	2019-07-31 15:07:02.095155+00
856	18	Plan	Lancer le recrutement d'un développeur Projet	2019-07-31 15:07:53.922125+00
857	115	Cause	lack of cash	2019-08-11 15:38:08.360525+00
858	115	Risk	no funding	2019-08-11 15:38:08.372134+00
859	115	Effect	project failure	2019-08-11 15:38:08.37923+00
860	115	Plan	increase sales	2019-08-11 15:39:23.574924+00
868	119	Plan	cvdds	2019-09-06 13:07:18.946824+00
873	126	Cause	rrr	2019-10-15 20:37:56.795356+00
\.


--
-- Data for Name: plan; Type: TABLE DATA; Schema: public; Owner: amtiotumrffdbe
--

COPY public.plan (id, part, schedule, completed) FROM stdin;
324	323	monthly	2019-06-27 01:21:05+00
845	589	monthly	2019-07-19 13:03:41.403964+00
142	123	annually	2019-04-29 18:00:18.034604+00
849	847	monthly	2019-07-19 13:15:13.386092+00
851	846	monthly	2019-07-19 13:16:22.739439+00
355	354	monthly	2019-06-21 06:36:43+00
306	304	monthly	2019-07-14 15:46:26+00
407	406	monthly	2019-06-27 01:45:28+00
338	337	monthly	2019-06-27 01:46:11+00
395	393	weekly	2019-07-24 15:01:06+00
333	332	monthly	2019-06-27 02:29:48+00
242	239	quarterly	2019-04-30 14:27:31.113528+00
245	239	weekly	2019-07-24 15:05:20+00
190	188	monthly	2019-10-10 06:27:32+00
138	11	weekly	2019-10-03 13:23:50+00
343	342	monthly	2019-06-28 02:05:06+00
855	587	monthly	2019-07-31 15:07:02.097698+00
208	206	weekly	2019-08-01 15:34:23+00
194	192	monthly	2019-10-10 06:29:32+00
297	295	quarterly	2019-05-02 07:21:28.517602+00
299	298	quarterly	2019-05-02 07:23:33.64349+00
143	13	monthly	2019-10-10 12:34:33+00
68	32	daily	2019-10-13 02:32:49+00
183	182	weekly	2019-10-13 02:37:28+00
388	386	05-05-2019	2019-05-03 07:11:14.029129+00
392	390	biweekly	2019-05-03 08:55:35.641317+00
216	206	weekly	2019-10-13 02:47:20+00
243	239	biweekly	2019-07-05 13:47:10+00
223	221	daily	2019-10-13 03:01:10+00
417	416	quarterly	2019-05-03 20:36:39.148274+00
420	419	quarterly	2019-05-03 20:37:44.030977+00
137	107	biweekly	2019-10-03 13:29:18+00
209	206	biweekly	2019-10-13 07:36:05+00
205	203	biweekly	2019-08-01 16:00:59+00
434	319	quarterly	2019-05-03 21:03:24.087888+00
435	239	quarterly	2019-05-03 21:03:44.666277+00
437	123	quarterly	2019-05-04 03:07:27.271319+00
453	11	monthly	2019-07-05 13:47:35+00
447	445	weekly	2019-05-05 05:50:18.744017+00
126	20	monthly	2019-10-03 13:29:23+00
456	455	quarterly	2019-05-05 09:23:27.040936+00
149	2	quarterly	2019-10-04 00:50:21+00
458	455	quarterly	2019-05-05 09:26:00.168367+00
459	455	quarterly	2019-05-05 09:26:09.018155+00
396	393	biweekly	2019-07-14 15:46:30+00
232	230	quarterly	2019-10-04 01:01:04+00
864	20	23-09-2019	2019-09-03 16:53:41.477389+00
472	471	quarterly	2019-05-05 16:25:40.919356+00
477	401	weekly	2019-07-15 02:39:45+00
195	101	quarterly	2019-09-03 12:58:35+00
868	867	weekly	2019-09-06 13:07:18.949759+00
860	857	monthly	2019-09-20 13:17:02+00
425	401	02-11-2019	2019-05-03 20:50:08.346212+00
832	239	biweekly	2019-07-15 02:56:56+00
202	200	02-11-2019	2019-06-24 01:17:18+00
187	185	monthly	2019-10-04 01:03:23+00
774	140	02-11-2019	2019-05-29 19:28:11.664878+00
424	422	02-11-2019	2019-05-03 20:40:30.262677+00
262	104	monthly	2019-06-21 10:55:38+00
125	23	monthly	2019-10-03 12:52:51+00
780	778	31-05-2019	2019-05-30 02:33:46.552769+00
130	80	monthly	2019-10-03 12:54:01+00
86	33	biweekly	2019-10-03 13:23:46+00
473	196	biweekly	2019-05-23 02:05:26+00
839	836	08-11-2019	2019-07-05 09:20:54.8122+00
841	599	08-11-2019	2019-07-05 09:33:26.443445+00
156	153	weekly	2019-10-10 03:30:38+00
163	161	biweekly	2019-10-10 03:31:05+00
166	128	monthly	2019-10-10 06:27:24+00
210	206	biweekly	2019-10-13 07:36:08+00
258	256	weekly	2019-05-30 12:37:50+00
781	224	03-06-2019	2019-05-30 17:17:54.380081+00
452	398	daily	2019-05-30 13:48:17+00
460	175	weekly	2019-05-30 16:34:20+00
786	32	18-06-2019	2019-06-14 12:39:08.210401+00
383	16	biweekly	2019-05-21 03:07:05+00
785	239	03-07-2019	2019-06-13 07:04:45.996928+00
791	158	01-03-2020	2019-06-15 05:31:06.231539+00
264	140	weekly	2019-06-17 04:06:29+00
436	123	daily	2019-06-17 07:27:37+00
792	32	biweekly	2019-06-17 19:15:21.177194+00
214	212	monthly	2019-06-21 02:22:29+00
360	359	monthly	2019-06-21 02:50:54+00
799	797	weekly	2019-06-23 20:23:49.508504+00
795	217	weekly	2019-06-21 08:41:29.567044+00
801	796	27-06-2019	2019-06-23 20:24:34.346385+00
275	272	monthly	2019-06-24 15:22:21+00
451	196	weekly	2019-06-24 15:30:54+00
277	272	monthly	2019-06-24 15:42:38+00
303	301	monthly	2019-06-25 10:51:51+00
289	287	monthly	2019-06-25 11:07:00+00
293	291	monthly	2019-06-25 11:09:28+00
327	326	monthly	2019-06-26 03:56:46+00
307	175	weekly	2019-06-28 04:06:33+00
363	362	monthly	2019-07-03 09:02:50+00
349	348	monthly	2019-07-03 09:11:29+00
352	351	monthly	2019-07-03 09:30:16+00
369	368	monthly	2019-07-03 09:37:02+00
403	182	weekly	2019-07-03 09:46:36+00
373	371	monthly	2019-07-03 10:05:11+00
768	224	biweekly	2019-07-04 01:18:32+00
439	16	monthly	2019-07-04 03:21:19+00
752	172	weekly	2019-07-04 03:21:27+00
259	151	weekly	2019-07-04 04:45:46+00
448	233	weekly	2019-07-04 09:12:49+00
476	11	monthly	2019-07-06 23:44:50+00
311	309	biweekly	2019-07-07 12:49:21+00
384	382	biweekly	2019-07-07 13:03:15+00
321	319	biweekly	2019-07-07 16:44:40+00
312	309	biweekly	2019-07-14 15:46:14+00
215	212	monthly	2019-07-15 03:31:05+00
237	233	weekly	2019-07-15 07:45:00+00
843	837	monthly	2019-07-19 12:49:48.457301+00
488	486	quarterly	2019-05-07 08:22:37.9054+00
491	490	quarterly	2019-05-07 14:24:52.24647+00
492	357	monthly	2019-05-07 14:26:07.026399+00
493	317	monthly	2019-05-07 14:30:51.590963+00
494	345	monthly	2019-05-07 14:31:26.858291+00
496	330	monthly	2019-05-07 14:32:29.756401+00
497	314	monthly	2019-05-07 14:32:40.97842+00
498	375	monthly	2019-05-07 14:39:45.932261+00
514	239	weekly	2019-05-24 07:56:34+00
503	501	monthly	2019-05-08 06:56:47.241834+00
507	505	monthly	2019-05-08 07:05:20.330575+00
508	221	monthly	2019-05-08 13:14:39.299123+00
701	98	weekly	2019-05-24 08:01:55+00
850	847	monthly	2019-07-19 13:15:32.235746+00
856	587	monthly	2019-07-31 15:07:53.924074+00
605	600	08-11-2019	2019-05-14 12:59:03.326058+00
702	92	weekly	2019-05-26 00:36:26+00
495	147	weekly	2019-05-26 00:38:04+00
602	599	08-11-2019	2019-05-14 12:52:47.149359+00
604	601	08-11-2019	2019-05-14 12:56:19.031942+00
840	838	08-11-2019	2019-07-05 09:22:22.90508+00
518	516	quarterly	2019-05-12 05:45:14.354532+00
522	520	monthly	2019-05-12 21:09:42.592616+00
533	532	monthly	2019-05-13 06:26:14.871206+00
534	532	02-06-2019	2019-05-13 06:26:46.305133+00
535	532	quarterly	2019-05-13 06:28:14.027269+00
538	537	02-06-2019	2019-05-13 06:36:04.381993+00
539	521	monthly	2019-05-13 06:37:33.286989+00
751	16	biweekly	2019-05-26 06:25:56.585128+00
669	110	04-06-2019	2019-05-15 14:04:13.648541+00
543	84	quarterly	2019-05-13 06:39:46.690301+00
544	13	monthly	2019-05-13 06:41:44.108651+00
545	13	monthly	2019-05-13 06:42:20.240499+00
550	549	02-06-2019	2019-05-13 06:48:00.537372+00
555	340	quarterly	2019-05-13 12:53:43.787174+00
558	557	quarterly	2019-05-13 13:24:56.878052+00
560	47	02-06-2019	2019-05-13 13:30:51.403181+00
561	467	02-06-2019	2019-05-13 13:33:30.254043+00
568	566	monthly	2019-05-13 14:17:48.380868+00
572	570	monthly	2019-05-13 14:18:41.935389+00
577	576	quarterly	2019-05-13 14:27:16.206315+00
527	526	biweekly	2019-05-27 13:59:05+00
525	523	biweekly	2019-05-27 13:59:18+00
708	393	weekly	2019-05-28 03:03:28+00
573	401	biweekly	2019-05-28 08:47:49+00
622	151	weekly	2019-05-28 10:08:08+00
744	742	daily	2019-05-29 06:22:31+00
776	98	18-06-2019	2019-05-29 19:28:47.311283+00
740	182	weekly	2019-05-30 05:05:11+00
736	462	weekly	2019-05-30 06:59:07+00
519	239	weekly	2019-05-30 09:55:57+00
676	670	04-06-2019	2019-05-15 21:34:54.216243+00
614	612	daily	2019-05-14 14:20:16.258356+00
618	615	daily	2019-05-14 15:01:09.163308+00
254	69	daily	2019-05-30 12:52:24+00
531	530	biweekly	2019-05-30 13:06:25+00
629	626	weekly	2019-05-14 19:55:28.037291+00
633	631	daily	2019-05-15 04:28:20.169666+00
640	639	weekly	2019-05-15 07:15:16.472532+00
725	724	weekly	2019-05-30 16:34:12+00
646	645	monthly	2019-05-15 07:23:35.751969+00
647	645	monthly	2019-05-15 07:23:49.11694+00
699	230	weekly	2019-05-30 16:34:30+00
574	393	biweekly	2019-06-11 06:06:14+00
794	196	weekly	2019-06-17 19:17:16.130664+00
677	670	15-08-2019	2019-05-15 21:38:42.58649+00
548	546	biweekly	2019-06-17 15:28:28+00
513	319	biweekly	2019-06-20 14:01:38+00
705	206	08-06-2019	2019-05-19 07:23:18.776553+00
707	182	08-06-2019	2019-05-19 10:40:06.96206+00
716	713	daily	2019-05-21 13:10:54.318618+00
717	482	10-06-2019	2019-05-21 16:25:13.486157+00
484	482	biweekly	2019-05-21 12:26:59+00
718	74	11-06-2019	2019-05-22 06:40:36.558356+00
722	720	26-05-2019	2019-05-22 13:42:25.606431+00
726	724	11-06-2019	2019-05-22 17:12:10.28781+00
738	365	biweekly	2019-05-23 07:21:01.188456+00
\.


--
-- Data for Name: project; Type: TABLE DATA; Schema: public; Owner: amtiotumrffdbe
--

COPY public.project (id, login, title, created) FROM stdin;
1	yegor256	Z	2019-04-16 14:43:07.114842+00
2	mbarbieri	Test	2019-04-18 14:27:52.035898+00
3	terales	Test project	2019-04-23 13:16:52.630899+00
4	g4s8	test123	2019-04-24 16:56:12.522966+00
5	maratori	AAA	2019-04-28 10:42:28.893343+00
6	puzanov	GoDee	2019-04-29 06:06:18.943642+00
7	utsukushihito	testproject	2019-04-29 17:49:36.656251+00
9	dmydlarz	Kurs Wspolbieznosci	2019-04-30 14:55:13.430833+00
10	vmax	Test	2019-05-03 07:09:18.414346+00
11	trudax	Test1	2019-05-03 08:54:10.216177+00
12	jerrygreen	Test	2019-05-03 12:09:29.170872+00
13	0	test	2019-05-05 05:48:57.046427+00
15	serranya	test	2019-05-14 07:04:58.768881+00
16	amihaiemil	dja	2019-05-14 08:44:41.437068+00
17	g4s8	test1	2019-05-14 08:57:46.303328+00
18	apocryphe	Try	2019-05-14 08:59:06.465065+00
20	rdavid	Foobar	2019-05-14 10:33:09.701325+00
21	samuelpearce	CORE Ops	2019-05-14 11:47:35.580181+00
22	pomeryt	Test	2019-05-14 12:28:37.052617+00
23	max4d	test	2019-05-14 12:50:08.448429+00
24	runoftheshipe	Testing	2019-05-14 14:16:11.450036+00
25	andreygomenyuk	Test	2019-05-14 15:00:24.562472+00
26	blackcat	Pricing	2019-05-14 15:36:41.71847+00
27	govindsoft	Risk	2019-05-14 16:04:04.280005+00
28	sheymans	test	2019-05-14 18:23:37.11712+00
29	lastk	teste	2019-05-14 18:54:04.845846+00
30	lrozenblyum	test1	2019-05-14 19:54:36.303669+00
31	agungsantoso	My Project	2019-05-15 04:12:05.676375+00
32	rusnasonov	test	2019-05-15 05:35:10.591807+00
33	rusnasonov	bcl	2019-05-15 05:35:52.037001+00
34	pirent	nevisMeta	2019-05-15 07:11:50.941987+00
35	lemhell	test	2019-05-15 07:19:28.754804+00
37	leiter-jakab	34	2019-05-15 07:44:14.340646+00
38	smallcreep	test	2019-05-15 08:46:28.452377+00
39	nikolas-charalambidis	Test project	2019-05-15 13:06:52.446168+00
40	furgas	Test project	2019-05-15 21:06:32.463309+00
41	augustineric	SmP	2019-05-16 10:08:19.861291+00
42	int3hh	sms	2019-05-16 10:47:07.962553+00
43	tvjames	Sample	2019-05-16 11:05:07.309259+00
44	tbalashov	main	2019-05-18 07:54:31.162459+00
45	theautobot	zoldpower	2019-05-19 07:52:27.77469+00
47	artworx	test	2019-05-21 13:08:39.995979+00
48	mpyatishev	test	2019-05-22 13:38:15.604247+00
49	lilo	test	2019-05-23 07:09:05.579677+00
51	agorlov	ObjectMVC	2019-05-23 17:24:11.30954+00
52	msudgh	test5	2019-05-26 09:36:12.804578+00
55	funivan	test	2019-05-29 09:39:14.683511+00
57	m16deployer	test233	2019-05-29 10:20:44.815285+00
58	andriikolesnik	JRA	2019-05-29 10:34:17.724893+00
59	thumbnail	wat	2019-05-29 11:26:25.20938+00
60	madtribe	mgrds	2019-05-29 12:58:55.709537+00
61	antonini	Test	2019-05-29 14:19:48.964763+00
62	caarlos0	foo	2019-05-30 02:33:02.058723+00
63	malamili	9sig	2019-06-03 11:41:58.177332+00
64	stuporhero	OCI	2019-06-06 05:13:59.194153+00
65	etolstoy	test	2019-06-07 14:36:51.149611+00
66	kuptservol	зз	2019-06-10 15:26:55.963296+00
69	jherimum	Tokenizacao 	2019-06-23 12:16:39.819736+00
70	martinmayer	Test	2019-06-23 17:47:44.601572+00
103	ammaratef45	zold-mobile	2019-06-25 10:00:42.616165+00
104	lechuckcaptain	Test	2019-06-25 17:28:17.444308+00
105	moonkus	RMP check	2019-06-27 07:10:40.507474+00
106	mdieblich	Häuser KG	2019-07-03 14:15:29.288242+00
107	fomkin	test	2019-07-04 05:34:07.589254+00
108	insomnium	Adpt	2019-07-04 06:02:01.432795+00
109	byzantime	YangMingShan	2019-07-05 10:41:02.843392+00
110	bogdanovmn	Translator	2019-07-06 16:27:25.601076+00
112	kostasgrevenitis	TestProject	2019-08-02 09:54:34.260178+00
114	antonegorov	Penis	2019-08-02 13:14:51.208382+00
115	rok-povsic	test-proj	2019-08-11 15:37:16.17147+00
116	gukoff	tst	2019-08-15 13:04:25.638818+00
117	v-kolesnikov	foobar	2019-08-27 12:40:36.335977+00
118	nikita-idexcel	nik	2019-09-04 09:51:27.730665+00
119	bhawanisingh	tet	2019-09-06 13:05:29.188143+00
122	phnomb	SDV	2019-09-13 09:45:40.89216+00
123	evgbtrk	PetProject	2019-09-16 17:47:42.915569+00
124	kuraisu	0xdeadbeef	2019-09-27 16:41:33.647944+00
125	avolver	Test	2019-10-03 20:09:22.370315+00
126	apranzo	test	2019-10-15 20:37:12.982904+00
\.


--
-- Data for Name: risk; Type: TABLE DATA; Schema: public; Owner: amtiotumrffdbe
--

COPY public.risk (id, probability) FROM stdin;
94	4
7	4
8	4
147	1
123	4
39	5
12	2
66	5
18	2
153	6
74	5
455	5
778	5
161	4
34	4
158	5
783	8
48	4
557	6
119	5
51	4
239	5
29	5
46	5
549	4
92	4
2	2
291	5
200	6
113	6
203	4
212	1
797	5
466	5
128	6
620	5
563	4
834	5
566	2
570	4
224	4
386	5
230	5
233	8
390	6
247	6
393	6
250	9
304	5
295	5
182	5
317	5
401	6
365	5
837	5
375	5
588	6
416	4
309	2
516	2
412	2
576	8
328	4
445	5
847	6
301	5
140	5
428	2
579	4
853	8
858	6
862	4
520	6
523	5
866	5
597	5
532	4
5	5
600	5
546	2
57	2
80	5
116	5
36	5
501	4
77	2
505	2
132	2
90	1
256	5
371	5
192	5
221	5
110	5
298	5
196	5
354	5
490	5
379	5
419	5
151	5
526	5
98	5
185	5
357	5
278	5
323	5
362	5
348	5
345	5
168	5
287	5
314	5
422	5
188	5
335	4
337	4
359	4
272	4
377	4
326	4
107	4
319	4
624	5
627	5
104	2
342	2
351	2
368	2
406	2
330	2
332	2
340	2
266	2
398	5
462	5
172	4
179	4
175	5
217	4
486	5
482	5
60	5
54	4
83	5
23	5
282	5
20	5
42	4
612	8
15	4
616	5
631	2
638	6
651	4
667	4
696	5
674	4
671	5
679	4
685	4
691	5
693	2
704	6
206	8
101	5
706	5
714	8
720	6
541	4
728	2
731	2
734	8
742	5
724	5
745	8
69	8
32	4
755	5
759	5
762	2
765	5
382	5
537	5
529	5
645	5
10	5
63	2
770	6
772	2
\.


--
-- Data for Name: task; Type: TABLE DATA; Schema: public; Owner: amtiotumrffdbe
--

COPY public.task (id, plan, created) FROM stdin;
17	388	2019-05-05 08:53:02.12243+00
266	780	2019-05-31 00:03:38.526857+00
442	237	2019-10-13 07:07:05.014106+00
443	242	2019-10-13 11:44:15.229815+00
444	243	2019-10-13 11:44:15.296092+00
269	676	2019-06-04 00:02:48.414095+00
125	633	2019-05-16 19:06:51.771314+00
201	722	2019-05-26 00:00:59.430423+00
132	392	2019-05-17 09:44:11.087336+00
79	447	2019-05-12 05:51:02.996709+00
150	629	2019-05-21 20:00:04.207162+00
154	640	2019-05-22 07:23:42.750627+00
329	801	2019-06-27 00:05:10.386285+00
229	553	2019-05-29 07:37:47.494317+00
160	716	2019-05-22 13:13:50.603381+00
162	410	2019-05-23 00:04:07.754294+00
336	799	2019-06-30 20:23:55.816493+00
403	214	2019-08-01 19:46:50.220775+00
407	677	2019-08-15 00:04:16.730546+00
408	843	2019-08-18 12:54:03.144311+00
108	618	2019-05-15 18:35:33.945302+00
409	845	2019-08-18 13:04:10.25408+00
111	614	2019-05-15 18:35:34.003231+00
412	868	2019-09-13 13:13:30.608243+00
427	205	2019-10-04 08:44:29.693452+00
428	849	2019-10-09 14:31:54.567583+00
252	744	2019-05-30 06:23:51.894861+00
429	850	2019-10-09 14:31:54.589333+00
430	851	2019-10-09 14:31:54.607027+00
431	855	2019-10-09 14:31:54.627228+00
432	856	2019-10-09 14:31:54.652145+00
434	208	2019-10-10 07:39:31.063384+00
437	215	2019-10-10 10:30:27.797416+00
438	138	2019-10-10 16:42:27.509981+00
\.


--
-- Data for Name: telechat; Type: TABLE DATA; Schema: public; Owner: amtiotumrffdbe
--

COPY public.telechat (id, login, created, recent) FROM stdin;
446831437	g4s8	2019-05-15 08:43:29.643521+00	
894182484	samuelpearce	2019-05-15 15:10:58.834557+00	
6285406	tolsi	2019-05-17 12:09:17.763215+00	
122012427	injectz	2019-05-19 12:14:16.66863+00	
48257239	konyahin	2019-06-09 22:49:52.402599+00	
666504218	ammaratef45	2019-06-25 10:01:09.193187+00	
146554985	yegor256	2019-05-01 06:26:40.953695+00	Let me remind you that there are some tasks still required to be completed. There are 8 tasks in the list:\n \n  `T434` (-48) "Write a new blog post" Blog; Blog traffic may go down; Most of what I invested into the blog will be lost \n  `T442` (+32) "Polish and promote one GitHub repo from my collection" GitHub; I may get more followers and stars; GitHub will become a lead generator for me personally \n  `T444` (+30) "Update Twitter Ads for EO and CA" My books; The books may become very popular; The books will become the source of income + reputation \n  `T438` (-30) "Time machine full backup" Laptop; My SDD may break; Serious delay in work and some data losses \n  `T443` (+30) "Mail all known publishers" My books; The books may become very popular; The books will become the source of income + reputation \n  `T427` (-20) "Plan the next webinar" Blog; OOP webinars may die; A large part of OOP video audience will be lost \n  `T437` (+8) "Paint a new picture" Paintings; My paintings may become very popular and expensive; Selling paintings will generate good income \n  `T403` (+8) "Review and update my art accounts" Paintings; My paintings may become very popular and expensive; Selling paintings will generate good income \n\nWhen done with a task, say /done and I will remove it from the agenda.
112089839	gukoff	2019-08-15 13:04:52.413694+00	I didn't understand you, but I'm still with you, [gukoff](https://github.com/gukoff)! In this chat I inform you about the most important tasks you have in your agenda in [0rsk.com](https://www.0rsk.com).
\.


--
-- Data for Name: teleping; Type: TABLE DATA; Schema: public; Owner: amtiotumrffdbe
--

COPY public.teleping (id, task, telechat, updated) FROM stdin;
950	229	146554985	2019-06-13 14:35:06.338285+00
10165	434	146554985	2019-10-18 20:24:15.686802+00
10311	444	146554985	2019-10-18 20:24:15.692067+00
10178	438	146554985	2019-10-18 20:24:15.695531+00
10312	443	146554985	2019-10-18 20:24:15.697711+00
9884	427	146554985	2019-10-18 20:24:15.702303+00
864	162	146554985	2019-06-18 18:46:39.367136+00
6824	403	146554985	2019-10-18 20:24:15.710153+00
10302	442	146554985	2019-10-18 20:24:15.689827+00
10169	437	146554985	2019-10-18 20:24:15.705672+00
\.


--
-- Data for Name: triple; Type: TABLE DATA; Schema: public; Owner: amtiotumrffdbe
--

COPY public.triple (id, cause, risk, effect, created) FROM stdin;
3	4	7	6	2019-04-29 14:21:53.984818+00
4	4	8	6	2019-04-29 14:23:28.836528+00
6	9	12	13	2019-04-29 14:42:27.779914+00
8	17	18	19	2019-04-29 14:45:57.003657+00
14	4	34	35	2019-04-29 14:56:25.352401+00
17	41	42	43	2019-04-29 15:13:45.645498+00
18	41	42	44	2019-04-29 15:14:57.476721+00
20	4	48	49	2019-04-29 15:17:23.009361+00
34	65	92	93	2019-04-29 16:05:03.670247+00
35	28	94	95	2019-04-29 16:07:09.95463+00
41	112	113	114	2019-04-29 16:17:02.316939+00
47	127	128	129	2019-04-29 17:20:24.538495+00
63	146	147	148	2019-04-30 04:16:11.470222+00
65	134	153	154	2019-04-30 06:40:02.414806+00
67	160	161	162	2019-04-30 08:03:31.287791+00
78	199	200	201	2019-04-30 12:54:54.165193+00
79	199	203	204	2019-04-30 12:57:06.06884+00
84	184	224	225	2019-04-30 14:05:53.166747+00
85	229	230	231	2019-04-30 14:14:17.191156+00
86	229	233	234	2019-04-30 14:16:34.66626+00
88	139	247	248	2019-04-30 14:52:47.0547+00
89	249	250	251	2019-04-30 14:55:51.414215+00
112	112	328	315	2019-05-02 08:00:01.782142+00
120	300	301	346	2019-05-02 08:15:32.486969+00
121	139	140	346	2019-05-02 08:17:22.161993+00
135	385	386	387	2019-05-03 07:10:46.567497+00
136	389	390	391	2019-05-03 08:55:07.70911+00
137	134	393	394	2019-05-03 14:09:41.078207+00
73	150	182	152	2019-04-30 12:37:10.424878+00
140	150	401	394	2019-05-03 18:13:54.971241+00
148	444	445	446	2019-05-05 05:49:44.8286+00
159	184	520	521	2019-05-12 21:09:26.018819+00
160	139	523	524	2019-05-13 06:08:31.429321+00
163	528	532	521	2019-05-13 06:25:41.961524+00
5	9	10	11	2019-04-29 14:24:37.235136+00
2	4	5	6	2019-04-29 14:21:16.028663+00
168	4	546	547	2019-05-13 06:43:46.433473+00
24	56	57	58	2019-04-29 15:24:33.469261+00
13	31	32	33	2019-04-29 14:52:19.529719+00
31	79	80	81	2019-04-29 15:47:46.415111+00
42	115	116	117	2019-04-29 16:31:38.756372+00
15	4	36	37	2019-04-29 14:57:22.362581+00
156	500	501	502	2019-05-08 06:56:32.57735+00
30	76	77	78	2019-04-29 15:46:37.955082+00
157	504	505	506	2019-05-08 06:59:17.419394+00
55	131	132	133	2019-04-29 17:25:32.871417+00
33	89	90	91	2019-04-29 16:04:03.983749+00
90	255	256	257	2019-04-30 15:57:50.470852+00
130	370	371	372	2019-05-02 09:31:27.853258+00
76	191	192	193	2019-04-30 12:50:16.930471+00
83	220	221	222	2019-04-30 13:35:47.548785+00
28	31	69	70	2019-04-29 15:42:55.178819+00
40	109	110	111	2019-04-29 16:14:30.921036+00
99	294	298	296	2019-05-02 07:22:05.685699+00
77	134	196	197	2019-04-30 12:52:09.36236+00
124	353	354	346	2019-05-02 08:53:52.939316+00
21	50	51	52	2019-04-29 15:19:46.720538+00
155	489	490	346	2019-05-07 14:24:32.826746+00
144	415	416	346	2019-05-03 20:36:25.162471+00
133	378	379	346	2019-05-02 09:36:33.9694+00
145	418	419	346	2019-05-03 20:37:30.842591+00
64	150	151	152	2019-04-30 06:37:20.021372+00
161	139	526	524	2019-05-13 06:14:33.898217+00
36	97	98	99	2019-04-29 16:10:14.220313+00
74	184	185	186	2019-04-30 12:46:24.921263+00
131	374	375	346	2019-05-02 09:35:07.215636+00
125	356	357	315	2019-05-02 08:56:36.497111+00
93	127	278	279	2019-05-01 06:24:53.797809+00
37	100	101	102	2019-04-29 16:11:08.512242+00
109	322	323	315	2019-05-02 07:56:51.273316+00
127	361	362	315	2019-05-02 09:13:31.737494+00
128	364	365	346	2019-05-02 09:22:52.702091+00
122	347	348	346	2019-05-02 08:50:31.041056+00
119	344	345	346	2019-05-02 08:15:10.816773+00
104	167	168	315	2019-05-02 07:46:28.075986+00
111	286	287	315	2019-05-02 07:59:07.665002+00
103	313	314	315	2019-05-02 07:46:01.356873+00
146	421	422	423	2019-05-03 20:40:07.349628+00
75	112	188	189	2019-04-30 12:49:04.934218+00
115	334	335	315	2019-05-02 08:10:33.582691+00
116	336	337	315	2019-05-02 08:11:32.217616+00
126	358	359	315	2019-05-02 08:57:21.569283+00
105	271	272	315	2019-05-02 07:48:26.41507+00
132	376	377	315	2019-05-02 09:36:02.567659+00
102	308	309	310	2019-05-02 07:36:00.194161+00
110	325	326	315	2019-05-02 07:58:30.819736+00
39	106	107	108	2019-04-29 16:13:43.50376+00
108	318	319	320	2019-05-02 07:55:28.919143+00
80	199	206	207	2019-04-30 12:58:13.674422+00
286	575	576	346	2019-05-13 14:26:59.111672+00
143	411	412	413	2019-05-03 20:35:24.350371+00
38	103	104	105	2019-04-29 16:12:39.29858+00
118	341	342	315	2019-05-02 08:13:46.73685+00
123	350	351	315	2019-05-02 08:51:20.267016+00
129	367	368	315	2019-05-02 09:24:13.398719+00
141	405	406	315	2019-05-03 20:21:49.461024+00
113	329	330	315	2019-05-02 08:00:27.81651+00
114	331	332	315	2019-05-02 08:08:44.509674+00
117	339	340	315	2019-05-02 08:12:59.426125+00
91	265	266	267	2019-05-01 05:17:44.601708+00
138	397	398	399	2019-05-03 17:53:01.598172+00
150	461	462	463	2019-05-05 09:42:14.79508+00
69	171	172	173	2019-04-30 09:11:19.109478+00
72	178	179	180	2019-04-30 09:20:20.196374+00
71	174	175	176	2019-04-30 09:18:40.3071+00
82	146	217	218	2019-04-30 13:29:23.710998+00
98	294	295	296	2019-05-02 07:21:12.561691+00
154	485	486	487	2019-05-07 08:22:23.399468+00
153	481	482	483	2019-05-07 06:32:02.726802+00
25	59	60	61	2019-04-29 15:25:41.511258+00
22	53	54	55	2019-04-29 15:21:39.225027+00
32	82	83	84	2019-04-29 15:49:45.066384+00
10	22	23	24	2019-04-29 14:47:47.960789+00
94	229	282	283	2019-05-01 16:55:34.41273+00
26	62	63	64	2019-04-29 15:28:05.770279+00
9	17	20	21	2019-04-29 14:46:56.8132+00
152	41	42	471	2019-05-05 16:25:18.807439+00
45	122	123	124	2019-04-29 16:46:31.653783+00
7	14	15	16	2019-04-29 14:44:25.082943+00
257	150	39	40	2019-05-13 13:14:46.08718+00
27	65	66	67	2019-04-29 15:29:40.500722+00
259	150	74	75	2019-05-13 13:18:20.240549+00
149	454	455	346	2019-05-05 09:23:11.303245+00
66	157	158	159	2019-04-30 08:00:52.843655+00
262	556	557	296	2019-05-13 13:24:44.88521+00
43	118	119	120	2019-04-29 16:32:50.060041+00
87	238	239	240	2019-04-30 14:22:34.967877+00
12	28	29	30	2019-04-29 14:50:35.084516+00
266	150	46	47	2019-05-13 13:30:00.557359+00
170	56	549	108	2019-05-13 06:47:32.238574+00
1	1	2	3	2019-04-29 14:14:59.737246+00
96	290	291	292	2019-05-02 06:25:42.259987+00
158	515	516	517	2019-05-12 05:45:00.128993+00
81	211	212	213	2019-04-30 13:13:39.106261+00
151	465	466	467	2019-05-05 13:34:48.035217+00
273	562	563	564	2019-05-13 13:35:25.948427+00
275	565	566	567	2019-05-13 14:17:35.367488+00
276	569	570	571	2019-05-13 14:18:32.642187+00
101	300	304	305	2019-05-02 07:33:27.676309+00
107	316	317	315	2019-05-02 07:51:12.499826+00
134	381	382	16	2019-05-03 03:59:38.085368+00
166	536	537	521	2019-05-13 06:35:43.909852+00
162	528	529	530	2019-05-13 06:24:24.136396+00
147	427	428	429	2019-05-03 20:52:10.767281+00
288	578	579	580	2019-05-14 07:05:44.279129+00
294	596	597	598	2019-05-14 12:31:27.117352+00
295	599	600	601	2019-05-14 12:49:37.905691+00
298	611	612	613	2019-05-14 14:19:57.820407+00
299	615	616	617	2019-05-14 15:00:51.30484+00
300	619	620	621	2019-05-14 15:39:07.844163+00
301	623	624	625	2019-05-14 16:04:36.254691+00
302	626	627	628	2019-05-14 19:55:09.728366+00
303	630	631	632	2019-05-15 04:28:01.730531+00
306	637	638	639	2019-05-15 07:14:32.085837+00
308	650	651	652	2019-05-15 08:47:40.053922+00
315	670	674	675	2019-05-15 21:30:52.674559+00
312	670	671	672	2019-05-15 21:19:00.325757+00
319	690	691	692	2019-05-16 10:10:45.350317+00
320	690	693	694	2019-05-16 10:12:24.727968+00
321	695	696	697	2019-05-16 11:06:27.594534+00
322	703	704	197	2019-05-17 06:03:24.277117+00
327	100	706	517	2019-05-19 07:47:21.050376+00
329	713	714	715	2019-05-21 13:09:50.575429+00
330	719	720	721	2019-05-22 13:40:21.63993+00
332	727	728	729	2019-05-22 18:45:35.322642+00
333	730	731	732	2019-05-22 18:46:03.615388+00
336	733	734	735	2019-05-22 18:53:44.765681+00
337	741	742	743	2019-05-23 17:28:18.96822+00
331	723	724	346	2019-05-22 17:09:11.050305+00
339	220	745	746	2019-05-26 04:57:33.83474+00
342	754	755	756	2019-05-29 11:27:00.885487+00
343	757	755	756	2019-05-29 11:27:35.880081+00
344	758	759	760	2019-05-29 12:32:11.316551+00
345	761	762	763	2019-05-29 13:02:19.830446+00
346	764	765	766	2019-05-29 14:20:54.21227+00
347	767	765	766	2019-05-29 14:21:41.22976+00
307	644	645	108	2019-05-15 07:23:17.528228+00
356	769	770	315	2019-05-29 16:51:02.590516+00
357	771	772	773	2019-05-29 16:51:48.624815+00
359	777	778	779	2019-05-30 02:33:31.817942+00
360	782	783	784	2019-06-07 14:37:31.574844+00
167	540	541	84	2019-05-13 06:39:01.609537+00
364	796	797	798	2019-06-23 17:51:34.025106+00
397	833	834	835	2019-07-04 05:35:01.912893+00
398	836	837	838	2019-07-05 09:18:36.737125+00
291	587	588	589	2019-05-14 09:39:16.571068+00
403	846	847	848	2019-07-19 13:14:46.85524+00
404	587	853	854	2019-07-31 15:05:14.664587+00
405	857	858	859	2019-08-11 15:38:08.407081+00
406	861	862	863	2019-08-27 12:45:28.708843+00
407	865	866	867	2019-09-06 13:06:57.947061+00
\.


--
-- Name: part_id_seq; Type: SEQUENCE SET; Schema: public; Owner: amtiotumrffdbe
--

SELECT pg_catalog.setval('public.part_id_seq', 874, true);


--
-- Name: project_id_seq; Type: SEQUENCE SET; Schema: public; Owner: amtiotumrffdbe
--

SELECT pg_catalog.setval('public.project_id_seq', 126, true);


--
-- Name: task_id_seq; Type: SEQUENCE SET; Schema: public; Owner: amtiotumrffdbe
--

SELECT pg_catalog.setval('public.task_id_seq', 444, true);


--
-- Name: telechat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: amtiotumrffdbe
--

SELECT pg_catalog.setval('public.telechat_id_seq', 1, false);


--
-- Name: teleping_id_seq; Type: SEQUENCE SET; Schema: public; Owner: amtiotumrffdbe
--

SELECT pg_catalog.setval('public.teleping_id_seq', 10568, true);


--
-- Name: triple_id_seq; Type: SEQUENCE SET; Schema: public; Owner: amtiotumrffdbe
--

SELECT pg_catalog.setval('public.triple_id_seq', 408, true);


--
-- Name: cause cause_pkey; Type: CONSTRAINT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.cause
    ADD CONSTRAINT cause_pkey PRIMARY KEY (id);


--
-- Name: effect effect_pkey; Type: CONSTRAINT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.effect
    ADD CONSTRAINT effect_pkey PRIMARY KEY (id);


--
-- Name: part part_pkey; Type: CONSTRAINT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.part
    ADD CONSTRAINT part_pkey PRIMARY KEY (id);


--
-- Name: part part_project_text_key; Type: CONSTRAINT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.part
    ADD CONSTRAINT part_project_text_key UNIQUE (project, text);


--
-- Name: databasechangeloglock pk_databasechangeloglock; Type: CONSTRAINT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.databasechangeloglock
    ADD CONSTRAINT pk_databasechangeloglock PRIMARY KEY (id);


--
-- Name: plan plan_id_part_key; Type: CONSTRAINT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.plan
    ADD CONSTRAINT plan_id_part_key UNIQUE (id, part);


--
-- Name: project project_pkey; Type: CONSTRAINT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.project
    ADD CONSTRAINT project_pkey PRIMARY KEY (id);


--
-- Name: risk risk_pkey; Type: CONSTRAINT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.risk
    ADD CONSTRAINT risk_pkey PRIMARY KEY (id);


--
-- Name: task task_pkey; Type: CONSTRAINT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.task
    ADD CONSTRAINT task_pkey PRIMARY KEY (id);


--
-- Name: task task_plan_key; Type: CONSTRAINT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.task
    ADD CONSTRAINT task_plan_key UNIQUE (plan);


--
-- Name: telechat telechat_login_key; Type: CONSTRAINT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.telechat
    ADD CONSTRAINT telechat_login_key UNIQUE (login);


--
-- Name: telechat telechat_pkey; Type: CONSTRAINT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.telechat
    ADD CONSTRAINT telechat_pkey PRIMARY KEY (id);


--
-- Name: teleping teleping_pkey; Type: CONSTRAINT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.teleping
    ADD CONSTRAINT teleping_pkey PRIMARY KEY (id);


--
-- Name: triple triple_cause_risk_effect_key; Type: CONSTRAINT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.triple
    ADD CONSTRAINT triple_cause_risk_effect_key UNIQUE (cause, risk, effect);


--
-- Name: triple triple_pkey; Type: CONSTRAINT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.triple
    ADD CONSTRAINT triple_pkey PRIMARY KEY (id);


--
-- Name: teleping unique_tasks; Type: CONSTRAINT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.teleping
    ADD CONSTRAINT unique_tasks UNIQUE (task, telechat);


--
-- Name: project unique_title; Type: CONSTRAINT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.project
    ADD CONSTRAINT unique_title UNIQUE (login, title);


--
-- Name: idx_effect1; Type: INDEX; Schema: public; Owner: amtiotumrffdbe
--

CREATE INDEX idx_effect1 ON public.effect USING btree (impact);


--
-- Name: idx_part1; Type: INDEX; Schema: public; Owner: amtiotumrffdbe
--

CREATE INDEX idx_part1 ON public.part USING btree (project, created);


--
-- Name: idx_plan1; Type: INDEX; Schema: public; Owner: amtiotumrffdbe
--

CREATE INDEX idx_plan1 ON public.plan USING btree (part);


--
-- Name: idx_project1; Type: INDEX; Schema: public; Owner: amtiotumrffdbe
--

CREATE INDEX idx_project1 ON public.project USING btree (login);


--
-- Name: idx_risk1; Type: INDEX; Schema: public; Owner: amtiotumrffdbe
--

CREATE INDEX idx_risk1 ON public.risk USING btree (probability);


--
-- Name: idx_task1; Type: INDEX; Schema: public; Owner: amtiotumrffdbe
--

CREATE INDEX idx_task1 ON public.task USING btree (plan);


--
-- Name: idx_telechat1; Type: INDEX; Schema: public; Owner: amtiotumrffdbe
--

CREATE INDEX idx_telechat1 ON public.telechat USING btree (login);


--
-- Name: idx_teleping1; Type: INDEX; Schema: public; Owner: amtiotumrffdbe
--

CREATE INDEX idx_teleping1 ON public.teleping USING btree (task);


--
-- Name: idx_teleping2; Type: INDEX; Schema: public; Owner: amtiotumrffdbe
--

CREATE INDEX idx_teleping2 ON public.teleping USING btree (updated);


--
-- Name: idx_triple1; Type: INDEX; Schema: public; Owner: amtiotumrffdbe
--

CREATE INDEX idx_triple1 ON public.triple USING btree (cause, risk, effect);


--
-- Name: cause cause_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.cause
    ADD CONSTRAINT cause_id_fkey FOREIGN KEY (id) REFERENCES public.part(id) ON DELETE CASCADE;


--
-- Name: effect effect_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.effect
    ADD CONSTRAINT effect_id_fkey FOREIGN KEY (id) REFERENCES public.part(id) ON DELETE CASCADE;


--
-- Name: part part_project_fkey; Type: FK CONSTRAINT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.part
    ADD CONSTRAINT part_project_fkey FOREIGN KEY (project) REFERENCES public.project(id) ON DELETE CASCADE;


--
-- Name: plan plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.plan
    ADD CONSTRAINT plan_id_fkey FOREIGN KEY (id) REFERENCES public.part(id) ON DELETE CASCADE;


--
-- Name: plan plan_part_fkey; Type: FK CONSTRAINT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.plan
    ADD CONSTRAINT plan_part_fkey FOREIGN KEY (part) REFERENCES public.part(id) ON DELETE CASCADE;


--
-- Name: risk risk_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.risk
    ADD CONSTRAINT risk_id_fkey FOREIGN KEY (id) REFERENCES public.part(id) ON DELETE CASCADE;


--
-- Name: task task_plan_fkey; Type: FK CONSTRAINT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.task
    ADD CONSTRAINT task_plan_fkey FOREIGN KEY (plan) REFERENCES public.part(id) ON DELETE CASCADE;


--
-- Name: teleping teleping_task_fkey; Type: FK CONSTRAINT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.teleping
    ADD CONSTRAINT teleping_task_fkey FOREIGN KEY (task) REFERENCES public.task(id) ON DELETE CASCADE;


--
-- Name: teleping teleping_telechat_fkey; Type: FK CONSTRAINT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.teleping
    ADD CONSTRAINT teleping_telechat_fkey FOREIGN KEY (telechat) REFERENCES public.telechat(id) ON DELETE CASCADE;


--
-- Name: triple triple_cause_fkey; Type: FK CONSTRAINT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.triple
    ADD CONSTRAINT triple_cause_fkey FOREIGN KEY (cause) REFERENCES public.cause(id) ON DELETE CASCADE;


--
-- Name: triple triple_effect_fkey; Type: FK CONSTRAINT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.triple
    ADD CONSTRAINT triple_effect_fkey FOREIGN KEY (effect) REFERENCES public.effect(id) ON DELETE CASCADE;


--
-- Name: triple triple_risk_fkey; Type: FK CONSTRAINT; Schema: public; Owner: amtiotumrffdbe
--

ALTER TABLE ONLY public.triple
    ADD CONSTRAINT triple_risk_fkey FOREIGN KEY (risk) REFERENCES public.risk(id) ON DELETE CASCADE;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: amtiotumrffdbe
--

REVOKE ALL ON SCHEMA public FROM postgres;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO amtiotumrffdbe;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: LANGUAGE plpgsql; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON LANGUAGE plpgsql TO amtiotumrffdbe;


--
-- PostgreSQL database dump complete
--

