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
    preco_venda NUMERIC(10,2) NOT NULL,
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
    status VARCHAR(30) DEFAULT 'Em Aberto' NOT NULL,
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
    quantidade INT NOT NULL,
    data_movimentacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 4. ESQUEMA "contabil" (Financeiro e Fiscal)
-- ============================================================================

CREATE TABLE contabil.plano_contas (
    id_conta SERIAL PRIMARY KEY,
    codigo_conta VARCHAR(20) NOT NULL UNIQUE,
    descricao VARCHAR(100) NOT NULL,
    tipo_conta VARCHAR(20) NOT NULL CHECK (tipo_conta IN ('RECEITA', 'DESPESA', 'ATIVO', 'PASSIVO'))
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
(1, 1, 'Pastilha de Freio Dianteira', 'Fras-le', 'PD/58', 125.50, 15),
(2, 2, 'Filtro de Óleo do Motor', 'Tecfil', 'PEL108', 35.90, 40),
(3, 3, 'Amortecedor Dianteiro (Par)', 'Monroe', 'SP045', 580.00, 6),
(4, 4, 'Jogo de Velas de Ignição', 'NGK', 'BKR6E', 98.00, 25),
(5, 5, 'Kit Correia Dentada e Tensor', 'Dayco', 'KTB286', 185.00, 10);

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
INSERT INTO adm.item_ordem_servico (id_item_os, id_os, descricao_servico_peca, quantidade, valor_unitario) VALUES
(1, 1, 'Mão de obra - Troca de Pastilhas de Freio', 1, 125.00),
(2, 1, 'Pastilha de Freio Fras-le PD/58', 1, 125.50),
(3, 2, 'Mão de obra - Troca de Óleo', 1, 98.00),
(4, 3, 'Troca de Par de Amortecedores Dianteiros', 1, 200.00),
(5, 4, 'Mão de obra - Troca de Velas', 1, 100.00);

-- Tabela: adm.movimentacao_estoque
INSERT INTO adm.movimentacao_estoque (id_movimentacao, id_peca, id_fornecedor, tipo_movimentacao, quantidade, data_movimentacao) VALUES
(1, 1, 3, 'ENTRADA', 20, '2026-09-01 19:48:19'),
(2, 2, 2, 'ENTRADA', 50, '2026-09-01 19:48:19'),
(3, 3, 5, 'ENTRADA', 10, '2026-09-01 19:48:19'),
(4, 4, 4, 'ENTRADA', 30, '2026-09-01 19:48:19'),
(5, 1, NULL, 'SAIDA', 1, '2026-09-01 19:48:19');

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


--VIWE´S 
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
 funcionários responsáveis e valores cobrados.
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