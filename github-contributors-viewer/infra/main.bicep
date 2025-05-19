/*
  This Bicep template deploys the necessary Azure resources for a GitHub Contributors Viewer application.
  It creates:
  - A resource group (if deployed at subscription level)
  - A storage account for hosting static frontend content
  - An App Service Plan and App Service for the backend API
  - Application insights for monitoring
  - Required configurations and settings
*/

@description('The name of the environment. This will be used as a suffix for all resources.')
param environmentName string = 'dev'

@description('The Azure region for all resources.')
param location string = resourceGroup().location

@description('Tags for all resources.')
param tags object = {
  environment: environmentName
  application: 'github-contributors-viewer'
}

// Define naming convention with a consistent prefix
var prefix = 'ghcv'
var resourceToken = '${prefix}-${environmentName}'

// Names for resources based on naming convention
var storageAccountName = replace('${resourceToken}storage', '-', '')  // Storage account names don't support hyphens
var appServicePlanName = '${resourceToken}-plan'
var frontendAppName = '${resourceToken}-frontend'
var backendAppName = '${resourceToken}-backend'
var appInsightsName = '${resourceToken}-insights'
var logAnalyticsWorkspaceName = '${resourceToken}-logs'

// Log Analytics Workspace for application insights
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// Application Insights for monitoring
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Storage account for frontend static website hosting
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
    allowBlobPublicAccess: true
    minimumTlsVersion: 'TLS1_2'
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

// Enable static website hosting on the storage account
resource staticWebsite 'Microsoft.Storage/storageAccounts/managementPolicies@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    policy: {}
  }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: [
        {
          allowedOrigins: ['*']
          allowedMethods: ['GET', 'OPTIONS']
          maxAgeInSeconds: 3600
          exposedHeaders: ['*']
          allowedHeaders: ['*']
        }
      ]
    }
    deleteRetentionPolicy: {
      enabled: false
    }
  }
}

// Enable static website hosting
resource staticWebsiteConfig 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobServices
  name: '$web'
  properties: {
    publicAccess: 'None'
  }
}

// App Service Plan for the backend API
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: 'B1' // Basic tier
    tier: 'Basic'
    size: 'B1'
    family: 'B'
    capacity: 1
  }
  properties: {
    reserved: false // false for Windows, true for Linux
  }
}

// Backend API App Service
resource backendApp 'Microsoft.Web/sites@2022-03-01' = {
  name: backendAppName
  location: location
  tags: union(tags, { 'azd-service-name': 'backend' })
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    clientAffinityEnabled: false
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~2'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~16' // Node.js version
        }
        {
          name: 'CORS_ALLOWED_ORIGINS'
          value: '*' // In production, you should limit this to specific domains
        }
      ]
      cors: {
        allowedOrigins: [
          'https://${storageAccount.name}.z13.web.core.windows.net'
          'https://${frontendApp.properties.defaultHostName}'
          'http://localhost:3000'
        ]
        supportCredentials: false
      }
      nodeVersion: '~16'
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
    }
  }
}

// Frontend App Service (for easier deployment and CI/CD)
resource frontendApp 'Microsoft.Web/sites@2022-03-01' = {
  name: frontendAppName
  location: location
  tags: union(tags, { 'azd-service-name': 'frontend' })
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    clientAffinityEnabled: false
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~2'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~16' // Node.js version
        }
        {
          name: 'REACT_APP_API_URL'
          value: 'https://${backendApp.properties.defaultHostName}'
        }
      ]
      nodeVersion: '~16'
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
    }
  }
}

// Outputs that can be used by GitHub Actions
output backendUrl string = 'https://${backendApp.properties.defaultHostName}'
output frontendUrl string = 'https://${frontendApp.properties.defaultHostName}'
output storageAccountName string = storageAccount.name
output appServicePlanName string = appServicePlan.name
output backendAppName string = backendApp.name
output frontendAppName string = frontendApp.name
output resourceGroupName string = resourceGroup().name
