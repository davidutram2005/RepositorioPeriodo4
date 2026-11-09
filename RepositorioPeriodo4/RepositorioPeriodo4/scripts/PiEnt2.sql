-- ============================================================================
-- 1. CRIAÇÃO DOS ESQUEMAS (SCHEMAS)
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS site;
CREATE SCHEMA IF NOT EXISTS adm;
CREATE SCHEMA IF NOT EXISTS contabil;

-- ============================================================================
-- 2. ESQUEMA "site" (Catálogo e Compatibilidade de Peças)
-- ============================================================================

CREATE TABLE site.marca (
    id_marca SERIAL PRIMARY KEY,
    nome_marca VARCHAR(100) NOT NULL
);

CREATE TABLE site.modelo (
    id_modelo SERIAL PRIMARY KEY,
    id_marca INT REFERENCES site.marca(id_marca) ON DELETE CASCADE,
    nome_modelo VARCHAR(100) NOT NULL
);

CREATE TABLE site.veiculo (
    id_veiculo SERIAL PRIMARY KEY,
    id_modelo INT REFERENCES site.modelo(id_modelo) ON DELETE CASCADE,
    ano_fabricacao INT NOT NULL,
    motorizacao VARCHAR(50),
    combustivel VARCHAR(30)
);

CREATE TABLE site.categoria (
    id_categoria SERIAL PRIMARY KEY,
    nome_categoria VARCHAR(100) NOT NULL
);

CREATE TABLE site.peca (
    id_peca SERIAL PRIMARY KEY,
    id_categoria INT REFERENCES site.categoria(id_categoria) ON DELETE SET NULL,
    nome_peca VARCHAR(150) NOT NULL,
    fabricante VARCHAR(100),
    codigo_fabricante VARCHAR(50),
    preco_venda NUMERIC(10,2) NOT NULL CHECK (preco_venda > 0),
    qnt_estoque INT DEFAULT 0
);

CREATE TABLE site.compatibilidade (
    id_compatibilidade SERIAL PRIMARY KEY,
    id_peca INT REFERENCES site.peca(id_peca) ON DELETE CASCADE,
    id_veiculo INT REFERENCES site.veiculo(id_veiculo) ON DELETE CASCADE,
    posicao_aplicacao VARCHAR(100),
    obs TEXT
);

-- ============================================================================
-- 3. ESQUEMA "adm" (Administrativo, Estoque e Oficina)
-- ============================================================================

CREATE TABLE adm.funcionario (
    id_funcionario SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(14) NOT NULL UNIQUE,
    cargo VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    data_admissao DATE DEFAULT CURRENT_DATE NOT NULL
);

CREATE TABLE adm.fornecedor (
    id_fornecedor SERIAL PRIMARY KEY,
    razao_social VARCHAR(150) NOT NULL,
    cnpj VARCHAR(18) NOT NULL UNIQUE,
    telefone VARCHAR(20),
    email VARCHAR(100)
);

CREATE TABLE adm.ordem_servico (
    id_os SERIAL PRIMARY KEY,
    id_funcionario INT REFERENCES adm.funcionario(id_funcionario) ON DELETE SET NULL,
    cliente_nome VARCHAR(100) NOT NULL,
    cliente_telefone VARCHAR(20),
    veiculo_descricao VARCHAR(100) NOT NULL,
    status VARCHAR(30) DEFAULT 'Em Aberto' NOT NULL
        CHECK (status IN ('Em Aberto', 'Em Andamento', 'Concluída', 'Cancelada')),
    data_abertura TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valor_total NUMERIC(10,2) DEFAULT 0.00
);

CREATE TABLE adm.item_ordem_servico (
    id_item_os SERIAL PRIMARY KEY,
    id_os INT REFERENCES adm.ordem_servico(id_os) ON DELETE CASCADE,
    descricao_servico_peca VARCHAR(150) NOT NULL,
    quantidade INT DEFAULT 1 NOT NULL,
    valor_unitario NUMERIC(10,2) NOT NULL
);

CREATE TABLE adm.movimentacao_estoque (
    id_movimentacao SERIAL PRIMARY KEY,
    id_peca INT REFERENCES site.peca(id_peca) ON DELETE RESTRICT,
    id_fornecedor INT REFERENCES adm.fornecedor(id_fornecedor) ON DELETE SET NULL,
    tipo_movimentacao VARCHAR(20) NOT NULL CHECK (tipo_movimentacao IN ('ENTRADA', 'SAIDA', 'AJUSTE')),
    quantidade INT NOT NULL CHECK (quantidade > 0),
    data_movimentacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 4. ESQUEMA "contabil" (Financeiro e Fiscal)
-- ============================================================================

-- Tipos ENUM do modelo da Prática 01: o tipo da conta inclui PATRIMONIO_LIQUIDO,
-- e a natureza só aceita DEVEDORA ou CREDORA.
CREATE TYPE contabil.tipo_conta_enum AS ENUM ('ATIVO', 'PASSIVO', 'PATRIMONIO_LIQUIDO', 'RECEITA', 'DESPESA');
CREATE TYPE contabil.natureza_conta_enum AS ENUM ('DEVEDORA', 'CREDORA');

CREATE TABLE contabil.plano_contas (
    id_conta SERIAL PRIMARY KEY,
    codigo_conta VARCHAR(20) NOT NULL UNIQUE,
    descricao VARCHAR(100) NOT NULL,
    tipo_conta contabil.tipo_conta_enum NOT NULL,
    natureza_conta contabil.natureza_conta_enum NOT NULL DEFAULT 'DEVEDORA'
);

CREATE TABLE contabil.nota_fiscal (
    id_nota SERIAL PRIMARY KEY,
    numero_nf VARCHAR(30) NOT NULL,
    chave_acesso VARCHAR(44),
    tipo_operacao VARCHAR(10) NOT NULL CHECK (tipo_operacao IN ('ENTRADA', 'SAIDA')),
    id_os INT REFERENCES adm.ordem_servico(id_os) ON DELETE SET NULL,
    id_fornecedor INT REFERENCES adm.fornecedor(id_fornecedor) ON DELETE SET NULL,
    valor_total NUMERIC(10,2) NOT NULL,
    valor_impostos NUMERIC(10,2) DEFAULT 0.00,
    data_emissao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE contabil.conta_pagar_receber (
    id_titulo SERIAL PRIMARY KEY,
    id_conta INT REFERENCES contabil.plano_contas(id_conta) ON DELETE RESTRICT,
    id_nota INT REFERENCES contabil.nota_fiscal(id_nota) ON DELETE SET NULL,
    tipo VARCHAR(10) NOT NULL CHECK (tipo IN ('PAGAR', 'RECEBER')),
    descricao VARCHAR(150) NOT NULL,
    valor NUMERIC(10,2) NOT NULL,
    data_vencimento DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDENTE' CHECK (status IN ('PENDENTE', 'PAGO', 'CANCELADO'))
);

CREATE TABLE contabil.lancamento_financeiro (
    id_lancamento SERIAL PRIMARY KEY,
    id_titulo INT REFERENCES contabil.conta_pagar_receber(id_titulo) ON DELETE CASCADE,
    forma_pagamento VARCHAR(50) NOT NULL,
    valor_pago NUMERIC(10,2) NOT NULL,
    data_pagamento TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE contabil.fechamento_mensal (
    id_fechamento SERIAL PRIMARY KEY,
    mes_referencia INT NOT NULL CHECK (mes_referencia BETWEEN 1 AND 12),
    ano_referencia INT NOT NULL,
    total_receitas NUMERIC(12,2) DEFAULT 0.00 NOT NULL,
    total_despesas NUMERIC(12,2) DEFAULT 0.00 NOT NULL,
    impostos_devidos NUMERIC(10,2) DEFAULT 0.00 NOT NULL,
    status VARCHAR(20) DEFAULT 'FECHADO',
    CONSTRAINT unq_fechamento_periodo UNIQUE (mes_referencia, ano_referencia)
);

-- ============================================================================
-- 5. INSERÇÃO DOS DADOS DE TESTE (DML)
-- ============================================================================

-- Tabela: site.marca
INSERT INTO site.marca (id_marca, nome_marca) VALUES
(1, 'Volkswagen'),
(2, 'Chevrolet'),
(3, 'Fiat'),
(4, 'Ford'),
(5, 'Toyota');

-- Tabela: site.modelo
INSERT INTO site.modelo (id_modelo, id_marca, nome_modelo) VALUES
(1, 1, 'Gol'),
(2, 2, 'Onix'),
(3, 3, 'Uno'),
(4, 4, 'Ka'),
(5, 5, 'Corolla');

-- Tabela: site.veiculo
INSERT INTO site.veiculo (id_veiculo, id_modelo, ano_fabricacao, motorizacao, combustivel) VALUES
(1, 1, 2018, '1.0 8V', 'Flex'),
(2, 2, 2020, '1.0 Turbo', 'Flex'),
(3, 3, 2015, '1.4 Fire', 'Flex'),
(4, 4, 2019, '1.5 3C', 'Flex'),
(5, 5, 2021, '2.0 16V', 'Flex');

-- Tabela: site.categoria
INSERT INTO site.categoria (id_categoria, nome_categoria) VALUES
(1, 'Sistema de Freios'),
(2, 'Filtragem e Lubrificantes'),
(3, 'Suspensão e Amortecedores'),
(4, 'Ignição e Elétrica'),
(5, 'Transmissão e Correias');

-- Tabela: site.peca
INSERT INTO site.peca (id_peca, id_categoria, nome_peca, fabricante, codigo_fabricante, preco_venda, qnt_estoque) VALUES
(1, 1, 'Pastilha de Freio Dianteira', 'Fras-le', 'PD/58', 125.50, 19),
(2, 2, 'Filtro de Óleo do Motor', 'Tecfil', 'PEL108', 35.90, 49),
(3, 3, 'Amortecedor Dianteiro (Par)', 'Monroe', 'SP045', 580.00, 9),
(4, 4, 'Jogo de Velas de Ignição', 'NGK', 'BKR6E', 98.00, 29),
(5, 5, 'Kit Correia Dentada e Tensor', 'Dayco', 'KTB286', 185.00, 9);

-- Tabela: site.compatibilidade
INSERT INTO site.compatibilidade (id_compatibilidade, id_peca, id_veiculo, posicao_aplicacao, obs) VALUES
(1, 1, 1, 'Dianteiro Esquerdo / Direito', 'Válido apenas para modelos com disco sólido.'),
(2, 2, 2, 'Filtro do Motor', 'Recomendado trocar a cada substituição de óleo 5W30.'),
(3, 3, 3, 'Eixo Dianteiro', 'Acompanha batentes e coifas.'),
(4, 4, 4, 'Cabeçote do Motor', 'Embalagem contém jogo com 3 unidades.'),
(5, 5, 5, 'Distribuição / Motor', 'Verificar o estado das polias na instalação.');

-- Tabela: adm.funcionario
INSERT INTO adm.funcionario (id_funcionario, nome, cpf, cargo, email, data_admissao) VALUES
(1, 'Carlos Eduardo Silva', '111.222.333-44', 'Mecânico Chefe', 'carlos.silva@oficina.com', '2021-03-15'),
(2, 'Mariana Rocha Alves', '222.333.444-55', 'Atendente / Recepção', 'mariana.rocha@oficina.com', '2022-01-10'),
(3, 'Roberto Souza Filho', '333.444.555-66', 'Mecânico Eletricista', 'roberto.souza@oficina.com', '2020-08-01'),
(4, 'Ana Paula Mendes', '444.555.666-77', 'Gerente de Estoque', 'ana.mendes@oficina.com', '2019-05-20'),
(5, 'Lucas Fernandes', '555.666.777-88', 'Auxiliar de Mecânica', 'lucas.fernandes@oficina.com', '2023-02-01');

-- Tabela: adm.fornecedor
INSERT INTO adm.fornecedor (id_fornecedor, razao_social, cnpj, telefone, email) VALUES
(1, 'Auto Peças Distribuidora LTDA', '12.345.678/0001-90', '(11) 3333-1111', 'contato@autopecasdist.com.br'),
(2, 'Lubrificantes & Cia S/A', '98.765.432/0001-10', '(21) 2222-4444', 'vendas@lubrificantescia.com'),
(3, 'Sistemas de Freios do Brasil', '45.678.912/0001-33', '(31) 3456-7890', 'comercial@freiosbrasil.com'),
(4, 'Componentes Elétricos NGK Distribuição', '33.222.111/0001-55', '(11) 4004-5555', 'pedidos@ngkdist.com.br'),
(5, 'Distribuidora Monroe Amortecedores', '77.888.999/0001-22', '(41) 3210-9876', 'suporte@monroedist.com.br');

-- Tabela: adm.ordem_servico
INSERT INTO adm.ordem_servico (id_os, id_funcionario, cliente_nome, cliente_telefone, veiculo_descricao, status, data_abertura, valor_total) VALUES
(1, 1, 'João Pedro Santos', '(32) 99988-1122', 'VW Gol 1.0 Flex 2018', 'Em Andamento', '2026-09-01 19:48:19', 250.50),
(2, 3, 'Fernanda Costa', '(32) 98877-2233', 'Chevrolet Onix 1.0 Turbo 2020', 'Em Aberto', '2026-09-01 19:48:19', 133.90),
(3, 1, 'Marcos Vinícius', '(32) 99111-3344', 'Fiat Uno 1.4 Fire 2015', 'Concluída', '2026-09-01 19:48:19', 780.00),
(4, 5, 'Beatriz Lima', '(32) 98123-4567', 'Ford Ka 1.5 2019', 'Em Andamento', '2026-09-01 19:48:19', 198.00),
(5, 3, 'Ricardo Oliveira', '(32) 99876-5432', 'Toyota Corolla 2.0 2021', 'Concluída', '2026-09-01 19:48:19', 450.00);

-- Tabela: adm.item_ordem_servico
-- O valor_total de cada OS é a soma dos seus itens (quantidade x valor_unitario).
INSERT INTO adm.item_ordem_servico (id_item_os, id_os, descricao_servico_peca, quantidade, valor_unitario) VALUES
(1, 1, 'Mão de obra - Troca de Pastilhas de Freio', 1, 125.00),
(2, 1, 'Pastilha de Freio Fras-le PD/58', 1, 125.50),
(3, 2, 'Mão de obra - Troca de Óleo', 1, 98.00),
(4, 3, 'Troca de Par de Amortecedores Dianteiros', 1, 200.00),
(5, 4, 'Mão de obra - Troca de Velas', 1, 100.00),
(6, 2, 'Filtro de Óleo do Motor Tecfil PEL108', 1, 35.90),
(7, 3, 'Amortecedor Dianteiro Monroe SP045 (Par)', 1, 580.00),
(8, 4, 'Jogo de Velas de Ignição NGK BKR6E', 1, 98.00),
(9, 5, 'Mão de obra - Troca de Correia Dentada', 1, 265.00),
(10, 5, 'Kit Correia Dentada e Tensor Dayco KTB286', 1, 185.00);

-- Tabela: adm.movimentacao_estoque
-- ENTRADA = compra do fornecedor; SAIDA = peça usada numa OS.
-- O qnt_estoque de site.peca é o saldo destas movimentações.
INSERT INTO adm.movimentacao_estoque (id_movimentacao, id_peca, id_fornecedor, tipo_movimentacao, quantidade, data_movimentacao) VALUES
(1, 1, 3, 'ENTRADA', 20, '2026-09-01 19:48:19'),
(2, 2, 2, 'ENTRADA', 50, '2026-09-01 19:48:19'),
(3, 3, 5, 'ENTRADA', 10, '2026-09-01 19:48:19'),
(4, 4, 4, 'ENTRADA', 30, '2026-09-01 19:48:19'),
(5, 1, NULL, 'SAIDA', 1, '2026-09-01 19:48:19'),
(6, 5, 1, 'ENTRADA', 10, '2026-09-01 19:48:19'),
(7, 2, NULL, 'SAIDA', 1, '2026-09-01 19:48:19'),
(8, 3, NULL, 'SAIDA', 1, '2026-09-01 19:48:19'),
(9, 4, NULL, 'SAIDA', 1, '2026-09-01 19:48:19'),
(10, 5, NULL, 'SAIDA', 1, '2026-09-01 19:48:19');

-- ============================================================================
-- 6. AJUSTE DE CONTADORES DAS SEQUÊNCIAS (SERIAL)
-- ============================================================================
SELECT setval('site.marca_id_marca_seq', COALESCE((SELECT MAX(id_marca) FROM site.marca), 1));
SELECT setval('site.modelo_id_modelo_seq', COALESCE((SELECT MAX(id_modelo) FROM site.modelo), 1));
SELECT setval('site.veiculo_id_veiculo_seq', COALESCE((SELECT MAX(id_veiculo) FROM site.veiculo), 1));
SELECT setval('site.categoria_id_categoria_seq', COALESCE((SELECT MAX(id_categoria) FROM site.categoria), 1));
SELECT setval('site.peca_id_peca_seq', COALESCE((SELECT MAX(id_peca) FROM site.peca), 1));
SELECT setval('site.compatibilidade_id_compatibilidade_seq', COALESCE((SELECT MAX(id_compatibilidade) FROM site.compatibilidade), 1));
SELECT setval('adm.funcionario_id_funcionario_seq', COALESCE((SELECT MAX(id_funcionario) FROM adm.funcionario), 1));
SELECT setval('adm.fornecedor_id_fornecedor_seq', COALESCE((SELECT MAX(id_fornecedor) FROM adm.fornecedor), 1));
SELECT setval('adm.ordem_servico_id_os_seq', COALESCE((SELECT MAX(id_os) FROM adm.ordem_servico), 1));
SELECT setval('adm.item_ordem_servico_id_item_os_seq', COALESCE((SELECT MAX(id_item_os) FROM adm.item_ordem_servico), 1));
SELECT setval('adm.movimentacao_estoque_id_movimentacao_seq', COALESCE((SELECT MAX(id_movimentacao) FROM adm.movimentacao_estoque), 1));

-- Conferência dos dados de teste: as duas consultas devem mostrar 'ok' em todas as linhas.
-- 1) valor da OS = soma dos itens
SELECT os.id_os, os.valor_total,
       COALESCE(SUM(i.quantidade * i.valor_unitario), 0) AS soma_itens,
       CASE WHEN os.valor_total = COALESCE(SUM(i.quantidade * i.valor_unitario), 0)
            THEN 'ok' ELSE 'DIVERGENTE' END AS conferencia
FROM adm.ordem_servico os
LEFT JOIN adm.item_ordem_servico i ON i.id_os = os.id_os
GROUP BY os.id_os, os.valor_total
ORDER BY os.id_os;

-- 2) estoque da peça = entradas - saídas
SELECT p.id_peca, p.nome_peca, p.qnt_estoque,
       COALESCE(SUM(CASE WHEN m.tipo_movimentacao = 'ENTRADA' THEN m.quantidade ELSE -m.quantidade END), 0) AS saldo_movimentacoes,
       CASE WHEN p.qnt_estoque = COALESCE(SUM(CASE WHEN m.tipo_movimentacao = 'ENTRADA' THEN m.quantidade ELSE -m.quantidade END), 0)
            THEN 'ok' ELSE 'DIVERGENTE' END AS conferencia
FROM site.peca p
LEFT JOIN adm.movimentacao_estoque m ON m.id_peca = p.id_peca
GROUP BY p.id_peca, p.nome_peca, p.qnt_estoque
ORDER BY p.id_peca;


-- VIEWS
--SCHEMA SITE

-- OR REPLACE
-- serve para atualizar ou sobrescrever uma VIEW existente no banco de dados 
-- sem precisar apagá-la primeiro.


--A site.vw_carros 
--junta os dados de marca, modelo e motorização 
--para criar um catálogo completo de veículos.

--A site.vw_revisao_carros 
--cruza cada veículo com as suas peças compatíveis,
--exibindo fabricante, posição e observações de montagem.
-- ============================================================================
-- VIEWS DO SCHEMA "site"
-- ============================================================================

--Utilizada por clientes do site para navegar e filtrar o catálogo completo de veículos.
CREATE OR REPLACE VIEW site.vw_carros AS
SELECT
    v.id_veiculo,
    m.nome_marca,
    mod.nome_modelo,
    v.ano_fabricacao,
    v.motorizacao,
    v.combustivel
FROM site.veiculo v
INNER JOIN site.modelo mod ON v.id_modelo = mod.id_modelo
INNER JOIN site.marca m ON mod.id_marca = m.id_marca;

-- Utilizada por mecânicos e vendedores para conferir a compatibilidade exata de cada peça com o veículo.
CREATE OR REPLACE VIEW site.vw_revisao_carros AS
SELECT
    m.nome_marca,
    mod.nome_modelo,
    v.ano_fabricacao,
    p.nome_peca,
    p.fabricante,
    c.posicao_aplicacao,
    c.obs
FROM site.modelo mod
INNER JOIN site.marca m ON mod.id_marca = m.id_marca
INNER JOIN site.veiculo v ON mod.id_modelo = v.id_modelo
INNER JOIN site.compatibilidade c ON v.id_veiculo = c.id_veiculo
INNER JOIN site.peca p ON c.id_peca = p.id_peca;

-- ============================================================================
-- VIEWS DO SCHEMA "adm"
-- ============================================================================

-- Utilizada pela recepção e gerência para acompanhar ordens de serviço,
-- funcionários responsáveis e valores cobrados.
CREATE OR REPLACE VIEW adm.vw_gerenciamento_cliente AS
SELECT
    os.id_os,
    os.cliente_nome AS nome_cliente,
    os.cliente_telefone AS telefone_contato,
    os.veiculo_descricao AS descricao_veiculo,
    os.status AS status_os,
    os.valor_total AS valor_total_os,
    ios.descricao_servico_peca AS descricao_item,
    ios.quantidade,
    ios.valor_unitario,
    f.nome AS nome_funcionario
FROM adm.ordem_servico os
LEFT JOIN adm.funcionario f ON os.id_funcionario = f.id_funcionario
LEFT JOIN adm.item_ordem_servico ios ON os.id_os = ios.id_os;






-- ============================================================================
-- PRÁTICA 03 - CARGA DO SCHEMA "contabil" (plano de contas e lançamentos de março)
-- Base de dados exigida pela Prática 05 ("com os dados já carregados nas práticas anteriores").
-- ============================================================================

-- Tabela de lançamentos no modelo da Prática 01 (débito e crédito ligados ao plano de contas).
-- A coluna "valor" só é acrescentada na Prática 05.
CREATE TABLE IF NOT EXISTS contabil.lancamentos (
    id SERIAL PRIMARY KEY,
    data_lancamento DATE NOT NULL,
    historico VARCHAR(150) NOT NULL,
    conta_debito_id INT,
    conta_credito_id INT,
    CONSTRAINT fk_conta_debito FOREIGN KEY (conta_debito_id)
        REFERENCES contabil.plano_contas(id_conta) ON DELETE RESTRICT,
    CONSTRAINT fk_conta_credito FOREIGN KEY (conta_credito_id)
        REFERENCES contabil.plano_contas(id_conta) ON DELETE RESTRICT
);

-- (a) Plano de contas: as 23 contas da Prática 03.
-- ON CONFLICT: se a conta já existir, só atualiza nome, tipo e natureza (o script pode rodar de novo).
INSERT INTO contabil.plano_contas (codigo_conta, descricao, tipo_conta, natureza_conta) VALUES
('1.1.01', 'Caixa',                          'ATIVO',              'DEVEDORA'),
('1.1.02', 'Bancos - Conta Movimento',       'ATIVO',              'DEVEDORA'),
('1.1.03', 'Clientes a Receber',             'ATIVO',              'DEVEDORA'),
('1.1.04', 'Estoque de Mercadorias',         'ATIVO',              'DEVEDORA'),
('1.2.01', 'Móveis e Utensílios',            'ATIVO',              'DEVEDORA'),
('1.2.02', 'Veículos',                       'ATIVO',              'DEVEDORA'),
('2.1.01', 'Fornecedores a Pagar',           'PASSIVO',            'CREDORA'),
('2.1.02', 'Salários a Pagar',               'PASSIVO',            'CREDORA'),
('2.1.03', 'Impostos a Recolher',            'PASSIVO',            'CREDORA'),
('2.2.01', 'Empréstimos Bancários (LP)',     'PASSIVO',            'CREDORA'),
('3.1.01', 'Capital Social',                 'PATRIMONIO_LIQUIDO', 'CREDORA'),
('3.1.02', 'Lucros/Prejuízos Acumulados',    'PATRIMONIO_LIQUIDO', 'CREDORA'),
('4.1.01', 'Receita de Vendas',              'RECEITA',            'CREDORA'),
('4.1.02', 'Receita de Serviços',            'RECEITA',            'CREDORA'),
('5.1.01', 'Custo das Mercadorias Vendidas', 'DESPESA',            'DEVEDORA'),
('5.1.02', 'Despesas com Salários',          'DESPESA',            'DEVEDORA'),
('5.1.03', 'Despesas com Aluguel',           'DESPESA',            'DEVEDORA'),
('5.1.04', 'Despesas com Energia Elétrica',  'DESPESA',            'DEVEDORA'),
('5.1.05', 'Despesas com Água',              'DESPESA',            'DEVEDORA'),
('5.1.06', 'Despesas com Telefone/Internet', 'DESPESA',            'DEVEDORA'),
('5.1.07', 'Despesas Bancárias/Tarifas',     'DESPESA',            'DEVEDORA'),
('5.1.08', 'Despesas com Combustível',       'DESPESA',            'DEVEDORA'),
('5.1.09', 'Despesas Diversas',              'DESPESA',            'DEVEDORA')
ON CONFLICT (codigo_conta) DO UPDATE
SET descricao = EXCLUDED.descricao,
    tipo_conta = EXCLUDED.tipo_conta,
    natureza_conta = EXCLUDED.natureza_conta;

-- (b) Lançamentos de março/2026.
-- Os dados chegaram "sujos", exatamente como na tabela da Prática 03. Por isso entram primeiro
-- numa tabela temporária, como texto, e são normalizados na passagem para contabil.lancamentos:
--   1. Nomes de conta fora do padrão ("Bancos", "Fornecedor", "CMV", "CAIXA"):
--      a comparação ignora maiúsculas e espaços, e um dicionário de apelidos liga cada
--      apelido ao código da conta correta.
--   2. Data fora do padrão ("05-03-2026"): o hífen vira barra antes da conversão para DATE.
--   3. Lançamento de 26/03 sem valor e valores em geral: o modelo da Prática 01 não tem a
--      coluna "valor", então nenhum valor é carregado (a Prática 05 confirma: os lançamentos
--      de março ficam sem valor e não entram no cálculo dos saldos).
--   4. Lançamento de 31/03 sem conta de crédito: entra só com a conta de débito
--      (as colunas de conta aceitam nulo no modelo da Prática 01).
CREATE TEMP TABLE carga_lancamentos_marco (
    linha INT,
    data_texto TEXT,
    historico TEXT,
    conta_debito TEXT,
    conta_credito TEXT,
    valor_texto TEXT
);

INSERT INTO carga_lancamentos_marco VALUES
( 1, '01/03/2026', 'Aporte de capital dos sócios',                'Bancos - Conta Movimento',       'Capital Social',             '50.000,00'),
( 2, '02/03/2026', 'Compra de mercadorias para revenda, a prazo', 'Estoque de Mercadorias',         'Fornecedores a Pagar',       '18.000,00'),
( 3, '03/03/2026', 'Pagamento de aluguel do mês',                 'Despesas com Aluguel',           'Caixa',                      '3.200,00'),
( 4, '03/03/2026', 'Venda de mercadorias à vista',                'Caixa',                          'Receita de Vendas',          '4.500,00'),
( 5, '03/03/2026', 'Baixa do custo da mercadoria vendida',        'Custo das Mercadorias Vendidas', 'Estoque de Mercadorias',     '2.700,00'),
( 6, '04/03/2026', 'Venda de mercadorias a prazo',                'Clientes a Receber',             'Receita de Vendas',          '6.200,00'),
( 7, '04/03/2026', 'Baixa do CMV da venda a prazo',               'Custo das Mercadorias Vendidas', 'Estoque de Mercadorias',     '3.720,00'),
( 8, '05/03/2026', 'Compra de mercadorias à vista',               'Estoque de Mercadorias',         'Bancos - Conta Movimento',   '9.000,00'),
( 9, '05-03-2026', 'Pagamento de conta de energia elétrica',      'Despesas com Energia Elétrica',  'Bancos',                     '850,00'),
(10, '06/03/2026', 'Recebimento de cliente (venda dia 04)',       'Bancos - Conta Movimento',       'Clientes a Receber',         '6.200,00'),
(11, '07/03/2026', 'Pagamento a fornecedor',                      'Fornecedor',                     'Bancos - Conta Movimento',   '9.000,00'),
(12, '08/03/2026', 'Venda de mercadorias à vista',                'CAIXA',                          'Receita de Vendas',          '5.100,00'),
(13, '08/03/2026', 'Baixa do CMV',                                'CMV',                            'Estoque de Mercadorias',     '3.060,00'),
(14, '09/03/2026', 'Pagamento de salários',                       'Despesas com Salários',          'Bancos - Conta Movimento',   '7.500,00'),
(15, '09/03/2026', 'Retenção de INSS/FGTS sobre a folha',         'Despesas com Salários',          'Impostos a Recolher',        '1.650,00'),
(16, '10/03/2026', 'Pagamento de telefone e internet',            'Despesas com Telefone/Internet', 'Bancos - Conta Movimento',   '320,00'),
(17, '10/03/2026', 'Compra de mercadorias a prazo',               'Estoque de Mercadorias',         'Fornecedores a Pagar',       '14.500,00'),
(18, '11/03/2026', 'Venda de mercadorias a prazo',                'Clientes a Receber',             'Receita de Vendas',          '8.300,00'),
(19, '11/03/2026', 'Baixa do CMV',                                'CMV',                            'Estoque de Mercadorias',     '4.980,00'),
(20, '12/03/2026', 'Pagamento de tarifas bancárias',              'Despesas Bancárias/Tarifas',     'Bancos - Conta Movimento',   '95,00'),
(21, '12/03/2026', 'Combustível para entregas',                   'Despesas com Combustível',       'Caixa',                      '410,00'),
(22, '13/03/2026', 'Recebimento de cliente',                      'Bancos - Conta Movimento',       'Clientes a Receber',         '8.300,00'),
(23, '14/03/2026', 'Venda de mercadorias à vista',                'Caixa',                          'Receita de Vendas',          '3.900,00'),
(24, '14/03/2026', 'Baixa do CMV',                                'CMV',                            'Estoque de Mercadorias',     '2.340,00'),
(25, '15/03/2026', 'Pagamento de água',                           'Despesas com Água',              'Bancos - Conta Movimento',   '210,00'),
(26, '15/03/2026', 'Empréstimo bancário recebido',                'Bancos - Conta Movimento',       'Empréstimos Bancários (LP)', '20.000,00'),
(27, '16/03/2026', 'Compra de veículo para entregas, à vista',    'Veículos',                       'Bancos - Conta Movimento',   '22.000,00'),
(28, '16/03/2026', 'Compra de mercadorias a prazo',               'Estoque de Mercadorias',         'Fornecedores a Pagar',       '11.200,00'),
(29, '17/03/2026', 'Venda de mercadorias a prazo',                'Clientes a Receber',             'Receita de Vendas',          '7.400,00'),
(30, '17/03/2026', 'Baixa do CMV',                                'CMV',                            'Estoque de Mercadorias',     '4.440,00'),
(31, '18/03/2026', 'Pagamento a fornecedores',                    'Fornecedores a Pagar',           'Bancos - Conta Movimento',   '14.500,00'),
(32, '18/03/2026', 'Prestação de serviço de instalação',          'Bancos - Conta Movimento',       'Receita de Serviços',        '1.800,00'),
(33, '19/03/2026', 'Venda de mercadorias à vista',                'Caixa',                          'Receita de Vendas',          '4.700,00'),
(34, '19/03/2026', 'Baixa do CMV',                                'CMV',                            'Estoque de Mercadorias',     '2.820,00'),
(35, '20/03/2026', 'Pagamento de parcela do empréstimo',          'Empréstimos Bancários (LP)',     'Bancos - Conta Movimento',   '2.000,00'),
(36, '20/03/2026', 'Material de escritório',                      'Despesas Diversas',              'Caixa',                      '180,00'),
(37, '21/03/2026', 'Recebimento de cliente',                      'Bancos - Conta Movimento',       'Clientes a Receber',         '7.400,00'),
(38, '21/03/2026', 'Venda de mercadorias a prazo',                'Clientes a Receber',             'Receita de Vendas',          '5.600,00'),
(39, '21/03/2026', 'Baixa do CMV',                                'CMV',                            'Estoque de Mercadorias',     '3.360,00'),
(40, '22/03/2026', 'Compra de mercadorias à vista',               'Estoque de Mercadorias',         'Caixa',                      '6.000,00'),
(41, '23/03/2026', 'Pagamento de tarifas bancárias',              'Despesas Bancárias/Tarifas',     'Bancos - Conta Movimento',   '88,00'),
(42, '24/03/2026', 'Venda de mercadorias à vista',                'Caixa',                          'Receita de Vendas',          '3.300,00'),
(43, '24/03/2026', 'Baixa do CMV',                                'CMV',                            'Estoque de Mercadorias',     '1.980,00'),
(44, '25/03/2026', 'Pagamento de impostos (Simples Nacional)',    'Impostos a Recolher',            'Bancos - Conta Movimento',   '2.450,00'),
(45, '25/03/2026', 'Venda de mercadorias à vista',                'Caixa',                          'Receita de Vendas',          '3.300,00'),
(46, '25/03/2026', 'Baixa do CMV',                                'CMV',                            'Estoque de Mercadorias',     '1.980,00'),
(47, '26/03/2026', 'Adiantamento de aluguel',                     'Despesas com Aluguel',           'Bancos - Conta Movimento',   NULL),
(48, '27/03/2026', 'Compra de mercadorias a prazo',               'Estoque de Mercadorias',         'Fornecedores a Pagar',       '9.800,00'),
(49, '28/03/2026', 'Venda de mercadorias a prazo',                'Clientes a Receber',             'Receita de Vendas',          '6.100,00'),
(50, '28/03/2026', 'Baixa do CMV',                                'CMV',                            'Estoque de Mercadorias',     '3.660,00'),
(51, '29/03/2026', 'Pagamento de salários',                       'Despesas com Salários',          'Bancos - Conta Movimento',   '7.500,00'),
(52, '30/03/2026', 'Recebimento de cliente',                      'Bancos - Conta Movimento',       'Clientes a Receber',         '5.600,00'),
(53, '31/03/2026', 'Despesas diversas do mês',                    'Despesas Diversas',              NULL,                         '150,00');

-- Dicionário de apelidos: nome que veio na planilha -> código da conta correta.
CREATE TEMP TABLE apelido_conta (apelido TEXT PRIMARY KEY, codigo_conta VARCHAR(20)) ;
INSERT INTO apelido_conta VALUES
('bancos',     '1.1.02'),   -- "Bancos"     -> Bancos - Conta Movimento
('fornecedor', '2.1.01'),   -- "Fornecedor" -> Fornecedores a Pagar
('cmv',        '5.1.01');   -- "CMV"        -> Custo das Mercadorias Vendidas

-- Função auxiliar: devolve o id da conta a partir do nome (exato, sem diferenciar
-- maiúsculas e espaços, ou pelo apelido). Nome vazio devolve NULL.
CREATE OR REPLACE FUNCTION pg_temp.id_da_conta(p_nome TEXT) RETURNS INT AS $$
    SELECT coalesce(
        (SELECT id_conta FROM contabil.plano_contas
          WHERE lower(trim(descricao)) = lower(trim(p_nome))),
        (SELECT pc.id_conta FROM contabil.plano_contas pc
           JOIN apelido_conta a ON a.codigo_conta = pc.codigo_conta
          WHERE a.apelido = lower(trim(p_nome))));
$$ LANGUAGE sql;

-- Remove os lançamentos de março de uma execução anterior (o script pode rodar de novo).
DELETE FROM contabil.lancamentos
WHERE data_lancamento BETWEEN DATE '2026-03-01' AND DATE '2026-03-31';

INSERT INTO contabil.lancamentos (data_lancamento, historico, conta_debito_id, conta_credito_id)
SELECT to_date(replace(data_texto, '-', '/'), 'DD/MM/YYYY'),
       historico,
       pg_temp.id_da_conta(conta_debito),
       pg_temp.id_da_conta(conta_credito)
FROM carga_lancamentos_marco
ORDER BY linha;

-- Conferência da carga: 23 contas, 53 lançamentos de março, e nenhum nome de conta
-- que tenha ficado sem correspondência (a única conta vazia esperada é o crédito de 31/03).
SELECT (SELECT count(*) FROM contabil.plano_contas) AS contas_no_plano,
       (SELECT count(*) FROM contabil.lancamentos
         WHERE data_lancamento BETWEEN DATE '2026-03-01' AND DATE '2026-03-31') AS lancamentos_marco;

SELECT c.linha, c.data_texto, c.conta_debito, c.conta_credito,
       pg_temp.id_da_conta(c.conta_debito) AS id_debito,
       pg_temp.id_da_conta(c.conta_credito) AS id_credito
FROM carga_lancamentos_marco c
WHERE pg_temp.id_da_conta(c.conta_debito) IS NULL
   OR (c.conta_credito IS NOT NULL AND pg_temp.id_da_conta(c.conta_credito) IS NULL)
   OR c.conta_credito IS NULL;


-- ============================================================================
-- DADOS DE TESTE DO SCHEMA "contabil" (notas, títulos, pagamentos e fechamento)
-- Fictícios, mas coerentes com os dados de "adm":
--   - notas de SAÍDA só para as OS concluídas (OS 3 e OS 5), com o valor da OS;
--   - notas de ENTRADA para as compras de estoque registradas em adm.movimentacao_estoque,
--     com custo de 60% do preço de venda da peça;
--   - impostos de 6% sobre as vendas (alíquota fictícia do Simples Nacional);
--   - cada título tem o valor da sua nota; títulos PAGOS têm pagamento do valor total;
--   - o fechamento mensal é calculado a partir das notas, e não digitado.
-- ON CONFLICT DO NOTHING permite executar o bloco mais de uma vez.
-- ============================================================================

-- Tabela: contabil.nota_fiscal
INSERT INTO contabil.nota_fiscal (id_nota, numero_nf, tipo_operacao, id_os, id_fornecedor, valor_total, valor_impostos, data_emissao) VALUES
(1, '000101', 'SAIDA',   3,    NULL,  780.00, 46.80, '2026-09-05 10:00:00'),  -- OS 3: amortecedores (Marcos Vinícius)
(2, '000102', 'SAIDA',   5,    NULL,  450.00, 27.00, '2026-09-08 16:30:00'),  -- OS 5: Toyota Corolla (Ricardo Oliveira)
(3, '58231',  'ENTRADA', NULL, 3,    1506.00,  0.00, '2026-09-01 09:00:00'),  -- 20 pastilhas x R$ 75,30
(4, '7740',   'ENTRADA', NULL, 2,    1077.00,  0.00, '2026-09-01 09:30:00'),  -- 50 filtros x R$ 21,54
(5, '120988', 'ENTRADA', NULL, 5,    3480.00,  0.00, '2026-09-01 10:15:00')   -- 10 pares de amortecedores x R$ 348,00
ON CONFLICT (id_nota) DO NOTHING;

-- Tabela: contabil.conta_pagar_receber (títulos)
-- RECEBER -> conta 1.1.03 Clientes a Receber · PAGAR -> conta 2.1.01 Fornecedores a Pagar
INSERT INTO contabil.conta_pagar_receber (id_titulo, id_conta, id_nota, tipo, descricao, valor, data_vencimento, status) VALUES
(1, (SELECT id_conta FROM contabil.plano_contas WHERE codigo_conta = '1.1.03'), 1, 'RECEBER', 'NF 000101 - OS 3',               780.00, '2026-09-05', 'PAGO'),
(2, (SELECT id_conta FROM contabil.plano_contas WHERE codigo_conta = '1.1.03'), 2, 'RECEBER', 'NF 000102 - OS 5',               450.00, '2026-10-08', 'PENDENTE'),
(3, (SELECT id_conta FROM contabil.plano_contas WHERE codigo_conta = '2.1.01'), 3, 'PAGAR',   'NF 58231 - Sistemas de Freios',  1506.00, '2026-09-30', 'PAGO'),
(4, (SELECT id_conta FROM contabil.plano_contas WHERE codigo_conta = '2.1.01'), 4, 'PAGAR',   'NF 7740 - Lubrificantes & Cia',  1077.00, '2026-10-01', 'PAGO'),
(5, (SELECT id_conta FROM contabil.plano_contas WHERE codigo_conta = '2.1.01'), 5, 'PAGAR',   'NF 120988 - Monroe',             3480.00, '2026-10-31', 'PENDENTE')
ON CONFLICT (id_titulo) DO NOTHING;

-- Tabela: contabil.lancamento_financeiro (pagamentos e recebimentos efetivados)
-- Os títulos 2 e 5 estão PENDENTES porque só foram pagos em parte.
INSERT INTO contabil.lancamento_financeiro (id_lancamento, id_titulo, forma_pagamento, valor_pago, data_pagamento) VALUES
(1, 1, 'Pix',                     780.00, '2026-09-05 10:05:00'),
(2, 3, 'Boleto',                 1506.00, '2026-09-30 14:00:00'),
(3, 4, 'Boleto',                 1077.00, '2026-10-01 11:20:00'),
(4, 5, 'Transferência bancária', 1740.00, '2026-10-15 09:00:00'),  -- 1ª parcela de 2
(5, 2, 'Cartão de crédito',       225.00, '2026-10-08 17:45:00')   -- entrada de 50%
ON CONFLICT (id_lancamento) DO NOTHING;

-- Tabela: contabil.fechamento_mensal (calculado a partir das notas fiscais)
INSERT INTO contabil.fechamento_mensal (mes_referencia, ano_referencia, total_receitas, total_despesas, impostos_devidos, status)
SELECT extract(month FROM data_emissao)::int,
       extract(year FROM data_emissao)::int,
       coalesce(sum(valor_total) FILTER (WHERE tipo_operacao = 'SAIDA'), 0),
       coalesce(sum(valor_total) FILTER (WHERE tipo_operacao = 'ENTRADA'), 0),
       coalesce(sum(valor_impostos), 0),
       'FECHADO'
FROM contabil.nota_fiscal
GROUP BY 1, 2
ON CONFLICT ON CONSTRAINT unq_fechamento_periodo DO UPDATE
SET total_receitas = EXCLUDED.total_receitas,
    total_despesas = EXCLUDED.total_despesas,
    impostos_devidos = EXCLUDED.impostos_devidos;

-- Ajuste das sequências, como nos demais schemas
SELECT setval('contabil.nota_fiscal_id_nota_seq', COALESCE((SELECT MAX(id_nota) FROM contabil.nota_fiscal), 1));
SELECT setval('contabil.conta_pagar_receber_id_titulo_seq', COALESCE((SELECT MAX(id_titulo) FROM contabil.conta_pagar_receber), 1));
SELECT setval('contabil.lancamento_financeiro_id_lancamento_seq', COALESCE((SELECT MAX(id_lancamento) FROM contabil.lancamento_financeiro), 1));

-- Conferência: cada título vale o mesmo que a sua nota, e o status bate com o que foi pago
SELECT t.id_titulo, t.tipo, t.valor AS valor_titulo, n.valor_total AS valor_nota,
       coalesce(sum(lf.valor_pago), 0) AS total_pago, t.status,
       CASE WHEN t.valor = n.valor_total
             AND (t.status = 'PAGO') = (coalesce(sum(lf.valor_pago), 0) = t.valor)
            THEN 'ok' ELSE 'DIVERGENTE' END AS conferencia
FROM contabil.conta_pagar_receber t
JOIN contabil.nota_fiscal n ON n.id_nota = t.id_nota
LEFT JOIN contabil.lancamento_financeiro lf ON lf.id_titulo = t.id_titulo
GROUP BY t.id_titulo, t.tipo, t.valor, n.valor_total, t.status
ORDER BY t.id_titulo;


-- ============================================================================
-- ENTREGA 03 - PRÁTICA 05: TRIGGER E FUNÇÃO DE BANCO (saldo automático das contas)
-- ============================================================================


-- PASSO 1: Ajustar a tabela de lançamentos e o plano de contas

-- Garante a criação da tabela de lançamentos
CREATE TABLE IF NOT EXISTS contabil.lancamentos (
    id SERIAL PRIMARY KEY,
    data_lancamento DATE NOT NULL,
    historico VARCHAR(150) NOT NULL,
    conta_debito_id INT REFERENCES contabil.plano_contas(id_conta) ON DELETE RESTRICT,
    conta_credito_id INT REFERENCES contabil.plano_contas(id_conta) ON DELETE RESTRICT
);

-- Adiciona a coluna 'valor' com restrição para aceitar apenas valores maiores que zero
ALTER TABLE contabil.lancamentos 
ADD COLUMN IF NOT EXISTS valor NUMERIC(14,2) CHECK (valor > 0);

-- Natureza das contas: a coluna natureza_conta já existe desde a criação do
-- plano_contas (ENUM da Prática 01). Aqui ela é atualizada pelo grupo do código.

UPDATE contabil.plano_contas SET natureza_conta = 'DEVEDORA' WHERE codigo_conta LIKE '1.%' OR codigo_conta LIKE '5.%';
UPDATE contabil.plano_contas SET natureza_conta = 'CREDORA' WHERE codigo_conta LIKE '2.%' OR codigo_conta LIKE '3.%' OR codigo_conta LIKE '4.%';

-- Inserção das contas de teste (caso ainda não estejam cadastradas)
INSERT INTO contabil.plano_contas (codigo_conta, descricao, tipo_conta, natureza_conta) VALUES
('1.1.01', 'Caixa', 'ATIVO', 'DEVEDORA'),
('1.1.02', 'Bancos Conta Movimento', 'ATIVO', 'DEVEDORA'),
('1.1.04', 'Estoque de Mercadorias', 'ATIVO', 'DEVEDORA'),
('2.1.01', 'Fornecedores a Pagar', 'PASSIVO', 'CREDORA'),
('3.1.01', 'Capital Social', 'PATRIMONIO_LIQUIDO', 'CREDORA'),
('4.1.01', 'Receita de Vendas', 'RECEITA', 'CREDORA'),
('5.1.01', 'Custo das Mercadorias Vendidas', 'DESPESA', 'DEVEDORA'),
('5.1.03', 'Despesas com Aluguel', 'DESPESA', 'DEVEDORA')
ON CONFLICT (codigo_conta) DO UPDATE 
SET tipo_conta = EXCLUDED.tipo_conta,
    natureza_conta = EXCLUDED.natureza_conta;



-- PASSO 2: Criar a tabela 'saldo_contas'

CREATE TABLE IF NOT EXISTS contabil.saldo_contas (
    conta_id INT PRIMARY KEY REFERENCES contabil.plano_contas(id_conta) ON DELETE CASCADE,
    saldo NUMERIC(14,2) NOT NULL DEFAULT 0.00,
    data_atualizacao TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- PASSO 3: Carga inicial da tabela 'saldo_contas' (saldo zero)

TRUNCATE TABLE contabil.saldo_contas CASCADE;

INSERT INTO contabil.saldo_contas (conta_id, saldo, data_atualizacao)
SELECT id_conta, 0.00, CURRENT_TIMESTAMP
FROM contabil.plano_contas
ON CONFLICT (conta_id) DO NOTHING;

-- Conferência da carga inicial (atividade 3 da Prática 05):
-- cada conta do plano de contas deve aparecer uma vez, com saldo 0.00.
SELECT conta_id, saldo, data_atualizacao
FROM contabil.saldo_contas
ORDER BY conta_id;


-- PASSO 4: Criar a função do Trigger em PL/pgSQL

CREATE OR REPLACE FUNCTION contabil.fn_atualiza_saldo()
RETURNS TRIGGER AS $$
DECLARE
    v_natureza_debito contabil.natureza_conta_enum;
    v_natureza_credito contabil.natureza_conta_enum;
BEGIN
    -- Se o valor for nulo ou inválido, retorna sem alterar
    IF NEW.valor IS NULL OR NEW.valor <= 0 THEN
        RETURN NEW;
    END IF;

    -- Processa a conta de débito
    IF NEW.conta_debito_id IS NOT NULL THEN
        SELECT natureza_conta INTO v_natureza_debito
        FROM contabil.plano_contas
        WHERE id_conta = NEW.conta_debito_id;

        IF v_natureza_debito = 'DEVEDORA' THEN
            UPDATE contabil.saldo_contas
            SET saldo = saldo + NEW.valor,
                data_atualizacao = CURRENT_TIMESTAMP
            WHERE conta_id = NEW.conta_debito_id;
        ELSIF v_natureza_debito = 'CREDORA' THEN
            UPDATE contabil.saldo_contas
            SET saldo = saldo - NEW.valor,
                data_atualizacao = CURRENT_TIMESTAMP
            WHERE conta_id = NEW.conta_debito_id;
        END IF;
    END IF;

    -- Processa a conta de crédito
    IF NEW.conta_credito_id IS NOT NULL THEN
        SELECT natureza_conta INTO v_natureza_credito
        FROM contabil.plano_contas
        WHERE id_conta = NEW.conta_credito_id;

        IF v_natureza_credito = 'DEVEDORA' THEN
            UPDATE contabil.saldo_contas
            SET saldo = saldo - NEW.valor,
                data_atualizacao = CURRENT_TIMESTAMP
            WHERE conta_id = NEW.conta_credito_id;
        ELSIF v_natureza_credito = 'CREDORA' THEN
            UPDATE contabil.saldo_contas
            SET saldo = saldo + NEW.valor,
                data_atualizacao = CURRENT_TIMESTAMP
            WHERE conta_id = NEW.conta_credito_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- PASSO 5: Criar o Trigger

DROP TRIGGER IF EXISTS trg_atualiza_saldo ON contabil.lancamentos;

CREATE TRIGGER trg_atualiza_saldo
AFTER INSERT ON contabil.lancamentos
FOR EACH ROW
EXECUTE FUNCTION contabil.fn_atualiza_saldo();


-- PASSO 6: Inserção dos lançamentos de teste

-- Remove só os lançamentos de teste de uma execução anterior (os que têm valor).
-- Os lançamentos de março, carregados na Prática 03, ficam sem valor e são mantidos.
DELETE FROM contabil.lancamentos WHERE valor IS NOT NULL;

INSERT INTO contabil.lancamentos (data_lancamento, historico, conta_debito_id, conta_credito_id, valor) VALUES
('2026-04-01', 'Aporte de capital dos sócios', 
 (SELECT id_conta FROM contabil.plano_contas WHERE descricao ILIKE '%Bancos%Movimento%'), 
 (SELECT id_conta FROM contabil.plano_contas WHERE descricao ILIKE '%Capital Social%'), 
 30000.00),

('2026-04-02', 'Compra de mercadorias à vista', 
 (SELECT id_conta FROM contabil.plano_contas WHERE descricao ILIKE '%Estoque de Mercadorias%'), 
 (SELECT id_conta FROM contabil.plano_contas WHERE descricao ILIKE '%Bancos%Movimento%'), 
 8000.00),

('2026-04-03', 'Venda de mercadorias à vista', 
 (SELECT id_conta FROM contabil.plano_contas WHERE descricao ILIKE '%Caixa%'), 
 (SELECT id_conta FROM contabil.plano_contas WHERE descricao ILIKE '%Receita de Vendas%'), 
 5000.00),

('2026-04-03', 'Baixa do custo da mercadoria vendida', 
 (SELECT id_conta FROM contabil.plano_contas WHERE descricao ILIKE '%Custo das Mercadorias Vendidas%'), 
 (SELECT id_conta FROM contabil.plano_contas WHERE descricao ILIKE '%Estoque de Mercadorias%'), 
 3000.00),

('2026-04-05', 'Pagamento de aluguel do mês', 
 (SELECT id_conta FROM contabil.plano_contas WHERE descricao ILIKE '%Despesas com Aluguel%'), 
 (SELECT id_conta FROM contabil.plano_contas WHERE descricao ILIKE '%Bancos%Movimento%'), 
 1500.00),

('2026-04-06', 'Compra de mercadorias a prazo', 
 (SELECT id_conta FROM contabil.plano_contas WHERE descricao ILIKE '%Estoque de Mercadorias%'), 
 (SELECT id_conta FROM contabil.plano_contas WHERE descricao ILIKE '%Fornecedores a Pagar%'), 
 4000.00);


-- PASSO 7: Consulta de conferência dos saldos (JOIN)

SELECT 
    pc.codigo_conta AS codigo,
    pc.descricao AS conta,
    pc.natureza_conta AS natureza,
    sc.saldo AS "Saldo (R$)"
FROM contabil.plano_contas pc
INNER JOIN contabil.saldo_contas sc ON pc.id_conta = sc.conta_id
ORDER BY pc.codigo_conta;


-- PASSO 8: Soma dos saldos agrupada por natureza da conta
/*
Explicação: Os dois totais devem ser iguais (R$ 39.000,00) devido ao Princípio das Partidas Dobradas 
da Contabilidade, onde cada lançamento possui origens e aplicações de valores equivalentes.
*/

SELECT 
    pc.natureza_conta AS natureza,
    SUM(sc.saldo) AS "Total (R$)"
FROM contabil.plano_contas pc
INNER JOIN contabil.saldo_contas sc ON pc.id_conta = sc.conta_id
GROUP BY pc.natureza_conta;
-- PASSO 9: Exclusão e alteração de lançamentos (atividade 9 da Prática 05)
/*
O que acontece com os saldos se um lançamento for excluído ou alterado?

O trigger trg_atualiza_saldo é disparado somente em INSERT (AFTER INSERT). Por isso:
- Se um lançamento for EXCLUÍDO (DELETE), os saldos não mudam: o valor que ele
  somou ou subtraiu continua nas contas, como se o lançamento ainda existisse.
- Se um lançamento for ALTERADO (UPDATE) - no valor, na conta de débito ou na
  conta de crédito -, os saldos também não mudam e continuam refletindo os dados antigos.
Nos dois casos, a tabela saldo_contas deixa de corresponder aos lançamentos, e a
soma das contas devedoras pode deixar de ser igual à soma das credoras.

O que seria necessário para que o saldo continuasse correto?
1. Disparar o trigger também em DELETE e UPDATE:
   AFTER INSERT OR UPDATE OR DELETE ON contabil.lancamentos FOR EACH ROW.
2. Na função, usar TG_OP para saber qual operação disparou o trigger e:
   - INSERT: aplicar o efeito de NEW (como já é feito hoje);
   - DELETE: desfazer o efeito de OLD, aplicando a regra ao contrário
     (o que tinha somado passa a subtrair, e vice-versa), e retornar OLD;
   - UPDATE: desfazer o efeito de OLD e depois aplicar o efeito de NEW.
3. Alternativa usada na contabilidade: não permitir UPDATE nem DELETE em
   lançamentos e corrigir erros com um lançamento de estorno, que tem débito
   e crédito invertidos. Assim o histórico fica completo e o trigger atual basta.
*/
