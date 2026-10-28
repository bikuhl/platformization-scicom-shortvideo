#' Feature Extraction for Platform Affordances Analysis
#' 
#' This script extracts features related to platform affordances from preprocessed video data:
#' - Algorithmic curation: Hashtags (extraction & classification)
#' - Hypertextuality: Links (internal/external, placement)
#' - Interactivity: Account mentions, Stitch/Duet/Challenge detection
#' - Multimodality: In-app creation, video format, spoken words, text analysis

library(tidyverse)
library(stringr)
library(cld2)
library(stringdist)
library(stopwords)

# ====================================
# CONFIGURATION
# ====================================

# Input paths
METADATA_PATH_TIKTOK <- "../../data/raw/video_metadata/tiktok_metadata_all.csv"
METADATA_PATH_YOUTUBE <- "../../data/raw/video_metadata/youtube_metadata_all.csv"
ACCOUNT_METADATA_TIKTOK <- "../../data/processed/tiktok_account_metadata.csv"
ACCOUNT_METADATA_YOUTUBE <- "../../data/processed/youtube_account_metadata.csv"
TRANSCRIPT_PATH_TIKTOK <- "../../data/transcripts/tiktok"
TRANSCRIPT_PATH_YOUTUBE <- "../../data/transcripts/youtube"
OCR_PATH_TIKTOK <- "../../data/ocr/tiktok"
OCR_PATH_YOUTUBE <- "../../data/ocr/youtube"
HASHTAG_CATEGORIES_PATH <- "hashtag_categories.csv"  # Manual classification of top 100 hashtags

# Output path
OUTPUT_PATH <- "../../data/annotations/extracted_features.csv"

# ====================================
# LOAD DATA
# ====================================

cat("Loading data...\n")

# Video metadata
tiktok_data <- read_csv(METADATA_PATH_TIKTOK, col_types = cols(`Video ID` = col_character()))
youtube_data <- read_csv(METADATA_PATH_YOUTUBE, col_types = cols(`Video ID` = col_character()))

# Account metadata
tiktok_accounts <- read_csv(ACCOUNT_METADATA_TIKTOK)
youtube_accounts <- read_csv(ACCOUNT_METADATA_YOUTUBE)

# Combine platforms
tiktok_data <- tiktok_data %>% mutate(platform = "tiktok")
youtube_data <- youtube_data %>% mutate(platform = "youtube")

total_data <- bind_rows(tiktok_data, youtube_data)

cat(sprintf("Loaded %d videos (%d TikTok, %d YouTube)\n", 
            nrow(total_data), nrow(tiktok_data), nrow(youtube_data)))

# ====================================
# LOAD TRANSCRIPTS
# ====================================

cat("Loading transcripts...\n")

load_transcripts <- function(path, platform) {
  files <- list.files(path, pattern = "\\.txt$", full.names = TRUE)
  
  map_dfr(files, function(file) {
    video_id <- tools::file_path_sans_ext(basename(file))
    text <- read_file(file)
    tibble(`Video ID` = video_id, transcript = text, platform = platform)
  })
}

transcripts_tiktok <- load_transcripts(TRANSCRIPT_PATH_TIKTOK, "tiktok")
transcripts_youtube <- load_transcripts(TRANSCRIPT_PATH_YOUTUBE, "youtube")
transcripts <- bind_rows(transcripts_tiktok, transcripts_youtube)

total_data <- total_data %>%
  left_join(transcripts, by = c("Video ID", "platform"))

# ====================================
# LOAD OCR TEXT
# ====================================

cat("Loading OCR text...\n")

load_ocr <- function(path, platform) {
  files <- list.files(path, pattern = "_ocr\\.txt$", full.names = TRUE)
  
  map_dfr(files, function(file) {
    video_id <- str_remove(basename(file), "_ocr\\.txt")
    text <- read_file(file)
    tibble(`Video ID` = video_id, text_in_video = text, platform = platform)
  })
}

ocr_tiktok <- load_ocr(OCR_PATH_TIKTOK, "tiktok")
ocr_youtube <- load_ocr(OCR_PATH_YOUTUBE, "youtube")
ocr_text <- bind_rows(ocr_tiktok, ocr_youtube)

total_data <- total_data %>%
  left_join(ocr_text, by = c("Video ID", "platform"))

# Join account data
total_data <- total_data %>%
  left_join(
    bind_rows(
      tiktok_accounts %>% mutate(platform = "tiktok"),
      youtube_accounts %>% mutate(platform = "youtube")
    ) %>% select(`Video ID` = ID, account_description = description, platform),
    by = c("Video ID", "platform")
  )

# ====================================
# 1. HASHTAG EXTRACTION
# ====================================

cat("\n=== Extracting Hashtags ===\n")

total_data <- total_data %>%
  mutate(
    hashtags_title = str_extract_all(tolower(Title), "#\\w+"),
    hashtags_description = str_extract_all(tolower(Description), "#\\w+"),
    hashtags_all = map2(hashtags_title, hashtags_description, ~unique(c(.x, .y))),
    n_hashtags = lengths(hashtags_all),
    has_hashtag = n_hashtags > 0
  )

cat(sprintf("  Videos with hashtags: %.1f%%\n", 
            mean(total_data$has_hashtag, na.rm = TRUE) * 100))

# Hashtag categories 
if (file.exists(HASHTAG_CATEGORIES_PATH)) {
  hashtag_category <- read_csv(HASHTAG_CATEGORIES_PATH, col_types = cols())
  
  # Remove last 3 rows if needed
  if (nrow(hashtag_category) > 100) {
    hashtag_category <- hashtag_category[1:(nrow(hashtag_category)-3), ]
  }
  
  # Create binary indicator for platform-specific hashtags
  platform_hashtags <- hashtag_category %>%
    filter(hashtag_category == "platform") %>%
    pull(hashtags_all) %>%
    tolower()
  
  total_data <- total_data %>%
    mutate(
      has_platform_hashtag = map_lgl(hashtags_all, function(tags) {
        any(tolower(tags) %in% platform_hashtags)
      })
    )
  
  cat(sprintf("  Platform-specific hashtags detected (%d unique tags)\n", 
              length(platform_hashtags)))
} else {
  cat("  Warning: Hashtag categories file not found at:", HASHTAG_CATEGORIES_PATH, "\n")
  cat("  Skipping platform-specific hashtag detection\n")
}

# ====================================
# 2. LINK EXTRACTION
# ====================================

cat("\n=== Extracting Links ===\n")

total_data <- total_data %>%
  mutate(
    # Check for links in different locations
    link_in_title = str_detect(Title, "http[s]?://|www\\."),
    link_in_description = str_detect(Description, "http[s]?://|www\\."),
    link_in_transcript = str_detect(transcript, "http[s]?://|www\\."),
    link_in_text_in_video = str_detect(text_in_video, "http[s]?://|www\\."),
    link_in_account_description = str_detect(account_description, "http[s]?://|www\\."),
    
    # Any link anywhere
    has_link_anywhere = link_in_title | link_in_description | link_in_transcript | 
      link_in_text_in_video | link_in_account_description,
    
    # Internal links (platform-specific)
    internal_link_anywhere = case_when(
      platform == "youtube" ~ 
        str_detect(paste(Title, Description, transcript, text_in_video, account_description), 
                   "youtube\\.com|youtu\\.be"),
      platform == "tiktok" ~ 
        str_detect(paste(Title, Description, transcript, text_in_video, account_description), 
                   "tiktok\\.com"),
      TRUE ~ FALSE
    ),
    
    # External links (non-platform)
    external_link_anywhere = has_link_anywhere & !internal_link_anywhere,
    
    # "Link in bio" mentions
    link_in_bio_anywhere = str_detect(
      tolower(paste(Title, Description, transcript, text_in_video, account_description)), 
      "link in bio"
    )
  )

cat(sprintf("  Videos with links: %.1f%%\n", 
            mean(total_data$has_link_anywhere, na.rm = TRUE) * 100))
cat(sprintf("  Videos with 'link in bio': %.1f%%\n", 
            mean(total_data$link_in_bio_anywhere, na.rm = TRUE) * 100))

# ====================================
# 3. ACCOUNT MENTIONS
# ====================================

cat("\n=== Extracting Account Mentions ===\n")

extract_mentions <- function(text, own_account) {
  if (is.na(text)) return(NA_character_)
  
  mentions <- str_extract_all(text, "@\\S+")[[1]]
  
  if (length(mentions) == 0) return(NA_character_)
  
  # Filter out own account
  mentions_clean <- str_remove(mentions, "@") %>% tolower()
  own_clean <- str_remove(own_account, "@") %>% tolower()
  
  mentions_filtered <- mentions[!(mentions_clean %in% own_clean)]
  
  if (length(mentions_filtered) == 0) return(NA_character_)
  
  paste(mentions_filtered, collapse = ", ")
}

total_data <- total_data %>%
  rowwise() %>%
  mutate(
    other_mentions = paste(
      extract_mentions(Title, account_name),
      extract_mentions(Description, account_name),
      extract_mentions(text_in_video, account_name),
      sep = ", "
    ),
    other_mentions = na_if(str_squish(str_remove_all(other_mentions, "NA")), ""),
    other_mentions = na_if(str_squish(other_mentions), ","),
    has_mention = !is.na(other_mentions) & str_detect(other_mentions, "@"),
    n_mentions = if_else(has_mention, str_count(other_mentions, "@"), 0L)
  ) %>%
  ungroup()

cat(sprintf("  Videos with mentions: %.1f%%\n", 
            mean(total_data$has_mention, na.rm = TRUE) * 100))

# ====================================
# 4. STITCH/DUET/CHALLENGE
# ====================================

cat("\n=== Detecting Stitch/Duet/Challenge ===\n")

total_data <- total_data %>%
  mutate(
    # Text to check (platform-specific)
    text_to_check = case_when(
      platform == "tiktok" ~ tolower(paste(Description, text_in_video, sep = " ")),
      platform == "youtube" ~ tolower(paste(Title, Description, sep = " ")),
      TRUE ~ tolower(Description)
    ),
    
    # Stitch
    has_stitch = str_detect(text_to_check, "stitch\\w*"),
    
    # Duet
    has_duet = str_detect(text_to_check, "duet\\w*|duett\\w*"),
    
    # Challenge
    has_challenge = str_detect(text_to_check, "\\w*challenge\\w*"),
    
    # Any collaborative format
    has_collab_format = has_stitch | has_duet | has_challenge
  ) %>%
  select(-text_to_check)

cat(sprintf("  Videos with stitch: %.1f%%\n", 
            mean(total_data$has_stitch, na.rm = TRUE) * 100))
cat(sprintf("  Videos with duet: %.1f%%\n", 
            mean(total_data$has_duet, na.rm = TRUE) * 100))
cat(sprintf("  Videos with challenge: %.1f%%\n", 
            mean(total_data$has_challenge, na.rm = TRUE) * 100))

# ====================================
# 5. SPOKEN WORDS DETECTION
# ====================================

cat("\n=== Detecting Spoken Words ===\n")

detect_speech <- function(transcript) {
  if (is.na(transcript) || transcript == "" || nchar(trimws(transcript)) == 0) {
    return(FALSE)
  }
  
  # Clean text
  text_cleaned <- str_replace_all(transcript, "\\[.*?\\]|\\(.*?\\)", "")
  text_cleaned <- trimws(text_cleaned)
  
  if (nchar(text_cleaned) == 0) return(FALSE)
  
  # Detect language
  detected_lang <- tryCatch(
    cld2::detect_language(text_cleaned),
    error = function(e) NA
  )
  
  # Exclude English (likely music)
  if (!is.na(detected_lang) && detected_lang == "en") return(FALSE)
  
  # Check for music patterns
  music_patterns <- c(
    "♪", "♫", "🎵", "🎶",
    "^(la|na|da|ba|oh|ah)[-\\s]+(la|na|da|ba|oh|ah)",
    "\\b(yeah|oh|ah|ooh)\\b[\\s,]{0,3}\\b(yeah|oh|ah|ooh)\\b"
  )
  
  is_music <- any(sapply(music_patterns, function(p) 
    str_detect(text_cleaned, regex(p, ignore_case = TRUE))))
  
  if (is_music) return(FALSE)
  
  # Count words and check structure
  word_count <- str_count(text_cleaned, "\\b\\w+\\b")
  has_sentence_structure <- str_detect(text_cleaned, "[.!?,;:]")
  
  return(word_count >= 5 & (has_sentence_structure | word_count >= 8))
}

total_data <- total_data %>%
  mutate(has_spoken_words = map_lgl(transcript, detect_speech))

cat(sprintf("  Videos with spoken words: %.1f%%\n", 
            mean(total_data$has_spoken_words, na.rm = TRUE) * 100))

# ====================================
# 6. ON-SCREEN TEXT DETECTION
# ====================================

cat("\n=== Detecting On-Screen Text ===\n")

has_onscreen_text <- function(text_in_video, min_words = 5) {
  if (is.na(text_in_video) || text_in_video == "" || nchar(trimws(text_in_video)) == 0) {
    return(FALSE)
  }
  
  text_clean <- str_squish(str_replace_all(text_in_video, "[[:punct:]]", " "))
  word_count <- str_count(text_clean, "\\S+")
  
  return(word_count >= min_words)
}

total_data <- total_data %>%
  mutate(has_text_onscreen = map_lgl(text_in_video, has_onscreen_text, min_words = 5))

cat(sprintf("  Videos with on-screen text: %.1f%%\n", 
            mean(total_data$has_text_onscreen, na.rm = TRUE) * 100))

# ====================================
# 7. TEXT TYPE CLASSIFICATION
# ====================================

cat("\n=== Classifying Text Type (Speech-to-Text vs. Supplementary) ===\n")

# Stopwords
german_stopwords <- stopwords::stopwords("de", source = "snowball")

# Jaccard similarity
jaccard_similarity <- function(text1, text2, stopwords) {
  if (is.na(text1) || is.na(text2) || text1 == "" || text2 == "") return(NA)
  
  # Clean and tokenize
  clean_text <- function(text) {
    text <- tolower(trimws(text))
    text <- str_replace_all(text, "[[:punct:]]", " ")
    text <- str_squish(text)
    words <- unlist(str_split(text, "\\s+"))
    words[!words %in% stopwords & nchar(words) > 2]
  }
  
  words1 <- clean_text(text1)
  words2 <- clean_text(text2)
  
  if (length(words1) == 0 || length(words2) == 0) return(NA)
  
  intersection <- length(intersect(words1, words2))
  union <- length(union(words1, words2))
  
  return(intersection / union)
}

# Levenshtein similarity
sequence_similarity <- function(text1, text2) {
  if (is.na(text1) || is.na(text2) || text1 == "" || text2 == "") return(NA)
  
  text1_clean <- tolower(str_squish(str_replace_all(text1, "[[:punct:]]", " ")))
  text2_clean <- tolower(str_squish(str_replace_all(text2, "[[:punct:]]", " ")))
  
  if (nchar(text1_clean) == 0 || nchar(text2_clean) == 0) return(NA)
  
  max_length <- max(nchar(text1_clean), nchar(text2_clean))
  lev_dist <- stringdist(text1_clean, text2_clean, method = "lv")
  
  return(1 - (lev_dist / max_length))
}

# Classify text type
classify_text_type <- function(transcript, text_in_video, has_speech, 
                               jaccard_sim, sequence_sim) {
  
  if (is.na(has_speech) || !has_speech) {
    if (is.na(text_in_video) || text_in_video == "" || 
        nchar(trimws(text_in_video)) == 0) {
      return("no_speech")
    } else {
      return("supplementary")
    }
  }
  
  if (is.na(text_in_video) || text_in_video == "" || 
      nchar(trimws(text_in_video)) == 0) {
    return("speech_only")
  }
  
  # Check word count
  text_video_clean <- str_squish(str_replace_all(text_in_video, "[[:punct:]]", " "))
  word_count_video <- str_count(text_video_clean, "\\S+")
  
  if (word_count_video < 5) return("unclear")
  
  if (is.na(jaccard_sim) && is.na(sequence_sim)) return("unclear")
  
  # Average similarity
  avg_similarity <- mean(c(jaccard_sim, sequence_sim), na.rm = TRUE)
  
  if (avg_similarity >= 0.55) {
    return("speech_to_text")
  } else if (avg_similarity >= 0.20) {
    return("mixed")
  } else {
    return("supplementary")
  }
}

cat("  Computing text similarities...\n")

total_data <- total_data %>%
  mutate(
    jaccard_sim = map2_dbl(transcript, text_in_video, jaccard_similarity, 
                           stopwords = german_stopwords),
    sequence_sim = map2_dbl(transcript, text_in_video, sequence_similarity),
    text_type = pmap_chr(list(transcript, text_in_video, has_spoken_words, 
                              jaccard_sim, sequence_sim), 
                         classify_text_type)
  )

cat("  Text type distribution:\n")
print(table(total_data$text_type))

# ====================================
# SAVE RESULTS
# ====================================

cat("\n=== Saving Features ===\n")

# Select relevant columns
features_output <- total_data %>%
  select(
    `Video ID`,
    platform,
    
    # Hashtags
    n_hashtags,
    has_hashtag,
    starts_with("has_") & ends_with("_hashtag"),
    
    # Links
    has_link_anywhere,
    internal_link_anywhere,
    external_link_anywhere,
    link_in_bio_anywhere,
    link_in_title,
    link_in_description,
    link_in_transcript,
    link_in_text_in_video,
    link_in_account_description,
    
    # Mentions
    has_mention,
    n_mentions,
    
    # Collaborative formats
    has_stitch,
    has_duet,
    has_challenge,
    has_collab_format,
    
    # Audio/Text
    has_spoken_words,
    has_text_onscreen,
    text_type,
    jaccard_sim,
    sequence_sim
  )

# Convert logical to binary (0/1)
features_output <- features_output %>%
  mutate(across(where(is.logical), ~as.integer(.)))

write_csv(features_output, OUTPUT_PATH)

cat(sprintf("\n✓ Features saved to: %s\n", OUTPUT_PATH))
cat(sprintf("  Total videos: %d\n", nrow(features_output)))
cat(sprintf("  Features extracted: %d\n", ncol(features_output) - 2))

cat("\nFeature extraction complete!\n")
