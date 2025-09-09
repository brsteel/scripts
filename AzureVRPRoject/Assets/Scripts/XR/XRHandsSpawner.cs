using UnityEngine;
using System.Collections; // for coroutine retry
using UnityEngine.XR;
using UnityEngine.XR.Interaction.Toolkit;
using Unity.XR.CoreUtils; // For XROrigin

namespace AzureVR
{
    // Simple runtime hand/controller objects so user can see hands and grab spawned interactables.
    // Uses legacy XRNode tracking (sufficient for basic pose) + XRController for toolkit linkage.
    [DisallowMultipleComponent]
    public class XRHandsSpawner : MonoBehaviour
    {
        [Header("Visuals")] public float handScale = 0.08f; // sphere radius
        public Color leftColor = new Color(0.2f, 0.7f, 1f, 0.8f);
        public Color rightColor = new Color(1f, 0.4f, 0.2f, 0.8f);
        [Tooltip("Add small forward offset so hands start in front of headset.")] public Vector3 initialOffset = new Vector3(0f, -0.1f, 0.25f);

        [Header("Ray (Optional)")] public bool addRayInteractors = false; public float rayLength = 8f;

        private XROrigin _origin;

        private void Start()
        {
            StartCoroutine(EnsureOriginAndSpawn());
        }

        private IEnumerator EnsureOriginAndSpawn()
        {
            const int maxFrames = 120; // ~2 seconds at 60fps
            int frame = 0;
            while (_origin == null && frame < maxFrames)
            {
                _origin = FindObjectOfType<XROrigin>();
                if (_origin != null) break;
                yield return null; frame++;
            }
            if (_origin == null)
            {
                Debug.LogWarning("XRHandsSpawner: XROrigin not found after waiting; hands not spawned.");
                yield break;
            }
            CreateHand(XRNode.LeftHand, "LeftHand", leftColor);
            CreateHand(XRNode.RightHand, "RightHand", rightColor);
        }

        private void CreateHand(XRNode node, string name, Color color)
        {
            if (transform.Find(name) != null) return; // already exists
            var go = new GameObject(name);
            go.transform.SetParent(_origin.CameraFloorOffsetObject.transform, false);
            go.transform.localPosition = initialOffset + (node == XRNode.LeftHand ? new Vector3(-0.15f, 0f, 0f) : new Vector3(0.15f, 0f, 0f));

            // Visual sphere
            var sphere = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            sphere.name = "Visual";
            sphere.transform.SetParent(go.transform, false);
            sphere.transform.localScale = Vector3.one * handScale;
            var mr = sphere.GetComponent<MeshRenderer>();
            if (mr != null)
            {
                var mat = new Material(Shader.Find("Universal Render Pipeline/Lit"));
                mat.color = color;
                mr.sharedMaterial = mat;
            }
            DestroyImmediate(sphere.GetComponent<Collider>()); // remove default collider; we'll add trigger collider at root

            // Tracking + interaction components (using modern VRHandTracker instead of deprecated XRController)
            var handTracker = go.AddComponent<VRHandTracker>();
            handTracker.trackingNode = node;
            var interactor = go.AddComponent<UnityEngine.XR.Interaction.Toolkit.Interactors.XRDirectInteractor>();
            // Collider (trigger) for direct grabs
            var col = go.AddComponent<SphereCollider>();
            col.isTrigger = true; col.radius = handScale * 0.6f;

            // Optional ray for distance (disabled by default unless flag set)
            if (addRayInteractors)
            {
                var rayGO = new GameObject("Ray");
                rayGO.transform.SetParent(go.transform, false);
                var ray = rayGO.AddComponent<UnityEngine.XR.Interaction.Toolkit.Interactors.XRRayInteractor>();
                ray.maxRaycastDistance = rayLength;
                ray.gameObject.SetActive(false); // leave off unless user enables at runtime
            }
        }
    }
}
