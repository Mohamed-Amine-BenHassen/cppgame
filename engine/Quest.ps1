# ---------------------------------------------------------------
#  Quest.ps1 - the game itself: levels, progress, checking.
# ---------------------------------------------------------------

. (Join-Path $PSScriptRoot 'Ui.ps1')
. (Join-Path $PSScriptRoot 'Toolchain.ps1')

$script:ProgressPath = Join-Path $GameRoot '.state\progress.json'

# ---------- levels ----------

function Get-Levels {
    if ($script:LevelCache) { return $script:LevelCache }
    $dirs = Get-ChildItem (Join-Path $GameRoot 'levels') -Directory | Sort-Object Name
    $list = foreach ($d in $dirs) {
        $metaFile = Join-Path $d.FullName 'meta.json'
        if (-not (Test-Path $metaFile)) { continue }
        $meta = Get-Content $metaFile -Raw | ConvertFrom-Json
        [pscustomobject]@{
            Slug     = $d.Name
            Number   = [int]($d.Name -replace '^(\d+).*$', '$1')
            Dir      = $d.FullName
            Title    = $meta.title
            Act      = $meta.act
            Xp       = [int]$meta.xp
            Concepts = @($meta.concepts)
            Hints    = @($meta.hints)
            Boss     = [bool]$meta.boss
            Tagline  = $meta.tagline
        }
    }
    $script:LevelCache = @($list)
    return $script:LevelCache
}

function Get-Level {
    param([Parameter(Mandatory)]$Id)
    $levels = Get-Levels
    if ("$Id" -match '^\d+$') {
        return $levels | Where-Object { $_.Number -eq [int]$Id } | Select-Object -First 1
    }
    return $levels | Where-Object { $_.Slug -like "*$Id*" } | Select-Object -First 1
}

function Get-WorkDir {
    param($Level)
    return Join-Path $GameRoot ('workspace\' + $Level.Slug)
}

# ---------- progress ----------

function Get-Progress {
    if (Test-Path $script:ProgressPath) {
        $p = Get-Content $script:ProgressPath -Raw | ConvertFrom-Json
        if ($null -eq $p.completed) { $p | Add-Member -NotePropertyName completed -NotePropertyValue @() -Force }
        return $p
    }
    return [pscustomobject]@{
        hero      = $null
        xp        = 0
        completed = @()
        attempts  = [pscustomobject]@{}
        started   = (Get-Date).ToString('o')
    }
}

function Save-Progress {
    param($Progress)
    New-Item -ItemType Directory -Force -Path (Split-Path $script:ProgressPath) | Out-Null
    $Progress | ConvertTo-Json -Depth 6 | Set-Content $script:ProgressPath -Encoding UTF8
}

function Test-LevelDone {
    param($Progress, $Level)
    return (@($Progress.completed) -contains $Level.Slug)
}

function Get-CurrentLevel {
    $p = Get-Progress
    foreach ($l in (Get-Levels)) {
        if (-not (Test-LevelDone $p $l)) { return $l }
    }
    return $null
}

function Get-TotalXp {
    $sum = 0
    foreach ($l in (Get-Levels)) { $sum += $l.Xp }
    return $sum
}

# ---------- the map ----------

function Show-Map {
    $p       = Get-Progress
    $levels  = Get-Levels
    $current = Get-CurrentLevel

    Write-Banner
    if ($p.hero) {
        Write-Host '  hero: ' -NoNewline -ForegroundColor DarkGray
        Write-Host $p.hero -ForegroundColor White
    }
    Write-XpBar -Xp ([int]$p.xp) -MaxXp (Get-TotalXp)

    $act = $null
    foreach ($l in $levels) {
        if ($l.Act -ne $act) {
            $act = $l.Act
            Write-Host ''
            Write-Rule $act 'DarkCyan'
        }

        $done  = Test-LevelDone $p $l
        $isCur = ($null -ne $current -and $l.Slug -eq $current.Slug)

        if ($done)      { $mark = '[x]'; $c = 'Green' }
        elseif ($isCur) { $mark = '[>]'; $c = 'Yellow' }
        else            { $mark = '[ ]'; $c = 'DarkGray' }

        $num = '{0:00}' -f $l.Number
        Write-Host "   $mark " -NoNewline -ForegroundColor $c
        Write-Host "$num " -NoNewline -ForegroundColor DarkGray
        Write-Host $l.Title.PadRight(28) -NoNewline -ForegroundColor $c
        if ($l.Boss)  { Write-Host 'BOSS ' -NoNewline -ForegroundColor Magenta }
        if ($isCur)   { Write-Host ' <- you are here' -NoNewline -ForegroundColor Yellow }
        Write-Host ''
    }

    Write-Host ''
    if ($current) {
        Write-Rule
        Write-Host '  next up: ' -NoNewline -ForegroundColor DarkGray
        Write-Host $current.Title -ForegroundColor White
        if ($current.Tagline) { Write-Host "  $($current.Tagline)" -ForegroundColor DarkGray }
        Write-Host '  run ' -NoNewline -ForegroundColor DarkGray
        Write-Host '.\play.ps1 start' -NoNewline -ForegroundColor Cyan
        Write-Host ' to begin.' -ForegroundColor DarkGray
    } else {
        Write-Host '  Every floor is cleared. You built a game. Now go build another.' -ForegroundColor Green
    }
    Write-Host ''
}

# ---------- starting a level ----------

function Start-Level {
    param($Id)

    $level = if ($Id) { Get-Level $Id } else { Get-CurrentLevel }
    if (-not $level) { Write-Fail "No such floor: $Id"; return }

    $p = Get-Progress
    if (-not $p.hero) {
        Write-Banner
        Write-Host '  Before we climb - what should the tower call you?' -ForegroundColor Gray
        Write-Host '  name> ' -NoNewline -ForegroundColor Cyan
        $name = Read-Host
        if (-not $name) { $name = 'apprentice' }
        $p.hero = $name
        Save-Progress $p
        Write-Host ''
        Write-Host "  Welcome, $name. Floor one is open." -ForegroundColor Yellow
        Start-Sleep -Milliseconds 600
    }

    $work  = Get-WorkDir $level
    $isNew = -not (Test-Path $work)
    if ($isNew) {
        New-Item -ItemType Directory -Force -Path $work | Out-Null
        Copy-Item (Join-Path $level.Dir 'start\*') -Destination $work -Recurse -Force
    }

    # Clearing fails when output is piped to a file; that is no reason to stop.
    try { Clear-Host } catch { Write-Host '' }

    Show-Markdown (Join-Path $level.Dir 'brief.md')

    Write-Rule 'your workspace'
    Write-Host ''
    foreach ($f in (Get-ChildItem $work -File | Where-Object { $_.Extension -in '.cpp', '.h', '.hpp', '.txt' })) {
        Write-Host '   edit  ' -NoNewline -ForegroundColor DarkGray
        Write-Host ('workspace\' + $level.Slug + '\' + $f.Name) -ForegroundColor Cyan
    }
    if (-not $isNew) { Write-Host '   (your existing work was kept)' -ForegroundColor DarkGray }

    Write-Host ''
    Write-Host '   .\play.ps1 run    ' -NoNewline -ForegroundColor Cyan
    Write-Host 'compile it and play with it yourself' -ForegroundColor DarkGray
    Write-Host '   .\play.ps1 check  ' -NoNewline -ForegroundColor Cyan
    Write-Host 'compile it and face the trials' -ForegroundColor DarkGray
    Write-Host '   .\play.ps1 hint   ' -NoNewline -ForegroundColor Cyan
    Write-Host 'a nudge, one at a time' -ForegroundColor DarkGray
    Write-Host ''

    # Open the editor without letting its console chatter into our output.
    if (Get-Command code -ErrorAction SilentlyContinue) {
        $main = Get-ChildItem $work -Filter *.cpp | Select-Object -First 1
        if ($main) {
            try {
                Start-Process -FilePath 'cmd.exe' `
                              -ArgumentList '/c', 'code', "`"$($main.FullName)`"" `
                              -WindowStyle Hidden -ErrorAction SilentlyContinue
            } catch { }
        }
    }
}

function Show-Brief {
    param($Id)
    $level = if ($Id) { Get-Level $Id } else { Get-CurrentLevel }
    if (-not $level) { return }
    Show-Markdown (Join-Path $level.Dir 'brief.md')
}

# ---------- running ----------

function Write-CompilerOutput {
    param([string]$Text)
    foreach ($line in ($Text -split "`r?`n")) {
        $color = 'DarkGray'
        if ($line -match ' error ')        { $color = 'Red' }
        elseif ($line -match ' warning ')  { $color = 'Yellow' }
        Write-Host ('    ' + $line) -ForegroundColor $color
    }
    Write-Host ''
    Write-Host '  Read the FIRST error, not the last. One mistake often causes ten.' -ForegroundColor DarkCyan
    Write-Host ''
}

function Invoke-LevelRun {
    param($Id)
    $level = if ($Id) { Get-Level $Id } else { Get-CurrentLevel }
    if (-not $level) { Write-Fail 'Nothing to run.'; return }

    $work = Get-WorkDir $level
    if (-not (Test-Path $work)) { Write-Warn 'Floor not started yet. Run: .\play.ps1 start'; return }

    Write-Host ''
    Write-Info "building with $(Get-CompilerLabel)..."
    $build = Build-Project -SourceDir $work -ExeName 'game'
    if (-not $build.Ok) {
        Write-Fail 'the compiler refused it.'
        Write-Host ''
        Write-CompilerOutput $build.Output
        return
    }
    Write-Ok 'compiled'
    Write-Host ''
    Write-Rule 'your program'
    Write-Host ''
    & $build.Exe
    Write-Host ''
    Write-Rule 'end of program'
    Write-Host ''
}

# ---------- checking ----------

function ConvertTo-Comparable {
    param([string]$Text)
    # The leading comma matters: without it PowerShell unrolls a one-line
    # result into a bare string, and the caller ends up comparing characters
    # instead of lines.
    if ($null -eq $Text) { return , @() }
    $lines = @((($Text -replace "`r`n", "`n") -split "`n") | ForEach-Object { $_.TrimEnd() })
    $end = $lines.Count - 1
    while ($end -ge 0 -and $lines[$end] -eq '') { $end-- }
    if ($end -lt 0) { return , @() }
    return , @($lines[0..$end])
}

function Test-SourceRules {
    param($Level, $WorkDir)

    $issues = @()
    $files = Get-ChildItem $WorkDir -File -Recurse |
             Where-Object { $_.Extension -in '.cpp', '.h', '.hpp' -and $_.FullName -notmatch '\\\.build\\' }
    $source = ($files | ForEach-Object { Get-Content $_.FullName -Raw }) -join "`n"

    foreach ($kind in 'require', 'forbid') {
        $file = Join-Path $Level.Dir "$kind.txt"
        if (-not (Test-Path $file)) { continue }
        foreach ($line in (Get-Content $file)) {
            if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith('#')) { continue }
            $parts   = $line -split '\|\|', 2
            $pattern = $parts[0].Trim()
            $why     = if ($parts.Count -gt 1) { $parts[1].Trim() } else { "source rule: $pattern" }
            $hit     = $source -match $pattern
            if ($kind -eq 'require' -and -not $hit) { $issues += $why }
            if ($kind -eq 'forbid'  -and $hit)      { $issues += $why }
        }
    }
    return , @($issues)
}

function Invoke-LevelCheck {
    param($Id, [switch]$Quiet, [string]$OverrideDir)

    $level = if ($Id) { Get-Level $Id } else { Get-CurrentLevel }
    if (-not $level) { Write-Fail 'Nothing to check.'; return $false }

    $work = if ($OverrideDir) { $OverrideDir } else { Get-WorkDir $level }
    if (-not (Test-Path $work)) { Write-Warn 'Floor not started yet. Run: .\play.ps1 start'; return $false }

    if (-not $Quiet) {
        Write-Host ''
        Write-Rule "trial - $($level.Title)" 'Cyan'
        Write-Host ''
    }

    $build = Build-Project -SourceDir $work -ExeName 'game'
    if (-not $build.Ok) {
        Write-Fail 'it does not compile yet'
        Write-Host ''
        Write-CompilerOutput $build.Output
        return $false
    }
    if (-not $Quiet) { Write-Ok 'compiles cleanly' }

    $issues = Test-SourceRules -Level $level -WorkDir $work
    if ($issues.Count -gt 0) {
        foreach ($i in $issues) { Write-Fail $i }
        Write-Host ''
        Write-Host '  The output may be right, but this trial is about HOW you got it.' -ForegroundColor DarkCyan
        Write-Host ''
        return $false
    }

    $testDir = Join-Path $level.Dir 'tests'
    $cases   = @(Get-ChildItem $testDir -Filter '*.in' -File -ErrorAction SilentlyContinue | Sort-Object Name)
    $passed  = 0
    $failed  = @()

    foreach ($case in $cases) {
        $name  = $case.BaseName
        $stdin = Get-Content $case.FullName -Raw -ErrorAction SilentlyContinue
        if ($null -eq $stdin) { $stdin = '' }

        $expected = ConvertTo-Comparable (Get-Content (Join-Path $testDir "$name.out") -Raw)

        $titleFile = Join-Path $testDir "$name.title"
        $label = if (Test-Path $titleFile) { (Get-Content $titleFile -Raw).Trim() } else { "trial $name" }

        Reset-RunArtifacts -Dir $work
        $res    = Invoke-Program -Exe $build.Exe -StdIn $stdin -WorkDir $work
        $actual = ConvertTo-Comparable $res.StdOut

        if ($res.TimedOut) {
            Write-Fail "$label - your program never stopped (infinite loop?)"
            $failed += @{ Label = $label; Expected = $expected; Actual = $actual; Timeout = $true }
            continue
        }

        $same = ($actual.Count -eq $expected.Count)
        if ($same) {
            for ($i = 0; $i -lt $actual.Count; $i++) {
                if ($actual[$i] -cne $expected[$i]) { $same = $false; break }
            }
        }

        if ($same) {
            $passed++
            if (-not $Quiet) { Write-Ok $label }
        } else {
            Write-Fail $label
            $failed += @{ Label = $label; Expected = $expected; Actual = $actual; Timeout = $false }
        }
    }

    Register-Attempt $level

    if ($failed.Count -gt 0) {
        $f = $failed[0]
        if (-not $f.Timeout) { Show-Diff -Expected $f.Expected -Actual $f.Actual }
        Write-Host "  $passed of $($cases.Count) trials passed." -ForegroundColor Yellow
        Write-Host '  Fix it and run ' -NoNewline -ForegroundColor DarkGray
        Write-Host '.\play.ps1 check' -NoNewline -ForegroundColor Cyan
        Write-Host ' again.  Stuck? ' -NoNewline -ForegroundColor DarkGray
        Write-Host '.\play.ps1 hint' -ForegroundColor Cyan
        Write-Host ''
        return $false
    }

    if (-not $Quiet) { Complete-Level $level }
    return $true
}

function Register-Attempt {
    param($Level)
    $p = Get-Progress
    if ($null -eq $p.attempts) { $p | Add-Member -NotePropertyName attempts -NotePropertyValue ([pscustomobject]@{}) -Force }
    $n = 0
    if ($p.attempts.PSObject.Properties.Name -contains $Level.Slug) { $n = [int]$p.attempts.($Level.Slug) }
    $p.attempts | Add-Member -NotePropertyName $Level.Slug -NotePropertyValue ($n + 1) -Force
    Save-Progress $p
}

function Complete-Level {
    param($Level)

    $p = Get-Progress
    $first = -not (Test-LevelDone $p $Level)

    Write-Host ''
    if ($first) {
        $oldRank = Get-Rank ([int]$p.xp)
        $p.completed = @($p.completed) + $Level.Slug
        $p.xp = [int]$p.xp + $Level.Xp
        $newRank = Get-Rank ([int]$p.xp)
        Save-Progress $p

        if ($Level.Boss) { Write-Host '   ***  BOSS FLOOR CLEARED  ***' -ForegroundColor Magenta }
        else             { Write-Host '   ***  FLOOR CLEARED  ***' -ForegroundColor Green }

        Write-Host ''
        Write-Host "   +$($Level.Xp) XP" -ForegroundColor Green
        if ($newRank -ne $oldRank) {
            Write-Host ''
            Write-Host "   New rank: $newRank" -ForegroundColor Yellow
        }
        Write-Host ''
        Write-XpBar -Xp ([int]$p.xp) -MaxXp (Get-TotalXp)
    } else {
        Write-Host '   All trials pass (floor already cleared).' -ForegroundColor Green
    }

    Write-Host ''
    $next = Get-CurrentLevel
    if ($next) {
        Write-Rule
        Write-Host '  Next floor: ' -NoNewline -ForegroundColor DarkGray
        Write-Host $next.Title -ForegroundColor White
        if ($next.Tagline) { Write-Host "  $($next.Tagline)" -ForegroundColor DarkGray }
        Write-Host '  ' -NoNewline
        Write-Host '.\play.ps1 start' -ForegroundColor Cyan
    } else {
        Write-Host '  =============================================================' -ForegroundColor Magenta
        Write-Host '   You are at the top of the tower.' -ForegroundColor Magenta
        Write-Host '   The game in workspace\25-the-last-door is one YOU wrote.' -ForegroundColor Magenta
        Write-Host '  =============================================================' -ForegroundColor Magenta
    }
    Write-Host ''
}

# ---------- help ----------

function Show-Hint {
    param($Id)
    $level = if ($Id) { Get-Level $Id } else { Get-CurrentLevel }
    if (-not $level) { return }

    $statePath = Join-Path $GameRoot ('.state\hints-' + $level.Slug + '.txt')
    $shown = if (Test-Path $statePath) { [int]((Get-Content $statePath -Raw).Trim()) } else { 0 }

    if ($shown -ge $level.Hints.Count) {
        Write-Host ''
        Write-Warn 'No hints left on this floor.'
        Write-Host '  To read the reference answer: ' -NoNewline -ForegroundColor DarkGray
        Write-Host '.\play.ps1 solution' -ForegroundColor Cyan
        Write-Host ''
        return
    }

    Write-Host ''
    Write-Host "  hint $($shown + 1) of $($level.Hints.Count)" -ForegroundColor DarkYellow
    Write-Host ''
    Write-Host '  ' -NoNewline
    Write-Inline $level.Hints[$shown]
    Write-Host ''
    Set-Content $statePath (($shown + 1).ToString())
}

function Show-Solution {
    param($Id)
    $level = if ($Id) { Get-Level $Id } else { Get-CurrentLevel }
    if (-not $level) { return }

    Write-Host ''
    Write-Warn 'Reading the answer is allowed - but retype it, do not paste it.'
    Write-Host ''
    foreach ($f in (Get-ChildItem (Join-Path $level.Dir 'solution') -File | Sort-Object Name)) {
        Write-Rule $f.Name 'Cyan'
        foreach ($line in (Get-Content $f.FullName)) {
            Write-Host ('    ' + $line) -ForegroundColor Cyan
        }
        Write-Host ''
    }
}

function Show-Status {
    $p   = Get-Progress
    $cur = Get-CurrentLevel
    Write-Host ''
    Write-XpBar -Xp ([int]$p.xp) -MaxXp (Get-TotalXp)
    Write-Host ''
    Write-Host "  cleared:  $(@($p.completed).Count) of $((Get-Levels).Count) floors" -ForegroundColor Gray
    $tc = if (Initialize-Toolchain) { Get-CompilerLabel } else { 'NOT FOUND' }
    Write-Host "  compiler: $tc" -ForegroundColor Gray
    if ($cur) { Write-Host "  current:  $($cur.Number). $($cur.Title)" -ForegroundColor Gray }
    Write-Host ''
}

function Reset-Level {
    param($Id)
    $level = if ($Id) { Get-Level $Id } else { Get-CurrentLevel }
    if (-not $level) { return }
    $work = Get-WorkDir $level
    Write-Host ''
    Write-Warn "This deletes your code in workspace\$($level.Slug) and restores the starter."
    Write-Host '  type YES to confirm: ' -NoNewline -ForegroundColor Yellow
    if ((Read-Host) -ne 'YES') { Write-Host '  cancelled.' -ForegroundColor DarkGray; return }
    Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force -Path $work | Out-Null
    Copy-Item (Join-Path $level.Dir 'start\*') -Destination $work -Recurse -Force
    Write-Ok 'starter code restored.'
}

# ---------- maintenance ----------

function Test-AllSolutions {
    param($Id)
    $levels = if ($Id) { @(Get-Level $Id) } else { Get-Levels }
    $fail = 0
    foreach ($l in $levels) {
        $tmp = Join-Path $env:TEMP ('tot-sol-' + $l.Slug)
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Force -Path $tmp | Out-Null
        Copy-Item (Join-Path $l.Dir 'solution\*') -Destination $tmp -Recurse -Force
        Write-Host ('  {0,-30}' -f $l.Slug) -NoNewline -ForegroundColor Gray
        $ok = Invoke-LevelCheck -Id $l.Number -Quiet -OverrideDir $tmp
        if ($ok) { Write-Host 'PASS' -ForegroundColor Green }
        else     { Write-Host 'FAIL' -ForegroundColor Red; $fail++ }
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Host ''
    if ($fail -eq 0) { Write-Ok 'every reference solution passes its own trials' }
    else { Write-Fail "$fail level(s) broken" }
}

function Show-Help {
    Write-Banner
    Write-Rule 'commands'
    Write-Host ''
    $rows = @(
        @('(nothing)',    'show the tower map'),
        @('start [n]',    'open the next floor and set up your workspace'),
        @('run [n]',      'compile your code and run it yourself'),
        @('check [n]',    'compile it and face the trials - this clears the floor'),
        @('hint',         'one nudge at a time'),
        @('solution [n]', 'show the reference answer'),
        @('brief [n]',    're-read the lesson'),
        @('status',       'xp, rank, compiler'),
        @('reset [n]',    'restore a floor to its starter code'),
        @('help',         'this list')
    )
    foreach ($r in $rows) {
        Write-Host ('   .\play.ps1 ' + $r[0].PadRight(14)) -NoNewline -ForegroundColor Cyan
        Write-Host $r[1] -ForegroundColor DarkGray
    }
    Write-Host ''
}
