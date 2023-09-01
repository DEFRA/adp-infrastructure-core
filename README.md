# adp-infrastructure
Infrastructure Repo for the ADP.


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