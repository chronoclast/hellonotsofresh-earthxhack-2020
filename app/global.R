# global

library(shiny)
library(httr)
library(jsonlite)
library(shinyWidgets)
library(DT)
library(dplyr)

# Demo data (for demo mode)
response_df <- readRDS("response_df.rds")

# This is a sample database with grocery store products
products <- readRDS('products.rds')
products$sensor_connected <- ifelse(products$product %in% c('tomatoes','apples','potatoes'),
                                    TRUE, FALSE)

# A random number to assing a initial recipe
n <- sample(c(1:nrow(response_df)), size = 1)

# Variables to indicate if we should run demo mode
demo_mode_adafruit = TRUE
demo_mode_spoonacularAPI = TRUE

if (demo_mode_adafruit == FALSE | demo_mode_spoonacularAPI == FALSE) {
  # Requirements for the app to run with real data:
  # - Spoonacular API key is needed  
  # - Sensors sending data via Adafruit
  # In demo version it works without either of those
  # Sourcing local file:
  message("Sourcing local file")
  source(gsub("app","dev/local.R",getwd()))
} 

# Have a start time for the fake senser inputs
start_apples = as.numeric(Sys.time()+10)
start_tomatoes = as.numeric(Sys.time()+5)
start_potatoes = as.numeric(Sys.time()) 

# Making this a global variable, to avoid too much reactivity in the product of the day output
previous_product_of_the_day <- "melons"

# We need an initial value for product of the day as well
product_of_the_day <- "melons"
  
values <- reactiveValues(products = products,
                         # Initialize the app with randomly picked recipe from the test data
                         recipe = response_df[n,],
                         recipeImageSkew = -6,
                         recipeIngredientsSkew = 4,
                         recipeImageMargin = 80)

recipe <- NULL