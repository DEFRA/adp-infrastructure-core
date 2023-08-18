@description('Required. Cluster number to which the apps/core services need to be deployed to.')
param clusterId string
@description('Required. The parameter object for the cluster. The object must contain the name,skuTier,nodeResourceGroup,miControlPlane,adminAadGroupObjectId and monitoringWorkspace values.')
param cluster object
@description('Required. Environment name.')
param environment string
@description('Required. Flux git repo URL for infra/core services')
param fluxInfraGitUrl string
@description('Required. Flux git repo URL for application services')
param fluxAppsGitUrl string

resource aks 'Microsoft.ContainerService/managedClusters@2021-10-01' existing = {
  name: cluster.name
}

resource fluxExtension 'Microsoft.KubernetesConfiguration/extensions@2021-09-01' = {
  name: 'flux'
  scope: aks
  properties: {
    extensionType: 'Microsoft.Flux'
    autoUpgradeMinorVersion: true
    releaseTrain: 'Stable'
    scope: {
      cluster: {
        releaseNamespace: 'flux-system'
      }
    }
    configurationSettings: {
      'helm-controller.enabled': 'true'
      'source-controller.enabled': 'true'
      'kustomize-controller.enabled': 'true'
      'notification-controller.enabled': 'true'
      'image-automation-controller.enabled': 'false'
      'image-reflector-controller.enabled': 'false'
    }
  }
}

resource coreFluxConfig 'Microsoft.KubernetesConfiguration/fluxConfigurations@2021-11-01-preview' = {
  name: 'flux-core-services'
  scope: aks
  dependsOn: [
    fluxExtension
  ]
  properties: {
    scope: 'cluster'
    namespace: 'flux-core-services'
    sourceKind: 'GitRepository'
    suspend: false
    gitRepository: {
      // url: 'https://github.com/defra/adp-flux-infrastructure'
      url: fluxInfraGitUrl
      timeoutInSeconds: 600
      syncIntervalInSeconds: 600
      repositoryRef: {
        branch: 'main'
      }
    }
    kustomizations: {
      infra: {
        path: './core/${environment}/${clusterId}'
        dependsOn: []
        timeoutInSeconds: 600
        syncIntervalInSeconds: 600
        validation: 'none'
        prune: true
      }
    }
  }
}

resource appsFluxConfig 'Microsoft.KubernetesConfiguration/fluxConfigurations@2021-11-01-preview' = {
  name: 'flux-apps'
  scope: aks
  dependsOn: [
    fluxExtension
  ]
  properties: {
    scope: 'cluster'
    namespace: 'flux-core-services'
    sourceKind: 'GitRepository'
    suspend: false
    gitRepository: {
      // url: 'https://github.com/defra/adp-flux-applications'
      url: fluxAppsGitUrl
      timeoutInSeconds: 600
      syncIntervalInSeconds: 600
      repositoryRef: {
        branch: 'main'
      }
    }
    kustomizations: {
      apps: {
        path: './apps/${environment}/${clusterId}'
        dependsOn: [
          {
            kustomizationName: 'infra'
          }
        ]
        timeoutInSeconds: 600
        syncIntervalInSeconds: 600
        validation: 'none'
        prune: true
      }
    }
  }
}
