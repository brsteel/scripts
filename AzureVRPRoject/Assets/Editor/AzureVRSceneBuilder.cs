// Auto-generated helper to build a demo scene with locomotion, construct environment, auth + tenant visualization.
#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.XR.Interaction.Toolkit;
using TMPro;
using AzureVR.Auth; // AuthManager
using AzureVR.Visualization; // TenantVisualizer

namespace AzureVR.Editor
{
    public static class AzureVRSceneBuilder
    {
        private const string ScenePath = "Assets/Scenes/Main.unity";
        private const string PrefabsFolder = "Assets/Prefabs";
        private const string TextPrefabPath = PrefabsFolder + "/TextLinePrefab.prefab";

        [MenuItem("Tools/AzureVR/Generate Sample Scene", priority = 0)]
        public static void GenerateScene()
        {
            if (!System.IO.Directory.Exists("Assets/Scenes"))
                System.IO.Directory.CreateDirectory("Assets/Scenes");
            if (!System.IO.Directory.Exists(PrefabsFolder))
                System.IO.Directory.CreateDirectory(PrefabsFolder);

            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            scene.name = "Main";

            // ConstructRoot with XRConstructRig
            var constructRoot = new GameObject("ConstructRoot");
            var rig = constructRoot.AddComponent<XRConstructRig>();
            rig.cubeCount = 6;

            // Modern VR setup using XR Interaction Toolkit 3.0+
            var sceneSetupGO = new GameObject("VR Scene Setup");
            var sceneSetup = sceneSetupGO.AddComponent<SceneSetup>();
            sceneSetup.initializeXR = true;
            sceneSetup.createBasicEnvironment = true;
            
            Debug.Log("AzureVRSceneBuilder: Added modern SceneSetup component (replaces old custom locomotion).");

            // Auth manager
            var authGO = new GameObject("Auth");
            var auth = authGO.AddComponent<AuthManager>();
            auth.ClientId = "<PUT-YOUR-CLIENT-ID-HERE>"; // Placeholder

            // Tenant viz root
            var vizRoot = new GameObject("TenantVizRoot");

            // Text prefab ensure
            GameObject textPrefab = AssetDatabase.LoadAssetAtPath<GameObject>(TextPrefabPath);
            if (textPrefab == null)
            {
                var temp = new GameObject("TextLinePrefab");
                var tmp = temp.AddComponent<TextMeshPro>();
                tmp.text = "Sample";
                tmp.fontSize = 0.2f;
                tmp.alignment = TextAlignmentOptions.Left;
                tmp.color = Color.cyan;
                PrefabUtility.SaveAsPrefabAsset(temp, TextPrefabPath);
                Object.DestroyImmediate(temp);
                textPrefab = AssetDatabase.LoadAssetAtPath<GameObject>(TextPrefabPath);
            }

            // Tenant visualizer
            var vizGO = new GameObject("TenantVisualizer");
            var viz = vizGO.AddComponent<TenantVisualizer>();
            viz.AuthManager = auth;
            viz.RootParent = vizRoot.transform;
            if (textPrefab != null) viz.TextPrefab = textPrefab;

            // Position constructs slightly in front of camera spawn (camera will be created at runtime by XRConstructRig).
            vizRoot.transform.position = new Vector3(0, 1.2f, 1.5f);

            // Mark scene dirty and save
            EditorSceneManager.MarkSceneDirty(scene);
            EditorSceneManager.SaveScene(scene, ScenePath);
            AssetDatabase.SaveAssets();
            Debug.Log("AzureVR sample scene generated at " + ScenePath);
        }
    }
}
#endif
