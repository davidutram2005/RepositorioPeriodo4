-- ============================================================================
-- TESTE DE CARGA – JACARÉ MECÂNICA
-- Executar num banco à parte, DEPOIS do scripts/PiEnt2.sql.
-- Mede: (A) o custo do trigger ao inserir 100.000 lançamentos,
--       (B) se os saldos continuam corretos com 100.000 lançamentos,
--       (C) ler o saldo pronto × somar os lançamentos (a desnormalização),
--       (D) o efeito de índices nas colunas de conta.
-- ============================================================================

DROP SCHEMA IF EXISTS carga CASCADE;
CREATE SCHEMA carga;
CREATE TABLE carga.tempos (medicao TEXT, execucao INT, ms NUMERIC);

-- Gera N lançamentos repetindo os 6 tipos de operação do teste original,
-- com valores de R$ 10 a R$ 500 (sempre maiores que zero).
CREATE FUNCTION carga.gerar(n INT) RETURNS void AS $$
    INSERT INTO contabil.lancamentos (data_lancamento, historico, conta_debito_id, conta_credito_id, valor)
    SELECT DATE '2026-01-01' + (g % 365),
           'Carga ' || g,
           CASE g % 6 WHEN 0 THEN d.bancos WHEN 1 THEN d.estoque WHEN 2 THEN d.caixa
                      WHEN 3 THEN d.cmv WHEN 4 THEN d.aluguel ELSE d.estoque END,
           CASE g % 6 WHEN 0 THEN d.capital WHEN 1 THEN d.bancos WHEN 2 THEN d.receita
                      WHEN 3 THEN d.estoque WHEN 4 THEN d.bancos ELSE d.fornec END,
           ((g % 50) + 1) * 10.00
    FROM generate_series(1, n) g,
         (SELECT max(id_conta) FILTER (WHERE codigo_conta = '1.1.01') AS caixa,
                 max(id_conta) FILTER (WHERE codigo_conta = '1.1.02') AS bancos,
                 max(id_conta) FILTER (WHERE codigo_conta = '1.1.04') AS estoque,
                 max(id_conta) FILTER (WHERE codigo_conta = '2.1.01') AS fornec,
                 max(id_conta) FILTER (WHERE codigo_conta = '3.1.01') AS capital,
                 max(id_conta) FILTER (WHERE codigo_conta = '4.1.01') AS receita,
                 max(id_conta) FILTER (WHERE codigo_conta = '5.1.01') AS cmv,
                 max(id_conta) FILTER (WHERE codigo_conta = '5.1.03') AS aluguel
          FROM contabil.plano_contas) d;
$$ LANGUAGE sql;

-- ---------------------------------------------------------------------------
-- (A) Custo do trigger: 100.000 lançamentos com e sem trigger, 3 vezes cada.
--     Cada execução é desfeita no final, para não acumular dados.
-- ---------------------------------------------------------------------------
DO $$
DECLARE t0 TIMESTAMPTZ; v_ms NUMERIC;
BEGIN
  FOR i IN 1..3 LOOP
    BEGIN
      ALTER TABLE contabil.lancamentos DISABLE TRIGGER trg_atualiza_saldo;
      t0 := clock_timestamp();
      PERFORM carga.gerar(100000);
      v_ms := extract(epoch FROM clock_timestamp() - t0) * 1000;
      RAISE EXCEPTION USING ERRCODE = 'P0098';
    EXCEPTION WHEN SQLSTATE 'P0098' THEN NULL; END;
    INSERT INTO carga.tempos VALUES ('A1 inserir 100 mil SEM trigger', i, round(v_ms));

    BEGIN
      t0 := clock_timestamp();
      PERFORM carga.gerar(100000);
      v_ms := extract(epoch FROM clock_timestamp() - t0) * 1000;
      RAISE EXCEPTION USING ERRCODE = 'P0098';
    EXCEPTION WHEN SQLSTATE 'P0098' THEN NULL; END;
    INSERT INTO carga.tempos VALUES ('A2 inserir 100 mil COM trigger', i, round(v_ms));
  END LOOP;
END $$;

-- Agora insere de verdade os 100.000 lançamentos (com trigger) para os testes B, C e D.
SELECT carga.gerar(100000);
VACUUM ANALYZE contabil.lancamentos;
VACUUM ANALYZE contabil.saldo_contas;

-- ---------------------------------------------------------------------------
-- (B) Correção em escala: o saldo guardado bate com o recalculado?
-- ---------------------------------------------------------------------------
\echo '=== B. Correção com 100.006 lançamentos ==='
WITH mov AS (
    SELECT pc.id_conta, pc.codigo_conta, pc.natureza_conta,
           coalesce(sum(l.valor) FILTER (WHERE l.conta_debito_id = pc.id_conta), 0) AS deb,
           coalesce(sum(l.valor) FILTER (WHERE l.conta_credito_id = pc.id_conta), 0) AS cred
    FROM contabil.plano_contas pc
    LEFT JOIN contabil.lancamentos l ON pc.id_conta IN (l.conta_debito_id, l.conta_credito_id)
    GROUP BY pc.id_conta, pc.codigo_conta, pc.natureza_conta)
SELECT m.codigo_conta, m.natureza_conta, sc.saldo AS saldo_guardado,
       CASE WHEN m.natureza_conta = 'DEVEDORA' THEN m.deb - m.cred ELSE m.cred - m.deb END AS saldo_recalculado,
       sc.saldo = CASE WHEN m.natureza_conta = 'DEVEDORA' THEN m.deb - m.cred ELSE m.cred - m.deb END AS confere
FROM mov m JOIN contabil.saldo_contas sc ON sc.conta_id = m.id_conta
ORDER BY m.codigo_conta;

SELECT (SELECT count(*) FROM contabil.lancamentos) AS total_lancamentos,
       sum(sc.saldo) FILTER (WHERE pc.natureza_conta = 'DEVEDORA') AS total_devedor,
       sum(sc.saldo) FILTER (WHERE pc.natureza_conta = 'CREDORA') AS total_credor
FROM contabil.plano_contas pc JOIN contabil.saldo_contas sc ON sc.conta_id = pc.id_conta;

-- ---------------------------------------------------------------------------
-- (C) e (D) Consultar o saldo de Bancos: tabela pronta × soma dos lançamentos,
--           sem e com índice nas colunas de conta. 30 execuções de cada.
-- ---------------------------------------------------------------------------
CREATE FUNCTION carga.medir(p_nome TEXT, p_sql TEXT, p_vezes INT) RETURNS void AS $$
DECLARE t0 TIMESTAMPTZ; v NUMERIC;
BEGIN
  EXECUTE p_sql INTO v;                         -- aquecimento (cache)
  FOR i IN 1..p_vezes LOOP
    t0 := clock_timestamp();
    EXECUTE p_sql INTO v;
    INSERT INTO carga.tempos VALUES (p_nome, i, extract(epoch FROM clock_timestamp() - t0) * 1000);
  END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT carga.medir('C1 saldo de Bancos lendo saldo_contas',
  $q$SELECT saldo FROM contabil.saldo_contas WHERE conta_id = (SELECT id_conta FROM contabil.plano_contas WHERE codigo_conta = '1.1.02')$q$, 30);

SELECT carga.medir('C2 saldo de Bancos somando lançamentos (sem índice)',
  $q$WITH b AS (SELECT id_conta FROM contabil.plano_contas WHERE codigo_conta = '1.1.02')
     SELECT coalesce(sum(l.valor) FILTER (WHERE l.conta_debito_id = b.id_conta), 0)
          - coalesce(sum(l.valor) FILTER (WHERE l.conta_credito_id = b.id_conta), 0)
     FROM contabil.lancamentos l, b
     WHERE l.conta_debito_id = b.id_conta OR l.conta_credito_id = b.id_conta$q$, 30);

\echo '=== Plano da consulta somando lançamentos, SEM índice ==='
EXPLAIN (ANALYZE, COSTS OFF, TIMING ON)
SELECT sum(valor) FROM contabil.lancamentos
WHERE conta_debito_id = (SELECT id_conta FROM contabil.plano_contas WHERE codigo_conta = '1.1.02')
   OR conta_credito_id = (SELECT id_conta FROM contabil.plano_contas WHERE codigo_conta = '1.1.02');

-- (D) No PostgreSQL, chave estrangeira NÃO cria índice automaticamente
--     (no MySQL/InnoDB, cria). Criamos os índices e medimos de novo.
CREATE INDEX idx_lanc_debito ON contabil.lancamentos (conta_debito_id);
CREATE INDEX idx_lanc_credito ON contabil.lancamentos (conta_credito_id);
ANALYZE contabil.lancamentos;

SELECT carga.medir('D1 saldo de Bancos somando lançamentos (com índice)',
  $q$WITH b AS (SELECT id_conta FROM contabil.plano_contas WHERE codigo_conta = '1.1.02')
     SELECT coalesce(sum(l.valor) FILTER (WHERE l.conta_debito_id = b.id_conta), 0)
          - coalesce(sum(l.valor) FILTER (WHERE l.conta_credito_id = b.id_conta), 0)
     FROM contabil.lancamentos l, b
     WHERE l.conta_debito_id = b.id_conta OR l.conta_credito_id = b.id_conta$q$, 30);

\echo '=== Plano da consulta somando lançamentos, COM índice ==='
EXPLAIN (ANALYZE, COSTS OFF, TIMING ON)
SELECT sum(valor) FROM contabil.lancamentos
WHERE conta_debito_id = (SELECT id_conta FROM contabil.plano_contas WHERE codigo_conta = '1.1.02')
   OR conta_credito_id = (SELECT id_conta FROM contabil.plano_contas WHERE codigo_conta = '1.1.02');

\echo '=== Plano da leitura do saldo pronto ==='
EXPLAIN (ANALYZE, COSTS OFF, TIMING ON)
SELECT saldo FROM contabil.saldo_contas
WHERE conta_id = (SELECT id_conta FROM contabil.plano_contas WHERE codigo_conta = '1.1.02');


-- ---------------------------------------------------------------------------
-- (E) Escala: o custo do trigger por lançamento conforme o tamanho do lote
--     (todos os lançamentos numa única transação; cada lote é desfeito).
-- ---------------------------------------------------------------------------
DO $$
DECLARE t0 TIMESTAMPTZ; v_ms NUMERIC; n INT;
BEGIN
  FOREACH n IN ARRAY ARRAY[1000, 5000, 10000, 25000, 50000] LOOP
    BEGIN
      t0 := clock_timestamp();
      PERFORM carga.gerar(n);
      v_ms := extract(epoch FROM clock_timestamp() - t0) * 1000;
      RAISE EXCEPTION USING ERRCODE = 'P0098';
    EXCEPTION WHEN SQLSTATE 'P0098' THEN NULL; END;
    INSERT INTO carga.tempos VALUES ('E lote de ' || lpad(n::text, 6, '0') || ' COM trigger (ms no lote)', 1, round(v_ms));
  END LOOP;
END $$;

-- ---------------------------------------------------------------------------
-- Resumo dos tempos (mediana)
-- ---------------------------------------------------------------------------
\echo '=== Resumo dos tempos ==='
SELECT medicao, count(*) AS execucoes,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY ms)::numeric, 3) AS mediana_ms,
       round(min(ms), 3) AS min_ms, round(max(ms), 3) AS max_ms
FROM carga.tempos GROUP BY medicao ORDER BY medicao;
