@description('Required. The name of the Front Door endpoint to create. This must be globally unique.')
param wafPolicyName string

@description('Optional. The list of custom rule sets to configure on the WAF.')
param customRules object = {
  rules: [
    {
      name: 'ApplyGeoFilter'
      priority: 100
      enabledState: 'Enabled'
      ruleType: 'MatchRule'
      action: 'Block'
      matchConditions: [
        {
          matchVariable: 'RemoteAddr'
          operator: 'GeoMatch'
          negateCondition: true
          matchValue: [ 'ZZ' ]
        }
      ]
    }
  ]
}

@description('Optional. The list of managed rule sets to configure on the WAF.')
param managedRules object = {
  managedRuleSets: [
    {
      ruleSetType: 'Microsoft_DefaultRuleSet'
      ruleSetVersion: '2.1'
      ruleGroupOverrides: []
      exclusions: []
      ruleSetAction: 'Block'
    }
    {
      ruleSetType: 'Microsoft_BotManagerRuleSet'
      ruleSetVersion: '1.0'
      ruleGroupOverrides: []
      exclusions: []
    }
  ]
}

@description('Optional. The PolicySettings for policy.')
param policySettings object =  {
      enabledState: 'Enabled'
      mode: 'Prevention'
      redirectUrl: null
      customBlockResponseStatusCode: 403
      customBlockResponseBody: null
      requestBodyCheck: 'Enabled'
    }

@description('Optional. The Azure region where the resources will be deployed.')
param location string = 'global'

@description('Required. Environment name.')
param environment string

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}
var tags = union(loadJsonContent('../default-tags.json'), customTags)

var frontDoorWafTags = {
  Name: wafPolicyName
  Purpose: 'ADP Core Front Door WAF'
  Tier: 'Shared'
}

module frontDoorWafPolicy 'br/SharedDefraRegistry:network.front-door-web-application-firewall-policy:0.4.1-prerelease' = {
  name: 'fdwaf-${deploymentDate}'
  params: {
    name: wafPolicyName
    location: location
    lock: 'CanNotDelete'
    tags: union(tags, frontDoorWafTags)
    sku: 'Premium_AzureFrontDoor' // The Microsoft-managed WAF rule sets require the premium SKU of Front Door.
    policySettings: policySettings
    customRules : customRules
    managedRules : managedRules
  }
}

output frontDoorWAFPolicyName string = frontDoorWafPolicy.name
