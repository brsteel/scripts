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
    
    # Find essential hashtags in the title
    hashtags = []
    essential_order = ['vr', 'pcvr', 'intotheradius2', 'convrgence', 'zombies', 'stalker']
    
    for tag in essential_order:
        if f'#{tag}' in title.lower():
            hashtags.append(f'#{tag}')
            if len(' '.join([base_title] + hashtags)) >= 95:  # Leave some buffer
                break
    
    # Build final title
    hashtag_text = ' ' + ' '.join(hashtags) if hashtags else ''
    available_space = 100 - len(hashtag_text)
    
    if len(base_title) > available_space:
        base_title = base_title[:available_space-3] + "..."
    
    return base_title + hashtag_text

def optimize_title(original_title, video_data=None):
    """Generate unique, dynamic title for each video - MAX 100 CHARACTERS"""
    
    # Extract episode/part numbering
    episode_match = re.search(r'(Episode|Part)\s+(\d+)', original_title, re.IGNORECASE)
    episode_text = ""
    if episode_match:
        episode_text = f" {episode_match.group(1).title()} {episode_match.group(2)}"
    
    # Extract version info
    version_info = extract_version_info(original_title)
    version_text = f" {version_info}" if version_info else ""
    
    # Extract game name and hashtag
    game_hashtag = ""
    if "radius" in original_title.lower():
        game_hashtag = "#intotheradius2"
    elif "zombie" in original_title.lower():
        game_hashtag = "#zombiearmyvr"
    elif "convrgence" in original_title.lower():
        game_hashtag = "#convrgence"
    elif "gorn" in original_title.lower():
        game_hashtag = "#gorn2"
    elif "unloop" in original_title.lower():
        game_hashtag = "#unloop"
    elif "wonderland" in original_title.lower():
        game_hashtag = "#escapingwonderland"
    
    # Dynamic title generation with character limits
    
    # ConVRgence - Keep existing unique titles but limit characters
    if "convrgence" in original_title.lower():
        if "episode 1" in original_title.lower():
            return truncate_title_to_100_chars("Roaming CHERNOBYL in VR! ☢️ ConVRgence Episode 1 #vr #pcvr #convrgence #stalker")
        elif "episode 2" in original_title.lower():
            return truncate_title_to_100_chars("STALKER VR Extraction Shooter! 🎯 ConVRgence Episode 2 #vr #pcvr #convrgence")
        elif "episode 3" in original_title.lower():
            return truncate_title_to_100_chars("VR Game with DOG Companion! 🐕 ConVRgence Episode 3 #vr #pcvr #convrgence")
        elif "episode 4" in original_title.lower():
            return truncate_title_to_100_chars("AI BEG for Their Lives! 😰 ConVRgence Episode 4 #vr #pcvr #convrgence")
        elif "episode 5" in original_title.lower():
            return truncate_title_to_100_chars("CROSSBOW Action! 🏹 ConVRgence Episode 5 #vr #pcvr #convrgence #stalker")
        elif "episode 6" in original_title.lower():
            return truncate_title_to_100_chars("MASSIVE Update! 🚀 ConVRgence Episode 6 #vr #pcvr #convrgence #stalker")
        elif "episode 7" in original_title.lower():
            return truncate_title_to_100_chars("FLAMETHROWER Mayhem! 🔥 ConVRgence Episode 7 #vr #pcvr #convrgence")
        else:
            return truncate_title_to_100_chars("The Soviet VR Game! 🌲 ConVRgence #vr #pcvr #convrgence #stalker")
    
    # Into the Radius 2 - Dynamic unique titles
    elif "radius" in original_title.lower():
        if "pechorsk" in original_title.lower() and "outskirt" in original_title.lower():
            return truncate_title_to_100_chars(f"DANGEROUS Anomaly Zone! ⚡ Into the Radius 2{version_text} #intotheradius2 #vr #pcvr")
        elif "climbing" in original_title.lower():
            return truncate_title_to_100_chars(f"INSANE VR Climbing! 🧗 Into the Radius 2{version_text} #intotheradius2 #vr #pcvr")
        elif "realistic" in original_title.lower():
            return truncate_title_to_100_chars(f"VR REALISM at its FINEST! 🎯 Into the Radius 2{version_text} #intotheradius2 #vr #pcvr")
        elif "ghost town" in original_title.lower():
            return truncate_title_to_100_chars(f"The SCARIEST VR Game is BACK! 💀 Into the Radius 2{version_text} #intotheradius2 #vr")
        elif "nightmare" in original_title.lower():
            return truncate_title_to_100_chars(f"VR NIGHTMARE Mode! 😱 Into the Radius 2{version_text} #intotheradius2 #vr #pcvr")
        elif "security level" in original_title.lower():
            return truncate_title_to_100_chars(f"MAXIMUM Security VR! 🚨 Into the Radius 2{version_text} #intotheradius2 #vr #pcvr")
        elif "enemy count" in original_title.lower():
            return truncate_title_to_100_chars(f"VR Enemy SWARM Mode! 🔥 Into the Radius 2{version_text} #intotheradius2 #vr #pcvr")
        else:
            return truncate_title_to_100_chars(f"PHOTOREALISTIC VR Coop! 🔥 Into the Radius 2{version_text}{episode_text} #intotheradius2 #vr #pcvr")
    
    # Zombie Army VR - Dynamic unique titles
    elif "zombie" in original_title.lower():
        if "part 1" in original_title.lower():
            return truncate_title_to_100_chars("Is This The NEXT BEST VR Zombie Game?! 🧟 Zombie Army VR Part 1 #vr #zombies #pcvr")
        elif "part 2" in original_title.lower():
            return truncate_title_to_100_chars("WWII Zombies in VR! 🪖 Zombie Army VR Part 2 #vr #zombies #pcvr")
        elif "part 3" in original_title.lower():
            return truncate_title_to_100_chars("VR Zombie CHAOS Mode! 🔥 Zombie Army VR Part 3 #vr #zombies #pcvr")
        elif "part 4" in original_title.lower():
            return truncate_title_to_100_chars("FINAL Zombie Battle! ⚔️ Zombie Army VR Part 4 #vr #zombies #pcvr")
        elif "part 5" in original_title.lower():
            return truncate_title_to_100_chars("Zombie VICTORY Finale! 🏆 Zombie Army VR Part 5 #vr #zombies #pcvr")
        elif "horde" in original_title.lower():
            return truncate_title_to_100_chars("VR Zombie HORDE Mode! 🎯 Zombie Army VR #vr #zombies #pcvr")
        elif "x-ray" in original_title.lower() or "xray" in original_title.lower():
            return truncate_title_to_100_chars("X-RAY Kill Cam VR! 💀 Zombie Army VR #vr #zombies #pcvr #horror")
        else:
            return truncate_title_to_100_chars(f"UNDEAD VR Warfare! ⚔️ Zombie Army VR{episode_text} #vr #zombies #pcvr")
    
    # Other games - Unique patterns
    elif "gorn" in original_title.lower():
        if "boss" in original_title.lower():
            return truncate_title_to_100_chars("EPIC VR Gladiator Returns! ⚔️ Gorn 2 Boss Battle #vr #gaming #pcvr #boss")
        else:
            return truncate_title_to_100_chars("BRUTAL Physics Combat! 💀 Gorn 2 #vr #gaming #pcvr")
    elif "unloop" in original_title.lower():
        return truncate_title_to_100_chars("This UNKNOWN VR Game is AMAZING! 🤩 Unloop Hidden Gem #vr #pcvr #hiddengem")
    elif "wonderland" in original_title.lower():
        return truncate_title_to_100_chars(f"VR Wonderland NIGHTMARE! 🐰 Escaping Wonderland{episode_text} #vr #pcvr #puzzle")
    
    # Fallback for any unmatched games
    else:
        return truncate_title_to_100_chars(f"This VR Game Will BLOW Your Mind! 🤯 {original_title[:20]}... #vr #pcvr #gaming")

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

def optimize_description(description, video_data, optimized_title=""):
    """Generate optimized description with game-specific knowledge"""
    
    if not optimized_title:
        return description
    
    # Determine game and create appropriate description
    if "radius" in optimized_title.lower():
        return generate_radius_description(optimized_title)
    elif "convrgence" in optimized_title.lower():
        return generate_convrgence_description(optimized_title)
    elif "zombie" in optimized_title.lower():
        return generate_zombie_description(optimized_title)
    elif "gorn" in optimized_title.lower():
        return generate_gorn_description(optimized_title)
    elif "wonderland" in optimized_title.lower():
        return generate_wonderland_description(optimized_title)
    elif "unloop" in optimized_title.lower():
        return generate_unloop_description(optimized_title)
    else:
        return generate_generic_vr_description(optimized_title)

def generate_radius_description(title):
    """Generate Into the Radius 2 specific description"""
    return """🌲 Into the Radius 2 - The Most REALISTIC VR Survival Experience!

Welcome back to the Pechorsk Anomaly Zone! In this episode, I'm diving deep into the most immersive STALKER-inspired VR game ever created.

🔥 What Makes This AMAZING:
• Photorealistic graphics that will blow your mind
• Realistic weapon handling and modular customization
• Dangerous anomalies and artifact hunting
• Day/night cycle with dynamic weather
• Procedurally generated missions
• Co-op multiplayer support

⚡ The Pechorsk Zone Features:
• Realistic ballistics and weapon physics
• Terrifying anomalies that can kill instantly
• Valuable artifacts hidden throughout
• Dynamic AI enemies and mutants
• Immersive survival mechanics

This is easily one of the best VR games available right now, combining the atmosphere of STALKER with cutting-edge VR technology!

💬 Have you played Into the Radius 2? Share your zone experiences in the comments!

👍 SMASH that LIKE button if you want to see more Into the Radius 2 content!
🔔 SUBSCRIBE for daily VR gaming adventures!

#IntoTheRadius2 #VR #PCVR #STALKER #SurvivalHorror #VirtualReality

🏷️ OPTIMIZED TAGS:
Into the Radius 2, VR survival, STALKER VR, Pechorsk Zone, realistic VR, anomaly zone, VR horror, survival horror VR, PCVR gaming, Quest 3 VR, modular weapons VR, procedural VR, co-op VR, artifact hunting, VR physics, immersive VR"""

def generate_convrgence_description(title):
    """Generate ConVRgence specific description"""
    return """☢️ ConVRgence - The STALKER VR Game You've Never Heard Of!

Step into the Chernokamensk Anomaly Zone with your faithful dog companion in this incredible extraction shooter that's flying under the radar!

🔥 Why ConVRgence is SPECIAL:
• True STALKER atmosphere in VR
• Loyal dog companion that follows you everywhere
• Extraction shooter mechanics
• Procedurally generated locations
• Bandit encounters and demon hunting
• Deep weapon customization
• Dynamic day/night survival

🌲 The Zone Experience:
• Atmospheric Soviet-era environments
• Intelligent AI that begs for mercy
• Crossbow and flamethrower combat
• Massive world updates regularly
• Hidden secrets and lore to discover
• Immersive inventory management

This is the VR STALKER game we've been waiting for! ConVRgence deserves WAY more attention than it's getting.

💬 Would you survive the Chernokamensk Zone? Let me know in the comments!

👍 If you enjoyed discovering this hidden VR gem, LIKE and SUBSCRIBE!

#ConVRgence #VR #PCVR #STALKER #ExtractionShooter #HiddenGem #VirtualReality

🏷️ OPTIMIZED TAGS:
ConVRgence, STALKER VR, Chernobyl VR, extraction shooter VR, dog companion VR, Soviet VR, anomaly zone VR, hidden VR gems, underrated VR, PCVR shooter, VR survival, zone exploration VR"""

def generate_zombie_description(title):
    """Generate Zombie Army VR specific description"""
    return """🧟 Zombie Army VR - WWII Zombie Carnage in Virtual Reality!

Get ready for the most BRUTAL zombie-slaying experience in VR! This isn't your typical zombie game - it's World War II meets undead horror with incredible X-ray kill cam action!

🔥 What Makes This EPIC:
• Authentic WWII weapons and equipment
• Incredible X-ray Kill Cam system
• Massive zombie horde battles
• Co-op multiplayer mayhem
• Multiple game modes including Horde
• Spectacular physics-based combat
• Left 4 Dead meets Sniper Elite vibes

💀 The Zombie Experience:
• Satisfying headshot mechanics
• Environmental kills and explosions
• Strategic weapon selection
• Intense survival scenarios
• Epic boss zombie encounters
• Immersive WWII atmosphere

This is hands down one of the best VR zombie games available! The combination of historical weapons and supernatural enemies creates an unforgettable experience.

💬 What's your favorite VR zombie game? Share your undead adventures below!

👍 LIKE if you want to see more zombie-slaying VR content!
🔔 SUBSCRIBE for more VR horror and action games!

#ZombieArmyVR #VR #PCVR #Zombies #WWII #Horror #VirtualReality

🏷️ OPTIMIZED TAGS:
Zombie Army VR, WWII VR, zombie VR games, X-ray kill cam VR, VR zombie shooter, historical VR, horror VR, co-op VR zombies, horde mode VR, PCVR zombies, authentic weapons VR, undead VR"""

def generate_gorn_description(title):
    """Generate Gorn 2 specific description"""
    return """⚔️ Gorn 2 - Gladiator Combat in VR!

Physics-based combat has never felt so satisfying in VR! Gorn 2 brings brutal gladiator battles to life.

🔥 Gorn 2 Features:
• Brutal gladiator combat
• Physics-based weapon systems
• Epic boss encounters
• Cartoony violence
• Arena championship battles

This is VR combat at its most fun and chaotic!

👍 LIKE if you want to see more gladiator action!
🔔 SUBSCRIBE for VR combat games!

#Gorn2 #VR #PCVR #Gladiator #Boss #Combat"""

def generate_wonderland_description(title):
    """Generate Escaping Wonderland specific description"""
    return """🐰 Escaping Wonderland - Alice's Dark VR Journey!

This isn't the Wonderland you remember! This VR puzzle adventure takes Alice's story to dark and twisted places.

🔥 Wonderland VR Features:
• Dark twisted Alice story
• Challenging VR puzzles
• Atmospheric environments
• Unique character interactions
• Immersive story adventure

Experience Wonderland like never before in VR!

👍 LIKE if you love VR puzzle adventures!
🔔 SUBSCRIBE for more story-driven VR!

#EscapingWonderland #VR #PCVR #Alice #Puzzle #Adventure"""

def generate_unloop_description(title):
    """Generate Unloop specific description"""
    return """🤩 Unloop - The VR Hidden Gem You Need to Play!

Unloop is flying completely under the radar, but it's one of the most innovative VR games I've played recently!

🔥 Why Unloop is Special:
• Unique gameplay mechanics
• Beautiful visual design
• Innovative VR interactions
• Underrated masterpiece
• Hidden gem discovery

Don't sleep on this incredible VR experience!

👍 LIKE if you want to discover more hidden VR gems!
🔔 SUBSCRIBE for VR game discoveries!

#Unloop #VR #PCVR #HiddenGem #Amazing #Discovery"""

def generate_generic_vr_description(title):
    """Generate generic VR description"""
    return """🎮 Epic VR Gaming Experience!

In this video, I dive into an incredible VR adventure that showcases the best of virtual reality gaming!

🔥 What You'll See:
• Immersive VR gameplay
• Epic moments and reactions
• Amazing graphics and physics
• VR gaming at its finest

💬 What do you think about this VR experience? Let me know in the comments!

👍 If you enjoyed this video, please LIKE and SUBSCRIBE for more VR content!

#VR #VirtualReality #PCGaming #Gaming #VRGameplay"""
