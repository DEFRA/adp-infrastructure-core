using 'azure-waf-baseline.bicep'

param wafPolicyName = 'newwaf1234567'

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

param customRules = [
  {
    name: 'PaloIpWAF'
    priority: 100
    enabledState: 'Enabled'
    ruleType: 'MatchRule'
    matchType: 'IP address'
    action: 'Deny traffic'
    matchConditions: [
      {
        matchVariables: [
          {
            variableName: 'SocketAddr'
          }
        ]
        operator: 'IPMatch'
        negationConditon: true
        matchValues: [  '52.142.87.204/32',
                        '52.142.86.40/32',
                        '52.158.29.71/32',
                        '52.142.85.239/32',
                        '40.74.1.3/32',
                        '40.74.8.84/32',
                        '51.104.252.122/32',
                        '40.81.156.55/32',
                        '51.11.27.97/32',
                        '40.81.153.120/32',
                        '40.81.127.250/32',
                        '20.40.104.49/32' 
                      ]
      }
    ]
  }
]
