using UnityEngine;
using TMPro;

namespace AzureVR
{
    /// <summary>
    /// Displays setup instructions and status in VR
    /// </summary>
    public class SetupInstructions : MonoBehaviour
    {
        [Header("Instruction Display")]
        public GameObject instructionPrefab;
        public Transform instructionParent;
        public float lineSpacing = 0.4f;

        private void Start()
        {
            ShowInstructions();
        }

        private void ShowInstructions()
        {
            if (instructionParent == null)
            {
                var instructionRoot = new GameObject("Instructions Root");
                instructionRoot.transform.position = new Vector3(-2f, 1.5f, 2f);
                instructionParent = instructionRoot.transform;
            }

            var instructions = new string[]
            {
                "Azure VR Setup Instructions:",
                "",
                "1. Set your Azure AD Client ID in SceneSetup",
                "2. Make sure OpenXR is enabled in XR Settings",
                "3. Put on your VR headset",
                "4. Press Play in Unity",
                "5. Check Console for device code",
                "6. Sign in on another device",
                "7. Your tenant info will appear in VR!",
                "",
                "Controls:",
                "- Use thumbsticks to move around",
                "- Grab cubes with grip buttons",
                "- Look around naturally"
            };

            for (int i = 0; i < instructions.Length; i++)
            {
                CreateInstructionLine(instructions[i], i);
            }
        }

        private void CreateInstructionLine(string text, int index)
        {
            GameObject textGO;
            
            if (instructionPrefab != null)
            {
                textGO = Instantiate(instructionPrefab, instructionParent);
            }
            else
            {
                textGO = new GameObject($"Instruction_{index}");
                textGO.transform.SetParent(instructionParent);
                var tmp = textGO.AddComponent<TextMeshPro>();
                tmp.fontSize = 0.3f;
                tmp.color = string.IsNullOrEmpty(text) ? Color.clear : Color.cyan;
                tmp.alignment = TextAlignmentOptions.Left;
            }

            textGO.transform.localPosition = new Vector3(0, -index * lineSpacing, 0);
            
            var tmpComponent = textGO.GetComponent<TextMeshPro>();
            if (tmpComponent != null)
            {
                tmpComponent.text = text;
            }
        }
    }
}
