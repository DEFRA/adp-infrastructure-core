using '../azure-waf.bicep'

param wafPolicyName = '#{{ adpPortalwafPolicyName }}'

param policySettings = {
  enabledState: 'Enabled'
  mode: 'Prevention'
}

param purpose = 'ADP Core ADP Portal Front Door WAF - All Services Generic'

param environment = '#{{ environment }}'

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

//param customRules = []

// param customRules =  [
//   {
//     name: 'CustomRule1'
//     priority: 100
//     ruleType: 'MatchRule'
//     action: 'Block'
//     matchConditions: [
//       {
//         matchVariable: 'SocketAddr'
//         operator: 'GeoMatch'
//         matchValues: ['US']
//         transforms: []
//       }
//     ]
//   }
// ]


// param customRules =  [
//   {
//     name: 'CustomRule1'
//     priority: 100
//     ruleType: 'MatchRule'
//     action: 'Block'
//     matchConditions: [
//       {
//         matchVariable: 'RemoteAddr'
//         operator: 'Does not contain'
//         matchValues: '20.40.104.49/32'
//       }
//     ]
//   }
// ]


param customRules =  [
  {
    name: 'BlockSQLInjection'
    priority: 1
    ruleType: 'MatchRule'
    matchConditions: [
      {
        matchVariables: [
          {
            variableName: 'QueryString'
          }
        ]
        operator: 'Contains'
        matchValues: [
          'UNION SELECT'      
        ]
        transforms: [
          'Lowercase'
        ]
      }
    ]
    action: 'Block'
  }
]
