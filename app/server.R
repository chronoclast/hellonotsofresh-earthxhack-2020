# server

server <- function(input, output) {
  # ============================ #
  # Refresh button for testing ####
  # ============================= #
  observeEvent(input$refresh, {
    # Bit lame, just to test - some made up message
    warning = sample(c("Oh no... we ran out of apples",
                       "Better start eating those oranges...",
                       "It is time for chicken"), 1)
    # Center according to message length not possible - better make all message around the length of better eat oranges
    showNotification(warning, 
                     type = sample(c("warning","error","default","message"), 1), 
                     closeButton = FALSE)
    Sys.sleep(3)
    # Pick a new random recipe...
    n <- sample(c(1:nrow(response_df)), size = 1)
    values$n <- n
  })
  
  # ======================= #
  # Show the recipe name ####
  # ======================= #
  output$recipe_name <- renderUI({
    HTML(paste0('<b style = "font-size: 72px; color: white">',tools::toTitleCase(response_df$title[values$n]),'</b>'))
  })
  
  # ========================== #
  # Show the recipe picture ####
  # ========================== #
  output$recipe_picture <- renderUI({
    # Printing for testing
    message(response_df$image[values$n])
    # Frame class is to add a frame around the (sometimes ugly) picture - see css file in the www folder
    HTML(paste0('<div class="frame" style = "transform: rotate(-6deg); margin-left:20px;"><img src="',response_df$image[values$n],'"/></div>'))
  })
  
  # ================================ #
  # Show the ingredients & prices ####
  # ================================ #
  output$ingredients_list <- renderUI({
    # Keep 5 ingredients to list (if we have more than 5)
    ingredients <- rbind(response_df$usedIngredients[values$n][[1]][c("name", "image")],
                         response_df$missedIngredients[values$n][[1]][c("name", "image")])
    if (nrow(ingredients) > 5) { 
      ingredients <- ingredients[1:5,]
    }
    
    # For the practice, let's add a fake price
    ingredients$price <- sample(seq(0.49, 5.49, by=0.1), size = nrow(ingredients))
    # Make a representable block in html with the images and the ingredient names
    ingredients_html <- paste(paste0('<div style="display: inline-block; margin-right:65px: margin-top:10px">',
                                     '<img style="margin-top:10px" src="',ingredients$image,
                                     '" height=60px/><b style="margin-left:20px">',tools::toTitleCase(ingredients$name),
                                     ' - Now for €',ingredients$price,'!</b>
                                       </div>'), collapse="")
    # The html for the ingredients list
    HTML(paste0('<div class = "paper" style="font-size: 200%; 
                                             color:#636363; 
                                             transform: rotate(4deg); 
                                             margin-top:60px;">
                 <p>Why not enjoy some delicious ',tools::toTitleCase(response_df$title[values$n]),
                      ' tonight? Here is what you\'ll need to prepare this dish:</p>',
                  ingredients_html,
                '</div>'))
  })
}