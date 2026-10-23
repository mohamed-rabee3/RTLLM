<#
.SYNOPSIS
    Full RTLLM run for DeepSeek-V4.1-Flash via the opencode zen API: generation, pass@1..5
    evaluation on Vivado XSim, Vivado synthesis PPA, and an Excel workbook per language.

.NOTES
    Every stage resumes: generation skips candidates that already exist, evaluation
    reuses completed trial outcomes from the previous JSON report, and synthesis can be
    re-run for the designs that failed without redoing the rest.
#>
param(
    [ValidateSet("verilog", "vhdl", "both")]
    [string]$Language = "both",

    [ValidateRange(1, 5)]
    [int]$Trials = 5,

    [ValidateRange(1, 16)]
    [int]$Workers = 4,

    [ValidateRange(1, 8)]
    [int]$SynthWorkers = 3,

    [string]$Model = "deepseek-v4.1-flash",
    [string]$Part = "xc7s100fgga676-2",
    [double]$ClockPeriod = 10.0,
    [double]$ToggleRate = 25.0,

    [switch]$SkipGenerate,
    [switch]$SkipEval,
    [switch]$SkipPPA
)

# Windows PowerShell 5.1 wraps every stderr line from a native executable in a
# NativeCommandError, and tqdm draws its progress bar on stderr. Under
# $ErrorActionPreference = "Stop" that turns a healthy generation run into a
# terminating error, so stage failures are detected from $LASTEXITCODE instead and
# each one throws explicitly.
$ErrorActionPreference = "Continue"
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$python = Join-Path $repoRoot "venv\Scripts\python.exe"
$reportDir = Join-Path $repoRoot "outputs\deepseek41_flash"
# Golden PPA is model-independent; reuse the baseline from the GLM run when present.
$sharedGoldenPpa = Join-Path $repoRoot "outputs\glm53_flash\golden_ppa.json"
$goldenPpaPath = if (Test-Path -LiteralPath $sharedGoldenPpa) { $sharedGoldenPpa } else { Join-Path $reportDir "golden_ppa.json" }

if (-not (Test-Path -LiteralPath $python)) { throw "Missing virtual environment Python: $python" }
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
Start-Transcript -Path (Join-Path $reportDir "full_run.log") -Append | Out-Null

$languages = if ($Language -eq "both") { @("verilog", "vhdl") } else { @($Language) }

function Get-EnvValue([string]$name) {
    $envFile = Join-Path $repoRoot ".env"
    if (-not (Test-Path -LiteralPath $envFile)) { return $null }
    foreach ($line in Get-Content -LiteralPath $envFile) {
        $trimmed = $line.Trim()
        if ($trimmed -eq "" -or $trimmed.StartsWith("#")) { continue }
        $split = $trimmed.IndexOf("=")
        if ($split -lt 1) { continue }
        if ($trimmed.Substring(0, $split).Trim() -eq $name) {
            return $trimmed.Substring($split + 1).Trim().Trim('"').Trim("'")
        }
    }
    return $null
}

# Preflight: a zero-balance or rejected key should fail here, not 300 requests in.
if (-not $SkipGenerate) {
    # A key in the process environment wins over .env, matching generate_rtl.py.
    $apiKey = if ($env:OPENCODE_API_KEY) { $env:OPENCODE_API_KEY } else { Get-EnvValue "OPENCODE_API_KEY" }
    if (-not $apiKey) { throw "OPENCODE_API_KEY is not set in the environment or .env" }
    $baseUrl = Get-EnvValue "OPENCODE_BASE_URL"
    if (-not $baseUrl) { $baseUrl = "https://opencode.ai/zen/go/v1" }

    $probeBody = @{
        model      = $Model
        messages   = @(@{ role = "user"; content = "ping" })
        max_tokens = 64
    } | ConvertTo-Json -Depth 5

    Write-Host "Preflight: checking $Model on $baseUrl ..."
    try {
        $ErrorActionPreference = "Stop"
        # The Go route refuses any request without a session id.
        Invoke-RestMethod -Method Post -Uri "$baseUrl/chat/completions" `
            -Headers @{
                Authorization         = "Bearer $apiKey"
                "x-opencode-session"  = [guid]::NewGuid().ToString()
            } `
            -ContentType "application/json" -Body $probeBody -TimeoutSec 120 | Out-Null
    } catch {
        $detail = $_.ErrorDetails.Message
        if (-not $detail) { $detail = $_.Exception.Message }
        throw "opencode preflight failed: $detail"
    } finally {
        $ErrorActionPreference = "Continue"
    }
    Write-Host "Preflight OK."
}

foreach ($lang in $languages) {
    $suffix = if ($lang -eq "vhdl") { "_vhdl" } else { "" }
    $generationDir = Join-Path $repoRoot "opencode_deepseek_v4_1_flash$suffix"
    $csvPath = Join-Path $reportDir "deepseek41_flash_${lang}_all72_design_results.csv"
    $jsonPath = Join-Path $reportDir "deepseek41_flash_${lang}_all72_benchmark_results.json"
    $ppaPath = Join-Path $reportDir "deepseek41_flash_${lang}_ppa.json"
    $xlsxPath = Join-Path $reportDir "RTLLM_DeepSeek-V4.1-Flash_${lang}_all72_results.xlsx"

    Write-Host ""
    Write-Host "=== $lang : generation ===================================================="
    if (-not $SkipGenerate) {
        & $python (Join-Path $repoRoot "generate_rtl.py") `
            --backend opencode `
            --model $Model `
            --lang $lang `
            --trials $Trials `
            --workers $Workers `
            --output-dir $generationDir
        if ($LASTEXITCODE -ne 0) { throw "RTL generation failed for $lang (exit $LASTEXITCODE)." }
    } else {
        Write-Host "skipped (-SkipGenerate)"
    }

    Write-Host ""
    Write-Host "=== $lang : Vivado XSim evaluation (pass@1..$Trials) ====================="
    if (-not $SkipEval) {
        $evalArgs = @(
            (Join-Path $repoRoot "auto_run.py"),
            "--lang", $lang,
            "--gen-dir", $generationDir,
            "--trials", $Trials,
            "--pass-k", 1, 2, 3, 4, 5,
            "--csv", $csvPath,
            "--json", $jsonPath
        )
        if (Test-Path -LiteralPath $jsonPath) { $evalArgs += @("--resume-from", $jsonPath) }
        & $python @evalArgs
        if ($LASTEXITCODE -ne 0) { throw "Vivado evaluation failed for $lang (exit $LASTEXITCODE)." }
    } else {
        Write-Host "skipped (-SkipEval)"
    }

    Write-Host ""
    Write-Host "=== $lang : synthesis PPA ==============================================="
    if (-not $SkipPPA) {
        if (-not (Test-Path -LiteralPath $goldenPpaPath)) {
            Write-Host "--- golden RTL baseline (once for all languages) ---"
            & $python (Join-Path $repoRoot "synth_metrics.py") `
                --mode golden `
                --part $Part --clock-period $ClockPeriod --toggle-rate $ToggleRate `
                --workers $SynthWorkers `
                --out-json $goldenPpaPath
            if ($LASTEXITCODE -ne 0) { throw "Golden PPA sweep failed (exit $LASTEXITCODE)." }
        }

        & $python (Join-Path $repoRoot "synth_metrics.py") `
            --mode model `
            --lang $lang `
            --gen-dir $generationDir `
            --report $jsonPath `
            --scope best-pass `
            --part $Part --clock-period $ClockPeriod --toggle-rate $ToggleRate `
            --workers $SynthWorkers `
            --out-json $ppaPath
        if ($LASTEXITCODE -ne 0) { throw "Model PPA sweep failed for $lang (exit $LASTEXITCODE)." }
    } else {
        Write-Host "skipped (-SkipPPA)"
    }

    Write-Host ""
    Write-Host "=== $lang : Excel workbook =============================================="
    $excelArgs = @((Join-Path $repoRoot "create_excel_report.py"), $jsonPath, $xlsxPath)
    if (Test-Path -LiteralPath $ppaPath) { $excelArgs += @("--ppa", $ppaPath) }
    if (Test-Path -LiteralPath $goldenPpaPath) { $excelArgs += @("--ppa-golden", $goldenPpaPath) }
    & $python @excelArgs
    if ($LASTEXITCODE -ne 0) { throw "Excel report creation failed for $lang (exit $LASTEXITCODE)." }

    Write-Host "Done: $xlsxPath"
}

Write-Host ""
Write-Host "=== cross-model comparison ==============================================="
& $python (Join-Path $repoRoot "compare_models.py")
if ($LASTEXITCODE -ne 0) { throw "Comparison workbook failed (exit $LASTEXITCODE)." }

Write-Host ""
Write-Host "Benchmark complete. Reports in $reportDir"
Stop-Transcript | Out-Null
