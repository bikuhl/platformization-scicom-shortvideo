# Preprocessing

Audio transcription, frame extraction, OCR text extraction, and image captioning for collected videos.

## Overview

This preprocessing pipeline generates structured data from video files:
1. **Audio Transcription** - Convert speech to text using Whisper
2. **Frame Extraction** - Extract frames every 2 seconds using FFmpeg
3. **OCR Text Extraction** - Extract visible text from frames using Tesseract
4. **Image Captioning** - Generate visual descriptions using BLIP-1

---

## Prerequisites

### System Requirements
- **FFmpeg 7.1+** must be installed and in PATH
- **GPU recommended** for faster processing (CUDA-compatible)
- **Tesseract OCR** with German and English language data

### Python Packages
```bash
pip install -r requirements.txt
```

**Key packages:**
- `torch` - PyTorch for deep learning models
- `transformers` - Hugging Face Transformers (Whisper, BLIP)
- `Pillow` - Image processing
- `tqdm` - Progress bars

### R Packages
```r
install.packages(c("tesseract", "magick", "stringr"))
```

---

## Scripts

### 1-2. Audio Transcription

**Files:** 
- `01_transcription_tiktok.py`
- `02_transcription_youtube.py`

**Process:**
1. Extracts audio from videos using FFmpeg (16kHz mono WAV)
2. Transcribes using OpenAI Whisper large-v3-turbo model

**Run:**
```bash
# TikTok
python 01_transcription_tiktok.py

# YouTube Shorts
python 02_transcription_youtube.py
```

**Model:** `openai/whisper-large-v3-turbo` (~1.5GB, downloads on first run)

**Input:** `data/videos/tiktok/` or `data/videos/youtube/`

---

### 3-4. Frame Extraction & OCR

**Files:**
- `03_extract_frames_ocr_tiktok.R`
- `04_extract_frames_ocr_youtube.R`

**Process:**
1. Extracts frames every 2 seconds using FFmpeg
2. Preprocesses frames:
   - Grayscale conversion
   - Contrast enhancement
   - Binary thresholding (50%)
3. Performs OCR with Tesseract (German & English)
4. Removes duplicate consecutive text

**Run:**
```r
# TikTok
Rscript 03_extract_frames_ocr_tiktok.R

# YouTube Shorts
Rscript 04_extract_frames_ocr_youtube.R
```

**Frame preprocessing steps:**
- Convert to grayscale
- Increase contrast (sharpen = 1)
- Apply binary threshold (50% black threshold)
- Minimum 10 characters to be considered valid text

**Input:** `data/videos/tiktok/` or `data/videos/youtube/`

**Note:** Only unique consecutive text is saved (duplicates across frames are removed)

---

### 5-6. Image Captioning

**Files:**
- `05_caption_frames_tiktok.py`
- `06_caption_frames_youtube.py`

**Process:**
Generates textual descriptions of video frames using BLIP-1 image captioning model

**Run:**
```bash
# TikTok
python 05_caption_frames_tiktok.py

# YouTube Shorts
python 06_caption_frames_youtube.py
```

**Model:** `Salesforce/blip-image-captioning-base`

**Frame sampling:** Every other frame (4-second intervals) to reduce processing time

**Input:** `data/frames/tiktok/` or `data/frames/youtube/`

---

## Complete Workflow

### For TikTok videos:
```bash
# 1. Transcribe audio
python 01_transcription_tiktok.py

# 2. Extract frames and OCR text
Rscript 03_extract_frames_ocr_tiktok.R

# 3. Generate frame captions
python 05_caption_frames_tiktok.py
```

### For YouTube Shorts:
```bash
# 1. Transcribe audio
python 02_transcription_youtube.py

# 2. Extract frames and OCR text
Rscript 04_extract_frames_ocr_youtube.R

# 3. Generate frame captions
python 06_caption_frames_youtube.py
```
---

## Notes

- **Frame extraction interval:** 2 seconds (fps=1/2 in FFmpeg)
- **Caption frame sampling:** Every other frame = 4-second intervals
- **OCR preprocessing:** Grayscale → Contrast → Threshold to enhance text visibility
- **Duplicate removal:** OCR removes consecutive identical text across frames
- **Language support:** OCR uses both German and English (Tesseract engines `deu` and `eng`)
- **GPU acceleration:** Automatically used if available (CUDA) for Whisper and BLIP
- **Resumability:** Transcription and captioning scripts skip already processed videos

---

## Data Privacy Note

The preprocessing outputs (transcripts, OCR text, frame captions) are not included in this repository due to copyright restrictions. Researchers can reproduce the preprocessing using the provided scripts.
