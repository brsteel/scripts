"""
Research-Enhanced YouTube SEO Optimizer
Based on comprehensive Steam page and competitor YouTube analysis

Game Intelligence Database:
- Into the Radius 2: Survival horror in Pechorsk Anomaly Zone, realistic weapons, day/night cycle
- ConVRgence: Extraction shooter with dog companion, Chernokamensk Zone, procedural generation
- Zombie Army VR: WWII zombie shooter with X-ray Kill Cam, authentic weapons, horde mode

Competitor Analysis:
- High-performing patterns: "The SCARIEST VR Game is BACK!" (140K views)
- Trending formats: "DANGEROUS VR Territory!", "VR REALISM at its FINEST!"
"""

import random
import re
from datetime import datetime

class ResearchEnhancedOptimizer:
    def __init__(self):
        self.game_research = {
            'into the radius 2': {
                'mechanics': ['Pechorsk Anomaly Zone', 'realistic weapons', 'artifacts', 'anomalies', 'survival horror', 'day/night cycle', 'procedural generation'],
                'templates': [
                    "The SCARIEST VR Game is BACK! 💀 Into the Radius 2",
                    "PHOTOREALISTIC VR Coop! 🔥 Into the Radius 2", 
                    "Most IMMERSIVE STALKER VR! 🌲 Into the Radius 2",
                    "VR SURVIVAL at its FINEST! 🎯 Into the Radius 2",
                    "DANGEROUS Anomaly Zone! ⚡ Into the Radius 2",
                    "Into the Radius 2 is ADVANCING! 🚀",
                    "ULTIMATE VR Survival! 💪 Into the Radius 2",
                    "VR REALISM Perfection! 🎮 Into the Radius 2",
                    "HARDEST VR Difficulty! 😰 Into the Radius 2",
                    "MODULAR Weapons VR! 🔫 Into the Radius 2"
                ],
                'hashtags': '#intotheradius2 #vr #pcvr #gaming #stalker'
            },
            'convrgence': {
                'mechanics': ['extraction shooter', 'dog companion', 'Chernokamensk Anomaly Zone', 'procedural generation', 'bandit encounters', 'demon hunting'],
                'templates': [
                    "Roaming CHERNOBYL in VR! ☢️ ConVRgence",
                    "The Soviet VR Game! 🌲 ConVRgence", 
                    "STALKER VR Extraction Shooter! 🎯 ConVRgence",
                    "AI BEG for Their Lives! 😰 ConVRgence VR",
                    "Best STALKER-Style VR Game! ⭐ ConVRgence",
                    "VR Game with DOG Companion! 🐕 ConVRgence",
                    "MASSIVE Update! 🚀 ConVRgence VR",
                    "New BOSS Enemy! 💀 ConVRgence VR",
                    "CROSSBOW Action! 🏹 ConVRgence VR",
                    "FLAMETHROWER Mayhem! 🔥 ConVRgence VR"
                ],
                'hashtags': '#vr #pcvr #gaming #convrgence #stalker'
            },
            'zombie army vr': {
                'mechanics': ['WWII zombie shooter', 'X-ray Kill Cam', 'authentic weapons', 'horde mode', 'co-op gameplay'],
                'templates': [
                    "Is This The NEXT BEST VR Zombie Game?! 🧟",
                    "ZOMBIE ARMY VR Full Review! 💀 Epic Horror",
                    "Brains EXPLODE in VR! 🔥 Zombie Army VR", 
                    "VR Zombie HORDE Mode! 🎯 Survival Horror",
                    "UNDEAD VR Warfare! ⚔️ Zombie Army VR",
                    "VR's Left 4 Dead?! 💥 Zombie Army VR",
                    "WWII Zombies in VR! 🪖 Zombie Army VR",
                    "X-RAY Kill Cam VR! 💀 Zombie Army VR"
                ],
                'hashtags': '#vr #zombies #pcvr #gaming #horror'
            }
        }
        
    def optimize_title(self, video):
        """Generate research-enhanced titles based on competitor analysis - MAX 100 CHARACTERS"""
        current_title = video['title']
        game_key = self._identify_game(current_title)
        
        if game_key and game_key in self.game_research:
            game_data = self.game_research[game_key]
            base_title = random.choice(game_data['templates'])
            
            # Add version info if present
            version = self._extract_version(current_title)
            if version:
                base_title += f" {version}"
                
            # Add episode/part info
            episode = self._extract_episode(current_title)
            if episode:
                base_title += f" {episode}"
                
            # Add specific context
            context = self._extract_context(current_title, game_data['mechanics'])
            if context:
                base_title += f" {context}"
                
            # Build full title with hashtags
            full_title = base_title + " " + game_data['hashtags']
            
            # Ensure title is under 100 characters
            return self._truncate_title(full_title, game_data['hashtags'])
        else:
            # Generic VR optimization
            base = f"This VR Game Will BLOW Your Mind! 🤯 {current_title[:20]}..."
            hashtags = " #vr #pcvr #gaming"
            return self._truncate_title(base + hashtags, hashtags)
    
    def optimize_description(self, video):
        """Generate research-enhanced descriptions with game mechanics"""
        current_title = video['title']
        current_desc = video.get('description', '')
        game_key = self._identify_game(current_title)
        
        if game_key and game_key in self.game_research:
            game_data = self.game_research[game_key]
            
            # Build description based on research
            if game_key == 'into the radius 2':
                return self._build_into_radius_description(current_title, game_data)
            elif game_key == 'convrgence':
                return self._build_convrgence_description(current_title, game_data)
            elif game_key == 'zombie army vr':
                return self._build_zombie_army_description(current_title, game_data)
        
        # Generic VR description
        return f"""🎮 Epic VR Gaming Experience!

In this video, I dive into an incredible VR adventure that showcases the best of virtual reality gaming! 

🔥 What You'll See:
• Immersive VR gameplay
• Epic moments and reactions
• Amazing graphics and physics
• VR gaming at its finest

💬 What do you think about this VR experience? Let me know in the comments!

👍 If you enjoyed this video, please LIKE and SUBSCRIBE for more VR content!

#VR #VirtualReality #PCGaming #Gaming #VRGameplay"""

    def _identify_game(self, title):
        """Identify game from title"""
        title_lower = title.lower()
        for game_key in self.game_research.keys():
            if game_key.replace(' ', '') in title_lower.replace(' ', ''):
                return game_key
        return None
    
    def _extract_version(self, title):
        """Extract version information"""
        patterns = [r'v?(\d+\.\d+)', r'\.(\d+\.\d+)', r'EA.*?(\d+\.\d+)']
        for pattern in patterns:
            match = re.search(pattern, title)
            if match:
                return f"v{match.group(1)}"
        return None
    
    def _extract_episode(self, title):
        """Extract episode/part information"""
        patterns = [r'part (\d+)', r'episode (\d+)', r'ep (\d+)']
        for pattern in patterns:
            match = re.search(pattern, title.lower())
            if match:
                return f"Part {match.group(1)}"
        return None
    
    def _extract_context(self, title, mechanics):
        """Extract relevant context based on game mechanics"""
        title_lower = title.lower()
        context_map = {
            'realistic': 'Realistic Mode',
            'nightmare': 'Nightmare Difficulty',
            'pechorsk': 'Pechorsk Outskirts',
            'security': 'Security Level',
            'ghost': 'Ghost Town',
            'climbing': 'Climbing Challenge',
            'boss': 'Boss Battle',
            'horde': 'Horde Mode',
            'coop': 'Co-op Mode'
        }
        
        for keyword, context in context_map.items():
            if keyword in title_lower:
                return context
        return None
    
    def _truncate_title(self, title, essential_hashtags):
        """Ensure title is under 100 characters while preserving essential hashtags"""
        if len(title) <= 100:
            return title
            
        # Essential hashtags that must be preserved
        core_hashtags = " #vr #pcvr"
        
        # If title is too long, progressively remove non-essential hashtags
        parts = title.split(' #')
        base_title = parts[0]  # Everything before first hashtag
        
        # Start with core hashtags
        current_title = base_title + core_hashtags
        
        # Add back important game-specific hashtags if space allows
        game_hashtags = ['intotheradius2', 'convrgence', 'zombies', 'stalker']
        for hashtag in game_hashtags:
            test_addition = f" #{hashtag}"
            if hashtag in title.lower() and len(current_title + test_addition) <= 100:
                current_title += test_addition
        
        # If still too long, truncate the base title
        if len(current_title) > 100:
            available_space = 100 - len(core_hashtags)
            base_title = base_title[:available_space-3] + "..."
            current_title = base_title + core_hashtags
            
        return current_title
    
    def _build_into_radius_description(self, title, game_data):
        """Build Into the Radius 2 specific description"""
        return f"""🌲 Into the Radius 2 - The Most REALISTIC VR Survival Experience!

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

    def _build_convrgence_description(self, title, game_data):
        """Build ConVRgence specific description"""
        return f"""☢️ ConVRgence - The STALKER VR Game You've Never Heard Of!

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

#ConVRgence #VR #PCVR #STALKER #ExtractionShooter #HiddenGem #VirtualReality"""

    def _build_zombie_army_description(self, title, game_data):
        """Build Zombie Army VR specific description"""
        return f"""🧟 Zombie Army VR - WWII Zombie Carnage in Virtual Reality!

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

#ZombieArmyVR #VR #PCVR #Zombies #WWII #Horror #VirtualReality"""

def generate_complete_optimizations():
    """Generate all optimizations with research intelligence"""
    optimizer = ResearchEnhancedOptimizer()
    
    # Sample video data (you would replace with actual video data)
    sample_videos = [
        {'title': 'Into the Radius 2 .13.7 Pechorsk Outskirts Realistic Mode', 'description': ''},
        {'title': 'ConVRgence VR Game Episode 1', 'description': ''},
        {'title': 'Zombie Army VR Part 1 First Mission', 'description': ''}
    ]
    
    print("🎯 RESEARCH-ENHANCED YOUTUBE OPTIMIZATIONS")
    print("=" * 60)
    print("Based on Steam page analysis and competitor research")
    print("High-performing title patterns from 140K-342K view videos")
    print()
    
    for i, video in enumerate(sample_videos, 1):
        print(f"📹 VIDEO {i}: {video['title']}")
        print("-" * 50)
        
        optimized_title = optimizer.optimize_title(video)
        optimized_description = optimizer.optimize_description(video)
        
        print(f"✨ OPTIMIZED TITLE:")
        print(f"{optimized_title}")
        print()
        
        print(f"📝 RESEARCH-ENHANCED DESCRIPTION:")
        print(optimized_description)
        print()
        print("=" * 60)
        print()

def generate_analytics_enhanced_optimizations():
    """Generate optimizations with analytics insights"""
    import pandas as pd
    
    try:
        df = pd.read_csv('video_analytics.csv')
        print("📊 ANALYTICS-ENHANCED COMPLETE OPTIMIZATIONS")
        print("=" * 60)
        print()
        
        optimizer = ResearchEnhancedOptimizer()
        
        for index, video in df.iterrows():
            title = video['title']
            views = video.get('views', 0)
            likes = video.get('likes', 0)
            comments = video.get('comments', 0)
            
            # Calculate engagement rate
            engagement_rate = ((likes + comments) / views * 100) if views > 0 else 0
            
            print(f"🎬 VIDEO {index + 1}: {title}")
            print(f"📊 Current Stats: {views:,} views | {likes} likes | {comments} comments | {engagement_rate:.2f}% engagement")
            print()
            
            # Generate optimizations with analytics context
            game_type = optimizer.identify_game_type(title)
            optimized_titles = optimizer.generate_research_enhanced_titles(title, game_type)
            optimized_description = optimizer.generate_research_enhanced_description(title, game_type)
            optimized_tags = optimizer.generate_optimized_tags(title, game_type)
            
            print("🔥 OPTIMIZED TITLE:")
            print(f"   {optimized_titles[0][:100]}")  # Ensure 100 char limit
            print()
            
            print("📝 OPTIMIZED DESCRIPTION:")
            print(optimized_description)
            
            if engagement_rate > 0:
                print(f"\n💡 PERFORMANCE INSIGHT:")
                if engagement_rate > 3:
                    print("   🔥 High engagement! This content style works well.")
                elif engagement_rate > 1:
                    print("   ✅ Good engagement. Consider similar content.")
                else:
                    print("   📈 Room for improvement with these optimizations.")
            
            print(f"\n🏷️ OPTIMIZED TAGS:")
            print(f"   {', '.join(optimized_tags)}")
            print()
            print("=" * 60)
            print()
            
    except FileNotFoundError:
        print("❌ video_analytics.csv not found. Run basic optimization instead.")
        generate_complete_optimizations()

if __name__ == "__main__":
    generate_complete_optimizations()
