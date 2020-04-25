# ui

# I downloaded the bootstrap from https://bootswatch.com/
ui <- fluidPage(theme = "bootstrap-sketchy.css",
                tags$style("body {color: white; !important;}"),
                # Free picture from https://pixabay.com/images/search/kitchen/
                setBackgroundImage(src = 'food-1932466_1920.jpg'),
                # add tiny refresh button for when shit hits the fan
                absolutePanel(top = 20, right = 25,
                              actionButton("refresh", "", icon = icon("refresh"))
                ),
                # To center the shinyNotification in the center & make the letters ridiculously big
                tags$head(tags$style(
                    HTML(".shiny-notification {
                           font-size:600%;
                           position:fixed;
                           top: calc(50%);
                           left: calc(50% - 300px);}"))), 
                div(style = "padding:32px",
                    uiOutput("recipe_name"),
                    fluidRow(
                      column(6,uiOutput("recipe_picture")),
                      column(6,uiOutput("ingredients_list"))
                    )
                  )
                )