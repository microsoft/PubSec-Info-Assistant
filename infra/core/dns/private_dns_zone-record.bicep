param privateDnsZoneName string
param recordName string
param recordIpAddress string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneName
}

resource aRecordRoot 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: privateDnsZone
  name: recordName
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: recordIpAddress
      }
    ]
  }
}

