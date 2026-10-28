import openai
import os
import pandas as pd

openai.api_key = os.getenv("OPENAI_API_KEY")

input_file = "../../data/processed/youtube_account_metadata.csv"
output_file = "../../data/annotations/youtube_account_categories.csv"

account_categories = {
    "YOUTUBE": "Active YouTubers. Channels managed by one or more individuals who produce self-produced YouTube videos (semi-)professionally or regularly with an established online presence. They typically provide descriptions of their focus/motivation or are identifiable via external sources (Wikipedia, other social media). Content should primarily be original, not just TV-material reuploads or compilations.",
    "YOUTUBEAC": "YouTubers with academic background. Same as YOUTUBE, but with identifiable academic degree(s) (Bachelor, Master, PhD, etc.). Includes former researchers or academics who no longer work in academia.",
    "ACADEM": "Professional academics. Researchers (including PhD candidates) with institutional affiliation (universities, research institutes, industry R&D). Includes lecturers, teachers, and group/project/team channels where all members have academic affiliation.",
    "STUDENT": "Students. Accounts by undergraduate/graduate students or channels where videos are clearly produced as class assignments.",
    "INSTITUTE": "Academic institution. Accounts hosted by institutions or their subdivisions (universities, research departments, government agencies focusing on research, libraries, professional associations). Excludes small research groups/projects (→ ACADEM).",
    "PUBL": "Academic publishers. Channels of academic publishers, journals, preprint servers, or academic associations acting mainly as publishers.",
    "COMPANY": "Commercial companies or non-profit organizations. Channels used for promoting products, services, or organizational activities (semi-commercial or non-profit included).",
    "MEDIA": "Media / news publishers. Commercial media companies or journalistic entities with established media presence beyond YouTube (mainstream media, public broadcasters, digital-native outlets like Buzzfeed). Also includes journalists clearly affiliated with these outlets.",
    "OTHER": "Other. Accounts not fitting into any of the above categories.",
    "N.A": "No information available. No identifiable data on account or persons behind it. Example: description missing, no personal appearance, no clues.",
    "UNCLEAR": "No clear assignment possible. The description provides no clear clues or allows multiple possible assignments."
}

df = pd.read_csv(input_file, encoding="utf-8")

if os.path.exists(output_file):
    results_df = pd.read_csv(output_file, encoding="utf-8")
    processed_channels = set(results_df["Channel"])
else:
    results_df = pd.DataFrame(columns=["Channel", "Description", "Category"])
    processed_channels = set()
    os.makedirs(os.path.dirname(output_file), exist_ok=True)

def annotate_account(channel, description):
    """Bestimme Kategorie für einen Social Media Account anhand der Beschreibung."""
    prompt = f"""
    You are a helpful assistant with experience in communication science.
    Your task is to assign the best fitting category to the following social media account.

    Account name: {channel}
    Description: {description}

    Categories and definitions:
    {chr(10).join([f"- {k}: {v}" for k,v in account_categories.items()])}

    Rules:
    - Choose exactly ONE category.
    - If description is completely empty → choose "EMPTY".
    - If description contains information but is ambiguous or fits multiple categories equally well → choose "UNCLEAR".
    - Otherwise return the single best matching category.

    Return ONLY the category keyword (e.g., YOUTUBE, ACADEM, EMPTY).
    """

    response = openai.ChatCompletion.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        temperature=0
    )

    return response["choices"][0]["message"]["content"].strip()


# Loop über alle Accounts, nur die noch nicht bearbeiteten
for i, row in df.iterrows():
    channel = row["name"]
    description = row["description"]

    if channel in processed_channels:
        continue  # bereits erledigt, überspringen

    print(f"Annotating ({i+1}/{len(df)}): {channel}")
    category = annotate_account(channel, description)

    # Ergebnis anhängen
    results_df = pd.concat([results_df, pd.DataFrame([{
        "Channel": channel,
        "Description": description,
        "Category": category
    }])], ignore_index=True)

    # Zwischenspeichern nach jedem Schritt
    results_df.to_csv(output_file, index=False, encoding="utf-8")

print("Fertig! Ergebnisse gespeichert unter:", output_file)
