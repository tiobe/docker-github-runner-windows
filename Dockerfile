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
    python \
    docker-cli

# Add MSBuild to the path
RUN [Environment]::SetEnvironmentVariable(\"Path\", $env:Path + \";C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\", \"Machine\")

COPY install-runner.ps1 .
RUN .\install-runner.ps1; Remove-Item .\install-runner.ps1 -Force

COPY entrypoint.ps1 .

ENTRYPOINT ["pwsh.exe", ".\\entrypoint.ps1"]
