@description('Required. The parameter object for the virtual network. The object must contain the name,resourceGroup and subnetClusterNodes values.')
param vnet object

@description('Required. The parameter object for the cluster. The object must contain the name,skuTier,nodeResourceGroup,miControlPlane,adminAadGroupObjectId and monitoringWorkspace values.')
param cluster object

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
@description('Required. The parameter object for configuring flux with the aks cluster. The object must contain the clusterId, fluxInfraGitUrl and fluxAppsGitUrl values.')
param clusterFluxConfig object

var kubernetesVersion = '1.26.6'

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}
var tags = union(loadJsonContent('../default-tags.json'), customTags)

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

module miClusterControlPlane 'br/SharedDefraRegistry:managed-identity.user-assigned-identities:0.4.6' = {
  name: 'aks-cluster-mi-${deploymentDate}'
  params: {
    name: cluster.miControlPlane
    location: location
    lock: 'CanNotDelete'
    tags: union(tags, tagsMi)
  }
}

module deployAKS 'br/SharedDefraRegistry:container-service.managed-clusters:0.5.8-prerelease' = {
  name: 'aks-cluster-${deploymentDate}'
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
      '${miClusterControlPlane.outputs.resourceId}': {}
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
            syncIntervalInSeconds: 300
            timeoutInSeconds: 180
            url: clusterFluxConfig.fluxInfraGitUrl
          }
          kustomizations: {
            cluster: {
              path: './clusters/${environment}/${clusterFluxConfig.clusterId}'
              dependsOn: []
              timeoutInSeconds: 600
              syncIntervalInSeconds: 600
              validation: 'none'
              prune: true
            }
            // infra: {
            //   path: './infra/${environment}/${clusterFluxConfig.clusterId}'
            //   dependsOn: [ 
            //     // 'cluster' 
            //   ]
            //   timeoutInSeconds: 600
            //   syncIntervalInSeconds: 600
            //   validation: 'none'
            //   prune: true
            // }
          }
        }
        {
          namespace: 'flux-services'
          scope: 'cluster'
          gitRepository: {
            repositoryRef: {
              branch: 'main'
            }
            syncIntervalInSeconds: 300
            timeoutInSeconds: 180
            url: clusterFluxConfig.fluxAppsGitUrl
          }
          kustomizations: {
            apps: {
              path: './services/${environment}/${clusterFluxConfig.clusterId}'
              timeoutInSeconds: 600
              syncIntervalInSeconds: 600
              retryIntervalInSeconds: 120
              prune: true
            }
          }
        }
      ]
    }
  }
}
