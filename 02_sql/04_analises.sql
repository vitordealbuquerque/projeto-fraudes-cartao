-- Blocos de analise - antifraude em cartao de credito
-- Ano de referencia: 2025

SET search_path TO antifraude;

-- ===========================================================================
-- KPI 1 - Panorama geral
-- ===========================================================================
SELECT
    COUNT(*)                                            AS total_transacoes,
    COUNT(*) FILTER (WHERE fraude)                      AS total_fraudes,
    ROUND(100.0 * COUNT(*) FILTER (WHERE fraude) / COUNT(*), 2)   AS taxa_fraude_pct,
    ROUND(SUM(valor), 2)                                AS valor_total_transacionado,
    ROUND(SUM(valor) FILTER (WHERE fraude), 2)          AS valor_total_fraude,
    ROUND(100.0 * SUM(valor) FILTER (WHERE fraude) / SUM(valor), 2) AS pct_valor_perdido,
    ROUND(AVG(valor) FILTER (WHERE NOT fraude), 2)      AS ticket_medio_legitimo,
    ROUND(AVG(valor) FILTER (WHERE fraude), 2)          AS ticket_medio_fraude
FROM transacoes;

-- ===========================================================================
-- Analise 1 - Taxa de fraude por categoria de estabelecimento (RANK)
-- ===========================================================================
WITH por_categoria AS (
    SELECT
        categoria,
        COUNT(*)                                     AS total_transacoes,
        COUNT(*) FILTER (WHERE fraude)               AS fraudes,
        ROUND(100.0 * COUNT(*) FILTER (WHERE fraude) / COUNT(*), 2) AS taxa_fraude_pct
    FROM transacoes
    GROUP BY categoria
)
SELECT
    categoria,
    total_transacoes,
    fraudes,
    taxa_fraude_pct,
    RANK() OVER (ORDER BY taxa_fraude_pct DESC) AS ranking_risco
FROM por_categoria
ORDER BY ranking_risco;

-- ===========================================================================
-- Analise 2 - Taxa de fraude por canal
-- ===========================================================================
SELECT
    canal,
    COUNT(*)                                       AS total_transacoes,
    COUNT(*) FILTER (WHERE fraude)                 AS fraudes,
    ROUND(100.0 * COUNT(*) FILTER (WHERE fraude) / COUNT(*), 2) AS taxa_fraude_pct
FROM transacoes
GROUP BY canal
ORDER BY taxa_fraude_pct DESC;

-- ===========================================================================
-- Analise 3 - Taxa de fraude por faixa horaria
-- ===========================================================================
SELECT
    faixa_horaria,
    COUNT(*)                                       AS total_transacoes,
    COUNT(*) FILTER (WHERE fraude)                 AS fraudes,
    ROUND(100.0 * COUNT(*) FILTER (WHERE fraude) / COUNT(*), 2) AS taxa_fraude_pct
FROM transacoes
GROUP BY faixa_horaria
ORDER BY taxa_fraude_pct DESC;

-- ===========================================================================
-- Analise 4 - Transacao fora da UF do cliente x taxa de fraude
-- ===========================================================================
WITH risco_uf AS (
    SELECT
        fora_da_uf,
        COUNT(*)                                     AS total_transacoes,
        COUNT(*) FILTER (WHERE fraude)               AS fraudes,
        ROUND(100.0 * COUNT(*) FILTER (WHERE fraude) / COUNT(*), 2) AS taxa_fraude_pct
    FROM transacoes
    GROUP BY fora_da_uf
)
SELECT
    *,
    ROUND(taxa_fraude_pct / MIN(taxa_fraude_pct) OVER (), 2) AS multiplicador_risco
FROM risco_uf
ORDER BY fora_da_uf;

-- ===========================================================================
-- Analise 5 - Distribuicao do valor da transacao: fraude x legitima (PERCENTILE_CONT)
-- ===========================================================================
SELECT
    fraude,
    COUNT(*) AS n,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY valor)::numeric, 2) AS p25,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY valor)::numeric, 2) AS mediana,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY valor)::numeric, 2) AS p75
FROM transacoes
GROUP BY fraude
ORDER BY fraude;

-- ===========================================================================
-- Analise 6 - Tipo de fraude mais comum (entre as transacoes fraudulentas)
-- ===========================================================================
SELECT
    tipo_fraude,
    COUNT(*) AS ocorrencias,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_do_total_fraude
FROM transacoes
WHERE fraude
GROUP BY tipo_fraude
ORDER BY ocorrencias DESC;

-- ===========================================================================
-- Analise 7 - Score de credito: cliente que ja sofreu fraude x cliente que nunca sofreu
-- ===========================================================================
WITH cliente_fraude AS (
    SELECT
        cl.cliente_id,
        cl.score_credito,
        BOOL_OR(t.fraude) AS ja_sofreu_fraude
    FROM clientes cl
    JOIN cartoes ca ON ca.cliente_id = cl.cliente_id
    JOIN transacoes t ON t.cartao_id = ca.cartao_id
    GROUP BY cl.cliente_id, cl.score_credito
)
SELECT
    ja_sofreu_fraude,
    COUNT(*)                          AS clientes,
    ROUND(AVG(score_credito), 1)      AS score_credito_medio
FROM cliente_fraude
GROUP BY ja_sofreu_fraude
ORDER BY ja_sofreu_fraude;

-- ===========================================================================
-- Analise 8 - Taxa de fraude por bandeira do cartao (RANK)
-- ===========================================================================
WITH por_bandeira AS (
    SELECT
        ca.bandeira,
        COUNT(*)                                     AS total_transacoes,
        COUNT(*) FILTER (WHERE t.fraude)             AS fraudes,
        ROUND(100.0 * COUNT(*) FILTER (WHERE t.fraude) / COUNT(*), 2) AS taxa_fraude_pct
    FROM transacoes t
    JOIN cartoes ca ON ca.cartao_id = t.cartao_id
    GROUP BY ca.bandeira
)
SELECT
    bandeira,
    total_transacoes,
    fraudes,
    taxa_fraude_pct,
    RANK() OVER (ORDER BY taxa_fraude_pct DESC) AS ranking_risco
FROM por_bandeira
ORDER BY ranking_risco;

-- ===========================================================================
-- Analise 9 (extra) - Evolucao mensal da taxa de fraude, com variacao mes a mes (LAG)
-- ===========================================================================
WITH por_mes AS (
    SELECT
        DATE_TRUNC('month', data_hora)::date          AS mes,
        COUNT(*)                                       AS total_transacoes,
        COUNT(*) FILTER (WHERE fraude)                 AS fraudes,
        ROUND(100.0 * COUNT(*) FILTER (WHERE fraude) / COUNT(*), 2) AS taxa_fraude_pct
    FROM transacoes
    GROUP BY 1
)
SELECT
    mes,
    total_transacoes,
    fraudes,
    taxa_fraude_pct,
    ROUND(taxa_fraude_pct - LAG(taxa_fraude_pct) OVER (ORDER BY mes), 2) AS variacao_pp_vs_mes_anterior
FROM por_mes
ORDER BY mes;
