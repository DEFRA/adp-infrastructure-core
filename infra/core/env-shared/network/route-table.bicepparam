using './route-table.bicep'

param routeTable = {
  name: 'UDR-Spoke-Route-From-#{{ ssvVirtualNetworkName }}'
  virtualApplicanceIp: '#{{ virtualApplianceIp }}'
}

param routes = [
  {
    name: 'Default'
    properties: {
      addressPrefix: '0.0.0.0/0'
      nextHopType: 'VirtualAppliance'
      nextHopIpAddress: '#{{ virtualApplianceIp }}'
    }
  }
  {
    name: 'subnet1'
    properties: {
      addressPrefix: '#{{ subnet1AddressPrefix }}'
      nextHopType: 'VnetLocal'
    }
  }
  {
    name: 'subnet2'
    properties: {
      addressPrefix: '#{{ subnet2AddressPrefix }}'
      nextHopType: 'VnetLocal'
    }
  }
  {
    name: 'subnet3'
    properties: {
      addressPrefix: '#{{ subnet3AddressPrefix }}'
      nextHopType: 'VnetLocal'
    }
  }
]

param location = '#{{ location }}'

param environment = '#{{ environment }}'
