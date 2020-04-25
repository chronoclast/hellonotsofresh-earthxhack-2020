# server

server <- function(input, output) {
  # ==================================================== #
  # Message to introduce the dummy version of the app ####
  # ==================================================== #
  showModal(modalDialog(
    title = "Welcome to Hello(NotSo)Fresh",
    HTML(paste0("<p>This is a dummy version of the app. We will show the real version in the live demo, of which we will ",
                "put a video on line on <a href='https://github.com/chronoclast/hellonotsofresh-earthxhack-2020' target='_blank'>",
                "our github page</a> as soon as it is available. The real version will use sensors that ",
                "are connected to supermarket products and will send the app data about which products are already in store ",
                "and better be sold quicly.</p>",
                "<p>Here you can simulate what happens when there is a change in products we want to promote by clicking on the",
                " <i class='fa fa-refresh' style='padding:8px;background-color:#ffc107;color:white;'>",
                "</i> refresh button in the upper right corner of the screen.</p>"))))
  
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
    # Adding a bit of delay...
    Sys.sleep(2)
    
    # Pick a new random recipe...
    n <- sample(c(1:nrow(response_df)), size = 1)
    values$n <- n
    
    # And arrange the layout also a bit more random, why not 
    values$recipeImageSkew = sample(-15:-1, 1)
    values$recipeIngredientsSkew = sample(3:15, 1)
    values$recipeImageMargin = sample(70:100, 1)
  })
  
  # ======================= #
  # Show the recipe name ####
  # ======================= #
  output$recipe_name <- renderUI({
    HTML(paste0('<div style="height:200px"><b style = "font-size: 72px; color: white;">',
                tools::toTitleCase(response_df$title[values$n]),'</b></div>'))
  })
  
  # ========================== #
  # Show the recipe picture ####
  # ========================== #
  output$recipe_picture <- renderUI({
    # Printing for testing
    message(response_df$image[values$n])
    # Frame class is to add a frame around the (sometimes ugly) picture - see css file in the www folder
    HTML(paste0('<div class="frame" style = "transform: rotate(',values$recipeImageSkew,
                'deg); margin-left:',values$recipeImageMargin,'px;"><img src="',response_df$image[values$n],'"/></div>'))
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
    HTML(paste0('<div class = "paper" style="font-size: 100%; 
                                             color:#636363; 
                                             transform: rotate(',values$recipeIngredientsSkew,'deg); 
                                             margin-top:16px;">
                 <p>Why not enjoy some delicious ',tools::toTitleCase(response_df$title[values$n]),
                  ' tonight? Here is what you\'ll need to prepare this dish:</p>',
                  ingredients_html,
                '</div>'))
  })
}