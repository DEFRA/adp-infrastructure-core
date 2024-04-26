using './network-security-group.bicep'

param environment = '#{{ environment }}'

param location = '#{{ location }}'

param nsgList = [
  {
    name: 'SEC#{{ projectName }}#{{ environment }}#{{ nc_resource_nsg }}140#{{ environmentId }}'
    purpose: 'ADP Application gateway subnet NSG'
    securityRules: [
        {
            name: 'AllowAzureFrontDoorBackend'
            properties: {
                protocol: 'Tcp'
                sourcePortRange: '*'
                sourceAddressPrefix: 'AzureFrontDoor.Backend'
                destinationAddressPrefix: '*'
                access: 'Allow'
                priority: 200
                direction: 'Inbound'
                sourcePortRanges: []
                destinationPortRanges: [
                    80
                    81
                    443
                ]
                sourceAddressPrefixes: []
                destinationAddressPrefixes: []
                description: 'Allow Azure FrontDoor Backend'
            }
        }
        {
            name: 'AllowGWM'
            properties: {
                protocol: '*'
                sourcePortRange: '*'
                destinationPortRange: '65200-65535'
                sourceAddressPrefix: '*'
                destinationAddressPrefix: '*'
                access: 'Allow'
                priority: 300
                direction: 'Inbound'
                sourcePortRanges: []
                destinationPortRanges: []
                sourceAddressPrefixes: []
                destinationAddressPrefixes: []
                description: 'Allow all inbound Gateway Management ports'
            }
        }      
    ]
  }
]
