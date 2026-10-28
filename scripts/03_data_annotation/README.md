# Annotation & Feature Extraction

Content classification, account categorization, and platform affordance feature extraction.

## Overview

This folder contains scripts for:
1. **Topic Classification** - Zero-shot classification of video content by scientific topic
2. **Account Classification** - Categorization of communicator types
3. **Call-to-Participation (CTA) Classification** - Analysis of engagement prompts
4. **Video Format Classification** - Detection of vertical/horizontal, native/repurposed formats
5. **Feature Extraction** - Extraction of platform affordance indicators

**Note:** The scripts in this folder document the automated annotation steps. For the final dataset, communicator types were coded manually by the author.

---

## Scripts Overview

### Python Scripts (01-07)
- **01-02:** Topic classification (GPT-4o mini)
- **03-04:** Account classification (GPT-4o mini)
- **05-06:** CTA/Engagement classification (GPT-4o mini)
- **07:** Video format classification (OpenCV)

### R Script (08)
- **08:** Platform affordance feature extraction

---

## Prerequisites

### For Python Scripts (01-07)

#### Python Packages
```bash
pip install -r requirements.txt
```

#### OpenAI API Key
```bash
export OPENAI_API_KEY="your_api_key_here"
```
Get API key from: https://platform.openai.com/api-keys

### For R Script (08)

#### R Packages
```r
install.packages(c("tidyverse", "stringr", "cld2", "stringdist", "stopwords"))
```

---

## 1-2. Topic Classification

**Files:** 
- `01_classify_topics_tiktok.py`
- `02_classify_topics_youtube.py`

**Method:** Zero-shot classification with GPT-4o mini (temperature=0.2)

**Input:**
- Video titles
- Audio transcripts: `data/transcripts/tiktok/*.txt` or `youtube/*.txt`
- OCR text: `data/ocr/tiktok/*.txt` or `youtube/*.txt`

**Categories:** Based on NOWT classification (Netherlands Observatory of Science and Technology, 2008) from Web of Science, plus:
- **No Scientific Topic** - Content unrelated to science/research
- **Academic Life** - Work life of scientists (research, teaching, career)
- **Unclear / Don't know** - Insufficient information

See `topic_categories_wos.csv` for complete list.

**Process:**
Two independent classification runs with identical prompts for reliability assessment (high agreement). Discrepant cases manually classified. Final dataset: 1,055 videos (586 TikTok + 469 YouTube Shorts). 

---

## 3-4. Account Classification

**Files:**
- `03_classify_accounts_tiktok.py`
- `04_classify_accounts_youtube.py`

**Method:** Zero-shot classification with GPT-4o mini (temperature=0)

**Input:** Account names and descriptions from:
- `data/processed/tiktok_account_metadata.csv`
- `data/processed/youtube_account_metadata.csv`

Categories (automated first pass):

- TIKTOK/YOUTUBE → Content creators
- TIKTOKAC/YOUTUBEAC → Science content creators (merged with TIKTOK/YOUTUBE in the final coding)
- ACADEM → Professional academics 
- STUDENT → Students
- INSTITUTE → Academic institutions
- PUBL → Academic publishers (merged into media/news publishers in the final coding)
- COMPANY → Commercial companies
- MEDIA → Media/news publishers
- OTHER → Others
- N.A → No information available (the prompt rule "EMPTY" was treated as N.A)
- UNCLEAR → Ambiguous classification

**Run:**
```bash
python 03_classify_accounts_tiktok.py
python 04_classify_accounts_youtube.py
```

---

## 5-6. Call-to-Participation (CTA) Classification

**Files:**
- `05_classify_cta_tiktok.py`
- `06_classify_cta_youtube.py`

**Method:** Zero-shot classification with GPT-4o mini (temperature=0)

**Input:**
- Video titles and descriptions
- Audio transcripts
- On-screen text (OCR)
- Frame descriptions

**Categories (Engagement Level):**
- **0 = Not engaging:** No explicit call to action
- **1 = Engaging within platform:** Explicit prompts to like, comment, share, follow
- **2 = Engaging outside platform:** Encouragement to act in real life (try recipe, conduct experiment, political action)
- **3 = Unclear:** Cannot determine engagement level

**Run:**
```bash
python 05_classify_cta_tiktok.py
python 06_classify_cta_youtube.py
```

---

## 7. Video Format Analysis

**File:** `07_classify_video_format.py`

**Method:** OpenCV frame analysis

**Process:**
1. Sample 3 random frames per video
2. Analyze aspect ratio
3. Detect letterboxing/pillarboxing (black bars)

**Classifications:**
- **vertical_native** - Native 9:16 format without black bars
- **vertical_repurposed** - Vertical with letterboxing (horizontal content adapted)
- **horizontal_native** - Native 16:9 format
- **horizontal_repurposed** - Horizontal with pillarboxing
- **square** - Aspect ratio 0.7-1.3

**Run:**
```bash
python 07_analyze_video_format.py
```

**Input:** Video frames from `data/frames/tiktok/` and `youtube/`

---

## 8. Feature Extraction (Platform Affordances)

**File:** `08_extract_features.R`

**Method:** Rule-based extraction and text analysis

**Features extracted:**

### Algorithmic Curation
- **Hashtags:** 
  - Extraction from titles and descriptions
  - Binary indicator: has_hashtag
  - Count: n_hashtags
  - Categories: platform-specific, channel-specific, media format, community, scientific field, scientific work, academia, general science

### Hypertextuality
- **Links:**
  - Detection in: title, description, transcript, on-screen text, account description
  - Binary indicators: has_link_anywhere, internal_link_anywhere, external_link_anywhere
  - "Link in bio" detection: link_in_bio_anywhere
  - Placement indicators: link_in_title, link_in_description, etc.

### Interactivity
- **Account Mentions:**
  - Extraction of @ mentions (excluding self-mentions)
  - Binary indicator: has_mention
  - Count: n_mentions
- **Collaborative Formats:**
  - Stitch detection: has_stitch
  - Duet detection: has_duet
  - Challenge detection: has_challenge
  - Combined: has_collab_format

### Multimodality
- **Spoken Words:**
  - Detection via transcript analysis
  - Language filtering (excludes English = likely music)
  - Music pattern filtering
  - Binary indicator: has_spoken_words
  
- **On-Screen Text:**
  - Detection via OCR (minimum 5 words)
  - Binary indicator: has_text_onscreen
  
- **Text Type Classification:**
  - **speech_to_text:** On-screen text is literal transcription (similarity ≥ 0.55)
  - **mixed:** Combination of transcription and supplementary text (0.20 ≤ similarity < 0.55)
  - **supplementary:** On-screen text adds information not in audio (similarity < 0.20)
  - **speech_only:** Has speech but no on-screen text
  - **no_speech:** No speech detected
  - **unclear:** Cannot determine
  - Similarity metrics: Jaccard similarity (word overlap excluding stopwords), Levenshtein distance

**Run:**
```bash
Rscript 08_extract_features.R
```

**Input:**
- Video metadata: `data/raw/video_metadata/`
- Transcripts: `data/transcripts/tiktok/` and `youtube/`
- OCR text: `data/ocr/tiktok/` and `youtube/`
- Account metadata: `data/processed/`
  
**Note:** Requires preprocessed data (transcripts, OCR) from `02_preprocessing/`

---

## Manual Coding

The following features were manually coded and are not included in the automated scripts:

### Visual Effects
Videos were manually coded for visual effects based on video frames:
- Split screen
- Green screen  
- Stickers
- Emojis (embedded and standalone)
- GIFs
- Comment/question boxes
- Other effects

### Sound Classification
Beyond spoken word detection, sound presence was manually coded:
- Music/instrumental sound
- Ambient sound

### In-App Creation Indicators
Manual coding of platform-specific creation features:
- **TikTok:** Video effects, non-original sound
- **YouTube:** Cuts to long-form content, app-provided music

These manually coded features were integrated into the final dataset during data merging.

---

## Data Privacy

These scripts process only metadata and extracted text. They do **not** share:
- Video files
- Complete transcripts
- Account descriptions
- Any personally identifiable information

Researchers using these scripts are responsible for:
- Compliance with platform Terms of Service
- GDPR and local data protection laws
- Institutional ethics guidelines

