# ============================================================
# 05. MAPA DA TAXA DE FEMINICÍDIO
# ALAGOAS - 2015 A 2025
# ============================================================

# ------------------------------------------------------------
# 1. PACOTES
# ------------------------------------------------------------

library(dplyr)
library(ggplot2)
library(geobr)
library(sf)
library(stringi)
library(classInt)


# ------------------------------------------------------------
# 2. CARREGAR OS FEMINICÍDIOS
# ------------------------------------------------------------

feminicidio_municipio <- readRDS(
  "CVLI/Dados/feminicidio_municipio.rds"
)

# Conferir o total de casos
sum(feminicidio_municipio$casos)


# ------------------------------------------------------------
# 3. IMPORTAR A POPULAÇÃO FEMININA DO CENSO 2022
# ------------------------------------------------------------

populacao_bruta <- read.csv(
  "CVLI/Dados/População Feminina.xlsx - População residente (Pessoas).csv",
  skip = 6,
  header = FALSE,
  fileEncoding = "UTF-8",
  stringsAsFactors = FALSE
)

# Selecionar somente os 102 municípios de Alagoas
# V1 = município; V3 = população feminina total

populacao_feminina_al <- populacao_bruta %>%
  filter(grepl("\\(AL\\)$", V1)) %>%
  transmute(
    municipio_original = sub("\\s*\\(AL\\)$", "", V1),
    populacao_feminina = as.numeric(V3)
  )

# Conferências
nrow(populacao_feminina_al)
sum(populacao_feminina_al$populacao_feminina)


# ------------------------------------------------------------
# 4. PADRONIZAR NOMES DOS MUNICÍPIOS
# ------------------------------------------------------------

# Função para remover acentos, diferenças de
# maiúsculas, apóstrofos e espaços extras

padronizar_municipio <- function(x) {
  x <- stri_trans_general(toupper(trimws(x)), "Latin-ASCII")
  x <- gsub("[^A-Z0-9]+", " ", x)
  trimws(x)
}

# Padronizar a base de feminicídios
feminicidio_municipio <- feminicidio_municipio %>%
  mutate(
    municipio = padronizar_municipio(`CIDADE DO FATO`)
  )

# Padronizar o Censo 2022
populacao_feminina_al <- populacao_feminina_al %>%
  mutate(
    municipio = padronizar_municipio(municipio_original)
  )

# Conferir correspondência
anti_join(
  feminicidio_municipio,
  populacao_feminina_al,
  by = "municipio"
)


# ------------------------------------------------------------
# 5. CARREGAR A MALHA MUNICIPAL DE ALAGOAS
# ------------------------------------------------------------

al_municipios <- read_municipality(
  code_muni = "AL",
  year = 2022
) %>%
  mutate(
    municipio = padronizar_municipio(name_muni)
  )


# ------------------------------------------------------------
# 6. INTEGRAR AS TRÊS BASES
# ------------------------------------------------------------

mapa_taxa_al <- al_municipios %>%
  left_join(
    feminicidio_municipio %>% select(municipio, casos),
    by = "municipio"
  ) %>%
  left_join(
    populacao_feminina_al %>%
      select(municipio, populacao_feminina),
    by = "municipio"
  ) %>%
  mutate(
    casos = coalesce(casos, 0L)
  )

# Conferir integridade dos dados
nrow(mapa_taxa_al)

sum(mapa_taxa_al$casos)

sum(is.na(mapa_taxa_al$populacao_feminina))

# Interromper caso falte alguma população
if (
  nrow(mapa_taxa_al) != 102 ||
  anyNA(mapa_taxa_al$populacao_feminina) ||
  any(mapa_taxa_al$populacao_feminina <= 0) ||
  sum(mapa_taxa_al$casos) != sum(feminicidio_municipio$casos)
) {
  stop("Verifique a integração das bases municipais.")
}


# ------------------------------------------------------------
# 7. CALCULAR A TAXA DE FEMINICÍDIO
# ------------------------------------------------------------

# Número de anos analisados
n_anos <- 11

mapa_taxa_al <- mapa_taxa_al %>%
  mutate(
    taxa_feminicidio = (
      casos / (populacao_feminina * n_anos)
    ) * 100000
  )

# Estatísticas da taxa
summary(mapa_taxa_al$taxa_feminicidio)

# Municípios com maiores taxas
mapa_taxa_al %>%
  st_drop_geometry() %>%
  arrange(desc(taxa_feminicidio)) %>%
  select(
    name_muni,
    casos,
    populacao_feminina,
    taxa_feminicidio
  ) %>%
  head(10)


# ------------------------------------------------------------
# 8. CLASSIFICAÇÃO DA TAXA PELO MÉTODO JENKS
# ------------------------------------------------------------

classes_taxa <- classIntervals(
  mapa_taxa_al$taxa_feminicidio,
  n = 5,
  style = "jenks"
)

# Conferir limites encontrados
classes_taxa$brks

# Criar as classes
mapa_taxa_al <- mapa_taxa_al %>%
  mutate(
    CLASSE_TAXA = findInterval(
      taxa_feminicidio,
      vec = classes_taxa$brks,
      all.inside = TRUE
    )
  )

# Quantidade de municípios por classe
table(mapa_taxa_al$CLASSE_TAXA)


# ------------------------------------------------------------
# 9. DEFINIR CORES E LEGENDA
# ------------------------------------------------------------

cores_taxa <- c(
  "1" = "#EAF3F8",
  "2" = "#B8D5E5",
  "3" = "#78AFCB",
  "4" = "#367FA8",
  "5" = "#164B70"
)

# Gerar rótulos com os limites do Jenks
limites <- classes_taxa$brks

rotulos_taxa <- paste0(
  formatC(
    head(limites, -1),
    format = "f", digits = 2,
    decimal.mark = ","
  ),
  " a ",
  formatC(
    tail(limites, -1),
    format = "f", digits = 2,
    decimal.mark = ","
  )
)


# ------------------------------------------------------------
# 10. CONSTRUIR O MAPA DA TAXA
# ------------------------------------------------------------

mapa_taxa <- ggplot(mapa_taxa_al) +

  geom_sf(
    aes(fill = factor(CLASSE_TAXA)),
    color = "grey35",
    linewidth = 0.15
  ) +

  scale_fill_manual(
    values = cores_taxa,
    breaks = as.character(1:5),
    labels = rotulos_taxa,
    name = "Taxa por 100 mil mulheres",
    drop = FALSE
  ) +

  labs(
    title = "Taxa de feminicídio nos municípios de Alagoas",
    subtitle = paste(
      "Média anual de 2015 a 2025 |",
      "População feminina do Censo 2022"
    ),
    caption = paste(
      "Fontes: CVLI e IBGE, Censo 2022.",
      "Elaboração própria."
    )
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

# Visualizar mapa
print(mapa_taxa)


# ------------------------------------------------------------
# 11. SALVAR BASES E MAPA
# ------------------------------------------------------------

dir.create(
  "CVLI/Resultados",
  recursive = TRUE,
  showWarnings = FALSE
)

# Salvar população feminina tratada
write.csv(
  populacao_feminina_al,
  "CVLI/Dados/populacao_feminina_censo_2022.csv",
  row.names = FALSE
)

# Salvar base espacial para Moran e LISA
saveRDS(
  mapa_taxa_al,
  "CVLI/Dados/mapa_taxa_al_2015_2025.rds"
)

# Salvar mapa
ggsave(
  "CVLI/Resultados/mapa_taxa_feminicidio_2015_2025.png",
  plot = mapa_taxa,
  width = 10,
  height = 8,
  dpi = 300
)
