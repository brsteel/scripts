# Azure Virtual Enclave Infrastructure

This Bicep solution deploys **only the native Azure Virtual Enclave control-plane resources** (Communities, Virtual Enclaves, Workloads) using the `Microsoft.Mission` preview provider. It does **not** (currently) create VMs, Key Vaults, NSGs, or other downstream workload assets – those are added later by you inside the resource groups referenced by each workload. Earlier drafts of this README implied VM, NSG, and Key Vault deployment; that has been corrected for accuracy.

## Architecture Overview

```text
Community: <baseName>
Enclave:   <baseName>e<enclaveIndex>
```

We intentionally removed the automatic numeric suffix for communities. If you need multiple communities in the same subscription, supply distinct `baseName` values per deployment (e.g. `alpha`, `bravo`). This keeps resource names stable and readable.

`baseName` max length is 28 – leaving room for enclave suffixes (`e0`, etc.) while staying within the 30‑character portal constraint. When planning many enclaves, you typically still remain well under the limit; adjust `baseName` downward only if you introduce longer custom enclave suffix logic in the future.

- **Explicit Azure RBAC**: Standard `Microsoft.Authorization/roleAssignments` with clearable inheritance (empty array = clear) and a summarized `rbacSummary` output.
- **Governance Hooks**: Optional governed service list emission (feature toggled) and maintenance mode object support (mode + principals + justification guardrail).
- **Diagnostics Defaults**: Central `diagnosticDestinationDefault` applied unless overridden per enclave.
- **Preview-Friendly Naming**: Compact naming always enforced to stay within preview constraints.
- **Auditing Outputs**: Hierarchical RBAC + maintenance info surfaces via deployment outputs for automation.

> NOTE: Add your actual application resources (VMs, PaaS, databases, etc.) separately inside the workload-declared resource groups after deployment. This template purposefully limits itself to control-plane objects while the RP is in preview.

## Documentation

- **[Quick Start Guide](QUICK-START.md)**: **START HERE** - Simple development deployments with minimal and basic configurations
- **[Nested Configuration Guide](NESTED-CONFIG-GUIDE.md)**: Complete guide to individual enclave and workload configurations
- **[Parameters Documentation](PARAMETERS.md)**: Comprehensive guide to all deployment parameters, including approval settings, network configuration, and governance options  
- **[Network Planning Guide](NETWORK-PLANNING.md)**: Address space planning and network configuration examples
- Deployment how-to is included in Quick Start and parameter files (separate guide forthcoming)
- **[Architecture Details](#architecture-overview)**: Technical architecture and design decisions

## Files Structure

```text
AzureVirtualEnclave/
├── solution.bicep             # Main subscription-scope template
├── solution.bicepparam        # Example parameter file (edit for your layout)
├── QUICK-START.md             # Getting started (will be pruned if redundant)
├── NESTED-CONFIG-GUIDE.md     # Deep dive: nested arrays & patterns
├── PARAMETERS.md              # Parameter reference (kept lean & current)
├── NETWORK-PLANNING.md        # Address space planning (logical guidance)
├── README.md                  # This file
└── modules/
  ├── ave-community.bicep    # Community module
  ├── ave-enclave.bicep      # Enclave module
  └── ave-workload.bicep     # Workload module
```

## Prerequisites

- Azure CLI installed and configured
- Bicep CLI installed (or use `az bicep install`)
- Azure subscription with appropriate permissions
- (Optional) PowerShell / Bash shell for running Azure CLI commands

### RBAC Role Assignment Model (Explicit ARM RBAC – Inline AVE RBAC Disabled)

The preview API surface (`2025-05-01-preview`) exposed properties such as `communityRoleAssignments` in What-If output, but those inline properties are **not currently writable** (attempts returned *Invalid role definition ID* / property ignored). This implementation therefore uses **standard Azure RBAC** resources (`Microsoft.Authorization/roleAssignments`) at each scope:

Scopes:

1. Community (`Microsoft.Mission/communities/<name>`)
2. Virtual Enclave (`Microsoft.Mission/virtualEnclaves/<name>`)
3. Workload (`Microsoft.Mission/virtualEnclaves/<enclave>/workloads/<name>`)

#### Supported Role Buckets

Contributor, Reader, NetworkContributor, MonitoringReader, MonitoringContributor, LogAnalyticsReader, LogAnalyticsContributor, SecurityReader, SecurityAdmin, UserAccessAdministrator.

Only Contributor is required for baseline operation; the rest are optional fine‑grained access buckets (leave arrays empty to skip).

#### Parameter-Driven Model

You provide arrays of principal Object IDs (users, groups, service principals) in parameter arrays. The template:

1. Maps each role bucket to its built‑in role definition ID.
2. Inherits arrays down the hierarchy (community → enclave → workload) unless a child defines a non‑empty override under its `rbac` object.
3. Creates one role assignment per (scope, role, principal) using deterministic GUID seeding: `guid(scopeId, roleDefinitionId, principalId)` ensuring idempotency.

#### Inheritance & Clearing Logic

Inheritance now uses a presence-based override model:

At each enclave:

```text
if rbac.<bucket> property exists (even if empty) -> use that array
else -> inherit parent community array
```

At each workload:

```text
if rbac.<bucket> property exists (even if empty) -> use that array
else -> inherit enclave effective array
```

To CLEAR an inherited role bucket, specify an empty array:

```bicep
rbac: {
  contributors: []            // clears inherited Contributor principals
  readers: ['<groupObjectId>'] // override Readers list
}
```

Absent property = inherit. Empty array = explicit “assign none”.

#### Example – Single User Contributor Everywhere

```bicep
param contributorPrincipals = [ 'abd8437b-107e-4c1b-9d65-6613f079ce61' ] // user objectId
param communityReaders = []
param communityNetworkContributors = []
// all other role arrays empty → only Contributor assignments emitted
```

Result: The specified principal receives Contributor at community, each enclave, and each workload scope.

#### Adding an Enclave Override

```bicep
enclaveConfigs: [
  {
    networkName: 'enc0-vnet'
    networkSize: '/24'
    rbac: {
      readers: ['aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee']  // enclave-only Reader
    }
    workloadConfigs: [
      {
        name: 'workload-a'
        rbac: {
          contributors: ['ffffffff-1111-2222-3333-444444444444'] // workload-specific Contributor (added in addition to inherited Contributor if provided)
        }
      }
    ]
  }
]
```

#### Generated Assignment ID Pattern

`guid(<scopeResourceId>, <roleDefinitionGuid>, <principalObjectId>)`

This allows you to pre-compute expected assignment IDs for audit or drift detection tooling.

#### RBAC Summary Output

Template now emits:

- Root output `rbacSummary`: array of community summaries (community effective arrays + each enclave effective arrays)
- Enclave output `workloadRbacSummary`: per-workload effective arrays


Use these outputs for automated auditing without enumerating live role assignments.

#### Removal / Pruning

Removing a principal from parameters does **not** delete an existing assignment automatically (Azure RBAC behavior). A future helper module or post-deployment script can reconcile and remove stale assignments.

#### Why Not Inline Mission RP RBAC?

Inline `*RoleAssignments` properties appeared in What-If but caused provisioning errors when supplied. Using explicit ARM RBAC resources ensures compatibility, visibility in Azure Activity Logs, and standard lifecycle management.

#### Security Guidance

Prefer assigning roles to Entra ID groups over individual users for maintainability and periodic access review. Minimize the number of principals in high-privilege buckets (Contributor, SecurityAdmin, UserAccessAdministrator).

### Pre-Creating Entra ID Groups (Recommended)

You may (optionally) pre-create Microsoft Entra ID (Azure AD) security groups to map to AVE community and enclave role buckets. Provide their object IDs via parameters to automatically assign RBAC at deploy time.

Suggested naming convention (example):

| Scope | Role Bucket | Suggested Group Display Name |
|-------|-------------|-------------------------------|
| Community | Contributor | AVE-Community-Contributors |
| Community | Reader | AVE-Community-Readers |
| Community | NetworkContributor | AVE-Community-NetworkContrib |
| Community | MonitoringReader | AVE-Community-MonitoringReaders |
| Community | MonitoringContributor | AVE-Community-MonitoringContrib |
| Community | LogAnalyticsReader | AVE-Community-LAReaders |
| Community | LogAnalyticsContributor | AVE-Community-LAContrib |
| Community | SecurityReader | AVE-Community-SecurityReaders |
| Community | SecurityAdmin | AVE-Community-SecurityAdmins |
| (Future) Enclave | Contributor | AVE-Enclave-Contributors |
| (Future) Enclave | Reader | AVE-Enclave-Readers |
| (Future) Enclave | NetworkContributor | AVE-Enclave-NetworkContrib |
| (Future) Enclave | MonitoringReader | AVE-Enclave-MonitoringReaders |
| (Future) Enclave | MonitoringContributor | AVE-Enclave-MonitoringContrib |
| (Future) Enclave | LogAnalyticsReader | AVE-Enclave-LAReaders |
| (Future) Enclave | LogAnalyticsContributor | AVE-Enclave-LAContrib |
| (Future) Enclave | SecurityReader | AVE-Enclave-SecurityReaders |
| (Future) Enclave | SecurityAdmin | AVE-Enclave-SecurityAdmins |
| (Future) Workload | Contributor | AVE-Workload-Contributors |
| (Future) Workload | Reader | AVE-Workload-Readers |

If you leave any parameter array empty, no assignments for that role bucket are created.

Example (parameter file snippet for community groups):

```bicep
param communityContributors = [ '11111111-2222-3333-4444-555555555555' ]
param communityReaders = [ 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' ]
param communityNetworkContributors = []
param communityMonitoringReaders = []
param communityMonitoringContributors = []
param communityLogAnalyticsReaders = []
param communityLogAnalyticsContributors = []
param communitySecurityReaders = []
param communitySecurityAdmins = []
```

Enclave/workload group object IDs are supplied similarly (see module parameter names). All parameters accept an array, enabling multiple groups if required.

## Quick Start

### Deployment (Azure CLI)

```bash
# Set environment variable for admin password
export ADMIN_PASSWORD="YourSecurePassword123!"

# Deploy using bicep parameters file
az deployment sub create \
  --name "ave-deployment" \
  --location "East US 2" \
  --template-file solution.bicep \
  --parameters solution.bicepparam
```

### Override Inline (discouraged for large topologies)

```bash
az deployment sub create \
  --name "ave-deployment" \
  --location "East US 2" \
  --template-file solution.bicep \
  --parameters baseName="myenclave" \
               @myNestedConfigOverrides.json
```

## Configuration Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `baseName` | string | - | Base name prefix for all resources |
| `location` | string | deployment().location | Azure region for deployment |
| `communityConfig` | object | {} | Single community configuration object with nested enclaves & workloads |
| `deployEnclaves` | bool | true | Skip enclaves/workloads when false (community-only phase) |
| `enableGovernedServiceList` | bool | false | Emit governedServiceList (preview – optional) |
| `diagnosticDestinationDefault` | string | Both | Default diagnostic routing (`EnclaveOnly`\|`Both`) |
| `contributorPrincipals` | array | [] | Principals (object IDs) for Contributor inheritance |
| `communityReaders` (etc.) | array | [] | Optional role bucket arrays (empty = none) |
| `tags` | object | basic set | Applied to created resource group + child deployments |
| `tags` | object | see params | Resource tags |

### Naming & Length Constraints

Portal-enforced limit: each AVE community resource name must be <= 30 characters.

This template uses a compact pattern for community and enclave names:

```text
Community: <baseName>c<communityIndex>
Enclave:   <baseName>c<communityIndex>e<enclaveIndex>
```

The template now constrains `baseName` to a maximum of 28 characters. With the compact pattern:

```text
<baseName>c<index>
```

Even the longest single‑digit community name will be at most 30 characters (portal limit). If you plan for more than 9 communities (rare), reduce `baseName` length accordingly (e.g. keep it ≤27 to allow `c10`).

The deployment output `hostedNameAnalysis` surfaces:

- Longest prospective community & enclave names
- Their lengths
- Whether they fall within the 30‑character limit

If you exceed the limit (e.g. long `baseName` + multi‑digit indices), the RP/portal will reject creation—adjust `baseName` accordingly.

## Enclave Configuration

Each `enclaveConfigs[]` entry supports (current subset):

| Field | Required | Description |
|-------|----------|-------------|
| `bastionEnabled` | yes | Boolean flag passed to RP (preview – behavior may evolve) |
| `networkName` | yes | Logical name for enclave virtual network construct (RP-managed) |
| `networkSize` | yes | `/24` `/25` `/26` or `'custom'` (with `customCidrRange`) |
| `customCidrRange` | conditional | Required only when `networkSize == 'custom'` |
| `allowSubnetCommunication` | yes | Boolean – preview connectivity toggle |
| `connectToAzureServices` | yes | Boolean passthrough (RP field) |
| `diagnosticDestination` | optional | Overrides module default (`EnclaveOnly`\|`Both`) |
| `maintenance` | optional | `{ mode: 'On'\|'Off', principals?:[], justification?:'' }` |
| `rbac` | optional | Role bucket overrides (presence-based, empty clears) |
| `workloadConfigs` | array | Child workloads (containers) |

## Network Architecture

> The Mission RP abstracts underlying network implementation details. Treat `addressSpace`, `networkSize`, and `customCidrRange` as **logical intent inputs** — the RP owns final realization.

## Enclave Network Sizing & Guardrails

Each enclave declares a `networkSize` plus (optionally) a `customCidrRange` inside its `enclaveConfig` object.

| Field | Purpose | Typical Values | Required | Notes |
|-------|---------|----------------|----------|-------|
| `networkSize` | Logical sizing directive | `/24`, `/25`, `/26`, `custom` | Yes | When not `custom` a deterministic slice is allocated automatically. |
| `customCidrRange` | Explicit CIDR block | e.g. `10.50.20.0/23` | Only if `networkSize == 'custom'` | Must sit inside the parent community `addressSpace` and not overlap other enclaves. |

### Recommended Practice

Use standard (non-`custom`) sizing for most deployments. This keeps allocation automatic and reduces IPAM overhead. Only use `custom` when you have a pre-assigned range or need a non-sequential / larger block.

### Guardrails (Template-Enforced)

1. If `networkSize == 'custom'` then `customCidrRange` must be provided.
2. If `networkSize != 'custom'` then `customCidrRange` must be omitted.
3. If `maintenance.mode == 'On'` a non-empty `maintenance.justification` is required.

### Examples

Standard sizing (preferred):

```bicep
enclaveConfigs: [
  {
    networkName: 'enc0-vnet'
    networkSize: '/24'        // automatic slice
    // customCidrRange omitted
  }
]
```

Custom sizing (only when needed):

```bicep
enclaveConfigs: [
  {
    networkName: 'encX-vnet'
    networkSize: 'custom'
    customCidrRange: '10.60.40.0/23'
  }
]
```

Invalid (will fail fast):

```bicep
// Missing customCidrRange
{ networkName: 'bad-vnet', networkSize: 'custom' }

// customCidrRange present but size not custom
{ networkName: 'bad-vnet2', networkSize: '/24', customCidrRange: '10.70.0.0/24' }

// Maintenance justification missing
{ networkName: 'bad-vnet3', networkSize: '/24', maintenance: { mode: 'On' } }
```

These assertions provide early feedback before the deployment reaches the resource provider, reducing troubleshooting time.

## Security Considerations

1. **Change Default Passwords**: Always use strong, unique passwords
2. **Network Security**: Review NSG rules for your security requirements
3. **Public IPs**: Consider removing public IPs for production deployments
4. **Key Management**: Implement proper key rotation policies
5. **Access Control**: Use Azure RBAC and conditional access policies
6. **Monitoring**: Enable Azure Security Center and Log Analytics

## Deployment Examples

### Example Scaling Patterns

All scaling is controlled by nested arrays inside `communityConfig.enclaveConfigs` (parameter file). No scalar enclave/workload count parameters exist.

| Scenario | Communities | Enclaves (total) | Workloads (total) |
|----------|-------------|------------------|-------------------|
| Dev | 1 | 1 | 2 |
| Test | 2 | 4 | 12 |
| Prod (illustrative) | 5 | 15 | 60 |

Counts are illustrative; adapt `communityConfig.enclaveConfigs[*].workloadConfigs` accordingly. For an authoritative count, inspect your parameter file or extend the template with custom outputs once Bicep adds richer aggregation functions.

## Accessing Virtual Machines

### Azure Virtual Enclave (AVE) Native Access

Azure Virtual Enclave provides built-in secure connectivity and access management:

1. **AVE Portal Integration** → Access through Azure Virtual Enclave service console
2. **Native Security Controls** → Built-in identity and access management
3. **Encrypted Connectivity** → Hardware-backed secure channels to workloads
4. **Audit and Compliance** → Comprehensive logging and monitoring
5. **Zero Trust Access** → Identity-based access without exposing public endpoints

### AVE Security Features

- **Hardware-based Attestation**: Cryptographic proof of enclave integrity
- **Secure Communication**: End-to-end encrypted channels
- **Identity Integration**: Azure AD/Entra ID integration
- **Policy Enforcement**: Fine-grained access controls
- **Audit Logging**: Complete session and access audit trails

### Direct VM Access (Not Recommended)

⚠️ **Important**: AVE workloads do not use public IP addresses. All connectivity should be through AVE's secure channels.

For troubleshooting scenarios only:

- Access must be configured through AVE service console
- Direct networking access violates AVE security model
- Use AVE's native secure access for all scenarios

## Monitoring and Management

After deployment, you can monitor your infrastructure using:

- **Azure Portal**: Resource groups, VMs, networking
- **Azure Monitor**: Performance metrics and logs
- **Key Vault**: Secret and key management
- **Security Center**: Security recommendations and compliance
- **Bastion Logs**: Connection audit trails and session monitoring

## Cost Optimization

- Use appropriate VM sizes for your workload requirements
- Consider reserved instances for production deployments  
- Implement auto-shutdown policies for development environments
- Monitor and optimize storage usage
- Use Azure Cost Management for ongoing cost analysis

## Troubleshooting

### Common Issues

1. **Deployment Fails**: Check subscription quotas for DCsv3 VMs
2. **Network Connectivity**: Verify NSG rules and routing
3. **Key Vault Access**: Ensure proper RBAC permissions
4. **VM Boot Issues**: Check boot diagnostics in Azure Portal

### Preview Known Issues (updated)

| Issue | Description | Mitigation |
|-------|-------------|------------|
| approvalSettings BadRequest | Any non-null approvalSettings payload returns BadRequest | Omit approvalSettings (template omits by default) |
| Enclave name length >30 | Verbose name pattern can exceed limit | Compact naming now enforced automatically |
| Virtual Hub InternalServerError | Intermittent failure provisioning virtual hub | Retry minimal (community+one enclave); capture correlationId; check Activity Log |



### Naming Pattern

`<baseName>c<communityIndex>e<enclaveIndex>` – fixed compact form. Keep `baseName` ≤ 24 chars to account for RP‑added hosted resource group suffixes.



### Maintenance Mode

Maintenance can be toggled per community and per enclave with this object inside the corresponding config:

```bicep
maintenance: {
  mode: 'On' // or 'Off'
  principals: [ '11111111-2222-3333-4444-555555555555' ] // optional Entra ID groups allowed during maintenance
  justification: 'Monthly patching' // required if mode == 'On'
}
```

If `principals` omitted while `mode` is On, the template currently allows it (future enhancement: validation). Justification is surfaced as a property when provided.



### Diagnostic Destination

Per-enclave override options:
`CommunityOnly` | `EnclaveOnly` | `Both` (default)
If an invalid value is provided, the module falls back to its `diagnosticDestinationDefault` parameter (default 'Both').

### Useful Commands

```powershell
# Check deployment status
az deployment sub show --name "ave-deployment"

# List all resources in resource group  
az resource list --resource-group "ave-dev-rg"

# Connect to VM via RDP/SSH
az vm show --resource-group "ave-dev-rg" --name "ave-dev-community-0-enclave-0-workload-0-vm" --show-details
```

## Contributing

When making changes to this template:

1. Follow Azure Bicep best practices
2. Update the README with any new parameters or features
3. Test deployments in a development subscription
4. Ensure proper error handling and validation

## License

This project is provided as-is for educational and development purposes.
