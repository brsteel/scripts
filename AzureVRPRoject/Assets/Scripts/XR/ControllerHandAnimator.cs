using UnityEngine;
using UnityEngine.XR;

namespace AzureVR
{
    /// <summary>
    /// Controller-driven hand animations - hands follow controllers and animate based on input
    /// This is how most VR games do hands (no hand tracking required)
    /// </summary>
    public class ControllerHandAnimator : MonoBehaviour
    {
        [Header("Hand Setup")]
        [Tooltip("The hand model (should have an Animator component)")]
        public Animator handAnimator;
        [Tooltip("Which hand is this? (affects input mapping)")]
        public XRNode controllerNode = XRNode.LeftHand;
        
        [Header("Animation Parameters")]
        [Tooltip("Animator parameter name for grip (0-1)")]
        public string gripParam = "Grip";
        [Tooltip("Animator parameter name for trigger (0-1)")]
        public string triggerParam = "Trigger";
        [Tooltip("Animator parameter name for point gesture")]
        public string pointParam = "Point";
        
        [Header("Input Smoothing")]
        public float animationSpeed = 10f;
        
        // Input tracking
        private UnityEngine.XR.InputDevice targetDevice;
        private float currentGrip = 0f;
        private float currentTrigger = 0f;
        private float targetGrip = 0f;
        private float targetTrigger = 0f;

        private void Start()
        {
            // Find the input device for this controller
            GetDevice();
        }

        private void Update()
        {
            // Make sure we have a valid device
            if (!targetDevice.isValid)
            {
                GetDevice();
                return;
            }

            // Get controller input
            UpdateControllerInput();
            
            // Smooth the animation values
            SmoothAnimationValues();
            
            // Update hand animations
            UpdateHandAnimation();
            
            // Update hand position/rotation to match controller
            UpdateHandTransform();
        }

        private void GetDevice()
        {
            targetDevice = UnityEngine.XR.InputDevices.GetDeviceAtXRNode(controllerNode);
        }

        private void UpdateControllerInput()
        {
            // Get grip value (how much the grip button is pressed)
            if (targetDevice.TryGetFeatureValue(CommonUsages.grip, out float gripValue))
            {
                targetGrip = gripValue;
            }

            // Get trigger value (how much the trigger is pressed)  
            if (targetDevice.TryGetFeatureValue(CommonUsages.trigger, out float triggerValue))
            {
                targetTrigger = triggerValue;
            }
        }

        private void SmoothAnimationValues()
        {
            // Smooth the animation transitions
            currentGrip = Mathf.Lerp(currentGrip, targetGrip, Time.deltaTime * animationSpeed);
            currentTrigger = Mathf.Lerp(currentTrigger, targetTrigger, Time.deltaTime * animationSpeed);
        }

        private void UpdateHandAnimation()
        {
            if (handAnimator == null) return;

            // Set animation parameters
            handAnimator.SetFloat(gripParam, currentGrip);
            handAnimator.SetFloat(triggerParam, currentTrigger);
            
            // Point gesture: trigger pressed but not grip (pointing finger)
            bool isPointing = currentTrigger > 0.1f && currentGrip < 0.1f;
            handAnimator.SetBool(pointParam, isPointing);
        }

        private void UpdateHandTransform()
        {
            // Make hand follow controller position and rotation
            if (targetDevice.TryGetFeatureValue(CommonUsages.devicePosition, out Vector3 position))
            {
                transform.position = position;
            }

            if (targetDevice.TryGetFeatureValue(CommonUsages.deviceRotation, out Quaternion rotation))
            {
                transform.rotation = rotation;
            }
        }

        private void OnValidate()
        {
            // Auto-find animator if not assigned
            if (handAnimator == null)
            {
                handAnimator = GetComponentInChildren<Animator>();
            }
        }
    }
}
