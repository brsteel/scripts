# 🎬 YouTube Auto-Uploader Setup & Usage Guide

## 🚀 Features

Your new YouTube Auto-Uploader provides:

1. **📁 Video/Short Upload** - Automatic detection of content type
2. **🖼️ Thumbnail Support** - Custom thumbnails for regular videos
3. **📋 Playlist Management** - Add videos to existing playlists
4. **🤖 AI-Powered SEO** - Generate titles, descriptions, and tags based on your successful patterns
5. **✅ Interactive Approval** - Review and edit content before upload
6. **🎯 Optimized for Your Channel** - Uses patterns from your highest-performing videos

## 📦 Installation

### Step 1: Install Dependencies
```bash
cd "c:\Users\brook\OneDrive\Documents\Scripts\SEOOptimizer"
pip install -r requirements.txt
```

### Step 2: Verify Credentials
Make sure your Google API credentials file is in the SEOOptimizer folder:
- `client_secret_102034359712-upvn0ts1m88qp811hfi160ca2a9hh7pb.apps.googleusercontent.com.json`

## 🎮 Usage

### Quick Start
```bash
python youtube_auto_uploader.py
```

### Interactive Workflow

The script will guide you through:

1. **📁 Video File Path**
   ```
   📁 Enter path to video file: C:\path\to\your\video.mp4
   ```

2. **🎯 Auto-Detection**
   - Automatically detects if it's a Short or regular video
   - Based on filename and file size

3. **🖼️ Thumbnail (Regular Videos Only)**
   ```
   🖼️ Enter path to thumbnail: C:\path\to\thumbnail.jpg
   ```

4. **📋 Playlist Selection**
   - Shows your existing playlists
   - Enter comma-separated names to add video to multiple playlists

5. **✍️ Content Description**
   ```
   💭 Your description: I did an epic sniper run in Into the Radius 2, 
   taking out enemies from extreme range with the new SR-25 rifle
   ```

6. **🤖 AI Content Generation**
   - Automatically generates optimized title, description, and tags
   - Based on your channel's successful patterns

7. **✅ Review & Approve**
   - Review generated content
   - Choose: Approve (y), Cancel (n), or Edit (e)

8. **🚀 Upload**
   - Uploads video with metadata
   - Sets thumbnail (if provided)
   - Adds to playlists
   - Returns YouTube URL

## 🎯 AI Optimization Patterns

The script uses your proven successful patterns:

### Title Patterns
- **Hook Words**: "INSANE", "INCREDIBLE", "AMAZING", "EPIC"
- **Game-Specific**: Detects Into the Radius 2, ConVRgence, Zombie Army VR
- **Format-Specific**: Different patterns for Shorts vs regular videos

### Description Templates
- **Into the Radius 2**: Full STALKER VR survival template
- **ConVRgence**: Hidden gem with dog companion template  
- **Zombie Army VR**: WWII zombie carnage template
- **Generic VR**: Fallback for other games

### Tag Generation
- **Base Tags**: VR gaming, virtual reality, PC VR games
- **Game-Specific**: Keywords proven to work for each game
- **Context-Aware**: Adds sniper, horror, zombie tags based on content
- **Platform Tags**: Oculus Rift, SteamVR, PCVR gaming

## 📊 Optimization Examples

### Example: Sniper Short
**Input**: "Amazing long-range shots with SR-25 in Into the Radius 2"
**Generated**:
- **Title**: "INSANE VR Sniper Shots! 🎯 Into the Radius 2 SR-25 #vr #sniper #intotheradius2 #shorts"
- **Description**: VR sniper showcase with game details
- **Tags**: VR sniper, Into the Radius 2, long range VR, VR precision shooting...

### Example: Regular ConVRgence Video
**Input**: "Episode 5 where difficulty really ramps up, had to use crossbow"
**Generated**:
- **Title**: "INCREDIBLE VR Adventure! Episode 5 🎮 ConVRgence #vr #pcvr #convrgence #stalker"
- **Description**: Full ConVRgence template with STALKER atmosphere details
- **Tags**: ConVRgence, STALKER VR, extraction shooter, VR hidden gem...

## 🔧 Advanced Features

### Custom Patterns
You can modify the successful patterns in the script:
```python
self.successful_patterns = {
    "title_hooks": ["YOUR", "CUSTOM", "HOOKS"],
    "vr_games": {
        "Your Game": {
            "hashtags": ["#yourgame", "#vr"],
            "keywords": ["game keywords"],
            "description_template": "Your template"
        }
    }
}
```

### Playlist Management
- Automatically fetches your existing playlists
- Add videos to multiple playlists simultaneously
- Creates playlist items with proper metadata

### Error Handling
- Validates file paths before upload
- Handles authentication errors gracefully
- Provides detailed error messages
- Supports resumable uploads for large files

## 🎬 Content Type Detection

### Shorts Detection
Automatically detects Shorts based on:
- Filename contains "short" or "shorts"
- File size < 50MB (customizable)
- Duration < 60 seconds (when ffmpeg support added)

### Regular Videos
- Everything else is treated as regular video
- Supports custom thumbnails
- Uses full description templates

## 📈 SEO Best Practices Built-In

### Title Optimization
- ✅ Under 100 characters (YouTube limit)
- ✅ Hook words for click-through rate
- ✅ Game-specific hashtags
- ✅ Trending VR keywords

### Description Optimization  
- ✅ Engaging opening hook
- ✅ Structured feature lists
- ✅ Technical game details
- ✅ Platform information
- ✅ Strategic hashtag placement

### Tag Strategy
- ✅ Mix of broad and specific tags
- ✅ Game-specific keywords
- ✅ VR platform tags
- ✅ Content type tags (horror, action, etc.)

## 🔧 Troubleshooting

### Common Issues

**Authentication Failed**
- Check credentials file exists
- Re-run authentication flow
- Verify Google Cloud project settings

**Video Not Found**
- Check file path is correct
- Use full absolute path
- Remove quotes from path

**Upload Failed**
- Check internet connection
- Verify file isn't corrupted
- Try smaller file size
- Check YouTube quota limits

**Playlist Not Found**
- Check playlist name spelling
- Ensure playlist exists on your channel
- Try refreshing playlist list

### Getting Help

1. Check error messages carefully
2. Verify all file paths exist
3. Test with a small video first
4. Check YouTube Studio for uploaded content

## 🎯 Tips for Best Results

### Content Creation
1. **Describe specifically** what you did in the video
2. **Mention the game name** for auto-detection
3. **Include key actions** (sniping, combat, exploration)
4. **Add episode numbers** for series content

### File Organization
1. **Use descriptive filenames** (helps with auto-detection)
2. **Separate folders** for regular videos vs shorts
3. **Keep thumbnails** in same folder as videos
4. **Consistent naming** for series content

### Playlist Strategy
1. **Game-specific playlists** for each VR game
2. **Series playlists** for ConVRgence episodes, etc.
3. **Content-type playlists** (Shorts, Livestreams, Reviews)
4. **Performance playlists** (Top Performers, New Uploads)

---

**🎮 Ready to revolutionize your YouTube workflow! This script combines your proven SEO patterns with automated upload capabilities.**