-- ============================================================================
-- TESTES FUNCIONAIS – JACARÉ MECÂNICA
-- Executar DEPOIS do scripts/PiEnt2.sql (estrutura, dados, views e Práticas 03 e 05).
--
-- Cada teste roda dentro de uma subtransação e é desfeito no final,
-- então um teste não interfere no outro e o banco volta ao estado inicial.
-- O resultado de cada teste fica na tabela teste.resultados.
--
-- Status possíveis:
--   PASSOU                 o banco se comportou como o projeto afirma
--   FALHOU                 o banco NÃO se comportou como o projeto afirma
--   LIMITAÇÃO CONFIRMADA   comportamento já declarado como limitação
--   INCONSISTÊNCIA         problema encontrado nos dados de teste
-- ============================================================================

DROP SCHEMA IF EXISTS teste CASCADE;
CREATE SCHEMA teste;

CREATE TABLE teste.resultados (
    id SERIAL PRIMARY KEY,
    categoria VARCHAR(40) NOT NULL,
    teste VARCHAR(200) NOT NULL,
    esperado VARCHAR(300) NOT NULL,
    obtido VARCHAR(500) NOT NULL,
    status VARCHAR(30) NOT NULL
);

-- Atalho: id de uma conta pelo código
CREATE FUNCTION teste.conta(p_codigo VARCHAR) RETURNS INT AS $$
    SELECT id_conta FROM contabil.plano_contas WHERE codigo_conta = p_codigo;
$$ LANGUAGE sql;

-- Atalho: saldo de uma conta pelo código
CREATE FUNCTION teste.saldo(p_codigo VARCHAR) RETURNS NUMERIC AS $$
    SELECT sc.saldo FROM contabil.saldo_contas sc
    JOIN contabil.plano_contas pc ON pc.id_conta = sc.conta_id
    WHERE pc.codigo_conta = p_codigo;
$$ LANGUAGE sql;

-- ----------------------------------------------------------------------------
-- espera_erro: executa um comando que DEVE ser recusado pelo banco.
-- Passa se o erro tiver o código esperado (SQLSTATE):
--   23514 = CHECK · 23505 = UNIQUE · 23503 = chave estrangeira · 23502 = NOT NULL
--   22P02 = valor fora do ENUM (tipo_conta e natureza_conta)
-- ----------------------------------------------------------------------------
CREATE FUNCTION teste.espera_erro(p_cat TEXT, p_nome TEXT, p_sqlstate TEXT, p_esperado TEXT, p_sql TEXT)
RETURNS void AS $$
DECLARE
    v_state TEXT;
    v_msg TEXT;
BEGIN
    BEGIN
        EXECUTE p_sql;
        RAISE EXCEPTION USING ERRCODE = 'P0099', MESSAGE = 'aceito';   -- desfaz o comando
    EXCEPTION WHEN OTHERS THEN
        v_state := SQLSTATE;
        v_msg := SQLERRM;
    END;
    INSERT INTO teste.resultados (categoria, teste, esperado, obtido, status) VALUES (
        p_cat, p_nome, p_esperado,
        CASE WHEN v_state = 'P0099' THEN 'o banco ACEITOU o comando'
             ELSE 'recusado (' || v_state || '): ' || left(v_msg, 300) END,
        CASE WHEN v_state = p_sqlstate THEN 'PASSOU' ELSE 'FALHOU' END);
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- cenario: executa uma ação, depois uma consulta que devolve (ok, obtido),
-- registra o resultado e desfaz tudo.
-- p_status_ok = status gravado quando ok = true (PASSOU ou LIMITAÇÃO CONFIRMADA)
-- ----------------------------------------------------------------------------
CREATE FUNCTION teste.cenario(p_cat TEXT, p_nome TEXT, p_esperado TEXT, p_acao TEXT, p_consulta TEXT,
                              p_status_ok TEXT DEFAULT 'PASSOU', p_status_falha TEXT DEFAULT 'FALHOU')
RETURNS void AS $$
DECLARE
    v_ok BOOLEAN;
    v_obtido TEXT;
BEGIN
    BEGIN
        IF p_acao IS NOT NULL THEN EXECUTE p_acao; END IF;
        EXECUTE p_consulta INTO v_ok, v_obtido;
        RAISE EXCEPTION USING ERRCODE = 'P0098', MESSAGE = 'desfazer';
    EXCEPTION
        WHEN SQLSTATE 'P0098' THEN NULL;
        WHEN OTHERS THEN v_ok := false; v_obtido := 'erro inesperado (' || SQLSTATE || '): ' || SQLERRM;
    END;
    INSERT INTO teste.resultados (categoria, teste, esperado, obtido, status)
    VALUES (p_cat, p_nome, p_esperado, coalesce(v_obtido, '(sem resultado)'),
            CASE WHEN v_ok THEN p_status_ok ELSE p_status_falha END);
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- 1. INTEGRIDADE – o banco recusa dados inválidos?
-- ============================================================================
SELECT teste.espera_erro('1. Integridade', 'CHECK: lançamento com valor negativo', '23514',
  'recusar (CHECK valor > 0)',
  $q$INSERT INTO contabil.lancamentos (data_lancamento, historico, conta_debito_id, conta_credito_id, valor)
     VALUES ('2026-04-10', 'teste', teste.conta('1.1.01'), teste.conta('4.1.01'), -500)$q$);

SELECT teste.espera_erro('1. Integridade', 'CHECK: lançamento com valor zero', '23514',
  'recusar (CHECK valor > 0)',
  $q$INSERT INTO contabil.lancamentos (data_lancamento, historico, conta_debito_id, conta_credito_id, valor)
     VALUES ('2026-04-10', 'teste', teste.conta('1.1.01'), teste.conta('4.1.01'), 0)$q$);

SELECT teste.espera_erro('1. Integridade', 'ENUM: natureza de conta inválida (XYZ)', '22P02',
  'recusar (natureza_conta_enum: só DEVEDORA ou CREDORA)',
  $q$UPDATE contabil.plano_contas SET natureza_conta = 'XYZ' WHERE codigo_conta = '1.1.01'$q$);

SELECT teste.espera_erro('1. Integridade', 'ENUM: tipo de conta inválido (CAIXA)', '22P02',
  'recusar (tipo_conta_enum: só ATIVO, PASSIVO, PATRIMONIO_LIQUIDO, RECEITA, DESPESA)',
  $q$INSERT INTO contabil.plano_contas (codigo_conta, descricao, tipo_conta) VALUES ('9.9.99', 'Teste', 'CAIXA')$q$);

SELECT teste.espera_erro('1. Integridade', 'CHECK: tipo de movimentação inválido (DEVOLUCAO)', '23514',
  'recusar (só ENTRADA, SAIDA, AJUSTE)',
  $q$INSERT INTO adm.movimentacao_estoque (id_peca, tipo_movimentacao, quantidade) VALUES (1, 'DEVOLUCAO', 1)$q$);

SELECT teste.espera_erro('1. Integridade', 'CHECK: status de título inválido (ABERTO)', '23514',
  'recusar (só PENDENTE, PAGO, CANCELADO)',
  $q$INSERT INTO contabil.conta_pagar_receber (id_conta, tipo, descricao, valor, data_vencimento, status)
     VALUES (teste.conta('2.1.01'), 'PAGAR', 'teste', 100, '2026-05-01', 'ABERTO')$q$);

SELECT teste.espera_erro('1. Integridade', 'CHECK: peça com preço zero', '23514',
  'recusar (CHECK preco_venda > 0)',
  $q$UPDATE site.peca SET preco_venda = 0 WHERE id_peca = 1$q$);

SELECT teste.espera_erro('1. Integridade', 'CHECK: OS com status inválido (Pausada)', '23514',
  'recusar (só Em Aberto, Em Andamento, Concluída, Cancelada)',
  $q$UPDATE adm.ordem_servico SET status = 'Pausada' WHERE id_os = 1$q$);

SELECT teste.espera_erro('1. Integridade', 'CHECK: movimentação de estoque com quantidade zero', '23514',
  'recusar (CHECK quantidade > 0)',
  $q$INSERT INTO adm.movimentacao_estoque (id_peca, tipo_movimentacao, quantidade) VALUES (1, 'ENTRADA', 0)$q$);

SELECT teste.espera_erro('1. Integridade', 'CHECK: fechamento com mês 13', '23514',
  'recusar (mês entre 1 e 12)',
  $q$INSERT INTO contabil.fechamento_mensal (mes_referencia, ano_referencia) VALUES (13, 2026)$q$);

SELECT teste.espera_erro('1. Integridade', 'UNIQUE: funcionário com CPF repetido', '23505',
  'recusar (CPF único)',
  $q$INSERT INTO adm.funcionario (nome, cpf, cargo, email) VALUES ('Teste', '111.222.333-44', 'Teste', 't@t.com')$q$);

SELECT teste.espera_erro('1. Integridade', 'UNIQUE: fornecedor com CNPJ repetido', '23505',
  'recusar (CNPJ único)',
  $q$INSERT INTO adm.fornecedor (razao_social, cnpj) VALUES ('Teste', '12.345.678/0001-90')$q$);

SELECT teste.espera_erro('1. Integridade', 'UNIQUE: código de conta repetido', '23505',
  'recusar (codigo_conta único)',
  $q$INSERT INTO contabil.plano_contas (codigo_conta, descricao, tipo_conta) VALUES ('1.1.01', 'Caixa 2', 'ATIVO')$q$);

SELECT teste.espera_erro('1. Integridade', 'UNIQUE: dois fechamentos para o mesmo mês', '23505',
  'recusar (um fechamento por mês e ano)',
  $q$INSERT INTO contabil.fechamento_mensal (mes_referencia, ano_referencia) VALUES (4, 2026), (4, 2026)$q$);

SELECT teste.espera_erro('1. Integridade', 'NOT NULL: funcionário sem nome', '23502',
  'recusar (nome obrigatório)',
  $q$INSERT INTO adm.funcionario (cpf, cargo, email) VALUES ('999.999.999-99', 'Teste', 't@t.com')$q$);

SELECT teste.espera_erro('1. Integridade', 'Chave estrangeira: lançamento em conta inexistente (id 9999)', '23503',
  'recusar (conta precisa existir)',
  $q$INSERT INTO contabil.lancamentos (data_lancamento, historico, conta_debito_id, conta_credito_id, valor)
     VALUES ('2026-04-10', 'teste', 9999, teste.conta('4.1.01'), 100)$q$);

SELECT teste.espera_erro('1. Integridade', 'Chave estrangeira: movimentação de peça inexistente (id 9999)', '23503',
  'recusar (peça precisa existir)',
  $q$INSERT INTO adm.movimentacao_estoque (id_peca, tipo_movimentacao, quantidade) VALUES (9999, 'ENTRADA', 1)$q$);

SELECT teste.espera_erro('1. Integridade', 'RESTRICT: apagar a conta Bancos, que tem lançamentos', '23503',
  'recusar (ON DELETE RESTRICT)',
  $q$DELETE FROM contabil.plano_contas WHERE codigo_conta = '1.1.02'$q$);

SELECT teste.espera_erro('1. Integridade', 'RESTRICT: apagar peça com movimentação de estoque', '23503',
  'recusar (ON DELETE RESTRICT)',
  $q$DELETE FROM site.peca WHERE id_peca = 1$q$);

SELECT teste.cenario('1. Integridade', 'CASCADE: apagar a marca Volkswagen',
  'modelo, veículo e compatibilidade dela também são apagados',
  $q$DELETE FROM site.marca WHERE id_marca = 1$q$,
  $q$SELECT (SELECT count(*) FROM site.modelo WHERE id_marca = 1) = 0
            AND (SELECT count(*) FROM site.veiculo WHERE id_veiculo = 1) = 0
            AND (SELECT count(*) FROM site.compatibilidade WHERE id_veiculo = 1) = 0,
            'modelos restantes: ' || (SELECT count(*) FROM site.modelo WHERE id_marca = 1)
            || ' · veículo 1: ' || (SELECT count(*) FROM site.veiculo WHERE id_veiculo = 1)
            || ' · compatibilidades do veículo 1: ' || (SELECT count(*) FROM site.compatibilidade WHERE id_veiculo = 1)$q$);

SELECT teste.cenario('1. Integridade', 'CASCADE: apagar a OS 1', 'os itens da OS 1 também são apagados',
  $q$DELETE FROM adm.ordem_servico WHERE id_os = 1$q$,
  $q$SELECT count(*) = 0, 'itens restantes da OS 1: ' || count(*) FROM adm.item_ordem_servico WHERE id_os = 1$q$);

SELECT teste.cenario('1. Integridade', 'SET NULL: apagar a categoria Sistema de Freios',
  'a peça 1 continua no catálogo, sem categoria',
  $q$DELETE FROM site.categoria WHERE id_categoria = 1$q$,
  $q$SELECT count(*) = 1 AND bool_and(id_categoria IS NULL),
            'peça 1 existe: ' || (count(*) = 1) || ' · categoria: ' || coalesce(max(id_categoria)::text, 'vazia')
     FROM site.peca WHERE id_peca = 1$q$);

SELECT teste.cenario('1. Integridade', 'SET NULL: apagar o funcionário Carlos (OS 1 e 3)',
  'as OS 1 e 3 continuam, sem funcionário',
  $q$DELETE FROM adm.funcionario WHERE id_funcionario = 1$q$,
  $q$SELECT count(*) = 2 AND bool_and(id_funcionario IS NULL),
            'OS mantidas: ' || count(*) || ' · funcionário: ' || coalesce(max(id_funcionario)::text, 'vazio')
     FROM adm.ordem_servico WHERE id_os IN (1, 3)$q$);

SELECT teste.cenario('1. Integridade', 'DEFAULT: nova OS sem informar status',
  'status preenchido como Em Aberto',
  $q$INSERT INTO adm.ordem_servico (cliente_nome, veiculo_descricao) VALUES ('Cliente Teste', 'Carro Teste')$q$,
  $q$SELECT status = 'Em Aberto', 'status: ' || status FROM adm.ordem_servico WHERE cliente_nome = 'Cliente Teste'$q$);

SELECT teste.cenario('1. Integridade', 'DEFAULT: novo título sem informar status',
  'status preenchido como PENDENTE',
  $q$INSERT INTO contabil.conta_pagar_receber (id_conta, tipo, descricao, valor, data_vencimento)
     VALUES (teste.conta('2.1.01'), 'PAGAR', 'Título teste', 100, '2026-05-01')$q$,
  $q$SELECT status = 'PENDENTE', 'status: ' || status FROM contabil.conta_pagar_receber WHERE descricao = 'Título teste'$q$);

SELECT teste.cenario('1. Integridade', 'SERIAL + setval: nova marca sem informar id',
  'recebe um id novo, depois dos 5 inseridos à mão (6 na 1ª execução; o número de uma sequência não volta atrás quando o teste é desfeito)',
  $q$INSERT INTO site.marca (nome_marca) VALUES ('Marca Teste')$q$,
  $q$SELECT id_marca > 5, 'id gerado: ' || id_marca FROM site.marca WHERE nome_marca = 'Marca Teste'$q$);


-- ============================================================================
-- 2. TRIGGER – os saldos são atualizados corretamente?
-- Estado inicial (após os 6 lançamentos): Caixa 5.000 · Bancos 20.500 ·
-- Estoque 9.000 · Fornecedores 4.000 · Capital 30.000 · Receita 5.000 ·
-- CMV 3.000 · Aluguel 1.500
-- ============================================================================
SELECT teste.cenario('2. Trigger', 'Estado inicial: os 8 saldos após os 6 lançamentos',
  'Caixa 5.000 · Bancos 20.500 · Estoque 9.000 · Fornec. 4.000 · Capital 30.000 · Receita 5.000 · CMV 3.000 · Aluguel 1.500',
  NULL,
  $q$SELECT teste.saldo('1.1.01') = 5000 AND teste.saldo('1.1.02') = 20500 AND teste.saldo('1.1.04') = 9000
        AND teste.saldo('2.1.01') = 4000 AND teste.saldo('3.1.01') = 30000 AND teste.saldo('4.1.01') = 5000
        AND teste.saldo('5.1.01') = 3000 AND teste.saldo('5.1.03') = 1500,
     'Caixa ' || teste.saldo('1.1.01') || ' · Bancos ' || teste.saldo('1.1.02') || ' · Estoque ' || teste.saldo('1.1.04')
     || ' · Fornec. ' || teste.saldo('2.1.01') || ' · Capital ' || teste.saldo('3.1.01') || ' · Receita ' || teste.saldo('4.1.01')
     || ' · CMV ' || teste.saldo('5.1.01') || ' · Aluguel ' || teste.saldo('5.1.03')$q$);

SELECT teste.cenario('2. Trigger', 'Devedora debitada + credora creditada: venda de R$ 1.000',
  'Caixa 5.000 → 6.000 (+) · Receita 5.000 → 6.000 (+)',
  $q$INSERT INTO contabil.lancamentos (data_lancamento, historico, conta_debito_id, conta_credito_id, valor)
     VALUES ('2026-04-10', 'Venda teste', teste.conta('1.1.01'), teste.conta('4.1.01'), 1000)$q$,
  $q$SELECT teste.saldo('1.1.01') = 6000 AND teste.saldo('4.1.01') = 6000,
            'Caixa ' || teste.saldo('1.1.01') || ' · Receita ' || teste.saldo('4.1.01')$q$);

SELECT teste.cenario('2. Trigger', 'Devedora debitada + devedora creditada: compra à vista de R$ 500',
  'Estoque 9.000 → 9.500 (+) · Bancos 20.500 → 20.000 (−)',
  $q$INSERT INTO contabil.lancamentos (data_lancamento, historico, conta_debito_id, conta_credito_id, valor)
     VALUES ('2026-04-10', 'Compra teste', teste.conta('1.1.04'), teste.conta('1.1.02'), 500)$q$,
  $q$SELECT teste.saldo('1.1.04') = 9500 AND teste.saldo('1.1.02') = 20000,
            'Estoque ' || teste.saldo('1.1.04') || ' · Bancos ' || teste.saldo('1.1.02')$q$);

SELECT teste.cenario('2. Trigger', 'Credora debitada + devedora creditada: pagamento de R$ 1.000 ao fornecedor',
  'Fornecedores 4.000 → 3.000 (−) · Bancos 20.500 → 19.500 (−)',
  $q$INSERT INTO contabil.lancamentos (data_lancamento, historico, conta_debito_id, conta_credito_id, valor)
     VALUES ('2026-04-10', 'Pagamento teste', teste.conta('2.1.01'), teste.conta('1.1.02'), 1000)$q$,
  $q$SELECT teste.saldo('2.1.01') = 3000 AND teste.saldo('1.1.02') = 19500,
            'Fornecedores ' || teste.saldo('2.1.01') || ' · Bancos ' || teste.saldo('1.1.02')$q$);

SELECT teste.cenario('2. Trigger', 'Um INSERT com 3 linhas (3 vendas de R$ 100)',
  'o trigger roda 3 vezes: Caixa 5.000 → 5.300 · Receita 5.000 → 5.300',
  $q$INSERT INTO contabil.lancamentos (data_lancamento, historico, conta_debito_id, conta_credito_id, valor) VALUES
     ('2026-04-10', 'v1', teste.conta('1.1.01'), teste.conta('4.1.01'), 100),
     ('2026-04-10', 'v2', teste.conta('1.1.01'), teste.conta('4.1.01'), 100),
     ('2026-04-10', 'v3', teste.conta('1.1.01'), teste.conta('4.1.01'), 100)$q$,
  $q$SELECT teste.saldo('1.1.01') = 5300 AND teste.saldo('4.1.01') = 5300,
            'Caixa ' || teste.saldo('1.1.01') || ' · Receita ' || teste.saldo('4.1.01')$q$);

SELECT teste.cenario('2. Trigger', 'data_atualizacao é atualizada pelo trigger',
  'a data da conta Caixa muda para o momento do lançamento',
  $q$UPDATE contabil.saldo_contas SET data_atualizacao = '2000-01-01' WHERE conta_id = teste.conta('1.1.01');
     INSERT INTO contabil.lancamentos (data_lancamento, historico, conta_debito_id, conta_credito_id, valor)
     VALUES ('2026-04-10', 'Data teste', teste.conta('1.1.01'), teste.conta('4.1.01'), 10)$q$,
  $q$SELECT data_atualizacao > '2000-01-01', 'data_atualizacao: ' || data_atualizacao
     FROM contabil.saldo_contas WHERE conta_id = teste.conta('1.1.01')$q$);

SELECT teste.cenario('2. Trigger', 'Partidas dobradas após vários lançamentos novos',
  'total devedor = total credor',
  $q$INSERT INTO contabil.lancamentos (data_lancamento, historico, conta_debito_id, conta_credito_id, valor) VALUES
     ('2026-04-11', 'a', teste.conta('1.1.01'), teste.conta('4.1.01'), 700),
     ('2026-04-11', 'b', teste.conta('5.1.03'), teste.conta('1.1.02'), 300),
     ('2026-04-11', 'c', teste.conta('2.1.01'), teste.conta('1.1.01'), 250),
     ('2026-04-11', 'd', teste.conta('1.1.04'), teste.conta('2.1.01'), 900)$q$,
  $q$SELECT sum(sc.saldo) FILTER (WHERE pc.natureza_conta = 'DEVEDORA') = sum(sc.saldo) FILTER (WHERE pc.natureza_conta = 'CREDORA'),
            'devedor ' || sum(sc.saldo) FILTER (WHERE pc.natureza_conta = 'DEVEDORA')
            || ' · credor ' || sum(sc.saldo) FILTER (WHERE pc.natureza_conta = 'CREDORA')
     FROM contabil.plano_contas pc JOIN contabil.saldo_contas sc ON sc.conta_id = pc.id_conta$q$);

SELECT teste.cenario('2. Trigger', 'Lançamento com valor vazio (NULL)',
  'o lançamento é gravado, mas nenhum saldo muda',
  $q$INSERT INTO contabil.lancamentos (data_lancamento, historico, conta_debito_id, conta_credito_id, valor)
     VALUES ('2026-04-10', 'Sem valor', teste.conta('1.1.01'), teste.conta('4.1.01'), NULL)$q$,
  $q$SELECT teste.saldo('1.1.01') = 5000 AND teste.saldo('4.1.01') = 5000
            AND EXISTS (SELECT 1 FROM contabil.lancamentos WHERE historico = 'Sem valor'),
            'lançamento gravado: ' || EXISTS (SELECT 1 FROM contabil.lancamentos WHERE historico = 'Sem valor')
            || ' · Caixa ' || teste.saldo('1.1.01') || ' · Receita ' || teste.saldo('4.1.01')$q$,
  'LIMITAÇÃO CONFIRMADA');

SELECT teste.cenario('2. Trigger', 'Lançamento só com conta de débito (crédito vazio)',
  'só um lado muda e os totais deixam de ser iguais',
  $q$INSERT INTO contabil.lancamentos (data_lancamento, historico, conta_debito_id, conta_credito_id, valor)
     VALUES ('2026-04-10', 'Só débito', teste.conta('1.1.01'), NULL, 1000)$q$,
  $q$SELECT sum(sc.saldo) FILTER (WHERE pc.natureza_conta = 'DEVEDORA') <> sum(sc.saldo) FILTER (WHERE pc.natureza_conta = 'CREDORA'),
            'devedor ' || sum(sc.saldo) FILTER (WHERE pc.natureza_conta = 'DEVEDORA')
            || ' · credor ' || sum(sc.saldo) FILTER (WHERE pc.natureza_conta = 'CREDORA')
     FROM contabil.plano_contas pc JOIN contabil.saldo_contas sc ON sc.conta_id = pc.id_conta$q$,
  'LIMITAÇÃO CONFIRMADA');

SELECT teste.cenario('2. Trigger', 'UPDATE: aluguel alterado de R$ 1.500 para R$ 2.000',
  'o saldo de Aluguel NÃO é refeito (continua 1.500)',
  $q$UPDATE contabil.lancamentos SET valor = 2000 WHERE historico = 'Pagamento de aluguel do mês'$q$,
  $q$SELECT teste.saldo('5.1.03') = 1500,
            'lançamento agora vale 2000 · saldo de Aluguel: ' || teste.saldo('5.1.03')$q$,
  'LIMITAÇÃO CONFIRMADA');

SELECT teste.cenario('2. Trigger', 'DELETE: aporte de capital apagado',
  'os saldos NÃO são refeitos (Bancos continua 20.500)',
  $q$DELETE FROM contabil.lancamentos WHERE historico = 'Aporte de capital dos sócios'$q$,
  $q$SELECT teste.saldo('1.1.02') = 20500 AND teste.saldo('3.1.01') = 30000,
            'lançamento apagado · Bancos ' || teste.saldo('1.1.02') || ' · Capital ' || teste.saldo('3.1.01')$q$,
  'LIMITAÇÃO CONFIRMADA');

SELECT teste.cenario('2. Trigger', 'Saldo guardado = saldo recalculado a partir dos lançamentos',
  'todas as contas do plano batem com a soma dos lançamentos',
  NULL,
  $q$WITH mov AS (
        SELECT pc.id_conta,
               coalesce(sum(CASE WHEN l.conta_debito_id = pc.id_conta THEN l.valor END), 0) AS deb,
               coalesce(sum(CASE WHEN l.conta_credito_id = pc.id_conta THEN l.valor END), 0) AS cred,
               pc.natureza_conta
        FROM contabil.plano_contas pc
        LEFT JOIN contabil.lancamentos l ON pc.id_conta IN (l.conta_debito_id, l.conta_credito_id)
        GROUP BY pc.id_conta, pc.natureza_conta),
     calc AS (SELECT id_conta, CASE WHEN natureza_conta = 'DEVEDORA' THEN deb - cred ELSE cred - deb END AS saldo_calc FROM mov)
     SELECT count(*) FILTER (WHERE c.saldo_calc <> sc.saldo) = 0,
            'contas divergentes: ' || count(*) FILTER (WHERE c.saldo_calc <> sc.saldo) || ' de ' || count(*)
     FROM calc c JOIN contabil.saldo_contas sc ON sc.conta_id = c.id_conta$q$);


-- ============================================================================
-- 3. VIEWS – mostram o que o projeto afirma?
-- ============================================================================
SELECT teste.cenario('3. Views', 'vw_carros: catálogo completo', '5 veículos',
  NULL, $q$SELECT count(*) = 5, count(*) || ' veículos' FROM site.vw_carros$q$);

SELECT teste.cenario('3. Views', 'vw_revisao_carros: peças compatíveis', '5 combinações peça × veículo',
  NULL, $q$SELECT count(*) = 5, count(*) || ' combinações' FROM site.vw_revisao_carros$q$);

SELECT teste.cenario('3. Views', 'INNER JOIN: veículo novo sem peça compatível',
  'aparece em vw_carros (6) e NÃO aparece em vw_revisao_carros (5)',
  $q$INSERT INTO site.veiculo (id_modelo, ano_fabricacao, motorizacao, combustivel) VALUES (1, 2024, '1.0', 'Flex')$q$,
  $q$SELECT (SELECT count(*) FROM site.vw_carros) = 6 AND (SELECT count(*) FROM site.vw_revisao_carros) = 5,
            'vw_carros: ' || (SELECT count(*) FROM site.vw_carros) || ' · vw_revisao_carros: ' || (SELECT count(*) FROM site.vw_revisao_carros)$q$);

SELECT teste.cenario('3. Views', 'LEFT JOIN: OS nova, ainda sem itens',
  'aparece em vw_gerenciamento_cliente uma vez, com item vazio',
  $q$INSERT INTO adm.ordem_servico (cliente_nome, veiculo_descricao) VALUES ('Cliente Sem Itens', 'Carro Teste')$q$,
  $q$SELECT count(*) = 1 AND bool_and(descricao_item IS NULL),
            'linhas da OS nova: ' || count(*) || ' · item: ' || coalesce(max(descricao_item), 'vazio')
     FROM adm.vw_gerenciamento_cliente WHERE nome_cliente = 'Cliente Sem Itens'$q$);

SELECT teste.cenario('3. Views', 'LEFT JOIN: OS com 2 itens',
  'a OS 5 aparece em 2 linhas, uma por item',
  NULL,
  $q$SELECT count(*) = 2, 'linhas da OS 5: ' || count(*) FROM adm.vw_gerenciamento_cliente WHERE id_os = 5$q$);

SELECT teste.cenario('3. Views', 'View sempre atualizada: nova OS aberta',
  'aparece na view sem recriá-la',
  $q$INSERT INTO adm.ordem_servico (cliente_nome, veiculo_descricao) VALUES ('Cliente View', 'Carro View')$q$,
  $q$SELECT count(*) = 1, 'linhas da nova OS na view: ' || count(*) FROM adm.vw_gerenciamento_cliente WHERE nome_cliente = 'Cliente View'$q$);


-- ============================================================================
-- 4. CONSISTÊNCIA DOS DADOS DE TESTE
-- ============================================================================
SELECT teste.cenario('4. Dados de teste', 'valor_total de cada OS = soma dos seus itens',
  'todas as 5 OS batem',
  NULL,
  $q$WITH t AS (SELECT os.id_os, os.valor_total, coalesce(sum(i.quantidade * i.valor_unitario), 0) AS soma
              FROM adm.ordem_servico os LEFT JOIN adm.item_ordem_servico i ON i.id_os = os.id_os GROUP BY os.id_os, os.valor_total)
     SELECT count(*) FILTER (WHERE valor_total <> soma) = 0,
            'OS divergentes: ' || count(*) FILTER (WHERE valor_total <> soma) || ' de 5'
            || coalesce(' → ' || string_agg(CASE WHEN valor_total <> soma THEN 'OS ' || id_os || ' (total ' || valor_total || ', itens ' || soma || ')' END, '; ' ORDER BY id_os), '')
     FROM t$q$, 'PASSOU', 'INCONSISTÊNCIA');

SELECT teste.cenario('4. Dados de teste', 'qnt_estoque de cada peça = entradas − saídas',
  'todas as 5 peças batem',
  NULL,
  $q$WITH t AS (SELECT p.id_peca, p.qnt_estoque,
                     coalesce(sum(CASE m.tipo_movimentacao WHEN 'ENTRADA' THEN m.quantidade WHEN 'SAIDA' THEN -m.quantidade ELSE 0 END), 0) AS mov
              FROM site.peca p LEFT JOIN adm.movimentacao_estoque m ON m.id_peca = p.id_peca GROUP BY p.id_peca, p.qnt_estoque)
     SELECT count(*) FILTER (WHERE qnt_estoque <> mov) = 0,
            'peças divergentes: ' || count(*) FILTER (WHERE qnt_estoque <> mov) || ' de 5'
            || coalesce(' → ' || string_agg(CASE WHEN qnt_estoque <> mov THEN 'peça ' || id_peca || ' (estoque ' || qnt_estoque || ', movimentações ' || mov || ')' END, '; ' ORDER BY id_peca), '')
     FROM t$q$, 'PASSOU', 'INCONSISTÊNCIA');


SELECT teste.cenario('4. Dados de teste', 'título = valor da nota · PAGO só quando foi pago tudo',
  'os 5 títulos batem com a nota e com os pagamentos',
  NULL,
  $q$WITH t AS (SELECT ti.id_titulo, ti.valor, ti.status, n.valor_total, coalesce(sum(lf.valor_pago), 0) AS pago
              FROM contabil.conta_pagar_receber ti
              JOIN contabil.nota_fiscal n ON n.id_nota = ti.id_nota
              LEFT JOIN contabil.lancamento_financeiro lf ON lf.id_titulo = ti.id_titulo
              GROUP BY ti.id_titulo, ti.valor, ti.status, n.valor_total),
          r AS (SELECT *, valor = valor_total AND (status = 'PAGO') = (pago = valor) AND pago <= valor AS ok FROM t)
     SELECT count(*) = 5 AND bool_and(ok),
            'títulos: ' || count(*) || ' · divergentes: ' || count(*) FILTER (WHERE NOT ok)
     FROM r$q$, 'PASSOU', 'INCONSISTÊNCIA');

SELECT teste.cenario('4. Dados de teste', 'fechamento mensal = soma das notas do mês',
  'setembro/2026: receitas 1.230 · despesas 6.063 · impostos 73,80',
  NULL,
  $q$SELECT total_receitas = 1230 AND total_despesas = 6063 AND impostos_devidos = 73.80,
            'receitas ' || total_receitas || ' · despesas ' || total_despesas || ' · impostos ' || impostos_devidos
     FROM contabil.fechamento_mensal WHERE mes_referencia = 9 AND ano_referencia = 2026$q$, 'PASSOU', 'INCONSISTÊNCIA');


-- ============================================================================
-- 5. PRÁTICAS 01 E 03 – plano de contas e carga dos lançamentos de março
-- ============================================================================
SELECT teste.cenario('5. Práticas 01 e 03', 'Plano de contas com as 23 contas da Prática 03',
  '23 contas: 6 ativo · 4 passivo · 2 patrimônio líquido · 2 receita · 9 despesa',
  NULL,
  $q$SELECT sum(n) = 23
            AND sum(n) FILTER (WHERE tipo_conta = 'ATIVO') = 6
            AND sum(n) FILTER (WHERE tipo_conta = 'PASSIVO') = 4
            AND sum(n) FILTER (WHERE tipo_conta = 'PATRIMONIO_LIQUIDO') = 2
            AND sum(n) FILTER (WHERE tipo_conta = 'RECEITA') = 2
            AND sum(n) FILTER (WHERE tipo_conta = 'DESPESA') = 9,
            string_agg(tipo_conta::text || ' ' || n, ' · ' ORDER BY tipo_conta) || ' · total ' || sum(n)
     FROM (SELECT tipo_conta, count(*) AS n FROM contabil.plano_contas GROUP BY tipo_conta) g$q$);

SELECT teste.cenario('5. Práticas 01 e 03', 'Natureza coerente com o tipo da conta',
  'ATIVO e DESPESA são DEVEDORAS; PASSIVO, PATRIMÔNIO LÍQUIDO e RECEITA são CREDORAS',
  NULL,
  $q$SELECT count(*) = 0, 'contas com natureza trocada: ' || count(*)
     FROM contabil.plano_contas
     WHERE natureza_conta <> CASE WHEN tipo_conta IN ('ATIVO', 'DESPESA') THEN 'DEVEDORA'::contabil.natureza_conta_enum
                                  ELSE 'CREDORA'::contabil.natureza_conta_enum END$q$);

SELECT teste.cenario('5. Práticas 01 e 03', 'Lançamentos de março carregados e normalizados',
  '53 lançamentos, todos entre 01/03 e 31/03/2026',
  NULL,
  $q$SELECT count(*) = 53 AND min(data_lancamento) = DATE '2026-03-01' AND max(data_lancamento) = DATE '2026-03-31',
            count(*) || ' lançamentos · de ' || min(data_lancamento) || ' a ' || max(data_lancamento)
     FROM contabil.lancamentos WHERE data_lancamento BETWEEN DATE '2026-03-01' AND DATE '2026-03-31'$q$);

SELECT teste.cenario('5. Práticas 01 e 03', 'Nomes de conta "sujos" ligados à conta certa',
  'só 1 conta vazia: o crédito de 31/03, que já veio vazio na planilha da prática',
  NULL,
  $q$SELECT count(*) FILTER (WHERE conta_debito_id IS NULL) = 0 AND count(*) FILTER (WHERE conta_credito_id IS NULL) = 1,
            'débitos vazios: ' || count(*) FILTER (WHERE conta_debito_id IS NULL)
            || ' · créditos vazios: ' || count(*) FILTER (WHERE conta_credito_id IS NULL)
     FROM contabil.lancamentos WHERE data_lancamento BETWEEN DATE '2026-03-01' AND DATE '2026-03-31'$q$);

SELECT teste.cenario('5. Práticas 01 e 03', 'Lançamentos de março não mexem nos saldos da Prática 05',
  'chegam sem valor (a planilha não tinha valores), então os saldos continuam os da Prática 05',
  NULL,
  $q$SELECT count(*) FILTER (WHERE valor IS NOT NULL) = 0 AND teste.saldo('1.1.02') = 20500,
            'lançamentos de março com valor: ' || count(*) FILTER (WHERE valor IS NOT NULL) || ' · Bancos ' || teste.saldo('1.1.02')
     FROM contabil.lancamentos WHERE data_lancamento BETWEEN DATE '2026-03-01' AND DATE '2026-03-31'$q$);


-- ============================================================================
-- RESULTADO
-- ============================================================================
SELECT categoria, status, count(*) AS testes FROM teste.resultados GROUP BY categoria, status ORDER BY categoria, status;
SELECT id, categoria, status, teste, esperado, obtido FROM teste.resultados ORDER BY id;
