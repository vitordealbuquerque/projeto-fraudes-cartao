"""
Gera a base sintética do projeto de antifraude em cartão de crédito.
Roda uma vez, exporta os 3 CSVs pra 03_dados/. Sem dado real de pessoa ou banco nenhum.
"""

import random
from datetime import datetime, timedelta

import numpy as np
import pandas as pd

random.seed(7)
np.random.seed(7)

# ---------------------------------------------------------------------------
# 1) CLIENTES
# ---------------------------------------------------------------------------

N_CLIENTES = 1800

nomes_proprios = [
    "Ana", "Bruno", "Camila", "Diego", "Elaine", "Fabio", "Gabriela", "Heitor",
    "Isabela", "Joao", "Karina", "Leandro", "Marcia", "Nelson", "Otavio",
    "Patricia", "Rodrigo", "Sabrina", "Thiago", "Vanessa", "Wagner", "Yasmin",
    "Cesar", "Debora", "Eduardo", "Flavia", "Gustavo", "Helena", "Igor", "Julia",
]
sobrenomes = [
    "Almeida", "Barros", "Cardoso", "Dias", "Esteves", "Ferraz", "Gouveia",
    "Henriques", "Igreja", "Junqueira", "Lacerda", "Machado", "Nogueira",
    "Oliveira", "Pinheiro", "Queiroz", "Ribas", "Salgado", "Teixeira", "Vieira",
]

cidades_uf = [
    ("Curitiba", "PR"), ("Londrina", "PR"), ("Maringa", "PR"),
    ("Florianopolis", "SC"), ("Joinville", "SC"), ("Blumenau", "SC"),
    ("Porto Alegre", "RS"), ("Caxias do Sul", "RS"), ("Pelotas", "RS"),
    ("Sao Paulo", "SP"), ("Campinas", "SP"), ("Sorocaba", "SP"),
    ("Belo Horizonte", "MG"), ("Uberlandia", "MG"),
    ("Rio de Janeiro", "RJ"), ("Niteroi", "RJ"),
    ("Salvador", "BA"), ("Recife", "PE"), ("Fortaleza", "CE"), ("Goiania", "GO"),
]

# peso proporcional aproximado de carteira de clientes por praca
pesos_cidade = [7, 3, 3, 5, 3, 3, 6, 3, 2, 12, 5, 3, 7, 3, 9, 3, 5, 5, 5, 4]
pesos_cidade = np.array(pesos_cidade) / sum(pesos_cidade)

clientes = []
for cliente_id in range(1, N_CLIENTES + 1):
    nome = f"{random.choice(nomes_proprios)} {random.choice(sobrenomes)}"
    idade = int(np.clip(np.random.normal(38, 12), 18, 78))
    cidade, uf = cidades_uf[np.random.choice(len(cidades_uf), p=pesos_cidade)]
    score_credito = int(np.clip(np.random.normal(650, 110), 300, 950))
    dias_de_conta = random.randint(30, 365 * 6)
    data_cadastro = (datetime(2025, 12, 31) - timedelta(days=dias_de_conta)).date()
    clientes.append(
        {
            "cliente_id": cliente_id,
            "nome_completo": nome,
            "idade": idade,
            "cidade": cidade,
            "uf": uf,
            "score_credito": score_credito,
            "data_cadastro": data_cadastro,
        }
    )

df_clientes = pd.DataFrame(clientes)

# ---------------------------------------------------------------------------
# 2) CARTOES (1 a 2 cartoes por cliente)
# ---------------------------------------------------------------------------

bandeiras = ["Visa", "Mastercard", "Elo", "American Express"]
peso_bandeiras = [0.42, 0.38, 0.15, 0.05]
tipos_cartao = ["Credito", "Multiplo"]

cartoes = []
cartao_id = 1
for cliente_id in df_clientes["cliente_id"]:
    n_cartoes = np.random.choice([1, 2], p=[0.72, 0.28])
    for _ in range(n_cartoes):
        bandeira = np.random.choice(bandeiras, p=peso_bandeiras)
        tipo_cartao = np.random.choice(tipos_cartao, p=[0.62, 0.38])
        limite = round(float(np.clip(np.random.lognormal(mean=7.6, sigma=0.65), 800, 45000)), 2)
        dias_emissao = random.randint(15, 365 * 5)
        data_emissao = (datetime(2025, 12, 31) - timedelta(days=dias_emissao)).date()
        cartoes.append(
            {
                "cartao_id": cartao_id,
                "cliente_id": cliente_id,
                "bandeira": bandeira,
                "tipo_cartao": tipo_cartao,
                "limite_credito": limite,
                "data_emissao": data_emissao,
            }
        )
        cartao_id += 1

df_cartoes = pd.DataFrame(cartoes)

# ---------------------------------------------------------------------------
# 3) TRANSACOES (ano de referencia: 2025)
# ---------------------------------------------------------------------------

categorias = [
    "Supermercado", "Combustivel", "Restaurantes", "Farmacia", "Vestuario",
    "Eletronicos", "Streaming e Assinaturas", "Apostas Online", "Joalheria",
    "Passagens e Viagem",
]
# peso normal de volume de transacao por categoria (nao tem relacao com risco de fraude)
peso_categoria = [0.22, 0.15, 0.16, 0.10, 0.09, 0.08, 0.08, 0.03, 0.02, 0.07]

canais = ["Presencial (maquininha)", "Online", "Aproximacao (contactless)"]
peso_canal = [0.46, 0.34, 0.20]

# risco relativo de fraude por categoria (multiplicador sobre a taxa base)
risco_categoria = {
    "Supermercado": 0.5,
    "Combustivel": 0.5,
    "Restaurantes": 0.6,
    "Farmacia": 0.4,
    "Vestuario": 0.9,
    "Eletronicos": 2.6,
    "Streaming e Assinaturas": 0.8,
    "Apostas Online": 3.4,
    "Joalheria": 2.9,
    "Passagens e Viagem": 1.3,
}
risco_canal = {"Presencial (maquininha)": 0.5, "Online": 2.4, "Aproximacao (contactless)": 0.7}

tipos_fraude = ["Clonagem", "Phishing", "Cartao Perdido ou Roubado", "Conta Invadida"]
peso_tipo_fraude = [0.30, 0.33, 0.17, 0.20]

TAXA_BASE_FRAUDE = 0.011  # 1,1% base, ajustada pelos multiplicadores acima

def _distribuicao_horaria():
    # mais movimento de dia, cauda mais fina de madrugada
    pesos = np.array([
        1.2, 0.8, 0.5, 0.4, 0.4, 0.6,   # 0h-5h
        1.5, 2.8, 4.2, 5.0, 5.2, 5.6,   # 6h-11h
        6.0, 5.8, 5.4, 5.6, 5.8, 6.2,   # 12h-17h
        7.0, 7.4, 6.8, 5.2, 3.4, 2.0,   # 18h-23h
    ])
    return pesos / pesos.sum()


PROB_HORARIA = _distribuicao_horaria()

inicio_ano = datetime(2025, 1, 1)
cliente_para_cartoes = df_cartoes.groupby("cliente_id")["cartao_id"].apply(list).to_dict()
cliente_uf = df_clientes.set_index("cliente_id")["uf"].to_dict()

registros = []
transacao_id = 1
for cliente_id, lista_cartoes in cliente_para_cartoes.items():
    uf_casa = cliente_uf[cliente_id]
    for cartao_id_atual in lista_cartoes:
        n_transacoes = int(np.clip(np.random.poisson(15), 3, 60))
        for _ in range(n_transacoes):
            dia_do_ano = random.randint(0, 364)
            hora = np.random.choice(range(24), p=PROB_HORARIA)
            minuto = random.randint(0, 59)
            data_hora = inicio_ano + timedelta(days=dia_do_ano, hours=int(hora), minutes=minuto)

            categoria = np.random.choice(categorias, p=peso_categoria)
            canal = np.random.choice(canais, p=peso_canal)

            # transacao fora da UF de casa (viagem, compra online de outro estado etc.)
            fora_da_uf = np.random.random() < 0.09
            uf_transacao = uf_casa
            if fora_da_uf:
                outras_ufs = [c[1] for c in cidades_uf if c[1] != uf_casa]
                uf_transacao = random.choice(outras_ufs)

            valor = round(float(np.clip(np.random.lognormal(mean=4.6, sigma=0.9), 15, 9000)), 2)

            risco = TAXA_BASE_FRAUDE * risco_categoria[categoria] * risco_canal[canal]
            if fora_da_uf:
                risco *= 2.1
            if hora in (0, 1, 2, 3, 4):
                risco *= 2.3
            risco = min(risco, 0.65)

            fraude = np.random.random() < risco
            if fraude:
                # fraude tende a ter ticket mais alto
                valor = round(valor * np.random.uniform(2.0, 5.5), 2)
                tipo_fraude = np.random.choice(tipos_fraude, p=peso_tipo_fraude)
            else:
                tipo_fraude = None

            registros.append(
                {
                    "transacao_id": transacao_id,
                    "cartao_id": cartao_id_atual,
                    "data_hora": data_hora,
                    "valor": valor,
                    "categoria": categoria,
                    "canal": canal,
                    "uf_transacao": uf_transacao,
                    "fraude": fraude,
                    "tipo_fraude": tipo_fraude,
                }
            )
            transacao_id += 1

df_transacoes = pd.DataFrame(registros)

# ---------------------------------------------------------------------------
# Exportacao
# ---------------------------------------------------------------------------

df_clientes["idade"] = df_clientes["idade"].astype("Int64")
df_clientes["score_credito"] = df_clientes["score_credito"].astype("Int64")

df_transacoes["fraude"] = df_transacoes["fraude"].map({True: "t", False: "f"})

df_clientes.to_csv("03_dados/clientes.csv", sep=";", index=False)
df_cartoes.to_csv("03_dados/cartoes.csv", sep=";", index=False)
df_transacoes.to_csv("03_dados/transacoes.csv", sep=";", index=False)

print("clientes:", len(df_clientes))
print("cartoes:", len(df_cartoes))
print("transacoes:", len(df_transacoes))
print("fraudes:", (df_transacoes["fraude"] == "t").sum())
print("taxa de fraude: {:.2%}".format((df_transacoes["fraude"] == "t").mean()))
