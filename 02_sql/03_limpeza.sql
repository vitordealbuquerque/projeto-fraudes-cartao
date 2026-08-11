-- Checagens de qualidade + colunas derivadas

SET search_path TO antifraude;

-- 1) duplicidade de chave
SELECT transacao_id, COUNT(*)
FROM transacoes
GROUP BY transacao_id
HAVING COUNT(*) > 1;

-- 2) cartao orfao (sem cliente) ou transacao orfa (sem cartao) -- esperado: 0 linhas nas duas
SELECT ca.cartao_id
FROM cartoes ca
LEFT JOIN clientes cl ON cl.cliente_id = ca.cliente_id
WHERE cl.cliente_id IS NULL;

SELECT t.transacao_id
FROM transacoes t
LEFT JOIN cartoes ca ON ca.cartao_id = t.cartao_id
WHERE ca.cartao_id IS NULL;

-- 3) consistencia fraude x tipo_fraude (toda fraude tem que ter tipo, toda nao-fraude nao pode ter)
SELECT COUNT(*) AS inconsistentes
FROM transacoes
WHERE (fraude = TRUE AND tipo_fraude IS NULL)
   OR (fraude = FALSE AND tipo_fraude IS NOT NULL);

-- 4) valores fora de faixa (esperado: 0 linhas)
SELECT COUNT(*) AS valor_invalido FROM transacoes WHERE valor <= 0;

-- 5) colunas derivadas usadas nas analises

ALTER TABLE transacoes ADD COLUMN IF NOT EXISTS faixa_horaria VARCHAR(20);
UPDATE transacoes
SET faixa_horaria = CASE
    WHEN EXTRACT(HOUR FROM data_hora) BETWEEN 0 AND 5 THEN 'Madrugada'
    WHEN EXTRACT(HOUR FROM data_hora) BETWEEN 6 AND 11 THEN 'Manha'
    WHEN EXTRACT(HOUR FROM data_hora) BETWEEN 12 AND 17 THEN 'Tarde'
    ELSE 'Noite'
END
WHERE faixa_horaria IS NULL;

ALTER TABLE transacoes ADD COLUMN IF NOT EXISTS fora_da_uf BOOLEAN;
UPDATE transacoes t
SET fora_da_uf = (t.uf_transacao <> cl.uf)
FROM cartoes ca
JOIN clientes cl ON cl.cliente_id = ca.cliente_id
WHERE ca.cartao_id = t.cartao_id
  AND t.fora_da_uf IS NULL;

CREATE INDEX IF NOT EXISTS idx_transacoes_faixa_horaria ON transacoes(faixa_horaria);
CREATE INDEX IF NOT EXISTS idx_transacoes_fora_uf ON transacoes(fora_da_uf);
