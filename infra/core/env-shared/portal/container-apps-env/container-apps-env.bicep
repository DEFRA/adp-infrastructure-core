@description('Required. The object of the Container App Env.')
param containerAppEnv object

@description('Required. The object of the Container App.')
param containerApp object

@description('Required. The object of Log Analytics Workspace.')
param workspace object

@description('Required. The object of Subnet.')
param subnet object

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. Environment name.')
param environment string

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

@description('Required. The name of the key vault where the secrets will be stored.')
param keyvaultName string

@description('Required. The name of the shared key vault where the app URL will be stored to be used by Front Door deployment')
param ssvPlatformKeyVaultName string

@description('Required. The name of the shared key vault Resource Group')
param ssvPlatformKeyVaultRG string

@description('Required. Object contains the Entra app details')
param portalEntraApp object

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}

var defaultTags = union(json(loadTextContent('../../../../common/default-tags.json')), customTags)

var additionalTags = {
  Name: containerAppEnv.name
  Purpose: 'Container App Env'
  Tier: 'Shared'
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: workspace.name
  scope: resourceGroup(workspace.subscriptionId, workspace.resourceGroup)
}

var internal = false
var infrastructureSubnetId = resourceId(subnet.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', subnet.vnetName, subnet.Name)
var dockerBridgeCidr = '172.16.0.1/28'
var workloadProfiles = containerAppEnv.workloadProfiles
var zoneRedundant = false
var infrastructureResourceGroupName = take('${containerAppEnv.name}_ME', 63)

module managedEnvironment 'br/SharedDefraRegistry:app.managed-environment:0.4.10' = {
  name: '${containerAppEnv.name}'
  params: {
    // Required parameters
    enableDefaultTelemetry: false
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.id
    name: '${containerAppEnv.name}'
    // Non-required parameters
    dockerBridgeCidr: !empty(infrastructureSubnetId) ? dockerBridgeCidr : null
    infrastructureSubnetId: !empty(infrastructureSubnetId) ? infrastructureSubnetId : null
    internal: internal
    location: location
    lock: {
      kind: 'CanNotDelete'
      name: '${containerAppEnv.name}-CanNotDelete'
    }
    workloadProfiles: !empty(workloadProfiles) ? workloadProfiles : null
    zoneRedundant: zoneRedundant
    infrastructureResourceGroupName: infrastructureResourceGroupName
    tags: union(defaultTags, additionalTags)
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyvaultName
}

module setKeyvaultSecret '.bicep/set-secret.bicep' = {
  name: 'PORTAL-APP-DEFAULT-URL'
  scope: resourceGroup(ssvPlatformKeyVaultRG)
  params: {
    ssvPlatformKeyVaultName: ssvPlatformKeyVaultName
    secretName: 'PORTAL-APP-DEFAULT-URL'
    secretValue: 'https://${containerApp.name}.${toLower(managedEnvironment.outputs.defaultDomain)}'
  }
}

resource secretbaseurl 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: 'APP-BASE-URL'
  parent: keyVault
  properties: {
    value: 'https://${containerApp.hostName}'
  }
}

resource tenantId 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: portalEntraApp.tenantIdSecretName
  parent: keyVault
  properties: {
    value: '${portalEntraApp.tenantIdSecretValue}'
  }
}

output appUrl string = 'https://${containerApp.name}.${toLower(managedEnvironment.outputs.defaultDomain)}'
