# ui.R
library(shinydashboard)

# Dashboard UI
ui <- dashboardPage(
  dashboardHeader(title = "Dashboard"),
  
  # Sidebar avec des éléments de navigation
  dashboardSidebar(
    width = 250, # La largeur peut être fixe
    sidebarMenu(
      menuItem("Home", tabName = "home", icon = icon("home")),
      menuItem("Histogrammes", tabName = "histograms", icon = icon("chart-bar")),
      menuItem("Carte des catastrophes", tabName = "map", icon = icon("globe")),
      menuItem("Evolution des catastrophes", tabName = "navitem3", icon = icon("chart-line")),
      menuItem("Catastrophes les plus coûteuses", tabName = "navitem6", icon = icon("dollar-sign")),
      menuItem("Catastrophes les plus meurtrières", tabName = "navitem5", icon = icon("skull-crossbones")),
      menuItem("Evolution des morts", tabName = "navitem4", icon = icon("user-injured"))
    )
  ),
  
  # Corps principal du tableau de bord
  dashboardBody(
    tabItems(
      
      tabItem(tabName = "home",
              div(style = "text-align: center;", h2("Données sur aléas naturels"),
                  p("Bienvenue sur notre Dashboard d'étude des catastrophes naturelles."),
                  
                  p("Cette plateforme interactive offre une exploration approfondie des différents aspects des catastrophes naturelles à travers le temps et l'espace."),
                  
                  p(HTML("<strong>Histogrammes des Catastrophes :</strong> Ici, nous analysons la fréquence et la sévérité des catastrophes naturelles au fil des ans. Les histogrammes permettent de visualiser les tendances et les modèles dans les données historiques, soulignant les périodes de haute activité et les types de catastrophes les plus communs.")),
                  p(HTML("<strong>Carte des Catastrophes :</strong> Cette section présente une carte interactive qui illustre la répartition géographique des catastrophes. En sélectionnant différentes plages d'années, vous pouvez observer comment certaines régions du monde sont plus affectées que d'autres et comment cela a évolué au fil du temps.")),
                  p(HTML("<strong>Evolution des Morts :</strong> Cette partie du dashboard se concentre sur l'impact humain des catastrophes naturelles. À travers des visualisations dynamiques, nous examinons l'évolution du nombre de décès dus aux catastrophes, offrant une perspective sombre mais nécessaire sur leur coût humain.")),
                  p(HTML("<strong>Evolution des Catastrophes :</strong> Ici, nous explorons les tendances dans l'occurrence des catastrophes naturelles au fil du temps. Cette analyse aide à comprendre si les catastrophes naturelles deviennent plus fréquentes et plus sévères avec le changement climatique et d'autres facteurs environnementaux.")),
                  p(HTML("<strong>Catastrophes les plus Meurtrières :</strong> Cet onglet met en lumière les catastrophes les plus dévastatrices en termes de pertes humaines. En examinant les catastrophes les plus meurtrières, nous pouvons apprendre de ces événements tragiques pour mieux nous préparer à l'avenir.")),
                  # Section ajoutée
                  h3("Interactivité et Exploration"),
                  p("Un élément clé de ce tableau de bord est son interactivité. Nous vous encourageons vivement à explorer les différents graphiques et visualisations interactives disponibles. Cliquez, faites glisser, et zoomez pour découvrir de nouveaux aperçus et perspectives sur les données. Votre interaction peut révéler des tendances cachées, des insights uniques et des informations détaillées qui ne sont pas immédiatement évidentes. N'hésitez pas à expérimenter et à explorer pour obtenir une compréhension plus profonde des catastrophes naturelles et de leur impact.")
              )),
      
      # Premier onglet : Histogrammes
      tabItem(tabName = "histograms",
              div(style = "text-align: center;", h2("Histogrammes des catastrophes")),
              fluidRow(
                box(title = "Filtres", status = "primary", solidHeader = TRUE, width = 12,
                    sliderInput("year_slider", "Sélectionnez une plage d'années :", 
                                min = 1900, max = 2021, value = c(1900, 2021),
                                step = 1, round = TRUE, sep = "", width = "100%",animate = TRUE)
                )
              ),
              fluidRow(
                box(plotOutput("graph1"), width = 6),
                box(plotOutput("graph2"), width = 6)
              ),
              fluidRow(
                box(plotOutput("graph3"), width = 6),
                box(plotlyOutput("graph4"), width = 6)
              )
      ),
      
      # Deuxième onglet : Carte
      tabItem(tabName = "map",
              div(style = "text-align: center;", h2("Carte des catastrophes")),
              fluidRow(
                box(title = "Filtres", status = "primary", solidHeader = TRUE, width = 12,
                    sliderInput("range", "Sélectionnez une plage d'années :", 
                                min = 1900, max = 2021, # Ces valeurs devront être dynamiques, ajustées selon vos données
                                value = c(2020, 2021), 
                                step = 1, round = TRUE, sep = "", width = "100%",animate = TRUE)
                )
              ),
              fluidRow(
                box(leafletOutput("map", height = 800), width = 12)
              )
      ),
      
      # troisième onglet : Evolution des morts
      tabItem(tabName = "navitem3",
              div(style = "text-align: center;", h2("Evolution des catastrophes")),
              fluidRow(
                box(plotlyOutput("graph31"), width = 12)
              ),
              fluidRow(
                box(plotlyOutput("graph32"), width = 12)
              )
      ),
      
      # 4e onglet : Evolution des catastrophes
      tabItem(tabName = "navitem4",
              div(style = "text-align: center;", h2("Evolution des morts")),
              fluidRow(
                box(title = "Filtres", status = "primary", solidHeader = TRUE, collapsible = TRUE, width = 12,
                    sliderInput("year_slider_carte", "Sélectionnez une plage d'années :", 
                                min = 1900, max = 2021, value = c(1900, 2021),
                                step = 1, round = TRUE, sep = "", width = "100%",animate = TRUE)
                )
              ),
              fluidRow(
                box(leafletOutput("carte41", height = 800), width = 12)
              ),
              fluidRow(
                box(leafletOutput("carte42", height = 800), width = 12)
              ),
              # Ajout d'une rangée fluide avec un slider pour filtrer les années
              fluidRow(
                box(title = "Filtres", status = "primary", solidHeader = TRUE, collapsible = TRUE, width = 12,
                    sliderInput("year_slider_graph41", "Sélectionnez une plage d'années :", 
                                min = 1900, max = 2021, value = c(1900, 2021),
                                step = 1, round = TRUE, sep = "", width = "100%",animate = TRUE)
                )
              ),
              fluidRow(
                box(plotlyOutput("graph41"), width = 12)
              )
      ),
      
      # 5e onglet : Catastrophes les plus meurtrières
      tabItem(tabName = "navitem5",
              div(style = "text-align: center;", h2("Catastrophes les plus meurtrières")),
              fluidRow(
                box(plotlyOutput("graph51", height = 1000), width = 12)
              ),
              fluidRow(
                box(title = "Filtres", status = "primary", solidHeader = TRUE, width = 12,
                    sliderInput("year_slider_graph52", "Sélectionnez une plage d'années :", 
                                min = 1900, max = 2021, value = c(1900, 2021),
                                step = 1, round = TRUE, sep = "", width = "100%",animate = TRUE)
                )
              ),
              div(style = "text-align: center;", h3("Sun graph des morts par catastrophes")),
              fluidRow(
                box(plotlyOutput("graph52", height = 1000), width = 12)
              )
      ),
      
      # 6e onglet : Catastrophes les plus chère
      tabItem(tabName = "navitem6",
              div(style = "text-align: center;", h2("Catastrophes les plus coûteuses")),
              fluidRow(
                box(plotlyOutput("graph61"), width = 12)
              ),
              fluidRow(
                box(title = "Filtres", status = "primary", solidHeader = TRUE, width = 12,
                    sliderInput("year_slider_graph62", "Sélectionnez une plage d'années :", 
                                min = 1900, max = 2021, value = c(1900, 2021),
                                step = 1, round = TRUE, sep = "", width = "100%",animate = TRUE)
                )
              ),
              div(style = "text-align: center;", h3("Sun graph du coût par catastrophes")),
              fluidRow(
                box(plotlyOutput("graph62", height = 1000), width = 12)
              )
              
              
              
      )
      
      
    )
  )
)
