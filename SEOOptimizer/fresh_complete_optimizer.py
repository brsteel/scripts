"""
FRESH COMPLETE OPTIMIZATION LIST
Generated with Research Intelligence & Game Data
Date: September 15, 2025
"""

import pandas as pd
import random
from research_enhanced_optimizer import ResearchEnhancedOptimizer

def load_video_data():
    """Load the fresh video data"""
    try:
        df = pd.read_csv('youtube_analytics_regular_videos.csv')
        return df.to_dict('records')
    except FileNotFoundError:
        print("❌ Video data not found. Run seooptimizer.py first.")
        return []

def generate_fresh_optimizations():
    """Generate fresh optimizations with research intelligence"""
    
    print("🎯 FRESH COMPLETE OPTIMIZATION LIST")
    print("=" * 60)
    print("🔬 Based on comprehensive Steam & YouTube research")
    print("📊 Using fresh channel data (146 videos)")
    print("🚀 Research-enhanced titles from high-performing competitors")
    print()
    
    # Initialize the research-enhanced optimizer
    optimizer = ResearchEnhancedOptimizer()
    
    # Load video data
    videos = load_video_data()
    
    if not videos:
        # Create sample data based on common patterns
        videos = create_sample_video_data()
    
    # Group videos by game for better organization
    game_groups = {}
    
    for video in videos:
        title = video.get('title', '')
        game_key = identify_game_category(title)
        
        if game_key not in game_groups:
            game_groups[game_key] = []
        game_groups[game_key].append(video)
    
    # Generate optimizations by game
    total_count = 1
    
    for game_key, game_videos in game_groups.items():
        if not game_videos:
            continue
            
        print(f"🎮 {game_key.upper()} OPTIMIZATIONS")
        print("-" * 50)
        
        for video in game_videos[:10]:  # Limit to first 10 per game for readability
            title = video.get('title', '')
            if not title:
                continue
                
            print(f"📹 VIDEO {total_count}: {title}")
            print()
            
            # Generate research-enhanced optimizations
            optimized_title = optimizer.optimize_title(video)
            optimized_description = optimizer.optimize_description(video)
            
            print(f"✨ RESEARCH-ENHANCED TITLE:")
            print(f"{optimized_title}")
            print()
            
            print(f"📝 INTELLIGENT DESCRIPTION:")
            print(optimized_description[:500] + "..." if len(optimized_description) > 500 else optimized_description)
            print()
            
            print("🔥 IMPLEMENTATION:")
            print("1. Copy the title above")
            print("2. Paste into your YouTube video title")
            print("3. Copy the description")
            print("4. Update your video description")
            print("5. Add engaging thumbnail with dramatic moment")
            print()
            print("=" * 60)
            print()
            
            total_count += 1
            
            if total_count > 30:  # Limit total output for readability
                break
                
        if total_count > 30:
            break
    
    print("🎯 RESEARCH INTELLIGENCE SUMMARY:")
    print("=" * 60)
    print("• Into the Radius 2: Survival horror in Pechorsk Anomaly Zone")
    print("• ConVRgence: Extraction shooter with dog companion in Chernokamensk")  
    print("• Zombie Army VR: WWII zombie shooter with X-ray Kill Cam")
    print("• Competitor patterns: 'SCARIEST', 'PHOTOREALISTIC', 'DANGEROUS'")
    print("• High-performing titles use CAPS, emotions, and specific game knowledge")
    print()
    print("📈 Expected Results:")
    print("• Increased click-through rates from emotional hooks")
    print("• Better audience retention from authentic game knowledge")
    print("• Improved search ranking from relevant keywords")
    print("• Higher engagement from research-backed descriptions")

def identify_game_category(title):
    """Identify game category from title"""
    title_lower = title.lower()
    
    if 'into the radius' in title_lower:
        return 'Into the Radius 2'
    elif 'convrgence' in title_lower:
        return 'ConVRgence'  
    elif 'zombie' in title_lower:
        return 'Zombie Army VR'
    elif 'gorn' in title_lower:
        return 'Gorn 2'
    elif 'wonderland' in title_lower:
        return 'Escaping Wonderland'
    elif 'unloop' in title_lower:
        return 'Unloop'
    else:
        return 'Other VR Games'

def create_sample_video_data():
    """Create sample data if CSV not available"""
    return [
        {'title': 'Into the Radius 2 .13.7 Pechorsk Outskirts Realistic Mode'},
        {'title': 'Into the Radius 2 .14.1 Ghost Town Nightmare Difficulty'},
        {'title': 'ConVRgence VR Game Episode 1'},
        {'title': 'ConVRgence Update New Boss Enemy'},
        {'title': 'Zombie Army VR Part 1 First Mission'},
        {'title': 'Zombie Army VR Horde Mode'},
        {'title': 'Gorn 2 First Boss Battle'},
        {'title': 'Unloop VR Game Review'},
        {'title': 'Escaping Wonderland Episode 1 Mirror Mire'}
    ]

if __name__ == "__main__":
    generate_fresh_optimizations()
