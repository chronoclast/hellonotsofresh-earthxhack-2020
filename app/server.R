# server

server <- function(input, output) {
  # ========================= #
  # Refresh products table ####
  # ========================= #
  productsUpdate <- reactive({ #iolink reactive ####
    invalidateLater(15000)
    message("Getting sensor data...")
    
    # Add shelftime from sensor data
    if (demo_mode_adafruit) {
      sensor_1 <- sample(seq(0.49, 3.49, by=0.1), sum(products$sensor_connected))
      # Products is currently a global variable that gets updated in the product of the day output
      products$shelftime[products$sensor_connected] <- products$shelftime[products$sensor_connected]+sensor_1
    } else{
      #sensor_1 <- fromJSON(Sys.getenv("ADAFRUIT_URL")$latest_value
    }
    
    return(products)
  })
  
  # ========================================================= #
  # Pop open modalDialog when show table button is pressed ####
  # ========================================================= #
  observeEvent(input$show_table, {
    showModal(modalDialog(
      title = "Product Database",
      DTOutput("product_status")
    ))   
  })
  
  # ================================================ #
  # Generate product table output for modalDialog ####
  # ================================================ #
  output$product_status <- renderDT({
    products <- values$products
    # Keep updated products table are source of truth
    datatable(products[order(products$shelftime, decreasing = TRUE),
                       names(products)[!names(products) %in% c("sensor_connected")]], rownames = FALSE)
  })
  
  # ============================================================= #
  # Product of the day banner: the secret to our interactivity ####
  # ============================================================= #
  output$product_of_the_day <- renderUI({
    # Still need to find a better way to keep products table up to date without global or reactive values
    products <<- productsUpdate()
    values$products <- products
    
    # Extract the product that has been on the shelf the longest
    product_of_the_day <- products$product[order(products$shelftime, decreasing = TRUE)][1]
    print(product_of_the_day)
    print(products$shelftime[order(products$shelftime, decreasing = TRUE)][1])
    
    if (values$product_of_the_day != product_of_the_day) {
      message('The product of the day has changed')
      previous_product_of_the_day <- values$product_of_the_day
      
      # Check the type, so we don't end up with potatoes & sweet potatoes or chicken and pork
      product_of_the_day_type <- products$type[products$product == product_of_the_day]
      
      # Pick 2 extra ingredients that are not sensor tracked and are not of the same type
      recipeIngredients <- gsub(' ','+',paste(c(product_of_the_day,
                                                sample(products$product[products$sensor_connected == FALSE & 
                                                                        products$type != product_of_the_day_type],2)),
                                              collapse = ',+'))
      
      if (demo_mode_spoonacularAPI) {
        # If demo mode, skip the API call
        n <- sample(c(1:nrow(response_df)), size = 1)
        response_df_sub <- response_df[n,]
      } else {
        # API call
        url <- paste0("https://api.spoonacular.com/recipes/findByIngredients",
                      "?ingredients=",recipeIngredients,
                      "&number=20", # number of recipes returned
                      "&ranking=1", # 1 = maximize use of ingredients listed; 2 = minimize missing ingredients
                      "&ignorePantry=true",
                      "&apiKey=", Sys.getenv("API_KEY"))
        response <- GET(url, accept_json())
        
        message(paste0("This query costed you ",response$headers$`x-api-quota-request`," credits"))
        message(paste0("Credits used today: ",response$headers$`x-api-quota-used`," (out of 150)"))
        
        response_df <- fromJSON(content(response, "text"))
        
        response_df_sub <-  response_df %>%
          rowwise() %>%
          # Make one long string with ingredients used in each recipe for easy filtering
          mutate(ingredients = paste(c(usedIngredients$name,missedIngredients$name),collapse=',')) %>%
          # Keep whatever recipes contain our product of the day & not the previous one
          filter(grepl(product_of_the_day, ingredients) & !grepl(previous_product_of_the_day, ingredients)) 
        
        response_df_sub <- as.data.frame(response_df_sub) %>%
          filter(usedIngredientCount == max(usedIngredientCount)) %>%
          arrange(desc(likes))
      }
      
      # Make a message to inform the recipe is going to change
      warning = sample(c(paste0("Oh no... we ran out of ",previous_product_of_the_day),
                         paste0("Better start eating those ",product_of_the_day,"..."),
                         paste0("It is time for ",product_of_the_day,"!")), 1)
      # Center according to message length not possible - better make all message around the length of better eat oranges
      showNotification(warning,
                       type = sample(c("warning","error","default","message"), 1),
                       closeButton = FALSE)
      # Adding a bit of delay...
      Sys.sleep(2)
      
      # And arrange the layout also a bit more random, why not
      values$recipeImageSkew = sample(-15:-1, 1)
      values$recipeIngredientsSkew = sample(3:15, 1)
      values$recipeImageMargin = sample(70:100, 1)
      
      # Reassign other values
      values$product_of_the_day <- product_of_the_day
      values$recipeIngredients <- recipeIngredients
      values$recipe <- response_df_sub[1,]
    }
    
    HTML(paste0('<div style="transform: rotate(8deg); background-color:#ffc107; ',
                'width:420px; font-size:36px; padding:8px; text-align:center;margin-top:-4em;',
                'margin-bottom:24px;">',
                'Product of the day: ',tools::toTitleCase(product_of_the_day),'!</div>'))
  })
  
  # ======================= #
  # Show the recipe name ####
  # ======================= #
  output$recipe_name <- renderUI({
    HTML(paste0('<div style="height:200px"><b style = "font-size: 72px; color: white;">',
                tools::toTitleCase(values$recipe$title),'</b></div>'))
  })
  
  # ========================== #
  # Show the recipe picture ####
  # ========================== #
  output$recipe_picture <- renderUI({
    # Printing for testing
    message(values$recipe$image)
    # Frame class is to add a frame around the (sometimes ugly) picture - see css file in the www folder
    HTML(paste0('<div class="frame" style = "transform: rotate(',values$recipeImageSkew,
                'deg); margin-left:',values$recipeImageMargin,'px;"><img src="',values$recipe$image,'"/></div>'))
  })
  
  # ================================ #
  # Show the ingredients & prices ####
  # ================================ #
  output$ingredients_list <- renderUI({
    # Keep 5 ingredients to list (if we have more than 5)
    ingredients <- rbind(values$recipe$usedIngredients[[1]][c("name", "image")],
                         values$recipe$missedIngredients[[1]][c("name", "image")])
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
                 <p>Why not enjoy some delicious ',tools::toTitleCase(values$recipe$title),
                  ' tonight? Here is what you\'ll need to prepare this dish:</p>',
                  ingredients_html,
                '</div>'))
  })
}