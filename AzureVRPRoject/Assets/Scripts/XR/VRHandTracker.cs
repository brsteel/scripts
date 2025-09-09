using UnityEngine;
using UnityEngine.XR;
using UnityEngine.XR.Interaction.Toolkit;

namespace AzureVR
{
    /// <summary>
    /// Modern VR hand tracking component compatible with XR Interaction Toolkit 3.0+
    /// Replaces the deprecated XRController functionality
    /// </summary>
    public class VRHandTracker : MonoBehaviour
    {
        [Header("Tracking Configuration")]
        public XRNode trackingNode = XRNode.LeftHand;
        public bool trackPosition = true;
        public bool trackRotation = true;
        
        [Header("Smoothing")]
        public bool enableSmoothing = true;
        public float positionSmoothing = 10f;
        public float rotationSmoothing = 10f;

        private InputDevice inputDevice;
        private bool deviceValid = false;

        private void Start()
        {
            // Initialize device tracking
            UpdateInputDevice();
        }

        private void Update()
        {
            // Update device reference if needed
            if (!deviceValid || !inputDevice.isValid)
            {
                UpdateInputDevice();
            }

            // Update transform based on tracked device
            if (deviceValid && inputDevice.isValid)
            {
                UpdateTransform();
            }
        }

        private void UpdateInputDevice()
        {
            // Get the input device for this tracking node
            inputDevice = InputDevices.GetDeviceAtXRNode(trackingNode);
            deviceValid = inputDevice.isValid;

            if (deviceValid)
            {
                Debug.Log($"VRHandTracker: Connected to {inputDevice.name} for {trackingNode}");
            }
        }

        private void UpdateTransform()
        {
            // Get position
            if (trackPosition && inputDevice.TryGetFeatureValue(CommonUsages.devicePosition, out Vector3 position))
            {
                if (enableSmoothing)
                {
                    transform.localPosition = Vector3.Lerp(transform.localPosition, position, positionSmoothing * Time.deltaTime);
                }
                else
                {
                    transform.localPosition = position;
                }
            }

            // Get rotation
            if (trackRotation && inputDevice.TryGetFeatureValue(CommonUsages.deviceRotation, out Quaternion rotation))
            {
                if (enableSmoothing)
                {
                    transform.localRotation = Quaternion.Lerp(transform.localRotation, rotation, rotationSmoothing * Time.deltaTime);
                }
                else
                {
                    transform.localRotation = rotation;
                }
            }
        }

        /// <summary>
        /// Get the current input device for this tracker
        /// </summary>
        public InputDevice GetInputDevice()
        {
            return inputDevice;
        }

        /// <summary>
        /// Check if the tracked device is valid and connected
        /// </summary>
        public bool IsDeviceValid()
        {
            return deviceValid && inputDevice.isValid;
        }

        /// <summary>
        /// Send haptic feedback to the tracked device
        /// </summary>
        public void SendHapticFeedback(float amplitude, float duration)
        {
            if (IsDeviceValid())
            {
                inputDevice.SendHapticImpulse(0, amplitude, duration);
            }
        }

        /// <summary>
        /// Get button state from the tracked device
        /// </summary>
        public bool GetButton(InputFeatureUsage<bool> button)
        {
            if (IsDeviceValid() && inputDevice.TryGetFeatureValue(button, out bool value))
            {
                return value;
            }
            return false;
        }

        /// <summary>
        /// Get float value from the tracked device
        /// </summary>
        public float GetFloat(InputFeatureUsage<float> feature)
        {
            if (IsDeviceValid() && inputDevice.TryGetFeatureValue(feature, out float value))
            {
                return value;
            }
            return 0f;
        }

        /// <summary>
        /// Get Vector2 value from the tracked device
        /// </summary>
        public Vector2 GetVector2(InputFeatureUsage<Vector2> feature)
        {
            if (IsDeviceValid() && inputDevice.TryGetFeatureValue(feature, out Vector2 value))
            {
                return value;
            }
            return Vector2.zero;
        }
    }
}
