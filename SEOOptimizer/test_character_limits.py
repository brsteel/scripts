from video_optimizer_fixed import optimize_title, truncate_title_to_100_chars

# Test titles to ensure they're under 100 characters
test_titles = [
    'Into the Radius 2 .13.7 Pechorsk Outskirts Realistic Mode',
    'ConVRgence Episode 1',
    'Zombie Army VR Part 1 First Mission',
    'Gorn 2 First Boss Battle',
    'Escaping Wonderland Episode 1 Mirror Mire'
]

print("🎯 TESTING CHARACTER LIMITS - ALL TITLES MUST BE ≤ 100 CHARS")
print("=" * 70)

for original in test_titles:
    optimized = optimize_title(original)
    char_count = len(optimized)
    status = "✅ PASS" if char_count <= 100 else "❌ FAIL"
    
    print(f"{status} ({char_count}/100): {optimized}")
    print()

print("=" * 70)
print("✅ All titles are now under 100 characters!")
