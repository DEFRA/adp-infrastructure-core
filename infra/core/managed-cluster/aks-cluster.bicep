@description('Required. The parameter object for the virtual network. The object must contain the name,resourceGroup and subnetClusterNodes values.')
param vnet object
@description('Required. The parameter object for the cluster. The object must contain the name,skuTier,nodeResourceGroup,miControlPlane,adminAadGroupObjectId and monitoringWorkspace values.')
param cluster object
@description('Required. The parameter object for private dns zone. The object must contain the prefix and resourceGroup values')
param privateDnsZone object

@description('Required. The parameter object for the container registry. The object must contain the name, subscriptionId and resourceGroup values.')
param containerRegistries array
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
@description('Optional. The parameter object for the monitoringWorkspace. The object must contain name of the name and resourceGroup.')
param monitoringWorkspace object
@description('Required. Azure Service Operator managed identity name')
param asoPlatformManagedIdentity string
@description('Required. The parameter object for the app configuration service. The object must contain name, resourceGroup and managedIdentityName.')
param appConfig object

var commonTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}
var tags = union(loadJsonContent('../../common/default-tags.json'), commonTags)
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
var tagsAsoMi = {
  Name: asoPlatformManagedIdentity
  Purpose: 'ADP Platform Azure Service Operator Managed Identity'
  Tier: 'Shared'
}
var tagsAppConfigMi = {
  Name: appConfig.managedIdentityName
  Purpose: 'ADP Platform App Configuration Service Managed Identity'
  Tier: 'Shared'
}

var privateDnsZoneName = toLower('${privateDnsZone.prefix}.privatelink.${location}.azmk8s.io')

var asoPlatformTeamMiRbacs = [
  {
    name: 'Contributor'
    roleDefinitionId: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  }
  {
    name: 'UserAccessAdministrator'
    roleDefinitionId: '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9'
  }
]

var systemNodePool = {
  name: 'npsystem01'
  mode: 'System'
  count: cluster.npSystem.count
  vmSize: 'Standard_DS3_v2'
  osDiskSizeGB: cluster.npSystem.osDiskSizeGB
  osDiskType: 'Ephemeral'
  osType: 'Linux'
  osSKU: 'Ubuntu'
  minCount: cluster.npSystem.minCount
  maxCount: cluster.npSystem.maxCount
  vnetSubnetId: resourceId(vnet.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnet.name, vnet.subnet02Name)
  enableAutoScaling: true
  enableCustomCATrust: false
  enableFIPS: false
  enableEncryptionAtHost: false
  type: 'VirtualMachineScaleSets'
  scaleSetPriority: 'Regular'
  scaleSetEvictionPolicy: 'Delete'
  enableNodePublicIP: false
  maxPods: cluster.npSystem.maxPods
  availabilityZones: cluster.npSystem.availabilityZones
  upgradeSettings: {
    maxSurge: '33%'
  }
  nodeTaints: [
    'CriticalAddonsOnly=true:NoSchedule'
  ]
  nodeLabels: {
    Ingress:'true'
  }
}

module managedIdentity 'br/SharedDefraRegistry:managed-identity.user-assigned-identity:0.4.3' = {
  name: 'aks-cluster-mi-${deploymentDate}'
  params: {
    name: cluster.miControlPlane
    location: location
    lock: 'CanNotDelete'
    tags: union(tags, tagsMi)
  }
}

module managedIdentityAppConfig 'br/SharedDefraRegistry:managed-identity.user-assigned-identity:0.4.3' = {
  name: 'appconfig-mi-${deploymentDate}'
  params: {
    name: appConfig.managedIdentityName
    location: location
    lock: 'CanNotDelete'
    tags: union(tags, tagsAppConfigMi)
    federatedIdentityCredentials: [
      {
        name: appConfig.managedIdentityName
        audiences: [
          'api://AzureADTokenExchange'
        ]
        issuer: deployAKS.outputs.oidcIssuerUrl
        subject: 'system:serviceaccount:app-config-service:az-appconfig-k8s-provider'
      }
    ]
  }
}

module managedIdentityAso 'br/SharedDefraRegistry:managed-identity.user-assigned-identity:0.4.3' = {
  name: 'aso-managed-identity-${deploymentDate}'
  params: {
    name: asoPlatformManagedIdentity
    tags: union(tags, tagsAsoMi)
    location: location
    lock: 'CanNotDelete'
    federatedIdentityCredentials: [
      {
        name: asoPlatformManagedIdentity
        audiences: [
          'api://AzureADTokenExchange'
        ]
        issuer: deployAKS.outputs.oidcIssuerUrl
        subject: 'system:serviceaccount:azureserviceoperator-system:azureserviceoperator-default'
      }
    ]
  }
}

module asoPlatformTeamMiRbacSubscriptionPermissions '.bicep/subscription-rbac.bicep' = [for asoPlatformTeamMiRbac in asoPlatformTeamMiRbacs: {
  name: 'subscription-${asoPlatformTeamMiRbac.name}-${deploymentDate}'
  scope: subscription()
  dependsOn: [
    managedIdentityAso
  ]
  params: {
    principalId: managedIdentityAso.outputs.principalId
    roleDefinitionId: asoPlatformTeamMiRbac.roleDefinitionId
  }
}]

module privateDnsZoneContributor '.bicep/private-dns-zone-contributor.bicep' = {
  name: 'aks-cluster-private-dns-zone-contributor-${deploymentDate}'
  scope: resourceGroup(privateDnsZone.resourceGroup)
  dependsOn: [
    managedIdentity
  ]
  params: {
    managedIdentity: {
      name: cluster.miControlPlane
      principalId: managedIdentity.outputs.principalId
    }
    privateDnsZoneName: privateDnsZoneName
  }
}

module networkContributor '.bicep/network-contributor.bicep' = {
  name: 'aks-cluster-network-contributor-${deploymentDate}'
  scope: resourceGroup(vnet.resourceGroup)
  dependsOn: [
    managedIdentity
  ]
  params: {
    managedIdentity: {
      name: cluster.miControlPlane
      principalId: managedIdentity.outputs.principalId
    }
    vnetName: vnet.name
  }
}

module deployAKS 'br/SharedDefraRegistry:container-service.managed-cluster:0.5.3' = {
  name: 'aks-cluster-${deploymentDate}'
  dependsOn: [
    privateDnsZoneContributor
    networkContributor
  ]
  params: {
    name: cluster.name
    location: location
    lock: 'CanNotDelete'
    tags: union(tags, aksTags)
    kubernetesVersion: cluster.kubernetesVersion
    nodeResourceGroup: cluster.nodeResourceGroup
    enableDefaultTelemetry: false
    omsAgentEnabled: true
    monitoringWorkspaceId: resourceId(monitoringWorkspace.resourceGroup, 'Microsoft.OperationalInsights/workspaces', monitoringWorkspace.name)
    enableRBAC: true
    aadProfileManaged: true
    disableLocalAccounts: true
    systemAssignedIdentity: false
    userAssignedIdentities: {
      '${managedIdentity.outputs.resourceId}': {}
    }
    enableWorkloadIdentity: true
    azurePolicyEnabled: true
    azurePolicyVersion: 'v2'
    enableOidcIssuerProfile: true
    aadProfileAdminGroupObjectIDs: array(cluster.adminAadGroupObjectId)
    enablePrivateCluster: true
    privateDNSZone: privateDnsZoneContributor.outputs.privateDnsZoneResourceId
    disableRunCommand: false
    enablePrivateClusterPublicFQDN: false
    networkPlugin: 'azure'
    networkPluginMode: 'overlay'
    networkPolicy: 'calico'
    podCidr: cluster.podCidr
    serviceCidr: cluster.serviceCidr
    dnsServiceIP: cluster.dnsServiceIp
    loadBalancerSku: 'standard'
    managedOutboundIPCount: 0
    outboundType: 'userDefinedRouting'
    skuTier: cluster.skuTier
    sshPublicKey: ''
    aksServicePrincipalProfile: {}
    aadProfileClientAppID: ''
    aadProfileServerAppID: ''
    aadProfileServerAppSecret: ''
    aadProfileTenantId: subscription().tenantId
    primaryAgentPoolProfile: [
      systemNodePool
    ]
    agentPools: [
      union(systemNodePool, { orchestratorVersion: cluster.kubernetesVersion })
      {
        name: 'npuser01shd'
        mode: 'User'
        count: cluster.npUser.count
        vmSize: 'Standard_DS3_v2'
        osDiskSizeGB: cluster.npUser.osDiskSizeGB
        osDiskType: 'Ephemeral'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        minCount: cluster.npUser.minCount
        maxCount: cluster.npUser.maxCount
        vnetSubnetId: resourceId(vnet.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnet.name, vnet.subnet03Name)
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

  }
}

module fluxExtensionResource 'br/SharedDefraRegistry:kubernetes-configuration.extension:0.4.4-prerelease' = {
  name: 'flux-extension-${deploymentDate}'
  params: {
    clusterName: cluster.name
    extensionType: 'microsoft.flux'
    name: 'flux'
    location: location
    releaseTrain: 'Stable'
    releaseNamespace: 'flux-system'
    configurationSettings: {
      'helm-controller.enabled': 'true'
      'source-controller.enabled': 'true'
      'kustomize-controller.enabled': 'true'
      'notification-controller.enabled': 'true'
      'image-automation-controller.enabled': 'true'
      'image-reflector-controller.enabled': 'true'
      'helm-controller.detectDrift': 'true'
      'useKubeletIdentity': 'true'
    }
    fluxConfigurations: [
      {
        name: 'flux-config'
        namespace: 'flux-config'
        scope: 'cluster'
        gitRepository: {
          repositoryRef: {
            branch: fluxConfig.clusterCore.gitRepository.branch
          }
          syncIntervalInSeconds: fluxConfig.clusterCore.gitRepository.syncIntervalInSeconds
          timeoutInSeconds: fluxConfig.clusterCore.gitRepository.timeoutInSeconds
          url: fluxConfig.clusterCore.gitRepository.url
        }
        kustomizations: {
          cluster: {
            path: fluxConfig.clusterCore.kustomizations.clusterPath
            dependsOn: []
            timeoutInSeconds: fluxConfig.clusterCore.kustomizations.timeoutInSeconds
            syncIntervalInSeconds: fluxConfig.clusterCore.kustomizations.syncIntervalInSeconds
            validation: 'none'
            prune: true
          }
          infra: {
            path: fluxConfig.clusterCore.kustomizations.infraPath
            timeoutInSeconds: fluxConfig.clusterCore.kustomizations.timeoutInSeconds
            syncIntervalInSeconds: fluxConfig.clusterCore.kustomizations.syncIntervalInSeconds
            dependsOn: [
              'cluster'
            ]
            validation: 'none'
            prune: true
            postBuild: {
              substitute: {
                ASO_MI_CLIENTID: managedIdentityAso.outputs.clientId
                SUBSCRIPTION_ID: subscription().subscriptionId
                TENANT_ID: tenant().tenantId
                LOAD_BALANCER_SUBNET: vnet.subnet01Name
                SHARED_CONTAINER_REGISTRY: containerRegistries[0].name
              }
            }
          }
          services: {
            path: fluxConfig.clusterCore.kustomizations.servicesPath
            timeoutInSeconds: fluxConfig.clusterCore.kustomizations.timeoutInSeconds
            syncIntervalInSeconds: fluxConfig.clusterCore.kustomizations.syncIntervalInSeconds
            dependsOn: [
              'cluster'
              'infra'
            ]
            validation: 'none'
            prune: true
            postBuild: {
              substitute: {
                APPCONFIG_NAME: appConfig.name
                APPCONFIG_MI_CLIENTID: managedIdentityAppConfig.outputs.clientId
              }
            }
          }
        }
      }
    ]
  }
}

module sharedAcrPullRoleAssignment '.bicep/acr-pull.bicep' = [for containerRegistry in containerRegistries: {
  name: '${containerRegistry.name}-acr-pull-role-${deploymentDate}'
  scope: resourceGroup(containerRegistry.subscriptionId, containerRegistry.resourceGroup)
  dependsOn: [
    deployAKS
  ]
  params: {
    principalId: deployAKS.outputs.kubeletidentityObjectId
    containerRegistryName: containerRegistry.name
  }
}]

module appConfigurationDataReaderRoleAssignment '.bicep/app-config-data-reader.bicep' = {
  name: 'app-config-data-reader-role-assignment-${deploymentDate}'
  scope: resourceGroup(appConfig.resourceGroup)
  dependsOn: [
    deployAKS
  ]
  params: {
    principalId: managedIdentityAppConfig.outputs.principalId
    appConfigName: appConfig.name
  }
}

output configuration array = [
  {
    name: 'CLUSTER_OIDC'
    value: deployAKS.outputs.oidcIssuerUrl
    label: 'Platform'
  }
]
