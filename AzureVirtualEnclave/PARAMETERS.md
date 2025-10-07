# Azure Virtual Enclave Parameter Reference

This document captures the **current, supported** parameters for the subscription‑scope `solution.bicep` template. All deprecated scalar sizing parameters and unsupported approval configuration payloads have been removed. Scaling now occurs **only** through nested arrays.

> NOTE: Earlier drafts used deprecated scalar counts (`numberOfEnclavesPerCommunity`, `numberOfWorkloadsPerEnclave`) and `approvalSettings` objects. Those are intentionally excluded because (a) the template derives structure from arrays, and (b) preview API calls with non‑null `approvalSettings` return `BadRequest`.

## Top-Level Parameters

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| `location` | string | `deployment().location` | No | Azure region for the deployment (canonicalized internally). |
| `baseName` | string | n/a | Yes | Short base name prefix; used for resource group & community naming (`<baseName>-rg`, `<baseName>c0`). Keep ≤ 24 chars. |
| `numberOfCommunities` | int | `1` | Yes | Must equal `length(communityConfigs)` (range 1‑10). Typical = 1; increase only when distinct governance or lifecycle boundaries are required. Guardrail only; authoritative shape is the array itself. |
| `deployEnclaves` | bool | `true` | No | Set `false` to deploy communities only (phased rollout / troubleshooting). |
| `communityConfigs` | array | `[]` | Yes | Hierarchical configuration: each element declares a community plus nested enclaves & workloads. |
| `enableGovernedServiceList` | bool | `false` | No | Emit governedServiceList into community properties (preview feature toggle). |
| `diagnosticDestinationDefault` | string | `Both` | No | Fallback when an enclave omits `diagnosticDestination` (allowed: `EnclaveOnly`\|`Both`). |
| `contributorPrincipals` | array | `[]` | No | Principal object IDs granted Contributor at all scopes (unless cleared/overridden). |
| `communityReaders` (and other role arrays) | array | `[]` | No | Optional role bucket principal object IDs. Empty array = none emitted. |
| `tags` | object | `{ DeployedBy: 'Bicep' }` | No | Applied to deployment resource group & used in module tag unions. |

### Role Bucket Parameters

The template exposes discrete arrays for standard built‑in roles to enable least‑privilege grouping:

`communityReaders`, `communityNetworkContributors`, `communityMonitoringReaders`, `communityMonitoringContributors`, `communityLogAnalyticsReaders`, `communityLogAnalyticsContributors`, `communitySecurityReaders`, `communitySecurityAdmins`, `communityUserAccessAdministrators`.

All are optional; an empty array means *no* role assignments for that bucket are created at the community scope. Inheritance to enclaves & workloads follows the clearable model (see below).

## Hierarchical Configuration (`communityConfigs`)

Each object in `communityConfigs` represents one community:

```bicep
communityConfigs: [
  {
    addressSpace: '10.10.0.0/16'
    dnsServers: []
    enclaveConfigs: [
      {
        bastionEnabled: true
        networkName: 'enc0-vnet'
        networkSize: '/24'
        allowSubnetCommunication: true
        connectToAzureServices: true
        diagnosticDestination: 'Both'
        workloadConfigs: [
          {
            name: 'workload-a'
            resourceGroupCollection: ['rg-contoso-a']
          }
        ]
      }
    ]
  }
]
```

### Community Object Fields

| Field | Required | Description |
|-------|----------|-------------|
| `addressSpace` | Yes | Logical CIDR boundary for enclave allocations (preview logical intent). |
| `dnsServers` | No | Custom DNS server IPs (empty = platform default). |
| `enclaveConfigs` | Yes | Array of enclave definition objects (can be empty when staging). |
| `maintenance` | No | `{ mode: 'On' or 'Off', principals?:[], justification?:'' }` – justification required when `mode=='On'`. |
| `rbac` | No | Optional clearable overrides for role buckets (same key names as top-level minus prefix). |

## Enclave Configuration (`enclaveConfigs[]`)

| Field | Required | Description |
|-------|----------|-------------|
| `bastionEnabled` | Yes | Boolean passthrough to RP (preview semantics). |
| `networkName` | Yes | Logical enclave network name. |
| `networkSize` | Yes | One of `/24`, `/25`, `/26`, or `'custom'`. |
| `customCidrRange` | Conditional | Required only if `networkSize == 'custom'`; must logically nest within `addressSpace`. |
| `allowSubnetCommunication` | Yes | Boolean toggle for internal subnet east/west. |
| `connectToAzureServices` | Yes | Boolean (platform connectivity). |
| `diagnosticDestination` | No | Overrides `diagnosticDestinationDefault` if valid. |
| `maintenance` | No | Same shape as on community – applied at enclave scope. |
| `rbac` | No | Role bucket overrides (presence-based; empty array clears). |
| `workloadConfigs` | Yes | Array of workload objects (may be empty). |

## Workload Configuration (`workloadConfigs[]`)

| Field | Required | Description |
|-------|----------|-------------|
| `name` | No | Custom workload container name (auto-generated if omitted). |
| `resourceGroupCollection` | No | Array of RG IDs or names (names auto-expanded to full IDs). |
| `rbac` | No | Role bucket overrides / clears (same inheritance semantics). |

### RBAC Inheritance & Clearing

At each level (community → enclave → workload) an RBAC bucket resolves as:

```text
if property exists (even if empty) use it
else inherit parent effective array
```

To explicitly *clear* a role from a child scope:

```bicep
rbac: {
  contributors: []   // removes inherited Contributor principals at this scope
}
```

Deployment outputs include a summarized `rbacSummary` to aid in auditing without live enumeration.

## Maintenance Object Guardrails

| Rule | Description |
|------|-------------|
| Justification required | When `maintenance.mode == 'On'` justification must be non-empty. |
| Principals optional | Omit or supply an array of group object IDs permitted during maintenance. |

## Deprecated / Unsupported (Historical)

| Former Element | Status | Replacement |
|----------------|--------|-------------|
| `numberOfEnclavesPerCommunity` | Removed | Length of `enclaveConfigs` array |
| `numberOfWorkloadsPerEnclave` | Removed | Length of `workloadConfigs` array |
| `approvalSettings` object | Omitted (preview API rejects) | (None) – future revisit when RP supports writes |

## Example Minimal Parameter File

```bicep
param baseName = 'contoso'
param numberOfCommunities = 1 // Typical deployments use a single community; bump only for deliberate separation.
param enableGovernedServiceList = true
param communityConfigs = [
  {
    addressSpace: '10.10.0.0/16'
    dnsServers: []
    enclaveConfigs: [
      {
        bastionEnabled: true
        networkName: 'enc0-vnet'
        networkSize: '/24'
        allowSubnetCommunication: true
        connectToAzureServices: true
        workloadConfigs: [
          {
            name: 'workload-a'
            resourceGroupCollection: ['rg-contoso-a']
          }
        ]
      }
    ]
  }
]
param contributorPrincipals = ['<objectId>']
param tags = {
  Environment: 'Test'
  Project: 'AVE-Test'
  DeployedBy: 'Bicep'
}
```

## Best Practices

1. Keep `baseName` short – hosted RG names add a suffix.
2. Represent scaling exclusively with nested arrays; avoid reintroducing scalar counts.
3. Use Entra ID groups (not users) in RBAC arrays for lifecycle manageability.
4. Explicitly clear inherited RBAC you do **not** want at a child scope with an empty array.
5. Reserve CIDR blocks to avoid overlap when adding enclaves later; rely on `customCidrRange` only when necessary.
6. Capture `rbacSummary` output in CI for drift detection.

## Troubleshooting Quick Hints

| Symptom | Likely Cause | Action |
|---------|--------------|--------|
| Deployment Succeeded but no enclaves | `deployEnclaves` = false | Set to true or remove parameter override |
| Missing RBAC assignments | Empty arrays or omitted principal IDs | Populate appropriate role bucket arrays |
| Validation error about maintenance | `mode: 'On'` without justification | Add `justification` field |
| Unexpected CIDR error (future) | Overlapping `customCidrRange` intent | Adjust ranges; keep a gap plan |

## Support

- See `README.md` for architecture & RBAC model details.
- Use Azure Activity Log and deployment outputs (`rbacSummary`) for auditing.
- Use Azure Activity Log and deployment outputs (`rbacSummary`) for auditing.
