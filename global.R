# global.R

# Chargement des bibliothèques
library(shiny)
library(leaflet)
library(dplyr)
library(readr)
library(plotly)
library(tidyverse)
library(shinydashboard)
library(ggplot2)
library(gapminder)
library(zoo) # pour rollapply
library(tidyr) # pour pivot_wider
library(sf)
library(sp)
library(networkD3)
# On importe nos données
disaster_data <- read_csv("./natural_disaster.csv")

# Chargement et préparation des données du premier fichier
df_catastrophe <- read.csv("natural_disaster.csv",sep=",")
df_geoloc <- read.csv("new_dataframe.csv",sep=",")
global_temp_data <- read.csv("Global Temperature.csv", sep = ",")

# Renommer les colonnes pour éviter les problèmes d'espaces
names(global_temp_data) <- c("Year", "Month", "Monthly_Anomaly", "Monthly_Unc", 
                             "Annual_Anomaly", "Annual_Unc", "Five_Year_Anomaly", 
                             "Five_Year_Unc", "Ten_Year_Anomaly", "Ten_Year_Unc", 
                             "Twenty_Year_Anomaly", "Twenty_year_Unc")

df_catastrophe$Latitude <- df_geoloc$Latitude
df_catastrophe$Longitude <- df_geoloc$Longitude

df_catastrophe_location <- df_catastrophe %>% filter(!is.na(Latitude) & !is.na(Longitude))

annees <- unique(df_catastrophe_location$Year)

marqueur_type_de_catastrophe <- list(
  "Drought" = list(color = 'beige', icon = 'tint'),
  "Drouuake" = list(color = 'beige', icon = 'tint'),
  "Volcanic activity" = list(color = 'orange', icon = 'fire'),
  "Mass movement (dry)" = list(color = 'black', icon = 'warning-sign'),
  "Storm" = list(color = 'darkblue', icon = 'cloud'),
  "Earthquake" = list(color = 'purple', icon = 'exclamation-sign'),
  "Earthquakeght" = list(color = 'purple', icon = 'exclamation-sign'),
  "Earthq" = list(color = 'purple', icon = 'exclamation-sign'),
  "Flood" = list(color = 'blue', icon = 'tint'),
  "Epidemic" = list(color = 'pink', icon = 'plus-sign'),
  "Landslide" = list(color = 'darkgreen', icon = 'arrow-down'),
  "Wildfire" = list(color = 'red', icon = 'fire'),
  "Extreme temperature" = list(color = 'darkred', icon = 'warning-sign'),
  "Fog" = list(color = 'lightgray', icon = 'cloud'),
  "Insect infestation" = list(color = 'green', icon = 'leaf'),
  "Impact" = list(color = 'black', icon = 'asterisk'),
  "Animal accident" = list(color = 'green', icon = 'leaf'),
  "Glacial lake outburst" = list(color = 'lightblue', icon = 'tint')
)


# Suppression des lignes avec des valeurs manquantes pour 'ISO' et 'Year'
df_castrophe_country <- df_catastrophe %>% 
  filter(!is.na(ISO) & !is.na(Year))

# Calcul du nombre total de catastrophes par année et par pays
disaster_counts <- df_castrophe_country %>%
  count(Year, ISO, name = "Disaster Count")

# Calcul du nombre total de morts par année et par pays
disaster_death_counts <- df_castrophe_country %>%
  group_by(Year, ISO) %>%
  summarise("Death Count" = sum(`Total.Deaths`, na.rm = TRUE)) %>%
  ungroup()

# Chemin vers le fichier GeoJSON qui contient les frontières des pays
country_geojson_sf <- st_read("countries.geojson")




# Select the necessary columns
selected_columns <- c('Disaster.Group', 'Disaster.Subgroup', 'Disaster.Type', 'Disaster.Subtype', 'Disaster.Subsubtype')
df_selected <- select(df_catastrophe, all_of(selected_columns))

# Créer la liste des labels
labels <- unique(unlist(df_selected))

# Créer un mapping pour les labels
label_mapping <- setNames(seq_along(labels), labels)

# Initialiser les listes source, target et value
source <- numeric()
target <- numeric()
value <- numeric()

# Remplir les listes pour chaque paire de colonnes adjacentes
for (i in 1:(length(selected_columns) - 1)) {
  col1 <- selected_columns[i]
  col2 <- selected_columns[i + 1]
  
  grouped_df <- df_selected %>%
    group_by(!!sym(col1), !!sym(col2)) %>%
    summarise(count = n(), .groups = 'drop')
  
  for(j in 1:nrow(grouped_df)) {
    source <- c(source, label_mapping[grouped_df[[1]][j]])
    target <- c(target, label_mapping[grouped_df[[2]][j]])
    value <- c(value, grouped_df$count[j])
  }
}

