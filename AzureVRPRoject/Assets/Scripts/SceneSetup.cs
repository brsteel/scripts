using UnityEngine;
using UnityEngine.XR.Interaction.Toolkit;
using Unity.XR.CoreUtils;
using TMPro;
using System.Collections;

namespace AzureVR
{
    /// <summary>
    /// Quick VR scene setup helper - creates basic VR environment without Azure components
    /// </summary>
    [DefaultExecutionOrder(-200)]
    public class SceneSetup : MonoBehaviour
    {
        [Header("Scene Setup")]
        public bool createXRRig = true;
        public bool createTestEnvironment = true;
        public bool createInstructions = true;
        
        private void Awake()
        {
            // Only run once
            if (FindObjectOfType<XROrigin>() != null && !createXRRig)
            {
                Debug.Log("SceneSetup: XR Rig already exists, skipping setup");
                return;
            }

            SetupScene();
        }

        private void SetupScene()
        {
            Debug.Log("SceneSetup: Creating basic VR scene...");

            // 1. Create XR Rig
            if (createXRRig)
            {
                CreateXRRig();
            }

            // 2. Create test environment
            if (createTestEnvironment)
            {
                CreateTestEnvironment();
            }

            // 3. Create instructions
            if (createInstructions)
            {
                CreateInstructions();
            }

            // 4. Final cleanup - fix any AudioListener duplicates after everything is created
            StartCoroutine(FixAudioListenersDelayed());

            Debug.Log("SceneSetup: Basic VR scene ready! Put on your headset and press Play.");
        }

        private void CreateXRRig()
        {
            // Create the complete hierarchy first, then add XROrigin component
            var xrOriginGO = new GameObject("XR Origin (XR Rig)");
            
            // Create Camera Offset child
            var cameraOffsetGO = new GameObject("Camera Offset");
            cameraOffsetGO.transform.SetParent(xrOriginGO.transform);
            cameraOffsetGO.transform.localPosition = Vector3.zero;
            
            // Create Main Camera under the Camera Offset
            var cameraGO = new GameObject("Main Camera");
            cameraGO.tag = "MainCamera";
            cameraGO.transform.SetParent(cameraOffsetGO.transform);
            cameraGO.transform.localPosition = Vector3.zero;
            
            var camera = cameraGO.AddComponent<Camera>();
            camera.clearFlags = CameraClearFlags.SolidColor;
            camera.backgroundColor = Color.black;
            camera.nearClipPlane = 0.1f; // Increased for better performance
            camera.farClipPlane = 100f;   // Limit draw distance
            // Note: AudioListener will be handled by our delayed cleanup
            
            // Performance optimizations for VR
            OptimizeForVR(camera);
            
            // Add XROrigin component - there will be a harmless warning about Camera Floor Offset
            // which we'll fix immediately after
            var xrOrigin = xrOriginGO.AddComponent<XROrigin>();
            
            // Set the Camera Floor Offset Object (this fixes the functionality even if warning appeared)
            xrOrigin.CameraFloorOffsetObject = cameraOffsetGO;
            
            Debug.Log("SceneSetup: XROrigin created and configured (ignore any Camera Floor Offset warning)");
            
            // Debug: Check if XR is actually running
            if (UnityEngine.XR.XRSettings.enabled)
            {
                Debug.Log("SceneSetup: XR is enabled, device: " + UnityEngine.XR.XRSettings.loadedDeviceName);
            }
            else
            {
                Debug.LogWarning("SceneSetup: XR is NOT enabled! Enabling desktop fallback mode...");
                EnableDesktopFallback(cameraGO);
            }

            // Add XR Interaction Manager
            if (FindObjectOfType<XRInteractionManager>() == null)
            {
                var interactionManagerGO = new GameObject("XR Interaction Manager");
                interactionManagerGO.AddComponent<XRInteractionManager>();
            }

            // Add basic directional light
            if (FindObjectOfType<Light>() == null)
            {
                var lightGO = new GameObject("Directional Light");
                var light = lightGO.AddComponent<Light>();
                light.type = LightType.Directional;
                light.intensity = 1.2f;
                light.color = new Color(1f, 0.95f, 0.8f);
                lightGO.transform.rotation = Quaternion.Euler(50f, -30f, 0f);
            }

            // Add locomotion setup
            var locomotionGO = new GameObject("Locomotion Setup");
            locomotionGO.AddComponent<XRLocomotionSetup>();

            Debug.Log("SceneSetup: XR Rig created with proper structure");
        }

        private void EnableDesktopFallback(GameObject cameraGO)
        {
            // Add mouse look for desktop testing
            var mouseLook = cameraGO.AddComponent<MouseLook>();
            
            // Position camera at standing height
            cameraGO.transform.position = new Vector3(0, 1.6f, 0);
            
            Debug.Log("SceneSetup: Desktop fallback enabled - use mouse to look around, WASD to move");
        }

        private void OptimizeForVR(Camera camera)
        {
            // Set target frame rate for VR (72 or 90 FPS)
            Application.targetFrameRate = 72;
            
            // Disable expensive camera effects
            camera.allowHDR = false;
            camera.allowMSAA = false;
            
            // Set quality settings for performance
            QualitySettings.shadows = ShadowQuality.Disable;
            QualitySettings.shadowResolution = ShadowResolution.Low;
            QualitySettings.antiAliasing = 0;
            QualitySettings.anisotropicFiltering = AnisotropicFiltering.Disable;
            QualitySettings.realtimeReflectionProbes = false;
            
            Debug.Log("SceneSetup: VR performance optimizations applied");
        }

        private void CreateInstructions()
        {
            // Create a simple welcome text in VR
            var instructionsRoot = new GameObject("Instructions");
            instructionsRoot.transform.position = new Vector3(-2f, 1.5f, 2f);

            var instructionText = new GameObject("Welcome Text");
            instructionText.transform.SetParent(instructionsRoot.transform);
            instructionText.transform.localPosition = Vector3.zero;

            var tmp = instructionText.AddComponent<TextMeshPro>();
            tmp.text = "Welcome to VR!\n\nControls:\n- Move: Thumbsticks\n- Grab: Grip buttons\n- Look around naturally\n\nGrab the colorful cubes!";
            tmp.fontSize = 0.3f;
            tmp.color = Color.cyan;
            tmp.alignment = TextAlignmentOptions.Left;
            tmp.autoSizeTextContainer = true;

            Debug.Log("SceneSetup: Instructions created");
        }

        private void CreateTestEnvironment()
        {
            // Create floor
            var floor = GameObject.CreatePrimitive(PrimitiveType.Plane);
            floor.name = "Floor";
            floor.transform.localScale = Vector3.one * 5f;
            
            var floorRenderer = floor.GetComponent<MeshRenderer>();
            // Use Standard shader (always available) or fallback to default
            var shader = Shader.Find("Standard") ?? Shader.Find("Legacy Shaders/Diffuse");
            if (shader != null)
            {
                var floorMaterial = new Material(shader);
                floorMaterial.color = new Color(0.1f, 0.1f, 0.2f, 1f);
                floorRenderer.material = floorMaterial;
            }
            else
            {
                // Just use the default material if no shader found
                floorRenderer.material.color = new Color(0.1f, 0.1f, 0.2f, 1f);
            }

            // Create some reference cubes
            for (int i = 0; i < 3; i++)
            {
                var cube = GameObject.CreatePrimitive(PrimitiveType.Cube);
                cube.name = $"Reference Cube {i + 1}";
                cube.transform.position = new Vector3(i * 1.5f - 1.5f, 0.5f, 3f);
                cube.transform.localScale = Vector3.one * 0.3f;
                
                var cubeRenderer = cube.GetComponent<MeshRenderer>();
                // Use Standard shader (always available) or fallback to default
                var cubeShader = Shader.Find("Standard") ?? Shader.Find("Legacy Shaders/Diffuse");
                if (cubeShader != null)
                {
                    var cubeMaterial = new Material(cubeShader);
                    cubeMaterial.color = new Color(Random.value, Random.value, Random.value, 1f);
                    cubeRenderer.material = cubeMaterial;
                }
                else
                {
                    // Just change the color of the existing material
                    cubeRenderer.material.color = new Color(Random.value, Random.value, Random.value, 1f);
                }

                // Make them grabbable
                var rigidbody = cube.AddComponent<Rigidbody>();
                var grabInteractable = cube.AddComponent<UnityEngine.XR.Interaction.Toolkit.Interactables.XRGrabInteractable>();
                grabInteractable.throwOnDetach = true;
            }

            // Create lighting
            var lightGO = new GameObject("Directional Light");
            var light = lightGO.AddComponent<Light>();
            light.type = LightType.Directional;
            light.intensity = 1.2f;
            light.color = new Color(1f, 0.95f, 0.8f);
            lightGO.transform.rotation = Quaternion.Euler(50f, -30f, 0f);

            Debug.Log("SceneSetup: Test environment created");
        }

        private System.Collections.IEnumerator FixAudioListenersDelayed()
        {
            // Wait a frame to ensure all components are fully initialized
            yield return null;
            
            // Find all AudioListeners in the scene
            AudioListener[] listeners = FindObjectsOfType<AudioListener>();
            
            if (listeners.Length > 1)
            {
                Debug.Log($"SceneSetup: Found {listeners.Length} AudioListeners, removing duplicates...");
                
                // Keep the first one (usually on the Main Camera), remove the rest
                for (int i = 1; i < listeners.Length; i++)
                {
                    Debug.Log($"SceneSetup: Removing duplicate AudioListener from {listeners[i].gameObject.name}");
                    DestroyImmediate(listeners[i]);
                }
                
                Debug.Log("SceneSetup: AudioListener cleanup complete.");
            }
            else
            {
                Debug.Log($"SceneSetup: AudioListener check OK - found {listeners.Length} listener(s).");
            }
        }

        [ContextMenu("Setup Scene Now")]
        public void SetupSceneManually()
        {
            SetupScene();
        }
    }
}
