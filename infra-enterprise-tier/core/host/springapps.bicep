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

resource build 'Microsoft.AppPlatform/Spring/buildServices/builds@2022-12-01' = {
  name: 'asabuild'
  parent: buildService
  properties: {
    agentPool: buildAgentpool.id
    builder: builder.id
    env: {
      BP_JVM_VERSION: 'a=1, b=2'
    }
    relativePath: '/'
  }
  dependsOn: [
    asaInstance
  ]
}

