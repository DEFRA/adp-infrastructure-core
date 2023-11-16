using './aks-cluster.bicep'
/*
param initializeOrRotateKmsKey = '#{{ InitializeOrRotateKmsKey }}'

param keyVault = {
  resourceGroup: 'SNDADPINFRG1401'
  keyVaultName: 'SNDADPINFVT1402'
}

param vnet = {
  name: 'SNDADPNETVN1401'
  resourceGroup: 'SNDADPNETRG1401'
  subnet01Name: ''
  subnet02Name: 'SNDADPNETSU1402-AA-KMS'
  subnet03Name: 'SNDADPNETSU1403-AA-KMS'
}

param cluster = {
  name: 'SNDADPINFAK1401-Test'
  kubernetesVersion: '1.27.3'
  skuTier: 'Free'
  nodeResourceGroup: 'SNDADPINFRG1401-Test-Managed'
  miControlPlane: 'SNDADPINFMI1401-Test-cluster-control-plane'
  adminAadGroupObjectId: 'cdf149cd-7dd6-48b0-9d1f-6be074b424cc'
  podCidr: '172.16.0.0/16'
  serviceCidr: '172.18.0.0/16'
  dnsServiceIp: '172.18.255.250'
  npSystem: {
    count: 2
    osDiskSizeGB: 80
    maxCount: 4
    minCount: 1
    maxPods: 80
    availabilityZones: [
      '1'
      '2'
      '3'
    ]
  }
  npUser: {
    count: 2
    osDiskSizeGB: 128
    maxCount: 10
    minCount: 2
    maxPods: 80
    minPods: 2
    availabilityZones: [
      '1'
      '2'
      '3'
    ]
  }
}

param privateDnsZone = {
  prefix: 'SNDADPDNSDZ1401'
  resourceGroup: 'SNDADPDNSRG1401'
}

param containerRegistries = [
  {
    name: 'SSVADPINFCR3401'
    resourceGroup: 'SSVADPINFRG3401'
    subscriptionId: '7dc5bbdf-72d7-42ca-ac23-eb5eea3764b4'
  }
  {
    name: 'SNDADPINFCR1401'
    resourceGroup: 'SNDADPINFRG1401'
    subscriptionId: '55f3b8c6-6800-41c7-a40d-2adb5e4e1bd1'
  }
]

param location = 'UKSouth'

param environment = 'SND'

param monitoringWorkspace = {
  name: 'SNDADPINFLW1401'
  resourceGroup: 'SNDADPINFRG1401'
}

// param fluxConfig = {
//   clusterCore: {
//     gitRepository: {
//       syncIntervalInSeconds: 300
//       timeoutInSeconds: 180
//       url: 'https://github.com/DEFRA/adp-flux-core'
//       branch: 'features/platform-config-map'
//     }
//     kustomizations: {
//       timeoutInSeconds: 600
//       syncIntervalInSeconds: 600
//       clusterPath: './clusters/snd/01'
//       infraPath: './infra/snd/01'
//       servicesPath: './services/snd/01'
//     }
//   }
// }

param asoPlatformManagedIdentity = 'SNDADPINFMI1401-Test-adp-aso-platform'

param appConfig = {
  name: 'sndadpinfac1401'
  resourceGroup: 'SNDADPINFRG1401'
  managedIdentityName: 'SNDADPINFMI1401-Test-adp-ac-platform'
}
*/
