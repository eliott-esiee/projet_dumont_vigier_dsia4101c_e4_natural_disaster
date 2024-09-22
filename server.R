# server.R

server <- function(input, output) {
  
  # Traitement des données pour la température globale
  global_temp_data <- global_temp_data %>%
    mutate(Year = as.numeric(Year),
           Annual_Anomaly = as.numeric(Annual_Anomaly)) %>% 
    filter(!is.na(Year), !is.na(Annual_Anomaly), Year >= 1900, Year <= 2021)
  
  global_temp_data$Smoothed_Anomaly <- rollapply(global_temp_data$Annual_Anomaly, 50, mean, fill = NA, align = "center")
  
  # Traitement des données pour les catastrophes naturelles
  df_catastrophe$Year <- as.numeric(df_catastrophe$Year)
  disaster_count_per_year <- df_catastrophe %>%
    filter(!is.na(Year)) %>%
    group_by(Year) %>%
    summarize(Count = n())
  
  disaster_count_by_type <- df_catastrophe %>%
    filter(!is.na(Year)) %>%
    count(Year, `Disaster.Type`) %>%
    pivot_wider(names_from = `Disaster.Type`, values_from = n, values_fill = list(n = 0))
  
  

  
  
  # Graphique 1
  output$graph1 <- renderPlot({
    filtered_data <- df_catastrophe %>%
      filter(Year >= input$year_slider[1], Year <= input$year_slider[2])
    
    ggplot(filtered_data, aes(x = `Total.Deaths`)) + 
      geom_histogram(fill = "blue", color = "black", alpha = 0.7) + 
      scale_y_log10(labels = scales::comma) +
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5)) +  # Centrer le titre
      labs(title = "Histogramme global du nombre total de décès dus aux catastrophes naturelles",
           x = "Décès totaux",
           y = "Nombre d'événements (Échelle logarithmique)")
  })
  
  # Graphique 2
  output$graph2 <- renderPlot({
    filtered_data <- df_catastrophe %>% 
      filter(Year >= input$year_slider[1], Year <= input$year_slider[2], 
             `Total.Deaths` >= 0, `Total.Deaths` <= 10000)
    
    ggplot(filtered_data, aes(x = `Total.Deaths`)) + 
      geom_histogram(fill = "blue", color = "black", alpha = 0.7) + 
      scale_y_log10(labels = scales::comma) +
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5)) +  # Centrer le titre
      labs(title = "Histogramme des décès (0 à 10,000) dus aux catastrophes naturelles",
           x = "Décès totaux",
           y = "Nombre d'événements (Échelle logarithmique)")
  })
  
  # Graphique 3
  output$graph3 <- renderPlot({
    filtered_data <- df_catastrophe %>% 
      filter(Year >= input$year_slider[1], Year <= input$year_slider[2], 
             `Total.Deaths` >= 0, `Total.Deaths` <= 10000)
    
    ggplot(filtered_data, aes(x = `Total.Deaths`, fill = `Disaster.Subgroup`)) + 
      geom_histogram(bins = 30, color="black", alpha=0.7) +
      scale_y_log10(labels = scales::comma) +
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5)) +  # Centrer le titre
      labs(title = "Histogramme des décès (0 à 10,000) dus aux catastrophes naturelles",
           x = "Décès totaux",
           y = "Nombre d'événements (Échelle logarithmique)")
  })
  
  
  
  
  
  output$graph4 <- renderPlotly({
    filtered_data <- df_catastrophe %>%
      filter(Year >= input$year_slider[1], Year <= input$year_slider[2], 
             `Total.Deaths` <= 500, `Total.Damages...000.US..` <= 1000000)
    
    p4 <- plot_ly(data = filtered_data) %>%
      add_histogram2d(x = ~`Total.Deaths`, y = ~`Total.Damages...000.US..`, nbinsx = 6, nbinsy = 6) %>%
      add_markers(x = ~`Total.Deaths`, y = ~`Total.Damages...000.US..`) %>%
      layout(
        title = "Histogramme 2D des Décès et Dommages", # Ajout du titre ici
        xaxis = list(title = "Décès totaux", range = c(0, 500)),
        yaxis = list(title = "Prix des dommages ('000 US$)", range = c(0, 1000000), type = "linear")
      )
    
    p4
  })
  
  
  # Définition du rendu de la carte Leaflet dans l'application Shiny
  output$map <- renderLeaflet({
    
    # Filtrage des données de catastrophe en fonction de la plage d'années sélectionnée par l'utilisateur
    df_selected <- df_catastrophe_location %>%
      filter(Year >= input$range[1] & Year <= input$range[2])
    
    # Initialisation de la carte Leaflet avec les données filtrées
    # Ajout d'un fond de carte à partir du fournisseur Esri
    map <- leaflet(df_selected) %>%
      addProviderTiles(providers$Esri.WorldTopoMap) %>%
      setView(lng = 2.5840685, lat = 48.8398094, zoom = 3)  # Définition de la vue initiale de la carte
    
    # Boucle pour ajouter des marqueurs personnalisés pour chaque catastrophe
    for (i in 1:nrow(df_selected)) {
      # Extraction du type de catastrophe pour chaque ligne de données
      catastrophe_type <- df_selected$Disaster.Type[i]
      
      # Récupération de la couleur et de l'icône correspondant au type de catastrophe
      marker_color <- marqueur_type_de_catastrophe[[catastrophe_type]]$color
      marker_icon <- marqueur_type_de_catastrophe[[catastrophe_type]]$icon
      
      # Ajout du marqueur sur la carte avec les propriétés personnalisées
      map <- addAwesomeMarkers(
        map, 
        lng=df_selected$Longitude[i], 
        lat=df_selected$Latitude[i], 
        popup=df_selected$Location[i],  # Popup affichant le lieu de la catastrophe
        icon=awesomeIcons(
          icon=marker_icon,   # Icône personnalisée
          markerColor=marker_color  # Couleur personnalisée
        ),
        group = catastrophe_type  # Groupement des marqueurs par type de catastrophe
      )
    }
    
    # Ajout d'un contrôle de couches pour permettre à l'utilisateur de filtrer les marqueurs par type de catastrophe
    map <- addLayersControl(
      map,
      overlayGroups = names(marqueur_type_de_catastrophe),
      options = layersControlOptions(collapsed = FALSE)
    )
    
    # Préparation des icônes et des couleurs pour la légende
    icons_for_legend <- sapply(marqueur_type_de_catastrophe, function(x) {gsub("-sign", "", x$icon)})
    colors_for_legend <- sapply(marqueur_type_de_catastrophe, function(x) x$color)
    
    # Fonction pour générer le code HTML de la légende
    generateLegendHTML <- function(icons, colors, labels) {
      html_legend <- '<div style="background-color: rgba(255,255,255,0.8); padding: 10px; border-radius: 5px;">'
      html_legend <- paste0(html_legend, "<h5>Types de Catastrophes</h5>")
      for (i in 1:length(icons)) {
        html_legend <- paste0(html_legend, sprintf('<i class="fa fa-%s" style="color: %s;"></i> %s<br/>', icons[i], colors[i], labels[i]))
      }
      html_legend <- paste0(html_legend, "</div>")
      return(html_legend)
    }
    
    # Génération et ajout de la légende HTML sur la carte
    html_legend <- generateLegendHTML(icons_for_legend, colors_for_legend, names(marqueur_type_de_catastrophe))
    map <- addControl(map, html=html_legend, position="bottomleft")
    
    # Retourner la carte configurée pour l'affichage
    map
  })
  
  
  #graphique 1 de navitem 3
  output$graph31 <- renderPlotly({
    fig1 <- plot_ly() %>%
      add_lines(x = ~Year, y = ~Count, data = disaster_count_per_year, name = 'Nombre de catastrophes', yaxis = "y") %>%
      add_lines(x = ~Year, y = ~Smoothed_Anomaly, data = global_temp_data, name = 'Écart de température', yaxis = "y2") %>%
      layout(title = "Nombre de catastrophes naturelles et écart de température par an",
             yaxis2 = list(overlaying = "y", side = "right"),
             xaxis = list(title = "Année"),
             yaxis = list(title = "Nombre de catastrophes"),
             yaxis2 = list(title = "Écart de température"))
    fig1
  })  
  
  #graphique 2 de navitem 3
  output$graph32 <- renderPlotly({
    fig2 <- plot_ly()
    for(disaster_type in colnames(disaster_count_by_type[-1])) {
      fig2 <- fig2 %>%
        add_lines(x = ~Year, y = disaster_count_by_type[[disaster_type]], data = disaster_count_by_type, name = disaster_type)
    }
    fig2 <- fig2 %>%
      layout(title = "Nombre de catastrophes naturelles par type par an",
             xaxis = list(title = "Année"),
             yaxis = list(title = "Nombre de catastrophes"))
    fig2    
  })  
  
  # Créer une carte colorée en fonction du nombre de catastrophes
  output$carte41 <- renderLeaflet({
    
    debut <- input$year_slider_carte[1]
    fin <- input$year_slider_carte[2]
    
    # Filtrer les données
    df_filtered <- disaster_counts %>%
      filter(Year >= debut & Year <= fin)
    
    # Calculs pour les catastrophes et les morts
    country_disaster_counts <- df_filtered %>%
      group_by(ISO) %>%
      summarise(Disaster_Count = sum(`Disaster Count`))
    
    
    
    
    # Fusionner avec les données géographiques
    merged_disaster_data <- merge(country_geojson_sf, country_disaster_counts, by.x = "ISO_A3", by.y = "ISO")
    
    
    # Création de la carte avec leaflet
    map_disaster <- leaflet() %>%
      setView(lng = 2.5840685, lat = 48.8398094, zoom = 3) %>%
      addProviderTiles(providers$Esri.WorldTopoMap) %>%
      
      addPolygons(data = merged_disaster_data,
                  fillColor = ~colorNumeric("YlOrRd", Disaster_Count)(Disaster_Count),
                  weight = 1,
                  color = "black",
                  fillOpacity = 0.7,
                  label = ~paste0(ISO_A3, ": ", Disaster_Count),
                  layerId = ~ISO_A3,
                  group = "Nombre de catastrophes naturelles par pays"
      )%>%
      addLayersControl(overlayGroups = c("Nombre de catastrophes naturelles par pays"))%>%
      
      # Ajouter une légende pour les décès (ajuster en fonction des données)
      addLegend("bottomleft", 
                pal = colorNumeric("OrRd", domain = merged_disaster_data$Disaster_Count),
                values = merged_disaster_data$Disaster_Count,
                title = "Nombre de catastrophes naturelles par pays",
                opacity = 0.7)
    
    map_disaster
  })
  
  #carte nombre de mort par pays
  output$carte42 <- renderLeaflet({
    
    debut <- input$year_slider_carte[1]
    fin <- input$year_slider_carte[2]
    df_filtered_death <- disaster_death_counts %>%
      filter(Year >= debut & Year <= fin)
    
    country_death_counts <- df_filtered_death %>%
      group_by(ISO) %>%
      summarise(Death_Count = sum(`Death Count`),Death_Count_log =log(1+sum(`Death Count`)) )
    
    merged_death_data <- merge(country_geojson_sf, country_death_counts, by.x = "ISO_A3", by.y = "ISO")
    
    map_death <- leaflet() %>%
      setView(lng = 2.5840685, lat = 48.8398094, zoom = 3) %>%
      addProviderTiles(providers$Esri.WorldTopoMap) %>%addPolygons(data = merged_death_data,
                                                                   fillColor = ~colorNumeric("YlOrRd", Death_Count_log)(Death_Count_log),
                                                                   weight = 1,
                                                                   color = "black",
                                                                   fillOpacity = 0.7,
                                                                   label = ~paste0(ISO_A3, ": ", Death_Count_log),
                                                                   layerId = ~ISO_A3,
                                                                   group = "Nombre de mort par pays"
      ) %>%
      addLayersControl(overlayGroups = c("Nombre de mort par pays")) %>%
      # Ajouter une légende pour les décès (ajuster en fonction des données)
      addLegend("bottomleft", 
                pal = colorNumeric("YlOrRd", domain = merged_death_data$Death_Count),
                values = merged_death_data$Death_Count,
                title = "Nombre de morts",
                opacity = 0.7)
    # Afficher la carte
    map_death
  })
  
  
  #graphique 1 de navitem 4
  output$graph41 <- renderPlotly({
    # manipuulation donnée pour le graphique 41
    # Filtrer les données en fonction de la sélection d'années
    filtered_data <- df_catastrophe %>%
      filter(Year >= input$year_slider_graph41[1], Year <= input$year_slider_graph41[2])
    
    # Agrégation des données pour obtenir le nombre total de morts et de catastrophes par pays et continent
    aggregated_data <- filtered_data %>%
      group_by(Continent, Country) %>%
      summarise(Total_Deaths = sum(`Total.Deaths`, na.rm = TRUE),
                Num_Disasters = n(), .groups = 'drop') # Compter les catastrophes et sommer les morts
    
    # Calculer le total des décès par continent
    continent_deaths <- aggregated_data %>%
      group_by(Continent) %>%
      summarise(Total_Deaths = sum(Total_Deaths, na.rm = TRUE), .groups = 'drop')
    
    # Ajouter une ligne pour chaque continent avec le monde comme parent
    world <- data.frame(Continent = rep("World", length(continent_deaths$Continent)), 
                        Country = continent_deaths$Continent, 
                        Total_Deaths = continent_deaths$Total_Deaths, 
                        Num_Disasters = NA)
    
    # Ajouter une ligne pour le monde sans parent
    world_total <- data.frame(Continent = NA, Country = "World", Total_Deaths = sum(continent_deaths$Total_Deaths, na.rm = TRUE), Num_Disasters = NA)
    
    # Combiner les dataframes
    hierarchy <- rbind(world_total, world, aggregated_data)
    
    # Remplacer les NA par des chaînes vides pour Plotly et des zéros pour les valeurs numériques
    hierarchy$Continent[is.na(hierarchy$Continent)] <- ""
    hierarchy$Total_Deaths[is.na(hierarchy$Total_Deaths)] <- 1 # Remplacer NA par 1 pour éviter log(0)
    hierarchy$Num_Disasters[is.na(hierarchy$Num_Disasters)] <- 0
    
    # Appliquer une échelle logarithmique pour les décès
    hierarchy$Log_Total_Deaths <- log10(hierarchy$Total_Deaths + 1) # Ajouter 1 pour éviter log(0)
    

    # Créer le treemap avec un titre
    fig <- plot_ly(
      type = "treemap",
      labels = hierarchy$Country,
      parents = hierarchy$Continent,
      values = hierarchy$Num_Disasters, # Utiliser le nombre de catastrophes pour la taille des cases
      textinfo = "label+value",
      marker = list(
        colors = hierarchy$Log_Total_Deaths, # Utiliser le logarithme du nombre total de morts pour la couleur des cases
        colorscale = 'RdBu', # Utiliser une échelle de rouge pour les morts
        cmin = min(hierarchy$Log_Total_Deaths, na.rm = TRUE), # Minimum basé sur le log du nombre minimal de morts
        cmax = max(hierarchy$Log_Total_Deaths, na.rm = TRUE), # Maximum basé sur le log du nombre maximal de morts
        colorbar = list(
          title = "Nombre de morts",
          tickvals = log10(c(1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 15000000)),
          ticktext = c("1", "10", "100", "1k", "10k", "100k", "1M", "10M", "")
        )
      )
    ) %>%
      layout(title = "Répartition des catastrophes naturelles par pays et continent")
    
    fig # Retourner le graphique pour l'affichage
  })
  
  #graphique 1 du navtab5
  output$graph51 <- renderPlotly({
    # Générer des couleurs aléatoires pour les nœuds
    set.seed(123) # Pour la reproductibilité
    
    node_colors <- sapply(1:length(labels), function(x) rgb(runif(1), runif(1), runif(1), 1))
    
    # Générer des couleurs pour les liens
    link_colors <- sapply(1:length(source), function(x) rgb(runif(1), runif(1), runif(1), 0.5))
    # Créer le diagramme de Sankey avec des couleurs
    fig <- plot_ly(
      type = "sankey",
      orientation = "h",
      node = list(
        label = labels,
        color = node_colors, # Utiliser les couleurs générées pour les nœuds
        pad = 15,
        thickness = 20,
        line = list(color = "black", width = 0.5)
      ),
      link = list(
        source = source - 1,
        target = target - 1,
        value = value,
        color = link_colors # Utiliser les couleurs générées pour les liens
      )
    )
    
    fig <- fig %>% layout(title = "Diagramme de Sankey des Catastrophes Naturelles", font = list(size = 10))
    
    fig
    
  })
  
  # Générer le graphique 2 du navitem 5
  output$graph52 <- renderPlotly({

    # Filtrer les données en fonction de la plage d'années sélectionnée
    df_catastrophe <- df_catastrophe %>%
      filter(Year >= input$year_slider_graph52[1], Year <= input$year_slider_graph52[2])
    
    # Remplacer les valeurs NA par 0 dans le nombre de décès
    df_catastrophe$Total.Deaths[is.na(df_catastrophe$Total.Deaths)] <- 0
    
    # Créer des identifiants uniques pour chaque niveau de la hiérarchie
    data <- df_catastrophe %>%
      mutate(GroupId = Disaster.Group,
             SubgroupId = ifelse(!is.na(Disaster.Subgroup), paste(Disaster.Group, Disaster.Subgroup, sep = "-"), Disaster.Group),
             TypeId = ifelse(!is.na(Disaster.Type), paste(Disaster.Group, Disaster.Subgroup, Disaster.Type, sep = "-"), SubgroupId),
             SubtypeId = ifelse(!is.na(Disaster.Subtype), paste(Disaster.Group, Disaster.Subgroup, Disaster.Type, Disaster.Subtype, sep = "-"), TypeId),
             SubsubtypeId = ifelse(!is.na(Disaster.Subsubtype), paste(Disaster.Group, Disaster.Subgroup, Disaster.Type, Disaster.Subtype, Disaster.Subsubtype, sep = "-"), SubtypeId))
    
    # Agréger les données pour chaque niveau en créant d'abord des labels
    group_data <- data %>%
      group_by(GroupId) %>%
      summarise(TotalDeaths = sum(Total.Deaths, na.rm = TRUE), .groups = 'drop') %>%
      mutate(Label = GroupId, Parent = "", ids = GroupId)
    
    subgroup_data <- data %>%
      group_by(GroupId, SubgroupId) %>%
      summarise(TotalDeaths = sum(Total.Deaths, na.rm = TRUE), .groups = 'drop') %>%
      mutate(Label = SubgroupId, Parent = GroupId, ids = SubgroupId)
    
    type_data <- data %>%
      group_by(SubgroupId, TypeId) %>%
      summarise(TotalDeaths = sum(Total.Deaths, na.rm = TRUE), .groups = 'drop') %>%
      mutate(Label = TypeId, Parent = SubgroupId, ids = TypeId)
    
    subtype_data <- data %>%
      group_by(TypeId, SubtypeId) %>%
      summarise(TotalDeaths = sum(Total.Deaths, na.rm = TRUE), .groups = 'drop') %>%
      mutate(Label = SubtypeId, Parent = TypeId, ids = SubtypeId)
    
    subsubtype_data <- data %>%
      group_by(SubtypeId, SubsubtypeId) %>%
      summarise(TotalDeaths = sum(Total.Deaths, na.rm = TRUE), .groups = 'drop') %>%
      mutate(Label = SubsubtypeId, Parent = SubtypeId, ids = SubsubtypeId)
    
    # S'assurer que toutes les colonnes sont présentes dans chaque dataframe
    cols <- c("ids", "Label", "Parent", "TotalDeaths")
    group_data <- group_data[cols]
    subgroup_data <- subgroup_data[cols]
    type_data <- type_data[cols]
    subtype_data <- subtype_data[cols]
    subsubtype_data <- subsubtype_data[cols]
    
    # Combiner toutes les données
    all_data <- rbind(group_data, subgroup_data, type_data, subtype_data, subsubtype_data)
    
    # Créer le diagramme en soleil avec tous les niveaux
    fig <- plot_ly(all_data, ids = ~ids, labels = ~Label, parents = ~Parent, values = ~TotalDeaths, branchvalues = "total", type = 'sunburst')
    
    # Retourner le graphique Plotly
    fig
  })
  
  #graphique 1 du navtab6
  output$graph61 <- renderPlotly({
    # Préparation des données
    data_summarized <- df_catastrophe %>%
      group_by(Year) %>%
      summarize(TotalCost = sum(Total.Damages...000.US.., na.rm = TRUE))
    
    # Création du graphique
    plot_ly(data_summarized, x = ~Year, y = ~TotalCost, type = 'scatter', mode = 'lines+markers') %>%
      layout(title = 'Coût total des catastrophes par année',
             xaxis = list(title = 'Année'),
             yaxis = list(title = 'Coût Total (en milliers de dollars US)'))
  })
  
  #graphique 2 du navtab6
  output$graph62 <- renderPlotly({
    
    # Filtrer les données en fonction de la plage d'années sélectionnée
    df_catastrophe <- df_catastrophe %>%
      filter(Year >= input$year_slider_graph62[1], Year <= input$year_slider_graph62[2])
    
    # Remplacer les valeurs NA par 0 dans le coût des catastrophes
    df_catastrophe$`Total.Damages...000.US..`[is.na(df_catastrophe$`Total.Damages...000.US..`)] <- 0
    
    # Créer des identifiants uniques pour chaque niveau de la hiérarchie
    df_catastrophe <- df_catastrophe %>%
      mutate(GroupId = as.character(Disaster.Group),
             SubgroupId = ifelse(!is.na(Disaster.Subgroup), paste(GroupId, Disaster.Subgroup, sep = "-"), GroupId),
             TypeId = ifelse(!is.na(Disaster.Type), paste(SubgroupId, Disaster.Type, sep = "-"), SubgroupId),
             SubtypeId = ifelse(!is.na(Disaster.Subtype), paste(TypeId, Disaster.Subtype, sep = "-"), TypeId),
             SubsubtypeId = ifelse(!is.na(Disaster.Subsubtype), paste(SubtypeId, Disaster.Subsubtype, sep = "-"), SubtypeId))
    
    # Agréger les données pour chaque niveau en créant d'abord des labels
    group_data <- df_catastrophe %>%
      group_by(GroupId) %>%
      summarise(TotalCosts = sum(`Total.Damages...000.US..`, na.rm = TRUE), .groups = 'drop') %>%
      mutate(Label = GroupId, Parent = "", ids = GroupId)
    
    subgroup_data <- df_catastrophe %>%
      group_by(GroupId, SubgroupId) %>%
      summarise(TotalCosts = sum(`Total.Damages...000.US..`, na.rm = TRUE), .groups = 'drop') %>%
      mutate(Label = SubgroupId, Parent = GroupId, ids = SubgroupId)
    
    type_data <- df_catastrophe %>%
      group_by(SubgroupId, TypeId) %>%
      summarise(TotalCosts = sum(`Total.Damages...000.US..`, na.rm = TRUE), .groups = 'drop') %>%
      mutate(Label = TypeId, Parent = SubgroupId, ids = TypeId)
    
    subtype_data <- df_catastrophe %>%
      group_by(TypeId, SubtypeId) %>%
      summarise(TotalCosts = sum(`Total.Damages...000.US..`, na.rm = TRUE), .groups = 'drop') %>%
      mutate(Label = SubtypeId, Parent = TypeId, ids = SubtypeId)
    
    subsubtype_data <- df_catastrophe %>%
      group_by(SubtypeId, SubsubtypeId) %>%
      summarise(TotalCosts = sum(`Total.Damages...000.US..`, na.rm = TRUE), .groups = 'drop') %>%
      mutate(Label = SubsubtypeId, Parent = SubtypeId, ids = SubsubtypeId)
    
    # S'assurer que toutes les colonnes sont présentes dans chaque dataframe
    cols <- c("ids", "Label", "Parent", "TotalCosts")
    all_data <- list(group_data, subgroup_data, type_data, subtype_data, subsubtype_data) %>%
      lapply(function(df) df[cols]) %>%
      bind_rows()
    
    # Créer le diagramme en soleil avec tous les niveaux
    fig <- plot_ly(all_data, ids = ~ids, labels = ~Label, parents = ~Parent, values = ~TotalCosts, branchvalues = "total", type = 'sunburst')
    
    # Retourner le graphique Plotly
    fig
  })
  
  
}
