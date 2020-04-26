# Generate Grocery Products "Database"

# Investigating the names of the ingredients provided by the Spoonacular API, 
# they are often quite precise (pork loin chops, fingerling potatoes) rather then general.
# So we better use general product names and filter later by grepl not full name
products <- c('apples', # sensor product
              'tomatoes', # sensor product
              'potatoes', # sensor product
              'chicken',
              'pork',
              'mushrooms',
              'sweet potatoes',
              'spring onions',
              'rhubarb',
              'lettuce',
              'sour cream',
              'beer',
              'carrots',
              'bell pepper')
# Units, make sense for the price display I think
units <- c('kg',
           'kg',
           'kg',
           'package',
           'package',
           'package',
           'kg',
           'package',
           'kg',
           'piece',
           'bottle',
           '20-pack',
           'kg',
           'package')
# Meat, vegetables, fruits, carbs, dairy
types <- c('fruit',
          'vegetable',
          'carb',
          'meat',
          'meat',
          'vegetable',
          'carb',
          'vegetable',
          'vegetable',
          'vegetable',
          'dairy',
          'alcohol',
          'vegetable',
          'vegetable')
# Either random price or price from the local supermarket magazine
prices <- c(sample(seq(0.49, 3.49, by=0.1),1), 
            sample(seq(0.49, 3.49, by=0.1),1), 
            sample(seq(0.49, 3.49, by=0.1),1),
            2.99,
            4.49,
            1.29,
            2.79,
            0.79,
            1.79,
            1.19,
            0.99,
            12.40,
            1.49,
            2.79)
# We can mix around a bit, base it a bit on the supermarket magazine again            
discounts <- c(0.1,0,0.16,0.23,0.15,0.13,0.20,0.25,0.35,0,0.3,0.23,0.11,0)
shelftime <- c(0,0,0,0,0,0,0,0,0,0,0,0,0,0)

products <- as.data.frame(x = list(product = products,
                              unit = units,
                              type = types,
                              price = prices,
                              discount = discounts,
                              shelftime = shelftime),
                          stringsAsFactors = F)

saveRDS(products, 'products.rds')
