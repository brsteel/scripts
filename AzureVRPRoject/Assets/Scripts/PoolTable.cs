using UnityEngine;

using UnityEngine.XR.Interaction.Toolkit.Interactables;
using System.Collections.Generic;

public class PoolTable : MonoBehaviour
{
    [Header("Table Dimensions")]
    public float tableWidth = 2.54f;        // Standard 9ft table width in meters
    public float tableLength = 1.27f;       // Standard 9ft table length in meters
    public float tableHeight = 0.8f;        // Standard table height
    public float railHeight = 0.05f;        // Height of the rails
    public float cushionHeight = 0.03f;     // Height of cushions above surface
    
    [Header("Physics Materials")]
    public PhysicsMaterial ballPhysicsMaterial;
    public PhysicsMaterial tablePhysicsMaterial;
    public PhysicsMaterial cushionPhysicsMaterial;
    
    [Header("Ball Settings")]
    public GameObject ballPrefab;
    public float ballRadius = 0.028575f;    // Standard pool ball radius (57.15mm)
    public Material[] ballMaterials;        // Materials for different colored balls
    
    [Header("Cue Settings")]
    public GameObject cueSticPrefab;
    
    [Header("Pockets")]
    public float pocketRadius = 0.065f;     // Standard pocket radius
    public GameObject pocketPrefab;
    
    [Header("Audio")]
    public AudioClip ballHitSound;
    public AudioClip pocketSound;
    public AudioSource audioSource;
    
    private List<GameObject> poolBalls = new List<GameObject>();
    private List<PoolPocket> pockets = new List<PoolPocket>();
    private GameObject cueStick;
    private GameObject cueBall;
    
    // Standard ball colors for 8-ball pool
    private Color[] ballColors = {
        Color.white,           // Cue ball
        Color.yellow,          // 1-ball
        Color.blue,            // 2-ball  
        Color.red,             // 3-ball
        new Color(0.5f, 0f, 0.5f), // 4-ball (purple)
        new Color(1f, 0.5f, 0f),   // 5-ball (orange)
        Color.green,           // 6-ball
        new Color(0.5f, 0.25f, 0f), // 7-ball (maroon)
        Color.black,           // 8-ball
        new Color(1f, 1f, 0.5f),   // 9-ball (yellow stripe)
        Color.blue,            // 10-ball (blue stripe)
        Color.red,             // 11-ball (red stripe)  
        new Color(0.5f, 0f, 0.5f), // 12-ball (purple stripe)
        new Color(1f, 0.5f, 0f),   // 13-ball (orange stripe)
        Color.green,           // 14-ball (green stripe)
        new Color(0.5f, 0.25f, 0f) // 15-ball (maroon stripe)
    };
    
    void Start()
    {
        BuildPoolTable();
        CreatePhysicsMaterials();
        SetupPockets();
        SetupBalls();
        CreateCueStick();
        SetupAudio();
    }
    
    void BuildPoolTable()
    {
        // Create table surface
        GameObject tableSurface = GameObject.CreatePrimitive(PrimitiveType.Cube);
        tableSurface.transform.parent = transform;
        tableSurface.transform.localPosition = Vector3.zero;
        tableSurface.transform.localScale = new Vector3(tableWidth, 0.05f, tableLength);
        tableSurface.name = "TableSurface";
        
        // Set table material (green felt)
        Renderer surfaceRenderer = tableSurface.GetComponent<Renderer>();
        Material tableFelt = CreateTableFeltMaterial();
        surfaceRenderer.material = tableFelt;
        
        // Apply physics material
        Collider surfaceCollider = tableSurface.GetComponent<Collider>();
        if (tablePhysicsMaterial != null)
            surfaceCollider.material = tablePhysicsMaterial;
        
        // Create rails and cushions
        CreateRailsAndCushions();
        
        // Create table legs
        CreateTableLegs();
        
        // Create table base
        CreateTableBase();
    }
    
    void CreateRailsAndCushions()
    {
        // Long rails (left and right sides)
        for (int i = 0; i < 2; i++)
        {
            CreateRail(i == 0 ? "Left" : "Right", 
                      new Vector3((i == 0 ? -1 : 1) * (tableWidth/2 + 0.025f), railHeight/2 + 0.025f, 0),
                      new Vector3(0.05f, railHeight, tableLength - pocketRadius * 2));
            
            CreateCushion(i == 0 ? "Left" : "Right",
                         new Vector3((i == 0 ? -1 : 1) * (tableWidth/2 - 0.01f), cushionHeight/2 + 0.025f, 0),
                         new Vector3(0.02f, cushionHeight, tableLength - pocketRadius * 2));
        }
        
        // Short rails (head and foot)
        for (int i = 0; i < 2; i++)
        {
            CreateRail(i == 0 ? "Head" : "Foot",
                      new Vector3(0, railHeight/2 + 0.025f, (i == 0 ? -1 : 1) * (tableLength/2 + 0.025f)),
                      new Vector3(tableWidth - pocketRadius * 2, railHeight, 0.05f));
            
            CreateCushion(i == 0 ? "Head" : "Foot",
                         new Vector3(0, cushionHeight/2 + 0.025f, (i == 0 ? -1 : 1) * (tableLength/2 - 0.01f)),
                         new Vector3(tableWidth - pocketRadius * 2, cushionHeight, 0.02f));
        }
    }
    
    void CreateRail(string name, Vector3 position, Vector3 scale)
    {
        GameObject rail = GameObject.CreatePrimitive(PrimitiveType.Cube);
        rail.transform.parent = transform;
        rail.name = $"Rail_{name}";
        rail.transform.localPosition = position;
        rail.transform.localScale = scale;
        
        // Set rail material (dark wood)
        Renderer railRenderer = rail.GetComponent<Renderer>();
        Material railMaterial = CreateWoodMaterial();
        railRenderer.material = railMaterial;
    }
    
    void CreateCushion(string name, Vector3 position, Vector3 scale)
    {
        GameObject cushion = GameObject.CreatePrimitive(PrimitiveType.Cube);
        cushion.transform.parent = transform;
        cushion.name = $"Cushion_{name}";
        cushion.transform.localPosition = position;
        cushion.transform.localScale = scale;
        
        // Set cushion material (rubber)
        Renderer cushionRenderer = cushion.GetComponent<Renderer>();
        Material cushionMaterial = CreateCushionMaterial();
        cushionRenderer.material = cushionMaterial;
        
        // Apply bouncy physics material
        Collider cushionCollider = cushion.GetComponent<Collider>();
        if (cushionPhysicsMaterial != null)
            cushionCollider.material = cushionPhysicsMaterial;
        
        // Add cushion script for realistic ball bouncing
        cushion.AddComponent<PoolCushion>();
    }
    
    void CreateTableLegs()
    {
        Vector3[] legPositions = {
            new Vector3(-tableWidth/2 + 0.1f, -tableHeight/2, -tableLength/2 + 0.1f),
            new Vector3(tableWidth/2 - 0.1f, -tableHeight/2, -tableLength/2 + 0.1f),
            new Vector3(-tableWidth/2 + 0.1f, -tableHeight/2, tableLength/2 - 0.1f),
            new Vector3(tableWidth/2 - 0.1f, -tableHeight/2, tableLength/2 - 0.1f)
        };
        
        for (int i = 0; i < legPositions.Length; i++)
        {
            GameObject leg = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            leg.transform.parent = transform;
            leg.name = $"TableLeg_{i + 1}";
            leg.transform.localPosition = legPositions[i];
            leg.transform.localScale = new Vector3(0.08f, tableHeight, 0.08f);
            
            Renderer legRenderer = leg.GetComponent<Renderer>();
            Material legMaterial = CreateWoodMaterial();
            legRenderer.material = legMaterial;
        }
    }
    
    void CreateTableBase()
    {
        GameObject tableBase = GameObject.CreatePrimitive(PrimitiveType.Cube);
        tableBase.transform.parent = transform;
        tableBase.name = "TableBase";
        tableBase.transform.localPosition = new Vector3(0, -tableHeight + 0.1f, 0);
        tableBase.transform.localScale = new Vector3(tableWidth - 0.2f, 0.2f, tableLength - 0.2f);
        
        Renderer baseRenderer = tableBase.GetComponent<Renderer>();
        Material baseMaterial = CreateWoodMaterial();
        baseRenderer.material = baseMaterial;
    }
    
    void SetupPockets()
    {
        // Corner pockets
        Vector3[] cornerPositions = {
            new Vector3(-tableWidth/2, 0.01f, -tableLength/2),  // Bottom left
            new Vector3(tableWidth/2, 0.01f, -tableLength/2),   // Bottom right
            new Vector3(-tableWidth/2, 0.01f, tableLength/2),   // Top left
            new Vector3(tableWidth/2, 0.01f, tableLength/2)     // Top right
        };
        
        // Side pockets (middle of long sides)
        Vector3[] sidePositions = {
            new Vector3(-tableWidth/2, 0.01f, 0),  // Left side
            new Vector3(tableWidth/2, 0.01f, 0)    // Right side
        };
        
        // Create corner pockets
        for (int i = 0; i < cornerPositions.Length; i++)
        {
            CreatePocket($"Corner_{i + 1}", cornerPositions[i]);
        }
        
        // Create side pockets
        for (int i = 0; i < sidePositions.Length; i++)
        {
            CreatePocket($"Side_{i + 1}", sidePositions[i]);
        }
    }
    
    void CreatePocket(string name, Vector3 position)
    {
        GameObject pocket = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
        pocket.transform.parent = transform;
        pocket.name = $"Pocket_{name}";
        pocket.transform.localPosition = position;
        pocket.transform.localScale = new Vector3(pocketRadius * 2, 0.1f, pocketRadius * 2);
        
        // Make pocket a trigger
        Collider pocketCollider = pocket.GetComponent<Collider>();
        pocketCollider.isTrigger = true;
        
        // Set pocket material (dark)
        Renderer pocketRenderer = pocket.GetComponent<Renderer>();
        Material pocketMaterial = new Material(Shader.Find("Standard"));
        pocketMaterial.color = Color.black;
        pocketRenderer.material = pocketMaterial;
        
        // Add pocket script
        PoolPocket pocketScript = pocket.AddComponent<PoolPocket>();
        pockets.Add(pocketScript);
    }
    
    void SetupBalls()
    {
        // Create cue ball
        cueBall = CreateBall(0, new Vector3(-tableWidth/4, ballRadius + 0.03f, 0));
        
        // Create object balls in triangle formation
        Vector3 rackPosition = new Vector3(tableWidth/4, ballRadius + 0.03f, 0);
        CreateBallRack(rackPosition);
    }
    
    GameObject CreateBall(int ballNumber, Vector3 position)
    {
        GameObject ball;
        
        if (ballPrefab != null)
        {
            ball = Instantiate(ballPrefab, transform.TransformPoint(position), Quaternion.identity);
        }
        else
        {
            ball = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            ball.transform.position = transform.TransformPoint(position);
        }
        
        ball.transform.parent = transform;
        ball.name = ballNumber == 0 ? "CueBall" : $"Ball_{ballNumber}";
        ball.transform.localScale = Vector3.one * (ballRadius * 2);
        
        // Add Rigidbody
        Rigidbody rb = ball.GetComponent<Rigidbody>();
        if (rb == null) rb = ball.AddComponent<Rigidbody>();
        
        rb.mass = 0.17f; // Standard pool ball weight in kg
        rb.linearDamping = 0.3f;
        rb.angularDamping = 0.5f;
        
        // Apply physics material
        Collider ballCollider = ball.GetComponent<Collider>();
        if (ballPhysicsMaterial != null)
            ballCollider.material = ballPhysicsMaterial;
        
        // Set ball material/color
        Renderer ballRenderer = ball.GetComponent<Renderer>();
        Material ballMaterial = new Material(Shader.Find("Standard"));
        ballMaterial.color = ballColors[ballNumber];
        ballMaterial.SetFloat("_Metallic", 0.1f);
        ballMaterial.SetFloat("_Glossiness", 0.9f);
        ballRenderer.material = ballMaterial;
        
        // Add ball script
        ball.AddComponent<PoolBall>();
        
        // Add XR Grab Interactable for VR interaction
        XRGrabInteractable grabInteractable = ball.AddComponent<XRGrabInteractable>();
        grabInteractable.movementType = XRBaseInteractable.MovementType.VelocityTracking;
        
        poolBalls.Add(ball);
        return ball;
    }
    
    void CreateBallRack(Vector3 centerPosition)
    {
        float ballDiameter = ballRadius * 2;
        float spacing = ballDiameter * 1.02f; // Slight spacing between balls
        
        // Standard 8-ball rack formation
        int[] rackOrder = { 1, 2, 3, 4, 8, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15 };
        Vector3[] rackPositions = {
            // Row 1 (front)
            new Vector3(0, 0, 0),
            // Row 2
            new Vector3(-spacing/2, 0, spacing * 0.866f),
            new Vector3(spacing/2, 0, spacing * 0.866f),
            // Row 3
            new Vector3(-spacing, 0, spacing * 1.732f),
            new Vector3(0, 0, spacing * 1.732f),
            new Vector3(spacing, 0, spacing * 1.732f),
            // Row 4
            new Vector3(-spacing * 1.5f, 0, spacing * 2.598f),
            new Vector3(-spacing/2, 0, spacing * 2.598f),
            new Vector3(spacing/2, 0, spacing * 2.598f),
            new Vector3(spacing * 1.5f, 0, spacing * 2.598f),
            // Row 5
            new Vector3(-spacing * 2, 0, spacing * 3.464f),
            new Vector3(-spacing, 0, spacing * 3.464f),
            new Vector3(0, 0, spacing * 3.464f),
            new Vector3(spacing, 0, spacing * 3.464f),
            new Vector3(spacing * 2, 0, spacing * 3.464f)
        };
        
        for (int i = 0; i < rackPositions.Length; i++)
        {
            Vector3 worldPos = centerPosition + rackPositions[i];
            CreateBall(rackOrder[i], worldPos);
        }
    }
    
    void CreateCueStick()
    {
        if (cueSticPrefab != null)
        {
            cueStick = Instantiate(cueSticPrefab, transform);
        }
        else
        {
            // Create simple cue stick
            cueStick = new GameObject("CueStick");
            cueStick.transform.parent = transform;
            
            GameObject stick = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            stick.transform.parent = cueStick.transform;
            stick.transform.localPosition = Vector3.zero;
            stick.transform.localScale = new Vector3(0.01f, 0.75f, 0.01f);
            
            // Add XR Grab Interactable
            XRGrabInteractable grabInteractable = cueStick.AddComponent<XRGrabInteractable>();
            
            // Add cue stick script
            cueStick.AddComponent<PoolCueStick>();
        }
        
        // Position cue stick
        cueStick.transform.localPosition = new Vector3(-tableWidth/2 - 0.5f, tableHeight + 0.1f, 0);
    }
    
    void CreatePhysicsMaterials()
    {
        // Create ball physics material if not assigned
        if (ballPhysicsMaterial == null)
        {
            ballPhysicsMaterial = new PhysicsMaterial("BallPhysics");
            ballPhysicsMaterial.dynamicFriction = 0.1f;
            ballPhysicsMaterial.staticFriction = 0.1f;
            ballPhysicsMaterial.bounciness = 0.8f;
            ballPhysicsMaterial.frictionCombine = PhysicsMaterialCombine.Average;
            ballPhysicsMaterial.bounceCombine = PhysicsMaterialCombine.Average;
        }
        
        // Create table physics material if not assigned
        if (tablePhysicsMaterial == null)
        {
            tablePhysicsMaterial = new PhysicsMaterial("TablePhysics");
            tablePhysicsMaterial.dynamicFriction = 0.3f;
            tablePhysicsMaterial.staticFriction = 0.3f;
            tablePhysicsMaterial.bounciness = 0.1f;
        }
        
        // Create cushion physics material if not assigned
        if (cushionPhysicsMaterial == null)
        {
            cushionPhysicsMaterial = new PhysicsMaterial("CushionPhysics");
            cushionPhysicsMaterial.dynamicFriction = 0.2f;
            cushionPhysicsMaterial.staticFriction = 0.2f;
            cushionPhysicsMaterial.bounciness = 0.9f;
        }
    }
    
    void SetupAudio()
    {
        if (audioSource == null)
        {
            audioSource = gameObject.AddComponent<AudioSource>();
        }
        
        audioSource.spatialBlend = 1.0f; // 3D sound
        audioSource.volume = 0.5f;
    }
    
    Material CreateTableFeltMaterial()
    {
        Material feltMaterial = new Material(Shader.Find("Standard"));
        feltMaterial.color = new Color(0.1f, 0.6f, 0.1f); // Pool table green
        feltMaterial.SetFloat("_Metallic", 0.0f);
        feltMaterial.SetFloat("_Glossiness", 0.2f); // Slightly rough for felt texture
        return feltMaterial;
    }
    
    Material CreateWoodMaterial()
    {
        Material woodMaterial = new Material(Shader.Find("Standard"));
        woodMaterial.color = new Color(0.4f, 0.2f, 0.1f); // Dark wood color
        woodMaterial.SetFloat("_Metallic", 0.0f);
        woodMaterial.SetFloat("_Glossiness", 0.7f);
        return woodMaterial;
    }
    
    Material CreateCushionMaterial()
    {
        Material cushionMaterial = new Material(Shader.Find("Standard"));
        cushionMaterial.color = new Color(0.2f, 0.7f, 0.2f); // Lighter green for cushions
        cushionMaterial.SetFloat("_Metallic", 0.0f);
        cushionMaterial.SetFloat("_Glossiness", 0.4f);
        return cushionMaterial;
    }
    
    public void PlayBallHitSound()
    {
        if (ballHitSound != null && audioSource != null)
        {
            audioSource.PlayOneShot(ballHitSound, 0.3f);
        }
    }
    
    public void PlayPocketSound()
    {
        if (pocketSound != null && audioSource != null)
        {
            audioSource.PlayOneShot(pocketSound, 0.8f);
        }
    }
    
    public void ResetBalls()
    {
        // Reset cue ball
        if (cueBall != null)
        {
            cueBall.transform.localPosition = new Vector3(-tableWidth/4, ballRadius + 0.03f, 0);
            Rigidbody cueBallRb = cueBall.GetComponent<Rigidbody>();
            cueBallRb.linearVelocity = Vector3.zero;
            cueBallRb.angularVelocity = Vector3.zero;
        }
        
        // Reset object balls to rack formation
        Vector3 rackPosition = new Vector3(tableWidth/4, ballRadius + 0.03f, 0);
        float ballDiameter = ballRadius * 2;
        float spacing = ballDiameter * 1.02f;
        
        Vector3[] rackPositions = {
            new Vector3(0, 0, 0),
            new Vector3(-spacing/2, 0, spacing * 0.866f),
            new Vector3(spacing/2, 0, spacing * 0.866f),
            new Vector3(-spacing, 0, spacing * 1.732f),
            new Vector3(0, 0, spacing * 1.732f),
            new Vector3(spacing, 0, spacing * 1.732f),
            new Vector3(-spacing * 1.5f, 0, spacing * 2.598f),
            new Vector3(-spacing/2, 0, spacing * 2.598f),
            new Vector3(spacing/2, 0, spacing * 2.598f),
            new Vector3(spacing * 1.5f, 0, spacing * 2.598f),
            new Vector3(-spacing * 2, 0, spacing * 3.464f),
            new Vector3(-spacing, 0, spacing * 3.464f),
            new Vector3(0, 0, spacing * 3.464f),
            new Vector3(spacing, 0, spacing * 3.464f),
            new Vector3(spacing * 2, 0, spacing * 3.464f)
        };
        
        for (int i = 1; i < poolBalls.Count && i - 1 < rackPositions.Length; i++)
        {
            GameObject ball = poolBalls[i];
            ball.transform.localPosition = rackPosition + rackPositions[i - 1];
            Rigidbody ballRb = ball.GetComponent<Rigidbody>();
            ballRb.linearVelocity = Vector3.zero;
            ballRb.angularVelocity = Vector3.zero;
        }
    }
}
