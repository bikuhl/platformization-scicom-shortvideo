# Data Collection

Collection of German science-related videos from TikTok and YouTube Shorts.

## Collection Period
September 1, 2020 - August 31, 2024

## Search Strategy
Automated Google searches in incognito mode for:
- `forschung OR wissenschaft site:tiktok.com`
- `forschung OR wissenschaft site:youtube.com/shorts/`

Up to 250 unique URLs collected per platform per year.

---

## Scripts Overview

### Python Scripts (URL & Video Metdata Collection)
1. **`01_collect_urls_tiktok.py`** - Collect TikTok video URLs via Google search
2. **`02_collect_urls_youtube.py`** - Collect YouTube Shorts URLs via Google search
3. **`03_video_metadata_tiktok.py`** - Download TikTok videos and metadata using yt-dlp
4. **`04_video_metadata_youtube.py`** - Download YouTube Shorts videos and metadata using yt-dlp

### R Scripts (Account Metadata)
5. **`05_account_metadata_tiktok.R`** - Collect TikTok account metadata from zeeschuimer
6. **`06_account_metadata_youtube.R`** - Collect YouTube account metadata via API

---

## Prerequisites

### For Python Scripts (01-04)

#### Firefox Browser
Scripts require Firefox browser to be installed.

#### Geckodriver
Selenium needs geckodriver for Firefox:
- **Windows/Mac:** Download from https://github.com/mozilla/geckodriver/releases
- **Linux:** `sudo apt install firefox-geckodriver`

Make sure geckodriver is in your PATH.

#### Python Packages
```bash
pip install -r requirements.txt
```

**requirements.txt:**
```
selenium>=4.0.0
beautifulsoup4>=4.0.0
requests>=2.0.0
yt-dlp>=2024.0.0
pandas>=2.0.0
```

### For R Scripts (05-06)

#### R Packages
```r
install.packages(c("ndjson", "dplyr", "readr", "tidyverse", "httr", "jsonlite"))
```

---

## Usage

### Step 1: Collect Video URLs

**TikTok:**
```bash
python 01_collect_urls_tiktok.py
```

**YouTube:**
```bash
python 02_collect_urls_youtube.py
```

---

### Step 2: Download Videos and Metadata

**TikTok:**
```bash
python 03_video_metadata_tiktok.py
```

**YouTube:**
```bash
python 04_video_metadata_youtube.py
```
#### Collected Metadata
- Video ID, title, description
- Uploader information
- Upload date
- Engagement metrics: views, likes, comments

#### Note on Data Splitting
The downloaded metadata was manually split by academic year into separate CSV files after collection. The scripts produce single files.

---

### Step 3: Collect Account Metadata

#### TikTok Accounts (zeeschuimer)

**File:** `05_account_metadata_tiktok.R`

**Method:** Process NDJSON files from zeeschuimer browser extension

**Steps:**
1. Install zeeschuimer: https://github.com/digitalmethodsinitiative/zeeschuimer
2. Collect TikTok posts via browser extension while browsing TikTok
3. Export NDJSON files to `data/raw/zeeschuimer/TikTok_posts/`
4. Run processing script:
```r
   Rscript 05_account_metadata_tiktok.R
```
---

#### YouTube Accounts (API)

**File:** `06_account_metadata_youtube.R`

**Method:** YouTube Data API v3

**Prerequisites:**
1. Get API key from Google Cloud Console: https://console.cloud.google.com/
2. Enable YouTube Data API v3 for your project
3. Set environment variable:
```bash
   export YOUTUBE_API_KEY="your_api_key_here"
```
   Or add directly to script (line 18)

**Input:** Video metadata CSVs (requires Step 2 to be completed)

**Run:**
```r
Rscript 06_account_metadata_youtube.R
```

---

## Data Availability

### Provided in Repository
- Collection scripts (all 6 scripts)
- The final, anonymized dataset (`data/platformization_dataset.csv`) and codebook (`CODEBOOK.md`)

### Not Included
- Video URLs
- Video files
- Raw metadata (titles, descriptions, uploader names)
- Account metadata (channel names, descriptions)

**Rationale:** Video URLs contain account names, and video files and raw metadata are subject to copyright and the platforms' Terms of Service. The final dataset contains derived variables only. The search queries and collection scripts allow researchers to collect equivalent data in line with current platform policies.
