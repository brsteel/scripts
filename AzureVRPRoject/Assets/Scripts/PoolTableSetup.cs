using UnityEngine;

public class PoolTableSetup : MonoBehaviour
{
    [Header("Setup Options")]
    public bool createOnStart = true;
    public Vector3 tablePosition = Vector3.zero;
    public Vector3 tableRotation = Vector3.zero;
    
    [Header("Prefab References (Optional)")]
    public GameObject poolTablePrefab;
    public GameObject ballPrefab;
    public GameObject cueSticPrefab;
    
    void Start()
    {
        if (createOnStart)
        {
            CreatePoolTable();
        }
    }
    
    [ContextMenu("Create Pool Table")]
    public void CreatePoolTable()
    {
        GameObject poolTableObj;
        
        if (poolTablePrefab != null)
        {
            poolTableObj = Instantiate(poolTablePrefab, tablePosition, Quaternion.Euler(tableRotation));
        }
        else
        {
            // Create empty GameObject and add PoolTable component
            poolTableObj = new GameObject("PoolTable");
            poolTableObj.transform.position = tablePosition;
            poolTableObj.transform.rotation = Quaternion.Euler(tableRotation);
            
            PoolTable poolTable = poolTableObj.AddComponent<PoolTable>();
            
            // Assign prefabs if available
            if (ballPrefab != null)
                poolTable.ballPrefab = ballPrefab;
            if (cueSticPrefab != null)
                poolTable.cueSticPrefab = cueSticPrefab;
        }
        
        Debug.Log("Pool table created!");
    }
    
    [ContextMenu("Delete Pool Table")]
    public void DeletePoolTable()
    {
        PoolTable existingTable = FindObjectOfType<PoolTable>();
        if (existingTable != null)
        {
            if (Application.isPlaying)
                Destroy(existingTable.gameObject);
            else
                DestroyImmediate(existingTable.gameObject);
            
            Debug.Log("Pool table deleted!");
        }
    }
}
