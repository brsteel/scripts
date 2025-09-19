import pandas as pd
import re
from datetime import datetime

def truncate_title_to_100_chars(title):
    """Ensure YouTube title doesn't exceed 100 character limit"""
    if len(title) <= 100:
        return title
    
    # Split by hashtags to preserve essential ones
    parts = title.split(' #')
    base_title = parts[0]
    
    # Essential hashtags to preserve
    essential_tags = [' #vr', ' #pcvr']
    essential_text = ''.join(tag for tag in essential_tags if any(tag in title.lower() for tag in essential_tags))
    
    # Calculate available space for base title
    available_space = 100 - len(essential_text)
    
    # Truncate base title if needed
    if len(base_title) > available_space:
        base_title = base_title[:available_space-3] + "..."
    
    return base_title + essential_text

def optimize_title(original_title, video_data):
    """Generate unique, dynamic title for each video based on content analysis"""
    
    # Extract episode/part numbering
    episode_match = re.search(r'(Episode|Part)\s+(\d+)', original_title, re.IGNORECASE)
    episode_text = ""
    if episode_match:
        episode_text = f" {episode_match.group(1).title()} {episode_match.group(2)}"
    
    # Extract version info
    version_info = extract_version_info(original_title)
    version_text = f" {version_info}" if version_info else ""
    
    # Extract game name from original title
    game = ""
    game_hashtag = ""
    if "radius" in original_title.lower():
        game = "Into the Radius 2"
        game_hashtag = "#intotheradius2"
    elif "zombie" in original_title.lower():
        game = "Zombie Army VR"
        game_hashtag = "#zombiearmyvr"
    elif "convrgence" in original_title.lower():
        game = "ConVRgence"
        game_hashtag = "#convrgence"
    elif "gorn" in original_title.lower():
        game = "Gorn 2"
        game_hashtag = "#gorn2"
    elif "unloop" in original_title.lower():
        game = "Unloop"
        game_hashtag = "#unloop"
    elif "wonderland" in original_title.lower():
        game = "Escaping Wonderland"
        game_hashtag = "#escapingwonderland"
    
    # Dynamic title generation based on specific content markers
    title_templates = []
    
    # ConVRgence - Keep existing unique titles
    if "convrgence" in original_title.lower():
        if "episode 1" in original_title.lower():
            return "This VR Game is ADDICTIVE! 🎮 ConVRgence Episode 1 #vr #pcvr #gaming #convrgence"
        elif "episode 2" in original_title.lower():
            return "VR Game You've NEVER Heard Of! 😲 ConVRgence Episode 2 #vr #pcvr #gaming #hiddengem"
        elif "episode 3" in original_title.lower() or "boss" in original_title.lower():
            return "EPIC VR Boss Fight! 🔥 ConVRgence Episode 3 #vr #pcvr #gaming #boss #convrgence"
        elif "episode 4" in original_title.lower() or "beer" in original_title.lower():
            return "VR Gameplay Gets CRAZY! 🤯 ConVRgence Episode 4 #vr #pcvr #gaming #convrgence"
        elif "episode 5" in original_title.lower():
            return "This VR Game SURPRISED Me! 🎯 ConVRgence Episode 5 #vr #pcvr #gaming #convrgence"
        elif "episode 6" in original_title.lower():
            return "Underrated VR Game! 💎 ConVRgence Episode 6 #vr #pcvr #gaming #underrated"
        elif "episode 7" in original_title.lower() or "update" in original_title.lower():
            return "VR Game UPDATE is AMAZING! 🚀 ConVRgence Episode 7 #vr #pcvr #gaming #update"
    
    # Into the Radius 2 - Dynamic unique titles based on content
    elif "radius" in original_title.lower():
        if "pechorsk" in original_title.lower() and "outskirt" in original_title.lower():
            return f"DANGEROUS VR Territory! 💀 Into the Radius 2{version_text} Pechorsk Outskirts {game_hashtag} #vr #pcvr #gaming"
        elif "climbing" in original_title.lower():
            return f"INSANE VR Climbing! 🧗 Into the Radius 2{version_text} Pechorsk Challenge {game_hashtag} #vr #pcvr #gaming"
        elif "realistic" in original_title.lower() and "harder" in original_title.lower():
            return f"HARDEST VR Difficulty! � Into the Radius 2{version_text} Realistic Mode {game_hashtag} #vr #pcvr #gaming"
        elif "realistic" in original_title.lower():
            return f"VR REALISM at its FINEST! 🎯 Into the Radius 2{version_text} Realistic {game_hashtag} #vr #pcvr #gaming"
        elif "standalone" in original_title.lower() or "quest 3" in original_title.lower():
            return f"Quest 3 STANDALONE Power! 🥽 Into the Radius 2{version_text} Review {game_hashtag} #vr #quest3 #gaming"
        elif "ghost town" in original_title.lower():
            return f"HAUNTED VR Exploration! 👻 Into the Radius 2{version_text} Ghost Town {game_hashtag} #vr #pcvr #gaming"
        elif "nightmare" in original_title.lower():
            return f"VR NIGHTMARE Mode! 😱 Into the Radius 2{version_text} Impossible Difficulty {game_hashtag} #vr #pcvr #gaming"
        elif "security level 4" in original_title.lower():
            return f"MAXIMUM Security VR! 🚨 Into the Radius 2{version_text} Level 4 Mission {game_hashtag} #vr #pcvr #gaming"
        elif "enemy count very high" in original_title.lower():
            return f"VR Enemy SWARM Mode! 🔥 Into the Radius 2{version_text} High Intensity {game_hashtag} #vr #pcvr #gaming"
        elif "just some fun" in original_title.lower():
            return f"VR Casual Gaming! 😎 Into the Radius 2{version_text} Chill Gameplay {game_hashtag} #vr #pcvr #gaming"
        elif "post sl3" in original_title.lower():
            return f"POST-Mission VR! 🎯 Into the Radius 2{version_text} After Security Level 3 {game_hashtag} #vr #pcvr #gaming"
        else:
            return f"POV: You're TRAPPED in VR! 😰 Into the Radius 2{version_text}{episode_text} {game_hashtag} #vr #pcvr #gaming #pov"
    
    # Zombie Army VR - Dynamic unique titles
    elif "zombie" in original_title.lower():
        if "elevator" in original_title.lower():
            return f"Zombie ELEVATOR Survival! � Epic VR Horror{episode_text} #vr #zombies #pcvr #gaming #horror"
        elif "part 1" in original_title.lower():
            return f"VR Zombie APOCALYPSE Begins! 🧟 Zombie Army VR Part 1 #vr #zombies #pcvr #gaming #horror"
        elif "part 2" in original_title.lower():
            return f"Zombie HORDE Intensifies! � Zombie Army VR Part 2 #vr #zombies #pcvr #gaming #action"
        elif "part 3" in original_title.lower():
            return f"VR Zombie CHAOS Mode! 🔥 Zombie Army VR Part 3 #vr #zombies #pcvr #gaming #intense"
        elif "part 4" in original_title.lower():
            return f"FINAL Zombie Battle! ⚔️ Zombie Army VR Part 4 #vr #zombies #pcvr #gaming #epic"
        elif "part 5" in original_title.lower():
            return f"Zombie VICTORY Finale! 🏆 Zombie Army VR Part 5 #vr #zombies #pcvr #gaming #win"
        else:
            return f"You WON'T Survive This VR! 😱 Zombie Army VR{episode_text} Terror #vr #zombies #pcvr #gaming #viral"
    
    # Other games - Unique patterns
    elif "gorn" in original_title.lower() and "boss" in original_title.lower():
        return f"EPIC VR Gladiator Fight! ⚔️ Gorn 2 First Boss Battle #vr #gaming #pcvr #boss #victory"
    elif "unloop" in original_title.lower():
        return f"This UNKNOWN VR Game is AMAZING! 🤩 Unloop Hidden Gem Review #vr #pcvr #gaming #hiddengem #amazing"
    elif "wonderland" in original_title.lower():
        return f"VR Wonderland Adventure! 🐰 Escaping Wonderland{episode_text} Puzzle Game #vr #pcvr #gaming #puzzle #adventure"
    
    # Fallback for any unmatched games
    else:
        if game:
            return f"This VR Game BLEW MY MIND! 🤯 {game}{episode_text}{version_text} #vr #pcvr #gaming {game_hashtag} #amazing"
        else:
            return f"HIDDEN VR Gem Discovery! 💎{episode_text} Amazing Gameplay #vr #pcvr #gaming #hiddengem #amazing"

def extract_version_info(title, description=""):
    """Extract version numbers from title or description"""
    version_patterns = [
        r'\.(\d+)\.(\d+)',  # .13.7, .14.1 format
        r'v\.?(\d+)\.?(\d+)?',  # v.12, v12 format
        r'(\d+)\.(\d+)',  # 13.7 format
        r'Early Access.*?(\d+\.\d+)',  # Early Access .13.7
        r'EA.*?(\d+\.\d+)',  # EA .13.7
        r'Beta.*?(\d+)',  # Beta 2
        r'Update.*?(\d+\.\d+)',  # Update .13.7
    ]
    
    text = f"{title} {description}".lower()
    
    for pattern in version_patterns:
        match = re.search(pattern, text)
        if match:
            if len(match.groups()) == 2:
                return f"v{match.group(1)}.{match.group(2)}"
            else:
                return f"v{match.group(1)}"
    
    return ""

def extract_activity_description(title, description=""):
    """Extract meaningful activity description from existing content"""
    activity_keywords = {
        'climbing': 'climbing challenges',
        'boss encounter': 'epic boss battles',
        'first boss': 'first boss encounter',
        'demon boss': 'demon boss fight',
        'elevator': 'elevator survival',
        'ghost town': 'ghost town exploration',
        'pechorsk': 'Pechorsk region gameplay',
        'outskirts': 'dangerous outskirts exploration',
        'security level': 'high security level missions',
        'nightmare': 'nightmare difficulty gameplay',
        'realistic': 'realistic difficulty challenges',
        'enemy count': 'intense enemy encounters',
        'no commentary': 'pure gameplay experience',
        'annotated tips': 'with helpful tips and strategies',
        'beta update': 'latest beta features',
        'difficulty ramps up': 'increasing difficulty challenges',
        'big update': 'major game update features'
    }
    
    text = f"{title} {description}".lower()
    activities = []
    
    for keyword, description in activity_keywords.items():
        if keyword in text:
            activities.append(description)
    
    if activities:
        return ", ".join(activities[:2])  # Limit to 2 activities
    
    return ""

def optimize_description(original_desc, video_data, optimized_title):
    """Generate optimized description with SEO keywords, version info, and activity details"""
    
    # Extract game info
    game = ""
    if "radius" in optimized_title.lower():
        game = "Into the Radius 2"
    elif "zombie" in optimized_title.lower():
        game = "Zombie Army VR"
    elif "convrgence" in optimized_title.lower():
        game = "ConVRgence"
    
    # Extract version and activity info
    original_title = video_data.get('title', '')
    version_info = extract_version_info(original_title, original_desc)
    activity_info = extract_activity_description(original_title, original_desc)
    
    # Build version text for hook
    version_text = f" {version_info}" if version_info else ""
    activity_text = f" featuring {activity_info}" if activity_info else ""
    
    # Hook (first 125 characters are crucial for search)
    hooks = [
        f"🎮 {game}{version_text} VR gameplay that will blow your mind! Watch as I tackle the most intense moments{activity_text}...",
        f"🔥 You WON'T believe what happens in this {game}{version_text} VR session{activity_text}! Prepare for non-stop action...",
        f"😱 This {game}{version_text} VR experience was INSANE{activity_text}! Join me for the most epic gameplay moments..."
    ]
    
    # Build specific gameplay details
    gameplay_details = f"🎯 What you'll experience in this video:\n"
    gameplay_details += f"• Intense VR action and immersive gameplay\n"
    gameplay_details += f"• High-quality PCVR gaming at 90FPS\n"
    
    if version_info:
        gameplay_details += f"• {game} {version_info} features and improvements\n"
    
    if activity_info:
        gameplay_details += f"• {activity_info.title()}\n"
    
    gameplay_details += f"• Expert-level gaming strategies and tips\n"
    gameplay_details += f"• Pure gameplay experience with great moments"

    # Main description body with keywords
    body = f"""
Welcome to The Old Man Gamer! 👋 Your ultimate destination for epic VR gaming content!

{gameplay_details}

🖥️ My Epic VR Gaming Setup:
• Intel I9 Processor 💪
• NVIDIA GeForce RTX 4070 Ti 🚀
• 32GB RAM ⚡
• 1TB SSD 💾
• Quest 3 + PCVR Setup 🥽

🎮 Why Subscribe to The Old Man Gamer?
✅ Daily VR gaming content and reviews
✅ Latest VR game gameplay and tutorials
✅ Premium PCVR gaming experience
✅ VR tips, tricks, and strategies
✅ Growing community of VR enthusiasts
✅ Father-son gaming perspectives

🔔 SMASH that LIKE button if you enjoyed this VR gameplay!
🔔 SUBSCRIBE for daily epic VR content!
🔔 Hit the BELL icon for instant notifications!

💬 Comment below: What VR game should I tackle next?

#VRGaming #PCVR #VirtualReality #Gaming #Quest3 #RTX4070Ti #GamingContent #VRGameplay #PCGaming #VRCommunity #TheOldManGamer #VRReview #GamingSetup #VR2024 #VRExperience
"""
    
    # Return complete description with hook + body
    return hooks[0] + "\n\n" + body

def optimize_tags(video_data):
    """Generate optimized tags based on competitor analysis"""
    
    # Base VR gaming tags (from competitor analysis)
    base_tags = [
        "VR", "Virtual Reality", "PCVR", "Gaming", "VR Gaming", "Quest 3", 
        "VR Games", "360", "Meta", "Oculus", "Virtual Reality Gaming",
        "PC Gaming", "VR Gameplay", "2024", "Gaming Content", "VR Experience"
    ]
    
    # Game-specific tags
    title = video_data.get('title', '').lower()
    game_tags = []
    
    if "radius" in title:
        game_tags = ["Into the Radius 2", "ITR2", "VR Horror", "VR Survival", "Realistic VR", "VR Shooter"]
    elif "zombie" in title:
        game_tags = ["Zombie Army VR", "VR Zombie", "Horror VR", "Zombie Games", "VR Action", "Undead VR"]
    elif "convrgence" in title:
        game_tags = ["ConVRgence", "VR Adventure", "Story VR", "VR RPG", "Immersive VR"]
    
    # Performance-based tags (based on your analytics)
    performance_tags = ["Funny", "Epic", "Intense", "Amazing", "Cool", "Best", "Top", "Must Watch"]
    
    # Technical tags
    tech_tags = ["RTX 4070 Ti", "High FPS", "90FPS", "4K VR", "Premium VR", "High Quality"]
    
    all_tags = base_tags + game_tags + performance_tags + tech_tags
    return all_tags[:30]  # YouTube allows max 500 characters in tags

def generate_video_optimizations():
    """Generate specific optimizations for your videos"""
    
    # Load your video data
    try:
        regular_videos = pd.read_csv('youtube_analytics_regular_videos.csv')
        shorts = pd.read_csv('youtube_analytics_shorts.csv')
    except FileNotFoundError:
        print("❌ Please run the main SEO optimizer first to generate the CSV files")
        return
    
    print("🚀 VIDEO OPTIMIZATION SUGGESTIONS")
    print("=" * 60)
    
    # Process top 10 regular videos
    top_videos = regular_videos.nlargest(10, 'views')
    
    optimizations = []
    
    for idx, (_, video) in enumerate(top_videos.iterrows(), 1):
        print(f"\n📹 VIDEO #{idx}")
        print(f"Current Title: {video['title']}")
        print(f"Current Performance: {video['views']} views, {video['averageViewPercentage']:.1f}% retention")
        print("-" * 50)
        
        # Generate optimized titles
        title_suggestions = optimize_title(video['title'], video)
        print("🎯 OPTIMIZED TITLE OPTIONS:")
        for i, suggestion in enumerate(title_suggestions[:3], 1):
            print(f"   {i}. {suggestion}")
        
        # Generate optimized description
        best_title = title_suggestions[0] if title_suggestions else video['title']
        desc_hooks, desc_body = optimize_description(video['description'], video, best_title)
        
        print("\n📝 OPTIMIZED DESCRIPTION HOOK OPTIONS:")
        for i, hook in enumerate(desc_hooks[:2], 1):
            print(f"   {i}. {hook}")
        
        # Generate tags
        optimized_tags = optimize_tags(video)
        print(f"\n🏷️ OPTIMIZED TAGS ({len(optimized_tags)} tags):")
        print(f"   {', '.join(optimized_tags[:15])}...")
        
        # Save optimization data
        optimization = {
            'original_title': video['title'],
            'optimized_titles': title_suggestions,
            'description_hooks': desc_hooks,
            'description_body': desc_body,
            'optimized_tags': optimized_tags,
            'current_views': video['views'],
            'current_retention': video['averageViewPercentage']
        }
        optimizations.append(optimization)
        
        print("-" * 60)
    
    # Process top shorts
    print(f"\n📱 SHORTS OPTIMIZATION")
    print("=" * 40)
    
    top_shorts = shorts.nlargest(3, 'views')
    for idx, (_, short) in enumerate(top_shorts.iterrows(), 1):
        print(f"\n🎬 SHORT #{idx}")
        print(f"Current: {short['title']}")
        print(f"Performance: {short['views']} views")
        
        # Shorts need different optimization (trending, hooks, emojis)
        short_suggestions = [
            f"This VR Moment Will SHOCK You! 😱 #{short['title'][:20].replace(' ', '').lower()} #vr #viral #gaming",
            f"POV: VR Gets TOO Real 😰 Epic Gaming Moment #vr #pov #gaming #shorts",
            f"VR Gaming Hit Different! 🔥 You Have to See This #vr #gaming #epic #mustwatch"
        ]
        
        print("🎯 OPTIMIZED SHORT TITLES:")
        for i, suggestion in enumerate(short_suggestions, 1):
            print(f"   {i}. {suggestion}")
    
    # Save all optimizations to file
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"video_optimizations_{timestamp}.txt"
    
    with open(filename, 'w', encoding='utf-8') as f:
        f.write("VIDEO OPTIMIZATION SUGGESTIONS\n")
        f.write("Generated by The Old Man Gamer SEO Optimizer\n")
        f.write("=" * 60 + "\n\n")
        
        for i, opt in enumerate(optimizations, 1):
            f.write(f"VIDEO #{i}\n")
            f.write(f"Original Title: {opt['original_title']}\n")
            f.write(f"Current Performance: {opt['current_views']} views, {opt['current_retention']:.1f}% retention\n\n")
            
            f.write("OPTIMIZED TITLES:\n")
            for j, title in enumerate(opt['optimized_titles'], 1):
                f.write(f"  {j}. {title}\n")
            
            f.write("\nDESCRIPTION HOOKS:\n")
            for j, hook in enumerate(opt['description_hooks'], 1):
                f.write(f"  {j}. {hook}\n")
            
            f.write(f"\nOPTIMIZED TAGS:\n")
            f.write(f"  {', '.join(opt['optimized_tags'])}\n")
            
            f.write("\n" + "="*60 + "\n\n")
    
    print(f"\n💾 Detailed optimizations saved to: {filename}")
    print("\n✅ OPTIMIZATION COMPLETE!")
    print("\n🎯 KEY TAKEAWAYS:")
    print("   • Add emojis and emotional hooks to titles")
    print("   • Use 'POV:', 'EPIC', 'INSANE' formats for higher engagement")
    print("   • Include hashtags directly in titles")
    print("   • Optimize descriptions with gaming setup info")
    print("   • Use trending VR keywords in tags")

if __name__ == "__main__":
    generate_video_optimizations()
