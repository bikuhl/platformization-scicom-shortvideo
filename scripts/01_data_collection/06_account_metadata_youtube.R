# Collect YouTube Account Metadata using YouTube Data API v3
#
# This script retrieves channel metadata for YouTube Shorts creators
# Process:
# 1. Load video metadata to get unique uploaders
# 2. Use YouTube API to get channel IDs
# 3. Retrieve detailed channel information (description, subscribers, etc.)
#
# Requirements: YouTube Data API key from Google Cloud Console
# https://console.cloud.google.com/

# Load required libraries
library(tidyverse)
library(httr)
library(jsonlite)

# YouTube Data API Key
# IMPORTANT: Replace with your own API key or use environment variable
api_key <- Sys.getenv("YOUTUBE_API_KEY")  

if (api_key == "") {
  stop("Please set YOUTUBE_API_KEY environment variable or add your API key to this script")
}

# Load video metadata to get unique channels
youtube_20 <- read_csv("../data/raw/video_metadata/youtube/youtube_metadata_20-21.csv", 
                       col_types = cols(`Video ID` = col_character()))
youtube_21 <- read_csv("../data/raw/video_metadata/youtube/youtube_metadata_21-22.csv", 
                       col_types = cols(`Video ID` = col_character()))
youtube_22 <- read_csv("../data/raw/video_metadata/youtube/youtube_metadata_22-23.csv", 
                       col_types = cols(`Video ID` = col_character()))
youtube_23 <- read_csv("../data/raw/video_metadata/youtube/youtube_metadata_23-24.csv", 
                       col_types = cols(`Video ID` = col_character()))

combined_youtube <- bind_rows(youtube_20, youtube_21, youtube_22, youtube_23)

# Extract unique uploaders
unique_uploaders <- unique(combined_youtube$Uploader)

# Function to get channel information using YouTube API
get_channel_info <- function(api_key, channel_id) {
  url <- paste0("https://www.googleapis.com/youtube/v3/channels?part=snippet,statistics&id=", 
                channel_id, "&key=", api_key)
  
  response <- GET(url)
  
  if (status_code(response) == 200) {
    data <- fromJSON(content(response, "text", encoding = "UTF-8"))
    
    if (length(data$items) > 0) {
      channel_info <- data$items[[1]]
      
      if ("snippet" %in% names(channel_info) && "statistics" %in% names(channel_info)) {
        return(list(
          ID = channel_id,
          nickname = channel_info$snippet$title,
          name = channel_info$snippet$customUrl,
          description = channel_info$snippet$description,
          published = channel_info$snippet$publishedAt,
          videos = as.numeric(channel_info$statistics$videoCount),
          subscriber = as.numeric(channel_info$statistics$subscriberCount),
          views = as.numeric(channel_info$statistics$viewCount),
          language = channel_info$snippet$defaultLanguage,
          country = channel_info$snippet$country
        ))
      }
    }
  }
  
  return(NULL)
}

# Extract channel IDs from video metadata
# YouTube video metadata contains Channel URL, extract ID from it
combined_youtube <- combined_youtube %>%
  mutate(Channel_ID = str_extract(`Channel URL`, "(?<=channel/)[^/]+"))

# Get unique channel IDs
unique_channel_ids <- unique(combined_youtube$Channel_ID) %>% na.omit()

# Collect channel metadata
all_channel_info_list <- list()

for (i in seq_along(unique_channel_ids)) {
  channel_id <- unique_channel_ids[i]
  
  channel_data <- get_channel_info(api_key, channel_id)
  
  if (!is.null(channel_data)) {
    all_channel_info_list <- append(all_channel_info_list, list(channel_data))
  }
  
  # Rate limiting: pause every 50 requests
  if (i %% 50 == 0) {
    Sys.sleep(1)
  }
}

# Convert to dataframe
if (length(all_channel_info_list) > 0) {
  youtube_account_metadata <- bind_rows(all_channel_info_list)
} else {
  stop("No channel data collected")
}

# Save processed account metadata
output_file <- "../data/processed/youtube_account_metadata.csv"
dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
write_csv(youtube_account_metadata, output_file)
