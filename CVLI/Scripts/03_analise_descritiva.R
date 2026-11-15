# ============================================================
# 03. ANÁLISE DESCRITIVA DOS FEMINICÍDIOS
# CVLI - ALAGOAS
# Período: 2015 a 2025
# ============================================================


# ------------------------------------------------------------
# 1. CARREGAR PACOTES
# ------------------------------------------------------------

library(dplyr)      # Manipulação dos dados
library(ggplot2)    # Construção dos gráficos
library(tidyr)      # Organização e preenchimento de dados
library(stringr)    # Tratamento de textos


# ------------------------------------------------------------
# 2. CARREGAR A BASE TRATADA
# ------------------------------------------------------------

base_feminicidio <- readRDS(
  "CVLI/Dados/base_feminicidio_tratada.rds"
)

# Conferir as variáveis
names(base_feminicidio)

# Conferir quantidade de registros
nrow(base_feminicidio)

# Conferir o período
table(base_feminicidio$ano)

# Conferir estrutura da base
str(base_feminicidio)


# ------------------------------------------------------------
# 3. CRIAR PASTA DE RESULTADOS
# ------------------------------------------------------------

dir.create(
  "CVLI/Resultados/Descritiva",
  recursive = TRUE,
  showWarnings = FALSE
)


# ------------------------------------------------------------
# 4. FUNÇÃO PARA TABELAS DE FREQUÊNCIA
# ------------------------------------------------------------

# Cria uma tabela com:
# categoria, frequência absoluta e percentual

tabela_frequencia <- function(dados, variavel) {

  dados %>%
    mutate(
      categoria = trimws(as.character({{ variavel }})),
      categoria = if_else(
        is.na(categoria) | categoria == "",
        "Não informado",
        categoria
      )
    ) %>%
    count(categoria, name = "frequencia") %>%
    mutate(
      percentual = round(
        frequencia / sum(frequencia) * 100,
        2
      )
    ) %>%
    arrange(desc(frequencia))
}


# ------------------------------------------------------------
# 5. DISTRIBUIÇÃO ANUAL DOS FEMINICÍDIOS
# ------------------------------------------------------------

feminicidio_ano <- base_feminicidio %>%
  count(ano, name = "casos") %>%
  complete(
    ano = 2015:2025,
    fill = list(casos = 0)
  ) %>%
  arrange(ano) %>%
  mutate(
    percentual = round(
      casos / sum(casos) * 100,
      2
    )
  )

# Visualizar distribuição anual
print(feminicidio_ano)

# Gráfico da evolução anual

grafico_anual <- ggplot(
  feminicidio_ano,
  aes(x = ano, y = casos)
) +
  geom_line(
    color = "#164B70",
    linewidth = 1
  ) +
  geom_point(
    color = "#164B70",
    size = 2.5
  ) +
  scale_x_continuous(
    breaks = 2015:2025
  ) +
  labs(
    title = "Evolução anual dos feminicídios em Alagoas",
    subtitle = "Período de 2015 a 2025",
    x = "Ano",
    y = "Número de feminicídios",
    caption = "Fonte: CVLI, Governo de Alagoas."
  ) +
  theme_minimal(base_size = 15) +
  theme(
    plot.title = element_text(size = 19, face = "bold"),
    plot.subtitle = element_text(size = 15),
    plot.caption = element_text(size = 11),
    axis.title = element_text(size = 15),
    axis.text = element_text(size = 13)
  )

print(grafico_anual)

ggsave(
  "CVLI/Resultados/Descritiva/evolucao_anual.png",
  grafico_anual,
  width = 10,
  height = 6,
  dpi = 300
)


# ------------------------------------------------------------
# 6. PERFIL ETÁRIO DAS VÍTIMAS
# ------------------------------------------------------------

# Estatísticas descritivas da idade

summary(base_feminicidio$idade)

# Desvio-padrão
sd(
  base_feminicidio$idade,
  na.rm = TRUE
)

# Quantidade de idades ausentes
sum(is.na(base_feminicidio$idade))

# Conferir registros com idade zero
base_feminicidio %>%
  filter(idade == 0) %>%
  select(
    ano,
    data_fato,
    `CIDADE DO FATO`,
    idade
  ) %>%
  print()

# Criar faixas etárias

base_feminicidio <- base_feminicidio %>%
  mutate(
    faixa_etaria = cut(
      idade,
      breaks = c(
        -Inf, 14, 17, 24, 34,
        44, 54, 64, Inf
      ),
      labels = c(
        "0 a 14",
        "15 a 17",
        "18 a 24",
        "25 a 34",
        "35 a 44",
        "45 a 54",
        "55 a 64",
        "65 ou mais"
      )
    )
  )

# Distribuição por faixa etária

tabela_idade <- tabela_frequencia(
  base_feminicidio,
  faixa_etaria
)

print(tabela_idade)

# Gráfico de faixas etárias

grafico_idade <- ggplot(
  base_feminicidio,
  aes(x = faixa_etaria)
) +
  geom_bar(
    fill = "#367FA8"
  ) +
  labs(
    title = "Distribuição dos feminicídios por faixa etária",
    x = "Faixa etária",
    y = "Número de vítimas"
  ) +
  theme_minimal(base_size = 15) +
  theme(
    plot.title = element_text(size = 19, face = "bold"),
    plot.subtitle = element_text(size = 15),
    plot.caption = element_text(size = 11),
    axis.title = element_text(size = 15),
    axis.text = element_text(size = 13)
  ) +
  theme(
    axis.text.x = element_text(
      angle = 45,
      hjust = 1
    )
  )

print(grafico_idade)

ggsave(
  "CVLI/Resultados/Descritiva/faixa_etaria.png",
  grafico_idade,
  width = 10,
  height = 6,
  dpi = 300
)


# ------------------------------------------------------------
# 7. COR/RAÇA DAS VÍTIMAS
# ------------------------------------------------------------

tabela_cor_raca <- tabela_frequencia(
  base_feminicidio,
  `COR/RACA DA VITIMA`
)

print(tabela_cor_raca)

grafico_cor_raca <- ggplot(
  tabela_cor_raca,
  aes(
    x = reorder(categoria, frequencia),
    y = frequencia
  )
) +
  geom_col(
    fill = "#367FA8"
  ) +
  coord_flip() +
  labs(
    title = "Feminicídios segundo cor/raça da vítima",
    x = "Cor/raça",
    y = "Número de vítimas"
  ) +
  theme_minimal(base_size = 15) +
  theme(
    plot.title = element_text(size = 19, face = "bold"),
    plot.subtitle = element_text(size = 15),
    plot.caption = element_text(size = 11),
    axis.title = element_text(size = 15),
    axis.text = element_text(size = 13)
  )

print(grafico_cor_raca)

ggsave(
  "CVLI/Resultados/Descritiva/cor_raca.png",
  grafico_cor_raca,
  width = 9,
  height = 6,
  dpi = 300
)


# ------------------------------------------------------------
# 8. ESCOLARIDADE DAS VÍTIMAS
# ------------------------------------------------------------

tabela_escolaridade <- tabela_frequencia(
  base_feminicidio,
  `ESCOLARIDADE VITIMA`
)

print(tabela_escolaridade)

grafico_escolaridade <- ggplot(
  tabela_escolaridade,
  aes(
    x = reorder(categoria, frequencia),
    y = frequencia
  )
) +
  geom_col(
    fill = "#367FA8"
  ) +
  coord_flip() +
  labs(
    title = "Escolaridade das vítimas de feminicídio",
    x = "Escolaridade",
    y = "Número de vítimas"
  ) +
  theme_minimal(base_size = 15) +
  theme(
    plot.title = element_text(size = 19, face = "bold"),
    plot.subtitle = element_text(size = 15),
    plot.caption = element_text(size = 11),
    axis.title = element_text(size = 15),
    axis.text = element_text(size = 13)
  )

print(grafico_escolaridade)

ggsave(
  "CVLI/Resultados/Descritiva/escolaridade.png",
  grafico_escolaridade,
  width = 10,
  height = 7,
  dpi = 300
)


# ------------------------------------------------------------
# 9. OCUPAÇÃO DAS VÍTIMAS
# ------------------------------------------------------------

tabela_ocupacao <- tabela_frequencia(
  base_feminicidio,
  `OCUPACAO VITIMA`
)

print(tabela_ocupacao)

# Mostrar as 15 categorias mais frequentes

grafico_ocupacao <- tabela_ocupacao %>%
  slice_max(
    order_by = frequencia,
    n = 15,
    with_ties = FALSE
  ) %>%
  ggplot(
    aes(
      x = reorder(categoria, frequencia),
      y = frequencia
    )
  ) +
  geom_col(
    fill = "#367FA8"
  ) +
  coord_flip() +
  labs(
    title = "Ocupações mais frequentes entre as vítimas",
    x = "Ocupação",
    y = "Número de vítimas"
  ) +
  theme_minimal(base_size = 15) +
  theme(
    plot.title = element_text(size = 19, face = "bold"),
    plot.subtitle = element_text(size = 15),
    plot.caption = element_text(size = 11),
    axis.title = element_text(size = 15),
    axis.text = element_text(size = 13)
  )

print(grafico_ocupacao)

ggsave(
  "CVLI/Resultados/Descritiva/ocupacao.png",
  grafico_ocupacao,
  width = 10,
  height = 7,
  dpi = 300
)


# ------------------------------------------------------------
# 10. HORÁRIO DAS OCORRÊNCIAS
# ------------------------------------------------------------

# Extrair a hora dos registros no formato HH:MM
# e dividir o dia em quatro períodos

base_feminicidio <- base_feminicidio %>%
  mutate(
    hora_texto = trimws(
      as.character(`HORA DO FATO`)
    ),

    hora = suppressWarnings(
      as.integer(
        str_extract(
          hora_texto,
          "^\\d{1,2}(?=:)"
        )
      )
    ),

    hora = if_else(
      !is.na(hora) & hora >= 0 & hora <= 23,
      hora,
      NA_integer_
    ),

    periodo_dia = case_when(
      hora >= 0 & hora < 6 ~ "Madrugada",
      hora >= 6 & hora < 12 ~ "Manhã",
      hora >= 12 & hora < 18 ~ "Tarde",
      hora >= 18 & hora <= 23 ~ "Noite",
      TRUE ~ "Não informado"
    )
  )

tabela_horario <- tabela_frequencia(
  base_feminicidio,
  periodo_dia
)

print(tabela_horario)

grafico_horario <- ggplot(
  tabela_horario,
  aes(
    x = reorder(categoria, frequencia),
    y = frequencia
  )
) +
  geom_col(
    fill = "#367FA8"
  ) +
  coord_flip() +
  labs(
    title = "Feminicídios por período do dia",
    x = "Período",
    y = "Número de ocorrências"
  ) +
  theme_minimal(base_size = 15) +
  theme(
    plot.title = element_text(size = 19, face = "bold"),
    plot.subtitle = element_text(size = 15),
    plot.caption = element_text(size = 11),
    axis.title = element_text(size = 15),
    axis.text = element_text(size = 13)
  )

print(grafico_horario)

ggsave(
  "CVLI/Resultados/Descritiva/horario.png",
  grafico_horario,
  width = 9,
  height = 6,
  dpi = 300
)


# ------------------------------------------------------------
# 11. LOCAL DO FATO
# ------------------------------------------------------------

tabela_local <- tabela_frequencia(
  base_feminicidio,
  `LOCAL DO FATO`
)

print(tabela_local)

grafico_local <- ggplot(
  tabela_local,
  aes(
    x = reorder(categoria, frequencia),
    y = frequencia
  )
) +
  geom_col(
    fill = "#367FA8"
  ) +
  coord_flip() +
  labs(
    title = "Locais das ocorrências de feminicídio",
    x = "Local do fato",
    y = "Número de ocorrências"
  ) +
  theme_minimal(base_size = 15) +
  theme(
    plot.title = element_text(size = 19, face = "bold"),
    plot.subtitle = element_text(size = 15),
    plot.caption = element_text(size = 11),
    axis.title = element_text(size = 15),
    axis.text = element_text(size = 13)
  )

print(grafico_local)

ggsave(
  "CVLI/Resultados/Descritiva/local_fato.png",
  grafico_local,
  width = 10,
  height = 7,
  dpi = 300
)


# ------------------------------------------------------------
# 12. INSTRUMENTO UTILIZADO
# ------------------------------------------------------------

tabela_instrumento <- tabela_frequencia(
  base_feminicidio,
  `INSTRUMENTO UTILIZADO`
)

print(tabela_instrumento)

grafico_instrumento <- ggplot(
  tabela_instrumento,
  aes(
    x = reorder(categoria, frequencia),
    y = frequencia
  )
) +
  geom_col(
    fill = "#367FA8"
  ) +
  coord_flip() +
  labs(
    title = "Instrumentos utilizados nos feminicídios",
    x = "Instrumento utilizado",
    y = "Número de ocorrências"
  ) +
  theme_minimal(base_size = 15) +
  theme(
    plot.title = element_text(size = 19, face = "bold"),
    plot.subtitle = element_text(size = 15),
    plot.caption = element_text(size = 11),
    axis.title = element_text(size = 15),
    axis.text = element_text(size = 13)
  )

print(grafico_instrumento)

ggsave(
  "CVLI/Resultados/Descritiva/instrumento.png",
  grafico_instrumento,
  width = 10,
  height = 7,
  dpi = 300
)


# ------------------------------------------------------------
# 13. DISTRIBUIÇÃO MUNICIPAL
# ------------------------------------------------------------

feminicidio_municipio <- readRDS(
  "CVLI/Dados/feminicidio_municipio.rds"
)

# Conferir os municípios com mais registros

top_municipios <- feminicidio_municipio %>%
  slice_max(
    order_by = casos,
    n = 15,
    with_ties = FALSE
  )

print(top_municipios)

grafico_municipios <- ggplot(
  top_municipios,
  aes(
    x = reorder(`CIDADE DO FATO`, casos),
    y = casos
  )
) +
  geom_col(
    fill = "#164B70"
  ) +
  coord_flip() +
  labs(
    title = "Municípios com mais feminicídios em Alagoas",
    subtitle = "Casos acumulados de 2015 a 2025",
    x = "Município",
    y = "Número de feminicídios"
  ) +
  theme_minimal(base_size = 15) +
  theme(
    plot.title = element_text(size = 19, face = "bold"),
    plot.subtitle = element_text(size = 15),
    plot.caption = element_text(size = 11),
    axis.title = element_text(size = 15),
    axis.text = element_text(size = 13)
  )

print(grafico_municipios)

ggsave(
  "CVLI/Resultados/Descritiva/municipios.png",
  grafico_municipios,
  width = 10,
  height = 7,
  dpi = 300
)


# ------------------------------------------------------------
# 14. EXPORTAR TABELAS DESCRITIVAS
# ------------------------------------------------------------

tabelas <- list(
  anual = feminicidio_ano,
  idade = tabela_idade,
  cor_raca = tabela_cor_raca,
  escolaridade = tabela_escolaridade,
  ocupacao = tabela_ocupacao,
  horario = tabela_horario,
  local_fato = tabela_local,
  instrumento = tabela_instrumento,
  municipios = feminicidio_municipio
)

# Salvar cada tabela em CSV

for (nome in names(tabelas)) {

  write.csv(
    tabelas[[nome]],
    file = paste0(
      "CVLI/Resultados/Descritiva/",
      nome,
      ".csv"
    ),
    row.names = FALSE,
    fileEncoding = "UTF-8"
  )

}


# ------------------------------------------------------------
# 15. CONFERÊNCIA FINAL
# ------------------------------------------------------------

# Total de feminicídios
nrow(base_feminicidio)

# Total distribuído por ano
sum(feminicidio_ano$casos)

# Conferir frequências das variáveis
sum(tabela_idade$frequencia)
sum(tabela_cor_raca$frequencia)
sum(tabela_escolaridade$frequencia)
sum(tabela_ocupacao$frequencia)
sum(tabela_horario$frequencia)
sum(tabela_local$frequencia)
sum(tabela_instrumento$frequencia)

# Conferir municípios com registros
nrow(feminicidio_municipio)

# Finalização
message("Análise descritiva concluída.")
