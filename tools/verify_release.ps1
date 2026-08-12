[CmdletBinding()]
param(
    [string]$GodotPath = "",
    [string]$OutputPath = "build/Room1604_Limbo.exe",
    [switch]$SkipExport,
    [switch]$ReproducibilityCheck
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))

if ([string]::IsNullOrWhiteSpace($GodotPath)) {
    $godotCommand = Get-Command godot_console.exe -ErrorAction SilentlyContinue
    if ($null -eq $godotCommand) {
        $godotCommand = Get-Command godot.exe -ErrorAction SilentlyContinue
    }
    if ($null -eq $godotCommand) {
        throw "Godot was not found. Pass -GodotPath with a Godot 4 console executable."
    }
    $GodotPath = $godotCommand.Source
}

$GodotPath = (Resolve-Path -LiteralPath $GodotPath).Path
if ([IO.Path]::IsPathRooted($OutputPath)) {
    $releaseExe = [IO.Path]::GetFullPath($OutputPath)
} else {
    $releaseExe = [IO.Path]::GetFullPath((Join-Path $projectRoot $OutputPath))
}

if ([IO.Path]::GetExtension($releaseExe) -ne ".exe") {
    throw "OutputPath must point to a Windows .exe file."
}

$releaseDirectory = Split-Path -Parent $releaseExe
if (-not (Test-Path -LiteralPath $releaseDirectory)) {
    New-Item -ItemType Directory -Path $releaseDirectory | Out-Null
}

function Invoke-LimboExport {
    param([Parameter(Mandatory = $true)][string]$TargetExe)

    Write-Host "Exporting release: $TargetExe"
    & $GodotPath --headless --path $projectRoot --export-release "Windows Desktop" $TargetExe
    if ($LASTEXITCODE -ne 0) {
        throw "Godot export failed with exit code $LASTEXITCODE."
    }

    $targetPck = [IO.Path]::ChangeExtension($TargetExe, ".pck")
    if (-not (Test-Path -LiteralPath $TargetExe) -or -not (Test-Path -LiteralPath $targetPck)) {
        throw "Release export did not produce both EXE and PCK files."
    }
}

function Invoke-LimboAudit {
    param(
        [Parameter(Mandatory = $true)][string]$ModeVariable,
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][string]$ExpectedMarker,
        [int]$QuitAfterFrames = 400000,
        # Дополнительные переменные прогона: второму кругу нужна ещё LIMBO_CIRCLE=2,
        # иначе соберётся первый круг и его аудит никогда не напечатает маркер.
        [hashtable]$ExtraVariables = @{}
    )

    # Прогон круга занимает десятки секунд реального времени, поэтому кадровый
    # предел здесь — только страховка от зависания: аудит завершается сам.
    # Гасим ВСЕ режимные переменные перед каждым прогоном, включая переменные
    # второго круга: иначе проходы засоряют окружение друг друга — прогон Круга I
    # унаследовал бы LIMBO_CIRCLE=2 от прогона Круга II и проверил бы не тот круг.
    $modeVariables = @(
        "LIMBO_AUDIT",
        "LIMBO_EXPORT_AUDIT",
        "LUST_AUDIT",
        "GLUT_AUDIT",
        "GREED_AUDIT",
        "WRATH_AUDIT",
        "HERESY_AUDIT",
        "VIOL_AUDIT",
        "FRAUD_AUDIT",
        "TREACH_AUDIT",
        "FLOW_AUDIT",
        "SHELL_SHOT",
        "FORCE_TOUCH",
        "LIMBO_CIRCLE"
    )
    $savedValues = @{}
    foreach ($name in $modeVariables) {
        $savedValues[$name] = [Environment]::GetEnvironmentVariable($name, "Process")
        [Environment]::SetEnvironmentVariable($name, $null, "Process")
    }

    $logPath = Join-Path $releaseDirectory ("verify_{0}.log" -f $Label)
    if (Test-Path -LiteralPath $logPath) {
        Remove-Item -LiteralPath $logPath
    }

    try {
        [Environment]::SetEnvironmentVariable($ModeVariable, "1", "Process")
        foreach ($extra in $ExtraVariables.GetEnumerator()) {
            [Environment]::SetEnvironmentVariable($extra.Key, $extra.Value, "Process")
        }
        $arguments = @(
            "--headless",
            "--log-file",
            ('"{0}"' -f $logPath),
            "--quit-after",
            [string]$QuitAfterFrames
        )
        $process = Start-Process `
            -FilePath $releaseExe `
            -ArgumentList $arguments `
            -WorkingDirectory $releaseDirectory `
            -WindowStyle Hidden `
            -Wait `
            -PassThru
    } finally {
        foreach ($name in $modeVariables) {
            [Environment]::SetEnvironmentVariable($name, $savedValues[$name], "Process")
        }
    }

    if ($process.ExitCode -ne 0) {
        throw "$Label audit failed with exit code $($process.ExitCode). See $logPath"
    }
    if (-not (Test-Path -LiteralPath $logPath)) {
        throw "$Label audit did not create its log: $logPath"
    }

    $logText = Get-Content -LiteralPath $logPath -Raw -Encoding UTF8
    if (-not $logText.Contains($ExpectedMarker)) {
        throw "$Label audit ended without marker '$ExpectedMarker'. See $logPath"
    }
    # В изолированном Windows-сеансе Godot не видит системное хранилище корневых
    # сертификатов и пишет engine ERROR даже офлайн-игре, которая сеть не
    # использует. Не прячем остальные ошибки: удаляется только эта известная
    # двухстрочная диагностика платформы, после чего действует прежний строгий
    # фильтр SCRIPT ERROR / ERROR.
    $checkedLog = [regex]::Replace(
        $logText,
        "(?m)^ERROR: Failed to read the root certificate store\.\r?\n\s+at: get_system_ca_certificates \(platform/windows/os_windows\.cpp:\d+\)\r?\n?",
        ""
    )
    if ($checkedLog -match "(?m)^(SCRIPT ERROR|ERROR:)") {
        throw "$Label audit logged an engine or script error. See $logPath"
    }

    Write-Host ("Audit {0}: OK" -f $Label)
}

if ($SkipExport) {
    $releasePck = [IO.Path]::ChangeExtension($releaseExe, ".pck")
    if (-not (Test-Path -LiteralPath $releaseExe) -or -not (Test-Path -LiteralPath $releasePck)) {
        throw "SkipExport requires an existing EXE and PCK at '$releaseExe'."
    }
    Write-Host "Using existing release: $releaseExe"
} else {
    Invoke-LimboExport -TargetExe $releaseExe
}

if ($ReproducibilityCheck) {
    if ($SkipExport) {
        throw "ReproducibilityCheck cannot be combined with SkipExport."
    }
    $firstExeHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $releaseExe).Hash
    $releasePck = [IO.Path]::ChangeExtension($releaseExe, ".pck")
    $firstPckHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $releasePck).Hash
    $systemTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    $reproDirectory = Join-Path $systemTemp ("room1604_repro_{0}" -f [Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $reproDirectory | Out-Null

    try {
        $reproExe = Join-Path $reproDirectory "Room1604_Limbo.exe"
        Invoke-LimboExport -TargetExe $reproExe
        $reproPck = [IO.Path]::ChangeExtension($reproExe, ".pck")
        $secondExeHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $reproExe).Hash
        $secondPckHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $reproPck).Hash
        if ($firstExeHash -ne $secondExeHash -or $firstPckHash -ne $secondPckHash) {
            throw "Reproducibility check failed: consecutive release hashes differ."
        }
        Write-Host "Reproducibility: OK (EXE and PCK hashes match)"
    } finally {
        $fullReproDirectory = [IO.Path]::GetFullPath($reproDirectory)
        $isSafeTemp = $fullReproDirectory.StartsWith(
            $systemTemp,
            [StringComparison]::OrdinalIgnoreCase
        ) -and (Split-Path -Leaf $fullReproDirectory).StartsWith("room1604_repro_")
        if ($isSafeTemp -and (Test-Path -LiteralPath $fullReproDirectory)) {
            Remove-Item -LiteralPath $fullReproDirectory -Recurse -Force
        }
    }
}

Invoke-LimboAudit `
    -ModeVariable "LIMBO_EXPORT_AUDIT" `
    -Label "export" `
    -ExpectedMarker "LIMBO_EXPORT_AUDIT_OK"
Invoke-LimboAudit `
    -ModeVariable "LIMBO_AUDIT" `
    -Label "full" `
    -ExpectedMarker "LIMBO_AUDIT_OK"
# Круг II. Собирается только при LIMBO_CIRCLE=2, поэтому проход первого круга
# выше остаётся ровно тем же, каким был до появления второго.
Invoke-LimboAudit `
    -ModeVariable "LUST_AUDIT" `
    -Label "circle2" `
    -ExpectedMarker "LUST_AUDIT_OK" `
    -ExtraVariables @{ "LIMBO_CIRCLE" = "2" }
Invoke-LimboAudit `
    -ModeVariable "GLUT_AUDIT" `
    -Label "circle3" `
    -ExpectedMarker "GLUT_AUDIT_OK" `
    -ExtraVariables @{ "LIMBO_CIRCLE" = "3" }
Invoke-LimboAudit `
    -ModeVariable "GREED_AUDIT" `
    -Label "circle4" `
    -ExpectedMarker "GREED_AUDIT_OK" `
    -ExtraVariables @{ "LIMBO_CIRCLE" = "4" }
Invoke-LimboAudit `
    -ModeVariable "WRATH_AUDIT" `
    -Label "circle5" `
    -ExpectedMarker "WRATH_AUDIT_OK" `
    -ExtraVariables @{ "LIMBO_CIRCLE" = "5" }
Invoke-LimboAudit `
    -ModeVariable "HERESY_AUDIT" `
    -Label "circle6" `
    -ExpectedMarker "HERESY_AUDIT_OK" `
    -ExtraVariables @{ "LIMBO_CIRCLE" = "6" }
Invoke-LimboAudit `
    -ModeVariable "VIOL_AUDIT" `
    -Label "circle7" `
    -ExpectedMarker "VIOL_AUDIT_OK" `
    -ExtraVariables @{ "LIMBO_CIRCLE" = "7" }
Invoke-LimboAudit `
    -ModeVariable "FRAUD_AUDIT" `
    -Label "circle8" `
    -ExpectedMarker "FRAUD_AUDIT_OK" `
    -ExtraVariables @{ "LIMBO_CIRCLE" = "8" }
Invoke-LimboAudit `
    -ModeVariable "TREACH_AUDIT" `
    -Label "circle9" `
    -ExpectedMarker "TREACH_AUDIT_OK" `
    -ExtraVariables @{ "LIMBO_CIRCLE" = "9" }
# Прогресс: сохранение, разблокировка кругов, порченые данные, слияние с
# облаком. Комната для этого не нужна, поэтому прогон быстрый.
Invoke-LimboAudit `
    -ModeVariable "FLOW_AUDIT" `
    -Label "progress" `
    -ExpectedMarker "FLOW_AUDIT_OK"

$releaseFiles = @(
    $releaseExe,
    [IO.Path]::ChangeExtension($releaseExe, ".pck")
)
Write-Host "Release verification: OK"
Get-FileHash -Algorithm SHA256 -LiteralPath $releaseFiles |
    Select-Object Path, Hash |
    Format-Table -AutoSize
