using UnityEngine;

public class PoolPocket : MonoBehaviour
{
    private PoolTable poolTable;
    
    [Header("Pocket Settings")]
    public string pocketName;
    public bool isCornerPocket = true;
    
    void Start()
    {
        poolTable = GetComponentInParent<PoolTable>();
        
        // Set pocket name based on position if not set
        if (string.IsNullOrEmpty(pocketName))
        {
            pocketName = gameObject.name;
        }
    }
    
    void OnTriggerEnter(Collider other)
    {
        PoolBall ball = other.GetComponent<PoolBall>();
        if (ball != null)
        {
            PocketBall(ball);
        }
    }
    
    void PocketBall(PoolBall ball)
    {
        Debug.Log($"Ball {ball.ballNumber} pocketed in {pocketName}");
        
        // Play pocket sound
        if (poolTable != null)
        {
            poolTable.PlayPocketSound();
        }
        
        // Stop ball movement
        Rigidbody ballRb = ball.GetComponent<Rigidbody>();
        if (ballRb != null)
        {
            ballRb.linearVelocity = Vector3.zero;
            ballRb.angularVelocity = Vector3.zero;
            ballRb.useGravity = false;
        }
        
        // Move ball below table (simulate falling into pocket)
        StartCoroutine(AnimateBallIntoPocket(ball));
    }
    
    System.Collections.IEnumerator AnimateBallIntoPocket(PoolBall ball)
    {
        Vector3 startPos = ball.transform.position;
        Vector3 endPos = transform.position - Vector3.up * 0.5f;
        
        float animationTime = 0.5f;
        float elapsed = 0f;
        
        while (elapsed < animationTime)
        {
            elapsed += Time.deltaTime;
            float t = elapsed / animationTime;
            
            // Ease in animation
            t = t * t * (3f - 2f * t);
            
            ball.transform.position = Vector3.Lerp(startPos, endPos, t);
            yield return null;
        }
        
        // Handle different ball types
        HandleBallPocketed(ball);
    }
    
    void HandleBallPocketed(PoolBall ball)
    {
        if (ball.isCueBall)
        {
            // Cue ball pocketed - scratch
            Debug.Log("Scratch! Cue ball pocketed.");
            StartCoroutine(RespawnCueBall(ball));
        }
        else if (ball.ballNumber == 8)
        {
            // 8-ball pocketed
            Debug.Log("8-ball pocketed!");
            Handle8BallPocketed();
        }
        else
        {
            // Regular object ball pocketed
            Debug.Log($"Ball {ball.ballNumber} pocketed successfully.");
            DisableBall(ball);
        }
    }
    
    System.Collections.IEnumerator RespawnCueBall(PoolBall cueBall)
    {
        yield return new WaitForSeconds(1f);
        
        // Find a good respawn position (behind head string)
        Vector3 respawnPos = new Vector3(-1f, 0.1f, 0f);
        
        // Make sure position is clear
        Collider[] nearbyObjects = Physics.OverlapSphere(respawnPos, 0.1f);
        bool positionClear = true;
        
        foreach (Collider col in nearbyObjects)
        {
            if (col.GetComponent<PoolBall>())
            {
                positionClear = false;
                break;
            }
        }
        
        if (!positionClear)
        {
            // Find alternative position
            for (float x = -1f; x < 1f; x += 0.1f)
            {
                Vector3 testPos = new Vector3(x, 0.1f, 0f);
                Collider[] testObjects = Physics.OverlapSphere(testPos, 0.1f);
                bool testClear = true;
                
                foreach (Collider col in testObjects)
                {
                    if (col.GetComponent<PoolBall>())
                    {
                        testClear = false;
                        break;
                    }
                }
                
                if (testClear)
                {
                    respawnPos = testPos;
                    break;
                }
            }
        }
        
        // Respawn cue ball
        cueBall.SetPosition(poolTable.transform.TransformPoint(respawnPos));
        
        Rigidbody cueBallRb = cueBall.GetComponent<Rigidbody>();
        cueBallRb.useGravity = true;
        
        // Re-enable ball
        cueBall.gameObject.SetActive(true);
        
        Debug.Log("Cue ball respawned.");
    }
    
    void Handle8BallPocketed()
    {
        // This would typically end the game
        // For now, just reset the table
        Debug.Log("Game Over! 8-ball pocketed.");
        
        if (poolTable != null)
        {
            StartCoroutine(ResetTableAfterDelay());
        }
    }
    
    System.Collections.IEnumerator ResetTableAfterDelay()
    {
        yield return new WaitForSeconds(2f);
        poolTable.ResetBalls();
    }
    
    void DisableBall(PoolBall ball)
    {
        // Move ball to storage area or disable it
        ball.gameObject.SetActive(false);
        
        // Or move to side rail for display
        Vector3 storagePos = new Vector3(2f, 0.1f, UnityEngine.Random.Range(-1f, 1f));
        ball.transform.position = poolTable.transform.TransformPoint(storagePos);
    }
}
