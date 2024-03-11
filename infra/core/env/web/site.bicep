@description('Required. The parameter object for the virtual network. The object must contain the name,resourceGroup and subnetPrivateEndpoints values.')
param vnet object = {
  name: 'SNDADPNETVN1401'
  resourceGroup: 'SNDADPNETRG1401'
  subnetFunctionApp: 'SNDADPNETSU1494'
  subnetPrivateEndpoints: 'SNDADPNETSU1498'
}

param storageAccount object = {
  name: 'sndadpinfst1402'
  fileShareName: 'function-content-share'
}

@description('Required. The parameter object for eventHub. The object must contain the name values.')
param appService object = {
  name: 'SNDADPINFFA1401'
  planName: 'SDNADPINFSP1401'
  planSku: {
    name: 'EP1'
    tier: 'ElasticPremium'
    // size: 'EP1'
    // family: 'EP'
    // capacity: 1
  }
}

param applicationInsightsName string = 'SNDADPINFAI1401'

param platformKeyVault object = {
  name: 'SNDADPINFVT1402'
  secretName: 'deploymentTriggerFunctionAppStorageAccountConnectionString'
  deploymentTriggerStorageConnectionString: 'https://SNDADPINFVT1402.vault.azure.net/secrets/deploymentTriggerFunctionAppStorageAccountConnectionString'
}

@description('Required. Environment name.')
param environment string = 'SND1'

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

var keyVaultSecretUri = '@Microsoft.KeyVault(SecretUri=${platformKeyVault.deploymentTriggerStorageConnectionString}/)'

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

resource storageAccountResource 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccount.name
}

resource keyVaultResource 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: platformKeyVault.name
}

resource secretResource 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVaultResource
  name: platformKeyVault.secretName
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccountResource.id,'2022-05-01').keys[0].value}'
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
    appInsightResourceId: applicationInsights.id
    siteConfig: {
      netFrameworkVersion: 'v4.0'
      linuxFxVersion: 'DOTNET-ISOLATED|8.0'
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'AzureWebJobsStorage'
          value: keyVaultSecretUri
          // value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccountResource.id,'2022-05-01').keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: keyVaultSecretUri
          // value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccountResource.id,'2022-05-01').keys[0].value}'
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
  }
}

// resource webSiteResource 'Microsoft.Web/sites@2023-01-01' = {
//   name: appService.name
//   location: location
//   kind: 'functionapp,linux'
//   properties: {
//     serverFarmId: webServerFarmResource.outputs.resourceId
//     vnetRouteAllEnabled: true
//     siteConfig: {
//       netFrameworkVersion: 'v4.0'
//       linuxFxVersion: 'DOTNET-ISOLATED|8.0'
//       ipSecurityRestrictions: [
//         {
//           ipAddress: 'AzureDevOps'
//           action: 'Allow'
//           tag: 'ServiceTag'
//           priority: 100
//           name: 'AllowAzureDevOps'
//           description: 'AllowAzureDevOps'
//         }
//       ]
//       cors: {
//         allowedOrigins: ['https://portal.azure.com']
//       }
//     }
//     httpsOnly: true
//     publicNetworkAccess: 'Enabled'
//     virtualNetworkSubnetId: resourceId(vnet.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnet.name, vnet.subnetFunctionApp)
//     keyVaultReferenceIdentity: 'SystemAssigned'
//   }
// }

// resource webSiteResource 'Microsoft.Web/sites@2023-01-01' = {
//   name: appService.name
//   tags: union(tags, appServiceTags)
//   location: location
//   kind: 'functionapp,linux'
//   properties: {
//     serverFarmId: webServerFarmResource.outputs.resourceId
//     virtualNetworkSubnetId: resourceId(vnet.resourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnet.name, vnet.subnetFunctionApp)
//     httpsOnly: true
//     vnetRouteAllEnabled: true
//     siteConfig: {
//       numberOfWorkers: 1
//       linuxFxVersion: 'DOTNET-ISOLATED|8.0'
//       acrUseManagedIdentityCreds: false
//       alwaysOn: false
//       http20Enabled: false
//       functionAppScaleLimit: 0
//       minimumElasticInstanceCount: 1
//     }
//   }
// }
