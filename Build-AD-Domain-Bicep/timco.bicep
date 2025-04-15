param orgId string
param elzSubName string
param elzRegionId string
param elzRegionName string
param elzNetworkRg string
param elzVnetName string
param elzVnetAddress string
param snetWeb string
param snetApp string
param snetDb string
param snetMgt string

targetScope = 'subscription'

resource rgNetwork 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: elzNetworkRg
  location: elzRegionName
}

module vnet './modules/network.bicep' = {
  name: 'vnetDeployment'
  scope: rgNetwork
  params: {
    orgId: orgId
    elzSubName: elzSubName
    elzRegionId: elzRegionId
    vnetName: elzVnetName
    vnetAddress: elzVnetAddress
    snetWeb: snetWeb
    snetApp: snetApp
    snetDb: snetDb
    snetMgt: snetMgt
    location: elzRegionName
  } 
}
