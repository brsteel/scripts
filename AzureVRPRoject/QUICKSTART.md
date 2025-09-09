# Quick Start Guide - Azure VR Project

## Prerequisites Check ✅

Before you begin, make sure you have:

1. **Unity 2022.3 LTS** - Open your AzureVRPRoject folder
2. **VR Headset Connected** - Ensure your headset (Quest, WMR, etc.) is connected and working
3. **OpenXR Runtime** - SteamVR, Oculus Desktop App, or Windows Mixed Reality
4. **Azure AD App Registration** - You'll need a Client ID

## Step 1: Unity Setup

1. Open Unity and load the AzureVRPRoject
2. Go to **Edit > Project Settings**
3. Navigate to **XR Plug-in Management**
4. Make sure **OpenXR** is checked for Windows Standalone
5. In OpenXR settings, enable your headset's interaction profile:
   - **Oculus Touch** (for Quest/Rift)
   - **Microsoft Mixed Reality** (for WMR headsets)
   - **HTC Vive** or **Valve Index** (for SteamVR headsets)

## Step 2: Scene Setup

Two options:

### Option A: Automatic Setup (Recommended)
1. Open the **Main.unity** scene
2. Create an empty GameObject and name it "Scene Manager"
3. Add the **SceneSetup** component to it
4. In the SceneSetup component:
   - Set your **Client ID** (from Azure AD app registration)
   - Leave **Tenant ID** as "common" (or set your specific tenant)
   - Make sure all checkboxes are enabled

### Option B: Manual Setup
1. Add the **XRConstructRig** component to an empty GameObject
2. Create separate GameObjects for AuthManager and TenantVisualizer
3. Wire up the references as described in the README

## Step 3: Azure AD App Registration

If you haven't done this yet:

1. Go to **Azure Portal > Entra ID > App registrations**
2. Click **New registration**
3. Name: "AzureVRProject"
4. Supported accounts: Single tenant (or multi-tenant if needed)
5. Redirect URI: Leave blank for device code flow
6. After creation:
   - Go to **API Permissions > Add permission**
   - Select **Microsoft Graph > Delegated permissions**
   - Add **Organization.Read.All**
   - Click **Grant admin consent**
7. Copy the **Application (client) ID**

## Step 4: Test the Scene

1. Put on your VR headset
2. Click **Play** in Unity
3. Watch the Unity Console for output like:
   ```
   Device code: ABC123XYZ
   Go to https://microsoft.com/devicelogin and enter the code.
   ```
4. On your phone or computer, go to the URL and enter the code
5. Sign in with your Azure AD account
6. Look in VR - you should see your tenant information floating in front of you!

## Step 5: Troubleshooting

### Common Issues:

**"No XR device found"**
- Make sure your headset is connected and recognized by Windows
- Check that SteamVR/Oculus Desktop is running
- Verify OpenXR is set as the active runtime

**"AuthManager: ClientId is not set"**
- You forgot to set the Client ID in the SceneSetup component

**"Graph call failed"**
- Check your Azure AD app permissions
- Make sure you granted admin consent
- Verify the device code authentication succeeded

**Text not visible in VR**
- The text might be positioned behind you
- Look around or move forward/backward
- Check the Azure Visualization Root position (should be at 0, 1.5, 2)

### Controls in VR:
- **Thumbstick/Trackpad**: Move around
- **Grip buttons**: Grab the colored cubes
- **Turn head**: Look around naturally

## Next Steps

Once you have the basic scene working:

1. **Extend data collection** - Add more Microsoft Graph endpoints
2. **Improve visualization** - Create 3D representations of resources
3. **Add interaction** - Select and manipulate Azure resources in VR
4. **Network topology** - Visualize resource relationships

## Useful Debug Info

While in Play mode, check the Console for:
- Authentication status messages
- Device code information
- Graph API call results
- Any error messages

The tenant information should appear as white text objects in VR space, showing:
- Tenant ID
- Display Name  
- Verified Domains

Have fun exploring your Azure tenant in VR! 🥽✨
