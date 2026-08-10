-- Antifraude em cartao de credito - DDL
-- Schema proprio, separado do "public"

CREATE SCHEMA IF NOT EXISTS antifraude;
SET search_path TO antifraude;

DROP TABLE IF EXISTS transacoes CASCADE;
DROP TABLE IF EXISTS cartoes CASCADE;
DROP TABLE IF EXISTS clientes CASCADE;

CREATE TABLE clientes (
    cliente_id      INTEGER PRIMARY KEY,
    nome_completo   VARCHAR(120) NOT NULL,
    idade           SMALLINT CHECK (idade BETWEEN 16 AND 100),
    cidade          VARCHAR(80) NOT NULL,
    uf              CHAR(2) NOT NULL,
    score_credito   SMALLINT CHECK (score_credito BETWEEN 0 AND 1000),
    data_cadastro   DATE NOT NULL
);

CREATE TABLE cartoes (
    cartao_id       INTEGER PRIMARY KEY,
    cliente_id      INTEGER NOT NULL REFERENCES clientes(cliente_id),
    bandeira        VARCHAR(30) NOT NULL,
    tipo_cartao     VARCHAR(20) NOT NULL,
    limite_credito  NUMERIC(12,2) NOT NULL CHECK (limite_credito > 0),
    data_emissao    DATE NOT NULL
);

CREATE TABLE transacoes (
    transacao_id    BIGINT PRIMARY KEY,
    cartao_id       INTEGER NOT NULL REFERENCES cartoes(cartao_id),
    data_hora       TIMESTAMP NOT NULL,
    valor           NUMERIC(12,2) NOT NULL CHECK (valor > 0),
    categoria       VARCHAR(40) NOT NULL,
    canal           VARCHAR(40) NOT NULL,
    uf_transacao    CHAR(2) NOT NULL,
    fraude          BOOLEAN NOT NULL DEFAULT FALSE,
    tipo_fraude     VARCHAR(40)
);

CREATE INDEX idx_cartoes_cliente ON cartoes(cliente_id);
CREATE INDEX idx_transacoes_cartao ON transacoes(cartao_id);
CREATE INDEX idx_transacoes_categoria ON transacoes(categoria);
CREATE INDEX idx_transacoes_fraude ON transacoes(fraude);
CREATE INDEX idx_transacoes_data ON transacoes(data_hora);
