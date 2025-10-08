# Azure Virtual Enclave Parameter Reference

This document captures the **current, supported** parameters for the subscription‑scope `solution.bicep` template. All deprecated scalar sizing parameters and unsupported approval configuration payloads have been removed. Scaling now occurs **only** through nested arrays.

> NOTE: Earlier drafts used deprecated scalar counts (`numberOfEnclavesPerCommunity`, `numberOfWorkloadsPerEnclave`) and `approvalSettings` objects. Those are intentionally excluded because (a) the template derives structure from arrays, and (b) preview API calls with non‑null `approvalSettings` return `BadRequest`.

## Top-Level Parameters

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| `location` | string | `deployment().location` | No | Azure region for the deployment (canonicalized internally). |
| `baseName` | string | n/a | Yes | Short base name prefix; used for resource group & community naming (`<baseName>-rg`). Keep concise (≤ 28 chars). |
| `deployEnclaves` | bool | `true` | No | Set `false` to skip enclave/workload creation (staged troubleshooting). |
| `communityConfig` | object | `{}` | Yes | Single community object containing `enclaveConfigs` and workloads per enclave. |
| `enableGovernedServiceList` | bool | `false` | No | Emit governedServiceList into community properties (preview feature toggle). |
| `diagnosticDestinationDefault` | string | `Both` | No | Fallback when an enclave omits `diagnosticDestination` (allowed: `EnclaveOnly`\|`Both`). |
| `contributorPrincipals` | array | `[]` | No | Principal object IDs granted Contributor at all scopes (unless cleared/overridden). |
| `communityReaders` (and other role arrays) | array | `[]` | No | Optional role bucket principal object IDs. Empty array = none emitted. |
| `tags` | object | `{ DeployedBy: 'Bicep' }` | No | Applied to deployment resource group & used in module tag unions. |

### Role Bucket Parameters

The template exposes discrete arrays for standard built‑in roles to enable least‑privilege grouping:

`communityReaders`, `communityNetworkContributors`, `communityMonitoringReaders`, `communityMonitoringContributors`, `communityLogAnalyticsReaders`, `communityLogAnalyticsContributors`, `communitySecurityReaders`, `communitySecurityAdmins`, `communityUserAccessAdministrators`.

All are optional; an empty array means *no* role assignments for that bucket are created at the community scope. Inheritance to enclaves & workloads follows the clearable model (see below).

| Parameter | Role Applied | Built-in Role Name | Role Definition ID | Behavior |
|-----------|--------------|--------------------|--------------------|----------|
| `contributorPrincipals` | Community / Enclave / Workload | Contributor | b24988ac-6180-42a0-ab88-20f7382dd24c | Assigned at community; inherited unless cleared downstream |
| `communityReaders` | Community | Reader | acdd72a7-3385-48ef-bd42-f606fba81ae7 | Inherited to enclaves/workloads unless overridden/cleared |
| `communityNetworkContributors` | Community | Network Contributor | 4d97b98b-1d4f-4787-a291-c67834d212e7 | Grants network-level management (preview logical intent) |
| `communityMonitoringReaders` | Community | Monitoring Reader | 43d0d8ad-25c7-4714-9337-8ba259a9fe05 | Read-only monitoring visibility |
| `communityMonitoringContributors` | Community | Monitoring Contributor | 749f88d5-cbae-40b8-bcfc-e573ddc772fa | Modify monitoring / insights config |
| `communityLogAnalyticsReaders` | Community | Log Analytics Reader | 73c42c96-874c-492b-b04d-ab87d138a893 | Read logs & saved searches |
| `communityLogAnalyticsContributors` | Community | Log Analytics Contributor | 92aaf0da-9dab-42b6-94a3-d43ce8d16293 | Manage LA workspace solutions / config |
| `communitySecurityReaders` | Community | Security Reader | 8d32ff11-19e7-4f25-8d7a-4176c81c0f83 | Read security posture/events |
| `communitySecurityAdmins` | Community | Security Admin | fb1c8493-542b-48ef-b624-b4c8fea62acd | Configure/dismiss security findings |
| `communityUserAccessAdministrators` | Community | User Access Administrator | 18d7d88d-d35e-4fb5-a5c3-7773a3e3d1af | Delegate RBAC management (use sparingly) |

Clearing / overriding at enclave or workload level:

```bicep
// Inside an enclave or workload config
rbac: {
  monitoringContributors: []   // explicitly remove inherited monitoring contributors here
  readers: [ '00000000-0000-0000-0000-000000000001' ] // replace inherited readers with this single principal
}
```

Any bucket key present (even with an empty array) stops inheritance for that bucket. Omitted buckets inherit unchanged.

### Enclave & Workload RBAC Overrides

At enclave or workload scope, the `rbac` object uses the **same bucket key names without the `community` prefix**:

```bicep
enclaveConfigs: [
  {
    networkName: 'enc0-vnet'
    // ...other enclave fields
    rbac: {
      readers: ['11111111-1111-1111-1111-111111111111'] // replace inherited readers
      monitoringContributors: []                        // explicitly clear this bucket
    }
    workloadConfigs: [
      {
        name: 'workload-a'
        rbac: {
          contributors: [] // clear inherited contributor principals just for this workload
          logReaders: ['22222222-2222-2222-2222-222222222222']
        }
      }
    ]
  }
]
```

Supported bucket property names inside `rbac` objects at enclave/workload level:

`contributors`, `readers`, `networkContributors`, `monitoringReaders`, `monitoringContributors`, `logReaders`, `logContributors`, `securityReaders`, `securityAdmins`, `userAccessAdministrators`.

Inheritance resolution order (per bucket):

1. Workload `rbac.<bucket>` if present (may be empty to clear)
2. Else Enclave `rbac.<bucket>` if present
3. Else Community top-level bucket array

The deployment output `rbacSummary` surfaces effective arrays for community and enclaves; each workload emits its own `workloadRbacEffective` object inside the enclave module outputs to aid audit pipelines.

## Community Configuration (`communityConfig`)

Single object supplying enclaves and workloads:

```bicep
communityConfig: {
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
```

### Community Object Fields

| Field | Required | Description |
|-------|----------|-------------|
| `addressSpace` | Yes | Logical CIDR boundary for enclave allocations (preview logical intent). |
| `dnsServers` | No | Custom DNS server IPs (empty = platform default). |
| `enclaveConfigs` | Yes | Array of enclave definition objects (can be empty when staging). |
| `maintenance` | No | `mode: Off/On/Advanced`, plus optional `principals`, `justification`. `On` requires justification; `Advanced` requires non-empty principals. |
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
| `maintenance` | No | Same shape as community. `Advanced` requires non-empty principals array; `On` requires justification. |
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
| Mode | Rules |
|------|-------|
| `Off` | No principals or justification processed. |
| `On` | `justification` must be non-empty if supplied; principals optional (grant limited operational access). |
| `Advanced` | `principals` MUST be a non-empty array of Entra ID group (or PIM-eligible role) object IDs; justification optional. |
| Principals representation | Each principal is emitted as `{ id: <objectId>, type: 'Group' }`. Use groups or PIM-enabled groups, not individual users, for lifecycle safety. |

## Validation Outputs

Deployment emits a structured `maintenanceValidation` output:

```json
{
  "community": { "mode": "Advanced", "status": "Pass", "issues": [] },
  "enclaves": [ { "name": "contosoe0", "validation": { "mode": "On", "status": "Pass", "issues": [] } } ],
  "anyFailures": false
}
```

Use `anyFailures` to gate pipelines; inspect `issues` arrays for remediation hints. Only maintenance-specific rule violations appear (CIDR or other guardrails remain in resource properties / existing validation messages).

## Deprecated / Unsupported (Historical)

| Former Element | Status | Replacement |
|----------------|--------|-------------|
| `numberOfEnclavesPerCommunity` | Removed | Length of `enclaveConfigs` array |
| `numberOfWorkloadsPerEnclave` | Removed | Length of `workloadConfigs` array |
| `approvalSettings` object | Omitted (preview API rejects) | (None) – future revisit when RP supports writes |

## Example Minimal Parameter File

```bicep
param baseName = 'contoso'
param enableGovernedServiceList = true
param communityConfig = {
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
