using './virtual-network.bicep'

param vnet = {}
param subnets = []
param location = 'UKSouth'
param environment = ''
param createdDate = ? /* TODO : please fix the value assigned to this parameter `utcNow()` */
param deploymentDate = ? /* TODO : please fix the value assigned to this parameter `utcNow()` */

