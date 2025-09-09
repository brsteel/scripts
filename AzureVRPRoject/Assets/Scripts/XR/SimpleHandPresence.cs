using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.XR;
using UnityEngine.XR.Interaction.Toolkit;

namespace AzureVR
{
    // Minimal placeholder to show controller/hand objects if desired.
    public class SimpleHandPresence : MonoBehaviour
    {
        public GameObject handModelPrefab;
        private GameObject _spawned;
        public InputActionProperty poseAction; // Optional if using new input system bindings.

        void Start()
        {
            if (handModelPrefab != null)
            {
                _spawned = Instantiate(handModelPrefab, transform);
            }
        }

        void Update()
        {
            if (poseAction.action != null && _spawned != null)
            {
                var val = poseAction.action.ReadValue<Pose>();
                transform.localPosition = val.position;
                transform.localRotation = val.rotation;
            }
        }
    }
}
