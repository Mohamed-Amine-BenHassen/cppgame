<#
    Authoring tool (not part of the player experience).

    Runs every level's STARTER code against its own trials. Every one of them
    must FAIL - a starter that passes means the floor teaches nothing.

    Usage:  pwsh -File engine\Test-Starters.ps1
#>
param([string]$Only)

$ErrorActionPreference = 'Stop'
$GameRoot = Split-Path $PSScriptRoot -Parent
. (Join-Path $GameRoot 'engine\Quest.ps1')

if (-not (Initialize-Toolchain)) { throw 'no compiler' }

$levels = if ($Only) { @(Get-Level $Only) } else { Get-Levels }
$bad = 0

foreach ($l in $levels) {
    $tmp = Join-Path $env:TEMP ('tot-start-' + $l.Slug)
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null
    Copy-Item (Join-Path $l.Dir 'start\*') -Destination $tmp -Recurse -Force

    Write-Host ('  {0,-30}' -f $l.Slug) -NoNewline -ForegroundColor Gray

    $passed = Invoke-LevelCheck -Id $l.Number -Quiet -OverrideDir $tmp 6>$null
    if ($passed) {
        Write-Host 'STARTER PASSES - the floor is free' -ForegroundColor Red
        $bad++
    } else {
        Write-Host 'fails as it should' -ForegroundColor DarkGreen
    }

    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
if ($bad -eq 0) {
    Write-Host '  [ OK ] every starter fails its own trials' -ForegroundColor Green
} else {
    Write-Host "  [FAIL] $bad starter(s) already pass" -ForegroundColor Red
}
