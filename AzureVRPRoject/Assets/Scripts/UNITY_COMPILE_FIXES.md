# Unity Compile Issues - Common Fixes

## Issues Fixed in Pool Table Scripts

### ✅ XR Interaction Toolkit API Updates
**Problem:** Unity auto-updates XR Interaction Toolkit APIs
**Solution:** Added proper namespace imports and simplified references:

```csharp
// Added these imports
using UnityEngine.XR.Interaction.Toolkit;
using UnityEngine.XR.Interaction.Toolkit.Interactables;

// Simplified from:
UnityEngine.XR.Interaction.Toolkit.Interactables.XRGrabInteractable
// To:
XRGrabInteractable
```

### ✅ Physics Material References
**Status:** All using correct `PhysicsMaterial` (Unity 3D Physics)
**Note:** Not `PhysicMaterial` (2D Physics) - this is correct

### ✅ Component References  
**Status:** All using modern `GetComponent<>()` syntax
**Examples:**
- `GetComponent<Rigidbody>()`
- `GetComponent<Renderer>()`
- `GetComponent<Collider>()`

## Common Unity Compile Issues & Fixes

### 1. **XR Interaction Toolkit Version Issues**
**Error:** `SelectEnterEventArgs` not found
**Fix:** Update to use proper namespace:
```csharp
using UnityEngine.XR.Interaction.Toolkit;
protected override void OnSelectEntered(SelectEnterEventArgs args) { }
```

### 2. **Deprecated Component Access**
**Error:** `.rigidbody` is deprecated
**Fix:** Use `GetComponent<>()`
```csharp
// OLD (deprecated):
transform.rigidbody.velocity = Vector3.zero;

// NEW (correct):
GetComponent<Rigidbody>().velocity = Vector3.zero;
```

### 3. **Missing Assembly References**
**Error:** `XRGrabInteractable` not found
**Fix:** 
1. Install XR Interaction Toolkit via Package Manager
2. Add assembly definition references in project settings
3. Add proper using statements

### 4. **Physics Material Issues**
**Error:** Wrong physics material type
**Fix:** Use correct type:
```csharp
public PhysicsMaterial ballMaterial;  // 3D Physics ✅
public PhysicMaterial ballMaterial;   // 2D Physics ❌
```

### 5. **Shader References**
**Error:** Shader not found
**Fix:** Use built-in shader names:
```csharp
new Material(Shader.Find("Standard"));        // ✅ Always available
new Material(Shader.Find("Sprites/Default")); // ✅ For UI/2D
```

## How to Troubleshoot

### Step 1: Check Console
1. Window > Console
2. Look for red error messages
3. Double-click errors to jump to problem code

### Step 2: Missing References
1. Check if packages are installed (Package Manager)
2. Verify assembly definition references
3. Ensure proper using statements

### Step 3: API Updates
1. Let Unity auto-update APIs when prompted
2. Check Unity documentation for changes
3. Update namespace imports

### Step 4: Clean & Rebuild
1. Assets > Reimport All (if needed)
2. Edit > Clear All PlayerPrefs
3. Delete Library folder and reopen project (nuclear option)

## Pool Table Specific Setup

### Required Packages
1. **XR Interaction Toolkit** - For VR interactions
2. **XR Plugin Management** - For VR runtime
3. **OpenXR** or **Oculus XR** - For headset support

### Scene Setup
1. Delete Main Camera
2. Add XR Origin (Action-based) from XR Interaction Toolkit
3. Add PoolTableSetup script to empty GameObject
4. Configure XR settings in Project Settings

### Testing Without VR
- Scripts work in regular play mode
- Hand interactions won't work without VR
- Physics and game logic still functional

## Commit Status
✅ All pool table scripts updated for Unity API compatibility
✅ XR Interaction Toolkit namespaces fixed  
✅ Modern Unity API compliance verified
✅ No compile errors detected
