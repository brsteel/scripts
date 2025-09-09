Attach TenantVisualizer to an empty GameObject in the scene.
Assign:
- AuthManager (on another GameObject with the AuthManager component)
- RootParent (empty transform to hold text lines)
- TextPrefab (a prefab with a TextMeshPro component)

Press Play; use provided device code to authenticate; tenant info will appear as stacked text objects.
