# ============================================================
# PET ECONOMIA — VIOLÊNCIA CONTRA A MULHER EM ALAGOAS
# Distribuição espacial das vítimas de feminicídio
# Período: janeiro de 2020 a dezembro de 2024
# Fonte: SINESP VDE
# ============================================================


# 1. INSTALAR E CARREGAR OS PACOTES
# Execute install.packages() somente se algum pacote ainda
# não estiver instalado no computador.

install.packages("BrazilCrime")
install.packages("dplyr")
install.packages("ggplot2")
install.packages("sf")
install.packages("geobr")
install.packages("colorspace")



library(BrazilCrime)
library(dplyr)
library(ggplot2)
library(sf)
library(geobr)
library(colorspace)

# 2. DEFINIR A PASTA DO PROJETO

pasta_saida <- "C:/Users/gusta/OneDrive/Pictures/Documentos/NEPE/NEPE"

dir.create(
  pasta_saida,
  recursive = TRUE,
  showWarnings = FALSE
)

getwd()

# 3. OBTER OS DADOS DO SINESP VDE
# A consulta inclui 2020 a 2025, mas a análise principal
# utilizará somente os anos completos de 2020 a 2024.
# O download pode levar alguns minutos.

dados_al <- get_sinesp_vde_data(
  state = "AL",
  city = "all",
  year = 2020:2025,
  category = "vitimas",
  typology = c(
    "Feminicídio",
    "Tentativa de feminicídio",
    "Estupro"
  ),
  granularity = "month"
)


# 4. PREPARAR OS DADOS DE POPULAÇÃO
# Este projeto utiliza a população municipal do Censo 2022.
#
# Na primeira execução, populacao_al precisa estar carregado
# no ambiente do R. O objeto deve conter as colunas:
# municipio e populacao.
#
# Se já estiver carregado, o código abaixo salva uma cópia
# local para permitir seu reaproveitamento nas próximas
# execuções.

arquivo_populacao <- file.path(
  pasta_saida,
  "populacao_al_censo2022.rds"
)

if (exists("populacao_al")) {

  saveRDS(
    populacao_al,
    arquivo_populacao
  )

} else if (file.exists(arquivo_populacao)) {

  populacao_al <- readRDS(
    arquivo_populacao
  )

} else {

  stop(
    paste(
      "O objeto populacao_al não está carregado.",
      "Carregue a tabela municipal de população do Censo 2022",
      "com as colunas municipio e populacao e execute novamente."
    )
  )
}


# Padronizar os nomes dos municípios

populacao_al <- populacao_al %>%
  mutate(
    municipio = toupper(trimws(municipio))
  )


# 5. SELECIONAR OS FEMINICÍDIOS DE 2020 A 2024
# O período corresponde a cinco anos civis completos.

feminicidio_al <- dados_al %>%
  filter(
    evento == "Feminicídio",
    ano >= 2020,
    ano <= 2024,
    municipio != "NÃO INFORMADO"
  ) %>%
  group_by(municipio) %>%
  summarise(
    casos = sum(total_vitima, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    municipio = toupper(trimws(municipio))
  )


# 6. INTEGRAR OS DADOS DE VÍTIMAS E POPULAÇÃO
# A população é a base da junção para manter os 102 municípios,
# inclusive aqueles sem vítimas registradas no período.

feminicidio_alpop <- populacao_al %>%
  left_join(
    feminicidio_al,
    by = "municipio"
  ) %>%
  mutate(
    casos = coalesce(casos, 0),
    taxa = (casos / populacao) * 100000
  )


# 7. CONFERIR OS RESULTADOS DA ANÁLISE

# Total de municípios
nrow(feminicidio_alpop)

# Total de vítimas no período
sum(feminicidio_alpop$casos, na.rm = TRUE)

# Conferir os municípios com mais vítimas
feminicidio_alpop %>%
  arrange(desc(casos)) %>%
  select(municipio, casos) %>%
  print(n = 20)

# Conferir a distribuição dos municípios por número de vítimas
feminicidio_alpop %>%
  count(casos, name = "municipios") %>%
  arrange(casos)


# 8. IMPORTAR A MALHA MUNICIPAL DE ALAGOAS
# Malha municipal do IBGE disponibilizada pelo pacote geobr.
# Sistema de referência: SIRGAS 2000 (EPSG:4674).

al_municipios <- read_municipality(
  code_muni = "AL",
  year = 2022,
  simplified = TRUE
)


# 9. ASSOCIAR OS DADOS À MALHA MUNICIPAL

mapa_al <- al_municipios %>%
  mutate(
    municipio = toupper(trimws(name_muni))
  ) %>%
  left_join(
    feminicidio_alpop,
    by = "municipio"
  )


# Conferir se todos os municípios foram associados

sum(is.na(mapa_al$casos))
nrow(mapa_al)

# Municípios sem casos registrados recebem valor zero
mapa_al <- mapa_al %>%
  mutate(
    casos = coalesce(casos, 0)
  )


# 10. CONSTRUIR AS CLASSES CARTOGRÁFICAS
# Cinco classes, com os municípios sem casos separados.
# Os intervalos foram definidos a partir da distribuição
# observada dos dados.

mapa_al <- mapa_al %>%
  mutate(
    faixa_feminicidio = case_when(
      casos == 0 ~ "0 - Nenhum caso",
      casos >= 1 & casos <= 2 ~ "1 a 2 vítimas",
      casos >= 3 & casos <= 4 ~ "3 a 4 vítimas",
      casos >= 5 & casos <= 6 ~ "5 a 6 vítimas",
      casos >= 7 ~ "7 ou mais vítimas"
    )
  )


# Definir a ordem da legenda

mapa_al$faixa_feminicidio <- factor(
  mapa_al$faixa_feminicidio,
  levels = c(
    "0 - Nenhum caso",
    "1 a 2 vítimas",
    "3 a 4 vítimas",
    "5 a 6 vítimas",
    "7 ou mais vítimas"
  )
)


# Conferir a quantidade de municípios por classe

mapa_al %>%
  st_drop_geometry() %>%
  count(faixa_feminicidio)


# 11. GERAR O MAPA DE DISTRIBUIÇÃO ESPACIAL
# Escala de cores frias: azul-claro, azul e roxo.
# Contornos escurecidos para destacar os limites municipais.

mapa_feminicidios <- ggplot(mapa_al) +

  geom_sf(
    aes(
      fill = faixa_feminicidio,
      color = after_scale(
        colorspace::darken(fill, amount = 0.15)
      )
    ),
    linewidth = 0.10
  ) +

  scale_fill_manual(
    values = c(
      "0 - Nenhum caso" = "#E8F1F8",
      "1 a 2 vítimas" = "#A9CBE3",
      "3 a 4 vítimas" = "#5486B4",
      "5 a 6 vítimas" = "#344B8E",
      "7 ou mais vítimas" = "#542B72"
    ),
    name = "Número de vítimas",
    drop = FALSE
  ) +

  labs(
    title = "Distribuição espacial dos feminicídios em Alagoas",
    subtitle = "Número acumulado de vítimas por município, 2020–2024",
    caption = "Fonte: SINESP VDE. Elaboração própria."
  ) +

  theme_void() +

  theme(
    plot.title = element_text(
      hjust = 0.5,
      face = "bold",
      size = 15
    ),
    plot.subtitle = element_text(
      hjust = 0.5,
      size = 11
    ),
    legend.position = "right",
    legend.title = element_text(
      face = "bold"
    ),
    plot.caption = element_text(
      hjust = 1,
      size = 9
    )
  )


# 12. EXIBIR O MAPA

mapa_feminicidios
