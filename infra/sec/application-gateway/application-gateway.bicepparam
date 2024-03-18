using './application-gateway.bicep'

param name = '#{{ secApplicationGatewayName }}'

param environment = '#{{ environment }}'

param location = '#{{ location }}'

param vnet = {
  name: '#{{ secVirtualNetworkName }}'
  resourceGroup: '#{{ secVirtualNetworkResourceGroup }}'
  subnetApplicationGateway: '#{{ secAppGatewaySubnetName }}'
}

param publicIPName = '#{{ secAppGWpublicIPName }}'

param wafPolicyName = '#{{ secApplicationGatewayWAFPolicyName }}'

param policySettings = {
  state: 'Enabled'
  mode: 'Prevention'
}

//param diagnosticSettings = {
//  workspacename: '#{{ logAnalyticsWorkspace }}'
//  resourceGroup: '#{{ servicesResourceGroup }}'
//}

param managedRuleSets = [
  {
    ruleSetType: 'OWASP'
    ruleSetVersion: '3.0'
    ruleGroupOverrides: [
      {
            ruleGroupName: 'REQUEST-942-APPLICATION-ATTACK-SQLI'
            rules: [
              {
                  ruleId: '942150'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942100'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942110'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942120'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942130'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942140'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942160'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942170'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942180'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942190'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942200'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942210'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942220'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942230'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942240'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942250'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942251'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942260'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942270'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942280'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942290'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942300'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942310'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942320'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942330'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942340'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942350'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942360'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942370'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942380'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942390'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942400'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942410'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942420'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942421'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942430'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942431'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942432'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942440'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942450'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '942460'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
          ]
      }
      {
          ruleGroupName: 'General'
          rules: [
              {
                  ruleId: '200004'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
          ]
      }
      {
          ruleGroupName: 'REQUEST-911-METHOD-ENFORCEMENT'
          rules: [
              {
                  ruleId: '911100'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
          ]
      }
      {
          ruleGroupName: 'REQUEST-913-SCANNER-DETECTION'
          rules: [
              {
                  ruleId: '913100'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '913101'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '913102'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '913110'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '913120'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
          ]
      }
      {
          ruleGroupName: 'REQUEST-920-PROTOCOL-ENFORCEMENT'
          rules: [
              {
                  ruleId: '920100'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920120'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920130'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920140'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920160'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920170'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920180'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920190'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920200'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920201'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920202'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920210'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920220'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920230'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920240'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920250'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920260'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920270'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920271'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920272'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920273'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920274'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920280'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920290'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920300'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920310'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920311'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920320'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920330'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920340'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920350'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920420'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920430'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920440'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920450'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '920460'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
          ]
      }
      {
          ruleGroupName: 'REQUEST-921-PROTOCOL-ATTACK'
          rules: [
              {
                  ruleId: '921100'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '921110'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '921120'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '921130'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '921140'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '921150'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '921151'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '921160'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '921170'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '921180'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
          ]
      }
      {
          ruleGroupName: 'REQUEST-930-APPLICATION-ATTACK-LFI'
          rules: [
              {
                  ruleId: '930100'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '930110'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '930120'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '930130'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
          ]
      }
      {
          ruleGroupName: 'REQUEST-931-APPLICATION-ATTACK-RFI'
          rules: [
              {
                  ruleId: '931100'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '931110'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '931120'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '931130'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
          ]
      }
      {
          ruleGroupName: 'REQUEST-932-APPLICATION-ATTACK-RCE'
          rules: [
              {
                  ruleId: '932100'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '932105'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '932110'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '932115'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '932120'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '932130'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '932140'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '932150'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '932160'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '932170'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '932171'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
          ]
      }
      {
          ruleGroupName: 'REQUEST-933-APPLICATION-ATTACK-PHP'
          rules: [
              {
                  ruleId: '933100'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '933110'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '933111'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '933120'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '933130'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '933131'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '933140'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '933150'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '933151'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '933160'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '933161'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '933170'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '933180'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
          ]
      }
      {
          ruleGroupName: 'REQUEST-941-APPLICATION-ATTACK-XSS'
          rules: [
              {
                  ruleId: '941100'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '941110'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '941120'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '941130'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '941140'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '941150'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '941160'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '941170'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '941180'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '941190'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '941200'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '941210'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '941220'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '941230'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '941240'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '941250'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '941260'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '941270'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '941280'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '941290'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '941300'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '941310'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '941320'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '941330'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '941340'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '941350'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
          ]
      }
      {
          ruleGroupName: 'REQUEST-943-APPLICATION-ATTACK-SESSION-FIXATION'
          rules: [
              {
                  ruleId: '943100'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '943110'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '943120'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
          ]
      }
      {
          ruleGroupName: 'Known-CVEs'
          rules: [
              {
                  ruleId: '800100'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '800110'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '800111'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '800112'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
              {
                  ruleId: '800113'
                  state: 'Disabled'
                  action: 'AnomalyScoring'
              }
          ]
      }
    ]
  }
]

param frontDoorId = '#{{ azureFrontDoorProfileFrontDoorId }}'

param backends = [
  {
    name: 'portal-web'
    backendAddressPool: {
      fqdn: '#{{ containerAppIngressFqdn }}'
    }
    backendHttpSetting: {
      port: 443
      protocol: 'Https'
      cookieBasedAffinity: 'Disabled'
      pickHostNameFromBackendAddress: true
      requestTimeout: 20
      probe: {
        path: '/'
        healthProbeStatusCode: '200-404'
      }
    }
    httpListener: {
      protocol: 'Http'
      hostNames: []
      requireServerNameIndication: false
    }
    requestRoutingRule: {
      backendAddressPool: 'portal-web'
      listenerName: 'portal-web'
      backendName: 'portal-web'
      ruleType: 'Basic'
      priority: 1
    }
  }
]
