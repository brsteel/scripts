using UnityEngine;

/// <summary>
/// Custom gravity controller that allows for variable gravity strength and direction
/// Perfect for VR environments with special gravity effects
/// </summary>
public class GravityController : MonoBehaviour
{
    [Header("Gravity Settings")]
    [SerializeField] private bool useCustomGravity = true;
    [SerializeField] private Vector3 gravityDirection = Vector3.down;
    [SerializeField] private float gravityStrength = 9.81f;
    [SerializeField] private bool affectAllRigidbodies = true;
    
    [Header("Zone Settings")]
    [SerializeField] private bool isGravityZone = false;
    [SerializeField] private Collider gravityZoneCollider;
    
    [Header("Debug")]
    [SerializeField] private bool showDebugInfo = false;
    
    private static GravityController globalInstance;
    private System.Collections.Generic.List<Rigidbody> affectedRigidbodies = new System.Collections.Generic.List<Rigidbody>();
    
    // Public properties
    public Vector3 GravityForce => gravityDirection.normalized * gravityStrength;
    public bool UseCustomGravity { get => useCustomGravity; set => useCustomGravity = value; }
    public float GravityStrength { get => gravityStrength; set => gravityStrength = value; }
    public Vector3 GravityDirection { get => gravityDirection; set => gravityDirection = value; }
    
    void Awake()
    {
        // Set as global instance if none exists and this affects all rigidbodies
        if (globalInstance == null && affectAllRigidbodies && !isGravityZone)
        {
            globalInstance = this;
        }
    }
    
    void Start()
    {
        // Disable Unity's global gravity if we're controlling it
        if (useCustomGravity && affectAllRigidbodies && !isGravityZone)
        {
            Physics.gravity = Vector3.zero;
            
            // Find all existing rigidbodies
            Rigidbody[] allRigidbodies = FindObjectsByType<Rigidbody>(FindObjectsSortMode.None);
            foreach (Rigidbody rb in allRigidbodies)
            {
                if (rb.useGravity)
                {
                    rb.useGravity = false; // Disable Unity gravity
                    affectedRigidbodies.Add(rb);
                }
            }
        }
        
        // Setup gravity zone collider
        if (isGravityZone && gravityZoneCollider == null)
        {
            gravityZoneCollider = GetComponent<Collider>();
            if (gravityZoneCollider != null)
            {
                gravityZoneCollider.isTrigger = true;
            }
        }
    }
    
    void FixedUpdate()
    {
        if (!useCustomGravity) return;
        
        // Apply gravity to all affected rigidbodies
        foreach (Rigidbody rb in affectedRigidbodies)
        {
            if (rb != null)
            {
                ApplyGravityToRigidbody(rb);
            }
        }
        
        // Clean up null references
        affectedRigidbodies.RemoveAll(rb => rb == null);
    }
    
    void ApplyGravityToRigidbody(Rigidbody rb)
    {
        Vector3 gravityForce = GravityForce * rb.mass;
        rb.AddForce(gravityForce, ForceMode.Force);
        
        if (showDebugInfo)
        {
            Debug.DrawRay(rb.position, gravityForce.normalized * 2f, Color.yellow, Time.fixedDeltaTime);
        }
    }
    
    // For gravity zones
    void OnTriggerEnter(Collider other)
    {
        if (!isGravityZone || !useCustomGravity) return;
        
        Rigidbody rb = other.GetComponent<Rigidbody>();
        if (rb != null && rb.useGravity && !affectedRigidbodies.Contains(rb))
        {
            rb.useGravity = false; // Disable Unity gravity
            affectedRigidbodies.Add(rb);
        }
    }
    
    void OnTriggerExit(Collider other)
    {
        if (!isGravityZone || !useCustomGravity) return;
        
        Rigidbody rb = other.GetComponent<Rigidbody>();
        if (rb != null && affectedRigidbodies.Contains(rb))
        {
            affectedRigidbodies.Remove(rb);
            
            // Re-enable Unity gravity if no other gravity controller is managing this rigidbody
            if (globalInstance == null || globalInstance == this)
            {
                rb.useGravity = true;
            }
        }
    }
    
    /// <summary>
    /// Add a rigidbody to be affected by this gravity controller
    /// </summary>
    public void AddRigidbody(Rigidbody rb)
    {
        if (rb != null && !affectedRigidbodies.Contains(rb))
        {
            rb.useGravity = false;
            affectedRigidbodies.Add(rb);
        }
    }
    
    /// <summary>
    /// Remove a rigidbody from this gravity controller
    /// </summary>
    public void RemoveRigidbody(Rigidbody rb)
    {
        if (rb != null && affectedRigidbodies.Contains(rb))
        {
            affectedRigidbodies.Remove(rb);
            
            // Re-enable Unity gravity if appropriate
            if (globalInstance == null || globalInstance == this)
            {
                rb.useGravity = true;
            }
        }
    }
    
    /// <summary>
    /// Set gravity to zero (weightless environment)
    /// </summary>
    public void SetZeroGravity()
    {
        gravityStrength = 0f;
    }
    
    /// <summary>
    /// Set Earth-like gravity
    /// </summary>
    public void SetEarthGravity()
    {
        gravityDirection = Vector3.down;
        gravityStrength = 9.81f;
    }
    
    /// <summary>
    /// Set Moon-like gravity
    /// </summary>
    public void SetMoonGravity()
    {
        gravityDirection = Vector3.down;
        gravityStrength = 1.62f;
    }
    
    /// <summary>
    /// Change gravity direction (useful for rotating rooms, etc.)
    /// </summary>
    public void SetGravityDirection(Vector3 newDirection)
    {
        gravityDirection = newDirection.normalized;
    }
    
    void OnDestroy()
    {
        // Restore Unity gravity if we were the global controller
        if (globalInstance == this)
        {
            Physics.gravity = new Vector3(0, -9.81f, 0);
            
            // Re-enable gravity on all affected rigidbodies
            foreach (Rigidbody rb in affectedRigidbodies)
            {
                if (rb != null)
                {
                    rb.useGravity = true;
                }
            }
            
            globalInstance = null;
        }
    }
    
    void OnDrawGizmosSelected()
    {
        if (!showDebugInfo) return;
        
        // Draw gravity direction
        Gizmos.color = Color.yellow;
        Vector3 start = transform.position;
        Vector3 end = start + (gravityDirection.normalized * 3f);
        Gizmos.DrawRay(start, gravityDirection.normalized * 3f);
        Gizmos.DrawWireSphere(end, 0.1f);
        
        // Draw gravity zone if applicable
        if (isGravityZone && gravityZoneCollider != null)
        {
            Gizmos.color = new Color(1f, 1f, 0f, 0.3f);
            Gizmos.matrix = transform.localToWorldMatrix;
            
            if (gravityZoneCollider is BoxCollider box)
            {
                Gizmos.DrawCube(box.center, box.size);
            }
            else if (gravityZoneCollider is SphereCollider sphere)
            {
                Gizmos.DrawSphere(sphere.center, sphere.radius);
            }
        }
    }
}
