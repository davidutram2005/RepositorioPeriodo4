CREATE SCHEMA IF NOT EXISTS site;
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