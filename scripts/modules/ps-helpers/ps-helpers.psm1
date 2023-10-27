<#
.SYNOPSIS
    Invoke a command and return the output.
.DESCRIPTION
    Invoke a command and return the output.
.PARAMETER Command
    The command to invoke.
.PARAMETER IsSensitive
    If true, the command will be hidden.
.PARAMETER IgnoreErrorCode
    If true, the command ignore the error.
.PARAMETER ReturnExitCode
    If true, the command will return LASTEXITCODE.
#>

function Invoke-CommandLine {
    param(
        [Parameter(Mandatory)]
        [string]$Command,
        [switch]$IsSensitive,
        [switch]$IgnoreErrorCode,
        [switch]$ReturnExitCode,
        [switch]$NoOutput
    )
  
    [string]$functionName = $MyInvocation.MyCommand
    Write-Debug "${functionName}:Entered"
    Write-Debug "${functionName}:IsSensitive=$IsSensitive"
    Write-Debug "${functionName}:IgnoreErrorCode=$IgnoreErrorCode"
    Write-Debug "${functionName}:ReturnExitCode=$ReturnExitCode"
  
    if ($IsSensitive) {
        Write-Debug "${functionName}:Command=<hidden>"
    } 
    else {
        Write-Debug "${functionName}:Command=$Command"
    }
  
    [string]$errorMessage = ""
    [string]$warningMessage = ""
    [string]$outputMessage = ""
    [string]$informationMessage = ""
  
    $output = Invoke-Expression -Command $Command -ErrorVariable errorMessage -WarningVariable warningMessage -OutVariable outputMessage -InformationVariable informationMessage 
    [int]$errCode = $LASTEXITCODE
  
    Write-Debug "${functionName}:output="
    $output | Write-Debug
    Write-Debug "${functionName}:errCode=$errCode"
  
    if (-not [string]::IsNullOrWhiteSpace($outputMessage)) { 
        Write-Debug "${functionName}:outputMessage=$outputMessage"
        Write-Verbose $outputMessage 
    }
  
    if (-not [string]::IsNullOrWhiteSpace($informationMessage)) { 
        Write-Debug "${functionName}:informationMessage=$informationMessage"
        Write-Verbose $informationMessage 
    }
  
    if (-not [string]::IsNullOrWhiteSpace($warningMessage)) {
        Write-Debug "${functionName}:warningMessage=$warningMessage"
        Write-Warning $warningMessage 
    }
  
    if (-not [string]::IsNullOrWhiteSpace($errorMessage)) {
        Write-Debug "${functionName}:errorMessage=$errorMessage"
        Write-Verbose $errorMessage
        Write-Error $errorMessage
        throw "$errorMessage"
    }
  
    if ($errCode -ne 0 -and -not $IgnoreErrorCode) {
        throw "unexpected exit code $errCode"
    }
  
    if ($ReturnExitCode) {
        Write-Output $errCode
    }
    elseif (-not $NoOutput) {
        Write-Output $output
    }
    Write-Debug "${functionName}:Exited"
  }

  