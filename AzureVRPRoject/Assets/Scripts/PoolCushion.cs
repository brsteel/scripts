using UnityEngine;

public class PoolCushion : MonoBehaviour
{
    [Header("Cushion Physics")]
    [Range(0.1f, 1.0f)]
    public float restitution = 0.85f; // Energy retained after bounce
    
    [Range(0.0f, 0.5f)]
    public float friction = 0.15f; // Friction with the cushion
    
    [Header("Audio")]
    public AudioClip cushionHitSound;
    private AudioSource audioSource;
    
    void Start()
    {
        // Set up audio
        audioSource = GetComponent<AudioSource>();
        if (audioSource == null)
        {
            audioSource = gameObject.AddComponent<AudioSource>();
        }
        
        audioSource.spatialBlend = 1.0f; // 3D sound
        audioSource.volume = 0.4f;
    }
    
    void OnCollisionEnter(Collision collision)
    {
        PoolBall ball = collision.gameObject.GetComponent<PoolBall>();
        if (ball != null)
        {
            ApplyCushionPhysics(collision, ball);
            PlayCushionSound(collision.impulse.magnitude);
        }
    }
    
    void ApplyCushionPhysics(Collision collision, PoolBall ball)
    {
        ContactPoint contact = collision.contacts[0];
        Vector3 normal = contact.normal;
        
        Rigidbody ballRb = ball.GetComponent<Rigidbody>();
        Vector3 velocity = ballRb.linearVelocity;
        
        // Calculate reflection
        Vector3 reflectedVelocity = Vector3.Reflect(velocity, normal);
        
        // Apply energy loss
        reflectedVelocity *= restitution;
        
        // Apply friction (reduce velocity parallel to cushion)
        Vector3 parallelComponent = velocity - Vector3.Dot(velocity, normal) * normal;
        Vector3 frictionForce = -parallelComponent * friction;
        
        // Set new velocity
        ballRb.linearVelocity = reflectedVelocity + frictionForce;
        
        // Add slight random variation for realism
        Vector3 randomVariation = new Vector3(
            Random.Range(-0.1f, 0.1f),
            0f,
            Random.Range(-0.1f, 0.1f)
        ) * 0.05f;
        
        ballRb.linearVelocity += randomVariation;
        
        // Ensure ball doesn't stick to cushion
        Vector3 separation = contact.point + normal * (ball.transform.localScale.x * 0.5f + 0.01f);
        ball.transform.position = separation;
    }
    
    void PlayCushionSound(float impactForce)
    {
        if (cushionHitSound != null && impactForce > 0.1f)
        {
            float volume = Mathf.Clamp(impactForce * 0.2f, 0.1f, 0.8f);
            audioSource.PlayOneShot(cushionHitSound, volume);
        }
    }
}
