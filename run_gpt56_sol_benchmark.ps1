param(
    [ValidateSet("verilog", "vhdl")]
    [string]$Language = "verilog",
    [ValidateRange(1, 5)]
    [int]$Trials = 5,
    [ValidateRange(1, 8)]
    [int]$Workers = 2,
    [ValidateRange(1024, 65535)]
    [int]$Port = 8000
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$python = Join-Path $repoRoot "venv\Scripts\python.exe"
$chatmock = Join-Path $repoRoot "venv\Scripts\chatmock.exe"
$runtimeDir = Join-Path $repoRoot ".runtime"
$reportDir = Join-Path $repoRoot "outputs\gpt56_sol_high"
$suffix = if ($Language -eq "vhdl") { "_vhdl" } else { "" }
$generationDir = Join-Path $repoRoot "chatmock_gpt_5_6_sol_high$suffix"
$legacyJsonPath = Join-Path $reportDir "gpt56_sol_high_${Language}_benchmark_results.json"
$csvPath = Join-Path $reportDir "gpt56_sol_high_${Language}_all72_design_results.csv"
$jsonPath = Join-Path $reportDir "gpt56_sol_high_${Language}_all72_benchmark_results.json"
$xlsxPath = Join-Path $reportDir "RTLLM_GPT-5.6_Sol_high_${Language}_all72_results.xlsx"
$baseUrl = "http://127.0.0.1:$Port/v1"
$serverStartedHere = $false
$serverProcess = $null

if (-not (Test-Path -LiteralPath $python)) {
    throw "Missing virtual environment Python: $python"
}
if (-not (Test-Path -LiteralPath $chatmock)) {
    throw "ChatMock is not installed. Run: $python -m pip install -r requirements-chatmock.txt"
}

New-Item -ItemType Directory -Force -Path $runtimeDir, $reportDir | Out-Null

try {
    try {
        Invoke-RestMethod -Uri "$baseUrl/models" -TimeoutSec 3 | Out-Null
    } catch {
        $stdoutLog = Join-Path $runtimeDir "chatmock.stdout.log"
        $stderrLog = Join-Path $runtimeDir "chatmock.stderr.log"
        $serverProcess = Start-Process -FilePath $chatmock -ArgumentList @(
            "serve",
            "--host", "127.0.0.1",
            "--port", $Port,
            "--debug-model", "gpt-5.6-sol",
            "--reasoning-effort", "high",
            "--reasoning-summary", "none",
            "--no-fast-mode",
            "--no-enable-web-search"
        ) -WorkingDirectory $repoRoot -WindowStyle Hidden -PassThru `
          -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog
        $serverStartedHere = $true

        $ready = $false
        for ($attempt = 0; $attempt -lt 45; $attempt++) {
            Start-Sleep -Seconds 1
            if ($serverProcess.HasExited) {
                throw "ChatMock exited during startup. See $stderrLog"
            }
            try {
                Invoke-RestMethod -Uri "$baseUrl/models" -TimeoutSec 3 | Out-Null
                $ready = $true
                break
            } catch {
            }
        }
        if (-not $ready) {
            throw "ChatMock did not become ready at $baseUrl within 45 seconds."
        }
    }

    $models = Invoke-RestMethod -Uri "$baseUrl/models" -TimeoutSec 30
    if (-not ($models.data.id -contains "gpt-5.6-sol")) {
        throw "The signed-in ChatGPT account does not expose gpt-5.6-sol through ChatMock."
    }

    & $python (Join-Path $repoRoot "generate_rtl.py") `
        --backend chatmock `
        --base-url $baseUrl `
        --model gpt-5.6-sol `
        --reasoning-effort high `
        --lang $Language `
        --trials $Trials `
        --workers $Workers `
        --output-dir $generationDir
    if ($LASTEXITCODE -ne 0) { throw "RTL generation failed with exit code $LASTEXITCODE." }

    $resumePath = if (Test-Path -LiteralPath $jsonPath) { $jsonPath } else { $legacyJsonPath }
    $evaluationArgs = @(
        (Join-Path $repoRoot "auto_run.py"),
        "--lang", $Language,
        "--gen-dir", $generationDir,
        "--trials", $Trials,
        "--pass-k", 1, 2, 3, 4, 5,
        "--csv", $csvPath,
        "--json", $jsonPath
    )
    if (Test-Path -LiteralPath $resumePath) {
        $evaluationArgs += @("--resume-from", $resumePath)
    }
    & $python @evaluationArgs
    if ($LASTEXITCODE -ne 0) { throw "Vivado evaluation failed with exit code $LASTEXITCODE." }

    & $python (Join-Path $repoRoot "create_excel_report.py") $jsonPath $xlsxPath
    if ($LASTEXITCODE -ne 0) { throw "Excel report creation failed with exit code $LASTEXITCODE." }

    Write-Host "Benchmark complete: $xlsxPath"
} finally {
    if ($serverStartedHere -and $null -ne $serverProcess -and -not $serverProcess.HasExited) {
        Stop-Process -Id $serverProcess.Id
    }
}
