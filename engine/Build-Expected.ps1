<#
    Authoring tool (not part of the player experience).

    For every level, compiles levels\<slug>\solution and runs it against each
    tests\*.in, writing the captured stdout to tests\*.out. Keeps the trials
    and the reference answers from ever drifting apart.

    Usage:  pwsh -File engine\Build-Expected.ps1 [-Only 07]
#>
param([string]$Only)

$ErrorActionPreference = 'Stop'
$GameRoot = Split-Path $PSScriptRoot -Parent
. (Join-Path $GameRoot 'engine\Quest.ps1')

if (-not (Initialize-Toolchain)) { throw 'no compiler' }

$levels = if ($Only) { @(Get-Level $Only) } else { Get-Levels }

foreach ($l in $levels) {
    $testDir = Join-Path $l.Dir 'tests'
    $cases = @(Get-ChildItem $testDir -Filter '*.in' -File -ErrorAction SilentlyContinue | Sort-Object Name)
    if ($cases.Count -eq 0) { Write-Host "  $($l.Slug): no test inputs" -ForegroundColor DarkGray; continue }

    $tmp = Join-Path $env:TEMP ('tot-gen-' + $l.Slug)
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null
    Copy-Item (Join-Path $l.Dir 'solution\*') -Destination $tmp -Recurse -Force

    $build = Build-Project -SourceDir $tmp -ExeName 'gen'
    if (-not $build.Ok) {
        Write-Host "  $($l.Slug): SOLUTION DOES NOT COMPILE" -ForegroundColor Red
        Write-Host $build.Output -ForegroundColor DarkGray
        continue
    }

    foreach ($case in $cases) {
        $stdin = Get-Content $case.FullName -Raw -ErrorAction SilentlyContinue
        if ($null -eq $stdin) { $stdin = '' }
        Reset-RunArtifacts -Dir $tmp
        $res = Invoke-Program -Exe $build.Exe -StdIn $stdin -WorkDir $tmp
        if ($res.TimedOut) {
            Write-Host "  $($l.Slug)/$($case.BaseName): TIMED OUT" -ForegroundColor Red
            continue
        }
        $text = (ConvertTo-Comparable $res.StdOut) -join "`n"
        Set-Content -Path (Join-Path $testDir ($case.BaseName + '.out')) -Value $text -Encoding UTF8 -NoNewline
        Write-Host "  $($l.Slug)/$($case.BaseName) -> $((ConvertTo-Comparable $res.StdOut).Count) lines" -ForegroundColor DarkGray
    }
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  $($l.Slug): expected output written" -ForegroundColor Green
}
