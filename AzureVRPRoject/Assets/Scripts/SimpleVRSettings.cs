using UnityEngine;
using UnityEngine.XR.Interaction.Toolkit;
using UnityEngine.XR.Interaction.Toolkit.Locomotion.Movement;
using UnityEngine.XR.Interaction.Toolkit.Locomotion.Turning;
using UnityEngine.XR.Interaction.Toolkit.Locomotion.Teleportation;

namespace AzureVR
{
    /// <summary>
    /// Simple VR settings using XR Interaction Toolkit 3.0+ locomotion providers
    /// Updated to use the new non-deprecated components
    /// </summary>
    public class SimpleVRSettings : MonoBehaviour
    {
        [Header("Locomotion Providers (Auto-found)")]
        private ContinuousMoveProvider continuousMoveProvider;
        private SnapTurnProvider snapTurnProvider;
        private TeleportationProvider teleportationProvider;

        [Header("Current Settings")]
        public bool smoothMovementEnabled = true;
        public bool snapTurnEnabled = true;
        public bool teleportationEnabled = true;

        void Start()
        {
            // Find the modern locomotion providers (XR Interaction Toolkit 3.0+)
            continuousMoveProvider = FindObjectOfType<ContinuousMoveProvider>();
            snapTurnProvider = FindObjectOfType<SnapTurnProvider>();
            teleportationProvider = FindObjectOfType<TeleportationProvider>();

            if (continuousMoveProvider == null)
                Debug.LogWarning("No ContinuousMoveProvider found. Add XR Origin (XR Rig) prefab to scene.");
            
            if (snapTurnProvider == null)
                Debug.LogWarning("No SnapTurnProvider found. Add XR Origin (XR Rig) prefab to scene.");
            
            if (teleportationProvider == null)
                Debug.LogWarning("No TeleportationProvider found. Add XR Origin (XR Rig) prefab to scene.");

            ApplySettings();
        }

        private void ApplySettings()
        {
            // Enable/disable the built-in providers
            if (continuousMoveProvider != null)
                continuousMoveProvider.enabled = smoothMovementEnabled;
            
            if (snapTurnProvider != null)
                snapTurnProvider.enabled = snapTurnEnabled;
            
            if (teleportationProvider != null)
                teleportationProvider.enabled = teleportationEnabled;
        }

        // Simple toggle methods for UI buttons
        public void ToggleSmoothMovement()
        {
            smoothMovementEnabled = !smoothMovementEnabled;
            if (continuousMoveProvider != null)
                continuousMoveProvider.enabled = smoothMovementEnabled;
            Debug.Log($"Smooth Movement: {smoothMovementEnabled}");
        }

        public void ToggleSnapTurn()
        {
            snapTurnEnabled = !snapTurnEnabled;
            if (snapTurnProvider != null)
                snapTurnProvider.enabled = snapTurnEnabled;
            Debug.Log($"Snap Turn: {snapTurnEnabled}");
        }

        public void ToggleTeleportation()
        {
            teleportationEnabled = !teleportationEnabled;
            if (teleportationProvider != null)
                teleportationProvider.enabled = teleportationEnabled;
            Debug.Log($"Teleportation: {teleportationEnabled}");
        }
    }
}
