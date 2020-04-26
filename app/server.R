# server

server <- function(input, output, session) {
  # ========================= #
  # Refresh products table ####
  # ========================= #
  productsUpdate <- reactive({ 
    invalidateLater(5000, session = session)
    message("Getting sensor data...")
    
    # Simulate removal by randomly multiplying the current value with zero from time to time
    removal_simulation <- sample(c(rep(1,20),0),3, replace = TRUE)
    
    # Reset to current time if we get a zero - COMMENTED OUT THE APPLE SINCE WE NEED IT FOR THE LIVE DEMO
    #start_apples <<- ifelse(removal_simulation[1] == 0, Sys.time(), start_apples)
    start_tomatoes <<- ifelse(removal_simulation[2] == 0, Sys.time(), start_tomatoes)
    start_potatoes <<- ifelse(removal_simulation[3] == 0, Sys.time(), start_potatoes)
    
    if (demo_mode_adafruit) {
      # Add shelftime from demo data
      products$shelftime[products$product == "apples"] <-  round(as.numeric(Sys.time())-start_apples, 0)
      products$shelftime[products$product == "tomatoes"] <- round(as.numeric(Sys.time())-start_tomatoes, 0)
      products$shelftime[products$product == "potatoes"] <- round(as.numeric(Sys.time())-start_potatoes, 0)
      
    } else {
      # Add shelftime from sensor data
      products$shelftime[products$product == "apples"] <-  round(as.numeric(Sys.time())-start_apples, 0)
      products$shelftime[products$product == "tomatoes"] <- as.numeric(fromJSON(paste0(Sys.getenv("ADAFRUIT_URL"),"time-right"))$last_value)
      products$shelftime[products$product == "potatoes"] <- as.numeric(fromJSON(paste0(Sys.getenv("ADAFRUIT_URL"),"time-middle"))$last_value)
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
    products <- productsUpdate()
    
    # Extract the product that has been on the shelf the longest
    product_of_the_day <- products$product[order(products$shelftime, decreasing = TRUE)][1]
    print(product_of_the_day)
    print(products$shelftime[order(products$shelftime, decreasing = TRUE)][1])
    
    # Update the products table for the data table
    values$products <- products
    
    if (previous_product_of_the_day != product_of_the_day) {
      message('The product of the day has changed')
      
      # Check the type, so we don't end up with potatoes & sweet potatoes or chicken and pork
      product_of_the_day_type <- products$type[products$product == product_of_the_day]
      
      # No problem combining vegetables with vegetables though - otherwise we will get only weird tomato beer recipes..
      product_of_the_day_type <- ifelse(product_of_the_day_type == "vegetable", "", product_of_the_day_type)
      
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
        # Spoonacular API call
        url <- paste0("https://api.spoonacular.com/recipes/findByIngredients",
                      "?ingredients=",recipeIngredients,
                      "&number=20", # number of recipes returned
                      "&ranking=1", # 1 = maximize use of ingredients listed; 2 = minimize missing ingredients
                      "&ignorePantry=true",
                      "&apiKey=", Sys.getenv("API_KEY"))
        response <- GET(url, accept_json())
        
        message("Query details:")
        print(paste0("You looked for: ", recipeIngredients))
        print(paste0("This query costed you ",response$headers$`x-api-quota-request`," credits"))
        print(paste0("Credits used today: ",response$headers$`x-api-quota-used`," (out of 150)"))
        
        response_df <- fromJSON(content(response, "text"))
        # Saving results with randomized name, so we can append these files later for the demo app :)
        saveRDS(response_df, paste0(gsub(":","-",Sys.time()),"_response_df.rds"))
        
        response_df_sub <-  response_df %>%
          rowwise() %>%
          # Make one long string with ingredients used in each recipe for easy filtering
          mutate(ingredients = paste(c(usedIngredients$name,missedIngredients$name),collapse=',')) %>%
          # Keep whatever recipes contain our product of the day & not the previous one
          filter(grepl(product_of_the_day, ingredients) & !grepl(previous_product_of_the_day, ingredients)) 
        
        response_df_sub <- as.data.frame(response_df_sub) %>%
          # I know this is a bit weird, but I don't want the max usedIngredients to be some weird recipe with
          # zero likes, nor to filter out all the recipes if the usedIngredients are generally low...
          filter(!usedIngredientCount < mean(usedIngredientCount)) %>%
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
      
      # And arrange the layout also a bit more random, why not
      values$recipeImageSkew = sample(-15:-1, 1)
      values$recipeIngredientsSkew = sample(3:15, 1)
      values$recipeImageMargin = sample(70:100, 1)
      
      # Reassign other values
      values$recipeIngredients <- recipeIngredients
      values$recipe <- response_df_sub[1,]
      
      # Test - remove if doesn't work
      previous_product_of_the_day <<- product_of_the_day
    }
    
    # Generate the actual output
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
    
    # Before keeping only five, prioritize ingredients we want to show
    if (values$recipe$usedIngredientCount > 0) {
      usedIngredients <- values$recipe$usedIngredients[[1]][c("name", "image")] 
      usedIngredients$prio <- 2
    } else {
      usedIngredients <- NULL
    }
    
    # Also for the missedIngredients
    if (values$recipe$missedIngredientCount > 0) {
      missingIngredients <- values$recipe$missedIngredients[[1]][c("name", "image")]
      
      # Check if specific ingredients are mentioned in the name, just to make the list a bit more sensible
      name_check <- unlist(strsplit(values$recipe$title, " "))
      for (n in name_check) {
        missingIngredients$prio[missingIngredients$name == tolower(n)] <- sum(grepl(tolower(n), tolower(values$recipe$missedIngredients[[1]]$name)))
      }
    } else {
      missingIngredients <- NULL
    }
    
    # Keep 5 ingredients to list (if we have more than 5)
    ingredients <- rbind(usedIngredients,missingIngredients)
    if (nrow(ingredients) > 5) { 
      ingredients <- ingredients[order(ingredients$prio, decreasing = T),][1:5,]
    }
    
    # For the practice, let's add a fake price
    ingredients$price <- sample(seq(0.49, 5.49, by=0.1), size = nrow(ingredients))
    
    # If we have the ingredients in our databse, we take our price and discount - actual prices from our local supermarket
    prices_df <- products[,c("product","price","discount","unit")]
    names(prices_df) <- c("name","price_original","discount","unit")
    ingredients <- merge(ingredients, prices_df, by="name", all.x=T)
    # Calculate discounted price, if relevant
    ingredients$price <- format(round(ifelse(!is.na(ingredients$price_original), 
                                ingredients$price_original*(1-ingredients$discount),
                                ingredients$price),2), nsmall = 2)
    ingredients$discount <- ifelse(ingredients$discount==0, NA, ingredients$discount)
    # Display discounted price highlighted
    ingredients$price <- ifelse(!is.na(ingredients$discount),
                                paste0("<del>€",ingredients$price_original,
                                       "</del> <b style='color:red;font-size:120%'>€",
                                       ingredients$price,"</b>"),
                                paste0("€",ingredients$price))
    
    # Make a representable block in html with the images and the ingredient names
    ingredients_html <- paste(paste0('<div style="display: inline-block; margin-right:65px: margin-top:10px">',
                                     '<img style="margin-top:10px" src="',ingredients$image,
                                     '" height=60px/><b style="margin-left:20px">',tools::toTitleCase(ingredients$name),
                                     ' - Now for ',ingredients$price,'!</b>
                                       </div>'), collapse="")
    # The html for the ingredients list
    HTML(paste0('<div class = "paper" style="font-size: 100%; 
                                             color:#636363; 
                                             transform: rotate(',values$recipeIngredientsSkew,'deg); 
                                             margin-top:10px;">
                 <p>Why not enjoy some delicious ',tools::toTitleCase(values$recipe$title),
                  ' tonight? Here is what you\'ll need to prepare this dish:</p>',
                  ingredients_html,
                '</div>'))
  })
}