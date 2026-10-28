# Process TikTok Account Metadata from zeeschuimer NDJSON Files
#
# This script processes NDJSON files collected via the zeeschuimer browser extension
# (https://github.com/digitalmethodsinitiative/zeeschuimer)
#
# Input: NDJSON files from zeeschuimer export
# Output: tiktok_account_metadata.csv with all account information
#
# Note: This includes all accounts captured by zeeschuimer (video creators,
# commenters, etc.). Filtering to relevant video creators is done during
# the data merging step.

# Load required libraries
library(ndjson)
library(dplyr)
library(readr)

# Set path to zeeschuimer NDJSON files
folder_path <- "../data/raw/zeeschuimer/TikTok_posts"

# Load all NDJSON files
ndjson_files <- list.files(folder_path, pattern = "\\.ndjson$", full.names = TRUE)

combined_data <- NULL
for (file in ndjson_files) {
  file_data <- ndjson::stream_in(file)
  combined_data <- bind_rows(combined_data, file_data)
}

# Extract only author/account data
author_data_tiktok <- combined_data %>%
  select(starts_with("data.author")) %>%
  distinct()

# Create live status indicator and remove roomId
author_data_tiktok <- author_data_tiktok %>%
  mutate(live = ifelse(!is.na(data.author.roomId), 1, 0)) %>%
  select(-data.author.roomId)

# Rename columns
author_data_tiktok <- author_data_tiktok %>%
  rename(
    ID = data.author.id,
    nickname = data.author.nickname,
    name = data.author.uniqueId,
    description = data.author.signature,
    videos = data.authorStats.videoCount,
    follower = data.authorStats.followerCount,
    following = data.authorStats.followingCount,
    digg = data.authorStats.diggCount,
    friend = data.authorStats.friendCount,
    heart = data.authorStats.heart,
    verified = data.author.verified,
    seller = data.author.ttSeller,
    stitchsetting = data.author.stitchSetting,
    duetsetting = data.author.duetSetting,
    downloadsetting = data.author.downloadSetting,
    commentsetting = data.author.commentSetting,
    avatarlarger = data.author.avatarLarger,
    avatarmedium = data.author.avatarMedium,
    avatarthumb = data.author.avatarThumb
  ) %>%
  select(
    ID, nickname, name, description, videos, follower, following, digg, friend, 
    heart, verified, seller, stitchsetting, duetsetting, downloadsetting, 
    commentsetting, avatarlarger, avatarmedium, avatarthumb, live
  )

# Save processed account metadata
output_file <- "../data/processed/tiktok_account_metadata.csv"
dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
write_csv(author_data_tiktok, output_file)
