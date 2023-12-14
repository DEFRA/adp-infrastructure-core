[CmdletBinding()]
param(
    [Parameter(Mandatory)] 
    [string]$TemplatesPath,
    [Parameter(Mandatory)]
    [string]$OnBoardingManifest,
    [Parameter(Mandatory)] 
    [string]$FluxServicesPath,
    [Parameter(Mandatory)]
    [string]$PSHelperDirectory
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
            Write-Host "$DirectoryPath doesn't exist, creating it"
            New-Item -Path $DirectoryPath -Type Directory
        }
        else {
            Write-Host "$DirectoryPath exists, no need to create it"
        }
    }

    end {
        Write-Debug "${functionName}:Exited"
    }
}

function New-FeatureBranch {
    param(
        [Parameter(Mandatory)]
        [string]$ProgrammeName
    )
    begin {
        [string]$functionName = $MyInvocation.MyCommand
        Write-Debug "${functionName}:Entered"
        Write-Debug "${functionName}:ProgrammeName=$ProgrammeName"
    }
    process {
        [string]$userEmail = "ado@noemail.com"
        [string]$userName = "Devops"

        [string]$gitUserEmailCommand = "git config user.email $userEmail"
        Write-Host $gitUserEmailCommand
        Invoke-CommandLine -Command $gitUserEmailCommand | Out-Null

        [string]$gitUserNameCommand = "git config user.name $userName"
        Write-Host $gitUserNameCommand
        Invoke-CommandLine -Command $gitUserNameCommand | Out-Null

        [string]$gitPullCommand = "git pull origin main"
        Write-Host $gitPullCommand
        Invoke-CommandLine -Command $gitPullCommand | Out-Null

        [string]$gitCheckoutCommand = "git checkout -b feature-$ProgrammeName-onboarding"
        Write-Host $gitCheckoutCommand
        Invoke-CommandLine -Command $gitCheckoutCommand | Out-Null

        [string]$gitStagingCommand = "git add -A"
        Write-Host $gitStagingCommand
        Invoke-CommandLine -Command $gitStagingCommand | Out-Null

        [string]$commitMessage = "Add Flux Services for $ProgrammeName"
        [string]$author = "ADO Devops <ado@noemail.com>"
        [string]$gitCommitCommand = "git commit -am '$commitMessage' --author='$author'"
        Write-Host $gitCommitCommand
        Invoke-CommandLine -Command $gitCommitCommand | Out-Null

        [string]$gitPushCommand = "git push --set-upstream origin feature-$ProgrammeName-onboarding"
        Write-Host $gitPushCommand
        Invoke-CommandLine -Command $gitPushCommand | Out-Null
    }
    end {
        Write-Debug "${functionName}:Exited"
    }
}

Set-StrictMode -Version 3.0

[string]$functionName = $MyInvocation.MyCommand
[datetime]$startTime = [datetime]::UtcNow

[int]$exitCode = -1
[bool]$setHostExitCode = (Test-Path -Path ENV:TF_BUILD) -and ($ENV:TF_BUILD -eq "true")
[bool]$enableDebug = (Test-Path -Path ENV:SYSTEM_DEBUG) -and ($ENV:SYSTEM_DEBUG -eq "true")

Set-Variable -Name ErrorActionPreference -Value Continue -scope global
Set-Variable -Name InformationPreference -Value Continue -Scope global

if ($enableDebug) {
    Set-Variable -Name VerbosePreference -Value Continue -Scope global
    Set-Variable -Name DebugPreference -Value Continue -Scope global
}

Write-Host "${functionName} started at $($startTime.ToString('u'))"
Write-Debug "${functionName}:TemplatesPath=$TemplatesPath"
Write-Debug "${functionName}:OnBoardingManifest=$OnBoardingManifest"
Write-Debug "${functionName}:FluxServicesPath=$FluxServicesPath"
Write-Debug "${functionName}:PSHelperDirectory=$PSHelperDirectory"

try {
    Write-Host "Import module:PSHelperDirectory=$PSHelperDirectory"
    Import-Module $PSHelperDirectory -Force

    [hashtable]$programmeDetails = $OnBoardingManifest | ConvertFrom-Json -AsHashtable

    [string]$programmeName = $programmeDetails.name
    [string]$serviceCode = $programmeDetails.servicecode
    [array]$services = $programmeDetails.services
    [array]$environments = $programmeDetails.environments

    [hashtable]$lookupTable = @{
        '__PROGRAMME_NAME__' = $programmeName
        '__SERVICE_CODE__'   = $serviceCode
        '__SERVICE_NAME__'   = 'PLACEHOLDER'
        '__ENVIRONMENT__'    = 'PLACEHOLDER'
        '__ENV_INSTANCE__'   = 'PLACEHOLDER'
        '__DEPENDS_ON__'     = 'infra'
    }

    [string]$programmePath = "$FluxServicesPath\$programmeName"
    [string]$programmeBaseDirectory = "$programmePath\base"

    New-Directory -DirectoryPath $programmePath
    New-Directory -DirectoryPath $programmeBaseDirectory

    [string]$templateProgrammePath = "$TemplatesPath/programme"
    [string]$templateProgrammeBasePath = "$templateProgrammePath/base"
    [string]$templateProgrammeServicePath = "$templateProgrammePath/service"
    [string]$templateProgrammeEnvironmentPath = "$templateProgrammePath/environment"

    # CREATE BASE DIRECTORIES AND FILES
    New-Directory -DirectoryPath "$programmeBaseDirectory/patch"
    Copy-Item -Path "$templateProgrammeBasePath/kustomization.yaml" -Destination "$programmeBaseDirectory/kustomization.yaml"
    Copy-Item -Path "$templateProgrammeBasePath/patch/kustomization.yaml" -Destination "$programmeBaseDirectory/patch/kustomization.yaml"
    ReplaceTokens -TemplateFile "$templateProgrammeBasePath/patch/kustomize.yaml" -DestinationFile "$programmeBaseDirectory/patch/kustomize.yaml"
    ReplaceTokens -TemplateFile "$templateProgrammeBasePath/helm-repository.yaml" -DestinationFile "$programmeBaseDirectory/helm-repository.yaml"

    # CREATE SERVICES DIRECTORIES AND FILES
    foreach ($service in $services) {
        New-Directory -DirectoryPath "$programmePath/$($service.name)/deploy/base"
        Copy-Item -Path "$templateProgrammeServicePath/kustomization.yaml" -Destination $programmePath/$($service.name)/kustomization.yaml
        Copy-Item -Path $templateProgrammeServicePath/deploy/base/* -Destination $programmePath/$($service.name)/deploy/base -Recurse
    
        $lookupTable['__SERVICE_NAME__'] = $service.name
        $lookupTable['__DEPENDS_ON__'] = 'infra'

        if ($service['dbMigration']) {
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

        if ($service['dbMigration']) {
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

                if ($service['ingress']) {
                    ReplaceTokens -TemplateFile "$templateProgrammeServicePath/deploy/environment/patch-ingress.yaml" -DestinationFile "$programmePath/$($service.name)/deploy/$($environment.name)/0$instance/patch.yaml"
                }
                else {
                    ReplaceTokens -TemplateFile "$templateProgrammeServicePath/deploy/environment/patch.yaml" -DestinationFile "$programmePath/$($service.name)/deploy/$($environment.name)/0$instance/patch.yaml"
                }

                if ($service['dbMigration']) {
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

    # CREATE ENVIRONMENT DIRECTORIES AND FILES
    foreach ($environment in $environments) {
        foreach ($instance in $environment.instances) {
            New-Directory -DirectoryPath "$programmePath/$($environment.name)/0$instance"
            Copy-Item -Path "$templateProgrammeEnvironmentPath/*" -Destination $programmePath/$($environment.name)/0$instance -Recurse
        
            foreach ($service in $services) {
                Add-Content -Path $programmePath/$($environment.name)/0$instance/kustomization.yaml -Value "  - ../../$($service.name)"
            }
        }
    }

    # CREATE FEATURE BRANCH IN ADP-SERVICES-FLUX
    New-FeatureBranch -ProgrammeName $programmeName

    $exitCode = 0
}
catch {
    $exitCode = -2
    Write-Error $_.Exception.ToString()
    throw $_.Exception
}
finally {
    [DateTime]$endTime = [DateTime]::UtcNow
    [Timespan]$duration = $endTime.Subtract($startTime)

    Write-Host "${functionName} finished at $($endTime.ToString('u')) (duration $($duration -f 'g')) with exit code $exitCode"
    if ($setHostExitCode) {
        Write-Debug "${functionName}:Setting host exit code"
        $host.SetShouldExit($exitCode)
    }
    exit $exitCode
}