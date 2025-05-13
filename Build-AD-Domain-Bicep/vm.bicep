param name string
param location string
param subnetId string
param storageAccountName string
param windowsVersion string
param zone string
param vmSize string
param publicIpAddressId string = ''

resource nic 'Microsoft.Network/networkInterfaces@2023-02-01' = {
  name: '${name}-nic01'  
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: empty(publicIpAddressId) ? null : {
            id: publicIpAddressId
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: name
  location: location
  zones: [zone]
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: name
      adminUsername: 'azureuser'
      adminPassword: 'P@ssword1234!' // Use Key Vault in production
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: windowsVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: 'https://${storageAccountName}.blob.core.windows.net'
      }
    }
  }
}
