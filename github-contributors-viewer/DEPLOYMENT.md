# GitHub Contributors Viewer - Azure Deployment Guide

This guide provides instructions for deploying the GitHub Contributors Viewer application to Azure using GitHub Actions.

## Prerequisites

Before you begin, ensure you have the following:

1. An Azure account with an active subscription
2. GitHub account with your application code
3. Permissions to create resources in Azure
4. Azure CLI installed locally (optional, for local testing)

## Step 1: Create Azure Service Principal

You need to create a service principal in Azure that GitHub Actions will use to deploy resources:

```bash
# Login to Azure
az login

# Set your subscription (if you have multiple)
az account set --subscription <SUBSCRIPTION_ID>

# Create a service principal with Contributor role
az ad sp create-for-rbac --name "github-contributors-viewer" --role Contributor \
                          --scopes /subscriptions/<SUBSCRIPTION_ID> \
                          --sdk-auth
```

Copy the JSON output from this command. You'll need it in the next step.

## Step 2: Add Azure Credentials to GitHub Secrets

1. In your GitHub repository, go to **Settings** > **Secrets and variables** > **Actions**
2. Click on **New repository secret**
3. Create a secret with the name `AZURE_CREDENTIALS` 
4. Paste the JSON output from the previous step as the value
5. Click **Add secret**

## Step 3: Customize the Deployment Parameters (Optional)

If needed, modify the parameters in `infra/main.parameters.json` to match your preferences:

- Change the default location from `eastus` to your preferred Azure region
- Update any tags or other values as needed

## Step 4: Run the GitHub Actions Workflow

1. In your GitHub repository, go to **Actions** tab
2. Click on the "Build and Deploy GitHub Contributors Viewer" workflow
3. Click **Run workflow**
4. Configure the options:
   - **Environment to deploy to**: Choose `dev`, `stage`, or `prod`
   - **Deploy infrastructure**: Check this if you want to deploy the Azure resources
   - **Deploy application**: Check this if you want to deploy the application code
5. Click **Run workflow**

The workflow will:
1. Build the frontend React application
2. Package the backend Node.js application
3. Deploy Azure infrastructure using Bicep (if selected)
4. Deploy the frontend and backend applications to Azure App Service (if selected)

## Step 5: Verify the Deployment

After the workflow completes successfully:

1. Go to the Azure portal and locate your resource group (`ghcv-<environment>-rg`)
2. Find the frontend App Service and navigate to its URL to test the application
3. You can also check Application Insights for monitoring data

## Troubleshooting

If deployment fails:

1. Check the GitHub Actions workflow logs for detailed error messages
2. Verify the service principal has sufficient permissions
3. Ensure that the Azure resources are properly deployed before attempting to deploy the application

## Managing Publishing Profiles (Alternative Deployment Method)

If you prefer to use publishing profiles instead of service principal:

1. Go to your App Service in the Azure portal
2. Navigate to **Deployment Center** > **Deployment Credentials** > **Get publish profile**
3. Download the publishing profile
4. Add the publishing profile as a GitHub secret:
   - `FRONTEND_PUBLISH_PROFILE` - For the frontend app
   - `BACKEND_PUBLISH_PROFILE` - For the backend app

Then modify the workflow to use publishing profiles instead:

```yaml
# For frontend deployment
- name: Deploy to Azure App Service
  uses: azure/webapps-deploy@v2
  with:
    app-name: ${{ needs.deploy_infrastructure.outputs.frontendAppName }}
    publish-profile: ${{ secrets.FRONTEND_PUBLISH_PROFILE }}
    package: frontend-build

# For backend deployment
- name: Deploy to Azure App Service
  uses: azure/webapps-deploy@v2
  with:
    app-name: ${{ needs.deploy_infrastructure.outputs.backendAppName }}
    publish-profile: ${{ secrets.BACKEND_PUBLISH_PROFILE }}
    package: backend
```

## Clean Up Resources

When you no longer need these resources, you can delete the resource group to avoid incurring further charges:

```bash
az group delete --name ghcv-<environment>-rg --yes
```

Replace `<environment>` with the environment you deployed (dev, stage, or prod).

## Additional Configuration

### GitHub Personal Access Token

If you're accessing private GitHub repositories through the API, consider creating a GitHub personal access token to increase the rate limit:

1. Go to your GitHub **Settings** > **Developer settings** > **Personal access tokens** > **Tokens (classic)**
2. Generate a new token with at least the `public_repo` scope
3. Add it as a secret named `GITHUB_TOKEN` in your repository
4. Uncomment the token usage in the `server.js` file

### Configure CORS to Your Domain

When deploying to production, update the CORS settings to only allow your specific domains:

1. Modify the `infra/main.bicep` file to update the CORS allowed origins with your custom domain
2. Update the `REACT_APP_API_URL` in the frontend settings to point to your API domain
