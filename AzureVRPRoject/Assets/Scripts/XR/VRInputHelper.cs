using UnityEngine;
using UnityEngine.XR;
using System.Collections.Generic;

namespace AzureVR
{
    /// <summary>
    /// Helper class for VR input management and controller detection
    /// </summary>
    public static class VRInputHelper
    {
        private static readonly Dictionary<XRNode, InputDevice> cachedDevices = new Dictionary<XRNode, InputDevice>();
        private static float lastUpdateTime = 0f;
        private const float CACHE_UPDATE_INTERVAL = 0.5f; // Update cache twice per second

        /// <summary>
        /// Get input device for specified XR node (with caching for performance)
        /// </summary>
        public static InputDevice GetInputDevice(XRNode node)
        {
            // Update cache periodically
            if (Time.time - lastUpdateTime > CACHE_UPDATE_INTERVAL)
            {
                UpdateDeviceCache();
                lastUpdateTime = Time.time;
            }

            cachedDevices.TryGetValue(node, out InputDevice device);
            return device;
        }

        /// <summary>
        /// Check if a button is pressed on the specified controller
        /// </summary>
        public static bool IsButtonPressed(XRNode node, InputFeatureUsage<bool> button)
        {
            var device = GetInputDevice(node);
            if (device.isValid && device.TryGetFeatureValue(button, out bool value))
            {
                return value;
            }
            return false;
        }

        /// <summary>
        /// Get 2D axis value from controller (e.g., thumbstick)
        /// </summary>
        public static Vector2 GetAxis2D(XRNode node, InputFeatureUsage<Vector2> axis)
        {
            var device = GetInputDevice(node);
            if (device.isValid && device.TryGetFeatureValue(axis, out Vector2 value))
            {
                return value;
            }
            return Vector2.zero;
        }

        /// <summary>
        /// Get float value from controller (e.g., trigger)
        /// </summary>
        public static float GetFloat(XRNode node, InputFeatureUsage<float> feature)
        {
            var device = GetInputDevice(node);
            if (device.isValid && device.TryGetFeatureValue(feature, out float value))
            {
                return value;
            }
            return 0f;
        }

        /// <summary>
        /// Send haptic feedback to controller
        /// </summary>
        public static void SendHapticFeedback(XRNode node, float amplitude, float duration)
        {
            var device = GetInputDevice(node);
            if (device.isValid)
            {
                device.SendHapticImpulse(0, amplitude, duration);
            }
        }

        /// <summary>
        /// Check if menu button is pressed on either controller
        /// </summary>
        public static bool IsMenuButtonPressed()
        {
            return IsButtonPressed(XRNode.LeftHand, CommonUsages.menuButton) ||
                   IsButtonPressed(XRNode.RightHand, CommonUsages.menuButton) ||
                   IsButtonPressed(XRNode.LeftHand, CommonUsages.secondaryButton) ||
                   IsButtonPressed(XRNode.RightHand, CommonUsages.secondaryButton);
        }

        /// <summary>
        /// Check if primary button is pressed on either controller
        /// </summary>
        public static bool IsPrimaryButtonPressed()
        {
            return IsButtonPressed(XRNode.LeftHand, CommonUsages.primaryButton) ||
                   IsButtonPressed(XRNode.RightHand, CommonUsages.primaryButton);
        }

        /// <summary>
        /// Check if secondary button is pressed on either controller
        /// </summary>
        public static bool IsSecondaryButtonPressed()
        {
            return IsButtonPressed(XRNode.LeftHand, CommonUsages.secondaryButton) ||
                   IsButtonPressed(XRNode.RightHand, CommonUsages.secondaryButton);
        }

        /// <summary>
        /// Get controller name/type for debugging
        /// </summary>
        public static string GetControllerName(XRNode node)
        {
            var device = GetInputDevice(node);
            return device.isValid ? device.name : "Unknown";
        }

        /// <summary>
        /// Check if any VR controllers are connected
        /// </summary>
        public static bool AreControllersConnected()
        {
            var leftDevice = GetInputDevice(XRNode.LeftHand);
            var rightDevice = GetInputDevice(XRNode.RightHand);
            return leftDevice.isValid || rightDevice.isValid;
        }

        /// <summary>
        /// Get debug info about connected controllers
        /// </summary>
        public static string GetControllerDebugInfo()
        {
            var info = "VR Controllers:\n";
            
            var leftDevice = GetInputDevice(XRNode.LeftHand);
            var rightDevice = GetInputDevice(XRNode.RightHand);

            info += $"Left: {(leftDevice.isValid ? leftDevice.name : "Not connected")}\n";
            info += $"Right: {(rightDevice.isValid ? rightDevice.name : "Not connected")}\n";

            if (leftDevice.isValid)
            {
                info += $"Left Features: {string.Join(", ", GetDeviceFeatures(leftDevice))}\n";
            }

            if (rightDevice.isValid)
            {
                info += $"Right Features: {string.Join(", ", GetDeviceFeatures(rightDevice))}\n";
            }

            return info;
        }

        private static void UpdateDeviceCache()
        {
            var inputDevices = new List<InputDevice>();
            InputDevices.GetDevices(inputDevices);

            cachedDevices.Clear();

            foreach (var device in inputDevices)
            {
                if (device.characteristics.HasFlag(InputDeviceCharacteristics.Left | InputDeviceCharacteristics.Controller))
                {
                    cachedDevices[XRNode.LeftHand] = device;
                }
                else if (device.characteristics.HasFlag(InputDeviceCharacteristics.Right | InputDeviceCharacteristics.Controller))
                {
                    cachedDevices[XRNode.RightHand] = device;
                }
                else if (device.characteristics.HasFlag(InputDeviceCharacteristics.HeadMounted))
                {
                    cachedDevices[XRNode.Head] = device;
                }
            }
        }

        private static List<string> GetDeviceFeatures(InputDevice device)
        {
            var features = new List<string>();
            var featureUsages = new List<InputFeatureUsage>();
            
            if (device.TryGetFeatureUsages(featureUsages))
            {
                foreach (var usage in featureUsages)
                {
                    features.Add(usage.name);
                }
            }

            return features;
        }

        /// <summary>
        /// Initialize VR input system (call this at startup)
        /// </summary>
        public static void Initialize()
        {
            InputDevices.deviceConnected += OnDeviceConnected;
            InputDevices.deviceDisconnected += OnDeviceDisconnected;
            UpdateDeviceCache();
            
            Debug.Log("VRInputHelper: Initialized");
        }

        /// <summary>
        /// Cleanup VR input system
        /// </summary>
        public static void Cleanup()
        {
            InputDevices.deviceConnected -= OnDeviceConnected;
            InputDevices.deviceDisconnected -= OnDeviceDisconnected;
            cachedDevices.Clear();
        }

        private static void OnDeviceConnected(InputDevice device)
        {
            Debug.Log($"VRInputHelper: Device connected - {device.name}");
            UpdateDeviceCache();
        }

        private static void OnDeviceDisconnected(InputDevice device)
        {
            Debug.Log($"VRInputHelper: Device disconnected - {device.name}");
            UpdateDeviceCache();
        }
    }
}
