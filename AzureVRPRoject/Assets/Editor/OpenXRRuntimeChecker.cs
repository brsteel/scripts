// Utility to verify the active OpenXR runtime on Windows (helpful for Virtual Desktop without SteamVR).
#if UNITY_EDITOR && UNITY_STANDALONE_WIN
using UnityEditor;
using UnityEngine;
using System;
using Microsoft.Win32;

namespace AzureVR.Editor
{
    [InitializeOnLoad]
    public static class OpenXRRuntimeChecker
    {
        private const string KhronosKeyPath = @"HKEY_LOCAL_MACHINE\Software\Khronos\OpenXR\1";
        private const string ValueName = "ActiveRuntime";
        private static DateTime _lastLogged = DateTime.MinValue;

        static OpenXRRuntimeChecker()
        {
            // Defer slightly so other domain load logs don't bury ours.
            EditorApplication.delayCall += () => CheckRuntime(verbose:false);
        }

        [MenuItem("Tools/AzureVR/Check OpenXR Runtime", priority = 50)]
        public static void MenuCheck() => CheckRuntime(verbose:true);

        private static void CheckRuntime(bool verbose)
        {
            try
            {
                var path = (string)Registry.GetValue(KhronosKeyPath, ValueName, null);
                if (string.IsNullOrEmpty(path))
                {
                    if (ShouldLog()) Debug.LogWarning("OpenXR runtime not set (registry value empty). Set Oculus runtime via Oculus App > Settings > General > OpenXR.");
                    return;
                }

                string lower = path.ToLowerInvariant();
                bool isOculus = lower.Contains("oculus_openxr");
                bool isSteam = lower.Contains("steamxr" ) || lower.Contains("steamvr");
                string msg = $"Active OpenXR runtime: {path}\nDetected: " + (isOculus ? "Oculus" : (isSteam ? "SteamVR" : "Other"));

                if (isOculus)
                {
                    if (verbose || ShouldLog()) Debug.Log("[OpenXRRuntimeChecker] " + msg + " (OK for Virtual Desktop without SteamVR)");
                }
                else
                {
                    if (ShouldLog()) Debug.LogWarning("[OpenXRRuntimeChecker] " + msg + "\nFor Virtual Desktop (no SteamVR) ensure Oculus is active.");
                }
            }
            catch (Exception ex)
            {
                if (ShouldLog()) Debug.LogError("[OpenXRRuntimeChecker] Failed to read OpenXR runtime: " + ex.Message);
            }
        }

        private static bool ShouldLog()
        {
            if ((DateTime.UtcNow - _lastLogged).TotalSeconds > 10)
            {
                _lastLogged = DateTime.UtcNow; return true;
            }
            return false;
        }
    }
}
#endif
