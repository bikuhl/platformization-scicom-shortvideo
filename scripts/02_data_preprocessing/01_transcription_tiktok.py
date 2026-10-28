"""
Extract audio and transcribe TikTok videos using Whisper large-v3-turbo.
Combines audio extraction (FFmpeg) and transcription in one script.
"""
import os
import subprocess
import torch
from transformers import AutoModelForSpeechSeq2Seq, AutoProcessor, pipeline

# Paths
VIDEO_PATH = "../../data/videos/tiktok"
AUDIO_PATH = "../../data/audio/tiktok"
OUTPUT_PATH = "../../data/transcripts/tiktok"

# Create directories
os.makedirs(AUDIO_PATH, exist_ok=True)
os.makedirs(OUTPUT_PATH, exist_ok=True)

# Setup device (GPU if available)
device = "cuda" if torch.cuda.is_available() else "cpu"
torch_dtype = torch.float16 if device == "cuda" else torch.float32

print(f"Using device: {device}")

# Load Whisper model
model_id = "openai/whisper-large-v3-turbo"
print(f"Loading model: {model_id}")

model = AutoModelForSpeechSeq2Seq.from_pretrained(
    model_id,
    torch_dtype=torch_dtype,
    low_cpu_mem_usage=True,
    use_safetensors=True
).to(device)

processor = AutoProcessor.from_pretrained(model_id)

# Create transcription pipeline
transcribe = pipeline(
    "automatic-speech-recognition",
    model=model,
    tokenizer=processor.tokenizer,
    feature_extractor=processor.feature_extractor,
    torch_dtype=torch_dtype,
    device=device
)

def extract_audio(video_file, audio_file):
    """Extract audio from video using FFmpeg"""
    cmd = [
        'ffmpeg', '-i', video_file,
        '-ar', '16000',      
        '-ac', '1',          
        '-c:a', 'pcm_s16le', 
        audio_file,
        '-y'                
    ]
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

# Get all video files
video_extensions = ('.mp4', '.mkv', '.avi', '.mov', '.flv', '.webm')
video_files = [f for f in os.listdir(VIDEO_PATH) if f.endswith(video_extensions)]

print(f"\nFound {len(video_files)} TikTok videos to process\n")

# Process all videos
for i, video_file in enumerate(video_files, 1):
    input_file = os.path.join(VIDEO_PATH, video_file)
    base_name = os.path.splitext(video_file)[0]
    audio_file = os.path.join(AUDIO_PATH, f"{base_name}.wav")
    output_file = os.path.join(OUTPUT_PATH, f"{base_name}_transcript.txt")
    
    # Skip if already transcribed
    if os.path.exists(output_file):
        print(f"[{i}/{len(video_files)}] Skipping (already exists): {video_file}")
        continue
    
    try:
        # Extract audio
        print(f"[{i}/{len(video_files)}] Processing: {video_file}")
        print(f"  Extracting audio...")
        extract_audio(input_file, audio_file)
        
        # Transcribe
        print(f"  Transcribing...")
        result = transcribe(audio_file)
        
        # Save transcript
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(result["text"])
        
        print(f"  ✓ Transcript saved: {base_name}_transcript.txt")
        
    except Exception as e:
        print(f"  ✗ Error: {e}")
        continue

print(f"\n✓ All TikTok videos processed!")
print(f"  Audio: {AUDIO_PATH}")
print(f"  Transcripts: {OUTPUT_PATH}")