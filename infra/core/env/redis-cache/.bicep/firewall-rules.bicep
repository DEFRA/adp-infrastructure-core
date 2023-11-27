
param redisCacheName string
param redisCacheSkuName string = 'Premium'
@description('Optional. Object array, with propterties Name, addressprefix in cidr format')
param firewallRules array = []

resource redisCacheParent 'Microsoft.Cache/redis@2022-06-01' existing = {
  name: redisCacheName
}

resource redisCacheFirewallRule 'Microsoft.Cache/redis/firewallRules@2022-06-01' = [for rule in firewallRules: if (startsWith(redisCacheSkuName, 'Premium')) {
  name: rule.name
  parent: redisCacheParent
  properties: {
    endIP: parseCidr(rule.addressprefix).lastUsable
    startIP: parseCidr(rule.addressprefix).firstUsable
  }  
}]
