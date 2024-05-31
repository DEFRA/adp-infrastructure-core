using '../front-door-waf.bicep'

param wafPolicyName = '#{{ adpPortalwafPolicyName }}'

param policySettings = {
  enabledState: 'Enabled'
  mode: 'Prevention'
}

param purpose = 'ADP Core ADP Portal Front Door WAF - All Services Generic'

param environment = '#{{ environment }}'

param deployWAF  = '#{{ deployAdpPortalWAF }}'

param managedRuleSets = [
{
        ruleSetType: 'Microsoft_DefaultRuleSet'
        ruleSetVersion: '2.1'
        ruleSetAction: 'Block'
        ruleGroupOverrides: [
          {
            ruleGroupName: 'RFI'
            rules: [
              {
                ruleId: '931130'
                enabledState: 'Enabled'
                action: 'AnomalyScoring'
                exclusions: [ // Backstage Portal Rules.
                  {
                    matchVariable: 'RequestBodyJsonArgNames'
                    selectorMatchOperator: 'Contains'
                    selector: 'entity.metadata.annotations'
                  }
                  {
                    matchVariable: 'RequestBodyJsonArgNames'
                    selectorMatchOperator: 'Contains'
                    selector: 'entity.metadata.links.url'
                  }
                  {
                    matchVariable: 'RequestBodyJsonArgNames'
                    selectorMatchOperator: 'Contains'
                    selector: 'entity.metadata.annotations.backstage'
                  }
                ]
              }
            ]
            exclusions: []
          }
          {
            ruleGroupName: 'MS-ThreatIntel-SQLI'
            rules: [
              {
                ruleId: '99031001'
                enabledState: 'Enabled'
                action: 'AnomalyScoring'
                exclusions: [ // Backstage Portal Rules.
                  {
                    matchVariable: 'RequestBodyJsonArgNames'
                    selectorMatchOperator: 'Contains'
                    selector: 'entity.metadata.annotations'
                  }
                ]
              }
            ]
            exclusions: []
          }
          { //backstage issues
            ruleGroupName: 'PROTOCOL-ENFORCEMENT'
            rules: [
              {
                ruleId: '920440'
                enabledState: 'Disabled'
                action: 'AnomalyScoring'
                exclusions: []
              }
            ]
            exclusions: []
          }
          { //backstage issues
            ruleGroupName: 'LFI'
            rules: [
              {
                ruleId: '930130'
                enabledState: 'Disabled'
                action: 'AnomalyScoring'
                exclusions: []
              }
            ]
            exclusions: []
          }
        ]
        exclusions: []
      }
      {
        ruleSetType: 'Microsoft_BotManagerRuleSet'
        ruleSetVersion: '1.0'
        ruleGroupOverrides: []
        exclusions: []
      }
]

param customRules = [
  {
      name: 'PaloIPWAF'
      enabledState: 'Enabled'
      priority: 300
      ruleType: 'MatchRule'
      matchConditions: [          
          {
              matchVariable: 'RemoteAddr'
              selector: null
              operator: 'IPMatch'
              negateCondition: true
              matchValue:  [ '#{{ noescape(customRule_PaloIpWAF) }}' ]          
              transforms: []
          }
      ]
      action: 'Block'
  }
]
