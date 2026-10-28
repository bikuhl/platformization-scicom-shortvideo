# Codebook: Platformization of science communication in short videos

- **Dataset**: platformization_dataset.csv
- **N**: 1,055 videos
- **Platforms**: TikTok (n = 586), YouTube Shorts (n = 469)
- **Collection period**: Videos published September 2020 – August 2024

Video IDs, URLs, and account names are not included. Missing values are coded as `NA`.

## 1. Video Identifiers

| Variable | Type | Description | Values/Range |
|---|---|---|---|
| Row_id | Integer | Anonymous running number (ordered by upload date) | 1 – 1055 |
| Platform | Categorical | Video platform (Shorts = YouTube Shorts) | TikTok, Shorts |

## 2. Temporal Information

| Variable | Type | Description | Values/Range |
|---|---|---|---|
| Upload_date | Date | Video upload date | YYYY-MM-DD |
| Period | Categorical | Upload period (September to August) | 2020-2021, 2021-2022, 2022-2023, 2023-2024 |

## 3. Engagement Metrics

| Variable | Type | Description | Values/Range |
|---|---|---|---|
| Views | Integer | Number of views | 5 – 11,300,000 |
| Likes | Integer | Number of likes | 0 – 1,200,000 |
| Comments | Integer | Number of comments | 0 – 20,500 |

## 4. Content Classification

| Variable | Type | Description | Values/Range |
|---|---|---|---|
| Discipline | Categorical | Aggregated discipline of the video's scientific topic | Medical & life sciences, Natural sciences, Engineering sciences, Social & behavioral sciences, Language, information & communication, Law, arts & humanities, Multiple disciplines, Academic work |

## 5. Communicator Information

| Variable | Type | Description | Values/Range |
|---|---|---|---|
| Account_category | Categorical | Type of communicator (manually coded). Content creators = accounts with more than 10,000 followers/subscribers; accounts below this threshold or without follower information = Others | Professional academics, Content creators, Media/news publishers, Academic institutions, Commercial companies, Students, Political/public actors/institutions, Others, No information available |
| follower | Integer | Followers (TikTok) or subscribers (Shorts) of the account at data collection; YouTube values are rounded as displayed by the platform; NA for 69 videos | 4 – 2,500,000 |

## 6. Platformization Indicators

### 6.1 Algorithmic Curation

| Variable | Type | Description | Values/Range |
|---|---|---|---|
| Has_hashtag | Binary | At least one hashtag in title or description | 0 = No, 1 = Yes |
| Has_platform_hashtag | Binary | At least one platform-specific hashtag indicating viral content | 0 = No, 1 = Yes |

### 6.2 Hypertextuality

| Variable | Type | Description | Values/Range |
|---|---|---|---|
| Link_in_title | Binary | Link present in video title | 0 = No, 1 = Yes |
| Link_in_description | Binary | Link present in video description | 0 = No, 1 = Yes |
| Link_in_transcript | Binary | Link mentioned in spoken audio | 0 = No, 1 = Yes |
| Link_in_text_in_video | Binary | Link visible in on-screen text | 0 = No, 1 = Yes |
| Link_in_account_description | Binary | Link in account description | 0 = No, 1 = Yes |
| Has_link_anywhere | Binary | Link present in any of the locations above | 0 = No, 1 = Yes |
| Internal_link_anywhere | Binary | Link to the same platform | 0 = No, 1 = Yes |
| External_link_anywhere | Binary | Link to an external website | 0 = No, 1 = Yes |
| Cut | Categorical | YouTube Cut feature (Shorts only) | 0 = Not used, Cut = Cut from long-form video, Cut:Short = Cut from other Short, NA = TikTok |

### 6.3 Interactivity

| Variable | Type | Description | Values/Range |
|---|---|---|---|
| Call_to_participation | Categorical | Type of call to participation | 0 = None, 1 = Within the platform, 2 = Outside the platform |
| Has_mention | Binary | Mentions another account (@) in title, description, or on-screen text | 0 = No, 1 = Yes |
| Has_stitch | Binary | Keyword "stitch" in title or description | 0 = No, 1 = Yes |
| Has_duet | Binary | Keyword "duet" in title or description | 0 = No, 1 = Yes |
| Has_challenge | Binary | Keyword "challenge" in title or description (imitation-type challenges identified manually) | 0 = No, 1 = Yes |

### 6.4 Multimodal Format

**Audio/Sound**

| Variable | Type | Description | Values/Range |
|---|---|---|---|
| Music_ambient | Binary | Music or ambient sound present | 0 = No, 1 = Yes |
| InApp_sound | Binary | Platform-provided music used | 0 = No, 1 = Yes |
| Has_spoken_words | Binary | Spoken language detected | 0 = No, 1 = Yes |
| Audio_composition | Categorical | Combination of speech and music/ambient sound; other = neither or undetermined | speech_and_music, speech_only, music_only, other |

**Visual Production**

| Variable | Type | Description | Values/Range |
|---|---|---|---|
| Has_in_app | Binary | Created using in-app features (TikTok: video effect or platform sound; Shorts: Cut feature or YouTube music) | 0 = No, 1 = Yes |
| InApp_effect | Binary | At least one in-app video effect used | 0 = No, 1 = Yes |
| Format_type | Categorical | Video orientation and origin | vertical_native, vertical_repurposed, square, horizontal_native, horizontal_repurposed |
| Is_vertical | Binary | Vertical format (native or repurposed) | 0 = No, 1 = Yes |
| Has_any_effect | Binary | At least one visual effect | 0 = No, 1 = Yes |
| Effect_stickers | Binary | Stickers/overlays present | 0 = No, 1 = Yes |
| Effect_split_screens | Binary | Split-screen effect | 0 = No, 1 = Yes |
| Effect_GIFs | Binary | Animated GIFs present | 0 = No, 1 = Yes |
| Effect_emojis | Binary | Emojis present | 0 = No, 1 = Yes |
| Effect_comment | Binary | Comment boxes shown | 0 = No, 1 = Yes |
| Effect_green_screen | Binary | Green screen effect | 0 = No, 1 = Yes |
| Effect_other | Binary | Other visual effects | 0 = No, 1 = Yes |

**Text**

| Variable | Type | Description | Values/Range |
|---|---|---|---|
| Has_text_onscreen | Binary | On-screen text present (at least 5 words) | 0 = No, 1 = Yes |
| Text_type | Categorical | Relationship between on-screen text and speech | speech_to_text = Literal transcription, supplementary = Additional information, mixed = Both, speech_only = Speech without sufficient on-screen text, no_speech = No speech, unclear = Cannot classify |

## 7. Affordance Alignment Index

| Variable | Type | Description | Values/Range |
|---|---|---|---|
| plat_hashtag | Binary | At least one hashtag (from Has_hashtag) | 0 = No, 1 = Yes |
| plat_platform_hashtag | Binary | Platform-specific hashtag (from Has_platform_hashtag) | 0 = No, 1 = Yes |
| plat_no_link | Binary | No link (inverted Has_link_anywhere) | 0 = No, 1 = Yes |
| plat_ctp | Binary | Call to participation (Call_to_participation = 1 or 2) | 0 = No, 1 = Yes |
| plat_mention | Binary | Mentions another account (from Has_mention) | 0 = No, 1 = Yes |
| plat_in_app | Binary | In-app production (from Has_in_app) | 0 = No, 1 = Yes |
| plat_vertical | Binary | Vertical format (from Is_vertical) | 0 = No, 1 = Yes |
| plat_effect | Binary | At least one visual effect (from Has_any_effect) | 0 = No, 1 = Yes |
| plat_music | Binary | Music or ambient sound (from Music_ambient) | 0 = No, 1 = Yes |
| plat_text | Binary | On-screen text (from Has_text_onscreen) | 0 = No, 1 = Yes |
| platformization_index | Integer | Sum of the ten plat_* indicators (equal weights) | 1 – 10 (theoretical range 0 – 10) |
