[![Build Status](https://dev.azure.com/defragovuk/DEFRA-FFC/_apis/build/status%2FADP%2FCore%2Fplatform-adp-core?repoName=DEFRA%2Fadp-infrastructure-core&branchName=main)](https://dev.azure.com/defragovuk/DEFRA-FFC/_build/latest?definitionId=4407&repoName=DEFRA%2Fadp-infrastructure-core&branchName=main)

# ADP Infrastructure - Core

Welcome to the ADP Infrastructure Core repository. This repository contains the 'core' and 'shared' platform infrastructure modules (Azure Bicep), scripts (Powershell, CLI), libraries, and Azure DevOps Pipelines that are used to build, support, and run the Azure Development Platform. All infrastructure modules and scripts in this repo are owned and managed by the ADP Platform Engineering Team. As this contains all the 'shared' infrastructure that all Tenants will use, no 'Tenant/Team' specific logic should reside here. The Infrastructure Services repository for Platform Tenants/Teams can be found here: https://github.com/DEFRA/adp-infrastructure-services that contains the Service logic.

## Repository Structure

The Platform uses infrastructure parameter files (.bicepParams) to instantiate pre-configured (_by ADP Platform Engineering_) and agnostic infrastructure modules (.bicep templates). 

* `azureDevOps` - Platform Generic Azure DevOps Pipeline YAML Files. This instantiates [ado-pipeline-common](https://github.com/DEFRA/ado-pipeline-common)
* `infra` - Platform Services Infrastructure folder. Contains Shared & Core infrastructure module instantiations.
* `nginxPlus` - Contains the AKS Cluster NGINX Ingress Controller Scripts.
* `scripts/modules` - Contains the Powershell scripts, modules and libraries that support the infrastructure deployments and configuration. 

## Service Connection documentation

Azure Resurce Manager(arm) Service Connections can be created or updated by referencing a `json manifest file`.

This script creates or updates the service connection and it also verify it. It uses "ServicePrincipal" scheme for authorization and you will need to supply ServicePrincipal clientID and ClientSecret details through keyvault.

This script uses $env:SYSTEM_ACCESSTOKEN and Project build service identity should be granted required permissions to perform create or update service endpoint operatins. For e.g. To create service connection in Defra-XXX project 'DEFRA-XXX Build Service (defragovuk)' identity should be granted 'Administrator' permissions at Service connection scope.

The json manifest file can be parameterised by adding place-holder (e.g. `#{{ yamlVariableName }}`). The place-holder will be replaced with values set in the yaml variable templates.


| :Note: Only Service connection of type azurerm can be created using this script and scope level is limited to subscription.   |
|:----------|


#### **Not supported features**

  * Currently Sharing service connection with other projects is not supported. 


#### **Invoking Initialize-ServiceEndpoint.ps1**

It can be used as a `preDeployScriptsList` or `postDeployScriptsList` of the pipeline-template `common-infrastructure-deploy.yaml` or `scriptsList` of the pipeline-template `common-scripts-deploy.yaml`. 

| :Note: The Type of the script must be set to 'AzureCLI' as it internally uses `az devops` commands. `useSystemAccessToken` should set to `true`.|
|:----------|

```yaml
extends:
  template: /templates/pipelines/common-infrastructure-deploy.yaml@PipelineCommon
  parameters:
    projectName: MyProjectName  
    groupedTemplates:
      - name: MyGroupName
        templates:
          - name: ArmTemplateName
            path: ArmTemplateFolder
            scope: Resource Group
            resourceGroupName: MyResourceGroupName
            postDeployScriptsList:
              - displayName: Create or Update AzureRm Service Endpoint(Service Connection)
                Type: AzureCLI
                useSystemAccessToken: true
                filePathsForTransform:
                  - 'infra/config/service-connections/tier2-service-connection.json'
                scriptPath: 'scripts/ado/Initialize-ServiceEndpoint.ps1'
                ScriptArguments: >
                  -ServiceEndpointJsonPath 'infra/config/service-connections/tier2-service-connection.json'
                  -WorkingDirectory $(Pipeline.Workspace)\s\self      
```

#### **Structure of the manifest file**
Example `manifest.json` file
```json
{
    "azureRMServiceConnections": [
        {
            "displayName": "Service endpoint Name",
            "description": "ADO automatic Service Connection",
            "tenantId":  "#{{ TenantId }}",
            "subscriptionId":  "#{{ SubscriptionId }}",
            "subscriptionName":  "#{{ SubscriptionName }}",
            "keyVault": {
                "name": "#{{ ssvPlatformKeyVaultName }}",
                "secrets": [
                    {
                        "key": "Keyvault secret name of Service connection's service principal clientID",
                        "type": "ClientId"
                    },
                    {
                        "key": "Keyvault secret name of Service connection's service principal clientSecret",
                        "type": "ClientSecret"
                    }
                ]
            },
            "isShared": false
          }        
    ]
}


```

#### Mandatory properties
* `displayName` Name of the service endpoint to create

* `description` Service Connection description

* `tenantId` Tenant id for creating azure rm service endpoint

* `subscriptionId` Subscription id for azure rm service endpoint

* `subscriptionName` Name of azure subscription for azure rm service endpoint

* `keyVault` Keyvault name to load Service connection secrets from (service principal clientID and clientSecret)


#### Optional properties
* `isShared` Default is false. Currently Share service connection is not supported. 
