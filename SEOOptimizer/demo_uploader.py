#!/usr/bin/env python3
"""
YouTube Auto-Uploader Demo
Shows example of generated content without actually uploading
"""

from youtube_auto_uploader import YouTubeAutoUploader

def demo_content_generation():
    """Demo the content generation without uploading"""
    print("🎬 YouTube Auto-Uploader Content Generation Demo")
    print("=" * 50)
    
    uploader = YouTubeAutoUploader()
    
    # Demo scenarios based on your content
    scenarios = [
        {
            "name": "Into the Radius 2 Sniper Short",
            "prompt": "Amazing long-range sniper shots with the new SR-25 rifle scope in Into the Radius 2 v0.14.1 beta",
            "is_short": True,
            "video_path": "sniper_shots_short.mp4"
        },
        {
            "name": "ConVRgence Episode",
            "prompt": "ConVRgence Episode 8 - explored the new underground facility with my dog companion, found some rare artifacts",
            "is_short": False,
            "video_path": "convrgence_ep8.mp4"
        },
        {
            "name": "Zombie Army VR Boss Fight",
            "prompt": "Epic boss battle in Zombie Army VR Part 6 - massive zombie horde encounter with X-ray kill cam action",
            "is_short": False,
            "video_path": "zombie_army_boss.mp4"
        },
        {
            "name": "Generic VR Short",
            "prompt": "Incredible physics interaction in VR - throwing objects and realistic hand tracking",
            "is_short": True,
            "video_path": "vr_physics_short.mp4"
        }
    ]
    
    for i, scenario in enumerate(scenarios, 1):
        print(f"\n🎯 Scenario {i}: {scenario['name']}")
        print("-" * 30)
        
        content = uploader.generate_content(
            scenario['prompt'], 
            scenario['video_path'], 
            scenario['is_short']
        )
        
        print(f"📱 Type: {'Short' if scenario['is_short'] else 'Regular Video'}")
        print(f"🎮 Detected Game: {content.get('detected_game', 'Generic VR')}")
        print(f"🎯 Title ({len(content['title'])} chars): {content['title']}")
        print(f"\n📝 Description ({len(content['description'])} chars):")
        print(content['description'][:200] + "..." if len(content['description']) > 200 else content['description'])
        print(f"\n🏷️ Tags ({len(content['tags'])} total):")
        print(", ".join(content['tags'][:8]) + ("..." if len(content['tags']) > 8 else ""))
        
        if i < len(scenarios):
            input("\nPress Enter to see next scenario...")
    
    print("\n🎉 Demo complete! These are the kinds of optimizations your uploader will generate automatically.")
    print("\n🚀 Ready to try the real thing? Run:")
    print("   python youtube_auto_uploader.py")

if __name__ == "__main__":
    demo_content_generation()