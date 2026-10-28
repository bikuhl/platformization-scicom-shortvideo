import openai
import os
import pandas as pd

openai.api_key = os.getenv("OPENAI_API_KEY")

transcript_path = "../../data/transcripts/youtube"
text_in_video_path = "../../data/ocr/youtube"
titles_path = "../../data/raw/video_metadata/youtube_metadata_all.csv"
categories_path = "topic_categories_wos.csv"

categories_df = pd.read_csv(categories_path, sep=";", encoding="utf-8")
categories = categories_df.iloc[:, 0].dropna().tolist()
categories.append("Academic Life")
categories.append("Unclear / Don't know")

def load_transcript(video_id):
    file_path = os.path.join(transcript_path, f"{video_id}_transcript.txt")
    if os.path.exists(file_path):
        with open(file_path, "r", encoding="utf-8") as f:
            return f.read().strip()
    return ""

def load_text_in_video(video_id):
    file_path = os.path.join(text_in_video_path, f"{video_id}_ocr.txt")
    if os.path.exists(file_path):
        with open(file_path, "r", encoding="utf-8") as f:
            return f.read().strip()
    return ""

def load_title_description(video_id, titles_df):
    row = titles_df.loc[titles_df["Video ID"] == video_id]
    if not row.empty:
        title = str(row.iloc[0]["Title"])
        description = str(row.iloc[0].get("Description", ""))
        return title, description
    return "", ""

def determine_category(video_id, transcript, text_in_video, title, description):
    prompt = f"""
You are a helpful assistant with experience in communication science.
You are given multiple information sources about a YouTube video:
- Title: {title}
- Description: {description}
- Transcript (spoken text): {transcript}
- Text inside the video (overlays, captions, embedded text): {text_in_video}

Your task:
0️⃣ First, determine whether the video has a scientific topic. 
   A scientific topic is one related to research, academic fields, scientific methods, experiments, or scholarly work. 
   - If it is NOT a scientific topic, return: **"No Scientific Topic"**.

1️⃣ If there is a scientific topic:
   - If it is about the general work life of scientists (research, teaching, academic career, personal qualification), return: **"Academic Life"**.
   - Otherwise, classify it into one of the following scientific fields:
     {', '.join(categories)}

❌ Important: Do NOT classify general science communication videos as "Education & Educational Research" unless the video specifically discusses education research as a scientific field.

2️⃣ If the content is unclear, overly general, or lacks enough information, return: **"Unclear / Don't know"**.

Return only the single best matching category.
"""
    response = openai.ChatCompletion.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.2
    )
    return response["choices"][0]["message"]["content"].strip()

def process_youtube_videos():
    titles_df = pd.read_csv(titles_path)
    results_file = "../../data/annotations/youtube_topics_run1.csv"

    if os.path.exists(results_file):
        results_df = pd.read_csv(results_file)
    else:
        results_df = pd.DataFrame(columns=["VideoID", "Category"])
        os.makedirs(os.path.dirname(results_file), exist_ok=True)

    processed_videos = set(results_df["VideoID"])

    for i, video_id in enumerate(titles_df["Video ID"], start=1):
        if video_id in processed_videos:
            print(f"Skipping already processed video {video_id}")
            continue

        print(f"Processing ({i}/{len(titles_df)}): {video_id}")
        transcript = load_transcript(video_id)
        text_in_video = load_text_in_video(video_id)
        title, description = load_title_description(video_id, titles_df)

        category = determine_category(video_id, transcript, text_in_video, title, description)

        # Direkt speichern nach jedem Video
        results_df = pd.concat([results_df, pd.DataFrame([{"VideoID": video_id, "Category": category}])], ignore_index=True)
        results_df.to_csv(results_file, index=False)
        print(f"Saved progress after video {video_id}")

    print("Done! Results saved as youtube_categories.csv")

# ---- Run ----
process_youtube_videos()