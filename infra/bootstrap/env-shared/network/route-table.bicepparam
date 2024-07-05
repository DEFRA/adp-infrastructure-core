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
]

param location = '#{{ location }}'

param environment = '#{{ environment }}'

param resourceLockEnabled = #{{ resourceLockEnabled }}
