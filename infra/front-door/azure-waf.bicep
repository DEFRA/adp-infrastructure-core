@description('Required. The name of the Front Door endpoint to create. This must be globally unique.')
param wafPolicyName string

@description('Optional. The list of custom rule sets to configure on the WAF.')
param customRules array = []

@description('Optional. The list of RuleSetExclusions to be configured on the Default Microsoft managed rule set')
param microsoftDefaultRuleSetRuleGroupOverrides array = []

@description('Optional. The list of exclusions to be configured on the Default Microsoft managed rule set.')
param microsoftDefaultRuleSetExclusions array = []


@description('Optional. The list of RuleSetExclusions to be configured on the Default Microsoft Bot Manager rule set')
param microsoftBotManagerRuleSetRuleGroupOverrides array = []

@description('Optional. The list of exclusions to be configured for Microsoft Bot Manager ruleset  ')
param microsoftBotManagerRuleSetExclusions array = []

@description('Optional. The PolicySettings for policy.')
param policySettings object = {
  enabledState: 'Enabled'
  mode: 'Prevention'
  redirectUrl: null
  customBlockResponseStatusCode: 403
  customBlockResponseBody: null
  requestBodyCheck: 'Enabled'
}

@description('Required. Environment name.')
param environment string

@description('Required. Purpose Tag.')
param purpose string

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

var managedRuleSets = [
  {
    ruleSetType: 'Microsoft_DefaultRuleSet'
    ruleSetVersion: '2.1'
    ruleGroupOverrides: microsoftDefaultRuleSetRuleGroupOverrides
    exclusions: microsoftDefaultRuleSetExclusions
    ruleSetAction: 'Block'
  }
  {
    ruleSetType: 'Microsoft_BotManagerRuleSet'
    ruleSetVersion: '1.0'
    ruleGroupOverrides: microsoftBotManagerRuleSetRuleGroupOverrides
    exclusions: microsoftBotManagerRuleSetExclusions
  }
]

var location = 'global'

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}
var tags = union(loadJsonContent('../default-tags.json'), customTags)

var frontDoorWafTags = {
  Name: wafPolicyName
  Purpose: purpose
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
    customRules: {
      rules: customRules
    }
    managedRules: {
      managedRuleSets: managedRuleSets
    }
  }
}

output frontDoorWAFPolicyName string = frontDoorWafPolicy.name
