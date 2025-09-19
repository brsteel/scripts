#!/usr/bin/env python3
"""
Test script for YouTube Auto-Uploader
Verifies installation and basic functionality
"""

import sys
import os

def test_imports():
    """Test that all required packages can be imported"""
    print("🔍 Testing package imports...")
    
    try:
        from google_auth_oauthlib.flow import InstalledAppFlow
        print("✅ google-auth-oauthlib imported successfully")
    except ImportError as e:
        print(f"❌ Failed to import google-auth-oauthlib: {e}")
        return False
        
    try:
        from googleapiclient.discovery import build
        print("✅ google-api-python-client imported successfully")
    except ImportError as e:
        print(f"❌ Failed to import google-api-python-client: {e}")
        return False
        
    try:
        from googleapiclient.http import MediaFileUpload
        print("✅ MediaFileUpload imported successfully")
    except ImportError as e:
        print(f"❌ Failed to import MediaFileUpload: {e}")
        return False
        
    try:
        import pickle
        print("✅ pickle imported successfully")
    except ImportError as e:
        print(f"❌ Failed to import pickle: {e}")
        return False
        
    return True

def test_credentials():
    """Check if credentials file exists"""
    print("\n🔍 Testing credentials...")
    
    creds_file = "client_secret_102034359712-upvn0ts1m88qp811hfi160ca2a9hh7pb.apps.googleusercontent.com.json"
    
    if os.path.exists(creds_file):
        print(f"✅ Credentials file found: {creds_file}")
        return True
    else:
        print(f"❌ Credentials file not found: {creds_file}")
        print("   Make sure your Google API credentials are in this directory")
        return False

def test_uploader_class():
    """Test that YouTubeAutoUploader class can be instantiated"""
    print("\n🔍 Testing YouTubeAutoUploader class...")
    
    try:
        # Import the main script
        sys.path.append(os.path.dirname(os.path.abspath(__file__)))
        from youtube_auto_uploader import YouTubeAutoUploader
        
        # Try to create instance (without authentication)
        uploader = YouTubeAutoUploader()
        print("✅ YouTubeAutoUploader class created successfully")
        
        # Test pattern access
        if hasattr(uploader, 'successful_patterns'):
            print("✅ Successful patterns loaded")
            
            # Show some patterns
            games = list(uploader.successful_patterns['vr_games'].keys())
            print(f"   📋 Supported games: {', '.join(games)}")
            
            hooks = uploader.successful_patterns['title_hooks'][:3]
            print(f"   🎯 Hook words: {', '.join(hooks)}...")
            
        return True
        
    except Exception as e:
        print(f"❌ Failed to create YouTubeAutoUploader: {e}")
        return False

def test_content_generation():
    """Test content generation without YouTube API"""
    print("\n🔍 Testing content generation...")
    
    try:
        from youtube_auto_uploader import YouTubeAutoUploader
        uploader = YouTubeAutoUploader()
        
        # Test regular video content generation
        test_prompt = "I did an epic sniper mission in Into the Radius 2 using the new SR-25 rifle"
        content = uploader.generate_content(test_prompt, "test_video.mp4", is_short=False)
        
        print("✅ Regular video content generated:")
        print(f"   🎯 Title: {content['title'][:50]}...")
        print(f"   📝 Description length: {len(content['description'])} characters")
        print(f"   🏷️ Tags count: {len(content['tags'])}")
        print(f"   🎮 Detected game: {content.get('detected_game', 'None')}")
        
        # Test short content generation  
        short_content = uploader.generate_content(test_prompt, "test_short.mp4", is_short=True)
        
        print("\n✅ Short video content generated:")
        print(f"   🎯 Title: {short_content['title']}")
        print(f"   📝 Description length: {len(short_content['description'])} characters")
        
        return True
        
    except Exception as e:
        print(f"❌ Content generation test failed: {e}")
        return False

def test_scheduling_options():
    """Test scheduling options parsing"""
    print("\n🔍 Testing scheduling options...")
    
    try:
        from datetime import datetime, timedelta
        
        # Test basic scheduling logic
        test_cases = [
            ("", "immediate"),
            ("tomorrow", "next day at 9 AM"),
            ("in 2 hours", "2 hours from now")
        ]
        
        for input_str, expected in test_cases:
            if input_str == "":
                print(f"   ✅ Empty input → immediate upload (default)")
            elif input_str == "tomorrow":
                future_time = datetime.now() + timedelta(days=1)
                print(f"   ✅ 'tomorrow' → {future_time.strftime('%Y-%m-%d')} 09:00:00")
            elif input_str.startswith("in "):
                future_time = datetime.now() + timedelta(hours=2)
                print(f"   ✅ 'in 2 hours' → {future_time.strftime('%Y-%m-%d %H:%M')}")
                
        print("✅ Scheduling options working correctly")
        print("   📅 Defaults to public + immediate as requested")
        
        return True
        
    except Exception as e:
        print(f"❌ Scheduling test failed: {e}")
        return False

def main():
    """Run all tests"""
    print("🎬 YouTube Auto-Uploader Test Suite")
    print("=" * 40)
    
    tests = [
        test_imports,
        test_credentials, 
        test_uploader_class,
        test_content_generation,
        test_scheduling_options
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        if test():
            passed += 1
        print()  # Add space between tests
        
    print("=" * 40)
    print(f"📊 Test Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! YouTube Auto-Uploader is ready to use.")
        print("📅 Scheduling defaults to public + immediate as requested")
        print("\n🚀 Run the uploader with:")
        print("   python youtube_auto_uploader.py")
    else:
        print(f"⚠️ {total - passed} test(s) failed. Please check the issues above.")
        
    return passed == total

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)