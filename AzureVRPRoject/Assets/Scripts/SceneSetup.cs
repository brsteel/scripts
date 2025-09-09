using UnityEngine;
using UnityEngine.XR.Management;
using System.Collections;
using Unity.XR.CoreUtils;
using UnityEngine.XR.Interaction.Toolkit;
using UnityEngine.XR.Interaction.Toolkit.Locomotion;
using UnityEngine.XR.Interaction.Toolkit.Locomotion.Movement;
using UnityEngine.XR.Interaction.Toolkit.Locomotion.Turning;
using UnityEngine.XR.Interaction.Toolkit.Locomotion.Teleportation;

namespace AzureVR
{
    /// <summary>
    /// Proper VR scene setup using XR Interaction Toolkit built-in components
    /// This replaces our custom implementation with Unity's official toolkit prefabs
    /// </summary>
    [DefaultExecutionOrder(-200)]
    public class SceneSetup : MonoBehaviour
    {
        [Header("XR Setup")]
        [Tooltip("Initialize XR manually. Disable if XR is already set up in Project Settings > XR Plug-in Management.")]
        public bool initializeXR = false; // Changed default to false
        public bool createBasicEnvironment = true;
        
        [Header("Toolkit Components")]
        public GameObject xrOriginPrefab; // Assign XR Origin (XR Rig) prefab from toolkit
        public GameObject interactionManagerPrefab; // Assign XR Interaction Manager prefab
        
        [Header("Environment")]
        public Material floorMaterial;
        public Material wallMaterial;

        void Start()
        {
            if (initializeXR)
            {
                StartCoroutine(InitializeXRAndSetupScene());
            }
            else
            {
                SetupScene();
            }
        }

        private IEnumerator InitializeXRAndSetupScene()
        {
            Debug.Log("SceneSetup: Checking XR initialization status...");

            var manager = XRGeneralSettings.Instance?.Manager;
            if (manager == null)
            {
                Debug.LogError("SceneSetup: XR Manager is null! Check XR Management settings.");
                SetupScene();
                yield break;
            }

            // Check if XR is already initialized
            if (manager.activeLoader != null)
            {
                Debug.Log("SceneSetup: XR is already initialized. Skipping initialization.");
            }
            else
            {
                Debug.Log("SceneSetup: Initializing XR...");
                // Initialize XR only if not already initialized
                yield return manager.InitializeLoader();
            }

            if (manager.activeLoader == null)
            {
                Debug.LogWarning("SceneSetup: Failed to initialize XR loader. Running in desktop mode.");
            }
            else
            {
                Debug.Log("SceneSetup: XR initialized successfully with loader: " + manager.activeLoader.name);
                
                // Start the XR subsystems if they're not already running
                yield return new WaitForSeconds(0.1f);
                try
                {
                    if (!manager.isInitializationComplete)
                    {
                        manager.StartSubsystems();
                        Debug.Log("SceneSetup: XR subsystems started");
                    }
                    else
                    {
                        Debug.Log("SceneSetup: XR subsystems already running");
                    }
                }
                catch (System.Exception e)
                {
                    Debug.LogWarning($"SceneSetup: Could not start XR subsystems: {e.Message}");
                }
            }

            // Setup scene with proper toolkit components
            SetupScene();
        }

        private void SetupScene()
        {
            Debug.Log("SceneSetup: Setting up VR scene with toolkit components...");

            // 1. Create XR Interaction Manager (handles all interactions)
            CreateXRInteractionManager();

            // 2. Create XR Origin (complete VR rig with locomotion)
            CreateXROrigin();

            // 3. Create basic environment
            if (createBasicEnvironment)
            {
                CreateBasicEnvironment();
            }

            // 4. Clean up any duplicate AudioListeners
            CleanupAudioListeners();

            Debug.Log("SceneSetup: VR scene setup complete!");
        }

        private void CreateXRInteractionManager()
        {
            // Check if one already exists
            if (FindObjectOfType<XRInteractionManager>() != null)
            {
                Debug.Log("SceneSetup: XR Interaction Manager already exists in scene.");
                return;
            }

            GameObject interactionManagerGO;
            
            if (interactionManagerPrefab != null)
            {
                // Use assigned prefab
                interactionManagerGO = Instantiate(interactionManagerPrefab);
                Debug.Log("SceneSetup: Created XR Interaction Manager from prefab.");
            }
            else
            {
                // Create manually
                interactionManagerGO = new GameObject("XR Interaction Manager");
                interactionManagerGO.AddComponent<XRInteractionManager>();
                Debug.Log("SceneSetup: Created XR Interaction Manager manually.");
            }

            interactionManagerGO.name = "XR Interaction Manager";
        }

        private void CreateXROrigin()
        {
            // Check if one already exists
            if (FindObjectOfType<XROrigin>() != null)
            {
                Debug.Log("SceneSetup: XR Origin already exists in scene.");
                return;
            }

            GameObject xrOriginGO;

            if (xrOriginPrefab != null)
            {
                // Use assigned prefab (recommended)
                xrOriginGO = Instantiate(xrOriginPrefab);
                Debug.Log("SceneSetup: Created XR Origin from prefab with built-in locomotion!");
            }
            else
            {
                // Create basic XR Origin manually
                xrOriginGO = CreateBasicXROrigin();
                Debug.Log("SceneSetup: Created basic XR Origin manually.");
            }

            xrOriginGO.name = "XR Origin";
        }

        private GameObject CreateBasicXROrigin()
        {
            // Create XR Origin
            GameObject xrOriginGO = new GameObject("XR Origin");
            XROrigin xrOrigin = xrOriginGO.AddComponent<XROrigin>();
            
            // Create Camera Offset
            GameObject cameraOffset = new GameObject("Camera Offset");
            cameraOffset.transform.SetParent(xrOriginGO.transform);
            xrOrigin.CameraFloorOffsetObject = cameraOffset;

            // Create Main Camera
            GameObject cameraGO = new GameObject("Main Camera");
            cameraGO.transform.SetParent(cameraOffset.transform);
            cameraGO.tag = "MainCamera";
            
            Camera camera = cameraGO.AddComponent<Camera>();
            camera.nearClipPlane = 0.01f;
            camera.farClipPlane = 1000f;
            
            cameraGO.AddComponent<AudioListener>();
            xrOrigin.Camera = camera;

            // Add basic locomotion components
            AddBasicLocomotion(xrOriginGO);

            // Add basic controllers
            AddBasicControllers(cameraOffset);

            return xrOriginGO;
        }

        private void AddBasicLocomotion(GameObject xrOrigin)
        {
            // Add Locomotion Mediator (required for XR Interaction Toolkit 3.0+)
            xrOrigin.AddComponent<LocomotionMediator>();

            // Add Continuous Move Provider (modern XR Interaction Toolkit 3.0+)
            var continuousMove = xrOrigin.AddComponent<ContinuousMoveProvider>();
            continuousMove.moveSpeed = 2.0f;

            // Add Snap Turn Provider (modern XR Interaction Toolkit 3.0+)
            var snapTurn = xrOrigin.AddComponent<SnapTurnProvider>();
            snapTurn.turnAmount = 45f;

            // Add Teleportation Provider (modern XR Interaction Toolkit 3.0+)
            xrOrigin.AddComponent<TeleportationProvider>();

            Debug.Log("SceneSetup: Added modern locomotion providers (XR Interaction Toolkit 3.0+).");
        }

        private void AddBasicControllers(GameObject cameraOffset)
        {
            // Create Left Controller (XR Interaction Toolkit 3.0+ approach)
            GameObject leftController = new GameObject("LeftHand Controller");
            leftController.transform.SetParent(cameraOffset.transform);
            
            // Add XR Ray Interactor for left hand
            var leftRayInteractor = leftController.AddComponent<UnityEngine.XR.Interaction.Toolkit.Interactors.XRRayInteractor>();
            leftRayInteractor.rayOriginTransform = leftController.transform;
            
            // Add XR Direct Interactor for grabbing
            leftController.AddComponent<UnityEngine.XR.Interaction.Toolkit.Interactors.XRDirectInteractor>();

            // Create Right Controller (XR Interaction Toolkit 3.0+ approach)
            GameObject rightController = new GameObject("RightHand Controller");
            rightController.transform.SetParent(cameraOffset.transform);
            
            // Add XR Ray Interactor for right hand
            var rightRayInteractor = rightController.AddComponent<UnityEngine.XR.Interaction.Toolkit.Interactors.XRRayInteractor>();
            rightRayInteractor.rayOriginTransform = rightController.transform;
            
            // Add XR Direct Interactor for grabbing
            rightController.AddComponent<UnityEngine.XR.Interaction.Toolkit.Interactors.XRDirectInteractor>();

            Debug.Log("SceneSetup: Added modern controller interactors (XR Interaction Toolkit 3.0+).");
        }

        private void CreateBasicEnvironment()
        {
            // Create floor
            GameObject floor = GameObject.CreatePrimitive(PrimitiveType.Plane);
            floor.name = "Floor";
            floor.transform.position = Vector3.zero;
            floor.transform.localScale = new Vector3(5, 1, 5);
            
            if (floorMaterial != null)
                floor.GetComponent<Renderer>().material = floorMaterial;
            else
                floor.GetComponent<Renderer>().material.color = Color.gray;

            // Create some walls for reference
            for (int i = 0; i < 4; i++)
            {
                GameObject wall = GameObject.CreatePrimitive(PrimitiveType.Cube);
                wall.name = $"Wall_{i}";
                wall.transform.localScale = new Vector3(10, 3, 0.1f);
                
                float angle = i * 90f;
                wall.transform.position = new Vector3(
                    Mathf.Sin(angle * Mathf.Deg2Rad) * 8f,
                    1.5f,
                    Mathf.Cos(angle * Mathf.Deg2Rad) * 8f
                );
                wall.transform.rotation = Quaternion.Euler(0, angle, 0);
                
                if (wallMaterial != null)
                    wall.GetComponent<Renderer>().material = wallMaterial;
                else
                    wall.GetComponent<Renderer>().material.color = new Color(0.8f, 0.8f, 1f);
            }

            // Add some interactive objects
            CreateInteractableObjects();

            Debug.Log("SceneSetup: Created basic environment.");
        }

        private void CreateInteractableObjects()
        {
            // Create some cubes to grab
            for (int i = 0; i < 3; i++)
            {
                GameObject cube = GameObject.CreatePrimitive(PrimitiveType.Cube);
                cube.name = $"Interactable Cube {i + 1}";
                cube.transform.position = new Vector3(i * 2 - 2, 1, 2);
                cube.transform.localScale = Vector3.one * 0.3f;
                
                // Add Rigidbody for physics
                Rigidbody rb = cube.AddComponent<Rigidbody>();
                rb.mass = 0.5f;
                
                // Add XR Grab Interactable
                UnityEngine.XR.Interaction.Toolkit.Interactables.XRGrabInteractable grabInteractable = cube.AddComponent<UnityEngine.XR.Interaction.Toolkit.Interactables.XRGrabInteractable>();
                
                // Color the cubes
                cube.GetComponent<Renderer>().material.color = new Color(
                    Random.Range(0.3f, 1f),
                    Random.Range(0.3f, 1f),
                    Random.Range(0.3f, 1f)
                );
            }

            Debug.Log("SceneSetup: Created interactable objects.");
        }

        private void CleanupAudioListeners()
        {
            AudioListener[] listeners = FindObjectsOfType<AudioListener>();
            if (listeners.Length > 1)
            {
                Debug.LogWarning($"SceneSetup: Found {listeners.Length} AudioListeners. Removing duplicates...");
                
                for (int i = 1; i < listeners.Length; i++)
                {
                    Debug.Log($"SceneSetup: Removing duplicate AudioListener from {listeners[i].gameObject.name}");
                    DestroyImmediate(listeners[i]);
                }
                
                Debug.Log("SceneSetup: AudioListener cleanup complete.");
            }
        }

        [ContextMenu("Setup VR Scene Now")]
        public void SetupSceneManually()
        {
            SetupScene();
        }

        [ContextMenu("Check XR Status")]
        public void CheckXRStatus()
        {
            var manager = XRGeneralSettings.Instance?.Manager;
            if (manager == null)
            {
                Debug.Log("XR Status: XR Manager is null. XR not configured in Project Settings.");
            }
            else if (manager.activeLoader == null)
            {
                Debug.Log("XR Status: XR Manager exists but no active loader. XR not initialized.");
            }
            else
            {
                Debug.Log($"XR Status: XR is active with loader '{manager.activeLoader.name}'. Initialization complete: {manager.isInitializationComplete}");
            }
        }

        [ContextMenu("Clear Scene")]
        public void ClearScene()
        {
            // Remove existing VR components
            XROrigin[] origins = FindObjectsOfType<XROrigin>();
            XRInteractionManager[] managers = FindObjectsOfType<XRInteractionManager>();
            
            foreach (var origin in origins)
                DestroyImmediate(origin.gameObject);
            
            foreach (var manager in managers)
                DestroyImmediate(manager.gameObject);
            
            Debug.Log("SceneSetup: Scene cleared of VR components.");
        }
    }
}
