#if UNITY_EDITOR && UNITY_STANDALONE_WIN
using UnityEditor;
using UnityEngine;
using Microsoft.Win32;
using System.IO;

namespace AzureVR.Editor
{
    public class OpenXRRuntimeSwitcher : EditorWindow
    {
        private const string KhronosKeyPath = @"SOFTWARE\Khronos\OpenXR\1";
        private const string ValueName = "ActiveRuntime";
        
        private string currentRuntime = "";
        private string[] availableRuntimes;
        private string[] runtimeNames;
        
        [MenuItem("Tools/AzureVR/OpenXR Runtime Switcher", priority = 51)]
        public static void ShowWindow()
        {
            GetWindow<OpenXRRuntimeSwitcher>("OpenXR Runtime Switcher");
        }
        
        private void OnEnable()
        {
            RefreshRuntimes();
        }
        
        private void RefreshRuntimes()
        {
            // Get current runtime
            try
            {
                using (var key = Registry.LocalMachine.OpenSubKey(KhronosKeyPath))
                {
                    currentRuntime = (string)key?.GetValue(ValueName) ?? "Not set";
                }
            }
            catch
            {
                currentRuntime = "Error reading registry";
            }
            
            // Find available runtimes
            var runtimes = new System.Collections.Generic.List<string>();
            var names = new System.Collections.Generic.List<string>();
            
            // Check for Oculus runtime
            var oculusPath = @"C:\Program Files\Oculus\Support\oculus-runtime\oculus_openxr_64.json";
            if (File.Exists(oculusPath))
            {
                runtimes.Add(oculusPath);
                names.Add("Oculus (Recommended for Quest)");
            }
            
            // Check for Virtual Desktop runtime
            var vdPath = @"C:\Program Files\Virtual Desktop Streamer\OpenXR\virtualdesktop-openxr.json";
            if (File.Exists(vdPath))
            {
                runtimes.Add(vdPath);
                names.Add("Virtual Desktop");
            }
            
            // Check for SteamVR runtime
            var steamPath = @"C:\Program Files (x86)\Steam\steamapps\common\SteamVR\steamxr_win64.json";
            if (File.Exists(steamPath))
            {
                runtimes.Add(steamPath);
                names.Add("SteamVR");
            }
            
            availableRuntimes = runtimes.ToArray();
            runtimeNames = names.ToArray();
        }
        
        private void OnGUI()
        {
            GUILayout.Label("OpenXR Runtime Switcher", EditorStyles.boldLabel);
            
            EditorGUILayout.Space();
            
            GUILayout.Label("Current Runtime:", EditorStyles.label);
            EditorGUILayout.SelectableLabel(currentRuntime, EditorStyles.textArea, GUILayout.Height(40));
            
            EditorGUILayout.Space();
            
            GUILayout.Label("Available Runtimes:", EditorStyles.label);
            
            if (availableRuntimes == null || availableRuntimes.Length == 0)
            {
                GUILayout.Label("No OpenXR runtimes found!");
                EditorGUILayout.Space();
                if (GUILayout.Button("Refresh"))
                {
                    RefreshRuntimes();
                }
                return;
            }
            
            for (int i = 0; i < availableRuntimes.Length; i++)
            {
                EditorGUILayout.BeginHorizontal();
                
                bool isCurrent = availableRuntimes[i].Equals(currentRuntime, System.StringComparison.OrdinalIgnoreCase);
                GUI.enabled = !isCurrent;
                
                if (GUILayout.Button(runtimeNames[i] + (isCurrent ? " (Current)" : ""), GUILayout.Height(25)))
                {
                    SetRuntime(availableRuntimes[i]);
                }
                
                GUI.enabled = true;
                EditorGUILayout.EndHorizontal();
            }
            
            EditorGUILayout.Space();
            
            if (GUILayout.Button("Refresh"))
            {
                RefreshRuntimes();
            }
            
            EditorGUILayout.Space();
            
            EditorGUILayout.HelpBox(
                "For Virtual Desktop (Quest wireless):\n" +
                "• Use Oculus runtime for best compatibility\n" +
                "• Make sure Virtual Desktop is running\n" +
                "• Quest should be connected via Virtual Desktop\n\n" +
                "For native Oculus (Quest Link/Air Link):\n" +
                "• Use Oculus runtime\n" +
                "• Make sure Oculus Desktop app is running\n\n" +
                "Changes take effect immediately - restart Unity after switching.",
                MessageType.Info);
        }
        
        private void SetRuntime(string runtimePath)
        {
            try
            {
                using (var key = Registry.LocalMachine.OpenSubKey(KhronosKeyPath, true))
                {
                    if (key == null)
                    {
                        EditorUtility.DisplayDialog("Error", "Cannot access OpenXR registry key. Run Unity as Administrator.", "OK");
                        return;
                    }
                    
                    key.SetValue(ValueName, runtimePath);
                    Debug.Log($"OpenXR runtime set to: {runtimePath}");
                    EditorUtility.DisplayDialog("Success", $"OpenXR runtime changed successfully!\n\nNew runtime: {Path.GetFileName(runtimePath)}\n\nRestart Unity for changes to take effect.", "OK");
                    RefreshRuntimes();
                }
            }
            catch (System.Exception ex)
            {
                EditorUtility.DisplayDialog("Error", $"Failed to set runtime: {ex.Message}\n\nTry running Unity as Administrator.", "OK");
            }
        }
    }
}
#endif
