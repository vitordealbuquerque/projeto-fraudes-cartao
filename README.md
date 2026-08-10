# Antifraude em Cartão de Crédito — Panorama 2025

Projeto de portfólio para transição de carreira para Análise de Dados. Setor: **antifraude / segurança em meios de pagamento**. Ciclo completo: modelagem SQL, limpeza, análise e dashboard executivo em Power BI.

Documentação completa do projeto (conceitos, dataset, checklist e modelo do dashboard): [`documentos/DOCUMENTACAO_PROJETO.md`](documentos/DOCUMENTACAO_PROJETO.md).

---

## A base

Base sintética (mas calibrada com padrões reais de fraude em cartão de crédito) de uma carteira fictícia de 1.800 clientes com 2.328 cartões ativos entre as bandeiras Visa, Mastercard, Elo e American Express. Em 2025 essa carteira gerou 34.917 transações, cada uma com categoria de estabelecimento, canal de pagamento, UF de origem e marcação de fraude quando aplicável.

Os números a seguir vieram de execução real de SQL contra essa base, não são estimativa: 494 fraudes (1,41% das transações), R$ 5.351.791,19 movimentados no total e R$ 272.839,73 perdidos em fraude — 5,10% de todo o valor transacionado. O ticket médio da transação fraudulenta (R$ 552,31) é 3,7 vezes maior que o da transação legítima (R$ 147,55).

---

## Como o projeto foi montado

A base foi gerada em Python, com distribuições calibradas para reproduzir padrões reais de fraude: risco maior em compras online, em categorias de alto valor de revenda (eletrônicos, joalheria) e em apostas online, risco maior em transações de madrugada e em transações fora do estado de residência do cliente.

A modelagem, limpeza e análise rodaram em PostgreSQL, num schema próprio (`antifraude`). O pipeline usa CTE, window function (`RANK` para ranquear categorias e bandeiras por taxa de fraude, `LAG` para medir a variação mês a mês), `FILTER (WHERE ...)` para as contagens condicionais, `PERCENTILE_CONT` para comparar a distribuição de valor entre fraude e transação legítima, e `BOOL_OR` para marcar clientes que já sofreram fraude. Os blocos de análise estão em `02_sql/04_analises.sql`.

O dashboard final foi montado no Power BI, com modelo semântico próprio, medidas DAX e visuais nativos (cartão, barras, colunas e linha).

---

## Estrutura do repositório

```
projeto-fraudes-cartao/
├── README.md
├── 00_gerar_base.py                        # geração da base sintética em Python
├── 02_sql/
│   ├── 01_criar_tabelas.sql                # DDL + índices + constraints
│   ├── 02_carregar_dados.sql               # COPY dos CSV
│   ├── 03_limpeza.sql                      # checagens + colunas derivadas (faixa_horaria, fora_da_uf)
│   └── 04_analises.sql                     # análises com CTE/RANK/FILTER/PERCENTILE_CONT/LAG
├── 03_dados/
│   ├── clientes.csv                        # 1.800 clientes
│   ├── cartoes.csv                         # 2.328 cartões
│   └── transacoes.csv                      # 34.917 transações de 2025
├── 04_prints/                              # imagens reais do projeto
│   ├── print_dashboard_final.png           # dashboard Power BI completo
│   ├── print_sql_evolucao_mensal.png       # print real do SQL — evolução mensal da taxa de fraude (LAG)
│   └── print_sql_percentis_valor.png       # print real do SQL — distribuição de valor (PERCENTILE_CONT)
└── documentos/
    └── DOCUMENTACAO_PROJETO.md             # documentação completa do projeto (conceitos, dataset, checklist, modelo do dashboard)
```

---

## O que o dashboard mostra

O bloco de topo traz os cinco números que resumem o risco: total de transações, taxa de fraude geral, valor perdido em fraude, percentual do valor total perdido e ticket médio da fraude. O ranking de taxa de fraude por categoria mostra Apostas Online (4,96%), Joalheria (4,72%) e Eletrônicos (4,23%) na ponta mais arriscada, contra Farmácia (0,57%) e Supermercado (0,74%) na ponta mais segura — quase 9x de diferença entre o topo e a base do ranking. O canal Online concentra a maior taxa de fraude (2,78%), quase 4x acima do canal Presencial (0,71%), e transações de madrugada (3,37%) e fora da UF do cliente (2,50%, 1,91x mais risco que dentro da UF) reforçam o mesmo padrão de comportamento fora do usual. A distribuição de valor confirma o achado mais direto do projeto: a mediana da transação fraudulenta (R$ 328,90) é mais de 3x a mediana da transação legítima (R$ 98,39). Um achado que não virou destaque no dashboard, mas vale registrar: nem o score de crédito do cliente (644,0 contra 648,4) nem a bandeira do cartão (variação de só 1,23% a 1,71%) mostraram diferença relevante de risco — o padrão de fraude está mesmo em comportamento (canal, horário, categoria, geografia), não no perfil do titular.

---

## Rodando localmente

Instale PostgreSQL 14+ e um cliente (pgAdmin ou psql). Crie um banco `fraudes_cartao`, rode `02_sql/01_criar_tabelas.sql`, carregue os CSV de `03_dados/` com `02_sql/02_carregar_dados.sql` e rode `02_sql/03_limpeza.sql` seguido de `02_sql/04_analises.sql`. O modelo e as medidas do dashboard estão documentados em `documentos/DOCUMENTACAO_PROJETO.md`.

---

## Autor

**Vitor França** — engcivil.vitorfranca@gmail.com
Em transição para Análise de Dados.
