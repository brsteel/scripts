using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Linq; // For FirstOrDefault
using Microsoft.Identity.Client;
using UnityEngine;

namespace AzureVR.Auth
{
    public class AuthManager : MonoBehaviour
    {
        [Header("Azure AD App Registration")] public string ClientId;
        [Tooltip("Leave blank to use common. For single-tenant, set to your directory (tenant) ID.")] public string TenantId = "common";
        [Tooltip("Optional redirect URI (should match app registration). For device code flow not required.")] public string RedirectUri = string.Empty;

        // Basic Microsoft Graph scope for organization read
        private readonly string[] _scopes = { "https://graph.microsoft.com/.default" };

        private IPublicClientApplication _pca;
        private AuthenticationResult _authResult;

        public bool IsAuthenticated => _authResult != null;
        public string AccessToken => _authResult?.AccessToken;

        private void Awake()
        {
            if (string.IsNullOrWhiteSpace(ClientId))
            {
                Debug.LogError("AuthManager: ClientId is not set.");
                enabled = false;
                return;
            }

            var builder = PublicClientApplicationBuilder.Create(ClientId)
                .WithAuthority(AzureCloudInstance.AzurePublic, TenantId);

            if (!string.IsNullOrWhiteSpace(RedirectUri))
            {
                builder = builder.WithRedirectUri(RedirectUri);
            }

            _pca = builder.Build();
        }

        public async Task<bool> SignInDeviceCodeAsync()
        {
            try
            {
                var accounts = await _pca.GetAccountsAsync();
                try
                {
                    _authResult = await _pca.AcquireTokenSilent(_scopes, accounts.FirstOrDefault()).ExecuteAsync();
                    Debug.Log("AuthManager: Silent token acquisition succeeded.");
                    return true;
                }
                catch (MsalUiRequiredException)
                {
                    // Fall back to device code
                }

                _authResult = await _pca.AcquireTokenWithDeviceCode(_scopes, callback =>
                {
                    Debug.Log($"Device code: {callback.UserCode}. Go to {callback.VerificationUrl} and enter the code.");
                    return Task.CompletedTask;
                }).ExecuteAsync();

                Debug.Log("AuthManager: Device code flow succeeded.");
                return true;
            }
            catch (Exception ex)
            {
                Debug.LogError($"AuthManager: Sign-in failed: {ex}");
                return false;
            }
        }

        public async Task SignOutAsync()
        {
            var accounts = await _pca.GetAccountsAsync();
            foreach (var acct in accounts)
            {
                await _pca.RemoveAsync(acct);
            }
            _authResult = null;
            Debug.Log("AuthManager: Signed out.");
        }
    }
}
