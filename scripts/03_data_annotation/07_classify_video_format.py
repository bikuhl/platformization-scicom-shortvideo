"""
Analyze video format (vertical/horizontal, native/repurposed) using OpenCV.
Examines video frames for aspect ratio and presence of letterboxing/pillarboxing.
"""
import cv2
import numpy as np
import pandas as pd
from pathlib import Path
import random

def analyze_frames_for_format(video_folder, n_frames=3):
    """
    Analyzes PNG frames of a video and detects format
    """
    video_folder = Path(video_folder)
    video_id = video_folder.name
    
    # Find all PNG frames
    frame_files = list(video_folder.glob("*.png"))
    
    if len(frame_files) == 0:
        return {
            'video_id': video_id,
            'status': 'no_frames',
            'n_frames_found': 0,
            'aspect_ratio': None,
            'format_type': 'error'
        }
    
    # Sample random frames (or all if fewer than n_frames)
    sample_size = min(n_frames, len(frame_files))
    sampled_frames = random.sample(frame_files, sample_size)
    
    black_bars_detected = []
    widths = []
    heights = []
    
    for frame_path in sampled_frames:
        # Load frame
        frame = cv2.imread(str(frame_path))
        
        if frame is None:
            continue
        
        height, width = frame.shape[:2]
        widths.append(width)
        heights.append(height)
        
        # Convert to grayscale
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        
        # Check for black bars
        threshold = 15  # Pixels below this value are considered "black"
        
        # Top and bottom 10% of frame
        top_strip = gray[:int(height * 0.1), :]
        bottom_strip = gray[int(height * 0.9):, :]
        
        # Left and right 10% of frame
        left_strip = gray[:, :int(width * 0.1)]
        right_strip = gray[:, int(width * 0.9):]
        
        # Check if predominantly black (>80% of pixels)
        top_black = np.mean(top_strip < threshold) > 0.8
        bottom_black = np.mean(bottom_strip < threshold) > 0.8
        left_black = np.mean(left_strip < threshold) > 0.8
        right_black = np.mean(right_strip < threshold) > 0.8
        
        has_letterbox = top_black and bottom_black
        has_pillarbox = left_black and right_black
        
        black_bars_detected.append({
            'letterbox': has_letterbox,
            'pillarbox': has_pillarbox
        })
    
    if len(widths) == 0:
        return {
            'video_id': video_id,
            'status': 'error_loading',
            'n_frames_found': len(frame_files),
            'aspect_ratio': None,
            'format_type': 'error'
        }
    
    # Average dimensions
    avg_width = np.mean(widths)
    avg_height = np.mean(heights)
    aspect_ratio = avg_width / avg_height if avg_height > 0 else 0
    
    # Analyze black bars
    letterbox_count = sum([d['letterbox'] for d in black_bars_detected])
    pillarbox_count = sum([d['pillarbox'] for d in black_bars_detected])
    
    has_letterbox = letterbox_count > (len(black_bars_detected) * 0.5)
    has_pillarbox = pillarbox_count > (len(black_bars_detected) * 0.5)
    
    # Classification
    if aspect_ratio < 0.7:  # ~9:16 or narrower = Vertical
        if has_letterbox:
            format_type = "vertical_repurposed"
        else:
            format_type = "vertical_native"
    elif aspect_ratio > 1.3:  # ~16:9 or wider = Horizontal
        if has_pillarbox:
            format_type = "horizontal_repurposed"
        else:
            format_type = "horizontal_native"
    else:
        format_type = "square"
    
    return {
        'video_id': video_id,
        'status': 'success',
        'n_frames_found': len(frame_files),
        'n_frames_analyzed': len(black_bars_detected),
        'width': int(avg_width),
        'height': int(avg_height),
        'aspect_ratio': round(aspect_ratio, 3),
        'has_letterbox': has_letterbox,
        'has_pillarbox': has_pillarbox,
        'format_type': format_type
    }

def process_all_videos(base_folder, platforms=['tiktok', 'youtube'], n_frames=3):
    """
    Process all videos for all platforms
    """
    base_folder = Path(base_folder)
    results = []
    
    for platform in platforms:
        platform_folder = base_folder / platform
        
        if not platform_folder.exists():
            print(f"Warning: {platform_folder} does not exist")
            continue
        
        # Find all video folders
        video_folders = [f for f in platform_folder.iterdir() if f.is_dir()]
        
        print(f"\n=== Processing {platform.upper()} ===")
        print(f"Found: {len(video_folders)} video folders")
        
        for i, video_folder in enumerate(video_folders, 1):
            if i % 50 == 0:
                print(f"  Progress: {i}/{len(video_folders)}")
            
            result = analyze_frames_for_format(video_folder, n_frames=n_frames)
            result['platform'] = platform
            results.append(result)
    
    return pd.DataFrame(results)

# Main execution
base_folder = "../../data/frames"

print("Starting video format analysis...")
df_results = process_all_videos(base_folder, platforms=['tiktok', 'youtube'], n_frames=3)

# Save results
output_path = "../../data/annotations/video_format_analysis.csv"
df_results.to_csv(output_path, index=False)

print(f"\n✓ Video format analysis complete!")
print(f"  Results saved to: {output_path}")
print(f"  Total videos analyzed: {len(df_results)}")