/*
using './aks-cluster.bicep'

param vnet = {
  name: '#{{ virtualNetworkName }}'
  resourceGroup: '#{{ virtualNetworkResourceGroup }}'
  subnet01Name: '#{{ networkResourceNamePrefix }}#{{ nc_resource_subnet }}#{{ nc_instance_regionid }}01'
  subnet02Name: '#{{ networkResourceNamePrefix }}#{{ nc_resource_subnet }}#{{ nc_instance_regionid }}98'
  subnet03Name: '#{{ networkResourceNamePrefix }}#{{ nc_resource_subnet }}#{{ nc_instance_regionid }}03'
}

param cluster = {
  name: '#{{ infraResourceNamePrefix }}#{{ nc_resource_kubernetesservice }}#{{ nc_instance_regionid }}01'
  kubernetesVersion: '#{{ aksVersion }}'
  skuTier: '#{{ aksClusterSkuTier }}'
  nodeResourceGroup: '#{{ aksResourceGroup }}-Managed'
  miControlPlane: '#{{ aksControlPlaneManagedIdentity }}'
  adminAadGroupObjectId: '#{{ aksAADProfileAdminGroupObjectId }}'
  podCidr: '#{{ aksClusterPodCidr }}'
  serviceCidr: '#{{ aksClusterServiceCidr }}'
  dnsServiceIp: '#{{ aksClusterDnsServiceIp }}'
  npSystem: {
    count: 2
    osDiskSizeGB: 80
    maxCount: 4
    minCount: 1
    maxPods: 110
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
    maxPods: 110
    minPods: 2
    availabilityZones: [
      '1'
      '2'
      '3'
    ]
  }
}

param privateDnsZone = {
  prefix: '#{{ dnsResourceNamePrefix }}#{{ nc_resource_dnszone }}#{{ nc_instance_regionid }}01'
  resourceGroup: '#{{ dnsResourceGroup }}'
}

param containerRegistries = [
  {
    name: '#{{ ssvSharedAcrName }}'
    resourceGroup: '#{{ ssvSharedResourceGroup }}'
    subscriptionId: '#{{ ssvSubscriptionId }}'
  }
  {
    name: '#{{ infraResourceNamePrefix }}#{{ nc_resource_containerregistry }}#{{ nc_instance_regionid }}01'
    resourceGroup: '#{{ servicesResourceGroup }}'
    subscriptionId: '#{{ subscriptionId }}'
  }
]

param location = '#{{ location }}'

param environment = '#{{ environment }}'

param monitoringWorkspace = {
  name: '#{{ logAnalyticsWorkspace }}'
  resourceGroup: '#{{ servicesResourceGroup }}'
}

param fluxConfig = {
  clusterCore: {
    gitRepository: {
      syncIntervalInSeconds: 300
      timeoutInSeconds: 180
      url: 'https://github.com/DEFRA/adp-flux-core'
      branch: 'main'
    }
    kustomizations: {
      timeoutInSeconds: 600
      syncIntervalInSeconds: 600
      clusterPath: './clusters/#{{ lower(environment) }}/0#{{ environmentId }}'
      infraPath: './infra/#{{ lower(environment) }}/0#{{ environmentId }}'
      servicesPath: './services/#{{ lower(environment) }}/0#{{ environmentId }}'
    }
  }
}

param asoPlatformManagedIdentity = '#{{ infraResourceNamePrefix }}#{{ nc_resource_managedidentity }}#{{ nc_instance_regionid }}01-adp-aso-platform'

param appConfig = {
  name: '#{{ infraResourceNamePrefix }}#{{ nc_resource_appconfiguration }}#{{ nc_instance_regionid }}01'
  resourceGroup: '#{{ servicesResourceGroup }}'
  managedIdentityName: '#{{ infraResourceNamePrefix }}#{{ nc_resource_managedidentity }}#{{ nc_instance_regionid }}01-adp-ac-platform'
}

param aksKmsKeyName = 'aksKmsKey'

param keyVault = {
  resourceGroup: 'SNDADPINFRG1401'
  keyVaultName: 'SNDADPINFVT1401AAKMS'
}
*/
