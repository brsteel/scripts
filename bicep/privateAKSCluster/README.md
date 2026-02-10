# Private AKS Cluster Deployment Guide

This guide describes how to deploy a private, enclave-protected Azure Kubernetes Service (AKS) cluster using the Virtual Enclaves Infrastructure as Code (IaC) templates.

This template uses a **Clean Architecture** approach with object-based parameters to manage the complexity of Enclave configuration, Connectivity, and Workload definition.

## Architecture Overview

The solution orchestrates the deployment of:
1.  **Virtual Enclave** (Networking, Policy, and Governance boundary).
2.  **Connectivity Layer** (Community Endpoints, VNet Peering, Firewall Egress).
3.  **AKS Workload** (Private Cluster, Node Pools, Key Vault, Storage).

Both the Enclave and the Workload are deployed via `modules` managed by a single orchestrator file: `aveAksDeployment.bicep`.

---

## Deployment File

*   **Template**: `aveAksDeployment.bicep`
*   **Method**: Subscription-scoped deployment (`az deployment sub create`)

### Usage Command

```bash
az deployment sub create \
  --name "deploy-private-aks" \
  --location eastus \
  --template-file "./aveAksDeployment.bicep" \
  --parameters "./sample.bicepparam"
```

---

## Parameter File Guide

The template accepts parameters grouped into four logical objects. This makes the parameter file readable and modular.

### 1. Deployment Context

Controls *where* the deployment happens and metadata applied to all resources.

```bicep
param deploymentContext = {
  subscriptionId: '...' // Target Subscription ID
  location: 'eastus'    // Target Region
  tags: {               // Global Tags
    Project: 'PrivateAKS'
  }
}
```

### 2. Enclave Configuration (`enclaveConfiguration`)

Controls the creation (or attachment) of the Virtual Enclave.

**Scenario A: Create New Enclave**
Use this to spin up a fresh environment.

```bicep
param enclaveConfiguration = {
  resourceGroupName: 'my-enclave-rg'
  name: 'my-enclave'
  communityResourceId: '/subscriptions/.../communities/my-community'
  customCidrRange: '10.0.1.0/24'
  diagnosticDestination: 'EnclaveOnly'
  enableBastion: false
  subnetDefinitions: [
     { name: 'subnet1', addressPrefix: '10.0.1.0/28' }
  ]
}
```

**Scenario B: Use Existing Enclave**
Use this when the Enclave exists, and you just want to deploy an AKS cluster into it.
*   **Logic**: If `existingResourceId` is provided, the coding agent skips the Enclave creation module entirely.
*   **Note**: `customCidrRange` and others can be omitted in this mode.

```bicep
param enclaveConfiguration = {
  existingResourceId: '/subscriptions/.../resourceGroups/.../providers/Microsoft.Mission/virtualEnclaves/my-existing-enclave'
  resourceGroupName: 'my-enclave-rg' // Still required for referential purposes
}
```

### 3. Connectivity Configuration (`connectivityConfiguration`)
Controls how the Enclave talks regarding the Community (Outbound connectivity).

**Standard Usage (Auto-Create Endpoint)**
```bicep
param connectivityConfiguration = {
  enableAksRequiredConnectivity: true // Auto-creates required endpoint for AKS egress
  aksRequiredSourceCidrs: ''          // Optional: Restrict source CIDRs
}
```

**Bring Your Own Endpoint (Reuse)**
If you already have a Community Endpoint (e.g., created by a Platform team), you can reference it to avoid conflicts.
```bicep
param connectivityConfiguration = {
  enableAksRequiredConnectivity: true
  aksRequiredEndpointDefinition: {
    existingResourceId: '/subscriptions/.../communityEndpoints/my-existing-endpoint'
  }
}
```

**Force Specific Name (Idempotency)**
If you need to ensure the automated endpoint uses a specific name (e.g. to match a prior deployment).
```bicep
param connectivityConfiguration = {
  enableAksRequiredConnectivity: true
  aksRequiredEndpointDefinition: {
    aksCommunityEndpointName: 'ce-my-specific-name'
  }
}
```

### 4. Workload Configuration (`workloadConfiguration`)
Controls the AKS Cluster, its resource group, and dependencies.

```bicep
param workloadConfiguration = {
  name: 'my-workload'
  resourceGroupName: 'my-workload-rg'
  
  // Required: Where is the Firewall located?
  communityManagedResourceGroupResourceId: '/subscriptions/.../resourceGroups/community-managed-rg'
  
  // AKS Feature Toggles
  aksNetworkOverlay: 'flatLegacy' // or 'azureCniOverlay'
  
  // Cluster Details
  aksDefinition: {
    nodePools: [
      { name: 'agentpool', count: 3, vmSize: 'Standard_D4s_v5' }
    ]
  }

  // Optional: Centralized DNS
  // privateDnsResourceGroupId: '/subscriptions/.../resourceGroups/dns-rg'
}
```

---

## Detailed Parameter Reference

| Parameter Object | Property | Required | Description |
| :--- | :--- | :--- | :--- |
| **enclaveConfiguration** | `resourceGroupName` | Yes | Name of the Resource Group for the Enclave resource. |
| | `name` | Yes | Name of the Virtual Enclave resource. |
| | `communityResourceId` | Yes (if creating) | The Parent Community Resource ID. |
| | `existingResourceId` | No | **Idempotency Key**. If provided, creation is skipped. |
| | `customCidrRange` | Yes (if creating) | The VNet CIDR. Must fit in Community space. |
| | `subnetDefinitions` | No | Custom subnets to create in the Enclave VNet. |
| **connectivityConfiguration** | `enableAksRequiredConnectivity` | No | Defaults to `true`. Creates AKS Egress path. |
| | `aksRequiredEndpointDefinition` | No | Pass `{ existingResourceId: '...' }` to reuse an endpoint. Use `{ aksCommunityEndpointName: '...' }` to force a specific name. |
| **workloadConfiguration** | `name` | Yes | Name of the Workload (used for naming resources). |
| | `resourceGroupName` | No | Defaults to `<name>-rg`. |
| | `communityManagedResourceGroupResourceId` | **Yes** | Required to locate the Firewall IP for route tables. |
| | `aksDefinition` | No | Object for overrides (Node Pools, Version, SKU). |
| | `privateDnsResourceGroupId` | No | If set, uses Centralized Private DNS Zones. |

---

## Route Table Logic

The deployment automatically handles User Defined Routing (UDR).

*   **Location**: The Route Table (`rt-aks-egress`) is created in the **Workload Resource Group**.
*   **Ownership**: This gives the Workload Owner full permission to manage routes.
*   **Route**: A default route (`0.0.0.0/0`) is added pointing to the Firewall IP (resolved via `communityManagedResourceGroupResourceId`).

## Troubleshooting

*   **Existing Endpoint Errors**: If you get a "Resource Conflict" on the Community Endpoint, use the `existingResourceId` property in `aksRequiredEndpointDefinition`.
*   **Subnet Overlap**: Ensure `customCidrRange` does not overlap with other Enclaves in the Community.
*   **Permission Denial**: Ensure the deployment principal has `Contributor` on the Target Subscription and `Network Contributor` on the Community Resource (for Endpoint creation/linking).
