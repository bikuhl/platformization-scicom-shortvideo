# Platformization of science communication on TikTok and YouTube Shorts

This repository contains code and data for a computational analysis of how science communicators adapt to short-video platform affordances on TikTok and YouTube Shorts.

## About

Short-video platforms have become crucial channels for science communication, but require adaptation to platform-specific affordances and logics. This study examines affordance alignment patterns across 1,055 German science-related videos using a combination of automated and manual methods. Drawing on the concept of platform affordances, the study analyzes four dimensions:
- **Algorithmic curation** (presence of hashtags, platform-specific hashtags)
- **Hypertextuality** (absence of links)
- **Interactivity** (call-to-participation, account referencing)
- **Multimodality** (in-app production, vertical format, visual effects, sound, on-screen text)

In addition, the study categorizes content and communicators and investigates associations between affordance alignment and engagement metrics, as well as differences and temporal trends between the platforms.

## Repository Structure

```
platformization-scicom-shortvideo/
├── README.md                                 # This file
├── LICENSE                                   # License
│
├── data/
│   ├── platformization_dataset.csv          # Final dataset (N = 1,055)
│   └── CODEBOOK.md                          # Variable descriptions
│
└── scripts/
    ├── 01_data_collection/
    │   ├── README.md                        # Collection procedure documentation
    │   ├── requirements.txt                 # Python dependencies
    │   ├── 01_collect_urls_tiktok.py        # TikTok URL collection
    │   ├── 02_collect_urls_youtube.py       # YouTube URL collection
    │   ├── 03_video_metadata_tiktok.py      # TikTok metadata extraction
    │   ├── 04_video_metadata_youtube.py     # YouTube metadata extraction
    │   ├── 05_account_metadata_tiktok.R     # TikTok account data
    │   └── 06_account_metadata_youtube.R    # YouTube account data
    │
    ├── 02_data_preprocessing/
    │   ├── README.md                        # Preprocessing documentation
    │   ├── requirements.txt                 # Python dependencies
    │   ├── 01_transcription_tiktok.py       # Audio transcription (TikTok)
    │   ├── 02_transcription_youtube.py      # Audio transcription (YouTube)
    │   ├── 03_extract_frames_ocr_tiktok.R   # Frame extraction & OCR (TikTok)
    │   ├── 04_extract_frames_ocr_youtube.R  # Frame extraction & OCR (YouTube)
    │   ├── 05_caption_frames_tiktok.py      # Image captioning (TikTok)
    │   └── 06_caption_frames_youtube.py     # Image captioning (YouTube)
    │
    ├── 03_data_annotation/
    │   ├── README.md                        # Annotation documentation
    │   ├── requirements.txt                 # Python dependencies
    │   ├── 01_classify_topics_tiktok.py     # Topic classification (TikTok)
    │   ├── 02_classify_topics_youtube.py    # Topic classification (YouTube)
    │   ├── 03_classify_accounts_tiktok.py   # Account classification (TikTok)
    │   ├── 04_classify_accounts_youtube.py  # Account classification (YouTube)
    │   ├── 05_classify_cta_tiktok.py        # Call-to-participation (TikTok)
    │   ├── 06_classify_cta_youtube.py       # Call-to-participation (YouTube)
    │   ├── 07_classify_video_format.py      # Video format classification
    │   ├── 08_extract_features.R            # Feature extraction
    │   └── topic_categories_wos.csv         # Web of Science topic categories
    │
    └── 04_data_analysis/
        ├── README.md                        # Analysis documentation
        └── 01_data_analysis.R               # Analysis script (tables and figures)
```

## Data availability

The final dataset contains derived variables only. Video IDs, URLs, account names, titles, descriptions, and transcripts are not included. Due to copyright restrictions and the platforms' Terms of Service, intermediate data files (downloaded videos, transcripts, frame captures) are not provided. The scripts in `scripts/01` to `03` document the collection, preprocessing, and annotation steps and can be adapted for similar studies; videos must be collected independently.
