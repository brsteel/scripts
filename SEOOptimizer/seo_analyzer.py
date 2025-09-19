from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
import pandas as pd
import re
from collections import Counter
import os

# Scopes for YouTube Analytics and Data API
SCOPES = ["https://www.googleapis.com/auth/yt-analytics.readonly",
          "https://www.googleapis.com/auth/youtube.readonly"]

# Allow unverified apps for testing
os.environ['OAUTHLIB_INSECURE_TRANSPORT'] = '1'

# Authenticate
flow = InstalledAppFlow.from_client_secrets_file("client_secret_102034359712-upvn0ts1m88qp811hfi160ca2a9hh7pb.apps.googleusercontent.com.json", SCOPES)
credentials = flow.run_local_server(port=0)

# Build API clients
youtube = build("youtube", "v3", credentials=credentials)

def analyze_keywords_in_text(text):
    """Extract keywords from title/description"""
    if pd.isna(text) or text == "":
        return []
    
    # Convert to lowercase and remove special characters
    text = re.sub(r'[^\w\s#]', ' ', text.lower())
    
    # Split into words, filter out common words
    stop_words = {'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should', 'may', 'might', 'can', 'this', 'that', 'these', 'those', 'i', 'you', 'he', 'she', 'it', 'we', 'they', 'me', 'him', 'her', 'us', 'them', 'my', 'your', 'his', 'her', 'its', 'our', 'their'}
    
    words = [word.strip() for word in text.split() if len(word.strip()) > 2 and word.strip() not in stop_words]
    
    # Extract hashtags separately
    hashtags = re.findall(r'#\w+', text)
    
    return words + hashtags

def get_competitor_data(game_keywords, max_results=20):
    """Get data from competitor channels in VR gaming niche"""
    
    competitors = []
    
    for keyword in game_keywords:
        try:
            # Search for popular videos with the keyword
            search_response = youtube.search().list(
                q=f"{keyword} VR gameplay",
                part="snippet",
                type="video",
                order="viewCount",
                maxResults=max_results,
                publishedAfter="2024-01-01T00:00:00Z"  # Recent videos
            ).execute()
            
            video_ids = [item['id']['videoId'] for item in search_response['items']]
            
            # Get detailed video info
            if video_ids:
                videos_response = youtube.videos().list(
                    part="snippet,statistics",
                    id=",".join(video_ids)
                ).execute()
                
                for video in videos_response['items']:
                    competitors.append({
                        'video_id': video['id'],
                        'title': video['snippet']['title'],
                        'description': video['snippet']['description'][:500],
                        'tags': ', '.join(video['snippet'].get('tags', [])),
                        'channel_title': video['snippet']['channelTitle'],
                        'view_count': int(video['statistics'].get('viewCount', 0)),
                        'like_count': int(video['statistics'].get('likeCount', 0)),
                        'comment_count': int(video['statistics'].get('commentCount', 0)),
                        'keyword_searched': keyword
                    })
        
        except Exception as e:
            print(f"Error searching for {keyword}: {e}")
            continue
    
    return pd.DataFrame(competitors)

def analyze_your_content():
    """Load and analyze your existing content"""
    
    # Load your regular videos data
    your_videos = pd.read_csv('youtube_analytics_regular_videos.csv')
    
    print("🔍 Analyzing YOUR content...")
    
    # Extract keywords from your titles
    all_title_words = []
    all_description_words = []
    all_tags = []
    
    for _, video in your_videos.iterrows():
        title_words = analyze_keywords_in_text(video['title'])
        desc_words = analyze_keywords_in_text(video['description'])
        tag_words = analyze_keywords_in_text(video['tags'])
        
        all_title_words.extend(title_words)
        all_description_words.extend(desc_words)
        all_tags.extend(tag_words)
    
    # Count most common words
    title_keywords = Counter(all_title_words).most_common(20)
    desc_keywords = Counter(all_description_words).most_common(20)
    tag_keywords = Counter(all_tags).most_common(20)
    
    print("\n📊 YOUR MOST USED KEYWORDS:")
    print("Titles:", [f"{word}({count})" for word, count in title_keywords[:10]])
    print("Descriptions:", [f"{word}({count})" for word, count in desc_keywords[:10]])
    print("Tags:", [f"{word}({count})" for word, count in tag_keywords[:10]])
    
    return your_videos, title_keywords, desc_keywords, tag_keywords

def analyze_competitors(your_games):
    """Analyze competitor content"""
    
    print("\n🔍 Analyzing COMPETITOR content...")
    
    # Extract game names from your content
    game_keywords = list(set(your_games))[:5]  # Top 5 games you play
    print(f"Analyzing competitors for: {game_keywords}")
    
    # Get competitor data
    competitor_df = get_competitor_data(game_keywords, max_results=15)
    
    if len(competitor_df) == 0:
        print("❌ No competitor data found")
        return None, [], [], []
    
    # Analyze competitor keywords
    comp_title_words = []
    comp_desc_words = []
    comp_tag_words = []
    
    for _, video in competitor_df.iterrows():
        title_words = analyze_keywords_in_text(video['title'])
        desc_words = analyze_keywords_in_text(video['description'])
        tag_words = analyze_keywords_in_text(video['tags'])
        
        comp_title_words.extend(title_words)
        comp_desc_words.extend(desc_words)
        comp_tag_words.extend(tag_words)
    
    comp_title_keywords = Counter(comp_title_words).most_common(20)
    comp_desc_keywords = Counter(comp_desc_words).most_common(20)
    comp_tag_keywords = Counter(comp_tag_words).most_common(20)
    
    print(f"\n📊 COMPETITOR KEYWORDS ({len(competitor_df)} videos analyzed):")
    print("Titles:", [f"{word}({count})" for word, count in comp_title_keywords[:10]])
    print("Tags:", [f"{word}({count})" for word, count in comp_tag_keywords[:10]])
    
    return competitor_df, comp_title_keywords, comp_desc_keywords, comp_tag_keywords

def generate_optimization_suggestions(your_videos, your_title_kw, comp_title_kw, comp_tag_kw):
    """Generate specific optimization suggestions"""
    
    print("\n🚀 OPTIMIZATION SUGGESTIONS:")
    print("=" * 60)
    
    # Keywords you should use more (popular with competitors but not you)
    your_title_words = set([word for word, count in your_title_kw])
    comp_title_words = set([word for word, count in comp_title_kw[:15]])
    comp_tag_words = set([word for word, count in comp_tag_kw[:15]])
    
    missing_title_keywords = comp_title_words - your_title_words
    missing_tag_keywords = comp_tag_words - your_title_words
    
    print("\n🎯 KEYWORDS TO ADD TO YOUR TITLES:")
    print(list(missing_title_keywords)[:10])
    
    print("\n🏷️ TAGS TO START USING:")
    print(list(missing_tag_keywords)[:15])
    
    # Analyze your top performing videos for patterns
    top_videos = your_videos.nlargest(10, 'views')
    
    print("\n🏆 YOUR TOP PERFORMING VIDEO PATTERNS:")
    print("(Use these patterns in future videos)")
    
    for i, video in enumerate(top_videos.iterrows(), 1):
        video_data = video[1]
        title_length = len(video_data['title'])
        print(f"\n{i:2d}. Views: {video_data['views']:4d} | Retention: {video_data['averageViewPercentage']:5.1f}%")
        print(f"    Title ({title_length} chars): {video_data['title'][:80]}...")
        
        # Extract key elements
        hashtags = re.findall(r'#\w+', video_data['title'])
        if hashtags:
            print(f"    Hashtags used: {', '.join(hashtags)}")
    
    return {
        'missing_title_keywords': list(missing_title_keywords)[:10],
        'missing_tag_keywords': list(missing_tag_keywords)[:15],
        'top_video_patterns': top_videos[['title', 'views', 'averageViewPercentage']].to_dict('records')
    }

def main():
    print("🎮 VR GAMING SEO ANALYZER")
    print("=" * 40)
    
    # Analyze your content
    your_videos, your_title_kw, your_desc_kw, your_tag_kw = analyze_your_content()
    
    # Extract games you play most
    game_mentions = []
    for title in your_videos['title']:
        if 'radius' in title.lower():
            game_mentions.append('Into the Radius 2')
        if 'zombie' in title.lower():
            game_mentions.append('Zombie Army VR')
        if 'convrgence' in title.lower():
            game_mentions.append('ConVRgence')
    
    # Add general VR terms
    game_mentions.extend(['VR Gaming', 'PCVR', 'Virtual Reality'])
    
    # Analyze competitors
    competitor_df, comp_title_kw, comp_desc_kw, comp_tag_kw = analyze_competitors(game_mentions)
    
    if competitor_df is not None:
        # Save competitor data
        competitor_df.to_csv('competitor_analysis.csv', index=False)
        print(f"\n💾 Saved competitor data: competitor_analysis.csv")
    
    # Generate suggestions
    suggestions = generate_optimization_suggestions(your_videos, your_title_kw, comp_title_kw, comp_tag_kw)
    
    # Save suggestions to file
    with open('seo_suggestions.txt', 'w') as f:
        f.write("VR GAMING SEO OPTIMIZATION SUGGESTIONS\n")
        f.write("=" * 50 + "\n\n")
        
        f.write("KEYWORDS TO ADD TO TITLES:\n")
        for keyword in suggestions['missing_title_keywords']:
            f.write(f"- {keyword}\n")
        
        f.write("\nTAGS TO START USING:\n")
        for tag in suggestions['missing_tag_keywords']:
            f.write(f"- {tag}\n")
        
        f.write("\nTOP PERFORMING VIDEO PATTERNS:\n")
        for i, video in enumerate(suggestions['top_video_patterns'], 1):
            f.write(f"{i}. {video['title']} (Views: {video['views']}, Retention: {video['averageViewPercentage']:.1f}%)\n")
    
    print(f"\n💾 Saved optimization suggestions: seo_suggestions.txt")
    print("\n✅ Analysis complete! Check the generated files for detailed insights.")

if __name__ == "__main__":
    main()
