using UnityEngine;
using UnityEngine.XR.Interaction.Toolkit;

public class PoolCueStick : XRGrabInteractable
{
    [Header("Cue Stick Settings")]
    public float maxPower = 20f;
    public float powerMultiplier = 1f;
    public LineRenderer aimingLine;
    public Transform tipTransform;
    
    [Header("Aiming")]
    public LayerMask ballLayerMask = 1;
    public float maxAimDistance = 5f;
    public int linePoints = 50;
    
    [Header("Audio")]
    public AudioClip cueHitSound;
    private AudioSource audioSource;
    
    private bool isAiming = false;
    private bool isReadyToShoot = false;
    private GameObject targetBall;
    private Vector3 startGrabPosition;
    private Vector3 pullBackDistance;
    private float shotPower = 0f;
    
    protected override void Awake()
    {
        base.Awake();
        
        // Set up audio
        audioSource = GetComponent<AudioSource>();
        if (audioSource == null)
        {
            audioSource = gameObject.AddComponent<AudioSource>();
        }
        
        audioSource.spatialBlend = 1.0f; // 3D sound
        audioSource.volume = 0.6f;
        
        // Set up aiming line if not assigned
        if (aimingLine == null)
        {
            GameObject lineObj = new GameObject("AimingLine");
            lineObj.transform.parent = transform;
            aimingLine = lineObj.AddComponent<LineRenderer>();
            SetupAimingLine();
        }
        
        // Set up tip transform if not assigned
        if (tipTransform == null)
        {
            GameObject tip = new GameObject("CueTip");
            tip.transform.parent = transform;
            tip.transform.localPosition = new Vector3(0, 0.75f, 0); // Tip of the cue
            tipTransform = tip.transform;
        }
        
        aimingLine.enabled = false;
    }
    
    void SetupAimingLine()
    {
        aimingLine.material = new Material(Shader.Find("Sprites/Default"));
        aimingLine.color = Color.white;
        aimingLine.startWidth = 0.005f;
        aimingLine.endWidth = 0.005f;
        aimingLine.positionCount = linePoints;
        aimingLine.useWorldSpace = true;
    }
    
    protected override void OnSelectEntered(SelectEnterEventArgs args)
    {
        base.OnSelectEntered(args);
        startGrabPosition = transform.position;
        isAiming = true;
        aimingLine.enabled = true;
    }
    
    protected override void OnSelectExited(SelectExitEventArgs args)
    {
        base.OnSelectExited(args);
        
        if (isReadyToShoot && targetBall != null)
        {
            ShootCue();
        }
        
        isAiming = false;
        isReadyToShoot = false;
        aimingLine.enabled = false;
        shotPower = 0f;
    }
    
    void Update()
    {
        if (isAiming)
        {
            UpdateAiming();
            CheckForShot();
        }
    }
    
    void UpdateAiming()
    {
        // Find the nearest ball (preferably cue ball)
        FindTargetBall();
        
        if (targetBall != null)
        {
            UpdateAimingLine();
            CalculateShootPower();
        }
    }
    
    void FindTargetBall()
    {
        // First try to find cue ball
        GameObject cueBall = GameObject.Find("CueBall");
        if (cueBall != null)
        {
            float distance = Vector3.Distance(tipTransform.position, cueBall.transform.position);
            if (distance <= maxAimDistance)
            {
                targetBall = cueBall;
                return;
            }
        }
        
        // If no cue ball in range, find nearest ball
        PoolBall[] allBalls = FindObjectsOfType<PoolBall>();
        float nearestDistance = maxAimDistance;
        GameObject nearestBall = null;
        
        foreach (PoolBall ball in allBalls)
        {
            float distance = Vector3.Distance(tipTransform.position, ball.transform.position);
            if (distance < nearestDistance)
            {
                nearestDistance = distance;
                nearestBall = ball.gameObject;
            }
        }
        
        targetBall = nearestBall;
    }
    
    void UpdateAimingLine()
    {
        if (targetBall == null) return;
        
        Vector3 startPos = tipTransform.position;
        Vector3 ballPos = targetBall.transform.position;
        Vector3 direction = (ballPos - startPos).normalized;
        
        // Create trajectory prediction
        Vector3[] points = new Vector3[linePoints];
        points[0] = startPos;
        
        float segmentLength = Vector3.Distance(startPos, ballPos) / (linePoints - 1);
        
        for (int i = 1; i < linePoints; i++)
        {
            Vector3 point = startPos + direction * (segmentLength * i);
            points[i] = point;
            
            // Stop at ball position
            if (Vector3.Distance(point, ballPos) < 0.1f)
            {
                points[i] = ballPos;
                
                // Fill remaining points with ball trajectory prediction
                if (i < linePoints - 1)
                {
                    PredictBallTrajectory(points, i, ballPos, direction);
                }
                break;
            }
        }
        
        aimingLine.positionCount = linePoints;
        aimingLine.SetPositions(points);
        
        // Color the line based on shot power
        Color lineColor = Color.Lerp(Color.white, Color.red, shotPower / maxPower);
        aimingLine.color = lineColor;
    }
    
    void PredictBallTrajectory(Vector3[] points, int startIndex, Vector3 ballPos, Vector3 cueDirection)
    {
        Vector3 ballDirection = cueDirection;
        Vector3 currentPos = ballPos;
        
        for (int i = startIndex + 1; i < linePoints; i++)
        {
            currentPos += ballDirection * 0.1f;
            points[i] = currentPos;
            
            // Simple collision prediction with table bounds
            PoolTable poolTable = FindObjectOfType<PoolTable>();
            if (poolTable != null)
            {
                Bounds tableBounds = new Bounds(poolTable.transform.position, 
                    new Vector3(poolTable.tableWidth, 0.1f, poolTable.tableLength));
                
                if (!tableBounds.Contains(currentPos))
                {
                    // Reflect off table edge (simplified)
                    if (Mathf.Abs(currentPos.x) > tableBounds.extents.x)
                        ballDirection.x = -ballDirection.x;
                    if (Mathf.Abs(currentPos.z) > tableBounds.extents.z)
                        ballDirection.z = -ballDirection.z;
                        
                    currentPos = tableBounds.ClosestPoint(currentPos);
                }
            }
        }
    }
    
    void CalculateShootPower()
    {
        pullBackDistance = startGrabPosition - transform.position;
        float pullBackMagnitude = pullBackDistance.magnitude;
        
        shotPower = Mathf.Clamp(pullBackMagnitude * powerMultiplier, 0f, maxPower);
        
        // Visual feedback - maybe vibration for VR controllers
        if (shotPower > maxPower * 0.8f)
        {
            // Trigger haptic feedback for high power
            if (isSelected)
            {
                // Add haptic feedback here if available
            }
        }
        
        isReadyToShoot = shotPower > 0.5f; // Minimum power threshold
    }
    
    void CheckForShot()
    {
        // Check if player is moving cue forward (shooting motion)
        if (isReadyToShoot && targetBall != null)
        {
            Vector3 currentVelocity = (transform.position - startGrabPosition) / Time.deltaTime;
            Vector3 directionToBall = (targetBall.transform.position - tipTransform.position).normalized;
            
            // Check if moving towards ball with sufficient speed
            float forwardVelocity = Vector3.Dot(currentVelocity, directionToBall);
            if (forwardVelocity > 2f) // Threshold for shooting motion
            {
                ShootCue();
            }
        }
    }
    
    void ShootCue()
    {
        if (targetBall == null) return;
        
        PoolBall ball = targetBall.GetComponent<PoolBall>();
        if (ball == null) return;
        
        Vector3 shootDirection = (targetBall.transform.position - tipTransform.position).normalized;
        Vector3 force = shootDirection * shotPower;
        
        // Apply force to the ball
        ball.ApplyForce(force, tipTransform.position);
        
        // Play cue hit sound
        if (cueHitSound != null)
        {
            float volume = Mathf.Clamp(shotPower / maxPower, 0.2f, 1f);
            audioSource.PlayOneShot(cueHitSound, volume);
        }
        
        // Visual effect - maybe particle system for chalk dust
        CreateChalkEffect();
        
        // Reset shot
        isReadyToShoot = false;
        shotPower = 0f;
        
        Debug.Log($"Shot fired! Power: {shotPower:F1}");
    }
    
    void CreateChalkEffect()
    {
        // Simple particle effect for chalk dust
        // You could enhance this with a proper particle system
        
        GameObject chalkEffect = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        chalkEffect.transform.position = tipTransform.position;
        chalkEffect.transform.localScale = Vector3.one * 0.05f;
        
        Renderer renderer = chalkEffect.GetComponent<Renderer>();
        Material chalkMat = new Material(Shader.Find("Standard"));
        chalkMat.color = new Color(0.8f, 0.8f, 1f, 0.5f);
        renderer.material = chalkMat;
        
        // Animate and destroy
        StartCoroutine(AnimateChalkEffect(chalkEffect));
    }
    
    System.Collections.IEnumerator AnimateChalkEffect(GameObject effect)
    {
        float duration = 0.5f;
        Vector3 startScale = effect.transform.localScale;
        Vector3 endScale = startScale * 3f;
        
        for (float t = 0; t < duration; t += Time.deltaTime)
        {
            float normalizedTime = t / duration;
            effect.transform.localScale = Vector3.Lerp(startScale, endScale, normalizedTime);
            
            Renderer renderer = effect.GetComponent<Renderer>();
            Color color = renderer.material.color;
            color.a = 1f - normalizedTime;
            renderer.material.color = color;
            
            yield return null;
        }
        
        Destroy(effect);
    }
}
