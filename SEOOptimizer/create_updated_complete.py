#!/usr/bin/env python3
"""
🎯 CREATE UPDATED COMPLETE OPTIMIZATION FILE
Apply ConVRgence gameplay fixes + episode numbering preservation to the complete guide
"""

import re
from datetime import datetime

def create_updated_complete_file():
    print("🔄 Creating updated complete optimization file...")
    
    # Read the original complete file
    try:
        with open('complete_video_optimizations_20250915_162259.txt', 'r', encoding='utf-8') as f:
            content = f.read()
    except FileNotFoundError:
        print("❌ Original complete file not found")
        return
    
    # ConVRgence episode fixes (gameplay-focused)
    convrgence_fixes = {
        "FyAPzSVi2AE": {
            "title": "This VR Game is ADDICTIVE! 🎮 ConVRgence Episode 1 #vr #pcvr #gaming #convrgence",
            "desc_hook": "🎮 ConVRgence VR gameplay that will surprise you! This hidden VR gem has incredible mechanics and addictive gameplay..."
        },
        "kpxRbVpOZhg": {
            "title": "VR Game You've NEVER Heard Of! 😲 ConVRgence Episode 2 #vr #pcvr #gaming #hiddengem",
            "desc_hook": "🔥 You haven't seen VR gameplay like this! ConVRgence Episode 2 delivers amazing VR gaming mechanics..."
        },
        "zqtUJ3rmJf0": {
            "title": "EPIC VR Boss Fight! 🔥 ConVRgence Episode 3 #vr #pcvr #gaming #boss #convrgence",
            "desc_hook": "💎 This VR boss fight will blow your mind! ConVRgence Episode 3 showcases incredible VR combat..."
        },
        "BwU6QdViBMg": {
            "title": "VR Gameplay Gets CRAZY! 🤯 ConVRgence Episode 4 #vr #pcvr #gaming #convrgence",
            "desc_hook": "🚀 ConVRgence Episode 4 VR gaming at its finest! Watch me explore incredible VR mechanics..."
        },
        "Wb3GcMZDBP8": {
            "title": "This VR Game SURPRISED Me! 🎯 ConVRgence Episode 5 #vr #pcvr #gaming #convrgence",
            "desc_hook": "🎯 This VR episode caught me off guard! ConVRgence Episode 5 has some of the best VR gameplay..."
        },
        "RwxnlHMgZ1s": {
            "title": "Underrated VR Game! 💎 ConVRgence Episode 6 #vr #pcvr #gaming #underrated",
            "desc_hook": "💎 This VR game deserves more attention! ConVRgence Episode 6 delivers amazing gameplay experience..."
        },
        "n1XC9wd1Qzs": {
            "title": "VR Game UPDATE is AMAZING! 🚀 ConVRgence Episode 7 #vr #pcvr #gaming #update",
            "desc_hook": "🚀 ConVRgence Episode 7 update brings incredible new VR mechanics and gameplay improvements..."
        }
    }
    
    # Other series fixes (preserve episode numbering)
    series_fixes = {
        "P3-wHz7OI4k": "You WON'T Believe This VR Zombie! 😱 Part 5 Terrifying Gameplay #vr #zombies #pcvr #gaming #viral",
        "b_ll7uSuOLY": "You WON'T Believe This VR Zombie! 😱 Part 2 Terrifying Gameplay #vr #zombies #pcvr #gaming #viral",
        "43Cxfom6V34": "You WON'T Believe This VR Zombie! 😱 Part 3 Terrifying Gameplay #vr #zombies #pcvr #gaming #viral",
        "siDLs-a2-hw": "You WON'T Believe This VR Zombie! 😱 Part 4 Terrifying Gameplay #vr #zombies #pcvr #gaming #viral",
        "-uZjbr4GMAw": "You WON'T Believe This VR Zombie! 😱 Part 1 Terrifying Gameplay #vr #zombies #pcvr #gaming #viral",
        "n3r0IPCUQcs": "This VR Game BLEW MY MIND! 🤯 Into the Radius 2 Episode 1 #vr #pcvr #gaming #intotheradius2",
        "3nfoq1KfXys": "This Escape Episode is INSANE! 🔥 Wonderland Episode 4 VR Gaming #vr #pcvr #gaming #series"
    }
    
    # Apply all fixes
    updated_content = content
    
    # Fix ConVRgence videos
    for video_id, fixes in convrgence_fixes.items():
        # Update title
        title_pattern = f"Video ID: {video_id}.*?OPTIMIZED TITLE:\n(.*?)(?=\n\nOPTIMIZED DESCRIPTION:)"
        title_match = re.search(title_pattern, updated_content, re.DOTALL)
        if title_match:
            updated_content = updated_content.replace(title_match.group(1), fixes["title"])
        
        # Update description hook
        desc_pattern = f"Video ID: {video_id}.*?OPTIMIZED DESCRIPTION:\n(.*?)(?=\n\nWelcome to The Old Man Gamer)"
        desc_match = re.search(desc_pattern, updated_content, re.DOTALL)
        if desc_match:
            updated_content = updated_content.replace(desc_match.group(1), fixes["desc_hook"])
    
    # Fix other series videos
    for video_id, new_title in series_fixes.items():
        title_pattern = f"Video ID: {video_id}.*?OPTIMIZED TITLE:\n(.*?)(?=\n\nOPTIMIZED DESCRIPTION:)"
        title_match = re.search(title_pattern, updated_content, re.DOTALL)
        if title_match:
            updated_content = updated_content.replace(title_match.group(1), new_title)
    
    # Add ConVRgence tags update
    convrgence_tags = "VR, Virtual Reality, PCVR, Gaming, VR Gaming, Quest 3, VR Games, ConVRgence, Hidden Gem, Underrated VR, VR Gameplay, Indie VR, VR Review, Amazing VR, Best VR Games, VR Action, Immersive Gaming, Gaming Setup, VR Tips, The Old Man Gamer, VR Community, Epic Gaming, Addictive VR, VR Mechanics, Gameplay VR"
    
    # Update ConVRgence tags
    for video_id in convrgence_fixes.keys():
        tags_pattern = f"Video ID: {video_id}.*?OPTIMIZED TAGS:\n(.*?)(?=\n\n======================================================================)"
        tags_match = re.search(tags_pattern, updated_content, re.DOTALL)
        if tags_match:
            original_tags = tags_match.group(1)
            # Replace ConVRgence-specific part with updated tags
            if "ConVRgence" in original_tags:
                updated_tags = re.sub(r'ConVRgence.*?Immersive VR', convrgence_tags, original_tags)
                updated_content = updated_content.replace(tags_match.group(1), updated_tags)
    
    # Add header note about updates
    header_addition = """
🎯 UPDATED VERSION - September 15, 2025
======================================================================
✅ FIXES APPLIED:
- ConVRgence optimizations corrected (gameplay focus, not story)
- Episode numbering preserved for all series content
- All 109 videos ready for implementation

"""
    
    updated_content = updated_content.replace("COMPLETE YOUTUBE SEO OPTIMIZATION GUIDE\nALL 109 REGULAR VIDEOS - The Old Man Gamer\n======================================================================", 
                                            "COMPLETE YOUTUBE SEO OPTIMIZATION GUIDE\nALL 109 REGULAR VIDEOS - The Old Man Gamer" + header_addition)
    
    # Save updated file
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    new_filename = f'UPDATED_complete_video_optimizations_{timestamp}.txt'
    
    with open(new_filename, 'w', encoding='utf-8') as f:
        f.write(updated_content)
    
    print(f"✅ Created updated complete file: {new_filename}")
    print("🎯 This file contains:")
    print("   ✅ All 109 video optimizations")
    print("   ✅ ConVRgence fixes (gameplay-focused)")
    print("   ✅ Episode numbering preserved")
    print("   ✅ Copy-paste ready content")
    print("   📁 Ready for implementation!")
    
    return new_filename

if __name__ == "__main__":
    create_updated_complete_file()
