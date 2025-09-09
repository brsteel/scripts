using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using UnityEngine;
using Newtonsoft.Json.Linq;

namespace AzureVR.Graph
{
    public class GraphClient
    {
        private static readonly HttpClient _http = new HttpClient();

        public async Task<JObject> GetOrganizationAsync(string accessToken)
        {
            if (string.IsNullOrWhiteSpace(accessToken)) throw new ArgumentException("Access token missing");

            var req = new HttpRequestMessage(HttpMethod.Get, "https://graph.microsoft.com/v1.0/organization");
            req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
            var resp = await _http.SendAsync(req);
            var body = await resp.Content.ReadAsStringAsync();
            if (!resp.IsSuccessStatusCode)
            {
                Debug.LogError($"GraphClient: Failure {resp.StatusCode} {body}");
                throw new InvalidOperationException("Graph call failed");
            }
            var json = JObject.Parse(body);
            return json;
        }
    }
}
