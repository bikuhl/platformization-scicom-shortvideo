"""
Download TikTok video metadata using yt-dlp
Note: This script was executed to collect the data, which was then 
manually split by academic year into separate CSV files.
"""

import yt_dlp
import pandas as pd
import os

# Create output directory for videos
os.makedirs('../data/raw/video_metadata', exist_ok=True)

# Load TikTok URLs from file
with open('../data/raw/tiktok_urls.txt', 'r', encoding='utf-8') as f:
    tiktok_urls = f.read().splitlines()

# Filter: Only URLs containing '/video/'
filtered_urls = [url for url in tiktok_urls if '/video/' in url]

print(f"Total URLs: {len(tiktok_urls)}")
print(f"Filtered URLs (with '/video/'): {len(filtered_urls)}")

# List to store metadata
metadata_list = []

# yt-dlp options
ydl_opts = {
    'format': 'best',
    'outtmpl': '../data/videos/tiktok/%(id)s.%(ext)s',
    'noplaylist': True,
    'quiet': False,
    'no_warnings': False,
}

# Download videos and extract metadata
with yt_dlp.YoutubeDL(ydl_opts) as ydl:
    for i, url in enumerate(filtered_urls, 1):
        try:
            print(f"Processing {i}/{len(filtered_urls)}: {url}")
            info_dict = ydl.extract_info(url, download=True)
            
            video_metadata = {
                'Video ID': info_dict.get('id'),
                'Title': info_dict.get('title'),
                'Description': info_dict.get('description'),
                'Uploader': info_dict.get('uploader'),
                'Uploader Description': info_dict.get('uploader_url', 'N/A'), 
                'Upload Date': info_dict.get('upload_date'),
                'Views': info_dict.get('view_count'),
                'Likes': info_dict.get('like_count'),
                'Comments': info_dict.get('comment_count'),
                'Shares': info_dict.get('repost_count'),  
                'Bookmarks': info_dict.get('bookmark_count'),  
            }
            metadata_list.append(video_metadata)
            
        except Exception as e:
            print(f"Error processing {url}: {e}")
            metadata_list.append({
                'Video ID': url,
                'Title': 'ERROR',
                'Description': 'N/A',
                'Uploader': 'N/A',
                'Uploader Description': 'N/A',
                'Upload Date': 'N/A',
                'Views': None,
                'Likes': None,
                'Comments': None,
                'Shares': None,
                'Bookmarks': None,
                'Error': str(e)
            })
            continue

# Convert metadata to DataFrame
df = pd.DataFrame(metadata_list)

# Save DataFrame as CSV
df.to_csv('../data/raw/video_metadata/tiktok_metadata_all.csv', index=False, encoding='utf-8')
