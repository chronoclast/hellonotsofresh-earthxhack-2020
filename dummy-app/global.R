# global

library(shiny)
library(httr)
library(jsonlite)
library(shinyWidgets)

demo <- readRDS("test.rds")
response_df <- demo[[1]]

n <- sample(c(1:nrow(response_df)), size = 1)
values <- reactiveValues(n = n,
                         recipeImageSkew = -6,
                         recipeIngredientsSkew = 4,
                         recipeImageMargin = 80)

