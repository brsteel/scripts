#!/usr/bin/env python3
"""
YouTube Auto-Uploader with AI-Powered SEO Optimization
=======================================================

Features:
- Upload videos/shorts with custom thumbnails
- AI-powered title, description, and tag generation
- Playlist management
- Interactive approval workflow
- Automatic SEO optimization based on your channel's successful patterns

Author: AI Assistant for The Old Man Gamer
Created: September 16, 2025
"""

import os
import sys
import json
import time
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from datetime import datetime

# Google API imports
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
from google.auth.transport.requests import Request
import pickle

# For AI content generation
import re
from datetime import datetime, timedelta

# Try to import dateutil for advanced date parsing
try:
    import dateutil.parser
    HAS_DATEUTIL = True
except ImportError:
    HAS_DATEUTIL = False
    print("💡 Tip: Install python-dateutil for advanced scheduling: pip install python-dateutil")

class YouTubeAutoUploader:
    def __init__(self, credentials_path: str = None):
        """Initialize the YouTube Auto-Uploader"""
        self.credentials_path = credentials_path or "client_secret_102034359712-upvn0ts1m88qp811hfi160ca2a9hh7pb.apps.googleusercontent.com.json"
        self.token_path = "youtube_upload_token.pickle"
        
        # YouTube API scopes
        self.scopes = [
            "https://www.googleapis.com/auth/youtube.upload",
            "https://www.googleapis.com/auth/youtube.readonly",
            "https://www.googleapis.com/auth/youtube"
        ]
        
        self.youtube = None
        self.channel_info = None
        
        # Your proven successful patterns for SEO
        self.successful_patterns = {
            "title_hooks": [
                "INSANE", "INCREDIBLE", "AMAZING", "EPIC", "BRUTAL", 
                "TERRIFYING", "MIND-BLOWING", "PHOTOREALISTIC", "ULTIMATE"
            ],
            "vr_games": {
                "Into the Radius 2": {
                    "hashtags": ["#intotheradius2", "#vr", "#pcvr"],
                    "keywords": ["Into the Radius 2", "VR survival", "STALKER VR", "realistic VR", "anomaly VR"],
                    "description_template": "🌲 Into the Radius 2 - The Most REALISTIC VR Survival Experience!\n\n{content}\n\n🔥 What Makes This INCREDIBLE:\n• Photorealistic graphics and immersion\n• Realistic weapon handling and physics\n• Dangerous anomalies and artifacts\n• Atmospheric Zone exploration\n• {specific_features}\n\n⚡ The VR Experience:\n• Physical interaction with everything\n• Authentic survival mechanics\n• Environmental storytelling\n• Genuine fear and tension\n• Next-level immersion\n\nThis is easily one of the best VR survival games available! The level of realism and atmospheric immersion showcases what VR gaming can achieve.\n\n🎮 Game: Into the Radius 2\n🎯 Platform: PC VR (Oculus, SteamVR)\n📍 Location: Pechorsk Anomaly Zone"
                },
                "ConVRgence": {
                    "hashtags": ["#vr", "#pcvr", "#convrgence", "#stalker"],
                    "keywords": ["ConVRgence", "STALKER VR", "extraction shooter", "VR hidden gem", "dog companion VR"],
                    "description_template": "☢️ ConVRgence - The STALKER VR Game You've Never Heard Of!\n\n{content}\n\n🔥 Why ConVRgence is SPECIAL:\n• True STALKER atmosphere in VR\n• Loyal dog companion that follows everywhere\n• Extraction shooter mechanics\n• {specific_features}\n\n🌲 The Zone Experience:\n• Atmospheric Soviet-era environments\n• Intelligent AI that begs for mercy\n• Hidden secrets and lore\n• Immersive survival gameplay\n\nThis is the VR STALKER game we've been waiting for! ConVRgence deserves WAY more attention than it's getting.\n\n🎮 Game: ConVRgence\n🎯 Platform: PC VR\n📍 Setting: Chernokamensk Anomaly Zone"
                },
                "Zombie Army VR": {
                    "hashtags": ["#vr", "#zombies", "#pcvr"],
                    "keywords": ["Zombie Army VR", "VR zombie games", "WWII zombie VR", "VR horror", "zombie survival VR"],
                    "description_template": "🧟 Zombie Army VR - WWII Zombie Carnage in Virtual Reality!\n\n{content}\n\n🔥 What Makes This EPIC:\n• Authentic WWII weapons and atmosphere\n• Incredible X-ray Kill Cam system\n• Massive zombie horde battles\n• {specific_features}\n\n💀 The Zombie Experience:\n• Satisfying headshot mechanics\n• Environmental kills and explosions\n• Strategic weapon selection\n• Left 4 Dead meets Sniper Elite vibes\n\nThis is hands down one of the best VR zombie experiences available!\n\n🎮 Game: Zombie Army VR\n🎯 Platform: PC VR\n⚔️ Setting: WWII Zombie Apocalypse"
                }
            },
            "shorts_patterns": {
                "sniper": "🎯 {hook_word} VR Sniper Shots! Into the Radius 2 SR-25 #vr #sniper #intotheradius2 #shorts",
                "action": "⚡ {hook_word} VR Action! {game} #vr #{game_tag} #shorts",
                "showcase": "🔥 {hook_word} VR Gameplay! {game} #vr #{game_tag} #gaming #shorts"
            }
        }
        
    def authenticate(self) -> bool:
        """Authenticate with YouTube API"""
        creds = None
        
        # Load existing token
        if os.path.exists(self.token_path):
            with open(self.token_path, 'rb') as token:
                creds = pickle.load(token)
                
        # If no valid credentials, get new ones
        if not creds or not creds.valid:
            if creds and creds.expired and creds.refresh_token:
                creds.refresh(Request())
            else:
                if not os.path.exists(self.credentials_path):
                    print(f"❌ Error: Credentials file not found: {self.credentials_path}")
                    return False
                    
                flow = InstalledAppFlow.from_client_secrets_file(
                    self.credentials_path, self.scopes)
                creds = flow.run_local_server(port=0)
                
            # Save credentials for next run
            with open(self.token_path, 'wb') as token:
                pickle.dump(creds, token)
                
        try:
            self.youtube = build('youtube', 'v3', credentials=creds)
            
            # Get channel info
            channel_response = self.youtube.channels().list(
                mine=True,
                part="id,snippet,statistics"
            ).execute()
            
            if channel_response['items']:
                self.channel_info = channel_response['items'][0]
                print(f"✅ Authenticated as: {self.channel_info['snippet']['title']}")
                return True
            else:
                print("❌ Error: Could not retrieve channel information")
                return False
                
        except Exception as e:
            print(f"❌ Authentication failed: {str(e)}")
            return False
            
    def detect_video_type(self, video_path: str) -> Tuple[bool, int]:
        """Detect if video is a Short based on duration and aspect ratio"""
        try:
            # For now, we'll use a simple file size and name heuristic
            # In production, you'd want to use ffprobe or similar
            file_size = os.path.getsize(video_path)
            filename = os.path.basename(video_path).lower()
            
            # Simple heuristics (you can enhance these)
            is_short = (
                'short' in filename or 
                'shorts' in filename or
                file_size < 50 * 1024 * 1024  # Less than 50MB likely a short
            )
            
            # Estimate duration (placeholder - use ffprobe in production)
            estimated_duration = 60 if is_short else 600  # 1 min for shorts, 10 min for regular
            
            return is_short, estimated_duration
            
        except Exception as e:
            print(f"⚠️ Could not detect video type: {str(e)}")
            return False, 600  # Default to regular video
            
    def get_playlists(self) -> Dict[str, str]:
        """Fetch user's playlists"""
        try:
            playlists = {}
            request = self.youtube.playlists().list(
                part="snippet",
                mine=True,
                maxResults=50
            )
            
            while request:
                response = request.execute()
                
                for playlist in response['items']:
                    playlists[playlist['snippet']['title']] = playlist['id']
                    
                request = self.youtube.playlists().list_next(request, response)
                
            return playlists
            
        except Exception as e:
            print(f"⚠️ Could not fetch playlists: {str(e)}")
            return {}
            
    def generate_content(self, user_prompt: str, video_path: str, is_short: bool = False) -> Dict[str, str]:
        """Generate optimized title, description, and tags based on user prompt"""
        
        # Detect game from prompt
        game_detected = None
        for game in self.successful_patterns["vr_games"].keys():
            if game.lower() in user_prompt.lower():
                game_detected = game
                break
                
        # Generate based on whether it's a short or regular video
        if is_short:
            title = self._generate_short_title(user_prompt, game_detected)
            description = self._generate_short_description(user_prompt, game_detected)
        else:
            title = self._generate_regular_title(user_prompt, game_detected)
            description = self._generate_regular_description(user_prompt, game_detected)
            
        tags = self._generate_tags(user_prompt, game_detected, is_short)
        
        return {
            "title": title,
            "description": description,
            "tags": tags,
            "detected_game": game_detected
        }
        
    def _generate_short_title(self, prompt: str, game: str = None) -> str:
        """Generate optimized title for YouTube Shorts"""
        hook_words = self.successful_patterns["title_hooks"]
        
        # Extract key action from prompt
        if "sniper" in prompt.lower() or "shoot" in prompt.lower():
            template = self.successful_patterns["shorts_patterns"]["sniper"]
            return template.format(hook_word=hook_words[0])  # INSANE
        elif game:
            game_tag = game.lower().replace(" ", "").replace("2", "2")
            template = self.successful_patterns["shorts_patterns"]["action"]
            return template.format(hook_word=hook_words[1], game=game, game_tag=game_tag)
        else:
            return f"{hook_words[0]} VR Moment! 🎮 #vr #gaming #shorts"
            
    def _generate_regular_title(self, prompt: str, game: str = None) -> str:
        """Generate optimized title for regular videos"""
        hook_words = self.successful_patterns["title_hooks"]
        
        if game and game in self.successful_patterns["vr_games"]:
            game_info = self.successful_patterns["vr_games"][game]
            hashtags = " ".join(game_info["hashtags"])
            
            # Extract key elements from prompt
            if "episode" in prompt.lower():
                episode_num = re.search(r'episode\s+(\d+)', prompt.lower())
                ep_text = f" Episode {episode_num.group(1)}" if episode_num else ""
                return f"{hook_words[0]} VR Adventure!{ep_text} 🎮 {game} {hashtags}"
            elif "sniper" in prompt.lower():
                return f"{hook_words[0]} VR Sniper Shots! 🎯 {game} {hashtags}"
            else:
                return f"{hook_words[0]} VR Experience! 🔥 {game} {hashtags}"
        else:
            return f"{hook_words[0]} VR Gameplay! 🎮 #vr #pcvr #gaming"
            
    def _generate_short_description(self, prompt: str, game: str = None) -> str:
        """Generate optimized description for YouTube Shorts"""
        base_desc = f"🎮 {prompt}\n\n"
        
        if game:
            base_desc += f"Amazing VR gameplay from {game}! "
            
        base_desc += "This is what makes VR gaming so incredible!\n\n"
        base_desc += "🔥 Follow for more VR content!\n"
        base_desc += "#VRGaming #PCVRGames #VirtualReality #Gaming #Shorts"
        
        return base_desc
        
    def _generate_regular_description(self, prompt: str, game: str = None) -> str:
        """Generate optimized description for regular videos"""
        if game and game in self.successful_patterns["vr_games"]:
            game_info = self.successful_patterns["vr_games"][game]
            template = game_info["description_template"]
            
            # Extract specific features from prompt
            specific_features = self._extract_features(prompt)
            
            return template.format(
                content=prompt,
                specific_features=specific_features
            )
        else:
            return f"🎮 {prompt}\n\nAmazing VR gaming experience that showcases the incredible potential of virtual reality!\n\n🔥 What makes VR special:\n• Complete immersion\n• Physical interaction\n• Realistic mechanics\n• Emotional engagement\n\nThis is the future of gaming!\n\n#VRGaming #PCVRGames #VirtualReality"
            
    def _generate_tags(self, prompt: str, game: str = None, is_short: bool = False) -> List[str]:
        """Generate optimized tags"""
        base_tags = ["VR gaming", "virtual reality", "PC VR games"]
        
        if is_short:
            base_tags.extend(["VR shorts", "gaming shorts", "VR gameplay"])
            
        if game and game in self.successful_patterns["vr_games"]:
            game_info = self.successful_patterns["vr_games"][game]
            base_tags.extend(game_info["keywords"])
            
        # Add context-specific tags from prompt
        if "sniper" in prompt.lower():
            base_tags.extend(["VR sniper", "long range VR", "VR precision shooting"])
        if "horror" in prompt.lower():
            base_tags.extend(["VR horror", "scary VR games"])
        if "zombie" in prompt.lower():
            base_tags.extend(["VR zombies", "zombie survival VR"])
            
        # Add platform tags
        base_tags.extend(["Oculus Rift games", "SteamVR games", "PCVR gaming"])
        
        return list(set(base_tags))  # Remove duplicates
        
    def _extract_features(self, prompt: str) -> str:
        """Extract specific features mentioned in the prompt"""
        features = []
        
        feature_keywords = {
            "weapon": "Advanced weapon mechanics",
            "enemy": "Challenging enemy encounters", 
            "exploration": "Atmospheric exploration",
            "mission": "Engaging mission objectives",
            "multiplayer": "Cooperative multiplayer action",
            "graphics": "Stunning visual fidelity",
            "physics": "Realistic physics simulation"
        }
        
        for keyword, feature in feature_keywords.items():
            if keyword in prompt.lower():
                features.append(feature)
                
        return "• " + "\n• ".join(features) if features else "Incredible VR immersion and gameplay"
        
    def get_scheduling_options(self) -> Dict[str, str]:
        """Get upload scheduling and privacy options from user"""
        print("\n⚙️ Upload Settings:")
        print("1. 🌐 Privacy: Public (default) / Unlisted / Private")
        print("2. ⏰ Schedule: Immediate (default) / Custom time")
        
        # Privacy setting
        privacy_choice = input("Privacy (press Enter for Public): ").lower().strip()
        privacy_map = {
            'public': 'public',
            'unlisted': 'unlisted', 
            'private': 'private',
            '': 'public'  # Default
        }
        privacy = privacy_map.get(privacy_choice, 'public')
        
        # Scheduling
        schedule_choice = input("Schedule (press Enter for Immediate): ").strip()
        publish_at = None
        
        if schedule_choice:
            try:
                # Try parsing the input
                if schedule_choice.lower() in ['tomorrow', 'next day']:
                    publish_at = (datetime.now() + timedelta(days=1)).replace(hour=9, minute=0, second=0, microsecond=0)
                elif schedule_choice.lower().startswith('in '):
                    # Parse "in 2 hours", "in 30 minutes", etc.
                    parts = schedule_choice.lower().split()
                    if len(parts) >= 3:
                        amount = int(parts[1])
                        unit = parts[2].rstrip('s')  # Remove plural 's'
                        
                        if unit in ['hour', 'hours']:
                            publish_at = datetime.now() + timedelta(hours=amount)
                        elif unit in ['minute', 'minutes']:
                            publish_at = datetime.now() + timedelta(minutes=amount) 
                        elif unit in ['day', 'days']:
                            publish_at = datetime.now() + timedelta(days=amount)
                else:
                    # Try parsing as date/time string
                    if HAS_DATEUTIL:
                        publish_at = dateutil.parser.parse(schedule_choice)
                    else:
                        print("⚠️ Advanced date parsing not available. Use formats like 'tomorrow' or 'in 2 hours'")
                        publish_at = None
                    
                # Convert to YouTube API format (RFC 3339)
                if publish_at:
                    # YouTube requires future time
                    if publish_at <= datetime.now():
                        print("⚠️ Schedule time must be in the future. Using immediate upload.")
                        publish_at = None
                    else:
                        print(f"⏰ Scheduled for: {publish_at.strftime('%Y-%m-%d %H:%M:%S')}")
                        
            except Exception as e:
                print(f"⚠️ Could not parse schedule time: {e}. Using immediate upload.")
                publish_at = None
        
        return {
            'privacy': privacy,
            'publish_at': publish_at.isoformat() + 'Z' if publish_at else None
        }

    def upload_video(self, video_path: str, thumbnail_path: str = None, 
                    playlists: List[str] = None, **metadata) -> Optional[str]:
        """Upload video to YouTube with metadata"""
        
        if not os.path.exists(video_path):
            print(f"❌ Error: Video file not found: {video_path}")
            return None
            
        print(f"🎬 Starting upload: {os.path.basename(video_path)}")
        
        # Prepare video metadata
        body = {
            'snippet': {
                'title': metadata.get('title', 'Untitled Video'),
                'description': metadata.get('description', ''),
                'tags': metadata.get('tags', []),
                'categoryId': '20'  # Gaming category
            },
            'status': {
                'privacyStatus': metadata.get('privacy', 'public'),
                'selfDeclaredMadeForKids': False
            }
        }
        
        # Add scheduling if provided
        if metadata.get('publish_at'):
            body['status']['publishAt'] = metadata['publish_at']
        
        try:
            # Upload video
            media = MediaFileUpload(
                video_path,
                chunksize=-1,
                resumable=True,
                mimetype='video/*'
            )
            
            insert_request = self.youtube.videos().insert(
                part=','.join(body.keys()),
                body=body,
                media_body=media
            )
            
            video_id = None
            response = None
            
            while response is None:
                status, response = insert_request.next_chunk()
                if status:
                    progress = int(status.progress() * 100)
                    print(f"📤 Upload progress: {progress}%")
                    
            video_id = response['id']
            print(f"✅ Video uploaded successfully! ID: {video_id}")
            
            # Set thumbnail if provided and not a short
            if thumbnail_path and os.path.exists(thumbnail_path):
                is_short = metadata.get('is_short', False)
                if not is_short:
                    self._set_thumbnail(video_id, thumbnail_path)
                else:
                    print("ℹ️ Skipping thumbnail for Short (not supported)")
                    
            # Add to playlists
            if playlists:
                self._add_to_playlists(video_id, playlists)
                
            return video_id
            
        except Exception as e:
            print(f"❌ Upload failed: {str(e)}")
            return None
            
    def _set_thumbnail(self, video_id: str, thumbnail_path: str):
        """Set custom thumbnail for video"""
        try:
            self.youtube.thumbnails().set(
                videoId=video_id,
                media_body=MediaFileUpload(thumbnail_path)
            ).execute()
            print(f"✅ Thumbnail set successfully")
            
        except Exception as e:
            print(f"⚠️ Failed to set thumbnail: {str(e)}")
            
    def _add_to_playlists(self, video_id: str, playlist_names: List[str]):
        """Add video to specified playlists"""
        available_playlists = self.get_playlists()
        
        for playlist_name in playlist_names:
            if playlist_name in available_playlists:
                try:
                    self.youtube.playlistItems().insert(
                        part="snippet",
                        body={
                            'snippet': {
                                'playlistId': available_playlists[playlist_name],
                                'resourceId': {
                                    'kind': 'youtube#video',
                                    'videoId': video_id
                                }
                            }
                        }
                    ).execute()
                    print(f"✅ Added to playlist: {playlist_name}")
                    
                except Exception as e:
                    print(f"⚠️ Failed to add to playlist '{playlist_name}': {str(e)}")
            else:
                print(f"⚠️ Playlist not found: {playlist_name}")
                
def main():
    """Interactive main function for the YouTube Auto-Uploader"""
    
    print("🎬 YouTube Auto-Uploader for The Old Man Gamer")
    print("=" * 50)
    
    # Initialize uploader
    uploader = YouTubeAutoUploader()
    
    # Authenticate
    if not uploader.authenticate():
        print("❌ Authentication failed. Please check your credentials.")
        return
        
    while True:
        print("\n🎮 YouTube Auto-Upload Workflow")
        print("-" * 30)
        
        # Step 1: Get video path
        video_path = input("📁 Enter path to video file: ").strip().strip('"')
        if not video_path or not os.path.exists(video_path):
            print("❌ Invalid video path. Try again.")
            continue
            
        # Step 2: Detect video type
        is_short, duration = uploader.detect_video_type(video_path)
        video_type = "Short" if is_short else "Regular Video"
        print(f"🎯 Detected: {video_type} (estimated {duration}s)")
        
        # Step 3: Get thumbnail (skip for shorts)
        thumbnail_path = None
        if not is_short:
            thumbnail_input = input("🖼️ Enter path to thumbnail (or press Enter to skip): ").strip().strip('"')
            if thumbnail_input and os.path.exists(thumbnail_input):
                thumbnail_path = thumbnail_input
                print("✅ Thumbnail loaded")
            else:
                print("ℹ️ No thumbnail provided")
        else:
            print("ℹ️ Shorts don't support custom thumbnails")
            
        # Step 4: Get playlists
        print("\n📋 Available Playlists:")
        available_playlists = uploader.get_playlists()
        if available_playlists:
            for i, name in enumerate(available_playlists.keys(), 1):
                print(f"   {i}. {name}")
        else:
            print("   No playlists found")
            
        playlist_input = input("📝 Enter playlist names (comma-separated, or press Enter for none): ").strip()
        selected_playlists = []
        if playlist_input:
            selected_playlists = [name.strip() for name in playlist_input.split(',')]
            
        # Step 5: Get content description
        print(f"\n✍️ Describe what you did in this {video_type.lower()}:")
        user_prompt = input("💭 Your description: ").strip()
        
        if not user_prompt:
            print("❌ Description is required. Try again.")
            continue
            
        # Step 6: Generate optimized content
        print("\n🤖 Generating optimized content...")
        generated_content = uploader.generate_content(user_prompt, video_path, is_short)
        
        # Step 7: Show generated content for approval
        print("\n📝 Generated Content:")
        print("-" * 20)
        print(f"🎯 Title: {generated_content['title']}")
        print(f"📝 Description:\n{generated_content['description'][:200]}...")
        print(f"🏷️ Tags: {', '.join(generated_content['tags'][:5])}...")
        if generated_content['detected_game']:
            print(f"🎮 Detected Game: {generated_content['detected_game']}")
            
        # Step 8: Get approval
        while True:
            approval = input("\n✅ Approve and upload? (y/n/e=edit): ").lower().strip()
            
            if approval == 'y':
                break
            elif approval == 'n':
                print("❌ Upload cancelled.")
                break
            elif approval == 'e':
                print("✏️ Edit mode:")
                generated_content['title'] = input(f"Title [{generated_content['title']}]: ") or generated_content['title']
                new_desc = input("Description (press Enter to keep current): ")
                if new_desc:
                    generated_content['description'] = new_desc
                new_tags = input("Tags (comma-separated, press Enter to keep current): ")
                if new_tags:
                    generated_content['tags'] = [tag.strip() for tag in new_tags.split(',')]
            else:
                print("Please enter 'y', 'n', or 'e'")
                continue
                
        if approval == 'n':
            continue
            
        # Step 9: Get scheduling options (defaults to public + immediate)
        scheduling_options = uploader.get_scheduling_options()
        
        # Step 10: Upload
        print("\n🚀 Starting upload...")
        
        upload_metadata = {
            'title': generated_content['title'],
            'description': generated_content['description'],
            'tags': generated_content['tags'],
            'is_short': is_short,
            'privacy': scheduling_options['privacy'],
            'publish_at': scheduling_options['publish_at']
        }
        
        video_id = uploader.upload_video(
            video_path=video_path,
            thumbnail_path=thumbnail_path,
            playlists=selected_playlists,
            **upload_metadata
        )
        
        if video_id:
            video_url = f"https://youtube.com/watch?v={video_id}"
            print(f"\n🎉 SUCCESS! Video uploaded:")
            print(f"🔗 URL: {video_url}")
            print(f"🆔 Video ID: {video_id}")
        else:
            print("\n❌ Upload failed. Please try again.")
            
        # Ask if user wants to upload another video
        another = input("\n🔄 Upload another video? (y/n): ").lower().strip()
        if another != 'y':
            break
            
    print("\n👋 Thanks for using YouTube Auto-Uploader!")

if __name__ == "__main__":
    main()