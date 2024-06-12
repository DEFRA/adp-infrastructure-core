@description('Required. The name of the Front Door WAF Policy to create.')
param wafPolicyName string

@description('Optional. The list of custom rule sets to configure on the WAF.')
param customRules array = []

@description('Optional. The list of custom rule sets to configure on the WAF.')
param defraApprovedIPcustomRule array = []

@description('Optional. The list of custom rule sets to configure on the WAF.')
param fcpDALcustomRule array = []

@description('Optional. The list of custom rule sets to configure on the WAF.')
param adoCallbackAccessRule array = []

@description('Optional. The list of managed rule sets to configure on the WAF (DRS).')
param managedRuleSets array = []

@description('Optional. The PolicySettings object (enabledState,mode) for policy.')
param policySettings object = {
  enabledState: 'Enabled'
  mode: 'Prevention'
}

@description('Required. Environment name.')
param environment string

@description('Optional. Deploy the ADP Portal WAF Policy.')
param deployWAF string = 'true'

@description('Required. Custom Block Response Body')
param customBlockResponseBody string 

@description('Required. Purpose Tag.')
param purpose string

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

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
var customRule = union(customRules,defraApprovedIPcustomRule,fcpDALcustomRule,adoCallbackAccessRule)

module frontDoorWafPolicy 'br/SharedDefraRegistry:network.front-door-web-application-firewall-policy:0.4.1' = if(deployWAF == 'true') {
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
      rules: customRule
    }
    managedRules: {
      managedRuleSets: managedRuleSets
    }
  }
}

output frontDoorWAFPolicyName string = frontDoorWafPolicy.name
