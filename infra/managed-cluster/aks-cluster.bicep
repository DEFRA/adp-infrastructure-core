@description('Required. The parameter object for the virtual network. The object must contain the name,resourceGroup and subnetClusterNodes values.')
param vnet object

@description('Required. The parameter object for the cluster. The object must contain the name,skuTier,nodeResourceGroup,miControlPlane,adminAadGroupObjectId and monitoringWorkspace values.')
param cluster object

@description('Required. The prefix for the private DNS zone.')
param privateDnsZonePrefix string

@allowed([
  'UKSouth'
])
@description('Required. The Azure region where the resources will be deployed.')
param location string
@description('Required. Environment name.')
param environment string
@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')
@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

var kubernetesVersion = '1.26.6'

var commonTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}
var tags = union(loadJsonContent('../default-tags.json'), commonTags)

var tagsMi = {
  Name: cluster.miControlPlane
  Purpose: 'Managed Identity'
  Tier: 'Security'
}

var aksTags = {
  Name: cluster.name
  Purpose: 'AKS Cluster'
  Tier: 'Shared'
}

module managedIdentity 'br/SharedDefraRegistry:managed-identity.user-assigned-identities:0.4.6' = {
  name: 'aks-cluster-mi-${deploymentDate}'
  params: {
    name: cluster.miControlPlane
    location: location
    lock: 'CanNotDelete'
    tags: union(tags, tagsMi)
  }
}

var privateDnsZoneName = '${privateDnsZonePrefix}.privatelink.${location}.azmk8s.io'

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
}

resource virtualNetwork 'Microsoft.ScVmm/virtualNetworks@2022-05-21-preview' existing = {
  name: vnet.name
}

resource privateDNSZoneVNetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${vnet.name}'
  location: 'global'
  parent: privateDnsZone
  properties: {
      registrationEnabled: true
      virtualNetwork: {
          id: virtualNetwork.id
      }
  }
}

resource msiVnetRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, 'NetworkContributor', managedIdentity.name)
  scope: virtualNetwork
  properties: {
      principalId: managedIdentity.outputs.principalId
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4d97b98b-1d4f-4787-a291-c67834d212e7') // Network Contributor
      principalType: 'ServicePrincipal'
  }
}

resource msiPrivDnsZoneRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, 'PrivateDNSZoneContributor', managedIdentity.name)
  scope: privateDnsZone
  properties: {
      principalId: managedIdentity.outputs.principalId
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b12aa53e-6015-4669-85d0-8515ebb3ae7f') // Private DNS Zone Contributor
      principalType: 'ServicePrincipal'
  }
}

module deployAKS 'br/SharedDefraRegistry:container-service.managed-clusters:0.5.8-prerelease' = {
  name: 'aks-cluster-${deploymentDate}'
  dependsOn: [
    managedIdentity
    privateDnsZone
    msiVnetRoleAssignment
    msiPrivDnsZoneRoleAssignment
  ]
  params: {
    name: cluster.name
    location: location
    lock: 'CanNotDelete'
    tags: union(tags, aksTags)
    aksClusterKubernetesVersion: kubernetesVersion
    nodeResourceGroup: cluster.nodeResourceGroup
    enableDefaultTelemetry: false
    omsAgentEnabled: true
    monitoringWorkspaceId: ''
    enableRBAC: true
    aadProfileManaged: true
    disableLocalAccounts: true
    systemAssignedIdentity: false
    userAssignedIdentities: {
      '${managedIdentity.outputs.resourceId}': {}
    }
    enableSecurityProfileWorkloadIdentity: true
    azurePolicyEnabled: true
    azurePolicyVersion: 'v2'
    enableOidcIssuerProfile: true
    aadProfileAdminGroupObjectIDs: array(cluster.adminAadGroupObjectId)
    enablePrivateCluster: true
    usePrivateDNSZone: true
    disableRunCommand: false
    enablePrivateClusterPublicFQDN: false
    aksClusterNetworkPlugin: 'azure'
    aksClusterNetworkPluginMode: 'overlay'
    aksClusterNetworkPolicy: 'calico'
    aksClusterPodCidr: '172.16.0.0/16'
    aksClusterServiceCidr: '172.18.0.0/16'
    aksClusterDnsServiceIP: '172.18.255.250'
    aksClusterDockerBridgeCidr: ''
    aksClusterLoadBalancerSku: 'standard'
    managedOutboundIPCount: 1
    aksClusterOutboundType: 'loadBalancer'
    aksClusterSkuTier: cluster.skuTier
    aksClusterSshPublicKey: ''
    aksServicePrincipalProfile: {}
    aadProfileClientAppID: ''
    aadProfileServerAppID: ''
    aadProfileServerAppSecret:''
    aadProfileTenantId: subscription().tenantId
    primaryAgentPoolProfile: [
      {
        name: 'npsystem'
        mode: 'System'
        count: cluster.npSystem.count
        vmSize: 'Standard_DS2_v2'
        osDiskSizeGB: cluster.npSystem.osDiskSizeGB
        osDiskType: 'Ephemeral'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        minCount: cluster.npSystem.minCount
        maxCount: cluster.npSystem.maxCount
        vnetSubnetId: resourceId(vnet.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnet.name, vnet.subnetClusterNodes)
        enableAutoScaling: true
        enableCustomCATrust: false
        enableFIPS: false
        enableEncryptionAtHost: false
        type: 'VirtualMachineScaleSets'
        scaleSetPriority: 'Regular'
        scaleSetEvictionPolicy: 'Delete'
        orchestratorVersion: kubernetesVersion
        enableNodePublicIP: false
        maxPods: cluster.npSystem.maxPods
        availabilityZones: cluster.npSystem.availabilityZones
        upgradeSettings: {
          maxSurge: '33%'
        }
        nodeTaints: [
          'CriticalAddonsOnly=true:NoSchedule'
        ]
      }
    ]
    agentPools: [
      {
        name: 'npuser01'
        mode: 'User'
        count: cluster.npUser.count
        vmSize: 'Standard_DS3_v2'
        osDiskSizeGB: cluster.npUser.osDiskSizeGB
        osDiskType: 'Ephemeral'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        minCount: cluster.npUser.minCount
        maxCount: cluster.npUser.maxCount
        vnetSubnetId: resourceId(vnet.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnet.name, vnet.subnetClusterNodes)
        enableAutoScaling: true
        enableCustomCATrust: false
        enableFIPS: false
        enableEncryptionAtHost: false
        type: 'VirtualMachineScaleSets'
        scaleSetPriority: 'Regular'
        scaleSetEvictionPolicy: 'Delete'
        orchestratorVersion: kubernetesVersion
        enableNodePublicIP: false
        maxPods: cluster.npUser.maxPods
        availabilityZones: cluster.npUser.availabilityZones
        upgradeSettings: {
          maxSurge: '33%'
        }
      }
    ]
    autoScalerProfileBalanceSimilarNodeGroups: 'false'
    autoScalerProfileExpander: 'random'
    autoScalerProfileMaxEmptyBulkDelete: '10'
    autoScalerProfileMaxGracefulTerminationSec: '600'
    autoScalerProfileMaxNodeProvisionTime: '15m'
    autoScalerProfileMaxTotalUnreadyPercentage: '45'
    autoScalerProfileNewPodScaleUpDelay: '0s'
    autoScalerProfileOkTotalUnreadyCount: '3'
    autoScalerProfileScaleDownDelayAfterAdd: '10m'
    autoScalerProfileScaleDownDelayAfterDelete: '20s'
    autoScalerProfileScaleDownDelayAfterFailure: '3m'
    autoScalerProfileScaleDownUnneededTime: '10m'
    autoScalerProfileScaleDownUnreadyTime: '20m'
    autoScalerProfileUtilizationThreshold: '0.5'
    autoScalerProfileScanInterval: '10s'
    autoScalerProfileSkipNodesWithLocalStorage: 'true'
    autoScalerProfileSkipNodesWithSystemPods: 'true'
  }
}
