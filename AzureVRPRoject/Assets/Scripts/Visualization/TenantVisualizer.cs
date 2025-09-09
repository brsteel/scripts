using System.Linq;
using System.Threading.Tasks;
using AzureVR.Auth;
using AzureVR.Graph;
using Newtonsoft.Json.Linq;
using UnityEngine;
using TMPro;

namespace AzureVR.Visualization
{
    public class TenantVisualizer : MonoBehaviour
    {
        public AuthManager AuthManager;
        public Transform RootParent;
        public GameObject TextPrefab; // Prefab with TextMeshPro component
        public float VerticalSpacing = 0.25f;

        private GraphClient _graphClient = new GraphClient();

        private async void Start()
        {
            if (AuthManager == null)
            {
                Debug.LogError("TenantVisualizer: AuthManager not assigned.");
                return;
            }

            if (!AuthManager.IsAuthenticated)
            {
                await AuthManager.SignInDeviceCodeAsync();
            }

            await LoadAndRenderAsync();
        }

        private async Task LoadAndRenderAsync()
        {
            var org = await _graphClient.GetOrganizationAsync(AuthManager.AccessToken);
            var first = org["value"]?.FirstOrDefault() as JObject;
            if (first == null)
            {
                Debug.LogWarning("TenantVisualizer: No organization objects returned.");
                return;
            }

            int i = 0;
            void SpawnLine(string label, string value)
            {
                if (string.IsNullOrEmpty(value)) return;
                var go = Instantiate(TextPrefab, RootParent);
                go.transform.localPosition = new Vector3(0, -i * VerticalSpacing, 0);
                var tmp = go.GetComponent<TextMeshPro>();
                if (tmp != null)
                {
                    tmp.text = $"{label}: {value}";
                }
                i++;
            }

            SpawnLine("Tenant Id", first.Value<string>("id"));
            SpawnLine("Display Name", first.Value<string>("displayName"));
            var domains = first["verifiedDomains"] as JArray;
            if (domains != null)
            {
                foreach (var d in domains.Take(5))
                {
                    SpawnLine("Domain", d.Value<string>("name"));
                }
            }
        }
    }
}
