
param vnet object = {
  name: 'SNDCDONETVN2401'
  resourceGroup: 'SNDCDONETRG2401'
  subnetClusterNodes: 'SNDCDONETSU2407'
}

param cluster object = {
  name: 'SNDCDOINFAK2401'
  nodeResourceGroup: 'SNDCDOINFRG2402'
  miControlPlane: 'SNDCDOINFMI2401'
  adminAadGroupObjectId: 'cdf149cd-7dd6-48b0-9d1f-6be074b424cc'
  monitoringWorkspace: {
    name: ''
    resourceGroup: ''
  }
}

@allowed([
  'uksouth'
])
param location string = 'uksouth'

@description('Required. Environment name.')
param environment string
param createdDate string = utcNow('yyyy-MM-dd')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')


resource vnetResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  scope: subscription()
  name: vnet.resourceGroup
}

resource clusterVirtualNetwork 'Microsoft.Network/virtualNetworks@2023-02-01' existing = {
  scope: vnetResourceGroup
  name: vnet.name

  resource clusterNodesSubnet 'subnets@2023-02-01' existing = {
    name: vnet.subnetClusterNodes
  }
}

//resource monitoringWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
//  scope: resourceGroup(cluster.monitoringWorkspace.resourceGroup)
//  name: cluster.monitoringWorkspace.name
//}

var kubernetesVersion = '1.26.6'

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment

}
var tags = union(loadJsonContent('../default-tags.json'), customTags)

var tagsMi = {
  Name : cluster.miControlPlane
  Purpose: 'Managed Identity'
  Tier:'Security'
}

var aksTags = {
  Name : cluster.name
  Purpose: 'AKS Cluster'
  Tier:'Shared Cluster'
}

module miClusterControlPlane 'br/SharedDefraRegistry:managed-identity.user-assigned-identities:0.4.6' = {
  name: 'aks-cluster-mi-${deploymentDate}'
  params: {
    name: cluster.miControlPlane
    location: location
    lock: 'CanNotDelete'
    tags: union(tags,tagsMi)
  }
}

module deployAKS '../../../../defra-adp-sandpit/ResourceModules/modules/container-service/managed-clusters/main.bicep' = {
  name: 'aks-cluster-${deploymentDate}'
  params: {
    name: cluster.name
    location: location
    lock: 'CanNotDelete'
    tags: union(tags,aksTags)
    aksClusterKubernetesVersion: kubernetesVersion
    nodeResourceGroup: cluster.nodeResourceGroup
    enableDefaultTelemetry: true
    omsAgentEnabled: true
    monitoringWorkspaceId: '' //monitoringWorkspace.id
    enableRBAC: true
    aadProfileManaged: true
    disableLocalAccounts: true
    userAssignedIdentities: {
      '${miClusterControlPlane.outputs.resourceId}': {}
    }
    enableSecurityProfileWorkloadIdentity: true
    azurePolicyEnabled: true
    azurePolicyVersion: 'v2'
    enableOidcIssuerProfile: true
    aadProfileAdminGroupObjectIDs: array(cluster.adminAadGroupObjectId)
    enablePrivateCluster: true
    usePrivateDNSZone: true
    aksClusterNetworkPlugin: 'azure'
    aksClusterNetworkPluginMode: 'overlay'
    aksClusterNetworkPolicy: 'calico'
    aksClusterPodCidr: '172.16.0.0/16'
    aksClusterServiceCidr: '172.18.0.0/16'
    aksClusterDnsServiceIP: '172.18.255.250'
    aksClusterLoadBalancerSku: 'standard'
    aksClusterOutboundType: 'loadBalancer'
    primaryAgentPoolProfile: [
      {
        name: 'npsystem'
        mode: 'System'
        count: 1
        vmSize: 'Standard_DS2_v2'
        type: 'VirtualMachineScaleSets'
        osDiskSizeGB: 80
        osDiskType: 'Ephemeral'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        nodeTaints: [
          'CriticalAddonsOnly=true:NoSchedule'
        ]
        orchestratorVersion: kubernetesVersion
        enableNodePublicIP: false
        vnetSubnetId: clusterVirtualNetwork::clusterNodesSubnet.id
        availabilityZones: [
          '1'
        ]
      }
    ]
    agentPools: [
      {
        name: 'npuser1'
        mode: 'User'
        count: 2
        vmSize: 'Standard_DS3_v2'
        type: 'VirtualMachineScaleSets'
        osDiskSizeGB: 128
        osDiskType: 'Ephemeral'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        orchestratorVersion: kubernetesVersion
        enableNodePublicIP: false
        enableAutoScaling: true
        upgradeSettings: {
          maxSurge: '33%'
        }
        maxCount: 3
        maxPods: 30
        minCount: 1
        minPods: 2
        nodeLabels: {}
        scaleSetEvictionPolicy: 'Delete'
        scaleSetPriority: 'Regular'
        storageProfile: 'ManagedDisks'
        vnetSubnetId: clusterVirtualNetwork::clusterNodesSubnet.id
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
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
