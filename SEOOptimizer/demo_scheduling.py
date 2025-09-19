#!/usr/bin/env python3
"""
Demo script for YouTube Auto-Uploader Scheduling Options
Shows how the scheduling system works without uploading
"""

from datetime import datetime, timedelta
import dateutil.parser

def demo_scheduling():
    """Demo the scheduling options"""
    print("🎬 YouTube Auto-Uploader - Scheduling Demo")
    print("=" * 45)
    
    print("\n⚙️ Upload Settings Options:")
    print("1. 🌐 Privacy: Public (default) / Unlisted / Private")
    print("2. ⏰ Schedule: Immediate (default) / Custom time")
    
    print("\n📅 Scheduling Examples:")
    
    scheduling_examples = [
        ("", "Immediate (default)"),
        ("tomorrow", "Tomorrow at 9:00 AM"),
        ("in 2 hours", "2 hours from now"),
        ("in 30 minutes", "30 minutes from now"), 
        ("in 1 day", "1 day from now"),
        ("2025-09-17 14:00", "Specific date/time"),
        ("next Monday 10am", "Advanced date parsing")
    ]
    
    for schedule_input, description in scheduling_examples:
        print(f"\n🔹 Input: '{schedule_input}' → {description}")
        
        if schedule_input == "":
            print("   ✅ Uploads immediately as public")
            continue
            
        try:
            publish_at = None
            
            if schedule_input.lower() in ['tomorrow', 'next day']:
                publish_at = (datetime.now() + timedelta(days=1)).replace(hour=9, minute=0, second=0, microsecond=0)
                
            elif schedule_input.lower().startswith('in '):
                parts = schedule_input.lower().split()
                if len(parts) >= 3:
                    amount = int(parts[1])
                    unit = parts[2].rstrip('s')
                    
                    if unit in ['hour', 'hours']:
                        publish_at = datetime.now() + timedelta(hours=amount)
                    elif unit in ['minute', 'minutes']:
                        publish_at = datetime.now() + timedelta(minutes=amount)
                    elif unit in ['day', 'days']:
                        publish_at = datetime.now() + timedelta(days=amount)
            else:
                publish_at = dateutil.parser.parse(schedule_input)
                
            if publish_at:
                print(f"   ✅ Scheduled for: {publish_at.strftime('%Y-%m-%d %H:%M:%S')}")
                print(f"   📅 YouTube API format: {publish_at.isoformat()}Z")
            else:
                print("   ❌ Could not parse - would default to immediate")
                
        except Exception as e:
            print(f"   ❌ Parse error: {e} - would default to immediate")
    
    print("\n🎯 Default Behavior:")
    print("- Privacy: PUBLIC (immediate publishing)")
    print("- Schedule: IMMEDIATE (uploads and goes live right away)")
    print("- Just press Enter for both to use defaults")
    
    print("\n💡 Pro Tips:")
    print("- 'tomorrow' schedules for 9 AM next day")
    print("- 'in X hours/minutes/days' schedules relative to now")
    print("- Specific dates work: '2025-09-17 14:00'")
    print("- Natural language: 'next Monday 10am'")
    
    print("\n🚀 In the real uploader:")
    print("1. Content generation happens first")
    print("2. You approve title/description/tags") 
    print("3. Then you choose privacy + scheduling")
    print("4. Upload happens with your settings")
    
    print("\n✅ Perfect for your workflow - defaults to public & immediate!")

if __name__ == "__main__":
    demo_scheduling()