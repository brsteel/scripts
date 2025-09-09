// Checks for required MSAL dependency assemblies and logs guidance if missing.
#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;
using System.IO;

namespace AzureVR.Editor
{
    [InitializeOnLoad]
    public static class MSALDependencyChecker
    {
        private static readonly string PluginsDir = "Assets/Plugins/Assemblies";
        private static readonly string[] Required =
        {
            "Microsoft.Identity.Client.dll",
            "Microsoft.IdentityModel.Abstractions.dll",
            "System.Diagnostics.DiagnosticSource.dll"
        };

        static MSALDependencyChecker()
        {
            EditorApplication.delayCall += Check; // run after initial compile
        }

        private static void Check()
        {
            if (!Directory.Exists(PluginsDir)) return;
            bool missing = false;
            foreach (var r in Required)
            {
                if (!File.Exists(Path.Combine(PluginsDir, r)))
                {
                    missing = true; break;
                }
            }
            if (!missing) return;

            Debug.LogWarning("[AzureVR] MSAL dependency assemblies missing. Open Tools > AzureVR > MSAL Dependency Help for instructions.");
        }

        [MenuItem("Tools/AzureVR/MSAL Dependency Help", priority = 50)]
        private static void ShowHelp()
        {
            const string msg = "MSAL dependencies required:\n" +
                               " - Microsoft.Identity.Client.dll (added)\n" +
                               " - Microsoft.IdentityModel.Abstractions.dll\n" +
                               " - System.Diagnostics.DiagnosticSource.dll\n\n" +
                               "Acquire via NuGet: Download the .nupkg for each, rename to .zip, extract, copy the net462 (or netstandard2.0) DLLs into Assets/Plugins/Assemblies.\n" +
                               "Then re-select each DLL in Unity and ensure Any Platform enabled, Editor + Standalone checked.\n\n" +
                               "If you cannot add them now, you may temporarily uncheck Validate References on Microsoft.Identity.Client.dll to suppress warnings (runtime calls may still fail).";
            EditorUtility.DisplayDialog("MSAL Dependency Guidance", msg, "Close");
        }
    }
}
#endif
