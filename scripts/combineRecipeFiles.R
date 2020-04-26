# Combine Recipe Files stored in between

# To be run in the app folder!
files <- list.files(pattern="response_df.rds")
response_df <- NULL
for (file in files) {
  df <- readRDS(file)
  response_df <- rbind(response_df, df)
}
saveRDS(response_df, "response_df.rds")

# Move the files out of this folder
unlink(files[!files %in% 'response_df.rds'])
