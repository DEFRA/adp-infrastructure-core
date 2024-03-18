@description('Required. The name of the Front Door WAF Policy to create.')
param wafPolicyName string

@description('Optional. The Azure region where the resources will be deployed.')
param location string = resourceGroup().location

@description('Optional. The list of managed rule sets to configure on the WAF (DRS).')
param managedRuleSets array = []

@description('Optional. The PolicySettings object (state,mode) for policy.')
param policySettings object = {
  state: 'Enabled'
  mode: 'Prevention'
}

@description('Required. The FrontDoor ID.')
param frontDoorId string

@description('Required. Environment name.')
param environment string

@description('Required. Purpose Tag.')
param purpose string

@description('Optional. Date in the format yyyyMMdd-HHmmss.')
param deploymentDate string = utcNow('yyyyMMdd-HHmmss')

@description('Optional. Date in the format yyyy-MM-dd.')
param createdDate string = utcNow('yyyy-MM-dd')

var customTags = {
  Location: location
  CreatedDate: createdDate
  Environment: environment
}
var tags = union(loadJsonContent('../../../common/default-tags.json'), customTags)

var appGatewayWafTags = {
  Name: wafPolicyName
  Purpose: purpose
  Tier: 'Shared'
}

module applicationGatewayWebApplicationFirewallPolicy 'br/SharedDefraRegistry:network.application-gateway-web-application-firewall-policy:0.5.6' = {
  name: 'agwaf-${deploymentDate}'
  params: {
    name: wafPolicyName
    location: location
    tags: union(tags, appGatewayWafTags)
    // managedRules: {
    //   managedRuleSets: managedRuleSets
    // }
    customRules: [
      {
          name: 'blockNonAFDTraffic'
          priority: 2
          ruleType: 'MatchRule'
          action: 'Block'
          matchConditions: [
              {
                  matchVariables: [
                      {
                          variableName: 'RequestHeaders'
                          selector: 'X-Azure-FDID'
                      }
                  ]
                  operator: 'Equal'
                  negationConditon: true
                  matchValues: [
                    frontDoorId
                  ]
                  transforms: [
                      'Lowercase'
                  ]
              }
          ]
          state: 'Enabled'
      }
  ]
    policySettings: {
      fileUploadLimitInMb: 10
      mode: policySettings.mode
      state: policySettings.state
    }
  }
}

output appGatewayWAFPolicyName string = applicationGatewayWebApplicationFirewallPolicy.outputs.name

output applicationGatewayWAFPolicyResourceId string = applicationGatewayWebApplicationFirewallPolicy.outputs.resourceId
