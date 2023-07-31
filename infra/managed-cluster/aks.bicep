@description('Optional. The location to deploy resources to.')
param location string = resourceGroup().location

@description('Optional. A short identifier for the kind of deployment. Should be kept short to not run into resource-name length-constraints.')
param serviceShort string = 'aatest'

@description('Optional. Enable telemetry via a Globally Unique Identifier (GUID).')
param enableDefaultTelemetry bool = true

// ============ //
// Dependencies //
// ============ //

// General resources
// =================

/*
module deployManagedIdentity 'br:snd2cdoinfac1401.azurecr.io/bicep/modules/managed-identity.user-assigned-identities:0.4.6' = {
  name: '${uniqueString(deployment().name, location)}-test-${serviceShort}-ua-mi'
  params: {
    name: 'controlplaneId'
  }
}

@description('This is the built-in Contributor role. See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#contributor')
resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

// Contributor = b24988ac-6180-42a0-ab88-20f7382dd24c
resource miRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, deployManagedIdentity.name, contributorRoleDefinition.id)
  properties: {
    roleDefinitionId: contributorRoleDefinition.id
    principalId: deployManagedIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}



module assignRoleToManagedIdentity 'br:snd2cdoinfac1401.azurecr.io/bicep/modules/authorization.role-assignments:0.4.6' = {
  scope: managementGroup().
  name: '${uniqueString(deployment().name, location)}-test-${serviceShort}-mi-role-assign'
  params: {
    principalId: deployManagedIdentity.outputs.principalId
    roleDefinitionIdOrName: 'Contributor'
    principalType: 'ServicePrincipal'
    resourceGroupName: resourceGroup().name
    subscriptionId: subscription().id
  }
}


module deployNsg 'br:snd2cdoinfac1401.azurecr.io/bicep/modules/network.network-security-groups:0.4.6' = {
  name: '${uniqueString(deployment().name, location)}-test-${serviceShort}-nsg'
  params: {
    name: 'miClusterNsg'
  }
}

module deployRouteTable 'br:snd2cdoinfac1401.azurecr.io/bicep/modules/network.route-tables:0.4.6' = {
  name: '${uniqueString(deployment().name, location)}-test-${serviceShort}-rt'
  params: {
    name: 'miClusterRt'
  }
}

module deployNetwork 'br:snd2cdoinfac1401.azurecr.io/bicep/modules/network.virtual-networks:0.4.7' = {
  name: '${uniqueString(deployment().name, location)}-test-${serviceShort}-network'
  params: {
    enableDefaultTelemetry: enableDefaultTelemetry
    name: 'wiVnet'
    addressPrefixes: [
      '10.1.0.0/16'
    ]
    subnets: [
      {
        addressPrefix: '10.1.0.0/24'
        name: 'default'
        networkSecurityGroupId: deployNsg.outputs.resourceId
        routeTableId: deployRouteTable.outputs.resourceId
      }
    ]
    //roleAssignments: [
    //  {
    //    roleDefinitionIdOrName: 'Network Contributor'
    //    principalIds: [
    //      deployManagedIdentity.outputs.principalId
    //    ]
    //    principalType: 'ServicePrincipal'
    //  }
    //]
  }
}

/*
module deployPrivateDns 'br:snd2cdoinfac1401.azurecr.io/bicep/modules/network.private-dns-zones:0.5.6' = {
  name: '${uniqueString(deployment().name, location)}-test-${serviceShort}-private-dns'
  params: {
    name: 'cdocluster-sndaa.privatelink.uksouth.azmk8s.io'
    //roleAssignments: [
    //  {
    //    roleDefinitionIdOrName: 'Private DNS Zone Contributor'
    //    principalIds: [
    //      deployManagedIdentity.outputs.principalId
    //    ]
    //    principalType: 'ServicePrincipal'
    //  }
    //  {
    //    roleDefinitionIdOrName: 'Network Contributor'
    //    principalIds: [
    //      deployManagedIdentity.outputs.principalId
    //    ]
    //    principalType: 'ServicePrincipal'
    //  }
    //]
    virtualNetworkLinks: [
      {
        registrationEnabled: true
        virtualNetworkResourceId: deployNetwork.outputs.resourceId
      }
    ]
  }
}
*/

/*
// General resources
// =================
resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
}

resource controlPlaneManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  scope: resourceGroup
  name: 'controlplaneId'
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  scope: resourceGroup
  name: 'cdocluster-sndaa.privatelink.uksouth.azmk8s.io'
}

*/

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-02-01' existing = {
  scope: resourceGroup('SNDCDONETRG2401')
  name: 'SNDCDONETVN2401'

  resource subnet 'subnets@2023-02-01' existing = {
    name: 'SNDCDONETSU2407'
  }
}


module deployAKS '../../../../defra-adp-sandpit/ResourceModules/modules/container-service/managed-clusters/main.bicep' = {
  name: '${uniqueString(deployment().name, location)}-test-${serviceShort}-aks'
  params: {
    name: 'SNDCDOINFAKS2401'
    nodeResourceGroup: 'SNDCDOINFRG2402'
    enableDefaultTelemetry: enableDefaultTelemetry
    location: location
    enableRBAC: true
    disableLocalAccounts: true
    aadProfileManaged: true
    systemAssignedIdentity: true
    //userAssignedIdentities: {
    //  '${deployManagedIdentity.outputs.resourceId}': {}
    //}
    aksClusterNetworkPlugin: 'azure'
    aksClusterNetworkPluginMode: 'overlay'
    aksClusterNetworkPolicy: 'calico'
    aksClusterPodCidr: '172.16.0.0/16'
    aksClusterServiceCidr: '172.18.0.0/16'
    aksClusterDnsServiceIP: '172.18.255.250'
    primaryAgentPoolProfile: [
      {
        name: 'systempool'
        count: 1
        vmSize: 'Standard_DS2_v2'
        mode: 'System'
        vnetSubnetId: virtualNetwork::subnet.id
      }
    ]
    enableSecurityProfileWorkloadIdentity: true
    //azurePolicyEnabled: false // Also look at the "akspolicy".
    enableOidcIssuerProfile: true
    aadProfileAdminGroupObjectIDs: [
      'cdf149cd-7dd6-48b0-9d1f-6be074b424cc'
    ]
    enablePrivateCluster: true
    usePrivateDNSZone: true
    //privateDNSZoneResourceId: deployPrivateDns.outputs.resourceId

    agentPools: [
      {
        vnetSubnetId:  virtualNetwork::subnet.id
        availabilityZones: [
          '1'
        ]
        count: 2
        enableAutoScaling: true
        maxCount: 3
        maxPods: 30
        minCount: 1
        minPods: 2
        mode: 'User'
        name: 'userpool1'
        nodeLabels: {}
        nodeTaints: []
        osDiskSizeGB: 128
        osType: 'Linux'
        scaleSetEvictionPolicy: 'Delete'
        scaleSetPriority: 'Regular'
        storageProfile: 'ManagedDisks'
        type: 'VirtualMachineScaleSets'
        vmSize: 'Standard_DS2_v2'
      }
    ]
  }
}
