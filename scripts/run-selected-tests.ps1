param(
  [string]$Root = "C:\Users\vidhuad\CMS-Automation\CMS-env-tests",
  [switch]$Headed,
  [string[]]$Specs = @(),
  [string[]]$EmailTo = @(),
  [string]$EmailFrom = "",
  [string]$SmtpServer = "",
  [int]$SmtpPort = 25,
  [switch]$UseSsl,
  [string]$SmtpUser = "",
  [string]$SmtpPassword = ""
)

# Load .env
$envFilePath = Join-Path $Root '.env'
if (Test-Path $envFilePath) {
  Get-Content $envFilePath | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith('#')) {
      $parts = $line -split '=',2
      if ($parts.Count -eq 2) {
        $k = $parts[0].Trim()
        $v = $parts[1]
        if (-not ${env:$k}) {
          ${env:$k} = $v
        }
      }
    }
  }
}

$ErrorActionPreference = "Stop"

# Logging setup
$logDir = Join-Path $Root "scheduled-test-logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logPath = Join-Path $logDir "cms-tests-$timestamp.log"
$jsonPath = Join-Path $logDir "cms-tests-$timestamp.json"
$summaryPath = Join-Path $logDir "cms-tests-$timestamp.md"

Push-Location $Root
try {

  "Started: $(Get-Date -Format o)" | Tee-Object -FilePath $logPath

  # Default specs
  $selectedSpecs = @(
    "tests/cms/cmsstg_login.spec.js",
    "tests/ecourt/ecourt_login.spec.js",
    "tests/edocs/edocs_dev_direct_login.spec.js",
    "tests/edocs/edocs_portal_login.spec.js",
    "tests/edocs/edocs_prod_direct_login.spec.js"
  )

  # Build Playwright path (reliable execution)
  $playwright = Join-Path $Root "node_modules\.bin\playwright.cmd"

  if (-not (Test-Path $playwright)) {
    throw "Playwright not found. Run: npm install && npx playwright install"
  }

  "`n> Running Playwright..." | Tee-Object -FilePath $logPath -Append

  # ✅ Run Playwright
  $specsToRun = if ($Specs.Count -gt 0) { $Specs } else { $selectedSpecs }
  $playwrightArgs = @("test")
  $playwrightArgs += $specsToRun
  $playwrightArgs += "--project=chrome"
  $playwrightArgs += "--project=edge"
  $playwrightArgs += "--reporter=list,json" # Use list for better log output, json for data
  
  if ($Headed) {
    $playwrightArgs += "--headed"
  }

  "`n> Executing: & `"$playwright`" $($playwrightArgs -join ' ')" | Tee-Object -FilePath $logPath -Append

  # Direct JSON output to our specific path
  $env:PLAYWRIGHT_JSON_OUTPUT_NAME = $jsonPath
  
  # Execute and capture stdout/stderr for the log
  $output = & $playwright $playwrightArgs 2>&1 | Out-String
  $output | Tee-Object -FilePath $logPath -Append

  # ✅ Handle failure without stopping script
  $testFailed = $false
  if ($LASTEXITCODE -ne 0) {
    $testFailed = $true
    Write-Warning "Some tests failed, continuing..."
  }

  # ✅ Parse JSON from the file Playwright generated
  if (-not (Test-Path $jsonPath)) {
    Write-Error "Playwright output:`n$output"
    throw "JSON report was not generated at $jsonPath. Check the log for details."
  }

  $jsonClean = Get-Content -Path $jsonPath -Raw
  if (-not $jsonClean) {
    throw "JSON report at $jsonPath is empty."
  }

  # ✅ Parse JSON
  $result = $jsonClean | ConvertFrom-Json

  # ✅ Summary stats
  $passed = $result.stats.expected
  $failed = $result.stats.unexpected
  $skipped = $result.stats.skipped
  $total = $passed + $failed + $skipped
  $mode = if ($Headed) { "headed" } else { "headless" }
  $duration = [math]::Round($result.stats.duration / 1000, 1)

  # ✅ Extract table rows from JSON
  $tableRows = @()
  foreach ($suite in $result.suites) {
    $specFile = $suite.file
    foreach ($innerSuite in $suite.suites) {
      $suiteTitle = $innerSuite.title
      foreach ($spec in $innerSuite.specs) {
        $testTitle = $spec.title
        foreach ($test in $spec.tests) {
          $browser = $test.projectName
          $status = $test.results[0].status
          $durationMs = $test.results[0].duration
          $durationS = [math]::Round($durationMs / 1000, 1)
          
          $tableRows += "| $browser | ``$specFile`` | $suiteTitle > $testTitle | $status | ${durationS}s |"
        }
      }
    }
  }

  # ✅ Markdown summary (for workflow and logs)
  $summary = @"
# CMS, eCourt, and eEDocs Test Summary

## Latest Run

- Started: $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")
- Machine path: ``$Root``
- Browser projects: ``chrome``, ``edge``
- Mode: $mode
- Command:
``````powershell
& "$playwright" $($playwrightArgs -join ' ')
``````

## Overall Result

- Total test runs: $total
- Passed: $passed
- Failed: $failed
- Skipped: $skipped
- Duration: ${duration}s
- JSON result: ``$jsonPath``
- Console log: ``$logPath``

## Test Results

| Browser | Spec | Test | Result | Duration |
| --- | --- | --- | --- | --- |
$( $tableRows -join "`n" )
"@

  # Save to both timestamped file and root test_summary.md
  $summary | Set-Content $summaryPath
  $summary | Set-Content (Join-Path $Root "test_summary.md")

  "Summary written: $summaryPath and test_summary.md" | Tee-Object -FilePath $logPath -Append

  # ✅ Email (optional)
  if ($EmailTo.Count -gt 0) {

    if (-not $EmailFrom -or -not $SmtpServer) {
      throw "EmailFrom and SmtpServer are required for email."
    }

    $subject = if ($testFailed) { "❌ Tests FAILED" } else { "✅ Tests PASSED" }

    Send-MailMessage `
      -To $EmailTo `
      -From $EmailFrom `
      -Subject $subject `
      -Body (Get-Content $summaryPath -Raw) `
      -SmtpServer $SmtpServer `
      -Port $SmtpPort `
      -UseSsl:$UseSsl

    "Email sent to: $($EmailTo -join ', ')" | Tee-Object -FilePath $logPath -Append
  }

}
finally {
  $env:PLAYWRIGHT_JSON_OUTPUT_NAME = $null
  Pop-Location
}