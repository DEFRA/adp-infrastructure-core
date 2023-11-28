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
    name: 'acainternal'
    properties: {
      addressPrefix: '#{{ subnet1AddressPrefix }}'
      nextHopType: 'VnetLocal'
    }
  }

]

param location = '#{{ location }}'

param environment = '#{{ environment }}'
