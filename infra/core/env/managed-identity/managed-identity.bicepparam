using './managed-identity.bicep'

param managedIdentities = [
  {
    name: '#{{ infraResourceNamePrefix }}#{{ nc_resource_managedidentity }}#{{ nc_instance_regionid }}01-adp-platform-core'
    tags: {
      Purpose: 'ADP Platform Managed Identity'
      Tier: 'Shared'
    }
    roleAssignments: []
  }
  {
    name: '#{{ infraResourceNamePrefix }}#{{ nc_resource_managedidentity }}#{{ nc_instance_regionid }}01-adp-platform-db-aad-admin'
    tags: {
      Purpose: 'ADP Platform Database AAD Admin Managed Identity'
      Tier: 'Shared'
    }
    roleAssignments: []
  }
]
param location = '#{{ location }}'
param environment = '#{{ environment }}'
