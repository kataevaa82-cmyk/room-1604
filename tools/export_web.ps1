# Сборка веб-версии для Яндекс Игр.
#
# Зачем отдельный шаг вместо html/head_include в export_presets.cfg: в Godot
# этот параметр НЕ применяется при экспорте из командной строки — плейсхолдер
# $GODOT_HEAD_INCLUDE остаётся в шаблоне необработанным, и работает опция
# только при экспорте из редактора. Вся наша сборка идёт через CLI, поэтому
# содержимое <head> вставляется здесь, после экспорта.
#
# Так даже лучше проверяемо: тег SDK остаётся статическим в самом index.html,
# и его наличие подтверждается поиском по файлу, а не «должно сработать».

[CmdletBinding()]
param(
    [string]$GodotPath = "",
    [string]$OutputDir = "build/web"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))

if ([string]::IsNullOrWhiteSpace($GodotPath)) {
    $command = Get-Command godot_console.exe -ErrorAction SilentlyContinue
    if ($null -eq $command) { $command = Get-Command godot.exe -ErrorAction SilentlyContinue }
    if ($null -eq $command) { throw "Godot was not found. Pass -GodotPath." }
    $GodotPath = $command.Source
}

$outDir = [IO.Path]::GetFullPath((Join-Path $projectRoot $OutputDir))
if (-not (Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
$indexPath = Join-Path $outDir "index.html"

Write-Host "Exporting web build: $indexPath"
& $GodotPath --headless --path $projectRoot --export-release "Web" $indexPath
if ($LASTEXITCODE -ne 0) { throw "Godot web export failed with exit code $LASTEXITCODE." }
if (-not (Test-Path -LiteralPath $indexPath)) { throw "Web export produced no index.html." }

# Содержимое <head>.
#
#  * Тег SDK Яндекса по относительному пути /sdk.js — рекомендованный вариант
#    для игр, залитых на хостинг площадки (а не через свой домен).
#  * initSDK объявлен ДО тега: скрипт грузится async и зовёт функцию по onload,
#    поэтому она обязана уже существовать.
#  * __ysdkReady взводится в ОБОИХ исходах, и при успехе и при ошибке: игра
#    ждёт любого ответа, а не только удачного, и не висит, если SDK не отдался
#    (например, когда игру открыли не на Яндексе).
#  * Правила страницы под требования площадки к мобильным: нет прокрутки, нет
#    подтягивания для обновления, нет выделения текста и контекстного меню по
#    долгому нажатию.
#
# Остальная логика моста живёт в scripts/systems/Platform.gd.
$marker = "<!-- room1604:head -->"
$headInclude = @"
$marker
<script>window.__ysdk=null;window.__ysdkReady=false;function initSDK(){try{YaGames.init().then(function(s){window.__ysdk=s;window.__ysdkReady=true;}).catch(function(){window.__ysdkReady=true;});}catch(e){window.__ysdkReady=true;}}</script>
<script src="/sdk.js" async onload="initSDK()"></script>
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover">
<style>
html,body{margin:0;padding:0;width:100%;height:100%;overflow:hidden;overscroll-behavior:none;background:#000;
-webkit-user-select:none;-moz-user-select:none;user-select:none;
-webkit-touch-callout:none;-webkit-tap-highlight-color:transparent}
canvas{display:block;touch-action:none;outline:none;-webkit-touch-callout:none}
/* room1604:loader — экран ожидания.
   Первая загрузка тянет около четырнадцати мегабайт (шаблон Godot плюс
   ресурсы), и на медленном канале это минуты. Серый прямоугольник Godot с
   системным индикатором всё это время выглядит как зависшая страница, поэтому
   он перекрашен под меню игры: те же цвета, та же надпись сверху. Правится
   только внешний вид, сам индикатор остаётся штатным. */
#status{background-color:#0b0a09!important}
#status-progress{bottom:13%;width:38%;height:6px;border:0;-webkit-appearance:none;appearance:none;
background:#241f18;border-radius:3px;overflow:hidden}
#status-progress::-webkit-progress-bar{background:#241f18}
#status-progress::-webkit-progress-value{background:#e8c07d}
#status-progress::-moz-progress-bar{background:#e8c07d}
#status::after{content:"КОМНАТА 1604  ·  ШЕСТНАДЦАТЫЙ ЭТАЖ";position:absolute;bottom:8%;left:0;right:0;
text-align:center;font:13px/1.4 'Noto Sans','Segoe UI',Arial,sans-serif;letter-spacing:.18em;color:#9f8e73}
</style>
"@

$html = [IO.File]::ReadAllText($indexPath)
if ($html.Contains($marker)) {
    Write-Host "Head include already present, skipping."
} else {
    if (-not $html.Contains("</head>")) { throw "index.html has no </head> to inject into." }
    $html = $html.Replace("</head>", $headInclude + "`n</head>")
    # Без BOM: Godot и браузеры читают его как мусорные символы в начале файла,
    # а Set-Content в PowerShell 5.1 добавляет BOM по умолчанию.
    [IO.File]::WriteAllText($indexPath, $html, (New-Object Text.UTF8Encoding($false)))
    Write-Host "Head include injected."
}

# Проверяем результат, а не надеемся на него.
$check = [IO.File]::ReadAllText($indexPath)
$required = @(
    '<script src="/sdk.js" async onload="initSDK()"></script>',
    'function initSDK',
    'overscroll-behavior:none',
    'viewport-fit=cover',
    'room1604:loader'
)
foreach ($needle in $required) {
    if (-not $check.Contains($needle)) { throw "index.html is missing required head content: $needle" }
}
# initSDK обязан быть объявлен раньше тега, который его зовёт по onload.
if ($check.IndexOf('function initSDK') -gt $check.IndexOf('src="/sdk.js"')) {
    throw "initSDK is declared after the SDK script tag; onload would fire before it exists."
}
Write-Host "Head content: OK"

# Требования площадки к архиву: не больше 100 МБ в разархивированном виде,
# index.html в корне, без пробелов и кириллицы в именах файлов.
$files = Get-ChildItem -LiteralPath $outDir -File
$totalMb = [math]::Round((($files | Measure-Object -Property Length -Sum).Sum / 1MB), 2)
Write-Host ("Unzipped size: {0} MB (Yandex limit: 100 MB)" -f $totalMb)
if ($totalMb -gt 100) { throw "Build exceeds the 100 MB Yandex limit: $totalMb MB" }

foreach ($file in $files) {
    if ($file.Name -match '[^\x20-\x7E]') { throw "Non-ASCII character in a shipped file name: $($file.Name)" }
    if ($file.Name.Contains(' ')) { throw "Space in a shipped file name: $($file.Name)" }
}
Write-Host "File names: OK (ASCII, no spaces)"

if (-not (Test-Path -LiteralPath $indexPath)) { throw "index.html missing from the archive root." }
Write-Host "Web build ready: $outDir"
$files | Select-Object Name, @{ N = "MB"; E = { [math]::Round($_.Length / 1MB, 2) } } |
    Sort-Object MB -Descending | Format-Table -AutoSize
