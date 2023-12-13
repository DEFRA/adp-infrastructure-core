[CmdletBinding()]
param(
    [Parameter(Mandatory)] 
    [string]$TemplatesPath,
    [Parameter(Mandatory)]
    [string]$OnBoardingManifest,
    [Parameter(Mandatory)] 
    [string]$FluxServicesPath
)

function ReplaceTokens {
    param(
        [Parameter(Mandatory)]
        [string]$TemplateFile,
        [Parameter(Mandatory)]
        [string]$DestinationFile
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand
        Write-Debug "${functionName}:Entered"
        Write-Debug "${functionName}:TemplateFile=$TemplateFile"
        Write-Debug "${functionName}:DestinationFile=$DestinationFile"
    }
    process {  
        Get-Content -Path $TemplateFile | ForEach-Object {
            $line = $_
        
            $lookupTable.GetEnumerator() | ForEach-Object {
                if ($line -match $_.Key) {
                    $line = $line -replace $_.Key, $_.Value
                }
            }
            $line
        } | Set-Content -Path $DestinationFile
    }

    end {
        Write-Debug "${functionName}:Exited"
    }
}

function New-Directory {
    param(
        [Parameter(Mandatory)]
        [string]$DirectoryPath
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand
        Write-Debug "${functionName}:Entered"
        Write-Debug "${functionName}:DirectoryPath=$DirectoryPath"
    }
    process {  
        if (-not (test-path $DirectoryPath) ) {
            write-host "$DirectoryPath doesn't exist, creating it"
            New-Item -Path $DirectoryPath -Type Directory
        }
        else {
            write-host "$DirectoryPath exists, no need to create it"
        }
    }

    end {
        Write-Debug "${functionName}:Exited"
    }
}

# $TemplatesPath = 'C:\Users\asaarif\GitRepos\adp-flux-services-onboarding-aa\templates'
# $FluxServicesPath = 'C:\Users\asaarif\GitRepos\adp-flux-services-1\services'

[hashtable]$programmeDetails = $OnBoardingManifest | ConvertFrom-Json -AsHashtable
# [PSCustomObject]$programmeDetails = Get-Content -Raw -Path $OnBoardingManifest | ConvertFrom-Json -AsHashtable

$programmeName = $programmeDetails.name
$serviceCode = $programmeDetails.servicecode
$services = $programmeDetails.services
$environments = $programmeDetails.environments
$programmePath = "$FluxServicesPath\$programmeName"
$programmeBaseDirectory = "$programmePath\base"

$lookupTable = @{
    '__PROGRAMME_NAME__' = $programmeName
    '__SERVICE_CODE__'   = $serviceCode
    '__SERVICE_NAME__'   = 'PLACEHOLDER'
    '__ENVIRONMENT__'    = 'PLACEHOLDER'
    '__ENV_INSTANCE__'   = 'PLACEHOLDER'
    '__DEPENDS_ON__'     = 'infra'
}

# # Create programme directory
# New-Item -Path $programmePath -Type Directory -Force # Should we use force

# # Create base directory
# New-Item -Path $programmeBaseDirectory -Type Directory -Force # Should we use force

New-Directory -DirectoryPath $programmePath
New-Directory -DirectoryPath $programmeBaseDirectory

#TEMPLATE PATHS
$templateProgrammePath = "$TemplatesPath/programme"
$templateProgrammeBasePath = "$templateProgrammePath/base"
$templateProgrammeServicePath = "$templateProgrammePath/service"
$templateProgrammeEnvironmentPath = "$templateProgrammePath/environment"

New-Directory -DirectoryPath "$programmeBaseDirectory/patch"
Copy-Item -Path "$templateProgrammeBasePath/kustomization.yaml" -Destination "$programmeBaseDirectory/kustomization.yaml"
Copy-Item -Path "$templateProgrammeBasePath/patch/kustomization.yaml" -Destination "$programmeBaseDirectory/patch/kustomization.yaml"
ReplaceTokens -TemplateFile "$templateProgrammeBasePath/patch/kustomize.yaml" -DestinationFile "$programmeBaseDirectory/patch/kustomize.yaml"
ReplaceTokens -TemplateFile "$templateProgrammeBasePath/helm-repository.yaml" -DestinationFile "$programmeBaseDirectory/helm-repository.yaml"

# Create services directory
foreach ($service in $services) {
    New-Directory -DirectoryPath "$programmePath/$($service.name)/deploy/base"
    Copy-Item -Path "$templateProgrammeServicePath/kustomization.yaml" -Destination $programmePath/$($service.name)/kustomization.yaml
    Copy-Item -Path $templateProgrammeServicePath/deploy/base/* -Destination $programmePath/$($service.name)/deploy/base -Recurse
    
    $lookupTable['__SERVICE_NAME__'] = $service.name
    $lookupTable['__DEPENDS_ON__'] = 'infra'

    if ($service.dbMigration) {
        $lookupTable['__DEPENDS_ON__'] = 'pre-deploy'
        New-Directory -DirectoryPath "$programmePath/$($service.name)/pre-deploy/base"
        Copy-Item -Path $templateProgrammeServicePath/pre-deploy/base/* -Destination $programmePath/$($service.name)/pre-deploy/base -Recurse
        ReplaceTokens -TemplateFile "$templateProgrammeServicePath/pre-deploy/base/image-repository-dbmigration.yaml" -DestinationFile "$programmePath/$($service.name)/pre-deploy/base/image-repository-dbmigration.yaml"
        ReplaceTokens -TemplateFile "$templateProgrammeServicePath/pre-deploy/base/migration.job.yaml" -DestinationFile "$programmePath/$($service.name)/pre-deploy/base/migration.job.yaml"
        ReplaceTokens -TemplateFile "$templateProgrammeServicePath/pre-deploy-kustomize.yaml" -DestinationFile "$programmePath/$($service.name)/pre-deploy-kustomize.yaml"
        Add-Content -Path $programmePath/$($service.name)/kustomization.yaml -Value "  - pre-deploy-kustomize.yaml"
    }

    ReplaceTokens -TemplateFile "$templateProgrammeServicePath/deploy-kustomize.yaml" -DestinationFile "$programmePath/$($service.name)/deploy-kustomize.yaml"
    ReplaceTokens -TemplateFile "$templateProgrammeServicePath/infra-kustomize.yaml" -DestinationFile "$programmePath/$($service.name)/infra-kustomize.yaml"
    ReplaceTokens -TemplateFile "$templateProgrammeServicePath/deploy/base/helm-release.yaml" -DestinationFile "$programmePath/$($service.name)/deploy/base/helm-release.yaml"

    New-Directory -DirectoryPath "$programmePath/$($service.name)/infra/base"
    Copy-Item -Path "$templateProgrammeServicePath/infra/base/*" -Destination $programmePath/$($service.name)/infra/base -Recurse
    ReplaceTokens -TemplateFile "$templateProgrammeServicePath/infra/base/aso-helm-release.yaml" -DestinationFile "$programmePath/$($service.name)/infra/base/aso-helm-release.yaml"
    ReplaceTokens -TemplateFile "$templateProgrammeServicePath/infra/base/image-repository.yaml" -DestinationFile "$programmePath/$($service.name)/infra/base/image-repository.yaml"

    if ($service.dbMigration) {
        New-Directory -DirectoryPath "$programmePath/$($service.name)/pre-deploy/base"
        Copy-Item -Path $templateProgrammeServicePath/pre-deploy/base/* -Destination $programmePath/$($service.name)/pre-deploy/base -Recurse
        ReplaceTokens -TemplateFile "$templateProgrammeServicePath/pre-deploy/base/image-repository-dbmigration.yaml" -DestinationFile "$programmePath/$($service.name)/pre-deploy/base/image-repository-dbmigration.yaml"
        ReplaceTokens -TemplateFile "$templateProgrammeServicePath/pre-deploy/base/migration.job.yaml" -DestinationFile "$programmePath/$($service.name)/pre-deploy/base/migration.job.yaml"
    }

    foreach ($environment in $environments) {
        $lookupTable['__ENVIRONMENT__'] = $($environment.name)
        foreach ($instance in $environment.instances) {
            $lookupTable['__ENV_INSTANCE__'] = $instance
            New-Directory -DirectoryPath "$programmePath/$($service.name)/deploy/$($environment.name)/0$instance"
            Copy-Item -Path $templateProgrammeServicePath/deploy/environment/kustomization.yaml -Destination $programmePath/$($service.name)/deploy/$($environment.name)/0$instance/kustomization.yaml

            if ($service.ingress) {
                ReplaceTokens -TemplateFile "$templateProgrammeServicePath/deploy/environment/patch-ingress.yaml" -DestinationFile "$programmePath/$($service.name)/deploy/$($environment.name)/0$instance/patch.yaml"
            } else {
                ReplaceTokens -TemplateFile "$templateProgrammeServicePath/deploy/environment/patch.yaml" -DestinationFile "$programmePath/$($service.name)/deploy/$($environment.name)/0$instance/patch.yaml"
            }

            if ($service.dbMigration) {
                New-Directory -DirectoryPath "$programmePath/$($service.name)/pre-deploy/$($environment.name)/0$instance"
                Copy-Item -Path $templateProgrammeServicePath/pre-deploy/environment/* -Destination $programmePath/$($service.name)/pre-deploy/$($environment.name)/0$instance -Recurse
                ReplaceTokens -TemplateFile "$templateProgrammeServicePath/pre-deploy/environment/image-policy.yaml" -DestinationFile "$programmePath/$($service.name)/pre-deploy/$($environment.name)/0$instance/image-policy.yaml"
                ReplaceTokens -TemplateFile "$templateProgrammeServicePath/pre-deploy/environment/patch.yaml" -DestinationFile "$programmePath/$($service.name)/pre-deploy/$($environment.name)/0$instance/patch.yaml"
            }

            New-Directory -DirectoryPath $programmePath/$($service.name)/infra/$($environment.name)/0$instance
            Copy-Item -Path "$templateProgrammeServicePath/infra/environment/*" -Destination $programmePath/$($service.name)/infra/$($environment.name)/0$instance -Recurse
            ReplaceTokens -TemplateFile "$templateProgrammeServicePath/infra/environment/patch.yaml" -DestinationFile "$programmePath/$($service.name)/infra/$($environment.name)/0$instance/patch.yaml"
            ReplaceTokens -TemplateFile "$templateProgrammeServicePath/infra/environment/image-policy.yaml" -DestinationFile "$programmePath/$($service.name)/infra/$($environment.name)/0$instance/image-policy.yaml"
        }
    }
}

foreach ($environment in $environments) {
    foreach ($instance in $environment.instances) {
        New-Directory -DirectoryPath "$programmePath/$($environment.name)/0$instance"
        Copy-Item -Path "$templateProgrammeEnvironmentPath/*" -Destination $programmePath/$($environment.name)/0$instance -Recurse
        
        foreach ($service in $services) {
            Add-Content -Path $programmePath/$($environment.name)/0$instance/kustomization.yaml -Value "  - ../../$($service.name)"
        }
    }
}

[string]$userEmail = "ado@noemail.com"
[string]$userName = "Devops"

git config user.email $userEmail

git config user.name $userName

git pull origin main

git checkout -b "feature-$($programmeName)-onboarding"

# git pull origin main

git add -A

[string]$commitMessage = "Add new version flux project"
[string]$author = "ADO Devops <ado@noemail.com>"
git commit -am $commitMessage --author=$author

git status

git push --set-upstream origin "feature-$($programmeName)-onboarding"