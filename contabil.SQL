CREATE SCHEMA IF NOT EXISTS contabil;
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