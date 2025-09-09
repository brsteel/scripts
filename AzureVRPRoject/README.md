# Azure VR Project (PCVR OpenXR)

Prototype Unity project (PCVR over OpenXR / Virtual Desktop) that signs into Azure AD (device code) and visualizes Microsoft Entra tenant metadata in 3D.

## Features (Initial)
- Device Code auth via MSAL
- Calls Microsoft Graph: `GET https://graph.microsoft.com/v1.0/organization`
- Renders tenant id, display name, and first verified domains as floating TextMeshPro objects

## Prerequisites
- Unity 2022.3 LTS (or later 2022 LTS) installed
- OpenXR Runtime (WMR / SteamVR / Oculus PC) active on Windows
- .NET Framework 4.x scripting runtime in Project Settings
- An Azure AD app registration (public client) with Microsoft Graph `Organization.Read.All` or `Directory.Read.All`

## Azure AD App Registration
1. Azure Portal > Entra ID > App registrations > New registration
2. Name: `AzureVRProject`
3. Supported account types: single-tenant (or multi if needed)
4. Redirect URI: leave blank for device code
5. After creation: API Permissions > Add > Microsoft Graph > Application (or Delegated) > `Organization.Read.All` (and grant admin consent) *Device code uses delegated*.
6. Copy the Application (client) ID.

## Unity Setup Steps
1. Open the folder `AzureVRPRoject` in Unity (it will create additional project files).
2. Window > Package Manager: verify packages (OpenXR, XR Management, TextMeshPro) match `Packages/manifest.json`.
3. Edit > Project Settings > XR Plug-in Management: install & enable OpenXR for Standalone.
4. In OpenXR settings enable required interaction profiles for your headset (e.g., Oculus Touch / WMR / Valve Index).
5. Import TextMeshPro Essentials when prompted.
6. Create a prefab with a TextMeshPro component (e.g., white text) named `TextLinePrefab`.

## Scene Wiring
1. Create an empty GameObject `Auth` and add `AuthManager`.
   - Set ClientId to your app's client id.
   - (Optional) Set TenantId, otherwise `common`.
2. Create empty GameObject `TenantVizRoot` (will hold text objects).
3. Create an empty GameObject `TenantVisualizer` and add `TenantVisualizer`.
   - Assign AuthManager reference.
   - Assign RootParent = `TenantVizRoot` transform.
   - Assign TextPrefab = your `TextLinePrefab`.
4. Add a basic XR rig (e.g., Starter Assets or XR Origin) to view text in VR.

## Play Mode Flow
1. Press Play.
2. In Console: copy device code & open verification URL, sign in.
3. After token acquisition tenant info appears vertically.

## Security Notes
- Device code flow avoids embedded browsers; user signs in externally.
- Access token is in memory only; no refresh persistence implemented yet.
- For production: add token cache, error UI, paging, and secure secret storage (if using confidential flows).

## Roadmap Ideas
- 3D glyphs or shapes representing domains.
- Spatial layout / radial menu to drill into subscriptions, resource groups.
- Caching & refresh indicators.
- Interactive selection via XR controllers.

## Construct Environment & Interaction (Basic)

The project now includes a lightweight XR construct setup:

### Added Packages

- XR Interaction Toolkit (`com.unity.xr.interaction.toolkit`)
- Input System (`com.unity.inputsystem`)

### New Scripts

- `XRConstructRig` – Drop in scene to auto-spawn:
   - XR Interaction Manager (if missing)
   - XR Origin container
   - Ground plane, key directional light
   - A handful of physics-enabled grabbable cubes (`XRGrabInteractable`)
- `SimpleHandPresence` – Optional placeholder for controller/hand pose representation using the Input System.

### Quick Start

1. Create an empty GameObject `ConstructRoot` and add `XRConstructRig`.
2. Press Play – if OpenXR is configured you'll have an origin, light, floor, and interactable cubes.
3. (Optional) Add action-based controller prefabs (XR Interaction Toolkit samples) for grabbing with your device-specific input actions.
4. Assign a material to cubes by setting `cubeMaterial` on the `XRConstructRig` component.

### Locomotion (Smooth Move, Teleport, Snap Turn)

Added components & assets:

- `Assets/Input/XRLocomotion.inputactions` – Input System asset with left (Move) & right (SnapTurn/Teleport) action maps.
- `XRLocomotionSetup` script – Attach to any GameObject (e.g., same root as `XRConstructRig`).

Steps:

1. In Project Settings > Player > Active Input Handling ensure both or new Input System is enabled.
2. Drag `XRLocomotion.inputactions` into the `locomotionActions` field on `XRLocomotionSetup`.
3. Press Play. Use left thumbstick for smooth move, right thumbstick left/right for snap turns, right primary button hold + trigger press to teleport.
4. Adjust move speed, snap angle, and cooldown on the component as desired.

Teleport surfaces: any collider on layers included in `teleportLayers` (default all). Add a separate floor layer and narrow mask if needed.

### Hand / Controller Models

Import XR Interaction Toolkit Samples (Package Manager > XR Interaction Toolkit > Samples) to get pre-built controller/hand prefabs and input action assets. Parent them under the generated XR Origin's `Camera Offset` > left/right controller anchors.

### Notes

- For iteration keep Scripting Backend = Mono; switch to IL2CPP for release build.
- The `XRConstructRig` avoids duplicating managers; safe to have only one instance.
- Expand by adding locomotion (Teleportation Provider + Ray Interactors) later.

### Removal

When you build a more custom rig, simply delete the `XRConstructRig` object; spawned content is contained under it.

## Troubleshooting

- If Graph call fails with 403: ensure admin consent granted for `Organization.Read.All`.
- If DNS / network errors: verify local firewall, proxy settings, and system clock (token validation needs accurate time).
- If OpenXR fails: confirm correct runtime selected in Windows Mixed Reality / SteamVR / Oculus app settings.
- MSAL missing dependency warnings: See MSAL Dependencies section below.

## License

Prototype code – adapt as needed.

## MSAL Dependencies

`Microsoft.Identity.Client.dll` may require additional assemblies:

- `Microsoft.IdentityModel.Abstractions.dll`
- `System.Diagnostics.DiagnosticSource.dll`

Steps to add:

1. Download each NuGet package from nuget.org.
2. Rename the `.nupkg` to `.zip` and extract.
3. Copy the DLL from `lib/net462/` (or `netstandard2.0/`) into `Assets/Plugins/Assemblies/`.
4. In Unity select each DLL and ensure: Any Platform = ON, Editor + Standalone checked, others off.
5. (Optional) If warnings persist: toggle off Validate References only temporarily.

Without these, MSAL may log unresolved reference warnings and certain diagnostics/logging features may not function; core device code auth can still work if the code paths avoid those APIs.
