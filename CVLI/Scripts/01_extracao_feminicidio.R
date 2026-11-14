install.packages("httr")
install.packages("jsonlite")

library(httr)
library(jsonlite)

url_catalogo <- "https://dados.al.gov.br/catalogo/api/3/action/package_search"

resposta <- GET(
  url_catalogo,
  query = list(
    q = "feminicídio"
  )
)

dados_catalogo <- fromJSON(
  content(
    resposta,
    "text",
    encoding = "UTF-8"
  ),
  flatten = TRUE
)

dados_catalogo$success
