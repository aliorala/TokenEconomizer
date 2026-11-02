#Requires -Version 5.1
param([Parameter(Mandatory)][string]$PythonPath)
$ErrorActionPreference = 'Stop'
$testRoot = Join-Path $PSScriptRoot ('.test-' + [guid]::NewGuid().ToString('N'))
$saved = @{}
foreach ($name in @('HOME','USERPROFILE','CODEX_HOME','TOKENECONOMIZER_HOME','PYTHONDONTWRITEBYTECODE','PLUGIN_ROOT')) {
    $saved[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}
try {
    New-Item -ItemType Directory -Path $testRoot | Out-Null
    $env:HOME = $testRoot
    $env:USERPROFILE = $testRoot
    $env:CODEX_HOME = Join-Path $testRoot '.codex'
    $env:TOKENECONOMIZER_HOME = Join-Path $testRoot '.tokeneconomizer'
    $env:PYTHONDONTWRITEBYTECODE = '1'
    $fake = Join-Path $testRoot 'codex.ps1'
    Set-Content -LiteralPath $fake -Value 'param([Parameter(ValueFromRemainingArguments=$true)]$Items) Add-Content -LiteralPath (Join-Path $env:HOME "calls.txt") -Value ($Items -join "|"); $global:LASTEXITCODE=0' -Encoding UTF8
    $installer = Join-Path $PSScriptRoot 'Install-TokenEconomizer.ps1'
    & $installer -PythonPath $PythonPath -CodexPath $fake -DryRun
    if (Test-Path $env:CODEX_HOME) { throw 'DryRun wrote files' }
    & $installer -PythonPath $PythonPath -CodexPath $fake
    $agents = Join-Path $env:CODEX_HOME 'AGENTS.md'
    Add-Content -LiteralPath $agents -Value "`nKEEP-USER-INSTRUCTIONS"
    & $installer -PythonPath $PythonPath -CodexPath $fake
    $text = Get-Content -LiteralPath $agents -Raw
    if ([regex]::Matches($text, '<!-- TOKENECONOMIZER-LOCAL-START -->').Count -ne 1 -or -not $text.Contains('KEEP-USER-INSTRUCTIONS')) { throw 'AGENTS preservation/idempotence failed' }
    $config = Get-Content (Join-Path $env:TOKENECONOMIZER_HOME 'config.json') -Raw | ConvertFrom-Json
    # Upstream canonicalizes loopguard=on to nudge.
    if ($config.microskills -ne 'envfacts' -or $config.toolprune -ne 'propose' -or $config.loopguard -ne 'nudge') { throw 'Global CLI settings mismatch' }
    $bundle = Join-Path $env:CODEX_HOME 'tools/tokeneconomizer-marketplace'
    if (@(Get-ChildItem (Split-Path $bundle) -Filter '*.backup-*').Count -ne 1) { throw 'Bundle backup missing' }
    $hooks = Get-Content (Join-Path $bundle 'tokeneconomizer/hooks/codex-hooks.json') -Raw | ConvertFrom-Json
    $command = $hooks.hooks.SessionStart[0].hooks[0].commandWindows
    $env:PLUGIN_ROOT = Join-Path $bundle 'tokeneconomizer'
    # Both actual Windows native shells must invoke the same absolute interpreter.
    $probe = Join-Path $testRoot 'probe.py'
    Set-Content -LiteralPath $probe -Encoding UTF8 -Value @'
import json, os, subprocess, sys
command = sys.argv[1]
for shell in (['cmd.exe', '/d', '/s', '/c', command], ['powershell.exe', '-NoProfile', '-Command', command]):
    result = subprocess.run(shell, input=json.dumps({'hook_event_name': 'Unknown'}), text=True, capture_output=True, timeout=30)
    assert result.returncode == 0, (shell[0], result.stderr)
    assert json.loads(result.stdout) == {}, result.stdout
assert not os.path.exists(os.path.join(os.environ['TOKENECONOMIZER_HOME'], 'errors.log'))
'@
    & $PythonPath -B $probe $command
    if ($LASTEXITCODE -ne 0) { throw 'Native shell hook probe failed' }
    Write-Host "PASS: DryRun, CLI ayarları, tekrar kurulum, yedek, AGENTS koruma ve iki native shell. Geçici çıktılar: $testRoot"
}
finally {
    foreach ($name in $saved.Keys) { [Environment]::SetEnvironmentVariable($name, $saved[$name], 'Process') }
}
