using UnityEngine;
using UnityEngine.XR.Interaction.Toolkit;
using Unity.XR.CoreUtils; // Needed for XROrigin

namespace AzureVR
{
    // Basic XR Rig setup helper: ensures required components exist and spawns a ground & lighting.
    [DisallowMultipleComponent]
    [DefaultExecutionOrder(-100)] // Ensure rig constructs before dependent spawners
    public class XRConstructRig : MonoBehaviour
    {
        [Header("Auto Spawn Elements")] public bool createFloor = true; public bool createLight = true; public bool createInteractables = true;
        public int cubeCount = 6;
        public Vector2 spawnArea = new Vector2(2f, 2f);
        public float cubeSize = 0.25f;
        public Material cubeMaterial;

        private void Awake()
        {
            EnsureRig();
            if (createFloor) CreateFloor();
            if (createLight) CreateLight();
            if (createInteractables) SpawnCubes();
        }

        private void EnsureRig()
        {
            // If user added this to an empty GameObject, add XR Origin & interaction system.
            XROrigin origin = GetComponentInChildren<XROrigin>();
            if (origin == null)
            {
                var originGO = new GameObject("XR Origin");
                originGO.transform.SetParent(transform, false);
                origin = originGO.AddComponent<XROrigin>();
                // Interaction Manager
                if (FindObjectOfType<XRInteractionManager>() == null)
                {
                    var im = new GameObject("XR Interaction Manager");
                    im.AddComponent<XRInteractionManager>();
                }
            }

            // Ensure a Camera exists (required for rendering & locomotion code referencing origin.Camera)
            if (origin != null && origin.GetComponentInChildren<Camera>() == null)
            {
                var camGO = new GameObject("Main Camera");
                camGO.tag = "MainCamera"; // Unity convention so systems find it
                // Parent to floor offset so height adjustments apply
                var parent = origin.CameraFloorOffsetObject != null ? origin.CameraFloorOffsetObject.transform : origin.transform;
                camGO.transform.SetParent(parent, false);
                camGO.transform.localPosition = Vector3.zero;
                var cam = camGO.AddComponent<Camera>();
                cam.clearFlags = CameraClearFlags.Skybox;
                cam.nearClipPlane = 0.01f;
                camGO.AddComponent<AudioListener>();
            }
        }

        private void CreateFloor()
        {
            var floor = GameObject.CreatePrimitive(PrimitiveType.Plane);
            floor.name = "ConstructFloor";
            floor.transform.SetParent(transform, false);
            floor.transform.localScale = Vector3.one * 2f;
            var mr = floor.GetComponent<MeshRenderer>();
            if (mr != null)
            {
                // Use Standard shader (always available) or fallback to default
                var shader = Shader.Find("Standard") ?? Shader.Find("Legacy Shaders/Diffuse");
                if (shader != null)
                {
                    mr.sharedMaterial = new Material(shader)
                    {
                        color = new Color(0.05f, 0.08f, 0.10f, 1f)
                    };
                }
                else
                {
                    // Just change the color of the existing material
                    mr.material.color = new Color(0.05f, 0.08f, 0.10f, 1f);
                }
            }
        }

        private void CreateLight()
        {
            if (FindObjectOfType<Light>() != null) return;
            var lightGO = new GameObject("KeyLight");
            var light = lightGO.AddComponent<Light>();
            light.type = LightType.Directional;
            light.intensity = 1.1f;
            light.color = new Color(1f, 0.96f, 0.9f);
            lightGO.transform.rotation = Quaternion.Euler(50f, -30f, 0f);
        }

        private void SpawnCubes()
        {
            for (int i = 0; i < cubeCount; i++)
            {
                var cube = GameObject.CreatePrimitive(PrimitiveType.Cube);
                cube.name = $"InteractableCube_{i}";
                cube.transform.SetParent(transform, false);
                cube.transform.localScale = Vector3.one * cubeSize;
                cube.transform.localPosition = new Vector3(
                    Random.Range(-spawnArea.x, spawnArea.x),
                    0.25f + Random.Range(0f, 0.5f),
                    Random.Range(-spawnArea.y, spawnArea.y));

                var rb = cube.AddComponent<Rigidbody>();
                rb.mass = 0.5f;
                rb.collisionDetectionMode = CollisionDetectionMode.Continuous;

                // Add grab interactable
                var grab = cube.AddComponent<UnityEngine.XR.Interaction.Toolkit.Interactables.XRGrabInteractable>();
                grab.throwOnDetach = true;
                grab.throwSmoothingDuration = 0.15f;
                grab.throwSmoothingCurve = AnimationCurve.Linear(0, 0, 1, 1);

                if (cubeMaterial != null)
                {
                    var mr = cube.GetComponent<MeshRenderer>();
                    mr.sharedMaterial = cubeMaterial;
                }
            }
        }
    }
}
