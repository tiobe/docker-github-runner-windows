
# Set the runner name
if ($null -ne $env:RUNNER_NAME) {
  $RUNNER_NAME = $env:RUNNER_NAME
} else {
  if ($null -ne $env:RUNNER_NAME_PREFIX) {
    $RUNNER_NAME = $env:RUNNER_NAME_PREFIX
  } else {
    $RUNNER_NAME = "windows-runner"
  }

  $RUNNER_NAME += "-" + (((New-Guid).Guid).replace("-", "")).substring(0, 8)
}

# Set GitHub host if not set
if ($null -ne $env:GITHUB_HOST) { 
  $GITHUB_HOST = $env:GITHUB_HOST
} else {
  $GITHUB_HOST = 'github.com'
}

# Set the api url
if ('github.com' -eq $GITHUB_HOST) {
  $URI = "https://api.$GITHUB_HOST"
} else {
  $URI = "https://$GITHUB_HOST/api/v3"
}

# Set the api to get the access token from
switch ($env:RUNNER_SCOPE) {
  org {
    if ($null -eq $env:ORG_NAME) {
      Write-Error "ORG_NAME required for organisational runners"
      exit 1
    }
    Write-Host "Setting up GitHub Self Hosted Runner for organisation: $env:ORG_NAME"
    $TOKEN_URL = "$URI/orgs/$env:ORG_NAME/actions/runners/registration-token"
    $CONFIG_URL = "https://$GITHUB_HOST/$env:ORG_NAME"
  }

  enterprise {
    if ($null -eq $env:ENTERPRISE_NAME) {
      Write-Error "ENTERPRISE_NAME required for enterprise runners"
      exit
    }
    Write-Host "Setting up GitHub Self Hosted Runner for enterprise: $env:ENTERPRISE_NAME"
    $TOKEN_URL = "$URI/enterprises/$env:ENTERPRISE_NAME/actions/runners/registration-token"
    $CONFIG_URL = "https://$GITHUB_HOST/enterprises/$env:ENTERPRISE_NAME"
  }

  default {
    if ($null -eq $env:REPO_URL) {
      Write-Error "REPO_URL required for repository runners"
      exit
    }
    if ($null -ne $env:RUNNER_TOKEN) {
      $RUNNER_TOKEN = $env:RUNNER_TOKEN
    } elseif ($null -ne $env:ACCESS_TOKEN) {
      $PATTERN = "https://(?:[^/]+/)?([^/]+)/([^/]+)"
      if ($env:REPO_URL -match $PATTERN) {
        
        $OWNER = $Matches[1]
        $REPO = $Matches[2]

        $TOKEN_URL = "$URI/repos/$OWNER/$REPO/actions/runners/registration-token"
      } else {
        Write-Error "URL format not recognized: $env:REPO_URL"
      }
    } else {
      Write-Error "ACCESS_TOKEN or RUNNER_TOKEN required for repository runners"
      exit
    }
    Write-Host "Setting up GitHub Self Hosted Runner for repository: $env:REPO_URL"
    
    $CONFIG_URL = $env:REPO_URL
  }
}

if ($null -ne $TOKEN_URL) {
  $HEADERS = @{
    'Accept' = 'application/vnd.github.v3+json';
    'Authorization' = "token $env:ACCESS_TOKEN";
    'Content-Length' = '0';
  }

  try {
    Write-Host "Obtaining the token for the runner"
    $RUNNER_TOKEN = ((Invoke-WebRequest -Uri $TOKEN_URL -Method "POST" -Headers $HEADERS).Content | ConvertFrom-Json).token
  }
  catch {
    Write-Error "Cannot obtain the token => $_.Exception.Message"
    exit
  }
}

# Set the labels if given
if ($null -ne $env:LABELS) { 
  $LABELS = $env:LABELS
} else {
  $LABELS = 'default'
}

# Set the labels if given
if ($null -ne $env:RUNNER_GROUP) { 
  $RUNNER_GROUP = $env:RUNNER_GROUP
} else {
  $RUNNER_GROUP = 'Default'
}

$EXTRA_ARGS=''

# Disable auto update if set
if ($null -ne $env:DISABLE_AUTO_UPDATE) { 
  Write-Host "Auto updating is disabled"
  $EXTRA_ARGS += " --disableupdate"
}

try {
  Write-Host "Configuring runner: $RUNNER_NAME"
  ./config.cmd --unattended --replace --url $CONFIG_URL --token $RUNNER_TOKEN --name $RUNNER_NAME --labels $LABELS --runnergroup $RUNNER_GROUP $EXTRA_ARGS

  # Remove access token for security reasons
  $env:ACCESS_TOKEN=$null

  ./run.cmd
} catch {
  Write-Error $_.Exception.Message
} finally {
  ./config.cmd remove --unattended --token $RUNNER_TOKEN
}