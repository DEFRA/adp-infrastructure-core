@description('Required. The parameter object for the virtual network. The object must contain the name,resourceGroup and subnetClusterNodes values.')
param vnet object
@description('Required. The parameter object for the cluster. The object must contain the name,skuTier,nodeResourceGroup,miControlPlane,adminAadGroupObjectId and monitoringWorkspace values.')
param cluster object
@description('Required. The prefix for the private DNS zone.')
param privateDnsZone object
@description('Required. The Name of the Azure Monitor Workspace.')
param azureMonitorWorkspaceName string
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
@description('Required. The parameter object for configuring flux with the aks cluster. The object must contain the fluxCore  and fluxServices values.')
param fluxConfig object
@description('Optional. Resource ID of the monitoringWorkspace.')
param monitoringWorkspaceId object

var commonTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}
var tags = union(loadJsonContent('../default-tags.json'), commonTags)
var tagsMi = {
  Name: cluster.miControlPlane
  Purpose: 'AKS Control Plane Managed Identity'
  Tier: 'Security'
}
var aksTags = {
  Name: cluster.name
  Purpose: 'AKS Cluster'
  Tier: 'Shared'
}
var pdnsTags = {
  Name: privateDnsZoneName
  Purpose: 'AKS Private DNS Zone'
}
var pdnsVnetLinksTags = {
  Name: vnet.name
  Purpose: 'AKS Private DNS Zone VNet Link'
}
var privateDnsZoneName = toLower('${privateDnsZone.prefix}.privatelink.${location}.azmk8s.io')

var azureMonitorWorkspaceTags = {
  Name: azureMonitorWorkspaceName
  Purpose: 'Azure Monitor Workspace'
}

resource azureMonitorWorkSpaceResource 'Microsoft.Monitor/accounts@2023-04-03' = {
  location: location
  name: azureMonitorWorkspaceName
  tags: azureMonitorWorkspaceTags
}

module managedIdentityModule 'br/SharedDefraRegistry:managed-identity.user-assigned-identities:0.4.6' = {
  name: 'aks-cluster-mi-${deploymentDate}'
  params: {
    name: cluster.miControlPlane
    location: location
    lock: 'CanNotDelete'
    tags: union(tags, tagsMi)
  }
}

module privateDnsZoneModule 'br/SharedDefraRegistry:network.private-dns-zones:0.5.7' = {
  name: 'aks-private-dns-zone-${deploymentDate}'
  dependsOn: [
    managedIdentityModule
  ]
  params: {
   name: privateDnsZoneName
   lock: 'CanNotDelete'
   tags: union(tags, pdnsTags)
   roleAssignments: [
    {
      roleDefinitionIdOrName: 'Private DNS Zone Contributor'
      principalIds: [
        managedIdentityModule.outputs.principalId
      ]
      principalType: 'ServicePrincipal'
    }
   ]
   virtualNetworkLinks: [
    {
      name: vnet.name
      virtualNetworkResourceId: resourceId(vnet.resourceGroup, 'Microsoft.Network/virtualNetworks', vnet.name)
      registrationEnabled: true
      tags: union(tags, pdnsVnetLinksTags)
    }
   ]
  }
}

module networkContributorModule '.bicep/network-contributor.bicep' = {
  name: 'aks-cluster-network-contributor-${deploymentDate}'
  scope: resourceGroup(vnet.resourceGroup)
  dependsOn: [
    privateDnsZoneModule
  ]
  params: {
    managedIdentity: {
      name: cluster.miControlPlane
      principalId: managedIdentityModule.outputs.principalId
    }
    vnetName: vnet.name
  }
}

module deployAKS 'br/SharedDefraRegistry:container-service.managed-clusters:0.5.13-prerelease' = {
  name: 'aks-cluster-${deploymentDate}'
  dependsOn: [
    networkContributorModule
  ]
  params: {
    name: cluster.name
    location: location
    lock: 'CanNotDelete'
    tags: union(tags, aksTags)
    aksClusterKubernetesVersion: cluster.kubernetesVersion
    nodeResourceGroup: cluster.nodeResourceGroup
    enableDefaultTelemetry: false
    omsAgentEnabled: true
    monitoringWorkspaceId: resourceId(monitoringWorkspaceId.resourceGroup, 'Microsoft.OperationalInsights/workspaces', monitoringWorkspaceId.name) 
    enableRBAC: true
    aadProfileManaged: true
    disableLocalAccounts: true
    systemAssignedIdentity: false
    userAssignedIdentities: {
      '${managedIdentityModule.outputs.resourceId}': {}
    }
    enableSecurityProfileWorkloadIdentity: true
    azurePolicyEnabled: true
    azurePolicyVersion: 'v2'
    enableOidcIssuerProfile: true
    aadProfileAdminGroupObjectIDs: array(cluster.adminAadGroupObjectId)
    enablePrivateCluster: true
    privateDNSZone: privateDnsZoneModule.outputs.resourceId
    disableRunCommand: false
    enablePrivateClusterPublicFQDN: false
    aksClusterNetworkPlugin: 'azure'
    aksClusterNetworkPluginMode: 'overlay'
    aksClusterNetworkPolicy: 'calico'
    aksClusterPodCidr: '172.16.0.0/16'
    aksClusterServiceCidr: '172.18.0.0/16'
    aksClusterDnsServiceIP: '172.18.255.250'
    aksClusterLoadBalancerSku: 'standard'
    managedOutboundIPCount: 1
    aksClusterOutboundType: 'loadBalancer'
    aksClusterSkuTier: cluster.skuTier
    aksClusterSshPublicKey: ''
    aksServicePrincipalProfile: {}
    aadProfileClientAppID: ''
    aadProfileServerAppID: ''
    aadProfileServerAppSecret: ''
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
        orchestratorVersion: cluster.kubernetesVersion
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
        orchestratorVersion: cluster.kubernetesVersion
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

    fluxExtension: {
      autoUpgradeMinorVersion: true
      releaseTrain: 'Stable'
      configurationSettings: {
        'helm-controller.enabled': 'true'
        'source-controller.enabled': 'true'
        'kustomize-controller.enabled': 'true'
        'notification-controller.enabled': 'true'
        'image-automation-controller.enabled': 'false'
        'image-reflector-controller.enabled': 'false'
      }
      configurations: [
        {
          namespace: 'flux-core'
          scope: 'cluster'
          gitRepository: {
            repositoryRef: {
              branch: 'main'
            }
            syncIntervalInSeconds: fluxConfig.fluxCore.gitRepository.syncIntervalInSeconds
            timeoutInSeconds: fluxConfig.fluxCore.gitRepository.timeoutInSeconds
            url: fluxConfig.fluxCore.gitRepository.url
          }
          kustomizations: {
            cluster: {
              path: fluxConfig.fluxCore.kustomizations.clusterPath
              dependsOn: []
              timeoutInSeconds: fluxConfig.fluxCore.kustomizations.timeoutInSeconds
              syncIntervalInSeconds: fluxConfig.fluxCore.kustomizations.syncIntervalInSeconds
              validation: 'none'
              prune: true
            }
            infra: {
              path: fluxConfig.fluxCore.kustomizations.infraPath
              dependsOn: [
                'cluster'
              ]
              timeoutInSeconds: fluxConfig.fluxCore.kustomizations.timeoutInSeconds
              syncIntervalInSeconds: fluxConfig.fluxCore.kustomizations.syncIntervalInSeconds
              validation: 'none'
              prune: true
            }
          }
        }
        {
          namespace: 'flux-services'
          scope: 'cluster'
          gitRepository: {
            repositoryRef: {
              branch: 'main'
            }
            syncIntervalInSeconds: fluxConfig.fluxServices.gitRepository.syncIntervalInSeconds
            timeoutInSeconds: fluxConfig.fluxServices.gitRepository.timeoutInSeconds
            url: fluxConfig.fluxServices.gitRepository.url
          }
          kustomizations: {
            apps: {
              path: fluxConfig.fluxServices.kustomizations.appsPath
              timeoutInSeconds: fluxConfig.fluxServices.kustomizations.timeoutInSeconds
              syncIntervalInSeconds: fluxConfig.fluxServices.kustomizations.syncIntervalInSeconds
              retryIntervalInSeconds: fluxConfig.fluxServices.kustomizations.retryIntervalInSeconds
              prune: true
            }
          }
        }
      ]
    }
  }
}
