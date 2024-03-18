using './network-security-group.bicep'

param environment = '#{{ environment }}'

param location = '#{{ location }}'

param nsgList = [
  {
    name: 'SEC#{{ projectName }}#{{ environment }}#{{ nc_resource_nsg }}140#{{ environmentId }}'
    purpose: 'ADP Application gateway subnet NSG'
    securityRules: [
        {
            name: 'AllowAzureFrontDoorBackend',
            properties: {
                protocol: 'TCP',
                sourcePortRange: '*',
                sourceAddressPrefix: 'AzureFrontDoor.Backend'
                destinationAddressPrefix: '*',
                access: 'Allow',
                priority: 200,
                direction: 'Inbound',
                sourcePortRanges: [],
                destinationPortRanges: [
                    80
                    443
                ],
                sourceAddressPrefixes: [],
                destinationAddressPrefixes: [],
                description: 'Allow Azure FrontDoor Backend'
            }
        }
        {
            name: 'AllowGWM',
            properties: {
                protocol: '*',
                sourcePortRange: '*',
                destinationPortRange: '65200-65535',
                sourceAddressPrefix: '*'
                destinationAddressPrefix: '*',
                access: 'Allow',
                priority: 300,
                direction: 'Inbound',
                sourcePortRanges: [],
                destinationPortRanges: [],
                sourceAddressPrefixes: [],
                destinationAddressPrefixes: [],
                description: 'Allow all inbound Gateway Management ports'
            }
        }  
        {
            name: 'DenyAnyOtherInbound',
            properties: {
                protocol: '*',
                sourcePortRange: '*',
                destinationPortRange: '*',
                sourceAddressPrefix: '*'
                destinationAddressPrefix: '*',
                access: 'Deny',
                priority: 4000,
                direction: 'Inbound',
                sourcePortRanges: [],
                destinationPortRanges: [],
                sourceAddressPrefixes: [],
                destinationAddressPrefixes: [],
                description: 'Deny All Other Inbound'
            }
        } 
        {
            name: 'DenyAllOtherOutbound',
            properties: {
                protocol: '*',
                sourcePortRange: '*',
                destinationPortRange: '*',
                sourceAddressPrefix: '*'
                destinationAddressPrefix: '*',
                access: 'Deny',
                priority: 4000,
                direction: 'Outbound',
                sourcePortRanges: [],
                destinationPortRanges: [],
                sourceAddressPrefixes: [],
                destinationAddressPrefixes: [],
                description': 'Deny All Other Outbound'
            }
        }       
    ]
  }
]
