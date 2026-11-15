# ============================================================
# 07. MORAN LOCAL (LISA) E CLUSTERS ESPACIAIS
# FEMINICÍDIOS EM ALAGOAS - 2015 A 2025
# ============================================================

# ------------------------------------------------------------
# 1. CARREGAR PACOTES
# ------------------------------------------------------------

library(dplyr)     # Manipulação de dados
library(sf)        # Dados espaciais
library(spdep)     # Moran Local e pesos espaciais
library(ggplot2)   # Mapas e gráficos


# ------------------------------------------------------------
# 2. CARREGAR BASE E MATRIZ QUEEN
# ------------------------------------------------------------

mapa_taxa_al <- readRDS(
  "CVLI/Dados/mapa_taxa_al_2015_2025.rds"
)

pesos_queen <- readRDS(
  "CVLI/Dados/pesos_queen.rds"
)

# Conferir quantidade de municípios
nrow(mapa_taxa_al)

# Conferir quantidade de municípios na matriz
length(pesos_queen$neighbours)

# Verificar consistência
stopifnot(
  nrow(mapa_taxa_al) == 102,
  length(pesos_queen$neighbours) == 102,
  all(is.finite(mapa_taxa_al$taxa_feminicidio))
)


# ------------------------------------------------------------
# 3. CALCULAR O MORAN LOCAL (LISA)
# ------------------------------------------------------------

set.seed(123)

lisa_resultado <- localmoran_perm(
  mapa_taxa_al$taxa_feminicidio,
  listw = pesos_queen,
  nsim = 999,
  alternative = "two.sided",
  zero.policy = TRUE
)

# Visualizar os resultados
head(lisa_resultado)

# Conferir os nomes das colunas
colnames(lisa_resultado)


# ------------------------------------------------------------
# 4. ORGANIZAR AS ESTATÍSTICAS DO LISA
# ------------------------------------------------------------

# Localizar a coluna do valor-p por permutação
coluna_p <- grep(
  "^Pr\\(.*\\) Sim$",
  colnames(lisa_resultado),
  value = TRUE
)

# Excluir a coluna de probabilidade folded
coluna_p <- setdiff(
  coluna_p,
  "Pr(folded) Sim"
)

if (length(coluna_p) != 1) {
  stop("Não foi possível identificar o valor-p simulado.")
}

# Adicionar estatísticas à base municipal
mapa_lisa_al <- mapa_taxa_al %>%
  mutate(
    lisa_i = lisa_resultado[, "Ii"],
    p_valor = lisa_resultado[, coluna_p]
  )

# Correção para múltiplos testes: Benjamini-Hochberg
mapa_lisa_al <- mapa_lisa_al %>%
  mutate(
    p_ajustado = p.adjust(p_valor, method = "BH")
  )


# ------------------------------------------------------------
# 5. CALCULAR OS QUADRANTES ESPACIAIS
# ------------------------------------------------------------

# Padronizar as taxas em torno da média
taxa_z <- as.numeric(
  scale(mapa_lisa_al$taxa_feminicidio)
)

# Calcular a defasagem espacial da taxa padronizada
lag_taxa_z <- lag.listw(
  pesos_queen,
  taxa_z,
  zero.policy = TRUE
)

# Definir quadrantes e clusters significativos
mapa_lisa_al <- mapa_lisa_al %>%
  mutate(
    taxa_z = taxa_z,
    lag_taxa_z = lag_taxa_z,

    quadrante = case_when(
      taxa_z >= 0 & lag_taxa_z >= 0 ~ "Alto-Alto",
      taxa_z < 0 & lag_taxa_z < 0 ~ "Baixo-Baixo",
      taxa_z >= 0 & lag_taxa_z < 0 ~ "Alto-Baixo",
      taxa_z < 0 & lag_taxa_z >= 0 ~ "Baixo-Alto"
    ),

    cluster_lisa = if_else(
      p_valor < 0.05,
      quadrante,
      "Não significativo"
    ),

    cluster_lisa_bh = if_else(
      p_ajustado < 0.05,
      quadrante,
      "Não significativo"
    )
  )

# Conferir distribuição dos clusters
table(mapa_lisa_al$cluster_lisa)

# Conferir distribuição após ajuste BH
table(mapa_lisa_al$cluster_lisa_bh)


# ------------------------------------------------------------
# 6. IDENTIFICAR MUNICÍPIOS SIGNIFICATIVOS
# ------------------------------------------------------------

municipios_significativos <- mapa_lisa_al %>%
  st_drop_geometry() %>%
  filter(p_valor < 0.05) %>%
  arrange(p_valor) %>%
  select(
    name_muni,
    casos,
    taxa_feminicidio,
    lisa_i,
    p_valor,
    p_ajustado,
    quadrante
  )

# Exibir a tabela
print(municipios_significativos, n = Inf)


# ------------------------------------------------------------
# 7. DEFINIR CORES DOS CLUSTERS
# ------------------------------------------------------------

cores_clusters <- c(
  "Alto-Alto" = "#C33E3E",
  "Baixo-Baixo" = "#367FA8",
  "Alto-Baixo" = "#E68C4D",
  "Baixo-Alto" = "#8BB9DA",
  "Não significativo" = "#E5E5E5"
)


# ------------------------------------------------------------
# 8. MAPA DE CLUSTERS LISA
# ------------------------------------------------------------

mapa_clusters <- ggplot(mapa_lisa_al) +

  geom_sf(
    aes(fill = cluster_lisa),
    color = "grey35",
    linewidth = 0.15
  ) +

  scale_fill_manual(
    values = cores_clusters,
    name = "Clusters LISA",
    drop = FALSE
  ) +

  labs(
    title = "Clusters espaciais de feminicídio em Alagoas",
    subtitle = paste(
      "LISA | 2015 a 2025 |",
      "Taxa média anual por 100 mil mulheres"
    ),
    caption = paste(
      "Fontes: CVLI e IBGE, Censo 2022.",
      "Queen | 999 permutações | p < 0,05 não ajustado."
    )
  ) +

  theme_minimal() +

  theme(
    panel.grid = element_blank(),
    axis.title = element_blank(),
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    legend.position = "right",
    plot.title = element_text(
      face = "bold",
      size = 14
    ),
    plot.subtitle = element_text(size = 10)
  )

# Visualizar
print(mapa_clusters)


# ------------------------------------------------------------
# 9. MAPA COM CORREÇÃO PARA MÚLTIPLOS TESTES
# ------------------------------------------------------------

mapa_clusters_bh <- ggplot(mapa_lisa_al) +

  geom_sf(
    aes(fill = cluster_lisa_bh),
    color = "grey35",
    linewidth = 0.15
  ) +

  scale_fill_manual(
    values = cores_clusters,
    name = "Clusters LISA",
    drop = FALSE
  ) +

  labs(
    title = "Clusters LISA com correção estatística",
    subtitle = "Alagoas, 2015 a 2025 | Método Benjamini-Hochberg",
    caption = paste(
      "Fontes: CVLI e IBGE, Censo 2022.",
      "999 permutações | p ajustado < 0,05."
    )
  ) +

  theme_minimal() +

  theme(
    panel.grid = element_blank(),
    axis.title = element_blank(),
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    legend.position = "right",
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10)
  )

print(mapa_clusters_bh)


# ------------------------------------------------------------
# 10. SALVAR OS RESULTADOS
# ------------------------------------------------------------

dir.create(
  "CVLI/Resultados",
  recursive = TRUE,
  showWarnings = FALSE
)

# Salvar base espacial com resultados LISA
saveRDS(
  mapa_lisa_al,
  "CVLI/Dados/mapa_lisa_al_2015_2025.rds"
)

# Salvar tabela de municípios significativos
write.csv(
  municipios_significativos,
  "CVLI/Resultados/municipios_lisa_significativos.csv",
  row.names = FALSE
)

# Exportar o mapa LISA
ggsave(
  "CVLI/Resultados/mapa_lisa_clusters_2015_2025.png",
  plot = mapa_clusters,
  width = 10,
  height = 8,
  dpi = 300
)

# Exportar o mapa com correção BH
ggsave(
  "CVLI/Resultados/mapa_lisa_clusters_bh_2015_2025.png",
  plot = mapa_clusters_bh,
  width = 10,
  height = 8,
  dpi = 300
)


# ------------------------------------------------------------
# CONFERÊNCIA FINAL DOS CLUSTERS LISA
# ------------------------------------------------------------

mapa_lisa_al %>%
  st_drop_geometry() %>%
  filter(cluster_lisa != "Não significativo") %>%
  select(
    name_muni,
    casos,
    taxa_feminicidio,
    cluster_lisa,
    p_valor,
    p_ajustado
  ) %>%
  arrange(cluster_lisa, p_valor) %>%
  print(n = Inf)
