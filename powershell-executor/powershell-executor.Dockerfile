ARG IMAGE_TAG=lts-7.2-ubuntu-22.04

FROM mcr.microsoft.com/powershell:${IMAGE_TAG}

# Use root user for installation
USER root

# Install Git
RUN apt-get update && apt-get install -y git

ARG DEBIAN_FRONTEND=noninteractive
RUN apt install -y -f postgresql postgresql-contrib

# Change default shell to powershell
SHELL ["pwsh", "-Command"]

# Install Az Module in Powershell
RUN pwsh -Command Install-Module -Name Az -Repository PSGallery -Force -AllowClobber

# Clone the repo and Run the powershell script and pass the params to it
CMD git clone $env:GIT_REPO_URL -b $env:GIT_BRANCH; $workingDir = $env:GIT_REPO_URL.Split('/')[-1].Replace('.git', ''); cd $workingDir; $cmd ="pwsh -File $env:SCRIPT_FILE_NAME"; Write-Host $cmd; Invoke-Expression $cmd