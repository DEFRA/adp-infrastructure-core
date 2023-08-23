@description('Required. The name of the Front Door endpoint to create. This must be globally unique.')
param wafPolicyName string

@allowed([
  'Detection'
  'Prevention'
])
@description('Optional. The mode that the WAF should be deployed using. In \'Prevention\' mode, the WAF will block requests it detects as malicious. In \'Detection\' mode, the WAF will not block requests and will simply log the request.')
param wafMode string = 'Prevention'

@allowed([
  'Standard_AzureFrontDoor'
  'Premium_AzureFrontDoor'
])
@description('Optional. The pricing tier of the WAF profile.')
param skuName string = 'Premium_AzureFrontDoor' // The Microsoft-managed WAF rule sets require the premium SKU of Front Door.

@description('Optional, The list of country codes that are allowed to access the Front Door endpoint. Country codes are specified using ISO 3166-1 alpha-2 format. [See here for a list of country codes.](https://docs.microsoft.com/azure/frontdoor/front-door-geo-filtering#countryregion-code-reference)')
param allowedCountries array = [ 'GB' ]

@description('Optional. The list of custom rule sets to configure on the WAF.')
param customRules array = [
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
        matchValue: allowedCountries
      }
    ]
  }
]

@description('Optional. The list of managed rule sets to configure on the WAF.')
param wafManagedRuleSets array = [
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

@description('Optional. The Azure region where the resources will be deployed.')
param location string = 'global'

@description('Required. Environment name.')
param environment string

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

var lock = 'CanNotDelete'

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

resource wafPolicy 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2020-11-01' = {
  name: wafPolicyName
  location: location
  sku: {
    name: skuName
  }
  properties: {
    policySettings: {
      enabledState: 'Enabled'
      mode: wafMode
      redirectUrl: null
      customBlockResponseStatusCode: 403
      customBlockResponseBody: null
      requestBodyCheck: 'Enabled'
    }
    customRules: {
      rules: customRules
    }
    managedRules: {
      managedRuleSets: wafManagedRuleSets
    }
  }
  tags: union(tags, frontDoorWafTags)
}

resource profile_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock)) {
  name: '${wafPolicy.name}-${lock}-lock'
  properties: {
    level: any(lock)
    notes: lock == 'CanNotDelete' ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: wafPolicy
}


output frontDoorWAFPolicyName string = wafPolicy.name
