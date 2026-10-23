<#
.SYNOPSIS
    Full RTLLM run for GPT-6 Astra through the ChatGPT layer (ChatMock): generation,
    pass@1..5 evaluation on Vivado XSim, Vivado synthesis PPA, an Excel workbook per
    language, and finally the cross-model comparison workbook.

.NOTES
    ChatMock is started through chatmock_serve.py, which advertises a Codex client
    version new enough for the ChatGPT catalog to expose the GPT-6 family.

    Every stage resumes: generation skips candidates that already exist, evaluation
    reuses completed trial outcomes from the previous JSON report, and synthesis can be
    re-run for the designs that failed without redoing the rest.
#>
param(
    [ValidateSet("verilog", "vhdl", "both")]
    [string]$Language = "both",

    [ValidateRange(1, 5)]
    [int]$Trials = 5,

    [ValidateRange(1, 8)]
    [int]$Workers = 4,

    [ValidateRange(1, 8)]
    [int]$SynthWorkers = 3,

    [ValidateRange(1024, 65535)]
    [int]$Port = 8000,

    [string]$Model = "gpt-6-astra",
    [string]$Part = "xc7s100fgga676-2",
    [double]$ClockPeriod = 10.0,
    [double]$ToggleRate = 25.0,

    [switch]$SkipGenerate,
    [switch]$SkipEval,
    [switch]$SkipPPA
)

# Windows PowerShell 5.1 wraps native stderr (tqdm progress) in NativeCommandError,
# so stage failures are detected from $LASTEXITCODE and thrown explicitly.
$ErrorActionPreference = "Continue"
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$python = Join-Path $repoRoot "venv\Scripts\python.exe"
$runtimeDir = Join-Path $repoRoot ".runtime"
$reportDir = Join-Path $repoRoot "outputs\gpt6_astra_high"
$baseUrl = "http://127.0.0.1:$Port/v1"
# Golden PPA is model-independent; reuse the baseline from the GLM run when present.
$sharedGoldenPpa = Join-Path $repoRoot "outputs\glm53_flash\golden_ppa.json"
$goldenPpaPath = if (Test-Path -LiteralPath $sharedGoldenPpa) { $sharedGoldenPpa } else { Join-Path $reportDir "golden_ppa.json" }

if (-not (Test-Path -LiteralPath $python)) { throw "Missing virtual environment Python: $python" }
New-Item -ItemType Directory -Force -Path $runtimeDir, $reportDir | Out-Null
Start-Transcript -Path (Join-Path $reportDir "full_run.log") -Append | Out-Null

$languages = if ($Language -eq "both") { @("verilog", "vhdl") } else { @($Language) }
$serverProcess = $null

function Test-ChatMock {
    try { return Invoke-RestMethod -Uri "$baseUrl/models" -TimeoutSec 5 } catch { return $null }
}

try {
    if (-not $SkipGenerate) {
        $models = Test-ChatMock
        if ($null -eq $models) {
            $serverProcess = Start-Process -FilePath $python -ArgumentList @(
                (Join-Path $repoRoot "chatmock_serve.py"),
                "serve",
                "--host", "127.0.0.1",
                "--port", $Port,
                "--reasoning-summary", "none",
                "--no-fast-mode",
                "--no-enable-web-search"
            ) -WorkingDirectory $repoRoot -WindowStyle Hidden -PassThru `
              -RedirectStandardOutput (Join-Path $runtimeDir "chatmock.stdout.log") `
              -RedirectStandardError (Join-Path $runtimeDir "chatmock.stderr.log")
            for ($attempt = 0; $attempt -lt 45 -and $null -eq $models; $attempt++) {
                Start-Sleep -Seconds 1
                if ($serverProcess.HasExited) { throw "ChatMock exited during startup. See $runtimeDir\chatmock.stderr.log" }
                $models = Test-ChatMock
            }
            if ($null -eq $models) { throw "ChatMock did not become ready at $baseUrl within 45 seconds." }
        }
        if (-not ($models.data.id -contains $Model)) {
            throw "ChatMock at $baseUrl does not list $Model. If an older ChatMock is already running on port $Port, stop it so chatmock_serve.py can start."
        }
    }

    foreach ($lang in $languages) {
        $suffix = if ($lang -eq "vhdl") { "_vhdl" } else { "" }
        $generationDir = Join-Path $repoRoot "chatmock_gpt_6_astra_high$suffix"
        $csvPath = Join-Path $reportDir "gpt6_astra_high_${lang}_all72_design_results.csv"
        $jsonPath = Join-Path $reportDir "gpt6_astra_high_${lang}_all72_benchmark_results.json"
        $ppaPath = Join-Path $reportDir "gpt6_astra_high_${lang}_ppa.json"
        $xlsxPath = Join-Path $reportDir "RTLLM_GPT-6_Astra_high_${lang}_all72_results.xlsx"

        Write-Host ""
        Write-Host "=== $lang : generation ===================================================="
        if (-not $SkipGenerate) {
            & $python (Join-Path $repoRoot "generate_rtl.py") `
                --backend chatmock `
                --base-url $baseUrl `
                --model $Model `
                --reasoning-effort high `
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
} finally {
    if ($null -ne $serverProcess -and -not $serverProcess.HasExited) {
        Stop-Process -Id $serverProcess.Id
    }
}

Write-Host ""
Write-Host "=== cross-model comparison ==============================================="
& $python (Join-Path $repoRoot "compare_models.py")
if ($LASTEXITCODE -ne 0) { throw "Comparison workbook failed (exit $LASTEXITCODE)." }

Write-Host ""
Write-Host "Benchmark complete. Reports in $reportDir"
Stop-Transcript | Out-Null
