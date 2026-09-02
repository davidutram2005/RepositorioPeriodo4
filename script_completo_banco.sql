--
-- PostgreSQL database dump
--

\restrict Pjh3wbK6m5PZIe3LYgAjZS00XGxiImWMpcWocOcZcVnrTYbXUZWZPIn4p7uDyeg

-- Dumped from database version 18.6
-- Dumped by pg_dump version 18.4

-- Started on 2026-09-01 21:20:59

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 6 (class 2615 OID 16486)
-- Name: adm; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA adm;


ALTER SCHEMA adm OWNER TO postgres;

--
-- TOC entry 7 (class 2615 OID 16487)
-- Name: contabil; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA contabil;


ALTER SCHEMA contabil OWNER TO postgres;

--
-- TOC entry 5 (class 2615 OID 16485)
-- Name: site; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA site;


ALTER SCHEMA site OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 236 (class 1259 OID 16589)
-- Name: fornecedor; Type: TABLE; Schema: adm; Owner: postgres
--

CREATE TABLE adm.fornecedor (
    id_fornecedor integer NOT NULL,
    razao_social character varying(150) NOT NULL,
    cnpj character varying(18) NOT NULL,
    telefone character varying(20),
    email character varying(100)
);


ALTER TABLE adm.fornecedor OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 16588)
-- Name: fornecedor_id_fornecedor_seq; Type: SEQUENCE; Schema: adm; Owner: postgres
--

CREATE SEQUENCE adm.fornecedor_id_fornecedor_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE adm.fornecedor_id_fornecedor_seq OWNER TO postgres;

--
-- TOC entry 5210 (class 0 OID 0)
-- Dependencies: 235
-- Name: fornecedor_id_fornecedor_seq; Type: SEQUENCE OWNED BY; Schema: adm; Owner: postgres
--

ALTER SEQUENCE adm.fornecedor_id_fornecedor_seq OWNED BY adm.fornecedor.id_fornecedor;


--
-- TOC entry 234 (class 1259 OID 16571)
-- Name: funcionario; Type: TABLE; Schema: adm; Owner: postgres
--

CREATE TABLE adm.funcionario (
    id_funcionario integer NOT NULL,
    nome character varying(100) NOT NULL,
    cpf character varying(14) NOT NULL,
    cargo character varying(50) NOT NULL,
    email character varying(100) NOT NULL,
    data_admissao date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE adm.funcionario OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 16570)
-- Name: funcionario_id_funcionario_seq; Type: SEQUENCE; Schema: adm; Owner: postgres
--

CREATE SEQUENCE adm.funcionario_id_funcionario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE adm.funcionario_id_funcionario_seq OWNER TO postgres;

--
-- TOC entry 5211 (class 0 OID 0)
-- Dependencies: 233
-- Name: funcionario_id_funcionario_seq; Type: SEQUENCE OWNED BY; Schema: adm; Owner: postgres
--

ALTER SEQUENCE adm.funcionario_id_funcionario_seq OWNED BY adm.funcionario.id_funcionario;


--
-- TOC entry 240 (class 1259 OID 16620)
-- Name: item_ordem_servico; Type: TABLE; Schema: adm; Owner: postgres
--

CREATE TABLE adm.item_ordem_servico (
    id_item_os integer NOT NULL,
    id_os integer,
    descricao_servico_peca character varying(150) NOT NULL,
    quantidade integer DEFAULT 1 NOT NULL,
    valor_unitario numeric(10,2) NOT NULL
);


ALTER TABLE adm.item_ordem_servico OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 16619)
-- Name: item_ordem_servico_id_item_os_seq; Type: SEQUENCE; Schema: adm; Owner: postgres
--

CREATE SEQUENCE adm.item_ordem_servico_id_item_os_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE adm.item_ordem_servico_id_item_os_seq OWNER TO postgres;

--
-- TOC entry 5212 (class 0 OID 0)
-- Dependencies: 239
-- Name: item_ordem_servico_id_item_os_seq; Type: SEQUENCE OWNED BY; Schema: adm; Owner: postgres
--

ALTER SEQUENCE adm.item_ordem_servico_id_item_os_seq OWNED BY adm.item_ordem_servico.id_item_os;


--
-- TOC entry 242 (class 1259 OID 16637)
-- Name: movimentacao_estoque; Type: TABLE; Schema: adm; Owner: postgres
--

CREATE TABLE adm.movimentacao_estoque (
    id_movimentacao integer NOT NULL,
    id_peca integer,
    id_fornecedor integer,
    tipo_movimentacao character varying(20) NOT NULL,
    quantidade integer NOT NULL,
    data_movimentacao timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT movimentacao_estoque_tipo_movimentacao_check CHECK (((tipo_movimentacao)::text = ANY ((ARRAY['ENTRADA'::character varying, 'SAIDA'::character varying, 'AJUSTE'::character varying])::text[])))
);


ALTER TABLE adm.movimentacao_estoque OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 16636)
-- Name: movimentacao_estoque_id_movimentacao_seq; Type: SEQUENCE; Schema: adm; Owner: postgres
--

CREATE SEQUENCE adm.movimentacao_estoque_id_movimentacao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE adm.movimentacao_estoque_id_movimentacao_seq OWNER TO postgres;

--
-- TOC entry 5213 (class 0 OID 0)
-- Dependencies: 241
-- Name: movimentacao_estoque_id_movimentacao_seq; Type: SEQUENCE OWNED BY; Schema: adm; Owner: postgres
--

ALTER SEQUENCE adm.movimentacao_estoque_id_movimentacao_seq OWNED BY adm.movimentacao_estoque.id_movimentacao;


--
-- TOC entry 238 (class 1259 OID 16601)
-- Name: ordem_servico; Type: TABLE; Schema: adm; Owner: postgres
--

CREATE TABLE adm.ordem_servico (
    id_os integer NOT NULL,
    id_funcionario integer,
    cliente_nome character varying(100) NOT NULL,
    cliente_telefone character varying(20),
    veiculo_descricao character varying(100) NOT NULL,
    status character varying(30) DEFAULT 'Em Aberto'::character varying NOT NULL,
    data_abertura timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    valor_total numeric(10,2) DEFAULT 0.00
);


ALTER TABLE adm.ordem_servico OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 16600)
-- Name: ordem_servico_id_os_seq; Type: SEQUENCE; Schema: adm; Owner: postgres
--

CREATE SEQUENCE adm.ordem_servico_id_os_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE adm.ordem_servico_id_os_seq OWNER TO postgres;

--
-- TOC entry 5214 (class 0 OID 0)
-- Dependencies: 237
-- Name: ordem_servico_id_os_seq; Type: SEQUENCE OWNED BY; Schema: adm; Owner: postgres
--

ALTER SEQUENCE adm.ordem_servico_id_os_seq OWNED BY adm.ordem_servico.id_os;


--
-- TOC entry 248 (class 1259 OID 16699)
-- Name: conta_pagar_receber; Type: TABLE; Schema: contabil; Owner: postgres
--

CREATE TABLE contabil.conta_pagar_receber (
    id_titulo integer NOT NULL,
    id_conta integer,
    id_nota integer,
    tipo character varying(10) NOT NULL,
    descricao character varying(150) NOT NULL,
    valor numeric(10,2) NOT NULL,
    data_vencimento date NOT NULL,
    status character varying(20) DEFAULT 'PENDENTE'::character varying,
    CONSTRAINT conta_pagar_receber_status_check CHECK (((status)::text = ANY ((ARRAY['PENDENTE'::character varying, 'PAGO'::character varying, 'CANCELADO'::character varying])::text[]))),
    CONSTRAINT conta_pagar_receber_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['PAGAR'::character varying, 'RECEBER'::character varying])::text[])))
);


ALTER TABLE contabil.conta_pagar_receber OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 16698)
-- Name: conta_pagar_receber_id_titulo_seq; Type: SEQUENCE; Schema: contabil; Owner: postgres
--

CREATE SEQUENCE contabil.conta_pagar_receber_id_titulo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE contabil.conta_pagar_receber_id_titulo_seq OWNER TO postgres;

--
-- TOC entry 5215 (class 0 OID 0)
-- Dependencies: 247
-- Name: conta_pagar_receber_id_titulo_seq; Type: SEQUENCE OWNED BY; Schema: contabil; Owner: postgres
--

ALTER SEQUENCE contabil.conta_pagar_receber_id_titulo_seq OWNED BY contabil.conta_pagar_receber.id_titulo;


--
-- TOC entry 252 (class 1259 OID 16740)
-- Name: fechamento_mensal; Type: TABLE; Schema: contabil; Owner: postgres
--

CREATE TABLE contabil.fechamento_mensal (
    id_fechamento integer NOT NULL,
    mes_referencia integer NOT NULL,
    ano_referencia integer NOT NULL,
    total_receitas numeric(12,2) DEFAULT 0.00 NOT NULL,
    total_despesas numeric(12,2) DEFAULT 0.00 NOT NULL,
    impostos_devidos numeric(10,2) DEFAULT 0.00 NOT NULL,
    status character varying(20) DEFAULT 'FECHADO'::character varying,
    CONSTRAINT fechamento_mensal_mes_referencia_check CHECK (((mes_referencia >= 1) AND (mes_referencia <= 12)))
);


ALTER TABLE contabil.fechamento_mensal OWNER TO postgres;

--
-- TOC entry 251 (class 1259 OID 16739)
-- Name: fechamento_mensal_id_fechamento_seq; Type: SEQUENCE; Schema: contabil; Owner: postgres
--

CREATE SEQUENCE contabil.fechamento_mensal_id_fechamento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE contabil.fechamento_mensal_id_fechamento_seq OWNER TO postgres;

--
-- TOC entry 5216 (class 0 OID 0)
-- Dependencies: 251
-- Name: fechamento_mensal_id_fechamento_seq; Type: SEQUENCE OWNED BY; Schema: contabil; Owner: postgres
--

ALTER SEQUENCE contabil.fechamento_mensal_id_fechamento_seq OWNED BY contabil.fechamento_mensal.id_fechamento;


--
-- TOC entry 250 (class 1259 OID 16724)
-- Name: lancamento_financeiro; Type: TABLE; Schema: contabil; Owner: postgres
--

CREATE TABLE contabil.lancamento_financeiro (
    id_lancamento integer NOT NULL,
    id_titulo integer,
    forma_pagamento character varying(50) NOT NULL,
    valor_pago numeric(10,2) NOT NULL,
    data_pagamento timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE contabil.lancamento_financeiro OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 16723)
-- Name: lancamento_financeiro_id_lancamento_seq; Type: SEQUENCE; Schema: contabil; Owner: postgres
--

CREATE SEQUENCE contabil.lancamento_financeiro_id_lancamento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE contabil.lancamento_financeiro_id_lancamento_seq OWNER TO postgres;

--
-- TOC entry 5217 (class 0 OID 0)
-- Dependencies: 249
-- Name: lancamento_financeiro_id_lancamento_seq; Type: SEQUENCE OWNED BY; Schema: contabil; Owner: postgres
--

ALTER SEQUENCE contabil.lancamento_financeiro_id_lancamento_seq OWNED BY contabil.lancamento_financeiro.id_lancamento;


--
-- TOC entry 246 (class 1259 OID 16673)
-- Name: nota_fiscal; Type: TABLE; Schema: contabil; Owner: postgres
--

CREATE TABLE contabil.nota_fiscal (
    id_nota integer NOT NULL,
    numero_nf character varying(30) NOT NULL,
    chave_acesso character varying(44),
    tipo_operacao character varying(10) NOT NULL,
    id_os integer,
    id_fornecedor integer,
    valor_total numeric(10,2) NOT NULL,
    valor_impostos numeric(10,2) DEFAULT 0.00,
    data_emissao timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT nota_fiscal_tipo_operacao_check CHECK (((tipo_operacao)::text = ANY ((ARRAY['ENTRADA'::character varying, 'SAIDA'::character varying])::text[])))
);


ALTER TABLE contabil.nota_fiscal OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 16672)
-- Name: nota_fiscal_id_nota_seq; Type: SEQUENCE; Schema: contabil; Owner: postgres
--

CREATE SEQUENCE contabil.nota_fiscal_id_nota_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE contabil.nota_fiscal_id_nota_seq OWNER TO postgres;

--
-- TOC entry 5218 (class 0 OID 0)
-- Dependencies: 245
-- Name: nota_fiscal_id_nota_seq; Type: SEQUENCE OWNED BY; Schema: contabil; Owner: postgres
--

ALTER SEQUENCE contabil.nota_fiscal_id_nota_seq OWNED BY contabil.nota_fiscal.id_nota;


--
-- TOC entry 244 (class 1259 OID 16659)
-- Name: plano_contas; Type: TABLE; Schema: contabil; Owner: postgres
--

CREATE TABLE contabil.plano_contas (
    id_conta integer NOT NULL,
    codigo_conta character varying(20) NOT NULL,
    descricao character varying(100) NOT NULL,
    tipo_conta character varying(20) NOT NULL,
    CONSTRAINT plano_contas_tipo_conta_check CHECK (((tipo_conta)::text = ANY ((ARRAY['RECEITA'::character varying, 'DESPESA'::character varying, 'ATIVO'::character varying, 'PASSIVO'::character varying])::text[])))
);


ALTER TABLE contabil.plano_contas OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 16658)
-- Name: plano_contas_id_conta_seq; Type: SEQUENCE; Schema: contabil; Owner: postgres
--

CREATE SEQUENCE contabil.plano_contas_id_conta_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE contabil.plano_contas_id_conta_seq OWNER TO postgres;

--
-- TOC entry 5219 (class 0 OID 0)
-- Dependencies: 243
-- Name: plano_contas_id_conta_seq; Type: SEQUENCE OWNED BY; Schema: contabil; Owner: postgres
--

ALTER SEQUENCE contabil.plano_contas_id_conta_seq OWNED BY contabil.plano_contas.id_conta;


--
-- TOC entry 228 (class 1259 OID 16526)
-- Name: categoria; Type: TABLE; Schema: site; Owner: postgres
--

CREATE TABLE site.categoria (
    id_categoria integer NOT NULL,
    nome_categoria character varying(100) NOT NULL
);


ALTER TABLE site.categoria OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 16525)
-- Name: categoria_id_categoria_seq; Type: SEQUENCE; Schema: site; Owner: postgres
--

CREATE SEQUENCE site.categoria_id_categoria_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE site.categoria_id_categoria_seq OWNER TO postgres;

--
-- TOC entry 5220 (class 0 OID 0)
-- Dependencies: 227
-- Name: categoria_id_categoria_seq; Type: SEQUENCE OWNED BY; Schema: site; Owner: postgres
--

ALTER SEQUENCE site.categoria_id_categoria_seq OWNED BY site.categoria.id_categoria;


--
-- TOC entry 232 (class 1259 OID 16551)
-- Name: compatibilidade; Type: TABLE; Schema: site; Owner: postgres
--

CREATE TABLE site.compatibilidade (
    id_compatibilidade integer NOT NULL,
    id_peca integer,
    id_veiculo integer,
    posicao_aplicacao character varying(100),
    obs text
);


ALTER TABLE site.compatibilidade OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 16550)
-- Name: compatibilidade_id_compatibilidade_seq; Type: SEQUENCE; Schema: site; Owner: postgres
--

CREATE SEQUENCE site.compatibilidade_id_compatibilidade_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE site.compatibilidade_id_compatibilidade_seq OWNER TO postgres;

--
-- TOC entry 5221 (class 0 OID 0)
-- Dependencies: 231
-- Name: compatibilidade_id_compatibilidade_seq; Type: SEQUENCE OWNED BY; Schema: site; Owner: postgres
--

ALTER SEQUENCE site.compatibilidade_id_compatibilidade_seq OWNED BY site.compatibilidade.id_compatibilidade;


--
-- TOC entry 222 (class 1259 OID 16489)
-- Name: marca; Type: TABLE; Schema: site; Owner: postgres
--

CREATE TABLE site.marca (
    id_marca integer NOT NULL,
    nome_marca character varying(100) NOT NULL
);


ALTER TABLE site.marca OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16488)
-- Name: marca_id_marca_seq; Type: SEQUENCE; Schema: site; Owner: postgres
--

CREATE SEQUENCE site.marca_id_marca_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE site.marca_id_marca_seq OWNER TO postgres;

--
-- TOC entry 5222 (class 0 OID 0)
-- Dependencies: 221
-- Name: marca_id_marca_seq; Type: SEQUENCE OWNED BY; Schema: site; Owner: postgres
--

ALTER SEQUENCE site.marca_id_marca_seq OWNED BY site.marca.id_marca;


--
-- TOC entry 224 (class 1259 OID 16498)
-- Name: modelo; Type: TABLE; Schema: site; Owner: postgres
--

CREATE TABLE site.modelo (
    id_modelo integer NOT NULL,
    id_marca integer,
    nome_modelo character varying(100) NOT NULL
);


ALTER TABLE site.modelo OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16497)
-- Name: modelo_id_modelo_seq; Type: SEQUENCE; Schema: site; Owner: postgres
--

CREATE SEQUENCE site.modelo_id_modelo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE site.modelo_id_modelo_seq OWNER TO postgres;

--
-- TOC entry 5223 (class 0 OID 0)
-- Dependencies: 223
-- Name: modelo_id_modelo_seq; Type: SEQUENCE OWNED BY; Schema: site; Owner: postgres
--

ALTER SEQUENCE site.modelo_id_modelo_seq OWNED BY site.modelo.id_modelo;


--
-- TOC entry 230 (class 1259 OID 16535)
-- Name: peca; Type: TABLE; Schema: site; Owner: postgres
--

CREATE TABLE site.peca (
    id_peca integer NOT NULL,
    id_categoria integer,
    nome_peca character varying(150) NOT NULL,
    fabricante character varying(100),
    codigo_fabricante character varying(50),
    preco_venda numeric(10,2) NOT NULL,
    qnt_estoque integer DEFAULT 0
);


ALTER TABLE site.peca OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 16534)
-- Name: peca_id_peca_seq; Type: SEQUENCE; Schema: site; Owner: postgres
--

CREATE SEQUENCE site.peca_id_peca_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE site.peca_id_peca_seq OWNER TO postgres;

--
-- TOC entry 5224 (class 0 OID 0)
-- Dependencies: 229
-- Name: peca_id_peca_seq; Type: SEQUENCE OWNED BY; Schema: site; Owner: postgres
--

ALTER SEQUENCE site.peca_id_peca_seq OWNED BY site.peca.id_peca;


--
-- TOC entry 226 (class 1259 OID 16512)
-- Name: veiculo; Type: TABLE; Schema: site; Owner: postgres
--

CREATE TABLE site.veiculo (
    id_veiculo integer NOT NULL,
    id_modelo integer,
    ano_fabricacao integer NOT NULL,
    motorizacao character varying(50),
    combustivel character varying(30)
);


ALTER TABLE site.veiculo OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 16511)
-- Name: veiculo_id_veiculo_seq; Type: SEQUENCE; Schema: site; Owner: postgres
--

CREATE SEQUENCE site.veiculo_id_veiculo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE site.veiculo_id_veiculo_seq OWNER TO postgres;

--
-- TOC entry 5225 (class 0 OID 0)
-- Dependencies: 225
-- Name: veiculo_id_veiculo_seq; Type: SEQUENCE OWNED BY; Schema: site; Owner: postgres
--

ALTER SEQUENCE site.veiculo_id_veiculo_seq OWNED BY site.veiculo.id_veiculo;


--
-- TOC entry 4942 (class 2604 OID 16592)
-- Name: fornecedor id_fornecedor; Type: DEFAULT; Schema: adm; Owner: postgres
--

ALTER TABLE ONLY adm.fornecedor ALTER COLUMN id_fornecedor SET DEFAULT nextval('adm.fornecedor_id_fornecedor_seq'::regclass);


--
-- TOC entry 4940 (class 2604 OID 16574)
-- Name: funcionario id_funcionario; Type: DEFAULT; Schema: adm; Owner: postgres
--

ALTER TABLE ONLY adm.funcionario ALTER COLUMN id_funcionario SET DEFAULT nextval('adm.funcionario_id_funcionario_seq'::regclass);


--
-- TOC entry 4947 (class 2604 OID 16623)
-- Name: item_ordem_servico id_item_os; Type: DEFAULT; Schema: adm; Owner: postgres
--

ALTER TABLE ONLY adm.item_ordem_servico ALTER COLUMN id_item_os SET DEFAULT nextval('adm.item_ordem_servico_id_item_os_seq'::regclass);


--
-- TOC entry 4949 (class 2604 OID 16640)
-- Name: movimentacao_estoque id_movimentacao; Type: DEFAULT; Schema: adm; Owner: postgres
--

ALTER TABLE ONLY adm.movimentacao_estoque ALTER COLUMN id_movimentacao SET DEFAULT nextval('adm.movimentacao_estoque_id_movimentacao_seq'::regclass);


--
-- TOC entry 4943 (class 2604 OID 16604)
-- Name: ordem_servico id_os; Type: DEFAULT; Schema: adm; Owner: postgres
--

ALTER TABLE ONLY adm.ordem_servico ALTER COLUMN id_os SET DEFAULT nextval('adm.ordem_servico_id_os_seq'::regclass);


--
-- TOC entry 4955 (class 2604 OID 16702)
-- Name: conta_pagar_receber id_titulo; Type: DEFAULT; Schema: contabil; Owner: postgres
--

ALTER TABLE ONLY contabil.conta_pagar_receber ALTER COLUMN id_titulo SET DEFAULT nextval('contabil.conta_pagar_receber_id_titulo_seq'::regclass);


--
-- TOC entry 4959 (class 2604 OID 16743)
-- Name: fechamento_mensal id_fechamento; Type: DEFAULT; Schema: contabil; Owner: postgres
--

ALTER TABLE ONLY contabil.fechamento_mensal ALTER COLUMN id_fechamento SET DEFAULT nextval('contabil.fechamento_mensal_id_fechamento_seq'::regclass);


--
-- TOC entry 4957 (class 2604 OID 16727)
-- Name: lancamento_financeiro id_lancamento; Type: DEFAULT; Schema: contabil; Owner: postgres
--

ALTER TABLE ONLY contabil.lancamento_financeiro ALTER COLUMN id_lancamento SET DEFAULT nextval('contabil.lancamento_financeiro_id_lancamento_seq'::regclass);


--
-- TOC entry 4952 (class 2604 OID 16676)
-- Name: nota_fiscal id_nota; Type: DEFAULT; Schema: contabil; Owner: postgres
--

ALTER TABLE ONLY contabil.nota_fiscal ALTER COLUMN id_nota SET DEFAULT nextval('contabil.nota_fiscal_id_nota_seq'::regclass);


--
-- TOC entry 4951 (class 2604 OID 16662)
-- Name: plano_contas id_conta; Type: DEFAULT; Schema: contabil; Owner: postgres
--

ALTER TABLE ONLY contabil.plano_contas ALTER COLUMN id_conta SET DEFAULT nextval('contabil.plano_contas_id_conta_seq'::regclass);


--
-- TOC entry 4936 (class 2604 OID 16529)
-- Name: categoria id_categoria; Type: DEFAULT; Schema: site; Owner: postgres
--

ALTER TABLE ONLY site.categoria ALTER COLUMN id_categoria SET DEFAULT nextval('site.categoria_id_categoria_seq'::regclass);


--
-- TOC entry 4939 (class 2604 OID 16554)
-- Name: compatibilidade id_compatibilidade; Type: DEFAULT; Schema: site; Owner: postgres
--

ALTER TABLE ONLY site.compatibilidade ALTER COLUMN id_compatibilidade SET DEFAULT nextval('site.compatibilidade_id_compatibilidade_seq'::regclass);


--
-- TOC entry 4933 (class 2604 OID 16492)
-- Name: marca id_marca; Type: DEFAULT; Schema: site; Owner: postgres
--

ALTER TABLE ONLY site.marca ALTER COLUMN id_marca SET DEFAULT nextval('site.marca_id_marca_seq'::regclass);


--
-- TOC entry 4934 (class 2604 OID 16501)
-- Name: modelo id_modelo; Type: DEFAULT; Schema: site; Owner: postgres
--

ALTER TABLE ONLY site.modelo ALTER COLUMN id_modelo SET DEFAULT nextval('site.modelo_id_modelo_seq'::regclass);


--
-- TOC entry 4937 (class 2604 OID 16538)
-- Name: peca id_peca; Type: DEFAULT; Schema: site; Owner: postgres
--

ALTER TABLE ONLY site.peca ALTER COLUMN id_peca SET DEFAULT nextval('site.peca_id_peca_seq'::regclass);


--
-- TOC entry 4935 (class 2604 OID 16515)
-- Name: veiculo id_veiculo; Type: DEFAULT; Schema: site; Owner: postgres
--

ALTER TABLE ONLY site.veiculo ALTER COLUMN id_veiculo SET DEFAULT nextval('site.veiculo_id_veiculo_seq'::regclass);


--
-- TOC entry 5188 (class 0 OID 16589)
-- Dependencies: 236
-- Data for Name: fornecedor; Type: TABLE DATA; Schema: adm; Owner: postgres
--

COPY adm.fornecedor (id_fornecedor, razao_social, cnpj, telefone, email) FROM stdin;
1	Auto Peças Distribuidora LTDA	12.345.678/0001-90	(11) 3333-1111	contato@autopecasdist.com.br
2	Lubrificantes & Cia S/A	98.765.432/0001-10	(21) 2222-4444	vendas@lubrificantescia.com
3	Sistemas de Freios do Brasil	45.678.912/0001-33	(31) 3456-7890	comercial@freiosbrasil.com
4	Componentes Elétricos NGK Distribuição	33.222.111/0001-55	(11) 4004-5555	pedidos@ngkdist.com.br
5	Distribuidora Monroe Amortecedores	77.888.999/0001-22	(41) 3210-9876	suporte@monroedist.com.br
\.


--
-- TOC entry 5186 (class 0 OID 16571)
-- Dependencies: 234
-- Data for Name: funcionario; Type: TABLE DATA; Schema: adm; Owner: postgres
--

COPY adm.funcionario (id_funcionario, nome, cpf, cargo, email, data_admissao) FROM stdin;
1	Carlos Eduardo Silva	111.222.333-44	Mecânico Chefe	carlos.silva@oficina.com	2021-03-15
2	Mariana Rocha Alves	222.333.444-55	Atendente / Recepção	mariana.rocha@oficina.com	2022-01-10
3	Roberto Souza Filho	333.444.555-66	Mecânico Eletricista	roberto.souza@oficina.com	2020-08-01
4	Ana Paula Mendes	444.555.666-77	Gerente de Estoque	ana.mendes@oficina.com	2019-05-20
5	Lucas Fernandes	555.666.777-88	Auxiliar de Mecânica	lucas.fernandes@oficina.com	2023-02-01
\.


--
-- TOC entry 5192 (class 0 OID 16620)
-- Dependencies: 240
-- Data for Name: item_ordem_servico; Type: TABLE DATA; Schema: adm; Owner: postgres
--

COPY adm.item_ordem_servico (id_item_os, id_os, descricao_servico_peca, quantidade, valor_unitario) FROM stdin;
1	1	Mão de obra - Troca de Pastilhas de Freio	1	125.00
2	1	Pastilha de Freio Fras-le PD/58	1	125.50
3	2	Mão de obra - Troca de Óleo	1	98.00
4	3	Troca de Par de Amortecedores Dianteiros	1	200.00
5	4	Mão de obra - Troca de Velas	1	100.00
\.


--
-- TOC entry 5194 (class 0 OID 16637)
-- Dependencies: 242
-- Data for Name: movimentacao_estoque; Type: TABLE DATA; Schema: adm; Owner: postgres
--

COPY adm.movimentacao_estoque (id_movimentacao, id_peca, id_fornecedor, tipo_movimentacao, quantidade, data_movimentacao) FROM stdin;
1	1	3	ENTRADA	20	2026-09-01 19:48:19.402933
2	2	2	ENTRADA	50	2026-09-01 19:48:19.402933
3	3	5	ENTRADA	10	2026-09-01 19:48:19.402933
4	4	4	ENTRADA	30	2026-09-01 19:48:19.402933
5	1	\N	SAIDA	1	2026-09-01 19:48:19.402933
\.


--
-- TOC entry 5190 (class 0 OID 16601)
-- Dependencies: 238
-- Data for Name: ordem_servico; Type: TABLE DATA; Schema: adm; Owner: postgres
--

COPY adm.ordem_servico (id_os, id_funcionario, cliente_nome, cliente_telefone, veiculo_descricao, status, data_abertura, valor_total) FROM stdin;
1	1	João Pedro Santos	(32) 99988-1122	VW Gol 1.0 Flex 2018	Em Andamento	2026-09-01 19:48:19.402933	250.50
2	3	Fernanda Costa	(32) 98877-2233	Chevrolet Onix 1.0 Turbo 2020	Em Aberto	2026-09-01 19:48:19.402933	133.90
3	1	Marcos Vinícius	(32) 99111-3344	Fiat Uno 1.4 Fire 2015	Concluída	2026-09-01 19:48:19.402933	780.00
4	5	Beatriz Lima	(32) 98123-4567	Ford Ka 1.5 2019	Em Andamento	2026-09-01 19:48:19.402933	198.00
5	3	Ricardo Oliveira	(32) 99876-5432	Toyota Corolla 2.0 2021	Concluída	2026-09-01 19:48:19.402933	450.00
\.


--
-- TOC entry 5200 (class 0 OID 16699)
-- Dependencies: 248
-- Data for Name: conta_pagar_receber; Type: TABLE DATA; Schema: contabil; Owner: postgres
--

COPY contabil.conta_pagar_receber (id_titulo, id_conta, id_nota, tipo, descricao, valor, data_vencimento, status) FROM stdin;
\.


--
-- TOC entry 5204 (class 0 OID 16740)
-- Dependencies: 252
-- Data for Name: fechamento_mensal; Type: TABLE DATA; Schema: contabil; Owner: postgres
--

COPY contabil.fechamento_mensal (id_fechamento, mes_referencia, ano_referencia, total_receitas, total_despesas, impostos_devidos, status) FROM stdin;
\.


--
-- TOC entry 5202 (class 0 OID 16724)
-- Dependencies: 250
-- Data for Name: lancamento_financeiro; Type: TABLE DATA; Schema: contabil; Owner: postgres
--

COPY contabil.lancamento_financeiro (id_lancamento, id_titulo, forma_pagamento, valor_pago, data_pagamento) FROM stdin;
\.


--
-- TOC entry 5198 (class 0 OID 16673)
-- Dependencies: 246
-- Data for Name: nota_fiscal; Type: TABLE DATA; Schema: contabil; Owner: postgres
--

COPY contabil.nota_fiscal (id_nota, numero_nf, chave_acesso, tipo_operacao, id_os, id_fornecedor, valor_total, valor_impostos, data_emissao) FROM stdin;
\.


--
-- TOC entry 5196 (class 0 OID 16659)
-- Dependencies: 244
-- Data for Name: plano_contas; Type: TABLE DATA; Schema: contabil; Owner: postgres
--

COPY contabil.plano_contas (id_conta, codigo_conta, descricao, tipo_conta) FROM stdin;
\.


--
-- TOC entry 5180 (class 0 OID 16526)
-- Dependencies: 228
-- Data for Name: categoria; Type: TABLE DATA; Schema: site; Owner: postgres
--

COPY site.categoria (id_categoria, nome_categoria) FROM stdin;
1	Sistema de Freios
2	Filtragem e Lubrificantes
3	Suspensão e Amortecedores
4	Ignição e Elétrica
5	Transmissão e Correias
\.


--
-- TOC entry 5184 (class 0 OID 16551)
-- Dependencies: 232
-- Data for Name: compatibilidade; Type: TABLE DATA; Schema: site; Owner: postgres
--

COPY site.compatibilidade (id_compatibilidade, id_peca, id_veiculo, posicao_aplicacao, obs) FROM stdin;
1	1	1	Dianteiro Esquerdo / Direito	Válido apenas para modelos com disco sólido.
2	2	2	Filtro do Motor	Recomendado trocar a cada substituição de óleo 5W30.
3	3	3	Eixo Dianteiro	Acompanha batentes e coifas.
4	4	4	Cabeçote do Motor	Embalagem contém jogo com 3 unidades.
5	5	5	Distribuição / Motor	Verificar o estado das polias na instalação.
\.


--
-- TOC entry 5174 (class 0 OID 16489)
-- Dependencies: 222
-- Data for Name: marca; Type: TABLE DATA; Schema: site; Owner: postgres
--

COPY site.marca (id_marca, nome_marca) FROM stdin;
1	Volkswagen
2	Chevrolet
3	Fiat
4	Ford
5	Toyota
\.


--
-- TOC entry 5176 (class 0 OID 16498)
-- Dependencies: 224
-- Data for Name: modelo; Type: TABLE DATA; Schema: site; Owner: postgres
--

COPY site.modelo (id_modelo, id_marca, nome_modelo) FROM stdin;
1	1	Gol
2	2	Onix
3	3	Uno
4	4	Ka
5	5	Corolla
\.


--
-- TOC entry 5182 (class 0 OID 16535)
-- Dependencies: 230
-- Data for Name: peca; Type: TABLE DATA; Schema: site; Owner: postgres
--

COPY site.peca (id_peca, id_categoria, nome_peca, fabricante, codigo_fabricante, preco_venda, qnt_estoque) FROM stdin;
1	1	Pastilha de Freio Dianteira	Fras-le	PD/58	125.50	15
2	2	Filtro de Óleo do Motor	Tecfil	PEL108	35.90	40
3	3	Amortecedor Dianteiro (Par)	Monroe	SP045	580.00	6
4	4	Jogo de Velas de Ignição	NGK	BKR6E	98.00	25
5	5	Kit Correia Dentada e Tensor	Dayco	KTB286	185.00	10
\.


--
-- TOC entry 5178 (class 0 OID 16512)
-- Dependencies: 226
-- Data for Name: veiculo; Type: TABLE DATA; Schema: site; Owner: postgres
--

COPY site.veiculo (id_veiculo, id_modelo, ano_fabricacao, motorizacao, combustivel) FROM stdin;
1	1	2018	1.0 8V	Flex
2	2	2020	1.0 Turbo	Flex
3	3	2015	1.4 Fire	Flex
4	4	2019	1.5 3C	Flex
5	5	2021	2.0 16V	Flex
\.


--
-- TOC entry 5226 (class 0 OID 0)
-- Dependencies: 235
-- Name: fornecedor_id_fornecedor_seq; Type: SEQUENCE SET; Schema: adm; Owner: postgres
--

SELECT pg_catalog.setval('adm.fornecedor_id_fornecedor_seq', 5, true);


--
-- TOC entry 5227 (class 0 OID 0)
-- Dependencies: 233
-- Name: funcionario_id_funcionario_seq; Type: SEQUENCE SET; Schema: adm; Owner: postgres
--

SELECT pg_catalog.setval('adm.funcionario_id_funcionario_seq', 5, true);


--
-- TOC entry 5228 (class 0 OID 0)
-- Dependencies: 239
-- Name: item_ordem_servico_id_item_os_seq; Type: SEQUENCE SET; Schema: adm; Owner: postgres
--

SELECT pg_catalog.setval('adm.item_ordem_servico_id_item_os_seq', 5, true);


--
-- TOC entry 5229 (class 0 OID 0)
-- Dependencies: 241
-- Name: movimentacao_estoque_id_movimentacao_seq; Type: SEQUENCE SET; Schema: adm; Owner: postgres
--

SELECT pg_catalog.setval('adm.movimentacao_estoque_id_movimentacao_seq', 5, true);


--
-- TOC entry 5230 (class 0 OID 0)
-- Dependencies: 237
-- Name: ordem_servico_id_os_seq; Type: SEQUENCE SET; Schema: adm; Owner: postgres
--

SELECT pg_catalog.setval('adm.ordem_servico_id_os_seq', 5, true);


--
-- TOC entry 5231 (class 0 OID 0)
-- Dependencies: 247
-- Name: conta_pagar_receber_id_titulo_seq; Type: SEQUENCE SET; Schema: contabil; Owner: postgres
--

SELECT pg_catalog.setval('contabil.conta_pagar_receber_id_titulo_seq', 1, false);


--
-- TOC entry 5232 (class 0 OID 0)
-- Dependencies: 251
-- Name: fechamento_mensal_id_fechamento_seq; Type: SEQUENCE SET; Schema: contabil; Owner: postgres
--

SELECT pg_catalog.setval('contabil.fechamento_mensal_id_fechamento_seq', 1, false);


--
-- TOC entry 5233 (class 0 OID 0)
-- Dependencies: 249
-- Name: lancamento_financeiro_id_lancamento_seq; Type: SEQUENCE SET; Schema: contabil; Owner: postgres
--

SELECT pg_catalog.setval('contabil.lancamento_financeiro_id_lancamento_seq', 1, false);


--
-- TOC entry 5234 (class 0 OID 0)
-- Dependencies: 245
-- Name: nota_fiscal_id_nota_seq; Type: SEQUENCE SET; Schema: contabil; Owner: postgres
--

SELECT pg_catalog.setval('contabil.nota_fiscal_id_nota_seq', 1, false);


--
-- TOC entry 5235 (class 0 OID 0)
-- Dependencies: 243
-- Name: plano_contas_id_conta_seq; Type: SEQUENCE SET; Schema: contabil; Owner: postgres
--

SELECT pg_catalog.setval('contabil.plano_contas_id_conta_seq', 1, false);


--
-- TOC entry 5236 (class 0 OID 0)
-- Dependencies: 227
-- Name: categoria_id_categoria_seq; Type: SEQUENCE SET; Schema: site; Owner: postgres
--

SELECT pg_catalog.setval('site.categoria_id_categoria_seq', 5, true);


--
-- TOC entry 5237 (class 0 OID 0)
-- Dependencies: 231
-- Name: compatibilidade_id_compatibilidade_seq; Type: SEQUENCE SET; Schema: site; Owner: postgres
--

SELECT pg_catalog.setval('site.compatibilidade_id_compatibilidade_seq', 5, true);


--
-- TOC entry 5238 (class 0 OID 0)
-- Dependencies: 221
-- Name: marca_id_marca_seq; Type: SEQUENCE SET; Schema: site; Owner: postgres
--

SELECT pg_catalog.setval('site.marca_id_marca_seq', 5, true);


--
-- TOC entry 5239 (class 0 OID 0)
-- Dependencies: 223
-- Name: modelo_id_modelo_seq; Type: SEQUENCE SET; Schema: site; Owner: postgres
--

SELECT pg_catalog.setval('site.modelo_id_modelo_seq', 5, true);


--
-- TOC entry 5240 (class 0 OID 0)
-- Dependencies: 229
-- Name: peca_id_peca_seq; Type: SEQUENCE SET; Schema: site; Owner: postgres
--

SELECT pg_catalog.setval('site.peca_id_peca_seq', 5, true);


--
-- TOC entry 5241 (class 0 OID 0)
-- Dependencies: 225
-- Name: veiculo_id_veiculo_seq; Type: SEQUENCE SET; Schema: site; Owner: postgres
--

SELECT pg_catalog.setval('site.veiculo_id_veiculo_seq', 5, true);


--
-- TOC entry 4989 (class 2606 OID 16599)
-- Name: fornecedor fornecedor_cnpj_key; Type: CONSTRAINT; Schema: adm; Owner: postgres
--

ALTER TABLE ONLY adm.fornecedor
    ADD CONSTRAINT fornecedor_cnpj_key UNIQUE (cnpj);


--
-- TOC entry 4991 (class 2606 OID 16597)
-- Name: fornecedor fornecedor_pkey; Type: CONSTRAINT; Schema: adm; Owner: postgres
--

ALTER TABLE ONLY adm.fornecedor
    ADD CONSTRAINT fornecedor_pkey PRIMARY KEY (id_fornecedor);


--
-- TOC entry 4983 (class 2606 OID 16585)
-- Name: funcionario funcionario_cpf_key; Type: CONSTRAINT; Schema: adm; Owner: postgres
--

ALTER TABLE ONLY adm.funcionario
    ADD CONSTRAINT funcionario_cpf_key UNIQUE (cpf);


--
-- TOC entry 4985 (class 2606 OID 16587)
-- Name: funcionario funcionario_email_key; Type: CONSTRAINT; Schema: adm; Owner: postgres
--

ALTER TABLE ONLY adm.funcionario
    ADD CONSTRAINT funcionario_email_key UNIQUE (email);


--
-- TOC entry 4987 (class 2606 OID 16583)
-- Name: funcionario funcionario_pkey; Type: CONSTRAINT; Schema: adm; Owner: postgres
--

ALTER TABLE ONLY adm.funcionario
    ADD CONSTRAINT funcionario_pkey PRIMARY KEY (id_funcionario);


--
-- TOC entry 4995 (class 2606 OID 16630)
-- Name: item_ordem_servico item_ordem_servico_pkey; Type: CONSTRAINT; Schema: adm; Owner: postgres
--

ALTER TABLE ONLY adm.item_ordem_servico
    ADD CONSTRAINT item_ordem_servico_pkey PRIMARY KEY (id_item_os);


--
-- TOC entry 4997 (class 2606 OID 16647)
-- Name: movimentacao_estoque movimentacao_estoque_pkey; Type: CONSTRAINT; Schema: adm; Owner: postgres
--

ALTER TABLE ONLY adm.movimentacao_estoque
    ADD CONSTRAINT movimentacao_estoque_pkey PRIMARY KEY (id_movimentacao);


--
-- TOC entry 4993 (class 2606 OID 16613)
-- Name: ordem_servico ordem_servico_pkey; Type: CONSTRAINT; Schema: adm; Owner: postgres
--

ALTER TABLE ONLY adm.ordem_servico
    ADD CONSTRAINT ordem_servico_pkey PRIMARY KEY (id_os);


--
-- TOC entry 5007 (class 2606 OID 16712)
-- Name: conta_pagar_receber conta_pagar_receber_pkey; Type: CONSTRAINT; Schema: contabil; Owner: postgres
--

ALTER TABLE ONLY contabil.conta_pagar_receber
    ADD CONSTRAINT conta_pagar_receber_pkey PRIMARY KEY (id_titulo);


--
-- TOC entry 5011 (class 2606 OID 16756)
-- Name: fechamento_mensal fechamento_mensal_pkey; Type: CONSTRAINT; Schema: contabil; Owner: postgres
--

ALTER TABLE ONLY contabil.fechamento_mensal
    ADD CONSTRAINT fechamento_mensal_pkey PRIMARY KEY (id_fechamento);


--
-- TOC entry 5009 (class 2606 OID 16733)
-- Name: lancamento_financeiro lancamento_financeiro_pkey; Type: CONSTRAINT; Schema: contabil; Owner: postgres
--

ALTER TABLE ONLY contabil.lancamento_financeiro
    ADD CONSTRAINT lancamento_financeiro_pkey PRIMARY KEY (id_lancamento);


--
-- TOC entry 5003 (class 2606 OID 16687)
-- Name: nota_fiscal nota_fiscal_numero_nf_key; Type: CONSTRAINT; Schema: contabil; Owner: postgres
--

ALTER TABLE ONLY contabil.nota_fiscal
    ADD CONSTRAINT nota_fiscal_numero_nf_key UNIQUE (numero_nf);


--
-- TOC entry 5005 (class 2606 OID 16685)
-- Name: nota_fiscal nota_fiscal_pkey; Type: CONSTRAINT; Schema: contabil; Owner: postgres
--

ALTER TABLE ONLY contabil.nota_fiscal
    ADD CONSTRAINT nota_fiscal_pkey PRIMARY KEY (id_nota);


--
-- TOC entry 4999 (class 2606 OID 16671)
-- Name: plano_contas plano_contas_codigo_conta_key; Type: CONSTRAINT; Schema: contabil; Owner: postgres
--

ALTER TABLE ONLY contabil.plano_contas
    ADD CONSTRAINT plano_contas_codigo_conta_key UNIQUE (codigo_conta);


--
-- TOC entry 5001 (class 2606 OID 16669)
-- Name: plano_contas plano_contas_pkey; Type: CONSTRAINT; Schema: contabil; Owner: postgres
--

ALTER TABLE ONLY contabil.plano_contas
    ADD CONSTRAINT plano_contas_pkey PRIMARY KEY (id_conta);


--
-- TOC entry 4977 (class 2606 OID 16533)
-- Name: categoria categoria_pkey; Type: CONSTRAINT; Schema: site; Owner: postgres
--

ALTER TABLE ONLY site.categoria
    ADD CONSTRAINT categoria_pkey PRIMARY KEY (id_categoria);


--
-- TOC entry 4981 (class 2606 OID 16559)
-- Name: compatibilidade compatibilidade_pkey; Type: CONSTRAINT; Schema: site; Owner: postgres
--

ALTER TABLE ONLY site.compatibilidade
    ADD CONSTRAINT compatibilidade_pkey PRIMARY KEY (id_compatibilidade);


--
-- TOC entry 4971 (class 2606 OID 16496)
-- Name: marca marca_pkey; Type: CONSTRAINT; Schema: site; Owner: postgres
--

ALTER TABLE ONLY site.marca
    ADD CONSTRAINT marca_pkey PRIMARY KEY (id_marca);


--
-- TOC entry 4973 (class 2606 OID 16505)
-- Name: modelo modelo_pkey; Type: CONSTRAINT; Schema: site; Owner: postgres
--

ALTER TABLE ONLY site.modelo
    ADD CONSTRAINT modelo_pkey PRIMARY KEY (id_modelo);


--
-- TOC entry 4979 (class 2606 OID 16544)
-- Name: peca peca_pkey; Type: CONSTRAINT; Schema: site; Owner: postgres
--

ALTER TABLE ONLY site.peca
    ADD CONSTRAINT peca_pkey PRIMARY KEY (id_peca);


--
-- TOC entry 4975 (class 2606 OID 16519)
-- Name: veiculo veiculo_pkey; Type: CONSTRAINT; Schema: site; Owner: postgres
--

ALTER TABLE ONLY site.veiculo
    ADD CONSTRAINT veiculo_pkey PRIMARY KEY (id_veiculo);


--
-- TOC entry 5018 (class 2606 OID 16631)
-- Name: item_ordem_servico item_ordem_servico_id_os_fkey; Type: FK CONSTRAINT; Schema: adm; Owner: postgres
--

ALTER TABLE ONLY adm.item_ordem_servico
    ADD CONSTRAINT item_ordem_servico_id_os_fkey FOREIGN KEY (id_os) REFERENCES adm.ordem_servico(id_os) ON DELETE CASCADE;


--
-- TOC entry 5019 (class 2606 OID 16653)
-- Name: movimentacao_estoque movimentacao_estoque_id_fornecedor_fkey; Type: FK CONSTRAINT; Schema: adm; Owner: postgres
--

ALTER TABLE ONLY adm.movimentacao_estoque
    ADD CONSTRAINT movimentacao_estoque_id_fornecedor_fkey FOREIGN KEY (id_fornecedor) REFERENCES adm.fornecedor(id_fornecedor);


--
-- TOC entry 5020 (class 2606 OID 16648)
-- Name: movimentacao_estoque movimentacao_estoque_id_peca_fkey; Type: FK CONSTRAINT; Schema: adm; Owner: postgres
--

ALTER TABLE ONLY adm.movimentacao_estoque
    ADD CONSTRAINT movimentacao_estoque_id_peca_fkey FOREIGN KEY (id_peca) REFERENCES site.peca(id_peca);


--
-- TOC entry 5017 (class 2606 OID 16614)
-- Name: ordem_servico ordem_servico_id_funcionario_fkey; Type: FK CONSTRAINT; Schema: adm; Owner: postgres
--

ALTER TABLE ONLY adm.ordem_servico
    ADD CONSTRAINT ordem_servico_id_funcionario_fkey FOREIGN KEY (id_funcionario) REFERENCES adm.funcionario(id_funcionario);


--
-- TOC entry 5023 (class 2606 OID 16713)
-- Name: conta_pagar_receber conta_pagar_receber_id_conta_fkey; Type: FK CONSTRAINT; Schema: contabil; Owner: postgres
--

ALTER TABLE ONLY contabil.conta_pagar_receber
    ADD CONSTRAINT conta_pagar_receber_id_conta_fkey FOREIGN KEY (id_conta) REFERENCES contabil.plano_contas(id_conta);


--
-- TOC entry 5024 (class 2606 OID 16718)
-- Name: conta_pagar_receber conta_pagar_receber_id_nota_fkey; Type: FK CONSTRAINT; Schema: contabil; Owner: postgres
--

ALTER TABLE ONLY contabil.conta_pagar_receber
    ADD CONSTRAINT conta_pagar_receber_id_nota_fkey FOREIGN KEY (id_nota) REFERENCES contabil.nota_fiscal(id_nota);


--
-- TOC entry 5025 (class 2606 OID 16734)
-- Name: lancamento_financeiro lancamento_financeiro_id_titulo_fkey; Type: FK CONSTRAINT; Schema: contabil; Owner: postgres
--

ALTER TABLE ONLY contabil.lancamento_financeiro
    ADD CONSTRAINT lancamento_financeiro_id_titulo_fkey FOREIGN KEY (id_titulo) REFERENCES contabil.conta_pagar_receber(id_titulo);


--
-- TOC entry 5021 (class 2606 OID 16693)
-- Name: nota_fiscal nota_fiscal_id_fornecedor_fkey; Type: FK CONSTRAINT; Schema: contabil; Owner: postgres
--

ALTER TABLE ONLY contabil.nota_fiscal
    ADD CONSTRAINT nota_fiscal_id_fornecedor_fkey FOREIGN KEY (id_fornecedor) REFERENCES adm.fornecedor(id_fornecedor);


--
-- TOC entry 5022 (class 2606 OID 16688)
-- Name: nota_fiscal nota_fiscal_id_os_fkey; Type: FK CONSTRAINT; Schema: contabil; Owner: postgres
--

ALTER TABLE ONLY contabil.nota_fiscal
    ADD CONSTRAINT nota_fiscal_id_os_fkey FOREIGN KEY (id_os) REFERENCES adm.ordem_servico(id_os);


--
-- TOC entry 5015 (class 2606 OID 16560)
-- Name: compatibilidade compatibilidade_id_peca_fkey; Type: FK CONSTRAINT; Schema: site; Owner: postgres
--

ALTER TABLE ONLY site.compatibilidade
    ADD CONSTRAINT compatibilidade_id_peca_fkey FOREIGN KEY (id_peca) REFERENCES site.peca(id_peca);


--
-- TOC entry 5016 (class 2606 OID 16565)
-- Name: compatibilidade compatibilidade_id_veiculo_fkey; Type: FK CONSTRAINT; Schema: site; Owner: postgres
--

ALTER TABLE ONLY site.compatibilidade
    ADD CONSTRAINT compatibilidade_id_veiculo_fkey FOREIGN KEY (id_veiculo) REFERENCES site.veiculo(id_veiculo);


--
-- TOC entry 5012 (class 2606 OID 16506)
-- Name: modelo modelo_id_marca_fkey; Type: FK CONSTRAINT; Schema: site; Owner: postgres
--

ALTER TABLE ONLY site.modelo
    ADD CONSTRAINT modelo_id_marca_fkey FOREIGN KEY (id_marca) REFERENCES site.marca(id_marca);


--
-- TOC entry 5014 (class 2606 OID 16545)
-- Name: peca peca_id_categoria_fkey; Type: FK CONSTRAINT; Schema: site; Owner: postgres
--

ALTER TABLE ONLY site.peca
    ADD CONSTRAINT peca_id_categoria_fkey FOREIGN KEY (id_categoria) REFERENCES site.categoria(id_categoria);


--
-- TOC entry 5013 (class 2606 OID 16520)
-- Name: veiculo veiculo_id_modelo_fkey; Type: FK CONSTRAINT; Schema: site; Owner: postgres
--

ALTER TABLE ONLY site.veiculo
    ADD CONSTRAINT veiculo_id_modelo_fkey FOREIGN KEY (id_modelo) REFERENCES site.modelo(id_modelo);


-- Completed on 2026-09-01 21:21:00

--
-- PostgreSQL database dump complete
--

\unrestrict Pjh3wbK6m5PZIe3LYgAjZS00XGxiImWMpcWocOcZcVnrTYbXUZWZPIn4p7uDyeg

