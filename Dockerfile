FROM mcr.microsoft.com/windows/servercore:ltsc2022

ARG RUNNER_VERSION="2.311.0"

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]

# Set working directory
WORKDIR /actions-runner

COPY install-choco.ps1 .
RUN .\install-choco.ps1; Remove-Item .\install-choco.ps1 -Force

# Install dependencies with Chocolatey
RUN choco install -y \
    git \
    gh \
    powershell-core \
    python

RUN choco install -y visualstudio2022buildtools --package-parameters \" \
    --quiet --norestart \
    --add Microsoft.VisualStudio.Workload.VisualStudioExtensionBuildTools \
    --add Microsoft.VisualStudio.Workload.ManagedDesktopBuildTools \
    --add Microsoft.NetCore.Component.SDK \
    --add Microsoft.Net.Component.4.6.1.TargetingPack \
    --add Microsoft.Net.Component.4.8.TargetingPack \
    \"

# Add MSBuild to the path
RUN [Environment]::SetEnvironmentVariable(\"Path\", $env:Path + \";C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\", \"Machine\")

COPY install-runner.ps1 .
RUN .\install-runner.ps1; Remove-Item .\install-runner.ps1 -Force

COPY entrypoint.ps1 .

ENTRYPOINT ["pwsh.exe", ".\\entrypoint.ps1"]