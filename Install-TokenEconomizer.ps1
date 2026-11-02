#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$SourcePath,
    [string]$PythonPath,
    [string]$CodexPath,
    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function FullPath([string]$Path) { [IO.Path]::GetFullPath($Path) }
function Assert-Child([string]$Path, [string]$Parent) {
    $prefix = (FullPath $Parent).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    if (-not (FullPath $Path).StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Güvensiz çıktı yolu: $Path"
    }
}
function Assert-NoLinks([string]$Path) {
    $cursor = FullPath $Path
    while ($cursor) {
        if (Test-Path -LiteralPath $cursor) {
            if ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Bağlantı/junction üzerinden kurulum reddedildi: $cursor"
            }
        }
        $cursor = Split-Path $cursor -Parent
    }
}
function Run([string]$Exe, [string[]]$Arguments) {
    & $Exe @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Komut başarısız ($LASTEXITCODE): $Exe $($Arguments -join ' ')" }
}
function Backup([string]$Path) {
    if (Test-Path -LiteralPath $Path) {
        $backupPath = "$Path.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$([guid]::NewGuid().ToString('N').Substring(0,8))"
        Copy-Item -LiteralPath $Path -Destination $backupPath -Recurse -Force
        Write-Host "Yedek: $backupPath"
    }
}
function Write-Utf8([string]$Path, [string]$Text) {
    [IO.File]::WriteAllText($Path, $Text, (New-Object Text.UTF8Encoding($false)))
}

if (-not $SourcePath) {
    $parentPath = Split-Path $PSScriptRoot -Parent
    $SourcePath = if (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'scripts/build_plugin.py')) { $PSScriptRoot }
    elseif (Test-Path -LiteralPath (Join-Path $parentPath 'scripts/build_plugin.py')) { $parentPath }
    else { Join-Path $parentPath 'TokenEconomizer' }
}
$SourcePath = (Resolve-Path -LiteralPath $SourcePath).Path
foreach ($required in @('scripts/build_plugin.py', 'plugin/hooks/codex-hooks.json', 'tokeneconomizer/plugin/cli.py')) {
    if (-not (Test-Path -LiteralPath (Join-Path $SourcePath $required) -PathType Leaf)) {
        throw "Upstream kaynak eksik: $required"
    }
}
# Upstream builder copies only these two code trees. Refuse private state or links in either.
foreach ($tree in @('plugin', 'tokeneconomizer')) {
    $treePath = Join-Path $SourcePath $tree
    Assert-NoLinks $treePath
    foreach ($item in Get-ChildItem -LiteralPath $treePath -Recurse -Force) {
        # plugin/lib is an upstream development symlink; build_plugin.py explicitly excludes it.
        if ($tree -eq 'plugin' -and ($item.FullName -eq (Join-Path $treePath 'lib'))) { continue }
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Kaynak bağlantısı: $($item.FullName)" }
        if ($item.Name -match '^(sessions|state|auth|auth\.json|\.env|\.codex|\.tokeneconomizer)$') {
            throw "Kaynakta özel durum dosyası/dizini bulundu: $($item.FullName)"
        }
    }
}

$candidatePaths = @()
if ($PythonPath) { $candidatePaths = @($PythonPath) }
else {
    $candidatePaths += Join-Path $env:USERPROFILE '.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
    foreach ($name in @('python.exe', 'python3.exe')) {
        $found = Get-Command $name -ErrorAction SilentlyContinue
        if ($found) { $candidatePaths += $found.Source }
    }
    $py = Get-Command py.exe -ErrorAction SilentlyContinue
    if ($py) {
        $detected = & $py.Source -3 -c 'import sys; print(sys.executable)' 2>$null
        if ($LASTEXITCODE -eq 0) { $candidatePaths += $detected }
    }
}
$PythonPath = $null
foreach ($candidate in $candidatePaths) {
    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf) -or $candidate -match '\\WindowsApps\\') { continue }
    $resolved = & $candidate -c 'import sys; assert sys.version_info >= (3,10); print(sys.executable)' 2>$null
    if ($LASTEXITCODE -eq 0 -and $resolved -and (Test-Path -LiteralPath ([string]$resolved) -PathType Leaf)) {
        $PythonPath = FullPath ([string]$resolved)
        break
    }
}
if (-not $PythonPath) { throw 'Python >=3.10 bulunamadı. -PythonPath ile gerçek python.exe verin.' }
if (-not $CodexPath) {
    $codexCommand = Get-Command codex -ErrorAction Stop
    $CodexPath = $codexCommand.Source
}
$CodexPath = (Resolve-Path -LiteralPath $CodexPath).Path
$codexRoot = if ($env:CODEX_HOME) { FullPath $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
$toolsRoot = Join-Path $codexRoot 'tools'
$bundle = Join-Path $toolsRoot 'tokeneconomizer-marketplace'
$agentsPath = Join-Path $codexRoot 'AGENTS.md'
$codexConfig = Join-Path $codexRoot 'config.toml'
$teRoot = if ($env:TOKENECONOMIZER_HOME) { FullPath $env:TOKENECONOMIZER_HOME } else { Join-Path $env:USERPROFILE '.tokeneconomizer' }
Assert-Child $bundle $toolsRoot
Assert-NoLinks $bundle
Assert-NoLinks $agentsPath
Assert-NoLinks $codexConfig
Assert-NoLinks $teRoot
Assert-NoLinks (Join-Path $teRoot 'config.json')
if (Test-Path -LiteralPath $bundle) {
    foreach ($item in Get-ChildItem -LiteralPath $bundle -Recurse -Force) {
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Bundle bağlantısı: $($item.FullName)" }
    }
}
Write-Host "Python: $PythonPath`nCodex: $CodexPath`nMarketplace: $bundle`nTE ayarları: $teRoot"
if ($DryRun) {
    Write-Host 'DryRun: doğrulama tamamlandı; dosya yazılmadı, eklenti/ayar değiştirilmedi.'
    return
}

New-Item -ItemType Directory -Path $toolsRoot -Force | Out-Null
Backup $bundle
Run $PythonPath @('-B', (Join-Path $SourcePath 'scripts/build_plugin.py'), '--out', $bundle)
$plugin = Join-Path $bundle 'tokeneconomizer'
Assert-Child $plugin $bundle
$hookPath = Join-Path $plugin 'hooks/codex-hooks.json'
$hooks = Get-Content -LiteralPath $hookPath -Raw | ConvertFrom-Json
foreach ($event in $hooks.hooks.PSObject.Properties) {
    foreach ($group in $event.Value) {
        foreach ($hook in $group.hooks) {
            if (-not $hook.commandWindows.StartsWith('python -X --% -u -X utf8 -c ')) {
                throw 'Upstream Windows hook biçimi değişmiş; kurulum durduruldu.'
            }
            $code = $hook.commandWindows.Substring('python -X --% -u -X utf8 -c '.Length)
            # EncodedCommand crosses both cmd.exe and PowerShell without path/quote expansion.
            # The decoded command invokes the selected absolute Python path with literal arguments.
            $launch = "& '" + $PythonPath.Replace("'", "''") + "' -u -X utf8 -c '" + $code.Replace("'", "''") + "'; exit `$LASTEXITCODE"
            $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($launch))
            $hook.commandWindows = "powershell.exe -NoLogo -NoProfile -NonInteractive -EncodedCommand $encoded"
        }
    }
}
Write-Utf8 $hookPath (($hooks | ConvertTo-Json -Depth 30) + "`n")
foreach ($required in @('.claude-plugin/marketplace.json', 'tokeneconomizer/lib/tokeneconomizer/plugin/cli.py')) {
    if (-not (Test-Path -LiteralPath (Join-Path $bundle $required) -PathType Leaf)) { throw "Bundle eksik: $required" }
}
Backup $codexConfig
Run $CodexPath @('plugin', 'marketplace', 'add', $bundle)
Run $CodexPath @('plugin', 'add', 'tokeneconomizer@tokeneconomizer')
Backup (Join-Path $teRoot 'config.json')
$bootstrap = Join-Path $plugin 'scripts/te_bootstrap.py'
Run $PythonPath @('-B', $bootstrap, 'cli', '--host', 'codex', 'config', 'set', '--global', 'microskills=envfacts', 'toolprune=propose', 'loopguard=on')

$start = '<!-- TOKENECONOMIZER-LOCAL-START -->'
$end = '<!-- TOKENECONOMIZER-LOCAL-END -->'
$block = @'
<!-- TOKENECONOMIZER-LOCAL-START -->
## Token tasarrufu
TokenEconomizer kurulu. Ortam bilgilerini yeniden keşfetmeden önce mevcut bilgileri kullan; gereksiz komut tekrarını ve uzun araç çıktısını azalt. Kaliteyi, gerekli testleri ve kullanıcının ajan tercihlerini koru.
Durum: `$tokeneconomizer:status`; terminal: Python ile `<CODEX_HOME>/tools/tokeneconomizer-marketplace/tokeneconomizer/scripts/te_bootstrap.py cli --host codex status`.
<!-- TOKENECONOMIZER-LOCAL-END -->
'@
$existing = if (Test-Path -LiteralPath $agentsPath) { [IO.File]::ReadAllText($agentsPath) } else { '' }
$pattern = '(?s)' + [regex]::Escape($start) + '.*?' + [regex]::Escape($end)
if (($existing.Contains($start) -or $existing.Contains($end)) -and -not [regex]::IsMatch($existing, $pattern)) {
    throw 'AGENTS.md içinde tamamlanmamış marker var; elle kontrol edin.'
}
$updated = if ([regex]::IsMatch($existing, $pattern)) { [regex]::Replace($existing, $pattern, [Text.RegularExpressions.MatchEvaluator]{ param($match) $block }) }
else { $existing.TrimEnd() + "`r`n`r`n" + $block + "`r`n" }
if ($updated -ne $existing) { Backup $agentsPath; Write-Utf8 $agentsPath $updated }
Run $PythonPath @('-B', $bootstrap, 'cli', '--host', 'codex', 'config', 'show')
Write-Host 'Kuruldu. Codex resmi Hooks need review ekranında hookları inceleyip onaylayın; ardından yeni oturum açıp $tokeneconomizer:status çalıştırın.'
