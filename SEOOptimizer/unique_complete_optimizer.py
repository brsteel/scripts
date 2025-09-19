import pandas as pd
import re
from datetime import datetime
from video_optimizer_fixed import (
    optimize_description,
    generate_radius_description, generate_convrgence_description, 
    generate_zombie_description, truncate_title_to_100_chars
)

def generate_unique_title(original_title, views, video_id):
    """Generate truly unique titles based on specific video content"""
    
    title_lower = original_title.lower()
    
    # Extract specific identifiers
    episode_match = re.search(r'episode\s*(\d+)', original_title, re.IGNORECASE)
    part_match = re.search(r'part\s*(\d+)', original_title, re.IGNORECASE)
    
    episode_num = episode_match.group(1) if episode_match else ""
    part_num = part_match.group(1) if part_match else ""
    
    # ZOMBIE ARMY VR - Unique titles for each video
    if "zombie" in title_lower:
        if "elevator" in title_lower:
            return "UNDEAD VR Warfare! ⚔️ Zombie Army VR Elevator Survival #vr #zombies #pcvr"
        elif part_num == "1":
            return "Is This The NEXT BEST VR Zombie Game?! 🧟 Zombie Army VR Part 1 #vr #zombies #pcvr"
        elif part_num == "2":
            return "WWII Zombies in VR! 🪖 Zombie Army VR Part 2 #vr #zombies #pcvr"
        elif part_num == "3":
            return "VR Zombie CHAOS Mode! 🔥 Zombie Army VR Part 3 #vr #zombies #pcvr"
        elif part_num == "4":
            return "FINAL Zombie Battle! ⚔️ Zombie Army VR Part 4 #vr #zombies #pcvr"
        elif "terrifying" in title_lower or "won't believe" in title_lower:
            return "VR Zombie TERROR Experience! 😱 Zombie Army VR Horror #vr #zombies #pcvr"
        else:
            return "EPIC VR Zombie Slaughter! 🧟‍♂️ Zombie Army VR Action #vr #zombies #pcvr"
    
    # INTO THE RADIUS 2 - Unique titles based on content
    elif "radius" in title_lower:
        if "dangerous" in title_lower and "territory" in title_lower:
            return "DANGEROUS Anomaly Zone! ⚡ Into the Radius 2 Pechorsk #intotheradius2 #vr #pcvr"
        elif "adventure" in title_lower:
            return "PHOTOREALISTIC VR Adventure! 🔥 Into the Radius 2 Gameplay #intotheradius2 #vr #pcvr"
        elif "blew my mind" in title_lower and "quest3" in title_lower:
            return "Quest 3 VR MASTERPIECE! 🤯 Into the Radius 2 Standalone #intotheradius2 #vr #quest3"  
        elif "blew my mind" in title_lower and video_id == "xc5kIFO2N_o":
            return "VR Graphics INSANITY! 🤯 Into the Radius 2 Visual Feast #intotheradius2 #vr #pcvr"
        elif "blew my mind" in title_lower and video_id == "sDwSXBdctF0":
            return "Most REALISTIC VR Ever! 🤯 Into the Radius 2 Immersion #intotheradius2 #vr #pcvr"
        elif "climbing" in title_lower:
            return "INSANE VR Climbing! 🧗 Into the Radius 2 Pechorsk Heights #intotheradius2 #vr #pcvr"
        elif "security level 4" in title_lower:
            return "MAXIMUM Security VR! 🚨 Into the Radius 2 Level 4 #intotheradius2 #vr #pcvr"
        elif "ghost town" in title_lower and part_num == "1":
            return "HAUNTED VR Zone! 👻 Into the Radius 2 Ghost Town Part 1 #intotheradius2 #vr"
        elif "ghost town" in title_lower and part_num == "3":
            return "VR NIGHTMARE Continues! 💀 Into the Radius 2 Ghost Town Part 3 #intotheradius2 #vr"
        elif "ghost town" in title_lower and part_num == "4":
            return "The SCARIEST VR Game is BACK! 💀 Into the Radius 2 Ghost Town Part 4 #intotheradius2 #vr"
        elif "nightmare" in title_lower:
            return "VR NIGHTMARE Mode! 😱 Into the Radius 2 Nightmarish Difficulty #intotheradius2 #vr #pcvr"
        elif "enemy count very high" in title_lower:
            return "VR Enemy SWARM Mode! 🔥 Into the Radius 2 High Enemy Count #intotheradius2 #vr #pcvr"
        elif "deathless" in title_lower and episode_num == "1":
            return "IMPOSSIBLE VR Challenge! 💀 Into the Radius 2 Deathless Episode 1 #intotheradius2 #vr"
        elif "v.12" in original_title and episode_num == "1":
            return "STALKER VR Episode 1! 🌲 Into the Radius 2 v12 Post-SL3 #intotheradius2 #vr #pcvr"
        else:
            return f"Into the ZONE VR! ⚡ Into the Radius 2 Experience #{video_id[:4]} #intotheradius2 #vr #pcvr"
    
    # CONVRGENCE - Episode-specific titles
    elif "convrgence" in title_lower:
        if episode_num == "2":
            return "STALKER VR Extraction Shooter! 🎯 ConVRgence Episode 2 #vr #pcvr #convrgence"
        elif episode_num == "4" and "beer" in title_lower:
            return "AI BEG for Their Lives! 😰 ConVRgence Episode 4 Beer Story #vr #pcvr #convrgence"
        elif episode_num == "5" and "difficulty" in title_lower:
            return "CROSSBOW Action! 🏹 ConVRgence Episode 5 Difficulty Ramps #vr #pcvr #convrgence #stalker"
        elif episode_num == "6":
            return "MASSIVE Update! 🚀 ConVRgence Episode 6 #vr #pcvr #convrgence #stalker"
        elif episode_num == "7":
            return "FLAMETHROWER Mayhem! 🔥 ConVRgence Episode 7 #vr #pcvr #convrgence"
        elif "hidden" in title_lower and "gem" in title_lower and video_id == "FyAPzSVi2AE":
            return "The Soviet VR Game! 🌲 ConVRgence Epic Discovery #vr #pcvr #convrgence #stalker"
        elif "hidden" in title_lower and "gem" in title_lower:
            return "VR Hidden GEM Found! 💎 ConVRgence Epic Adventure #vr #pcvr #convrgence #stalker"
        else:
            return "VR Game with DOG Companion! 🐕 ConVRgence Zone Explorer #vr #pcvr #convrgence #stalker"
    
    # OTHER GAMES - Specific titles
    elif "half life" in title_lower and "alyx" in title_lower:
        return "My First VR Masterpiece! 👑 Half Life Alyx Part 1 First Time #vr #pcvr #halflifealyx"
    elif "gorn" in title_lower:
        return "EPIC VR Gladiator Returns! ⚔️ Gorn 2 Boss Battle First Boss #vr #gaming #pcvr #boss"
    elif "wonderland" in title_lower:
        return "VR Wonderland NIGHTMARE! 🐰 Escaping Wonderland Episode 4 Mirror Mire #vr #pcvr #puzzle"
    elif "unloop" in title_lower:
        return "This UNKNOWN VR Game is AMAZING! 🤩 Unloop Hidden Gem Review #vr #pcvr #hiddengem"
    
    else:
        # Fallback with unique identifier
        game_name = original_title.split()[0] if original_title.split() else "VR Game"
        return f"This {game_name} VR Experience! 🎮 Hidden Gem #{video_id[:4]} #vr #pcvr #gaming"

def load_video_data():
    """Load video data from CSV file"""
    try:
        df = pd.read_csv('video_analytics.csv')
        return df.to_dict('records')
    except FileNotFoundError:
        print("❌ video_analytics.csv not found!")
        return []

def generate_complete_optimizations():
    """Generate optimizations for all videos with unique titles"""
    
    videos = load_video_data()
    if not videos:
        return
    
    # Filter out shorts and livestreams
    regular_videos = [v for v in videos if not v.get('is_short', False) and not v.get('is_livestream', False)]
    
    # Sort by views (descending) for priority ranking
    regular_videos.sort(key=lambda x: x.get('views', 0), reverse=True)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # Create optimizations
    optimizations = []
    
    print(f"🚀 GENERATING UNIQUE OPTIMIZATIONS FOR ALL {len(regular_videos)} VIDEOS")
    print("=" * 60)
    
    for idx, video in enumerate(regular_videos, 1):
        if idx % 20 == 0:
            print(f"📊 Processed {idx}/{len(regular_videos)} videos...")
        
        # Generate unique optimized title
        optimized_title = generate_unique_title(video['title'], video['views'], video['video_id'])
        
        # Ensure title is under 100 characters
        optimized_title = truncate_title_to_100_chars(optimized_title)
        
        # Generate optimized description based on game type
        title_lower = video['title'].lower()
        if 'radius' in title_lower:
            optimized_description = generate_radius_description(video['title'])
        elif 'convrgence' in title_lower:
            optimized_description = generate_convrgence_description(video['title'])
        elif 'zombie' in title_lower:
            optimized_description = generate_zombie_description(video['title'])
        else:
            # Use basic description for other games
            optimized_description = f"""🎮 {video['title']} - VR Gaming Experience!

This VR game offers incredible immersive gameplay that will keep you engaged from start to finish!

🔥 Game Features:
• Stunning VR graphics and environments
• Immersive gameplay mechanics
• Smooth VR interactions and controls
• Engaging storyline and content
• Compatible with major VR headsets

This is definitely worth checking out if you're a VR gaming enthusiast!

💬 Have you played this game? Share your thoughts in the comments!

👍 LIKE if you enjoyed this VR gaming content!
🔔 SUBSCRIBE for more VR game reviews and gameplay!

#VR #PCVR #Gaming #VirtualReality"""
        
        # Generate tags
        if 'radius' in title_lower:
            optimized_tags = "Into the Radius 2, VR survival, STALKER VR, Pechorsk Zone, realistic VR, anomaly zone, VR horror, survival horror VR, PCVR gaming, Quest 3 VR"
        elif 'convrgence' in title_lower:
            optimized_tags = "ConVRgence, VR extraction shooter, STALKER VR, dog companion VR, Soviet VR, Chernokamensk Zone, hidden VR gem, procedural VR, bandit encounters, VR survival"
        elif 'zombie' in title_lower:
            optimized_tags = "Zombie Army VR, WWII zombies, VR horror, X-ray kill cam, zombie horde VR, authentic weapons, co-op VR, undead VR, historical VR, Left 4 Dead VR"
        else:
            optimized_tags = "VR gaming, PCVR, virtual reality, immersive VR, VR adventure, gaming, VR experience, Quest 3, Steam VR, VR gameplay"
        
        # Determine impact level
        views = video.get('views', 0)
        if views > 200:
            impact = "HIGH IMPACT"
        elif views > 50:
            impact = "MEDIUM IMPACT"
        else:
            impact = "RECOVERY IMPACT"
        
        optimization = {
            'rank': idx,
            'video_id': video['video_id'],
            'current_title': video['title'],
            'optimized_title': optimized_title,
            'optimized_description': optimized_description,
            'optimized_tags': optimized_tags,
            'views': views,
            'retention': video.get('averageViewPercentage', 0),
            'impact': impact
        }
        
        optimizations.append(optimization)
    
    # Save to text file
    output_file = f"complete_video_optimizations_unique_{timestamp}.txt"
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("COMPLETE YOUTUBE SEO OPTIMIZATION GUIDE\\nALL REGULAR VIDEOS - The Old Man Gamer\\n")
        f.write("=" * 70 + "\\n\\n")
        f.write("INSTRUCTIONS:\\n")
        f.write("1. Go to YouTube Studio (studio.youtube.com)\\n")
        f.write("2. Find video by Video ID or current title\\n")
        f.write("3. Copy-paste optimized content\\n")
        f.write("4. Save changes\\n")
        f.write("5. Track improvements in spreadsheet\\n\\n")
        f.write("PRIORITY ORDER: Start with HIGH impact videos first\\n")
        f.write("=" * 70 + "\\n\\n")
        
        for opt in optimizations:
            f.write(f"RANK #{opt['rank']} - {opt['impact']}\\n")
            f.write(f"Video ID: {opt['video_id']}\\n")
            f.write(f"Current Performance: {opt['views']:,} views, {opt['retention']:.1f}% retention\\n")
            f.write("-" * 60 + "\\n")
            f.write(f"CURRENT TITLE:\\n{opt['current_title']}\\n\\n")
            f.write(f"OPTIMIZED TITLE:\\n{opt['optimized_title']}\\n\\n")
            f.write(f"OPTIMIZED DESCRIPTION:\\n{opt['optimized_description']}\\n\\n")
            f.write(f"OPTIMIZED TAGS:\\n{opt['optimized_tags']}\\n\\n")
            f.write("=" * 70 + "\\n\\n")
    
    # Summary
    high_impact = len([o for o in optimizations if o['impact'] == 'HIGH IMPACT'])
    medium_impact = len([o for o in optimizations if o['impact'] == 'MEDIUM IMPACT'])
    recovery_impact = len([o for o in optimizations if o['impact'] == 'RECOVERY IMPACT'])
    
    print("\\n✅ UNIQUE OPTIMIZATION GUIDE CREATED!")
    print(f"📄 File: {output_file}")
    print(f"\\n📊 OPTIMIZATION SUMMARY:")
    print(f"   🔥 HIGH Impact Videos: {high_impact} (>200 views)")
    print(f"   ⚡ MEDIUM Impact Videos: {medium_impact} (50-200 views)")
    print(f"   🚀 RECOVERY Videos: {recovery_impact} (<50 views)")

if __name__ == "__main__":
    generate_complete_optimizations()
