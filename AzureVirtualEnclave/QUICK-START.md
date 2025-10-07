# Quick Start - Simple Development Deployment

This guide shows how to deploy the simplest Azure Virtual Enclave setup for development.

## Parameter File

### `solution.bicepparam`
- Example included in repo (single community → one enclave → one or more workloads)
- Modify nested arrays to scale (add enclaves/workloads) – no scalar count parameters required

```bash
# Deploy simple development setup  
az deployment sub create \
  --location "East US 2" \
  --template-file solution.bicep \
  --parameters solution.bicepparam
```

## What Gets Deployed

### Example Topology
```
Subscription  
└── Resource Group: simple-ave-dev-rg
    └── Community: simple-ave-dev-community-0
        └── Virtual Enclave: simple-ave-dev-community-0-enclave-0
            ├── Azure Bastion (enabled)
            ├── Virtual Network: dev-vnet (10.0.0.0/24)  
            ├── Workload: dev-app
            └── Workload: dev-data
```

## Prerequisites

1. **Azure CLI** installed and logged in
2. **Azure subscription** with appropriate permissions
3. **Microsoft.Mission** resource provider registered

```bash
# Register the resource provider
az provider register --namespace Microsoft.Mission
```

## Deployment Commands

### PowerShell
```powershell
# Development deployment  
az deployment sub create `
  --location "East US 2" `
  --template-file solution.bicep `
  --parameters solution.bicepparam
```

### Bash
```bash
# Development deployment
az deployment sub create \
  --location "East US 2" \
  --template-file solution.bicep \  
  --parameters solution.bicepparam
```

## Customization Options

### Adjust Location / Network / Workload Names
Edit `solution.bicepparam` directly. Add or remove objects in `enclaveConfigs` / `workloadConfigs` arrays to scale. Example workload entry:

```bicep
{
  name: 'my-custom-app'
  resourceGroupCollection: ['rg-my-app']
}
```

## Next Steps After Deployment

1. **Verify Deployment**
   - Check Azure portal for created resources
   - Verify AVE community and enclave are running

2. **Access Resources**  
   - Use Azure Bastion for secure VM access
   - No public IPs are created on workloads

3. **Deploy Applications**
   - Add resources to the workload resource groups
   - Use the AVE service console for advanced configuration

4. **Scale Up**
  - Add objects to `communityConfigs[0].enclaveConfigs` or inside each enclave's `workloadConfigs`
  - No need to adjust separate count parameters – the arrays are authoritative

## Cleanup

To remove all resources:

```bash
# Delete the resource group (removes everything)
az group delete --name minimal-ave-rg --yes --no-wait

# Or for simple development setup
az group delete --name simple-ave-dev-rg --yes --no-wait
```

## Troubleshooting

### Common Issues

1. **Resource Provider Not Registered**
   ```bash
   az provider register --namespace Microsoft.Mission
   az provider show --namespace Microsoft.Mission --query registrationState
   ```

2. **Permission Issues**
   - Ensure you have Contributor access at subscription level
   - AVE resources require subscription-level permissions

3. **Region Availability**
   - AVE may not be available in all regions
   - Try East US 2, West US 2, or West Europe

4. **Template Errors**
   - Validate Bicep syntax: `az bicep build --file solution.bicep`
   - Check parameter file: `az deployment sub validate --template-file solution.bicep --parameters solution.bicepparam`

## Support

For questions or issues:
- Review the [Parameters Documentation](PARAMETERS.md)
- Check the [Network Planning Guide](NETWORK-PLANNING.md)  
- See [Nested Configuration Guide](NESTED-CONFIG-GUIDE.md) for advanced scenarios
