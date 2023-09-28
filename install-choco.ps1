$securityProtocolSettingsOriginal = [System.Net.ServicePointManager]::SecurityProtocol
try {
    [System.Net.ServicePointManager]::SecurityProtocol = 3072 -bor 768 -bor 192 -bor 48
}
catch {
    Write-Warning "Unable to set PowerShell to use TLS 1.2 and TLS 1.1 check .NET Framework installed. If you see underlying connection closed or trust errors, try the following: (1) upgrade to .NET Framework 4.5 (2) specify internal Chocolatey package location (set $env:chocolateyDownloadUrl prior to install or host the package internally), (3) use the Download + PowerShell method of install. See https://chocolatey.org/install for all install options."
}
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
[System.Net.ServicePointManager]::SecurityProtocol = $securityProtocolSettingsOriginal