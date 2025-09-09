using UnityEngine;

namespace AzureVR
{
    /// <summary>
    /// Add this component to any GameObject in your scene to automatically set up VR
    /// This replaces all the custom scripts with proper XR Interaction Toolkit usage
    /// </summary>
    public class AutoVRSetup : MonoBehaviour
    {
        void Start()
        {
            // Find or create the SceneSetup component
            SceneSetup sceneSetup = FindObjectOfType<SceneSetup>();
            
            if (sceneSetup == null)
            {
                // Create a GameObject with SceneSetup component
                GameObject setupGO = new GameObject("VR Scene Setup");
                sceneSetup = setupGO.AddComponent<SceneSetup>();
                Debug.Log("AutoVRSetup: Created SceneSetup component automatically.");
            }
            
            // The SceneSetup will handle everything from here
            Debug.Log("AutoVRSetup: VR initialization delegated to SceneSetup component.");
            
            // Remove this component as it's no longer needed
            Destroy(this);
        }
    }
}
