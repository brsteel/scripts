using UnityEngine;

public class PoolBall : MonoBehaviour
{
    private Rigidbody rb;
    private PoolTable poolTable;
    private bool isMoving = false;
    private float stopThreshold = 0.01f;
    
    [Header("Ball Properties")]
    public int ballNumber = 0;
    public bool isCueBall = false;
    
    [Header("Audio")]
    public AudioClip rollSound;
    private AudioSource audioSource;
    private bool isPlayingRollSound = false;
    
    void Start()
    {
        rb = GetComponent<Rigidbody>();
        poolTable = GetComponentInParent<PoolTable>();
        
        // Set up audio
        audioSource = GetComponent<AudioSource>();
        if (audioSource == null)
        {
            audioSource = gameObject.AddComponent<AudioSource>();
        }
        
        audioSource.spatialBlend = 1.0f; // 3D sound
        audioSource.volume = 0.2f;
        audioSource.loop = true;
        
        // Determine if this is the cue ball
        isCueBall = (ballNumber == 0 || gameObject.name.Contains("Cue"));
    }
    
    void Update()
    {
        CheckMovement();
        HandleRollingSound();
    }
    
    void CheckMovement()
    {
        bool wasMoving = isMoving;
        isMoving = rb.velocity.magnitude > stopThreshold;
        
        // If ball just stopped moving
        if (wasMoving && !isMoving)
        {
            OnBallStopped();
        }
    }
    
    void HandleRollingSound()
    {
        if (isMoving && rb.velocity.magnitude > 0.1f)
        {
            if (!isPlayingRollSound && rollSound != null)
            {
                audioSource.clip = rollSound;
                audioSource.Play();
                isPlayingRollSound = true;
            }
            
            // Adjust volume based on speed
            if (audioSource.isPlaying)
            {
                audioSource.volume = Mathf.Clamp(rb.velocity.magnitude * 0.1f, 0.05f, 0.3f);
            }
        }
        else
        {
            if (isPlayingRollSound)
            {
                audioSource.Stop();
                isPlayingRollSound = false;
            }
        }
    }
    
    void OnCollisionEnter(Collision collision)
    {
        // Play hit sound when balls collide
        if (collision.gameObject.CompareTag("Ball") || collision.gameObject.GetComponent<PoolBall>())
        {
            float impactForce = collision.impulse.magnitude;
            if (impactForce > 0.1f && poolTable != null)
            {
                poolTable.PlayBallHitSound();
            }
        }
        
        // Handle cushion collision
        if (collision.gameObject.GetComponent<PoolCushion>())
        {
            HandleCushionCollision(collision);
        }
    }
    
    void HandleCushionCollision(Collision collision)
    {
        // Apply realistic cushion physics
        Vector3 normal = collision.contacts[0].normal;
        Vector3 velocity = rb.velocity;
        
        // Reduce velocity slightly to simulate energy loss
        rb.velocity = velocity * 0.95f;
        
        if (poolTable != null)
        {
            poolTable.PlayBallHitSound();
        }
    }
    
    void OnBallStopped()
    {
        // Round position to prevent floating point errors
        Vector3 pos = transform.position;
        pos.x = Mathf.Round(pos.x * 1000f) / 1000f;
        pos.z = Mathf.Round(pos.z * 1000f) / 1000f;
        transform.position = pos;
        
        // Ensure ball is completely stopped
        rb.velocity = Vector3.zero;
        rb.angularVelocity = Vector3.zero;
    }
    
    public void ApplyForce(Vector3 force, Vector3 position)
    {
        rb.AddForceAtPosition(force, position, ForceMode.Impulse);
    }
    
    public void ApplyForce(Vector3 force)
    {
        rb.AddForce(force, ForceMode.Impulse);
    }
    
    public bool IsMoving()
    {
        return isMoving;
    }
    
    public Vector3 GetVelocity()
    {
        return rb.velocity;
    }
    
    public void SetPosition(Vector3 position)
    {
        rb.velocity = Vector3.zero;
        rb.angularVelocity = Vector3.zero;
        transform.position = position;
    }
}
