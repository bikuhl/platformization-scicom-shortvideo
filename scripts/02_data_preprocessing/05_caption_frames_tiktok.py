"""
Generate image captions for TikTok video frames using BLIP-1.
Processes every other frame (4-second intervals) and saves descriptions as CSV.
"""
import os
import torch
from transformers import BlipProcessor, BlipForConditionalGeneration
from PIL import Image
from tqdm import tqdm
import pandas as pd

# Paths
FRAME_DIR = "../../data/frames/tiktok"
OUTPUT_DIR = "../../data/captions/tiktok"

# Create output directory
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Setup device
device = "cuda" if torch.cuda.is_available() else "cpu"
print(f"Using device: {device}")

# Load BLIP model
print("Loading BLIP-1 model...")
processor = BlipProcessor.from_pretrained("Salesforce/blip-image-captioning-base")
model = BlipForConditionalGeneration.from_pretrained(
    "Salesforce/blip-image-captioning-base"
).to(device)

# Get already processed videos
existing_outputs = {
    os.path.splitext(f)[0]
    for f in os.listdir(OUTPUT_DIR)
    if f.endswith(".csv")
}

# Get all video folders
video_folders = [
    f for f in os.listdir(FRAME_DIR)
    if os.path.isdir(os.path.join(FRAME_DIR, f))
]

print(f"\nFound {len(video_folders)} TikTok video folders")
print(f"Already processed: {len(existing_outputs)}")
print(f"To process: {len(video_folders) - len(existing_outputs)}\n")

# Process each video folder
for video_folder in tqdm(video_folders, desc="Processing videos"):
    folder_path = os.path.join(FRAME_DIR, video_folder)
    
    # Skip if already processed
    if video_folder in existing_outputs:
        continue
    
    # Get all frame files
    frame_files = sorted([
        f for f in os.listdir(folder_path)
        if f.lower().endswith((".png", ".jpg", ".jpeg"))
    ])
    
    if not frame_files:
        continue
    
    descriptions = []
    
    # Process every other frame (4-second intervals instead of 2)
    for i, frame_file in enumerate(frame_files):
        if i % 2 != 0:
            continue
        
        frame_path = os.path.join(folder_path, frame_file)
        
        try:
            # Load and process image
            raw_image = Image.open(frame_path).convert('RGB')
            inputs = processor(images=raw_image, return_tensors="pt").to(device)
            
            # Generate caption
            out = model.generate(**inputs)
            caption = processor.decode(out[0], skip_special_tokens=True)
            
            descriptions.append({
                "frame": frame_file,
                "description": caption
            })
            
        except Exception as e:
            print(f"Error processing {frame_file}: {e}")
            continue
    
    # Save results as CSV
    if descriptions:
        df = pd.DataFrame(descriptions)
        output_path = os.path.join(OUTPUT_DIR, f"{video_folder}.csv")
        df.to_csv(output_path, index=False, encoding="utf-8")

print(f"\n✓ Caption generation complete!")
print(f"  Output: {OUTPUT_DIR}")