# ============================================================
# 06. AUTOCORRELAÇÃO ESPACIAL - MORAN GLOBAL
# FEMINICÍDIOS EM ALAGOAS - 2015 A 2025
# ============================================================

# ------------------------------------------------------------
# 1. CARREGAR PACOTES
# ------------------------------------------------------------

library(dplyr)     # Manipulação dos dados
library(sf)        # Manipulação dos dados espaciais
library(spdep)     # Análise de dependência espacial
library(ggplot2)   # Visualização gráfica


# ------------------------------------------------------------
# 2. CARREGAR A BASE ESPACIAL
# ------------------------------------------------------------

mapa_taxa_al <- readRDS(
  "CVLI/Dados/mapa_taxa_al_2015_2025.rds"
)

# Conferir quantidade de municípios
nrow(mapa_taxa_al)

# Conferir a taxa de feminicídio
summary(mapa_taxa_al$taxa_feminicidio)

# Verificar valores ausentes
sum(is.na(mapa_taxa_al$taxa_feminicidio))

# Verificar valores não finitos
sum(!is.finite(mapa_taxa_al$taxa_feminicidio))

# Conferir a geometria
sum(!st_is_valid(mapa_taxa_al))

# Interromper se a base estiver incompleta
if (
  nrow(mapa_taxa_al) != 102 ||
  any(!is.finite(mapa_taxa_al$taxa_feminicidio)) ||
  any(!st_is_valid(mapa_taxa_al))
) {
  stop("Verifique a base espacial antes de calcular Moran.")
}


# ------------------------------------------------------------
# 3. CONSTRUIR A MATRIZ DE VIZINHANÇA QUEEN
# ------------------------------------------------------------

# Identificar municípios vizinhos
vizinhos_queen <- poly2nb(
  mapa_taxa_al,
  queen = TRUE
)

# Conferir quantidade de municípios
length(vizinhos_queen)

# Resumo das relações de vizinhança
summary(vizinhos_queen)

# Identificar municípios sem vizinhos
which(card(vizinhos_queen) == 0)


# ------------------------------------------------------------
# 4. CONSTRUIR OS PESOS ESPACIAIS
# ------------------------------------------------------------

pesos_queen <- nb2listw(
  vizinhos_queen,
  style = "W",
  zero.policy = TRUE
)

# Conferir os pesos
summary(pesos_queen)


# ------------------------------------------------------------
# 5. ÍNDICE DE MORAN GLOBAL
# ------------------------------------------------------------

moran_global <- moran.test(
  mapa_taxa_al$taxa_feminicidio,
  listw = pesos_queen,
  alternative = "two.sided",
  zero.policy = TRUE
)

# Exibir resultado
print(moran_global)


# ------------------------------------------------------------
# 6. TESTE DE PERMUTAÇÃO DE MORAN
# ------------------------------------------------------------

# Garantir reprodutibilidade
set.seed(123)

# Moran com 999 permutações
moran_permutacao <- moran.mc(
  mapa_taxa_al$taxa_feminicidio,
  listw = pesos_queen,
  nsim = 999,
  alternative = "two.sided",
  zero.policy = TRUE
)

# Exibir resultado
print(moran_permutacao)

# Visualizar distribuição simulada
plot(moran_permutacao)


# ------------------------------------------------------------
# 7. DIAGRAMA DE DISPERSÃO DE MORAN
# ------------------------------------------------------------

moran.plot(
  mapa_taxa_al$taxa_feminicidio,
  listw = pesos_queen,
  zero.policy = TRUE,
  xlab = "Taxa de feminicídio",
  ylab = "Defasagem espacial da taxa",
  main = "Diagrama de Moran - Alagoas (2015 a 2025)"
)


# ------------------------------------------------------------
# 8. SALVAR OS RESULTADOS
# ------------------------------------------------------------

dir.create(
  "CVLI/Resultados",
  recursive = TRUE,
  showWarnings = FALSE
)

saveRDS(
  moran_global,
  "CVLI/Resultados/moran_global.rds"
)

saveRDS(
  moran_permutacao,
  "CVLI/Resultados/moran_permutacao.rds"
)

# Salvar a matriz de vizinhança para o LISA
saveRDS(
  pesos_queen,
  "CVLI/Dados/pesos_queen.rds"
)

saveRDS(
  vizinhos_queen,
  "CVLI/Dados/vizinhos_queen.rds"
)
