# Community Network Planning Guide

When deploying multiple Azure Virtual Enclave communities, each must have non-overlapping address spaces. This guide provides common network configurations to prevent conflicts.

## Quick Reference: Non-Overlapping Address Spaces

### RFC 1918 Private Address Ranges
- **10.0.0.0/8**: 10.0.0.0 to 10.255.255.255 (16,777,216 addresses)
- **172.16.0.0/12**: 172.16.0.0 to 172.31.255.255 (1,048,576 addresses)  
- **192.168.0.0/16**: 192.168.0.0 to 192.168.255.255 (65,536 addresses)

## Recommended Configurations by Number of Communities

### 2 Communities
```bicep
communityConfigs: [
  { addressSpace: '10.0.0.0/16' },  // Community 0: 10.0.x.x
  { addressSpace: '10.1.0.0/16' }   // Community 1: 10.1.x.x
]
```

### 3 Communities  
```bicep
communityConfigs: [
  { addressSpace: '10.0.0.0/16' },  // Community 0: 10.0.x.x
  { addressSpace: '10.1.0.0/16' },  // Community 1: 10.1.x.x
  { addressSpace: '10.2.0.0/16' }   // Community 2: 10.2.x.x
]
```

### 5 Communities
```bicep
communityConfigs: [
  { addressSpace: '10.0.0.0/16' },  // Community 0: 10.0.x.x
  { addressSpace: '10.1.0.0/16' },  // Community 1: 10.1.x.x
  { addressSpace: '10.2.0.0/16' },  // Community 2: 10.2.x.x
  { addressSpace: '10.3.0.0/16' },  // Community 3: 10.3.x.x
  { addressSpace: '10.4.0.0/16' }   // Community 4: 10.4.x.x
]
```

### 10 Communities (Maximum)
```bicep
communityConfigs: [
  { addressSpace: '10.0.0.0/16' },  // Community 0
  { addressSpace: '10.1.0.0/16' },  // Community 1
  { addressSpace: '10.2.0.0/16' },  // Community 2
  { addressSpace: '10.3.0.0/16' },  // Community 3
  { addressSpace: '10.4.0.0/16' },  // Community 4
  { addressSpace: '10.5.0.0/16' },  // Community 5
  { addressSpace: '10.6.0.0/16' },  // Community 6
  { addressSpace: '10.7.0.0/16' },  // Community 7
  { addressSpace: '10.8.0.0/16' },  // Community 8
  { addressSpace: '10.9.0.0/16' }   // Community 9
]
```

## Alternative Network Schemes

### Mixed RFC 1918 Ranges
For organizations with existing network infrastructure:

```bicep
communityConfigs: [
  { addressSpace: '10.0.0.0/16' },     // Production: 10.0.x.x
  { addressSpace: '172.16.0.0/16' },   // Staging: 172.16.x.x
  { addressSpace: '192.168.0.0/16' }   // Development: 192.168.x.x
]
```

### Large Environments (/12 subnets)
For very large deployments with many enclaves:

```bicep
communityConfigs: [
  { addressSpace: '10.0.0.0/12' },   // Community 0: 10.0.0.0 - 10.15.255.255
  { addressSpace: '10.16.0.0/12' },  // Community 1: 10.16.0.0 - 10.31.255.255
  { addressSpace: '10.32.0.0/12' }   // Community 2: 10.32.0.0 - 10.47.255.255
]
```

## Environment-Specific Examples

### Development, Staging, Production
```bicep
communityConfigs: [
  // Development Environment
  {
    addressSpace: '10.0.0.0/16'
    dnsServers: []
    // ... minimal approval settings
  }
  // Staging Environment  
  {
    addressSpace: '10.1.0.0/16'
    dnsServers: ['8.8.8.8', '8.8.4.4']
    // ... moderate approval settings
  }
  // Production Environment
  {
    addressSpace: '10.2.0.0/16'
    dnsServers: ['internal-dns-1', 'internal-dns-2']
    // ... strict approval settings
  }
]
```

### Multi-Region Deployment
```bicep
communityConfigs: [
  // East US Community
  {
    addressSpace: '10.10.0.0/16'
    // ... region-specific settings
  }
  // West US Community
  {
    addressSpace: '10.20.0.0/16'
    // ... region-specific settings
  }
  // Europe Community
  {
    addressSpace: '10.30.0.0/16'
    // ... region-specific settings
  }
]
```

## Address Space Planning

### Subnet Allocation Within Communities

With `numberOfEnclavesPerCommunity = 5` and `/24` enclave networks:
- Community `10.0.0.0/16` can have:
  - Enclave 0: `10.0.0.0/24` (254 hosts)
  - Enclave 1: `10.0.1.0/24` (254 hosts)
  - Enclave 2: `10.0.2.0/24` (254 hosts)
  - Enclave 3: `10.0.3.0/24` (254 hosts)
  - Enclave 4: `10.0.4.0/24` (254 hosts)
  - Room for 251 more `/24` subnets

### Capacity Planning

| Community Size | Enclaves | Subnet Size | Total Hosts per Community |
|---------------|----------|-------------|---------------------------|
| `/16` | 5 | `/24` | 1,270 hosts |
| `/16` | 5 | `/23` | 2,540 hosts |
| `/12` | 5 | `/24` | 1,270 hosts (massive room for growth) |

## Best Practices

1. **Start with `/16` communities** unless you need more addresses
2. **Use sequential numbering** (10.0.x.x, 10.1.x.x, 10.2.x.x) for simplicity
3. **Document your scheme** in deployment notes
4. **Reserve address ranges** for future expansion
5. **Consider existing networks** in your organization
6. **Test connectivity** between communities if required
7. **Use different ranges per environment** (dev/staging/prod)

## Validation

Before deployment, verify:
- [ ] No overlapping address spaces between communities
- [ ] Address spaces don't conflict with existing organizational networks
- [ ] Sufficient addresses for planned enclaves and workloads
- [ ] Array length matches `numberOfCommunities` parameter
- [ ] DNS servers are appropriate for each community's purpose

## Common Mistakes to Avoid

❌ **Don't do this:**
```bicep
communityConfigs: [
  { addressSpace: '10.0.0.0/16' },
  { addressSpace: '10.0.0.0/16' }   // DUPLICATE! Will cause conflicts
]
```

❌ **Don't do this:**
```bicep
communityConfigs: [
  { addressSpace: '10.0.0.0/16' },
  { addressSpace: '10.0.1.0/24' }   // OVERLAP! 10.0.1.x is inside 10.0.0.0/16
]
```

✅ **Do this instead:**
```bicep
communityConfigs: [
  { addressSpace: '10.0.0.0/16' },
  { addressSpace: '10.1.0.0/16' }   // UNIQUE! No conflicts
]
```

For questions about network planning, consult your network administrator or Azure support.