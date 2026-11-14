Feminicídios em Alagoas (2015 a 2025)
Projeto de pesquisa do NEPE | PET Economia

Análise descritiva e exploratória de dados espaciais dos registros de feminicídio nos
102 municípios de Alagoas, entre 2015 e 2025.
Status: repositório inicial de divulgação. A análise foi desenvolvida no RStudio.
Apenas o script descritivo disponível nesta entrega foi incluído integralmente;
os demais scripts originais devem ser copiados do projeto local antes de afirmar
que o repositório reproduz toda a pesquisa.

Principais resultados
Indicador	Resultado
Feminicídios registrados (2015 a 2025)	306
Média anual de registros	27,8
Municípios analisados	102
Ano com mais registros	2019 (43)
Maceió, registros absolutos	79
Moran Global, matriz Queen	0,1371
Moran Global, valor-p de permutação (999)	0,040
LISA Queen, p sem ajuste	6 municípios
LISA Queen, após ajuste Benjamini-Hochberg	0 municípios


Os resultados LISA acima referem-se à análise executada em R. Resultados
posteriores obtidos com outras configurações ou softwares precisam ser
documentados separadamente e conciliados antes da publicação.
Fontes e metodologia
- Feminicídios: API do portal de dados abertos do Governo de Alagoas,
  base de Crimes Violentos Letais Intencionais (CVLI).
- População feminina: IBGE, Censo Demográfico 2022.
- Malha municipal: IBGE, por meio do pacote geobr.
- Ambiente: R e RStudio.
- Estatísticas espaciais: Moran Global e LISA, pesos de contiguidade Queen
  padronizados por linha; 999 permutações.
Taxa média anual aproximada por 100 mil mulheres:

taxa_i = [feminicidios_i (2015 a 2025) / (populacao_feminina_i_2022 × 11)] × 100000

A população feminina de 2022 é mantida fixa ao longo dos 11 anos, razão pela
qual essa taxa não corresponde a uma série de taxas anuais observadas.
Organização
scripts/                 scripts R e exportador de resultados públicos
dados/agregados/         tabelas agregadas, sem dados individuais
resultados/descritiva/   gráficos PNG (adicionar exportações locais)
resultados/mapas/        mapas PNG (adicionar exportações locais)
resultados/autocorrelacao/ gráficos Moran e LISA (adicionar exportações locais)
docs/index.html          página estática opcional para GitHub Pages
Como completar com seus resultados locais
1. Copie os scripts originais 01, 02, 04, 05, 06 e 07 da pasta
   CVLI/Scripts/ do RStudio para scripts/ neste repositório.
2. Copie os gráficos PNG já exportados em CVLI/Resultados/ para as
   respectivas pastas de resultados/.
3. Para atualizar os dados agregados, execute scripts/08_exportar_resultados_publicos.R
   a partir da raiz do projeto RStudio original, ajustando saida se necessário.
   Depois copie os CSV exportados para dados/agregados/ deste repositório.
4. Confira consistência entre a execução de RStudio e eventuais análises em GeoDa
   antes de editar indicadores de Moran ou LISA na documentação.
Site no GitHub Pages
Este repositório inclui uma página estática em docs/index.html.
No GitHub: Settings > Pages > Build and deployment > Deploy from a branch,
selecione main e /docs e salve.

O GitHub Pages hospeda HTML/CSS/JavaScript, mas não executa código Streamlit.
Um futuro dashboard Streamlit pode usar este mesmo repositório como fonte e
ser hospedado em Streamlit Community Cloud.
Ética e limitações
Não publique bases individuais com idade, data, bairro, horário ou outras
combinações que possam permitir identificar vítimas. Os CSV deste repositório
contêm apenas totais agregados. Para leitura dos indicadores, considerar
limitações de registros administrativos, classificação dos casos,
populações municipais pequenas e ausência de significância LISA após
correção para testes múltiplos.
Autoria
Pesquisa desenvolvida no âmbito do NEPE (Núcleo de Estudos e Pesquisa Econômica),
PET Economia. Preencher os nomes dos autores e a instituição antes da divulgação.
