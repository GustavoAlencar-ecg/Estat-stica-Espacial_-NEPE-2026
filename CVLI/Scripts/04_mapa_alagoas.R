# ============================================================
# 04. DISTRIBUIÇÃO ESPACIAL DOS FEMINICÍDIOS
# ALAGOAS - 2015 A 2025
# ============================================================

# ============================================================
# PACOTES
# ============================================================

library(dplyr)      # Manipulação e organização de dados
library(ggplot2)    # Construção de gráficos e mapas
library(geobr)      # Malhas geográficas oficiais do Brasil
library(sf)         # Manipulação de dados espaciais
library(stringi)    # Padronização de textos e nomes
library(classInt)   # Classificação de valores pelo método Jenks


# ------------------------------------------------------------
# 1. CARREGAR BASES
# ------------------------------------------------------------

# Carregar a base municipal criada no script 02
feminicidio_municipio <- readRDS(
  "CVLI/Dados/feminicidio_municipio.rds"
)

# Carregar a malha dos municípios de Alagoas
al_municipios <- read_municipality(
  code_muni = "AL",
  year = 2022
)

# Conferir a quantidade de municípios
nrow(al_municipios)

# Conferir as variáveis disponíveis
names(al_municipios)


# ------------------------------------------------------------
# 2. PADRONIZAÇÃO DOS NOMES DOS MUNICÍPIOS
# ------------------------------------------------------------

# Padronizar os nomes na base CVLI
feminicidio_municipio <- feminicidio_municipio %>%
  mutate(
    municipio = stri_trans_general(
      toupper(trimws(`CIDADE DO FATO`)),
      "Latin-ASCII"
    )
  )

# Padronizar os nomes na malha geográfica
al_municipios <- al_municipios %>%
  mutate(
    municipio = stri_trans_general(
      toupper(trimws(name_muni)),
      "Latin-ASCII"
    )
  )

# Conferir os nomes padronizados
head(feminicidio_municipio)

head(al_municipios$municipio)


# ------------------------------------------------------------
# 3. CONFERIR CORRESPONDÊNCIA DOS MUNICÍPIOS
# ------------------------------------------------------------

# Identificar municípios da base CVLI que não
# foram encontrados na malha de Alagoas

municipios_nao_encontrados <- feminicidio_municipio %>%
  anti_join(
    st_drop_geometry(al_municipios),
    by = "municipio"
  )

# Conferir possíveis incompatibilidades
print(municipios_nao_encontrados)

# Quantidade de municípios sem correspondência
nrow(municipios_nao_encontrados)


# ------------------------------------------------------------
# 4. CORRIGIR NOMES DOS MUNICÍPIOS
# ------------------------------------------------------------

# Corrigir municípios que possuem apóstrofos
# diferentes entre as duas bases

feminicidio_municipio <- feminicidio_municipio %>%
  mutate(
    municipio = case_when(
      municipio == "OLHO D AGUA DAS FLORES" ~ "OLHO D'AGUA DAS FLORES",
      municipio == "OLHO D AGUA GRANDE" ~ "OLHO D'AGUA GRANDE",
      municipio == "TANQUE D ARCA" ~ "TANQUE D'ARCA",
      TRUE ~ municipio
    )
  )

# Conferir novamente a correspondência
municipios_nao_encontrados <- feminicidio_municipio %>%
  anti_join(
    st_drop_geometry(al_municipios),
    by = "municipio"
  )

print(municipios_nao_encontrados)

# Interromper caso existam municípios não encontrados
if (nrow(municipios_nao_encontrados) > 0) {
  stop("Existem municípios sem correspondência na malha.")
}


# ------------------------------------------------------------
# 5. INTEGRAR FEMINICÍDIOS À MALHA MUNICIPAL
# ------------------------------------------------------------

mapa_feminicidio_al <- al_municipios %>%
  left_join(
    feminicidio_municipio,
    by = "municipio"
  ) %>%
  mutate(
    casos = coalesce(casos, 0L)
  )

# Conferir quantidade de municípios
nrow(mapa_feminicidio_al)

# Conferir total de feminicídios
sum(mapa_feminicidio_al$casos)

# Resumo da distribuição
summary(mapa_feminicidio_al$casos)


# ------------------------------------------------------------
# 6. CLASSIFICAÇÃO DOS CASOS ABSOLUTOS - JENKS
# ------------------------------------------------------------

# Calcular cinco classes pelo método de quebras naturais

classes_casos <- classIntervals(
  mapa_feminicidio_al$casos,
  n = 5,
  style = "jenks"
)

# Conferir os limites encontrados
classes_casos$brks

# Atribuir uma classe a cada município
mapa_feminicidio_al <- mapa_feminicidio_al %>%
  mutate(
    CLASSE_CASOS = findInterval(
      casos,
      vec = classes_casos$brks,
      all.inside = TRUE
    )
  )

# Conferir quantos municípios ficaram em cada classe
table(mapa_feminicidio_al$CLASSE_CASOS)


# ------------------------------------------------------------
# 7. DEFINIR AS CORES E OS INTERVALOS DA LEGENDA
# ------------------------------------------------------------

cores_casos <- c(
  "1" = "#EAF3F8",
  "2" = "#B8D5E5",
  "3" = "#78AFCB",
  "4" = "#367FA8",
  "5" = "#164B70"
)

# Criar legenda a partir dos limites do Jenks

limites <- classes_casos$brks

rotulos_casos <- paste0(
  limites[-length(limites)],
  " a ",
  limites[-1] - 1
)

# Corrigir o limite superior da última classe
rotulos_casos[length(rotulos_casos)] <- paste0(
  limites[length(limites) - 1],
  " a ",
  limites[length(limites)]
)

# Conferir
rotulos_casos


# ------------------------------------------------------------
# 8. MAPA DOS VALORES ABSOLUTOS DE FEMINICÍDIO
# ------------------------------------------------------------

mapa_casos_al <- ggplot(mapa_feminicidio_al) +

  geom_sf(
    aes(fill = factor(CLASSE_CASOS)),
    color = "grey35",
    linewidth = 0.15
  ) +

  scale_fill_manual(
    values = cores_casos,
    name = "Número de feminicídios",
    labels = rotulos_casos,
    drop = FALSE
  ) +

  labs(
    title = "Distribuição de feminicídios nos municípios de Alagoas",
    subtitle = "Número acumulado de casos (2015 a 2025)",
    caption = "Fonte: CVLI, Governo de Alagoas. Elaboração própria."
  ) +

  theme(
    panel.grid = element_blank(),
    axis.title = element_blank(),
    axis.text = element_blank(),
    axis.ticks = element_blank(),

    legend.position = "right",

    legend.title = element_text(size = 15, face = "bold"),
    legend.text = element_text(size = 13),

    plot.title = element_text(size = 19, face = "bold"),
    plot.subtitle = element_text(size = 15),
    plot.caption = element_text(size = 11)
  )

# Exibir o mapa
print(mapa_casos_al)


# ------------------------------------------------------------
# 9. EXPORTAR MAPA
# ------------------------------------------------------------

dir.create(
  "CVLI/Resultados",
  recursive = TRUE,
  showWarnings = FALSE
)

ggsave(
  filename = "CVLI/Resultados/mapa_feminicidios_jenks_2015_2025.png",
  plot = mapa_casos_al,
  width = 10,
  height = 8,
  dpi = 300
)
