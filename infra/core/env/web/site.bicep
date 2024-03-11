@description('Required. The parameter object for the virtual network. The object must contain the name,resourceGroup, subnetFunctionApp and subnetPrivateEndpoints values.')
param vnet object

@description('Required. The parameter object for the App Service storage account. The object must contain name and fileShareName')
param storageAccount object

@description('Required. The parameter object for the App Service. The object must contain the name, planName, planSku.name, planSku.tier and managedIdentityName.')
param appService object

@description('Required. Application Insights name.')
param applicationInsightsName string

@description('Required. Platform KeyVault name.')
param platformKeyVaultName string

@description('Required. Environment name.')
param environment string

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

@description('Optional. The Azure region where the resources will be deployed.')
param location string = resourceGroup().location

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}
var tags = union(loadJsonContent('../../../common/default-tags.json'), customTags)

var appServiceTags = {
  Name: appService.name
  Purpose: 'ADP Core App Service'
  Tier: 'Shared'
}

var tagsMi = {
  Name: appService.managedIdentityName
  Purpose: 'Function App Managed Identity'
  Tier: 'Security'
}

var keyVaultSecretUri = '@Microsoft.KeyVault(SecretUri=${storageAccount.deploymentTriggerStorageConnectionString}/)'
var keyVaultSecretOfficerRoleDefinitionID = 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'

resource applicationInsightsResource 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

resource storageAccountResource 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccount.name
}

resource keyVaultResource 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: platformKeyVaultName
}

resource secretResource 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVaultResource
  name: storageAccount.deploymentTriggerStorageConnectionStringSecretName
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccountResource.id,'2022-05-01').keys[0].value}'
  }
}

module managedIdentity 'br/SharedDefraRegistry:managed-identity.user-assigned-identity:0.4.3' = {
  name: 'function-app-mi-${deploymentDate}'
  params: {
    name: appService.managedIdentityName
    location: location
    lock: 'CanNotDelete'
    tags: union(tags, tagsMi)
  }
}

resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, appService.managedIdentityName, keyVaultSecretOfficerRoleDefinitionID, platformKeyVaultName)
  scope: keyVaultResource
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretOfficerRoleDefinitionID)
    principalId: managedIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

module webServerFarmResource 'br/SharedDefraRegistry:web.serverfarm:0.4.12' = {
  name: 'server-farm-${deploymentDate}'
  params: {
    name: appService.planName
    location: location
    sku: appService.planSku
    lock: {
      kind: 'CanNotDelete'
    }
    reserved: true
  }
}

module functionApp 'br/SharedDefraRegistry:web.site:0.4.19' = {
  name: 'functionapp-${deploymentDate}'
  params: {
    name: appService.name
    tags: union(tags, appServiceTags)
    kind: 'functionapp,linux'
    serverFarmResourceId: webServerFarmResource.outputs.resourceId
    appInsightResourceId: applicationInsightsResource.id
    siteConfig: {
      netFrameworkVersion: 'v4.0'
      linuxFxVersion: 'DOTNET-ISOLATED|8.0'
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsightsResource.properties.InstrumentationKey
        }
        {
          name: 'AzureWebJobsStorage'
          value: keyVaultSecretUri
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: keyVaultSecretUri
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: storageAccount.fileShareName
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
        {
          name: 'WEBSITE_SKIP_CONTENTSHARE_VALIDATION'
          value: '1'
        }
        {
          name: 'WEBSITE_CONTENTOVERVNET'
          value: '1'
        }
      ]
      ipSecurityRestrictions: [
        {
          ipAddress: 'AzureDevOps'
          action: 'Allow'
          tag: 'ServiceTag'
          priority: 100
          name: 'AllowAzureDevOps'
          description: 'AllowAzureDevOps'
        }
      ]
      cors: {
        allowedOrigins: ['https://portal.azure.com']
      }
    }
    virtualNetworkSubnetId: resourceId(vnet.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnet.name, vnet.subnetFunctionApp)
    publicNetworkAccess: 'Enabled'
    vnetRouteAllEnabled: true
    httpsOnly: true
    keyVaultAccessIdentityResourceId: managedIdentity.outputs.resourceId
    managedIdentities: {
      userAssignedResourceIds: [
        managedIdentity.outputs.resourceId
      ]
    }
  }
}
