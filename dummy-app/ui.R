# ui

# I downloaded the bootstrap from https://bootswatch.com/
# To make the modalDialog work with the demo, I had to adjust the bootstrap.ccs a bit see https://stackoverflow.com/questions/16093568/bootstrap-modal-not-displaying
ui <- fluidPage(theme = "bootstrap-sketchy.css",
                # Some extra styling to make the app more readable...
                tags$style("body {color: white; !important;}"),
                tags$style("html {font-size:120%; !important;}"),
                tags$style(".modal-dialog {color: black; !important;}"),
                tags$style("#refresh {background-color: #ffc107; color: white; !important}"),
                # Free picture from https://pixabay.com/images/search/kitchen/
                setBackgroundImage(src = 'food-1932466_1920.jpg'),
                # add tiny refresh button for when shit hits the fan
                absolutePanel(top = 20, right = 25,
                              actionButton("refresh", "", icon = icon("refresh"))
                ),
                # To center the shinyNotification in the center & make the letters ridiculously big
                tags$head(tags$style(
                    HTML(".shiny-notification {
                           font-size:300%;
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