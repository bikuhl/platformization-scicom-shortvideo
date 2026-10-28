#' Extract frames from TikTok videos and perform OCR text extraction
#' 
#' This script:
#' 1. Extracts frames every 2 seconds using FFmpeg
#' 2. Preprocesses frames (grayscale, contrast, threshold)
#' 3. Performs OCR with Tesseract (German & English)
#' 4. Removes duplicate consecutive text

# Load libraries
library(tesseract)
library(magick)
library(stringr)

# Paths
video_dir <- "../../data/videos/tiktok"
frame_dir <- "../../data/frames/tiktok"
ocr_dir <- "../../data/ocr/tiktok"

# Create directories
dir.create(frame_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(ocr_dir, showWarnings = FALSE, recursive = TRUE)

# Find all video files
video_files <- list.files(video_dir, pattern = "\\.mp4$", full.names = TRUE)

cat("Found", length(video_files), "TikTok videos to process\n\n")

# OCR engine (German & English)
ocr_engine <- tesseract(c("deu", "eng"))

# Frame preprocessing and OCR
process_frame <- function(image_path, min_chars = 10) {
  img <- image_read(image_path) %>%
    image_convert(colorspace = "gray") %>%
    image_contrast(sharpen = 1) %>%
    image_threshold(type = "black", threshold = "50%")
  
  text <- ocr(img, engine = ocr_engine) %>%
    str_squish()
  
  if (nchar(text) >= min_chars) return(text) else return("")
}

# Process each video
for (i in seq_along(video_files)) {
  video_path <- video_files[i]
  video_name <- tools::file_path_sans_ext(basename(video_path))
  frame_subdir <- file.path(frame_dir, video_name)
  dir.create(frame_subdir, showWarnings = FALSE)
  
  cat(sprintf("[%d/%d] Processing: %s\n", i, length(video_files), video_name))
  
  # Extract frames (every 2 seconds, fps=1/2)
  ffmpeg_cmd <- sprintf('ffmpeg -i "%s" -vf fps=1/2 "%s/frame_%%03d.png" -loglevel quiet',
                        video_path, frame_subdir)
  system(ffmpeg_cmd)
  
  # Get all frames
  frame_files <- list.files(frame_subdir, pattern = "\\.png$", full.names = TRUE)
  frame_files <- sort(frame_files)
  
  if (length(frame_files) == 0) {
    cat("  No frames extracted, skipping\n")
    next
  }
  
  cat(sprintf("  Extracted %d frames\n", length(frame_files)))
  
  # OCR with duplicate removal
  previous_text <- ""
  combined_text <- character()
  
  for (frame in frame_files) {
    text <- process_frame(frame)
    
    # Only keep text that differs from previous frame
    if (text != "" && text != previous_text) {
      combined_text <- c(combined_text, text)
      previous_text <- text
    }
  }
  
  # Save OCR output
  if (length(combined_text) > 0) {
    ocr_file <- file.path(ocr_dir, paste0(video_name, "_ocr.txt"))
    writeLines(combined_text, ocr_file)
    cat(sprintf("  ✓ Saved %d unique text segments\n", length(combined_text)))
  } else {
    cat("  No text detected\n")
  }
}
