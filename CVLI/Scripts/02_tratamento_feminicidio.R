# ============================================================
# 02. TRATAMENTO DOS FEMINICÍDIOS
# ALAGOAS - 2015 A 2025
# ============================================================

library(dplyr)

# ------------------------------------------------------------
# 1. DISTRIBUIÇÃO POR MUNICÍPIO
# ------------------------------------------------------------

feminicidio_municipio <- base_feminicidio %>%
  count(
    `CIDADE DO FATO`,
    name = "casos"
  ) %>%
  arrange(desc(casos))


# ------------------------------------------------------------
# 2. CONFERÊNCIAS
# ------------------------------------------------------------

# Total de feminicídios
nrow(base_feminicidio)

# Total de casos distribuídos
sum(feminicidio_municipio$casos)

# Municípios com registros
nrow(feminicidio_municipio)

# Distribuição anual
table(base_feminicidio$ano)

# Idades ausentes
sum(is.na(base_feminicidio$idade))

# Municípios sem identificação
sum(is.na(base_feminicidio$`CIDADE DO FATO`))

# Visualizar
View(feminicidio_municipio)


# ------------------------------------------------------------
# 3. SALVAR AS BASES TRATADAS
# ------------------------------------------------------------

dir.create("CVLI/Dados", recursive = TRUE, showWarnings = FALSE)

saveRDS(
  base_feminicidio,
  "CVLI/Dados/base_feminicidio_tratada.rds"
)

saveRDS(
  feminicidio_municipio,
  "CVLI/Dados/feminicidio_municipio.rds"
)
