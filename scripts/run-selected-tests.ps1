param(
  [string]$Root = "C:\Users\vidhuad\CMS-Automation\CMS-env-tests",
  [switch]$Headed,
  [string[]]$EmailTo = @(),
  [string]$EmailFrom = "",
  [string]$SmtpServer = "",
  [int]$SmtpPort = 25,
  [switch]$UseSsl,
  [string]$SmtpUser = "",
  [string]$SmtpPassword = ""
)

# Load .env (if present) and set missing environment variables so both the script and child processes can use them.
$envFilePath = Join-Path $Root '.env'
if (Test-Path $envFilePath) {
  Get-Content $envFilePath | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith('#')) {
      $parts = $line -split '=',2
      if ($parts.Count -eq 2) {
        $k = $parts[0].Trim()
        $v = $parts[1]
        if (-not [string]::IsNullOrEmpty(${env:$k})) { return }
        ${env:$k} = $v
      }
    }
  }
}

# Map common environment variables to script parameters when parameters were not provided.
if ([string]::IsNullOrWhiteSpace($EmailFrom) -and $env:EMAIL_FROM) { $EmailFrom = $env:EMAIL_FROM }
if ($EmailTo.Count -eq 0 -and $env:EMAIL_TO) { $EmailTo = $env:EMAIL_TO -split ',' | ForEach-Object { $_.Trim() } }
if ([string]::IsNullOrWhiteSpace($SmtpServer) -and $env:SMTP_SERVER) { $SmtpServer = $env:SMTP_SERVER }
if ($SmtpPort -eq 25 -and $env:SMTP_PORT) { $SmtpPort = [int]$env:SMTP_PORT }
if (-not $UseSsl -and $env:SMTP_USE_SSL) { if ($env:SMTP_USE_SSL -match '^(1|true)$') { $UseSsl = $true } }
if ([string]::IsNullOrWhiteSpace($SmtpUser) -and $env:SMTP_USER) { $SmtpUser = $env:SMTP_USER }
if ([string]::IsNullOrWhiteSpace($SmtpPassword) -and $env:SMTP_PASSWORD) { $SmtpPassword = $env:SMTP_PASSWORD }

$ErrorActionPreference = "Stop"

$logDir = Join-Path $Root "scheduled-test-logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logPath = Join-Path $logDir "cms-ecourt-edocs-$timestamp.log"
$jsonPath = Join-Path $logDir "cms-ecourt-edocs-$timestamp.json"
$summaryPath = Join-Path $Root "test_summary.md"

Push-Location $Root
try {
  "Started: $(Get-Date -Format o)" | Tee-Object -FilePath $logPath

  $specs = @(
    "tests/cms/cmsstg_login.spec.js",
    "tests/ecourt/ecourt_login.spec.js",
    "tests/edocs/edocs_dev_direct_login.spec.js",
    "tests/edocs/edocs_portal_login.spec.js"
  )

  $headedArg = if ($Headed) { "--headed" } else { "" }
  $command = "npx playwright test $($specs -join ' ') --project=chrome --project=edge $headedArg --reporter=json"

  "`n> $command" | Tee-Object -FilePath $logPath -Append
  cmd /c "$command > `"$jsonPath`"" 2>&1 | Tee-Object -FilePath $logPath -Append
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed with exit code $LASTEXITCODE`: $command"
  }

  $jsonText = Get-Content $jsonPath -Raw
  $configIndex = $jsonText.IndexOf('"config"')
  if ($configIndex -lt 0) {
    throw "JSON reporter output was not found in $jsonPath"
  }
  $jsonStart = $jsonText.LastIndexOf("{", $configIndex)
  $jsonEnd = $jsonText.LastIndexOf("}")
  if ($jsonStart -lt 0 -or $jsonEnd -le $jsonStart) {
    throw "JSON reporter output was malformed in $jsonPath"
  }
  $jsonPayload = $jsonText.Substring($jsonStart, $jsonEnd - $jsonStart + 1)
  $result = $jsonPayload | ConvertFrom-Json
  $rows = New-Object System.Collections.Generic.List[string]
  $passed = 0
  $failed = 0
  $skipped = 0
  $tick = [char]96
  $fence = "$tick$tick$tick"

  function Add-SuiteResults {
    param(
      [object]$Suite,
      [string[]]$TitleParts = @()
    )

    if ($null -eq $Suite) {
      return
    }

    $nextTitleParts = $TitleParts
    if ($Suite.title -and (($Suite.title -replace "\\", "/") -ne $Suite.file)) {
      $nextTitleParts = $TitleParts + $Suite.title
    }

    if ($null -ne $Suite.suites) {
      foreach ($childSuite in $Suite.suites) {
        Add-SuiteResults -Suite $childSuite -TitleParts $nextTitleParts
      }
    }

    if ($null -ne $Suite.specs) {
      foreach ($spec in $Suite.specs) {
        foreach ($test in $spec.tests) {
          foreach ($runResult in $test.results) {
            $status = $runResult.status
            if ($status -eq "passed") { $passed++ }
            elseif ($status -eq "skipped") { $skipped++ }
            else { $failed++ }

            $durationSeconds = [math]::Round($runResult.duration / 1000, 1)
            $title = (($nextTitleParts + $spec.title) -join " > ") -replace "\|", "\|"
            $project = $test.projectName -replace "\|", "\|"
            $file = ($spec.file -replace "/", "\")
            $rows.Add("| $project | $tick$file$tick | $title | $status | ${durationSeconds}s |")
          }
        }
      }
    }
  }

  foreach ($suite in $result.suites) {
    Add-SuiteResults -Suite $suite
  }

  $passed = $result.stats.expected
  $failed = $result.stats.unexpected
  $skipped = $result.stats.skipped
  $total = $passed + $failed + $skipped
  $mode = if ($Headed) { "headed" } else { "headless" }
  $duration = [math]::Round($result.stats.duration / 1000, 1)
  $summary = @"
# CMS, eCourt, and eEDocs Test Summary

## Latest Run

- Started: $($result.stats.startTime)
- Machine path: $tick$Root$tick
- Browser projects: ${tick}chrome$tick, ${tick}edge$tick
- Mode: $mode
- Command:

${fence}powershell
$command
$fence

## Overall Result

- Total test runs: $total
- Passed: $passed
- Failed: $failed
- Skipped: $skipped
- Duration: ${duration}s
- JSON result: $tick$jsonPath$tick
- Console log: $tick$logPath$tick

## Test Results

| Browser | Spec | Test | Result | Duration |
| --- | --- | --- | --- | --- |
$($rows -join "`n")
"@

  Set-Content -Path $summaryPath -Value $summary
  "`nCompleted: $(Get-Date -Format o)" | Tee-Object -FilePath $logPath -Append
  "Summary: $summaryPath" | Tee-Object -FilePath $logPath -Append

  if ($EmailTo.Count -gt 0) {
    if ([string]::IsNullOrWhiteSpace($EmailFrom) -or [string]::IsNullOrWhiteSpace($SmtpServer)) {
      throw "EmailTo was provided, but EmailFrom and SmtpServer are required to send email."
    }

    $subjectStatus = if ($failed -eq 0) { "PASSED" } else { "FAILED" }
    $subject = "CMS/eCourt/eEDocs tests $subjectStatus - $timestamp"
    $body = Get-Content $summaryPath -Raw

    $mailParams = @{
      To = $EmailTo
      From = $EmailFrom
      Subject = $subject
      Body = $body
      SmtpServer = $SmtpServer
      Port = $SmtpPort
      Attachments = @($summaryPath, $logPath)
    }

    if ($UseSsl) {
      $mailParams.UseSsl = $true
    }

    if (-not [string]::IsNullOrWhiteSpace($SmtpUser)) {
      $securePassword = ConvertTo-SecureString $SmtpPassword -AsPlainText -Force
      $mailParams.Credential = New-Object System.Management.Automation.PSCredential($SmtpUser, $securePassword)
    }

    Send-MailMessage @mailParams
    "Email sent to: $($EmailTo -join ', ')" | Tee-Object -FilePath $logPath -Append
  }
}
finally {
  Pop-Location
}
