-- Carga dos CSVs (delimitador ";")

SET search_path TO antifraude;

\copy clientes FROM '03_dados/clientes.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';');
\copy cartoes FROM '03_dados/cartoes.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';');
\copy transacoes FROM '03_dados/transacoes.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';');

-- checagem rapida de volumetria
SELECT 'clientes' AS tabela, COUNT(*) AS linhas FROM clientes
UNION ALL
SELECT 'cartoes', COUNT(*) FROM cartoes
UNION ALL
SELECT 'transacoes', COUNT(*) FROM transacoes;
