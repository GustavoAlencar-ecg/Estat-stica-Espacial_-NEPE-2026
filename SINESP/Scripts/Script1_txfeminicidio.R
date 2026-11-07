# ============================================================
# PET ECONOMIA
# Violência contra a mulher em Alagoas
# ============================================================


# ============================================================
# 1. PACOTES
# ============================================================

library(BrazilCrime)
library(dplyr)
library(ggplot2)
library(sf)
library(geobr)
library(gganimate)
library(gifski)
library(classInt)


# ============================================================
# 2. EXTRAÇÃO DOS DADOS
# ============================================================

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


# ============================================================
# 3. FEMINICÍDIO POR MUNICÍPIO
# ============================================================

feminicidio_al <- dados_al %>%
  filter(evento == "Feminicídio") %>%
  group_by(municipio) %>%
  summarise(
    casos = sum(total_vitima, na.rm = TRUE),
    .groups = "drop"
  )


# ============================================================
# 4. ESTUPRO POR MUNICÍPIO
#    Somente vítimas do sexo feminino
# ============================================================

estupro_al <- dados_al %>%
  filter(evento == "Estupro") %>%
  group_by(municipio) %>%
  summarise(
    casos = sum(feminino, na.rm = TRUE),
    .groups = "drop"
  )


# ============================================================
# 5. POPULAÇÃO DOS MUNICÍPIOS DE ALAGOAS
#    Censo Demográfico 2022
# ============================================================

populacao_al <- data.frame(
  municipio = c(
    "ÁGUA BRANCA",
    "ANADIA",
    "ARAPIRACA",
    "ATALAIA",
    "BARRA DE SANTO ANTÔNIO",
    "BARRA DE SÃO MIGUEL",
    "BATALHA",
    "BELÉM",
    "BELO MONTE",
    "BOCA DA MATA",
    "BRANQUINHA",
    "CACIMBINHAS",
    "CAJUEIRO",
    "CAMPESTRE",
    "CAMPO ALEGRE",
    "CAMPO GRANDE",
    "CANAPI",
    "CAPELA",
    "CARNEIROS",
    "CHÃ PRETA",
    "COITÉ DO NÓIA",
    "COLÔNIA LEOPOLDINA",
    "COQUEIRO SECO",
    "CORURIPE",
    "CRAÍBAS",
    "DELMIRO GOUVEIA",
    "DOIS RIACHOS",
    "ESTRELA DE ALAGOAS",
    "FEIRA GRANDE",
    "FELIZ DESERTO",
    "FLEXEIRAS",
    "GIRAU DO PONCIANO",
    "IBATEGUARA",
    "IGACI",
    "IGREJA NOVA",
    "INHAPI",
    "JACARÉ DOS HOMENS",
    "JACUÍPE",
    "JAPARATINGA",
    "JARAMATAIA",
    "JEQUIÁ DA PRAIA",
    "JOAQUIM GOMES",
    "JUNDIÁ",
    "JUNQUEIRO",
    "LAGOA DA CANOA",
    "LIMOEIRO DE ANADIA",
    "MACEIÓ",
    "MAJOR ISIDORO",
    "MARAGOGI",
    "MARAVILHA",
    "MARECHAL DEODORO",
    "MARIBONDO",
    "MAR VERMELHO",
    "MATA GRANDE",
    "MATRIZ DE CAMARAGIBE",
    "MESSIAS",
    "MINADOR DO NEGRÃO",
    "MONTEIRÓPOLIS",
    "MURICI",
    "NOVO LINO",
    "OLHO D'ÁGUA DAS FLORES",
    "OLHO D'ÁGUA DO CASADO",
    "OLHO D'ÁGUA GRANDE",
    "OLIVENÇA",
    "OURO BRANCO",
    "PALESTINA",
    "PALMEIRA DOS ÍNDIOS",
    "PÃO DE AÇÚCAR",
    "PARICONHA",
    "PARIPUEIRA",
    "PASSO DE CAMARAGIBE",
    "PAULO JACINTO",
    "PENEDO",
    "PIAÇABUÇU",
    "PILAR",
    "PINDOBA",
    "PIRANHAS",
    "POÇO DAS TRINCHEIRAS",
    "PORTO CALVO",
    "PORTO DE PEDRAS",
    "PORTO REAL DO COLÉGIO",
    "QUEBRANGULO",
    "RIO LARGO",
    "ROTEIRO",
    "SANTA LUZIA DO NORTE",
    "SANTANA DO IPANEMA",
    "SANTANA DO MUNDAÚ",
    "SÃO BRÁS",
    "SÃO JOSÉ DA LAJE",
    "SÃO JOSÉ DA TAPERA",
    "SÃO LUÍS DO QUITUNDE",
    "SÃO MIGUEL DOS CAMPOS",
    "SÃO MIGUEL DOS MILAGRES",
    "SÃO SEBASTIÃO",
    "SATUBA",
    "SENADOR RUI PALMEIRA",
    "TANQUE D'ARCA",
    "TAQUARANA",
    "TEOTÔNIO VILELA",
    "TRAIPU",
    "UNIÃO DOS PALMARES",
    "VIÇOSA"
  ),

  populacao = c(
    19008,
    13966,
    234696,
    37512,
    16365,
    7944,
    16448,
    4722,
    5936,
    21187,
    9603,
    10482,
    16024,
    6665,
    32106,
    8143,
    15559,
    15032,
    8999,
    5910,
    10810,
    15816,
    5581,
    50414,
    25397,
    51318,
    9805,
    15429,
    22712,
    3963,
    9618,
    36102,
    13731,
    23995,
    21372,
    15167,
    5083,
    5352,
    9219,
    4985,
    9470,
    17150,
    4092,
    23907,
    18457,
    24740,
    957916,
    17700,
    32174,
    9534,
    60370,
    13679,
    3155,
    21844,
    23857,
    15405,
    4845,
    7184,
    25187,
    10020,
    20695,
    8349,
    4330,
    10812,
    11446,
    4325,
    71574,
    23823,
    10573,
    13835,
    13804,
    6576,
    58650,
    15908,
    35370,
    2731,
    22609,
    12518,
    24071,
    9295,
    20082,
    11080,
    93927,
    6474,
    6919,
    46220,
    11323,
    6555,
    20813,
    30604,
    30873,
    51990,
    8482,
    31786,
    24278,
    12303,
    5796,
    19032,
    38053,
    23565,
    59280,
    24092
  )
)


# ============================================================
# 6. CÁLCULO DA TAXA DE FEMINICÍDIO
# ============================================================

feminicidio_alpop <- feminicidio_al %>%
  left_join(
    populacao_al,
    by = "municipio"
  ) %>%
  filter(municipio != "NÃO INFORMADO") %>%
  mutate(
    taxa = (casos / populacao) * 100000
  )


# ============================================================
# 7. MALHA DOS MUNICÍPIOS DE ALAGOAS
# ============================================================

al_municipios <- read_municipality(
  code_muni = "AL",
  year = 2022,
  simplified = TRUE
)


# ============================================================
# 8. INTEGRAÇÃO DOS DADOS COM A MALHA
# ============================================================

mapa_al <- al_municipios %>%
  mutate(
    municipio = toupper(name_muni)
  ) %>%
  left_join(
    feminicidio_alpop,
    by = "municipio"
  )


# ============================================================
# 9. MAPA DE FEMINICÍDIOS
#    Número absoluto de casos
# ============================================================

ggplot(mapa_al) +
  geom_sf(aes(fill = casos)) +
  scale_fill_gradient(
    low = "#F0F8FF",
    high = "#000A6F",
    na.value = "grey90"
  ) +
  theme_void() +
  labs(
    title = "Feminicídios nos municípios de Alagoas",
    subtitle = "Somatório de 2020 a 2025",
    fill = "Número de casos"
  )


# ============================================================
# 10. MAPA DE FEMINICÍDIOS
#     Taxa por 100 mil habitantes
# ============================================================

ggplot(mapa_al) +
  geom_sf(aes(fill = taxa)) +
  scale_fill_gradient(
    low = "#F0F8FF",
    high = "#000A6F",
    na.value = "grey90"
  ) +
  theme_void() +
  labs(
    title = "Taxa de feminicídios nos municípios de Alagoas",
    subtitle = "Somatório de 2020 a 2025 | por 100 mil habitantes",
    fill = "Taxa"
  )


# ============================================================
# 11. CLASSIFICAÇÃO DE JENKS
# ============================================================

jenks_taxa <- classIntervals(
  mapa_al$taxa,
  n = 5,
  style = "jenks"
)

jenks_taxa$brks
