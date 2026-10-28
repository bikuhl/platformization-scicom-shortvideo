"""
Download YouTube Shorts video metadata using yt-dlp
Note: This script was executed to collect the data, which was then 
manually split by academic year into separate CSV files.
"""

import yt_dlp
import pandas as pd
import os

# Create output directory for videos
os.makedirs('../data/raw/video_metadata', exist_ok=True)

# Load URLs
with open('../data/raw/youtube_urls.txt', 'r', encoding='utf-8') as f:
    youtube_urls = f.read().splitlines()

print(f"Total URLs: {len(youtube_urls)}")

# List to store metadata
metadata_list = []

# yt-dlp options
ydl_opts = {
    'format': 'best',
    'outtmpl': '../data/videos/youtube/%(id)s.%(ext)s',
    'noplaylist': True,
    'quiet': False,
    'no_warnings': False,
}

# Download videos and extract metadata
with yt_dlp.YoutubeDL(ydl_opts) as ydl:
    for i, url in enumerate(youtube_urls, 1):
        try:
            print(f"Processing {i}/{len(youtube_urls)}: {url}")
            info_dict = ydl.extract_info(url, download=True)
            
            video_metadata = {
                'Video ID': info_dict.get('id'),
                'Title': info_dict.get('title'),
                'Description': info_dict.get('description'),
                'Uploader': info_dict.get('uploader'),
                'Uploader ID': info_dict.get('uploader_id'),
                'Channel URL': info_dict.get('channel_url'),
                'Upload Date': info_dict.get('upload_date'),
                'Views': info_dict.get('view_count'),
                'Likes': info_dict.get('like_count'),
                'Comments': info_dict.get('comment_count'),
            }
            metadata_list.append(video_metadata)
            
        except Exception as e:
            print(f"Error processing {url}: {e}")
            metadata_list.append({
                'Video ID': url,
                'Title': 'ERROR',
                'Error': str(e)
            })
            continue

# Convert metadata to DataFrame
df = pd.DataFrame(metadata_list)

# Save DataFrame as CSV
df.to_csv('../data/raw/video_metadata/youtube_metadata_all.csv', index=False, encoding='utf-8')
