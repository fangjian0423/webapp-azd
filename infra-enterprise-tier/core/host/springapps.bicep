param environmentName string
param location string = resourceGroup().location
var tags = { 'azd-env-name': environmentName }
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))


resource asaInstance 'Microsoft.AppPlatform/Spring@2022-12-01' = {
  name: 'asa-${resourceToken}'
  location: location
  tags: union(tags, { 'azd-service-name': 'helloworld-web' })
  sku: {
    tier: 'Enterprise'
    name: 'E0'
  }
}

resource buildService 'Microsoft.AppPlatform/Spring/buildServices@2023-03-01-preview' = {
  name: '${asaInstance.name}/default'
  properties: {

  }
  dependsOn: [
    asaInstance
  ]
}

resource asaApp 'Microsoft.AppPlatform/Spring/apps@2022-12-01' = {
  name: 'helloworld-web'
  location: location
  parent: asaInstance
  identity: {
      type: 'SystemAssigned'
    }
  properties: {
    public: true
  }
}

resource asaDeployment 'Microsoft.AppPlatform/Spring/apps/deployments@2022-12-01' = {
  name: 'default'
  parent: asaApp
  properties: {
    deploymentSettings: {
      resourceRequests: {
        cpu: '1'
        memory: '2Gi'
      }
    }
    source: {
      type: 'BuildResult'
      buildResultId: '<default>'
    }
  }
}

resource buildAgentpool 'Microsoft.AppPlatform/Spring/buildServices/agentPools@2023-03-01-preview' = {
  name: '${asaInstance.name}/default/default'
  properties: {
    poolSize: {
      name: 'S2'
    }
  }
  dependsOn: [
    asaInstance
    buildService
  ]
}

resource builder 'Microsoft.AppPlatform/Spring/buildServices/builders@2023-03-01-preview' = {
  name: 'asabuildername'
  parent: buildService
  properties: {
    buildpackGroups: [
      {
        buildpacks: [
          {
            id: 'tanzu-buildpacks/nodejs'
          }
          {
            id: 'tanzu-buildpacks/dotnet-core'
          }
          {
            id: 'tanzu-buildpacks/go'
          }
          {
            id: 'tanzu-buildpacks/python'
          }
          {
            id: 'tanzu-buildpacks/java-azure'
          }
        ]
        name: 'java'
      }
    ]
    stack: {
      id: 'io.buildpacks.stacks.bionic'
      version: 'full'
    }
  }
  dependsOn: [
    asaInstance
  ]
}

