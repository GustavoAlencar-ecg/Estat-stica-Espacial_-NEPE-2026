# ============================================================
# EXTRAÇÃO DOS CASOS DE FEMINICÍDIO
# CVLI - ALAGOAS
# Período: 2020 a 2024
# ============================================================

library(httr)
library(jsonlite)
library(dplyr)

# ------------------------------------------------------------
# 1. Acessar a API
# ------------------------------------------------------------

url <- "https://dados.al.gov.br/catalogo/api/3/action/datastore_search"

resposta <- GET(
  url,
  query = list(
    resource_id = "546e1b4f-4cb7-44ac-9dcc-1c33dc213b6c",
    limit = 30000
  )
)

# ------------------------------------------------------------
# 2. Ler a resposta
# ------------------------------------------------------------

dados <- fromJSON(
  content(
    resposta,
    "text",
    encoding = "UTF-8"
  ),
  flatten = TRUE
)

# Conferir se deu certo
dados$success

# ------------------------------------------------------------
# 3. Transformar todos os registros em uma base
# ------------------------------------------------------------

base_cvli <- as.data.frame(
  dados$result$records
)

# Conferir quantidade
nrow(base_cvli)

# Conferir variáveis
names(base_cvli)

# ------------------------------------------------------------
# 4. Selecionar feminicídios de 2020 a 2024
# ------------------------------------------------------------

base_feminicidio <- base_cvli %>%
  filter(
    `SUBJETIVIDADE COMPLEMENTAR` == "Feminicídio"
  ) %>%
  mutate(
    data_fato = as.Date(
      substr(`DATA DO FATO`, 1, 10)
    )
  ) %>%
  filter(
    data_fato >= as.Date("2015-01-01"),
    data_fato <= as.Date("2025-12-31")
  )

# ------------------------------------------------------------
# 5. Conferir resultado
# ------------------------------------------------------------

nrow(base_feminicidio)

View(base_feminicidio)

names(base_feminicidio)

str(base_feminicidio) # exibir a estrutura interna de base_feminicidio


# ------------------------------------------------------------
# 6. ORGANIZAR A BASE PARA A ANÁLISE
# ------------------------------------------------------------

base_feminicidio <- base_feminicidio %>%
  mutate(
    ano = as.integer(
      format(data_fato, "%Y")
    ),
    idade = as.numeric(
      `IDADE DA VITIMA`
    )
  ) %>%
  select(
    ano,
    data_fato,
    `HORA DO FATO`,
    `CIDADE DO FATO`,
    `BAIRRO DO FATO`,
    `SEXO DA VITIMA`,
    `COR/RACA DA VITIMA`,
    idade,
    `INSTRUMENTO UTILIZADO`,
    `LOCAL DO FATO`,
    `OCUPACAO VITIMA`,
    `ESCOLARIDADE VITIMA`
  )

# ------------------------------------------------------------
# 7. CONFERIR A BASE ORGANIZADA
# ------------------------------------------------------------

names(base_feminicidio)

nrow(base_feminicidio)

table(base_feminicidio$ano)

View(base_feminicidio)


# ------------------------------------------------------------
# 8. CONFERIR A VARIÁVEL IDADE
# ------------------------------------------------------------

sum(is.na(base_feminicidio$idade))

summary(base_feminicidio$idade)


# ------------------------------------------------------------
# 9. DISTRIBUIÇÃO DOS FEMINICÍDIOS POR MUNICÍPIO
# ------------------------------------------------------------

feminicidio_municipio <- base_feminicidio %>%
  count(
    `CIDADE DO FATO`,
    name = "casos"
  ) %>%
  arrange(
    desc(casos)
  )

# Visualizar a base municipal

View(feminicidio_municipio)

# Conferir o total de casos

sum(feminicidio_municipio$casos)

# Conferir os municípios com mais casos

head(
  feminicidio_municipio,
  20
)

#https://github.com/GustavoAlencar-ecg/Estat-stica-Espacial_-NEPE-2026.git
