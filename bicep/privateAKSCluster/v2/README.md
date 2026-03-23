# Private AKS Cluster v2 - Deployment 1 (Enclave Foundation)

This directory contains the first deployment in the v2 redesign for private AKS on Azure Virtual Enclaves.

Scope for this initial run:
- Deploy or attach an AVE enclave.
- Configure AKS-required community endpoint/connection rules.
- Create an AKS control-plane user-assigned managed identity (UAI).
- Create an empty egress route table and associate it to specified enclave subnets.

Out of scope for this initial run:
- AKS workload deployment.
- AKS cluster deployment.
- End-to-end workload integration.

## Group model

Deployment 1 expects three standalone Microsoft Entra security groups:
- Enclave administrators group.
- Workload administrators group.
- Maintenance principals group.

These groups are intentionally independent. Membership in one group does not imply membership in another.

## Template

- Main template: `aveAksEnclaveDeployment.bicep`
- Sample parameters: `sample.enclave.bicepparam`
- Deployment 2 template: `aveAksWorkloadDeployment.bicep`
- Deployment 2 sample parameters: `sample.workload.bicepparam`

## Deployment command

```bash
az deployment sub create \
  --name "deploy-aks-enclave-v2" \
  --location eastus \
  --template-file "./aveAksEnclaveDeployment.bicep" \
  --parameters "./sample.enclave.bicepparam"
```

## Required inputs

- `deploymentContext`: subscription, location, tags.
- `enclaveConfiguration`: enclave details and subnet definitions.
- `connectivityConfiguration`: AKS connectivity endpoint/connection behavior.
- `aksFoundationConfiguration`: UAI, egress route table, and private DNS settings.

### Enclave configuration contract

- `enclaveRoleAssignments`
- `workloadRoleAssignments`
- `maintenanceModePrincipals`
- `maintenanceMode`: `Off` | `General` | `Advanced`
- `allowedSubnetCommunications`: optional subnet-to-subnet NSG allow rules when `allowSubnetCommunication` is `false`

Private DNS configuration (under `aksFoundationConfiguration`):
- `enablePrivateDnsZoneSetup` (default `true`)
- `privateDnsResourceGroupResourceId` (optional): resource ID of an existing Resource Group that already contains private DNS zones. Can be in another subscription.
- `privateDnsZoneNames` (optional): list of existing zone names to link when using an existing DNS resource group.

Workload RG RBAC delegation configuration (under `aksFoundationConfiguration`):
- `workloadRbacDelegation.resourceGroupName` (required)
- `workloadRbacDelegation.resourceGroupLocation` (optional, defaults to deployment location)
- `workloadRbacDelegation.roleDefinitionId` (optional, defaults to User Access Administrator)
- `workloadRbacDelegation.principals` (optional array of `{ id, type }`; defaults to enclave Contributor principals from `enclaveRoleAssignments`)

Behavior:
- Existing-zones mode is used only when both `privateDnsResourceGroupResourceId` and `privateDnsZoneNames` are provided. In this mode, the deployment links the enclave VNet to those existing zones.
- If either value is missing, the deployment assumes full control: it creates the required default private DNS zones in the enclave deployment resource group and links the enclave VNet.
- Deployment 1 always assigns the selected role (User Access Administrator by default) at the specified workload resource group scope to the selected principals (enclave Contributor principals by default).
- Deployment fails fast if `workloadRbacDelegation.resourceGroupName` is missing or if no principals can be resolved.

Rule object shape for `allowedSubnetCommunications`:
- `sourceSubnetName`
- `destinationSubnetName`
- `sourceNsgName`
- `destinationNsgName`
- `sourceSubnetPrefix` (optional override; auto-derived from `sourceSubnetName`)
- `destinationSubnetPrefix` (optional override; auto-derived from `destinationSubnetName`)
- `direction`: `inbound` | `outbound` | `both` (default `both`)
- `protocol`: default `*`
- `sourcePortRange`: default `*`
- `destinationPortRange`: default `*`
- `priority`: optional, otherwise generated from `subnetCommunicationPriorityStart`

Sample convention used in this folder:
- Subnet names: `aks-system`, `aks-user1`, `aks-user2`, `privateendpoints`
- NSG names: `<subnetName>-enclave-nsg` (for example, `aks-system-enclave-nsg`)
- Rule set: explicit pairwise `both` rules are provided to avoid implicit broad subnet communication.

Egress route-table associations and subnet communication rules are orchestrated through a child module that runs after enclave creation and uses the managed resource group name returned by AVE.

Egress route table behavior (UDR path):
- The deployment always performs route table create + subnet association when `egressSubnetNames` are provided.
- `egressRouteTableName`: optional override (default `rt-aks-egress`).

## Prerequisites for policy-restricted environments

If tenant/subscription policy restricts route table creation or subnet route-table association, policy exemptions must be created before running deployment 1.

Scope to exempt:
- The enclave managed resource group created by AVE.

Operations to exempt:
- `Microsoft.Network/routeTables/write`
- `Microsoft.Network/virtualNetworks/subnets/write`

How to exempt:
1. Identify the policy assignment (or initiative assignment) enforcing the deny effect.
2. Create a policy exemption at the enclave managed resource group scope for that assignment.
3. If the assignment is an initiative, use `policyDefinitionReferenceIds` to target only the route-table/subnet-association policy definitions when possible.
4. Ensure the deploying identity has permissions required by the policy model and resource operations.

Optional tuning keys:
- `subnetCommunicationRuleNamePrefix` (default `allow-subnet`)
- `subnetCommunicationPriorityStart` (default `3000`)

### Default behavior when not specified

- `diagnosticDestination`: `Both`
- `enableBastion`: `true`
- `allowSubnetCommunication`: `false`

## Critical operational gate between deployment 1 and deployment 2

Deployment 1 creates the AKS control-plane UAI, but it cannot add that UAI to a Microsoft Entra group.

Before running deployment 2 (workload), you must:
1. Ensure the UAI service principal has Advanced maintenance-mode access (direct principal assignment or group-based assignment).
2. If using group-based assignment, wait for group membership propagation.
3. Validate the effective access using your deployment script wrapper (non-CI and CI/CD paths).
4. Proceed with workload deployment only after validation passes.

### Post-enclave creation helper script

Script location:
- `scripts/Add-UaiToEntraGroup.ps1`

Use this script only when you choose the group-based assignment path and deployment 1 returns `aksControlPlaneIdentityPrincipalId`.

Example usage:

```powershell
./scripts/Add-UaiToEntraGroup.ps1 \
  -GroupObjectId "<maintenance-principals-group-object-id>" \
  -MemberObjectId "<aks-control-plane-identity-principal-id>"
```

Behavior:
- Validates Azure CLI login and object existence.
- Adds the member if missing.
- Verifies final membership.
- Supports `-Force` to retry add even if membership appears present.

## Outputs from deployment 1

- `enclaveResourceId`
- `enclaveManagedResourceGroupName`
- `aksControlPlaneIdentityResourceId`
- `aksControlPlaneIdentityPrincipalId`
- `aksControlPlaneIdentityClientId`
- `egressRouteTableId`
- `privateDnsZoneResourceIds`
- `workloadRbacDelegationApplied`
- `workloadRbacDelegationResourceGroupId`
- `workloadRbacDelegationRoleDefinitionId`

## Deployment 2 (AKS workload)

Deployment 2 is intentionally separate from deployment 1. It creates the Mission workload resource and deploys workload resources such as AKS, Key Vault, and Storage.

Template and sample:
- `aveAksWorkloadDeployment.bicep`
- `sample.workload.bicepparam`

Deployment command:

```bash
az deployment sub create \
  --name "deploy-aks-workload-v2" \
  --location usgovvirginia \
  --template-file "./aveAksWorkloadDeployment.bicep" \
  --parameters "./sample.workload.bicepparam"
```

Required deployment 2 prerequisites:
1. Deployment 1 completed successfully.
2. The AKS control-plane UAI service principal from deployment 1 has Advanced maintenance-mode access (direct principal assignment or group-based assignment).
3. The AKS control-plane UAI service principal from deployment 1 has enclave Contributor rights (direct principal assignment or group-based assignment).
4. If group-based assignment is used, group membership propagation is complete.
5. The deployment user has subscription-scope deployment rights required by `az deployment sub create` (must include `Microsoft.Resources/deployments/validate/action`; `Contributor` at subscription scope satisfies this).

Deployment 2 enforces prerequisite acknowledgment using:
- `aksControlPlaneIdentityInAdvancedMaintenanceMode` (must be `true`).
- `aksControlPlaneIdentityHasEnclaveContributorRole` (must be `true`).

Minimal workload configuration contract (`workloadConfiguration`):
- `enclaveResourceId`
- `name`
- `communityManagedResourceGroupResourceId`

Optional workload inputs:
- `resourceGroupName`
- `location`
- `managedResourceGroupName`
- `privateDnsResourceGroupId` (required in practice for workload deployment): resource ID of an existing DNS resource group that already contains required private DNS zones from deployment 1
- `aksNetworkOverlay`
- `aksDefinition`
- `keyVaultDefinition`
- `storageDefinition`

Workload PDNS behavior:
- Deployment 2 links to existing private DNS zones only.
- Deployment 2 does not create private DNS zones.
- Zone creation behavior remains in deployment 1 (enclave foundation), including existing-vs-create logic there.

### Deployment-user subscription role helper script

Script location:
- `scripts/Grant-DeploymentUserSubscriptionRole.ps1`

Use this script to grant the deployment user a role at subscription scope for deployment 2 execution.

Examples:

```powershell
./scripts/Grant-DeploymentUserSubscriptionRole.ps1 \
  -SubscriptionId "<target-subscription-id>" \
  -UserPrincipalName "<user@contoso.com>"
```

```powershell
./scripts/Grant-DeploymentUserSubscriptionRole.ps1 \
  -SubscriptionId "<target-subscription-id>" \
  -UserObjectId "<entra-user-object-id>" \
  -RoleName "Contributor"
```

## Notes

- The route table created in deployment 1 is intentionally empty.
- The template associates the route table to the `egressSubnetNames` you provide.
- Subnet communication rules require explicit NSG names and subnet prefixes in each rule object.
