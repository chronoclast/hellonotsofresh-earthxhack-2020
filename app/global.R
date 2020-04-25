# global

library(shiny)
library(httr)
library(jsonlite)
library(shinyWidgets)

demo <- readRDS("test.rds")
response_df <- demo[[1]]
ingredients <- demo[[3]]

response_df <- response_df[order(response_df$likes, decreasing = TRUE),]
n <- sample(c(1:nrow(response_df)), size = 1)
values <- reactiveValues(n = n)

