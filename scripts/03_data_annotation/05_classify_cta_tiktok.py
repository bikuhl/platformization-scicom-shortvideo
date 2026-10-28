"""
Classify call-to-participation (CTA) in TikTok videos using GPT-4o mini.
Analyzes engagement level based on audio transcripts, and on-screen text.
"""
import pandas as pd
import os
import time
from glob import glob
import openai

openai.api_key = os.getenv("OPENAI_API_KEY")

# Paths
EXCEL_PATH = "../../data/raw/video_metadata/tiktok_metadata_all.csv"
VIDEO_TEXT_DIR = "../../data/ocr/tiktok"
AUDIO_TRANSCRIPT_DIR = "../../data/transcripts/tiktok"
OUTPUT_PATH = "../../data/annotations/tiktok_cta_engagement.csv"

def load_text_file(path):
    if os.path.exists(path):
        with open(path, encoding='utf-8') as f:
            return f.read().strip()
    return ""

def load_video_data(video_id):
    # Text in Video (OCR)
    video_text_path = os.path.join(VIDEO_TEXT_DIR, f"{video_id}_ocr.txt")
    video_text = load_text_file(video_text_path)

    # Audio Transcript
    audio_path = os.path.join(AUDIO_TRANSCRIPT_DIR, f"{video_id}_transcript.txt")
    audio_text = load_text_file(audio_path)

    return video_text, audio_text

def create_prompt(title, video_text, audio_text):
    return f"""
You are a communication scientist analyzing call-to-participation in short videos.

Your task: Classify the engagement level based on explicit calls to action in the video.

=== Codebook: Engagement Level ===
- 0 = Not engaging: The video does not contain any explicit or visible call to action. There are no elements in the audio, text, or visuals that ask viewers to like, comment, share, follow, or do anything beyond watching the video.
- 1 = Engaging within the platform: The video explicitly asks the viewer to like, comment, share, follow, or interact within the platform. These instructions must be clearly stated or strongly implied in the audio, on-screen text, or visual gestures.
- 2 = Engaging outside the platform: The video explicitly encourages viewers to do something in real life, outside of the platform. This may include trying a recipe, conducting an experiment, participating in a political action, or applying health advice. General inspiration or positive mood is not enough.
- 3 = Unclear: It is not possible to determine the level of engagement based on the available content.

Important: If there is no clear evidence for engagement, choose "0".

=== Response Format ===
Engagement Level: <choose from: 0 / 1 / 2 / 3>
Explanation: <brief explanation for your choice>

=== Video Input ===
TITLE: {title}
TEXT ON VIDEO: {video_text}
AUDIO TRANSCRIPT: {audio_text}
"""

def run_gpt4(prompt):
    response = openai.ChatCompletion.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        temperature=0
    )
    return response["choices"][0]["message"]["content"]

# Main processing
if os.path.exists(OUTPUT_PATH):
    results_df = pd.read_csv(OUTPUT_PATH)
    processed_ids = set(results_df['Video.ID'].astype(str))
else:
    results_df = pd.DataFrame(columns=["Video.ID", "Title", "EngagementLevel", "RawOutput"])
    processed_ids = set()
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)

df = pd.read_csv(EXCEL_PATH, dtype={"Video ID": str})

for idx, row in df.iterrows():
    video_id = row["Video ID"]
    title = str(row.get("Title", ""))

    # Skip if already processed
    if video_id in processed_ids:
        continue

    print(f"\nProcessing video: {video_id}")

    try:
        # Load video text, and audio transcript
        video_text, audio_text = load_video_data(video_id)

        # Create prompt for GPT
        prompt = create_prompt(title, video_text, audio_text)
        response = run_gpt4(prompt)

        # Default value
        engage = "ERROR"

        # Extract result from GPT output
        for line in response.splitlines():
            if "Engagement Level:" in line:
                engage = line.split(":", 1)[-1].strip()
                break

        # Add result to DataFrame
        results_df = pd.concat([results_df, pd.DataFrame([{
            "Video.ID": video_id,
            "Title": title,
            "EngagementLevel": engage,
            "RawOutput": response
        }])], ignore_index=True)

        # Save results
        results_df.to_csv(OUTPUT_PATH, index=False, encoding='utf-8')
        print(f"Saved result for {video_id} — Engagement: {engage}")

        time.sleep(1)

    except Exception as e:
        print(f"Error processing {video_id}: {e}")