from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
import pandas as pd

# Scopes for YouTube Analytics and Data API
SCOPES = ["https://www.googleapis.com/auth/yt-analytics.readonly",
          "https://www.googleapis.com/auth/youtube.readonly"]

# Authenticate
flow = InstalledAppFlow.from_client_secrets_file("client_secret_102034359712-upvn0ts1m88qp811hfi160ca2a9hh7pb.apps.googleusercontent.com.json", SCOPES)
# Allow unverified apps for testing
import os
os.environ['OAUTHLIB_INSECURE_TRANSPORT'] = '1'
credentials = flow.run_local_server(port=0)

# Build API clients
youtube = build("youtube", "v3", credentials=credentials)
analytics = build("youtubeAnalytics", "v2", credentials=credentials)

# Try to get channel info with more details
try:
    # First, try to get channel with more parts
    channel_response = youtube.channels().list(
        mine=True,
        part="id,snippet,statistics"
    ).execute()
    
    print("Full channel response:", channel_response)
    
    if "items" not in channel_response or len(channel_response["items"]) == 0:
        print("\nNo channel found with 'mine=True'. Trying alternative method...")
        
        # Try getting channels for authenticated user
        channel_response = youtube.channels().list(
            part="id,snippet,statistics",
            forUsername="me"
        ).execute()
        
        print("Alternative response:", channel_response)
        
        if "items" not in channel_response or len(channel_response["items"]) == 0:
            print("Still no channel found. This might be a brand account issue.")
            print("\nPlease provide your channel ID manually:")
            print("1. Go to your YouTube channel")
            print("2. Look at the URL: https://www.youtube.com/channel/[CHANNEL_ID]")
            print("3. Copy the channel ID (starts with UC...)")
            
            channel_id = input("\nEnter your channel ID: ").strip()
            if not channel_id.startswith('UC'):
                print("Invalid channel ID. Should start with 'UC'")
                exit()
            
            # Verify the channel ID works
            try:
                test_response = youtube.channels().list(
                    part="snippet,statistics",
                    id=channel_id
                ).execute()
                
                if "items" in test_response and len(test_response["items"]) > 0:
                    channel_info = test_response["items"][0]
                    channel_name = channel_info["snippet"]["title"]
                    subscriber_count = channel_info["statistics"].get("subscriberCount", "Hidden")
                    print(f"\n✅ Found channel: {channel_name}")
                    print(f"   Subscribers: {subscriber_count}")
                else:
                    print("Channel ID not found or not accessible.")
                    exit()
            except Exception as e:
                print(f"Error verifying channel ID: {e}")
                exit()
                
            print("Continuing with manual channel ID...")
            exit()
    
    channel_info = channel_response["items"][0]
    channel_id = channel_info["id"]
    channel_name = channel_info["snippet"]["title"]
    subscriber_count = channel_info["statistics"].get("subscriberCount", "Hidden")
    
    print(f"\n✅ Found channel: {channel_name}")
    print(f"   Channel ID: {channel_id}")
    print(f"   Subscribers: {subscriber_count}")
    
except Exception as e:
    print(f"Error getting channel info: {e}")
    exit()

# Query analytics for last 90 days - get ALL videos
analytics_response = analytics.reports().query(
    ids=f"channel=={channel_id}",
    startDate="2025-06-15",
    endDate="2025-09-15",
    metrics="views,averageViewDuration,averageViewPercentage,likes,comments,subscribersGained",
    dimensions="video",
    sort="-views",
    maxResults=200  # Increased to get more videos
).execute()

# Convert to DataFrame
df = pd.DataFrame(analytics_response["rows"], columns=[h["name"] for h in analytics_response["columnHeaders"]])

# Get video details (titles, descriptions, tags, etc.)
if len(df) > 0:
    print("Fetching video details...")
    video_ids = df['video'].tolist()
    
    # YouTube API allows max 50 video IDs per request
    video_details = []
    for i in range(0, len(video_ids), 50):
        batch_ids = video_ids[i:i+50]
        video_response = youtube.videos().list(
            part="snippet,statistics,contentDetails,liveStreamingDetails",
            id=",".join(batch_ids)
        ).execute()
        
        for video_item in video_response["items"]:
            # Parse duration to identify shorts (videos under 60 seconds)
            duration = video_item.get('contentDetails', {}).get('duration', 'PT0S')
            
            # Convert ISO 8601 duration to seconds
            import re
            duration_seconds = 0
            if duration != 'PT0S':
                matches = re.findall(r'(\d+)([HMS])', duration)
                for value, unit in matches:
                    if unit == 'H':
                        duration_seconds += int(value) * 3600
                    elif unit == 'M':
                        duration_seconds += int(value) * 60
                    elif unit == 'S':
                        duration_seconds += int(value)
            
            # Check if it's a livestream
            is_livestream = 'liveStreamingDetails' in video_item
            
            # Check if it's a short (under 60 seconds)
            is_short = duration_seconds > 0 and duration_seconds <= 60
            
            video_details.append({
                'video_id': video_item['id'],
                'title': video_item['snippet']['title'],
                'description': video_item['snippet']['description'][:200] + "..." if len(video_item['snippet']['description']) > 200 else video_item['snippet']['description'],
                'published_date': video_item['snippet']['publishedAt'],
                'tags': ', '.join(video_item['snippet'].get('tags', [])),
                'category_id': video_item['snippet']['categoryId'],
                'duration': duration,
                'duration_seconds': duration_seconds,
                'is_short': is_short,
                'is_livestream': is_livestream,
                'total_views': video_item['statistics'].get('viewCount', 0),
                'total_likes': video_item['statistics'].get('likeCount', 0),
                'total_comments': video_item['statistics'].get('commentCount', 0)
            })
    
    # Create video details DataFrame
    video_df = pd.DataFrame(video_details)
    
    # Merge analytics data with video details
    final_df = df.merge(video_df, left_on='video', right_on='video_id', how='left')
    
    # Filter out shorts and livestreams
    regular_videos_df = final_df[~final_df['is_short'] & ~final_df['is_livestream']].copy()
    shorts_df = final_df[final_df['is_short']].copy()
    livestreams_df = final_df[final_df['is_livestream']].copy()
    
    # Reorder columns for better readability
    columns_order = ['video_id', 'title', 'views', 'averageViewDuration', 'averageViewPercentage', 
                    'likes', 'comments', 'subscribersGained', 'total_views', 'total_likes', 
                    'total_comments', 'published_date', 'duration_seconds', 'is_short', 'is_livestream', 
                    'tags', 'description']
    
    # Save all data
    final_df_ordered = final_df[columns_order]
    final_df_ordered.to_csv("youtube_analytics_all.csv", index=False)
    
    # Save filtered data
    if len(regular_videos_df) > 0:
        regular_videos_ordered = regular_videos_df[columns_order]
        regular_videos_ordered.to_csv("youtube_analytics_regular_videos.csv", index=False)
    
    if len(shorts_df) > 0:
        shorts_ordered = shorts_df[columns_order]
        shorts_ordered.to_csv("youtube_analytics_shorts.csv", index=False)
    
    if len(livestreams_df) > 0:
        livestreams_ordered = livestreams_df[columns_order]
        livestreams_ordered.to_csv("youtube_analytics_livestreams.csv", index=False)
    
    print("✅ Analytics data saved:")
    print(f"   📁 All videos: youtube_analytics_all.csv ({len(final_df)} videos)")
    print(f"   🎬 Regular videos: youtube_analytics_regular_videos.csv ({len(regular_videos_df)} videos)")
    print(f"   📱 Shorts: youtube_analytics_shorts.csv ({len(shorts_df)} videos)")
    print(f"   🔴 Livestreams: youtube_analytics_livestreams.csv ({len(livestreams_df)} videos)")
    
    # Show summary
    print(f"\n📊 Summary:")
    print(f"   Total videos analyzed: {len(final_df)}")
    print(f"   Regular videos: {len(regular_videos_df)} ({len(regular_videos_df)/len(final_df)*100:.1f}%)")
    print(f"   Shorts: {len(shorts_df)} ({len(shorts_df)/len(final_df)*100:.1f}%)")
    print(f"   Livestreams: {len(livestreams_df)} ({len(livestreams_df)/len(final_df)*100:.1f}%)")
else:
    print("No analytics data found for the specified date range")
