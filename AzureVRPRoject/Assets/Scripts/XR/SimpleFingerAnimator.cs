using UnityEngine;
using UnityEngine.XR;

namespace AzureVR
{
    /// <summary>
    /// Simple finger animator that rotates finger bones based on controller input
    /// Replaces controller animations with hand animations
    /// </summary>
    public class SimpleFingerAnimator : MonoBehaviour
    {
        [Header("Controller Input")]
        public XRNode controllerNode = XRNode.LeftHand;
        
        [Header("Metacarpal Bones (drag from hierarchy)")]
        public Transform thumbBone;
        public Transform indexMetacarpal;
        public Transform middleMetacarpal;
        public Transform ringMetacarpal;
        public Transform littleMetacarpal;
        
        [Header("Animation Settings")]
        [Range(0, 90)]
        public float maxFingerCurl = 45f;
        [Range(0, 90)] 
        public float maxThumbCurl = 60f;
        public float animationSpeed = 8f;
        
        private UnityEngine.XR.InputDevice inputDevice;
        private float currentGrip = 0f;
        private float currentTrigger = 0f;

        private void Start()
        {
            inputDevice = UnityEngine.XR.InputDevices.GetDeviceAtXRNode(controllerNode);
            
            // Auto-find bones if not assigned
            if (thumbBone == null || indexMetacarpal == null)
            {
                AutoFindBones();
            }
        }

        private void Update()
        {
            if (!inputDevice.isValid)
            {
                inputDevice = UnityEngine.XR.InputDevices.GetDeviceAtXRNode(controllerNode);
                return;
            }

            // Get controller input
            inputDevice.TryGetFeatureValue(CommonUsages.grip, out float grip);
            inputDevice.TryGetFeatureValue(CommonUsages.trigger, out float trigger);
            
            // Smooth the input
            currentGrip = Mathf.Lerp(currentGrip, grip, Time.deltaTime * animationSpeed);
            currentTrigger = Mathf.Lerp(currentTrigger, trigger, Time.deltaTime * animationSpeed);
            
            // Animate fingers
            AnimateFingers();
        }

        private void AnimateFingers()
        {
            // Thumb joints curl with trigger
            float thumbCurl = currentTrigger * maxThumbCurl;
            if (thumbJoint1 != null)
                thumbJoint1.localRotation = Quaternion.Euler(thumbCurl * 0.6f, 0, 0);
            if (thumbJoint2 != null)
                thumbJoint2.localRotation = Quaternion.Euler(thumbCurl, 0, 0);
            
            // Index finger curls more with trigger (pointing gesture)
            float indexCurl = (currentGrip * 0.3f + currentTrigger * 0.7f) * maxFingerCurl;
            if (indexJoint1 != null)
                indexJoint1.localRotation = Quaternion.Euler(indexCurl * 0.6f, 0, 0);
            if (indexJoint2 != null)
                indexJoint2.localRotation = Quaternion.Euler(indexCurl, 0, 0);
            
            // Other fingers curl mainly with grip
            float fingerCurl = currentGrip * maxFingerCurl;
            
            // Middle finger
            if (middleJoint1 != null)
                middleJoint1.localRotation = Quaternion.Euler(fingerCurl * 0.6f, 0, 0);
            if (middleJoint2 != null)
                middleJoint2.localRotation = Quaternion.Euler(fingerCurl, 0, 0);
                
            // Ring finger
            if (ringJoint1 != null)
                ringJoint1.localRotation = Quaternion.Euler(fingerCurl * 0.6f, 0, 0);
            if (ringJoint2 != null)
                ringJoint2.localRotation = Quaternion.Euler(fingerCurl, 0, 0);
                
            // Pinky finger
            if (pinkyJoint1 != null)
                pinkyJoint1.localRotation = Quaternion.Euler(fingerCurl * 0.6f, 0, 0);
            if (pinkyJoint2 != null)
                pinkyJoint2.localRotation = Quaternion.Euler(fingerCurl, 0, 0);
        }

        private void AutoFindBones()
        {
            // Try to find finger joint bones by name
            Transform[] children = GetComponentsInChildren<Transform>();
            
            foreach (Transform child in children)
            {
                string name = child.name.ToLower();
                
                // Look for actual finger joint bones, not metacarpals
                if (name.Contains("thumb_01") || name.Contains("thumb.01"))
                    thumbJoint1 = child;
                else if (name.Contains("thumb_02") || name.Contains("thumb.02"))
                    thumbJoint2 = child;
                else if (name.Contains("index_01") || name.Contains("index.01"))
                    indexJoint1 = child;
                else if (name.Contains("index_02") || name.Contains("index.02"))
                    indexJoint2 = child;
                else if (name.Contains("middle_01") || name.Contains("middle.01"))
                    middleJoint1 = child;
                else if (name.Contains("middle_02") || name.Contains("middle.02"))
                    middleJoint2 = child;
                else if (name.Contains("ring_01") || name.Contains("ring.01"))
                    ringJoint1 = child;
                else if (name.Contains("ring_02") || name.Contains("ring.02"))
                    ringJoint2 = child;
                else if (name.Contains("pinky_01") || name.Contains("pinky.01") || name.Contains("little_01"))
                    pinkyJoint1 = child;
                else if (name.Contains("pinky_02") || name.Contains("pinky.02") || name.Contains("little_02"))
                    pinkyJoint2 = child;
            }
            
            Debug.Log($"Auto-found finger joints: Thumb1={thumbJoint1?.name}, Index1={indexJoint1?.name}");
        }
    }
}
