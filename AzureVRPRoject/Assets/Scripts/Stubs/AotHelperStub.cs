// Stub for AotHelper used by Unity Services Core telemetry on platforms / builds where
// the real implementation might not be present. Safe to remove if the real module is linked.

namespace Unity.Services.Core.Internal
{
    public static class AotHelper
    {
        public static void EnsureType<T>() {}
        public static void EnsureType<T1, T2>() {}
        public static void EnsureType<T1, T2, T3>() {}
    }

    // Some versions nest under an AOT namespace segment; include both to be safe.
    namespace AOT
    {
        public static class AotHelper
        {
            public static void EnsureType<T>() {}
            public static void EnsureType<T1, T2>() {}
            public static void EnsureType<T1, T2, T3>() {}
        }
    }
}

// Global fallback if package code references AotHelper without namespace qualification.
public static class AotHelper
{
    public static void EnsureType<T>() {}
    public static void EnsureType<T1, T2>() {}
    public static void EnsureType<T1, T2, T3>() {}
}


