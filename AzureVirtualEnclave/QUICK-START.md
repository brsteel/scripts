# Quick Start - Simple Development Deployment

This guide shows how to deploy the simplest Azure Virtual Enclave setup for development.

## Available Parameter Files

### 1. Minimal Setup (`solution.minimal.bicepparam`)
- **1 Community** → **1 Enclave** → **1 Workload**
- Most basic possible deployment
- Perfect for learning and initial testing

```bash
# Deploy minimal setup
az deployment sub create \
  --location "East US 2" \
  --template-file solution.bicep \
  --parameters solution.minimal.bicepparam
```

### 2. Simple Development (`solution.bicepparam`)  
- **1 Community** → **1 Enclave** → **2 Workloads**
- Good for basic application development
- Includes separate app and data workloads

```bash
# Deploy simple development setup  
az deployment sub create \
  --location "East US 2" \
  --template-file solution.bicep \
  --parameters solution.bicepparam
```

## What Gets Deployed

### Minimal Setup
```
Subscription
└── Resource Group: minimal-ave-rg
    └── Community: minimal-ave-community-0
        └── Virtual Enclave: minimal-ave-community-0-enclave-0
            ├── Azure Bastion (enabled)
            ├── Virtual Network: minimal-vnet (10.0.0.0/24)
            └── Workload: minimal-workload
```

### Simple Development Setup
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
# Minimal deployment
az deployment sub create `
  --location "East US 2" `
  --template-file solution.bicep `
  --parameters solution.minimal.bicepparam

# Simple development deployment  
az deployment sub create `
  --location "East US 2" `
  --template-file solution.bicep `
  --parameters solution.bicepparam
```

### Bash
```bash
# Minimal deployment
az deployment sub create \
  --location "East US 2" \
  --template-file solution.bicep \
  --parameters solution.minimal.bicepparam

# Simple development deployment
az deployment sub create \
  --location "East US 2" \
  --template-file solution.bicep \  
  --parameters solution.bicepparam
```

## Customization Options

### Change Location
Edit the parameter file:
```bicep
param location = 'West US 2'  // Change to your preferred region
```

### Change Network Range
Edit the parameter file:
```bicep
addressSpace: '172.16.0.0/16'        // Different private IP range
customCidrRange: '172.16.0.0/24'     // Matching enclave range
```

### Change Workload Names
Edit the parameter file:
```bicep
workloadConfigs: [
  {
    name: 'my-custom-app'
    resourceGroupCollection: ['rg-my-app']
  }
]
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
   - Modify parameter files to add more enclaves or workloads
   - See [Nested Configuration Guide](NESTED-CONFIG-GUIDE.md) for complex scenarios

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