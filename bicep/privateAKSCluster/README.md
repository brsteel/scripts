# Private AKS Cluster Deployment Guide

This guide describes how to deploy a private, enclave-protected Azure Kubernetes Service (AKS) cluster using the Virtual Enclaves Infrastructure as Code (IaC) templates.

The deployment creates a **Virtual Enclave** (a protected networking boundary) and an **AKS Workload** (the compute cluster and associated resources) within that boundary.

## Overview

The solution can be deployed in two ways:
1.  **Combined Deployment**: Deploys the Enclave and the AKS Workload in a single operation. Recommended for new environments or "stamp" deployments.
2.  **Individual Deployment**: Deploys the Enclave first, followed by the AKS Workload. Recommended when the Enclave lifecycle is managed separately from the Workload (e.g., different teams or lifecycles).

All deployments are strictly **Private**. The AKS API Server is a **Private Cluster** (accessed via Private Endpoint), and all dependent resources (Key Vault, Storage Accounts, Container Registry) are accessed solely via Private Endpoints.

---

## Prerequisites

Before deploying, ensure you have the following:

1.  **Azure Subscriptions**:
    *   **Enclave Subscription**: Where the networking and governance boundary lives.
    *   **Workload Subscription**: (Optional) Where the AKS cluster resources live. Can be the same as the Enclave subscription.
2.  **Resource Provider Registration**:
    *   Ensure `Microsoft.Mission`, `Microsoft.ContainerService`, `Microsoft.KeyVault`, `Microsoft.Storage`, and `Microsoft.Network` are registered.
3.  **Deployment Identity**:
    *   Ensure you have the Object ID (Principal ID) of the user or Service Principal that will perform the deployment. This will be used in the parameter file to configure necessary access.

---

## Option 1: Combined Deployment

This method creates the Enclave and immediately provisions the AKS Workload inside it.

**Template**: `combineEnclaveAndAksCluster.bicep`

### Usage

```bash
az deployment sub create \
  --name "deploy-combined-cluster" \
  --location usgovvirginia \
  --template-file "templates/privateAKSCluster/combineEnclaveAndAksCluster.bicep" \
  --parameters "templates/privateAKSCluster/paramfiles/combined.bicepparam"
```

### Sample Parameter File (`combined.bicepparam`)

```bicep
using '../combineEnclaveAndAksCluster.bicep'

// --------------------------------------------------------------------------------
// ENCLAVE CONFIGURATION
// --------------------------------------------------------------------------------
// NEW RESOURCE GROUP: The name of the resource group to create for the Enclave
param aveResourceGroupName = 'rg-aks-enclave-demo'
param location = 'usgovvirginia'
param enclaveName = 'enclave-aks-demo'

// EXISTING COMMUNITY: The Resource ID of the Mission Community to join
param communityResourceId = '/subscriptions/<sub-id>/resourceGroups/<rg-name>/providers/Microsoft.Mission/communities/<community-name>'
// Must fit strictly within the Community Address Space
param customCidrRange = '10.20.0.0/20'

// SUBNETS
// Critical: You must define the subnets that AKS Node Pools and Private Endpoints will use.
param subnetDefinitions = [
  {
    name: 'aks-system'
    networkPrefixSize: 24
  }
  {
    name: 'aks-user'
    networkPrefixSize: 24
  }
  {
    name: 'aks-pods' // Optional: Sample for Azure CNI Pod Subnet integration
    networkPrefixSize: 24
  }
  {
    name: 'privateEndpoints' // Recommended for PL services
    networkPrefixSize: 24
  }
]

// DIAGNOSTICS
// 'CommunityOnly', 'EnclaveOnly', or 'Both'
param diagnosticDestination = 'EnclaveOnly'

// IDENTITY & PERMISSIONS (Advanced Maintenance Mode)
// Add your Deploying User/SPN ID here to ensure you can perform networking tasks
param enclaveRoleAssignments = [
  {
    // Contributor Role Definition ID (b24988ac-6180-42a0-ab88-20f7382dd24c)
    // See "Finding Role Definition IDs" in the README for other roles
    roleDefinitionId: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
    principals: [
      {
        id: '<YOUR-PRINCIPAL-OBJECT-ID>'
        type: 'User' // Supported types: 'User', 'Group', 'ServicePrincipal'
      }
    ]
  }
]

// --------------------------------------------------------------------------------
// WORKLOAD CONFIGURATION
// --------------------------------------------------------------------------------
param workloadName = 'aks-cluster-01'
param targetSubscriptionId = '<workload-sub-id>'
// Required for Firewall egress path
param communityManagedResourceGroupResourceId = '/subscriptions/<sub-id>/resourceGroups/<community-firewall-rg>'

// AKS CONFIGURATION
// Supported Overlays: 'flatLegacy', 'azureCniPodSubnet', 'azureCniOverlay'
// 'azureCniOverlay' automatically sets networkPluginMode='overlay' and podCidr='10.244.0.0/16'
param aksNetworkOverlay = 'azureCniOverlay'

// KEY VAULT & STORAGE CONFIGURATION
// Ensure these match a subnet defined in subnetDefinitions
param keyVaultDefinition = {
  privateEndpointSubnetName: 'privateEndpoints'
}
param storageDefinition = {
  privateEndpointSubnetName: 'privateEndpoints'
}

param aksDefinition = {
  skuTier: 'Standard'
  // Optional: Override default Pod CIDR (10.244.0.0/16) when using Overlay
  // podCidr: '192.168.0.0/16'
  // 'outboundType' defaults to userDefinedRouting. Explicitly set to 'loadBalancer' if desired.
  outboundType: 'userDefinedRouting'
  // Optional: Enable Istio Service Mesh
  /*
  serviceMeshProfile: {
    mode: 'Istio'
    istio: {
      components: {
        ingressGateways: [
          {
            enabled: true
            mode: 'External'
          }
        ]
      }
    }
  }
  */
  // Define Node Pools mapping to Enclave Subnets
  nodePools: [
    {
      name: 'systempool'
      mode: 'System'
      count: 3
      vmSize: 'Standard_D4s_v5'
      subnetName: 'aks-system'
    }
    {
      name: 'userpool'
      mode: 'User'
      count: 3
      vmSize: 'Standard_D4s_v5'
      subnetName: 'aks-user'
    }
  ]
}

param tags = {
  environment: 'production'
  owner: 'platform-team'
}
```

---

## Option 2: Individual Deployment

This method separates the infrastructure (Enclave) from the application platform (Workload).

### Step 1: Deploy the Enclave

**Template**: `aksEnclave.bicep`

This creates the boundary, virtual network, and governance policies.

```bash
az deployment sub create \
  --name "deploy-enclave" \
  --location usgovvirginia \
  --template-file "templates/privateAKSCluster/aksEnclave.bicep" \
  --parameters "paramfiles/enclave.bicepparam"
```

#### Sample Parameter File (`enclave.bicepparam`)

```bicep
using '../templates/privateAKSCluster/aksEnclave.bicep'

param aveResourceGroupName = 'rg-enclave-001'
param location = 'usgovvirginia'
param enclaveName = 'enclave-demo-01'
param communityResourceId = '/subscriptions/<sub-id>/resourceGroups/<rg-name>/providers/Microsoft.Mission/communities/<community-name>'
param customCidrRange = '10.20.0.0/20'

// SUBNETS
// Define subnets for AKS Node Pools and Private Endpoints
param subnetDefinitions = [
  {
    name: 'aks-system'
    networkPrefixSize: 24
  }
  {
    name: 'aks-user'
    networkPrefixSize: 24
  }
  {
    name: 'privateEndpoints'
    networkPrefixSize: 26
  }
]

// Critical: Add deploying user for network permission access
param enclaveRoleAssignments = [
  {
    // Contributor Role Definition ID (b24988ac-6180-42a0-ab88-20f7382dd24c)
    // See "Finding Role Definition IDs" below for other roles
    roleDefinitionId: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
    principals: [
      {
        id: '<YOUR-PRINCIPAL-OBJECT-ID>'
        type: 'User' // Supported types: 'User', 'Group', 'ServicePrincipal'
      }
    ]
  }
]

param diagnosticDestination = 'EnclaveOnly'
```

### Step 2: Deploy the Workload

**Template**: `aksClusterWorkload.bicep`

This references the existing Enclave and deploys AKS into it.

```bash
az deployment sub create \
  --name "deploy-workload" \
  --location usgovvirginia \
  --template-file "templates/privateAKSCluster/aksClusterWorkload.bicep" \
  --parameters "paramfiles/workload.bicepparam"
```

#### Sample Parameter File (`workload.bicepparam`)

```bicep
using '../templates/privateAKSCluster/aksClusterWorkload.bicep'

param workloadName = 'aks-cluster-01'
param targetSubscriptionId = '<workload-sub-id>'

// Reference the Enclave created in Step 1
param enclaveResourceId = '/subscriptions/<sub-id>/resourceGroups/<rg-name>/providers/Microsoft.Mission/virtualEnclaves/enclave-demo-01'

// Use the same firewall community RG as the enclave
param communityManagedResourceGroupResourceId = '/subscriptions/<sub-id>/resourceGroups/<community-firewall-rg>'

// AKS CONFIGURATION
// Use 'azureCniOverlay' for simplified networking. Defaults to flatLegacy if omitted.
// This sets networkPluginMode='overlay' and podCidr='10.244.0.0/16'
param aksNetworkOverlay = 'azureCniOverlay'

// KEY VAULT & STORAGE CONFIGURATION
// 'privateDetails' allows customization of subnet names and DNS
param keyVaultDefinition = {
  privateEndpointSubnetName: 'privateEndpoints'
}
param storageDefinition = {
  privateEndpointSubnetName: 'privateEndpoints'
}

param aksDefinition = {
  skuTier: 'Standard'
  disableLocalAccounts: true
  // 'outboundType' defines egress path. Defaults to 'userDefinedRouting' (Firewall).
  // Use 'loadBalancer' for SLB egress (no firewall route table will be attached).
  outboundType: 'userDefinedRouting'
  // Optional: Override default Pod CIDR (10.244.0.0/16)
  // podCidr: '192.168.0.0/16' 
  // Optional: Enable Istio Service Mesh
  /*
  serviceMeshProfile: {
    mode: 'Istio'
    istio: {
      components: {
        ingressGateways: [
          {
            enabled: true
            mode: 'External'
          }
        ]
      }
    }
  }
  */
  // Match subnets defined in the Enclave
  nodePools: [
    {
      name: 'systempool'
      mode: 'System'
      count: 3
      subnetName: 'aks-system'
    }
  ]
}
```

---

## Advanced Networking: Custom Egress & Connectivity

For strict egress control (e.g., locking down outbound traffic to specific IPs or Service Tags), you can define custom **Enclave Endpoints** and **Connections** using the `aksUserDefinedNetworkDefinitions` parameter.

Each item in this array defines a pair:
1.  **Endpoint**: The destination definition (IPs, FQDNs, Service Tags).
2.  **Connection**: The link from specific subnets to that Endpoint.

The Bicep template automatically links the connection to the endpoint defined in the same object.

### Example: Multiple Custom Rules
This example shows how to allow traffic to a specific Geneva endpoint AND a storage service.

```bicep
param aksUserDefinedNetworkDefinitions = [
  // 1. Allow Geneva Monitoring Egress
  {
    endpoint: {
      name: 'ce-geneva-egress'
      properties: {
        ruleCollection: [
          {
            name: 'geneva-https'
            destinationType: 'IPAddress'
            destination: '20.140.147.164/30,52.181.180.148/32'
            protocols: ['TCP']
            port: '443'
          }
        ]
      }
    }
    connection: {
      name: 'ec-geneva-egress'
      subnetNames: ['aks-user', 'aks-pods'] // Apply to these subnets only
    }
  }, // <--- Comma separates definitions

  // 2. Allow Azure Storage Egress
  {
    endpoint: {
      name: 'ce-storage-usgov'
      properties: {
        ruleCollection: [
          {
            name: 'storage-https'
            destinationType: 'ServiceTag'
            destination: 'Storage.USGovVirginia'
            protocols: ['TCP']
            port: '443'
          }
        ]
      }
    }
    connection: {
      name: 'ec-storage-usgov'
      subnetNames: ['aks-pods'] // Apply only to Pods
    }
  }
]
```

---

## Technical Details

### Advanced Maintenance Mode & Identity

Virtual Enclaves operate under a "Locked Down by Default" model. Networking operations (like creating Private Endpoints for Key Vault or peering VNETs) are restricted.

To successfully deploy the AKS Workload (which creates Private Endpoints), the **Deploying Identity** must be permitted to perform these actions on the Enclave VNet.

The Bicep templates handle this configuration automatically, provided you supply the correct input:
1.  **Input**: Provide the Deploying Identity's Object ID in the `enclaveRoleAssignments` parameter (see sample `bicepparam` files above).
2.  **Automation**: The Enclave deployment uses this ID to configure the **Advanced Maintenance Mode** on the Virtual Enclave resource.
3.  **Result**: The identity is granted the necessary network permissions (e.g., `Network Contributor`) on the Enclave VNet, allowing the subsequent Workload deployment to succeed.

**Important**: If the `enclaveRoleAssignments` parameter is omitted or does not include the deploying user, the Workload deployment will likely fail with `AuthorizationFailed` errors when attempting to create Private Endpoints.

## Portal Deployment (Alternative)

If you prefer using the Azure Portal instead of the CLI, you must first **compile** the Bicep templates into a single ARM JSON file, as the Portal does not verify local module references during upload.

### 1. Compile to JSON
Run the following command locally to generate the ARM template:

```bash
# For Combined Deployment
az bicep build --file templates/privateAKSCluster/combineEnclaveAndAksCluster.bicep --outfile combined-deployment.json
```

### 2. Prepare Parameters (Recommended)

Because this template uses complex parameter objects (like `subnetDefinitions` and `aksDefinition`), manually entering them in the Portal UI can be error-prone. It is highly recommended to generate a JSON parameter file from your `.bicepparam` file.

1.  **Create your parameters file** (e.g., `main.bicepparam`):
    ```bicep
    using 'templates/privateAKSCluster/combineEnclaveAndAksCluster.bicep'

    param enclaveName = 'my-aks-enclave'
    // ... other parameters ...
    ```

2.  **Build the parameters file to JSON**:
    ```bash
    az bicep build-params --file main.bicepparam --outfile main.parameters.json
    ```

### 3. Deploy via Portal
1.  Search for **"Deploy a custom template"** in the Azure Portal search bar.
2.  Select **"Build your own template in the editor"**.
3.  Click **"Load file"** and upload the `combined-deployment.json` template file.
4.  Click **"Save"**.
5.  **Load Parameters**:
    *   Click **"Edit parameters"**.
    *   Click **"Load file"** and select your generated `main.parameters.json`.
    *   *(Alternatively, you can copy and paste the JSON content directly into the editor).*
    *   Click **"Save"**.
6.  Click **Review + create**.

### Finding Role Definition IDs

When configuring `enclaveRoleAssignments`, you need to provide the **Role Definition ID** (GUID) for the permissions you want to grant. 

*   **Contributor**: `b24988ac-6180-42a0-ab88-20f7382dd24c` (Grants full access to manage all resources)
*   **Network Contributor**: `4d97b98b-1d4f-4787-a291-c67834d212e7` (Grants access to manage networks, sufficient for subnet joins)

You can find the ID for any Azure Role using the Azure CLI:

```bash
# Find ID for "Network Contributor"
az role definition list --name "Network Contributor" --query "[0].name" -o tsv
```

Copy the output GUID and paste it into `roleDefinitionId` in your `.bicepparam` file.

### Workload Architecture & Resources

The deployment creates a **Workload Resource Group** containing the AKS cluster and its dependent infrastructure. These resources interact tightly with the **Enclave VNet** (located in the separate Enclave Resource Group).

#### 1. Deployed Resources
*   **Azure Kubernetes Service (AKS)**:
    *   **Private Cluster**: The API Server is internal and accessed via a Private Endpoint.
    *   **Node Pools**: VM Scale Sets are attached to the Enclave Subnets (`aks-system`, `aks-user`).
    *   **Overlay Networking** (If Enabled): If using `azureCniOverlay`, Pods use a private overlay CIDR (Default: `10.244.0.0/16`) and do not consume VNet IPs. This CIDR can be customized in `aksDefinition`.
*   **Supporting Infrastructure**:
    *   **Key Vault**: Stores cluster secrets (e.g., encryption keys). Accessed via Private Endpoint in the Enclave VNet.
    *   **Storage Account**: Used for cluster state/boot diagnostics. Accessed via Private Endpoint.
    *   **Log Analytics Workspace**: Stores cluster logs, metrics, and audit data.
    *   **User Assigned Identity**: Assigned to the AKS Control Plane to manage network operations.
    *   **Egress Route Table**: A Route Table (`rt-aks-egress`) is created in the **Enclave Resource Group** and attached to AKS subnets.
        *   *Note*: This contains a `0.0.0.0/0` route to the Firewall. It is strictly required because AKS is configured with `outboundType: userDefinedRouting`. If this UDR is missing during deployment, AKS provisioning will fail.
*   **Private DNS Zones**:
    *   All necessary zones (KeyVault, Storage, ACR, Monitor, etc.) are **deployed in the Workload Resource Group**.
    *   They are automatically **linked** to the Enclave VNet to ensure correct name resolution.

#### 2. Resource Interactions
*   **Enclave <-> Workload**: The Enclave provides the **Virtual Network** and **Subnets**. The Workload "plugs in" to this network using the Subnet IDs defined in the Enclave.
*   **Identity <-> Network**: The **AKS User Assigned Identity** is configured with necessary permissions on the Enclave VNet (via `enclaveRoleAssignments`), allowing it to attach nodes to subnets and manage Private Endpoints.

#### 3. DNS Zone List
The deployment automatically provisions the following Private DNS Zones in the Workload RG:
*   `privatelink.usgovcloudapi.net` (KeyVault, Storage)
*   `privatelink.azurecr.us` (Container Registry)
*   `privatelink.monitor.azure.us` (Azure Monitor)
*   `privatelink.oms.opinsights.azure.us` (Log Analytics)
*   `privatelink.ods.opinsights.azure.us` (Log Analytics Data)
*   `privatelink.agentsvc.azure.us` (Agent Service)

Ensure your Enclave VNet has the correct DNS resolution path (typically pointing to the Firewall or Azure DNS) to resolve these zones.

### Diagnostics & Observability

The template automatically configures comprehensive logging and monitoring for the AKS cluster and its dependent resources.

#### Log Analytics Workspace
A dedicated Log Analytics Workspace is created in the Workload Resource Group to store all telemetry.
*   **Default Sku**: `PerGB2018`
*   **Retention**: 30 Days
*   **Access Control**: Public Ingestion and Query are **Disabled** by default.

#### Diagnostic Settings
Diagnostic settings are automatically applied to forward logs and metrics to the Workload Log Analytics Workspace.

| Resource | Logs Enabled | Metrics Enabled |
| :--- | :--- | :--- |
| **AKS Control Plane** | `kube-apiserver`, `kube-controller-manager`, `kube-scheduler`, `cluster-autoscaler`, `kube-audit`, `kube-audit-admin` | `AllMetrics` |
| **Key Vault** | `AuditEvent` | `AllMetrics` |
| **Storage Account** | *(None)* | `Transaction`, `Capacity` |

#### Container Insights (OmsAgent)
The **Container Insights (OMSAgent)** add-on is enabled on the AKS cluster. It is configured to send container stdout/stderr logs and performance metrics to the Workload Log Analytics Workspace.

#### Configuration Options
You can customize the diagnostics behavior using the `aksDefinition` parameter:

```bicep
param aksDefinition = {
  diagnostics: {
    // 'WorkloadOnly' (Default): Ssend logs to the new Workload Workspace.
    // 'WorkloadAndEnclave': Send logs to BOTH the Workload Workspace AND the central Enclave Workspace.
    mode: 'WorkloadOnly' 
    workspace: {
      skuName: 'PerGB2018'
      retentionInDays: 30
    }
  }
}
```

### Istio Service Mesh & mTLS

To enable the **AKS Istio Add-on**, include the `serviceMeshProfile` object within your `aksDefinition` parameter. This installs Istio in **Permissive Mode** by default (allowing both plaintext and mTLS).

```bicep
param aksDefinition = {
  // ... other configuration ...
  serviceMeshProfile: {
    mode: 'Istio'
    istio: {
      components: {
        ingressGateways: [
          {
            enabled: true
            mode: 'External'
          }
        ]
      }
    }
  }
}
```

To enforce **Strict mTLS** (Zero Trust) across the mesh, you must apply a `PeerAuthentication` policy after deployment:

1.  **Connect to the Cluster**: (Requires connectivity to the private API server, e.g., via Jumpbox)
    ```bash
    az aks get-credentials --resource-group <workload-rg> --name <cluster-name>
    ```
2.  **Apply Strict Policy**:
    Create a file `strict-mtls.yaml`:
    ```yaml
    apiVersion: security.istio.io/v1beta1
    kind: PeerAuthentication
    metadata:
      name: default
      namespace: istio-system
    spec:
      mtls:
        mode: STRICT
    ```
    Apply it:
    ```bash
    kubectl apply -f strict-mtls.yaml
    ```

### Advanced Networking: Custom Community Connections

You can define additional connections to the Mission Community using the `aksUserDefinedNetworkDefinitions` parameter. This is useful for connecting to shared services or existing endpoints.

#### Creating a New Endpoint and Connection
```bicep
param aksUserDefinedNetworkDefinitions = [
  {
    endpoint: {
      name: 'ce-custom-service'
      properties: {
        ruleCollection: [
          {
            name: 'allow-service-api'
            protocols: ['TCP']
            port: '8443'
            destination: 'api.shared-service.local'
            destinationType: 'FQDN'
          }
        ]
      }
    }
    connection: {
      name: 'ec-custom-service'
      // Define which subnets can access this endpoint
      subnetNames: ['aks-user']
    }
  }
]
```

#### Connecting to an Existing Endpoint
If the Community Endpoint already exists (e.g., created by another enclave or shared infrastructure), you can reference it by ID instead of defining it.

```bicep
param aksUserDefinedNetworkDefinitions = [
  {
    endpoint: {
      // Provide the Resource ID of the EXISTING Community Endpoint
      existingResourceId: '/subscriptions/<sub-id>/resourceGroups/<rg-name>/providers/Microsoft.Mission/communities/<community>/communityEndpoints/ce-shared-db'
    }
    connection: {
      name: 'ec-connect-to-shared-db'
      subnetNames: ['aks-user']
    }
  }
]
```

---

## Parameter Reference

This table details the key parameters for `combineEnclaveAndAksCluster.bicep`.

| Parameter | Type | Required? | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `aveResourceGroupName` | string | **Yes** | - | Name of the Resource Group to create for the Enclave. |
| `enclaveName` | string | **Yes** | - | Name of the Virtual Enclave resource (e.g., `enclave-01`). |
| `workloadName` | string | **Yes** | - | Name of the Workload to create (e.g., `aks-cluster-01`). |
| `communityResourceId` | string | **Yes** | - | Resource ID of the Mission Community this enclave joins. |
| `communityManagedResourceGroupResourceId`| string | **Yes** | - | Resource ID of the Resource Group managed by the Community (contains the Firewall). |
| `customCidrRange` | string | **Yes** | - | The CIDR block for the Enclave VNet (must fit in Community space). |
| `diagnosticDestination` | string | **Yes** | - | Where to send Enclave logs: `'CommunityOnly'`, `'EnclaveOnly'`, or `'Both'`. |
| `subnetDefinitions` | array | **Yes** | - | List of subnets to create. Must include subnets for System/User nodes and Private Endpoints. |
| `allowSubnetCommunication`| bool | No | `false` | **Important**: Set to `true` to allow NSG traffic between subnets (required for basic AKS DNS/NTP function). |
| `aksNetworkOverlay` | string | No | `'flatLegacy'`| Networking mode: `'flatLegacy'`, `'azureCniPodSubnet'`, or `'azureCniOverlay'`. |
| `enableBastion` | bool | No | `false` | Deploys Azure Bastion in the Enclave VNet if set to true. |
| `targetSubscriptionId` | string | No | *(Current)* | Subscription ID for the Workload resources (defaults to deployment subscription). |
| `aksDefinition` | object | No | `{}` | Advanced overrides for AKS cluster settings (node pools, add-ons). |
| `aksUserDefinedNetworkDefinitions` | array | No | `[]` | List of custom endpoints/connections. Supports creating new or linking to existing endpoints. |
