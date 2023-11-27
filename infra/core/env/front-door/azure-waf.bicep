@description('Required. The name of the Front Door WAF Policy to create.')
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

@description('Optional. The PolicySettings object (enabledState,mode) for policy.')
param policySettings object = {
  enabledState: 'Enabled'
  mode: 'Prevention'
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
var tags = union(loadJsonContent('../../../common/default-tags.json'), customTags)

var frontDoorWafTags = {
  Name: wafPolicyName
  Purpose: purpose
  Tier: 'Shared'
}

var customBlockResponseBody = '<!DOCTYPE html> <html> <head> <title> Defra - 403 Forbidden</title> <meta name="viewport" content="width=device-width, initial-scale=1"> <style> body {background-color:#ffffff;background-repeat:no-repeat;background-position:top left;background-attachment:fixed;} h1{text-align:center;font-family:Arial, sans-serif;color:#ff0a0a;background-color:#ffffff;} p {text-align:left;font-family:Georgia, serif;font-size:14px;font-style:normal;font-weight:normal;color:#000000;background-color:#ffffff;} </style> </head> <body> <h1>Unfortunately, there is a problem with your request</h1> <br /> <p><b>Your request has been blocked.</b> Please contact the site administrator or the Defra helpdesk with the following information. </p> <p></p> <p><b>Tracking Request ID</b>: {{azure-ref}}</p> </body> </html>'

module frontDoorWafPolicy 'br/SharedDefraRegistry:network.front-door-web-application-firewall-policy:0.4.1' = {
  name: 'fdwaf-${deploymentDate}'
  params: {
    name: wafPolicyName
    location: location
    lock: 'CanNotDelete'
    tags: union(tags, frontDoorWafTags)
    sku: 'Premium_AzureFrontDoor' // The Microsoft-managed WAF rule sets require the premium SKU of Front Door.
    policySettings: {
      enabledState: policySettings.enabledState
      mode: policySettings.mode
      redirectUrl: null
      customBlockResponseStatusCode: 403
      customBlockResponseBody: base64(customBlockResponseBody)
      requestBodyCheck: 'Enabled'
    }
    customRules: {
      rules: customRules
    }
    managedRules: {
      managedRuleSets: managedRuleSets
    }
  }
}

output frontDoorWAFPolicyName string = frontDoorWafPolicy.name
