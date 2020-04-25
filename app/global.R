# global

library(shiny)
library(httr)
library(jsonlite)
library(shinyWidgets)
library(DT)
library(dplyr)

demo <- readRDS("test.rds")
response_df <- demo[[1]]

# This is a sample database with grocery store products
products <- readRDS('products.rds')
products$sensor_connected <- ifelse(products$product %in% c('tomatoes','apples','potatoes'),
                                    TRUE, FALSE)

n <- sample(c(1:nrow(response_df)), size = 1)

demo_mode_adafruit = TRUE
demo_mode_spoonacularAPI = TRUE

if (demo_mode_adafruit == FALSE | demo_mode_spoonacularAPI == FALSE) {
  # Requirements for the app to run with real data:
  # - Spoonacular API key is needed  
  # - Sensors sending data via Adafruit
  # In demo version it works without either of those
  
  # Sourcing local file
  message("Sourcing local file")
  source(gsub("app","dev/local.R",getwd()))
}

values <- reactiveValues(products = products,
                         product_of_the_day = 'melons',
                         # Initialize the app with randomly picked recipe from the test data
                         recipe = response_df[n,],
                         recipeImageSkew = -6,
                         recipeIngredientsSkew = 4,
                         recipeImageMargin = 80)

