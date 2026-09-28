CREATE SCHEMA IF NOT EXISTS adm;
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