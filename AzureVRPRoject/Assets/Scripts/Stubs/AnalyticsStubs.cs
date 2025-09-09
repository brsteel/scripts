// Minimal stub to satisfy OpenXRAnalytics references when Unity Analytics module isn't included.
// If you later enable Analytics, remove this file.
namespace UnityEngine.Analytics
{
    public enum AnalyticsResult
    {
        Ok = 0,
        NotInitialized = 1,
        AnalyticsDisabled = 2,
        TooManyItems = 3,
        SizeLimitReached = 4,
        TooManyRequests = 5,
        InvalidData = 6,
        UnsupportedPlatform = 7,
        RemoteDisabled = 8,
        Unauthorized = 9,
        VersionMismatch = 10
    }
}
