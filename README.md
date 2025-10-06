# Scripts

## Azure Virtual Enclave (AVE) – Naming & Hosted Resource Groups

The Microsoft.Mission (Azure Virtual Enclave) resource provider creates additional *hosted* resource groups and internal platform resources for each community and enclave you deploy.

### Why Names Are Kept Compact

Each community and each enclave spawns a hosted RG using the pattern:

```text
<objectName>-HostedResources-<nonce>
```

Approximate added length overhead:

* `-HostedResources-` literal: 17 chars
* Random/hash nonce: ~13 chars
* Total overhead: ~30 characters beyond your supplied community/enclave name

If Azure RG name limits (often 90 chars) apply here, then practical maximum for `<objectName>` is about 60. To retain safety headroom for future RP changes and internal location suffixes (e.g., `-usgovvirginia` on some network artifacts), we intentionally keep `baseName`, community, and enclave names short and index‑based.

### Observed Patterns (Sample)

Community hosted RG example:

```text
ave1workc0-HostedResources-3rnlk3099fz1f
```

Enclave hosted RG example:

```text
ave1workc0e0-HostedResources-2d3nnwxvz6qbx
```

Internal platform resources inside those hosted RGs follow a `<prefix>-<functional-token>` style, where `<prefix>` is the exact community or enclave name you supplied:

Examples (community level):

```text
ave1workc0-vhub-usgovvirginia
ave1workc0-fw-usgovvirginia
ave1workc0-fw-policy
ave1workc0-policy-enforcement-msi
ave1workc0-vwan
ave1workc0-loga
```

Examples (enclave level):

```text
ave1workc0e0-vnet
ave1workc0e0-bastion
ave1workc0e0-bastion-nsg
ave1workc0e0-management-nsg
ave1workc0e0-dce
ave1workc0e0-dcr
ave1workc0e0-ampls
ave1workc0e0-pe / ave1workc0e0-pe.nic.<GUID>
ave1workc0e0-pip
ave1workc0e0-loga
```

Some NSGs or private DNS zone link names may be generic (e.g., `management-subnet-enclave-nsg`) because each enclave has an isolated hosted RG, preventing collisions.

### Length Guidance

| Component | Formula | Safety Recommendation |
|----------|---------|------------------------|
| Community hosted RG | `len(communityName) + 30` | Keep `communityName <= 24` for large future headroom |
| Enclave hosted RG | `len(enclaveName) + 30` | Keep `enclaveName <= 28` |

Current compact pattern ensures: `communityName = <baseName>c<i>` and `enclaveName = <communityName>e<j>`.

### Deployment Outputs

`solution.bicep` now emits an object `hostedNameAnalysis` plus `baseNameLengthWarning` (empty unless risk detected) to assist CI/CD gate logic.

### Future Enhancements (Planned / Optional)

* Optional semantic naming mode once true RP length limits are formally tested.
* Automated length probe (implemented directly with temporary param variations) to empirically map max allowed name lengths.
* Validation/normalization that short workload resource group identifiers are expanded to full ARM IDs (Bicep logic TBD).

---
