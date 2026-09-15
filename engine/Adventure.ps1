# ---------------------------------------------------------------
#  Adventure.ps1 - the game. You start it once and stay inside it.
#
#  Screens: title -> tower -> lesson -> trial -> victory -> tower
#  The trial screen watches your source files and re-runs the trials
#  the instant you save, so writing code IS the combat system.
# ---------------------------------------------------------------

. (Join-Path $PSScriptRoot 'Screen.ps1')
. (Join-Path $PSScriptRoot 'Quest.ps1')

$script:State    = 'title'
$script:Sel      = 0          # index into Get-Levels
$script:Keys     = $null      # scripted input queue, for testing
$script:Log      = New-Object System.Collections.ArrayList

# --- input -----------------------------------------------------------

function Read-GameKey {
    param([switch]$NonBlocking)

    if ($script:Keys -and $script:Keys.Count -gt 0) { return $script:Keys.Dequeue() }
    if ($script:Scripted) { return 'esc' }

    # A redirected stdin has no keyboard behind it. Bow out rather than throw.
    try {
        if ($NonBlocking -and -not [Console]::KeyAvailable) { return $null }
        $k = [Console]::ReadKey($true)
    } catch {
        return 'esc'
    }
    switch ($k.Key) {
        'UpArrow'    { return 'up' }
        'DownArrow'  { return 'down' }
        'LeftArrow'  { return 'left' }
        'RightArrow' { return 'right' }
        'Enter'      { return 'enter' }
        'Escape'     { return 'esc' }
        'Backspace'  { return 'backspace' }
        'Spacebar'   { return 'space' }
    }
    if ($k.KeyChar) { return ([string]$k.KeyChar).ToLower() }
    return $null
}

function Invoke-Beat {
    param([int]$Ms = 90)
    if (-not $script:Scripted) { Start-Sleep -Milliseconds $Ms }
}

function Push-Log {
    param([string]$Text, [string]$Color = 'gray')
    [void]$script:Log.Add(@{ Text = $Text; Color = $Color })
    while ($script:Log.Count -gt 4) { $script:Log.RemoveAt(0) }
}

# --- text helpers ----------------------------------------------------

function Split-Wrap {
    param([string]$Text, [int]$Width = 72)
    $out = @()
    $line = ''
    foreach ($word in ($Text -split '\s+')) {
        if (-not $word) { continue }
        if ($line -eq '') { $line = $word }
        elseif (($line.Length + 1 + $word.Length) -le $Width) { $line += ' ' + $word }
        else { $out += $line; $line = $word }
    }
    if ($line -ne '') { $out += $line }
    if ($out.Count -eq 0) { $out = @('') }
    return $out
}

# Turns `inline code` into cyan segments inside a normal line.
function Convert-Inline {
    param([string]$Text, [string]$Base = 'gray', [int]$Indent = 3)
    $segs = @(, @((' ' * $Indent), 'dim'))
    foreach ($part in [regex]::Split($Text, '(`[^`]*`)')) {
        if ($part -match '^`(.*)`$') { $segs += , @($Matches[1], 'cyan') }
        elseif ($part)               { $segs += , @(($part -replace '\*\*', ''), $Base) }
    }
    return $segs
}

# Renders a brief.md into frame rows, ready to paginate.
function Get-BriefRows {
    param([string]$Path)

    $rows   = @()
    $inCode = $false
    $para   = @()

    # Markdown is hard-wrapped in the source; re-flow each paragraph so it
    # fits this screen instead of splitting every source line in half.
    foreach ($line in (Get-Content $Path)) {

        $isPlain = ($line -notmatch '^\s*```') -and (-not $inCode) -and
                   ($line -notmatch '^#{1,3} ') -and ($line -notmatch '^\s*[-*] ') -and
                   ($line -notmatch '^\s*\d+\. ') -and ($line -notmatch '^\s*>') -and
                   ($line -notmatch '^\s*\|') -and ($line -notmatch '^\s*$')

        if ($isPlain) { $para += $line.Trim(); continue }

        if ($para.Count -gt 0) {
            foreach ($w in (Split-Wrap ($para -join ' ') 72)) { $rows += , (Convert-Inline $w 'gray' 2) }
            $para = @()
        }

        if ($line -match '^\s*```') { $inCode = -not $inCode; $rows += , @(, @('', 'dim')); continue }
        if ($inCode)                { $rows += , @(, @(('      ' + $line), 'cyan')); continue }

        switch -Regex ($line) {
            '^# (.*)' {
                $rows += , @(, @('', 'dim'))
                $rows += , @(, @(('  ' + $Matches[1]), 'yellow'))
                $rows += , @(, @(('  ' + ('=' * [Math]::Min(70, $Matches[1].Length))), 'deep'))
                break
            }
            '^## (.*)'  { $rows += , @(, @('', 'dim')); $rows += , @(, @(('  ' + $Matches[1]), 'orange')); break }
            '^### (.*)' { $rows += , @(, @(('  ' + $Matches[1]), 'gold')); break }
            '^\s*[-*] (.*)' {
                foreach ($w in (Split-Wrap $Matches[1] 68)) { $rows += , (Convert-Inline $w 'gray' 5) }
                break
            }
            '^\s*(\d+)\. (.*)' {
                $first = $true
                foreach ($w in (Split-Wrap $Matches[2] 66)) {
                    $pre = if ($first) { '   ' + $Matches[1] + '. ' } else { '      ' }
                    $rows += , ((, @($pre, 'deep')) + (Convert-Inline $w 'gray' 0))
                    $first = $false
                }
                break
            }
            '^\s*>(.*)' {
                foreach ($w in (Split-Wrap $Matches[1] 68)) { $rows += , (Convert-Inline $w 'dim' 5) }
                break
            }
            '^\s*\|' { $rows += , @(, @(('  ' + $line), 'blue')); break }
            '^\s*$'  { $rows += , @(, @('', 'dim')); break }
            default  { foreach ($w in (Split-Wrap $line 72)) { $rows += , (Convert-Inline $w 'gray' 2) } }
        }
    }

    # a file that ends mid-paragraph still has to print it
    if ($para.Count -gt 0) {
        foreach ($w in (Split-Wrap ($para -join ' ') 72)) { $rows += , (Convert-Inline $w 'gray' 2) }
    }

    return , @($rows)
}

# --- shared chrome ---------------------------------------------------

function Add-StatusBar {
    param($Progress)
    $xp    = [int]$Progress.xp
    $total = Get-TotalXp
    $segs  = @(@('  ', 'dim'), @((Get-Rank $xp).PadRight(18), 'yellow'))
    $segs += New-Bar -Value $xp -Max $total -Width 24 -FullColor 'green'
    $segs += , @(" $xp / $total xp", 'dim')
    Add-Row $segs
}

function Add-Keys {
    param([object[]]$Pairs)
    $segs = @(, @('  ', 'dim'))
    foreach ($p in $Pairs) {
        $segs += , @("[$($p[0])] ", 'yellow')
        $segs += , @("$($p[1])   ", 'dim')
    }
    Add-Row $segs
}

# --- title -----------------------------------------------------------

$script:TitleArt = @(
    '#####  ###  #   # ##### #### ',
    '  #   #   # #   # #     #   #',
    '  #   #   # # # # ####  #### ',
    '  #   #   # ## ## #     #  # ',
    '  #    ###  #   # ##### #   #'
)

function Show-Title {
    $p = Get-Progress

    Reset-Frame
    Add-Blank 3
    for ($i = 0; $i -lt $script:TitleArt.Count; $i++) {
        $c = if ($i -eq 2) { 'cyan' } else { 'deep' }
        Add-Center $script:TitleArt[$i] $c
    }
    Add-Blank 1
    Add-Center 'o f   T U R I N G' 'yellow'
    Add-Blank 2
    Add-Center 'learn C++ by building a game, one floor at a time' 'dim'
    Add-Blank 3

    if ($p.hero) {
        Add-Center ('welcome back, ' + $p.hero) 'gray'
        Add-Blank 1
        Add-Center ((@($p.completed).Count).ToString() + ' of 25 floors cleared') 'dim'
    } else {
        Add-Center 'a tower, twenty-five floors, and a game at the top' 'gray'
    }
    Add-Blank 3
    Add-Center 'press any key' 'yellow'
    Show-Frame

    [void](Read-GameKey)

    if (-not $p.hero) { Invoke-NamePrompt }
    $script:State = 'tower'

    # start wherever the climb left off
    $levels = Get-Levels
    $cur = Get-CurrentLevel
    if ($cur) {
        for ($i = 0; $i -lt $levels.Count; $i++) {
            if ($levels[$i].Slug -eq $cur.Slug) { $script:Sel = $i; break }
        }
    } else {
        $script:Sel = $levels.Count - 1
    }
}

function Invoke-NamePrompt {
    $name = ''
    while ($true) {
        Reset-Frame
        Add-Blank 6
        Add-Center 'The tower asks for a name.' 'gray'
        Add-Blank 2
        Add-Center ('> ' + $name + '_') 'cyan'
        Add-Blank 2
        Add-Center 'type it, then press enter' 'dim'
        Show-Frame

        $k = Read-GameKey
        if ($k -eq 'enter') { break }
        elseif ($k -eq 'backspace') { if ($name.Length -gt 0) { $name = $name.Substring(0, $name.Length - 1) } }
        elseif ($k -eq 'space') { if ($name.Length -lt 16) { $name += ' ' } }
        elseif ($k -and $k.Length -eq 1 -and $name.Length -lt 16) { $name += $k }
        if ($script:Scripted) { break }
    }

    if (-not $name.Trim()) { $name = 'apprentice' }
    $p = Get-Progress
    $p.hero = $name.Trim()
    Save-Progress $p
}

# --- the tower -------------------------------------------------------

$script:ActRoman = @('I', 'II', 'III', 'IV', 'V', 'VI')

function Get-ActGroups {
    $groups = New-Object System.Collections.ArrayList
    $act = $null
    foreach ($l in (Get-Levels)) {
        if ($l.Act -ne $act) {
            $act = $l.Act
            [void]$groups.Add(@{ Act = $act; Levels = (New-Object System.Collections.ArrayList) })
        }
        [void]$groups[$groups.Count - 1].Levels.Add($l)
    }
    return $groups
}

function Test-Unlocked {
    param($Index)
    $levels = Get-Levels
    $p = Get-Progress
    if (Test-LevelDone $p $levels[$Index]) { return $true }
    for ($i = 0; $i -lt $Index; $i++) {
        if (-not (Test-LevelDone $p $levels[$i])) { return $false }
    }
    return $true
}

function Invoke-Tower {
    $levels = Get-Levels
    $groups = Get-ActGroups

    while ($script:State -eq 'tower') {
        $p   = Get-Progress
        $sel = $levels[$script:Sel]

        Reset-Frame
        Add-Blank 1
        Add-Center 'T H E   T O W E R' 'cyan'
        Add-Blank 1
        Add-StatusBar $p
        Add-Blank 1

        # top floor first, so it reads like a tower
        for ($g = $groups.Count - 1; $g -ge 0; $g--) {
            $group = $groups[$g]
            $segs  = @(, @(('   ' + $script:ActRoman[$g].PadLeft(3) + ' |  '), 'deep'))

            foreach ($l in $group.Levels) {
                $idx      = [array]::IndexOf($levels, $l)
                $done     = Test-LevelDone $p $l
                $unlocked = Test-Unlocked $idx
                $isSel    = ($idx -eq $script:Sel)
                $num      = '{0:00}' -f $l.Number

                if ($isSel)         { $segs += , @(('{' + $num + '}'), 'yellow') }
                elseif ($done)      { $segs += , @(('[' + $num + ']'), 'green') }
                elseif ($unlocked)  { $segs += , @(('[' + $num + ']'), 'orange') }
                else                { $segs += , @(('[' + $num + ']'), 'dim') }

                $segs += , @(' ', 'dim')
            }

            $label = ($group.Act -replace '^ACT [IVX]+ - ', '')
            $pad   = 34 - (($group.Levels.Count) * 5)
            $tail  = (' ' * [Math]::Max(1, $pad)) + $label
            $segs += , @($tail, 'dim')
            Add-Row $segs
            Add-Text '       |' 'deep'
        }

        Add-Text ('    ===+' + ('=' * 62)) 'deep'
        Add-Blank 1

        # what is under the cursor
        $done     = Test-LevelDone $p $sel
        $unlocked = Test-Unlocked $script:Sel
        $mark     = if ($done) { 'cleared' } elseif ($unlocked) { 'open' } else { 'sealed' }
        $markCol  = if ($done) { 'green' } elseif ($unlocked) { 'yellow' } else { 'red' }

        $selNum = '{0:00}' -f $sel.Number
        Add-Row @(
            @("   floor $selNum  ", 'dim'),
            @($sel.Title, 'white'),
            @("   $mark", $markCol),
            @($(if ($sel.Boss) { '   * BOSS *' } else { '' }), 'magenta')
        )
        Add-Text $sel.Tagline 'dim' 3
        Add-Blank 1
        Add-Text ('   teaches: ' + ($sel.Concepts -join ', ')) 'deep'
        Add-Blank 1
        Add-Rule 'deep'
        Add-Keys @(@('WASD', 'walk'), @('ENTER', 'go in'), @('Q', 'leave the tower'))
        Show-Frame

        $k = Read-GameKey
        switch ($k) {
            { $_ -in 'left', 'a' }  { if ($script:Sel -gt 0) { $script:Sel-- } }
            { $_ -in 'right', 'd' } { if ($script:Sel -lt $levels.Count - 1) { $script:Sel++ } }
            { $_ -in 'up', 'w' }    { $script:Sel = [Math]::Min($levels.Count - 1, $script:Sel + 4) }
            { $_ -in 'down', 's' }  { $script:Sel = [Math]::Max(0, $script:Sel - 4) }
            { $_ -in 'enter', 'e' } {
                if ($unlocked) { $script:State = 'lesson' }
                else { Show-Sealed $sel }
            }
            { $_ -in 'q', 'esc' }   { $script:State = 'quit' }
        }
    }
}

function Show-Sealed {
    param($Level)
    Reset-Frame
    Add-Blank 8
    Add-Center 'The door will not open.' 'red'
    Add-Blank 1
    Add-Center 'Clear the floors below it first.' 'dim'
    Add-Blank 2
    Add-Center 'press any key' 'yellow'
    Show-Frame
    [void](Read-GameKey)
}

# --- the lesson ------------------------------------------------------

function Invoke-Lesson {
    $levels = Get-Levels
    $level  = $levels[$script:Sel]
    $rows   = Get-BriefRows (Join-Path $level.Dir 'brief.md')

    $perPage = 21
    $pages   = [Math]::Max(1, [int][Math]::Ceiling($rows.Count / $perPage))
    $page    = 0

    while ($script:State -eq 'lesson') {
        Reset-Frame
        $num = '{0:00}' -f $level.Number
        $pos = $page + 1
        Add-Row @(
            @("  floor $num  ", 'deep'),
            @($level.Title, 'cyan'),
            @("     page $pos of $pages", 'dim')
        )
        Add-Rule 'deep'

        $start = $page * $perPage
        $end   = [Math]::Min($rows.Count - 1, $start + $perPage - 1)
        if ($start -le $end) {
            for ($i = $start; $i -le $end; $i++) { Add-Row $rows[$i] }
        }
        while ($script:Rows.Count -lt 25) { Add-Blank 1 }

        Add-Rule 'deep'
        if ($page -lt $pages - 1) {
            Add-Keys @(@('SPACE', 'read on'), @('B', 'back a page'), @('T', 'to the trial'), @('ESC', 'the tower'))
        } else {
            Add-Keys @(@('ENTER', 'face the trial'), @('B', 'back a page'), @('ESC', 'the tower'))
        }
        Show-Frame

        $k = Read-GameKey
        switch ($k) {
            { $_ -in 'space', 'right', 'd', 'down' } {
                if ($page -lt $pages - 1) { $page++ } else { $script:State = 'trial' }
            }
            { $_ -in 'b', 'left', 'a', 'up' } { if ($page -gt 0) { $page-- } }
            { $_ -in 'enter', 't' }           { $script:State = 'trial' }
            'esc'                             { $script:State = 'tower' }
        }
    }
}

# --- trials, run silently -------------------------------------------

function Get-TrialResult {
    param($Level, [string]$WorkDir)

    $result = @{
        Built = $false; BuildOutput = ''; RuleIssues = @()
        Cases = @(); Passed = 0; Total = 0; AllPass = $false
    }

    $build = Build-Project -SourceDir $WorkDir -ExeName 'game'
    $result.BuildOutput = $build.Output
    if (-not $build.Ok) { return $result }
    $result.Built = $true

    # Test-SourceRules already hands back a real array; wrapping it in @()
    # again would turn "no issues" into one empty issue.
    $result.RuleIssues = Test-SourceRules -Level $Level -WorkDir $WorkDir

    $testDir = Join-Path $Level.Dir 'tests'
    $cases   = @(Get-ChildItem $testDir -Filter '*.in' -File -ErrorAction SilentlyContinue | Sort-Object Name)
    $result.Total = $cases.Count

    foreach ($case in $cases) {
        $name  = $case.BaseName
        $stdin = Get-Content $case.FullName -Raw -ErrorAction SilentlyContinue
        if ($null -eq $stdin) { $stdin = '' }

        $expected  = ConvertTo-Comparable (Get-Content (Join-Path $testDir "$name.out") -Raw)
        $titleFile = Join-Path $testDir "$name.title"
        $label     = if (Test-Path $titleFile) { (Get-Content $titleFile -Raw).Trim() } else { "trial $name" }

        Reset-RunArtifacts -Dir $WorkDir
        $res    = Invoke-Program -Exe $build.Exe -StdIn $stdin -WorkDir $WorkDir
        $actual = ConvertTo-Comparable $res.StdOut

        $pass = (-not $res.TimedOut) -and ($actual.Count -eq $expected.Count)
        if ($pass) {
            for ($i = 0; $i -lt $actual.Count; $i++) {
                if ($actual[$i] -cne $expected[$i]) { $pass = $false; break }
            }
        }
        if ($pass) { $result.Passed++ }

        $result.Cases += @{
            Label = $label; Pass = $pass; TimedOut = $res.TimedOut
            Expected = $expected; Actual = $actual
        }
    }

    $result.AllPass = ($result.Built -and $result.RuleIssues.Count -eq 0 -and
                       $result.Total -gt 0 -and $result.Passed -eq $result.Total)
    return $result
}

function Get-WorkStamp {
    param([string]$Dir)
    if (-not (Test-Path $Dir)) { return 0 }
    $files = Get-ChildItem $Dir -File -Recurse -ErrorAction SilentlyContinue |
             Where-Object { $_.Extension -in '.cpp', '.h', '.hpp' -and $_.FullName -notmatch '\\\.build\\' }
    $sum = 0
    foreach ($f in $files) { $sum += $f.LastWriteTimeUtc.Ticks }
    return $sum
}

function Open-Editor {
    param([string]$Dir)
    if (-not (Get-Command code -ErrorAction SilentlyContinue)) { return $false }
    $main = Get-ChildItem $Dir -Filter *.cpp -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $main) { return $false }
    try {
        Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', 'code', "`"$($main.FullName)`"" `
                      -WindowStyle Hidden -ErrorAction SilentlyContinue
        return $true
    } catch { return $false }
}

# --- guardians -------------------------------------------------------

$script:Sentinel = @(
    '     .-----.  ',
    '    / o   o \ ',
    '   |    -    |',
    '    \  ===  / ',
    '     "-----"  '
)

$script:Warden = @(
    '   \  /^\  /  ',
    '   <\_| |_/>  ',
    '    | o o |   ',
    '   _|  V  |_  ',
    '  /_|_____|_\ '
)

function Get-Guardian {
    param($Level)
    if ($Level.Boss) { return @{ Art = $script:Warden; Name = 'THE WARDEN'; Color = 'magenta' } }
    return @{ Art = $script:Sentinel; Name = 'THE SENTINEL'; Color = 'blue' }
}

# --- the trial arena -------------------------------------------------

function Get-FirstError {
    param([string]$Text)
    foreach ($l in ($Text -split "`r?`n")) {
        if ($l -match 'error') { return $l.Trim() }
    }
    $first = ($Text -split "`r?`n") | Where-Object { $_.Trim() } | Select-Object -First 1
    return [string]$first
}

function Get-FirstDiff {
    param($Case)
    $exp = $Case.Expected
    $act = $Case.Actual
    $max = [Math]::Max($exp.Count, $act.Count)
    for ($i = 0; $i -lt $max; $i++) {
        $a = if ($i -lt $act.Count) { $act[$i] } else { $null }
        $e = if ($i -lt $exp.Count) { $exp[$i] } else { $null }
        if ($a -cne $e) {
            return @{
                Line  = $i + 1
                Yours = if ($null -eq $a) { '(nothing)' } else { $a }
                Wants = if ($null -eq $e) { '(nothing)' } else { $e }
            }
        }
    }
    return $null
}

function Add-Clip {
    param([string]$Prefix, [string]$Text, [string]$Color, [int]$Width = 58)
    $t = [string]$Text
    if ($t.Length -gt $Width) { $t = $t.Substring(0, $Width - 3) + '...' }
    Add-Row @(@("   $Prefix", 'dim'), @($t, $Color))
}

function Show-TrialFrame {
    param($Level, [string]$Work, $Result, [string]$Busy, [int]$Flash = 0)

    $g = Get-Guardian $Level
    Reset-Frame
    Add-Blank 1
    $num = '{0:00}' -f $Level.Number
    Add-Row @(
        @("  floor $num  ", 'deep'),
        @($Level.Title, 'cyan'),
        @($(if ($Level.Boss) { '        * BOSS FLOOR *' } else { '' }), 'magenta')
    )
    Add-Rule 'deep'
    Add-Blank 1

    $total  = if ($Result) { $Result.Total } else { 0 }
    $passed = if ($Result) { $Result.Passed } else { 0 }
    $left   = [Math]::Max(0, $total - $passed)
    $artCol = if ($Flash -gt 0) { 'red' } else { $g.Color }

    $info = @(
        @(, @($g.Name, $artCol)),
        @(),
        @(),
        @(),
        @(, @('it falls when every trial passes', 'dim'))
    )
    if ($Result -and $Result.Built -and $total -gt 0) {
        $hp = @(, @('hp ', 'dim'))
        $hp += New-Bar -Value $left -Max $total -Width 16 -FullColor $(if ($left -gt 0) { 'red' } else { 'green' })
        $hp += , @(" $left / $total", 'gray')
        $info[2] = $hp
    } elseif ($Result -and -not $Result.Built) {
        $info[2] = @(@('hp ', 'dim'), @('[################]', 'dim'), @('  SHIELDED', 'orange'))
    } else {
        $info[2] = @(, @('hp  ....', 'dim'))
    }

    for ($i = 0; $i -lt 5; $i++) {
        $segs = @(, @("  $($g.Art[$i])   ", $artCol))
        if ($info[$i]) { $segs += $info[$i] }
        Add-Row $segs
    }

    Add-Blank 1
    Add-Rule 'deep'

    if ($Result -and $Result.Built -and $Result.RuleIssues.Count -gt 0) {
        Add-Text 'the runes are the wrong shape:' 'orange' 3
        foreach ($issue in $Result.RuleIssues) { Add-Clip '  ! ' $issue 'orange' }
    } elseif ($Result -and $Result.Built) {
        foreach ($c in $Result.Cases) {
            if ($c.Pass) { Add-Row @(@('   [x] ', 'green'), @($c.Label, 'dim')) }
            else         { Add-Row @(@('   [ ] ', 'red'),   @($c.Label, 'gray')) }
        }
    } else {
        Add-Text 'it will not even compile yet.' 'red' 3
    }

    while ($script:Rows.Count -lt 21) { Add-Blank 1 }
    Add-Rule 'deep'

    foreach ($entry in $script:Log) { Add-Clip '> ' $entry.Text $entry.Color 62 }
    while ($script:Rows.Count -lt 27) { Add-Blank 1 }

    Add-Rule 'deep'
    if ($Busy) {
        Add-Text $Busy 'yellow' 2
    } else {
        Add-Row @(@('  watching ', 'dim'), @(('workspace\' + $Level.Slug), 'cyan'), @('  - save the file to strike', 'dim'))
    }
    Add-Keys @(@('E', 'editor'), @('R', 'retry'), @('H', 'hint'), @('B', 'brief'), @('L', 'answer'), @('ESC', 'flee'))
    Show-Frame
}

function Invoke-Trial {
    $levels = Get-Levels
    $level  = $levels[$script:Sel]
    $work   = Get-WorkDir $level

    if (-not (Test-Path $work)) {
        New-Item -ItemType Directory -Force -Path $work | Out-Null
        Copy-Item (Join-Path $level.Dir 'start\*') -Destination $work -Recurse -Force
    }

    $script:Log = New-Object System.Collections.ArrayList
    Push-Log 'the door seals behind you.' 'dim'
    if (Open-Editor $work) { Push-Log 'your editor opens the file. write, then save.' 'cyan' }

    $stamp      = Get-WorkStamp $work
    $result     = $null
    $needRun    = $true
    $prevPassed = -1
    $guard      = 0
    $dirty      = $true

    while ($script:State -eq 'trial') {

        if ($needRun) {
            $dirty = $true
            Show-TrialFrame $level $work $result 'the runes glow. testing...'
            $result  = Get-TrialResult $level $work
            $needRun = $false

            if (-not $result.Built) {
                Push-Log ('it rejects you: ' + (Get-FirstError $result.BuildOutput)) 'red'
            } elseif ($result.RuleIssues.Count -gt 0) {
                Push-Log 'it compiles, but the shape is wrong.' 'orange'
            } else {
                if ($prevPassed -ge 0 -and $result.Passed -gt $prevPassed) {
                    $hit = $result.Passed - $prevPassed
                    Push-Log ('a hit! ' + $hit + ' more trial(s) pass.') 'lime'
                    Show-TrialFrame $level $work $result 'STRUCK' 1
                    Invoke-Beat 220
                } elseif ($prevPassed -gt $result.Passed) {
                    Push-Log 'it recovers - something that passed now fails.' 'orange'
                }

                if ($result.AllPass) {
                    Push-Log 'every trial passes. the guardian breaks apart.' 'lime'
                    Show-TrialFrame $level $work $result 'THE GUARDIAN FALLS'
                    Invoke-Beat 500
                    $script:State = 'victory'
                    break
                }

                $failing = @($result.Cases | Where-Object { -not $_.Pass })
                if ($failing.Count -gt 0) {
                    $d = Get-FirstDiff $failing[0]
                    if ($failing[0].TimedOut) {
                        Push-Log 'your program never stopped. an endless loop?' 'red'
                    } elseif ($d) {
                        Push-Log ('line ' + $d.Line + ' yours: ' + $d.Yours) 'red'
                        Push-Log ('line ' + $d.Line + ' wants: ' + $d.Wants) 'green'
                    }
                }
            }
            $prevPassed = $result.Passed
        }

        if ($dirty) {
            Show-TrialFrame $level $work $result $null
            $dirty = $false
        }

        $k = Read-GameKey -NonBlocking
        if ($k) { $dirty = $true }
        switch ($k) {
            'e'   { if (Open-Editor $work) { Push-Log 'editor opened.' 'dim' } else { Push-Log 'no editor found.' 'orange' } }
            'r'   { $needRun = $true; Push-Log 'you strike again.' 'dim' }
            'h'   { Show-Hints $level }
            'b'   { Show-Brief-Overlay $level }
            'l'   { Show-Answer $level }
            'esc' { $script:State = 'lesson' }
            'q'   { $script:State = 'lesson' }
        }

        $now = Get-WorkStamp $work
        if ($now -ne $stamp) {
            $stamp   = $now
            $needRun = $true
            Push-Log 'you saved. the runes shift.' 'cyan'
        }

        if (-not $k) { Invoke-Beat 130 }

        if ($script:Scripted) {
            $guard++
            if ($guard -gt 2) { $script:State = 'tower'; break }
        }
    }
}

# --- overlays --------------------------------------------------------

function Show-Hints {
    param($Level)

    $statePath = Join-Path $GameRoot ('.state\hints-' + $Level.Slug + '.txt')
    $shown = if (Test-Path $statePath) { [int]((Get-Content $statePath -Raw).Trim()) } else { 0 }
    if ($shown -lt $Level.Hints.Count) {
        $shown++
        Set-Content $statePath ([string]$shown)
    }

    while ($true) {
        Reset-Frame
        Add-Blank 1
        Add-Center 'W H I S P E R S' 'gold'
        Add-Rule 'deep'
        Add-Blank 1

        if ($Level.Hints.Count -eq 0) {
            Add-Text 'this floor keeps its own counsel.' 'dim' 3
        }
        for ($i = 0; $i -lt $shown -and $i -lt $Level.Hints.Count; $i++) {
            $n = $i + 1
            $first = $true
            foreach ($w in (Split-Wrap $Level.Hints[$i] 66)) {
                if ($first) {
                    Add-Row ((, @("   $n. ", 'gold')) + (Convert-Inline $w 'gray' 0))
                    $first = $false
                } else {
                    Add-Row (Convert-Inline $w 'gray' 6)
                }
            }
            Add-Blank 1
        }

        while ($script:Rows.Count -lt 26) { Add-Blank 1 }
        Add-Rule 'deep'
        if ($shown -lt $Level.Hints.Count) {
            Add-Keys @(@('H', 'one more whisper'), @('ESC', 'back to the fight'))
        } else {
            Add-Text ('that is every hint on this floor.') 'dim' 2
            Add-Keys @(@('ESC', 'back to the fight'))
        }
        Show-Frame

        $k = Read-GameKey
        if ($k -eq 'h' -and $shown -lt $Level.Hints.Count) {
            $shown++
            Set-Content $statePath ([string]$shown)
        } elseif ($k -in 'esc', 'enter', 'space', 'q', $null) {
            break
        }
        if ($script:Scripted) { break }
    }
}

function Show-Brief-Overlay {
    param($Level)

    $rows    = Get-BriefRows (Join-Path $Level.Dir 'brief.md')
    $perPage = 22
    $pages   = [Math]::Max(1, [int][Math]::Ceiling($rows.Count / $perPage))
    $page    = 0

    while ($true) {
        Reset-Frame
        $pos = $page + 1
        Add-Row @(@('  the lesson  ', 'deep'), @($Level.Title, 'cyan'),
                  @("    page $pos of $pages", 'dim'))
        Add-Rule 'deep'

        $start = $page * $perPage
        $end   = [Math]::Min($rows.Count - 1, $start + $perPage - 1)
        if ($start -le $end) { for ($i = $start; $i -le $end; $i++) { Add-Row $rows[$i] } }
        while ($script:Rows.Count -lt 27) { Add-Blank 1 }

        Add-Rule 'deep'
        Add-Keys @(@('SPACE', 'next page'), @('B', 'back'), @('ESC', 'to the fight'))
        Show-Frame

        $k = Read-GameKey
        if ($k -in 'space', 'right', 'd', 'enter') { if ($page -lt $pages - 1) { $page++ } else { break } }
        elseif ($k -in 'b', 'left', 'a')           { if ($page -gt 0) { $page-- } }
        elseif ($k -in 'esc', 'q')                 { break }
        if ($script:Scripted) { break }
    }
}

function Show-Answer {
    param($Level)

    Reset-Frame
    Add-Blank 8
    Add-Center 'Reading the answer is allowed.' 'gray'
    Add-Blank 1
    Add-Center 'But retype it. Do not paste it.' 'orange'
    Add-Blank 2
    Add-Center 'press Y to see it, anything else to go back' 'dim'
    Show-Frame
    if ((Read-GameKey) -ne 'y') { return }

    $lines = @()
    foreach ($f in (Get-ChildItem (Join-Path $Level.Dir 'solution') -File | Sort-Object Name)) {
        $lines += @{ T = '--- ' + $f.Name + ' ---'; C = 'orange' }
        foreach ($l in (Get-Content $f.FullName)) { $lines += @{ T = '  ' + $l; C = 'cyan' } }
        $lines += @{ T = ''; C = 'dim' }
    }

    $perPage = 24
    $pages   = [Math]::Max(1, [int][Math]::Ceiling($lines.Count / $perPage))
    $page    = 0

    while ($true) {
        Reset-Frame
        $pos = $page + 1
        Add-Row @(@('  the answer  ', 'deep'), @($Level.Title, 'cyan'),
                  @("    page $pos of $pages", 'dim'))
        Add-Rule 'deep'
        $start = $page * $perPage
        $end   = [Math]::Min($lines.Count - 1, $start + $perPage - 1)
        if ($start -le $end) { for ($i = $start; $i -le $end; $i++) { Add-Text $lines[$i].T $lines[$i].C 2 } }
        while ($script:Rows.Count -lt 28) { Add-Blank 1 }
        Add-Keys @(@('SPACE', 'next page'), @('ESC', 'back'))
        Show-Frame

        $k = Read-GameKey
        if ($k -in 'space', 'right', 'd', 'enter') { if ($page -lt $pages - 1) { $page++ } else { break } }
        elseif ($k -in 'esc', 'q', 'b')            { break }
        if ($script:Scripted) { break }
    }
}

# --- victory ---------------------------------------------------------

function Invoke-Victory {
    $levels = Get-Levels
    $level  = $levels[$script:Sel]

    $p       = Get-Progress
    $first   = -not (Test-LevelDone $p $level)
    $oldXp   = [int]$p.xp
    $oldRank = Get-Rank $oldXp

    if ($first) {
        $p.completed = @($p.completed) + $level.Slug
        $p.xp = $oldXp + $level.Xp
        Save-Progress $p
    }

    $newXp   = [int](Get-Progress).xp
    $newRank = Get-Rank $newXp
    $total   = Get-TotalXp

    # count the xp up, so it feels like it was earned
    $steps = if ($script:Scripted -or -not $first) { 1 } else { 12 }
    for ($s = 1; $s -le $steps; $s++) {
        $shown = $oldXp + [int](($newXp - $oldXp) * ($s / $steps))

        Reset-Frame
        Add-Blank 2
        if ($level.Boss) {
            Add-Center '*  B O S S   F L O O R   C L E A R E D  *' 'magenta'
        } else {
            Add-Center 'F L O O R   C L E A R E D' 'lime'
        }
        Add-Blank 1
        Add-Center $level.Title 'white'
        Add-Blank 2
        for ($i = 0; $i -lt 5; $i++) { Add-Center (Get-Guardian $level).Art[$i] 'dim' }
        Add-Blank 2

        if ($first) { Add-Center ('+ ' + $level.Xp + ' xp') 'green' }
        else        { Add-Center 'already cleared - no xp this time' 'dim' }

        Add-Blank 1
        $bar = @(, @('   ', 'dim'))
        $bar += New-Bar -Value $shown -Max $total -Width 40 -FullColor 'green'
        $bar += , @(" $shown / $total", 'dim')
        Add-Row $bar
        Add-Blank 1
        Add-Center $newRank 'yellow'
        Add-Blank 1

        if ($first -and $newRank -ne $oldRank -and $s -eq $steps) {
            Add-Center ('you are no longer a ' + $oldRank) 'dim'
            Add-Center ('YOU ARE NOW A ' + $newRank.ToUpper()) 'gold'
        } else {
            Add-Blank 2
        }

        while ($script:Rows.Count -lt 28) { Add-Blank 1 }
        if ($s -eq $steps) { Add-Center 'press any key' 'yellow' }
        Show-Frame
        if ($s -lt $steps) { Invoke-Beat 55 }
    }

    [void](Read-GameKey)

    $next = Get-CurrentLevel
    if ($null -eq $next) { $script:State = 'ending'; return }

    for ($i = 0; $i -lt $levels.Count; $i++) {
        if ($levels[$i].Slug -eq $next.Slug) { $script:Sel = $i; break }
    }
    $script:State = 'tower'
}

function Invoke-Ending {
    Reset-Frame
    Add-Blank 2
    Add-Center 'You are standing on the roof of the tower.' 'gray'
    Add-Blank 2
    Add-Center 'T H E   C L I M B   I S   D O N E' 'gold'
    Add-Blank 2
    Add-Center 'Twenty-five floors. Every one of them compiled.' 'dim'
    Add-Blank 1
    Add-Center 'In workspace\25-the-last-door there is a game' 'gray'
    Add-Center 'with a dungeon, monsters, loot, a locked door' 'gray'
    Add-Center 'and a save file. You wrote all of it.' 'gray'
    Add-Blank 2
    Add-Center 'Now open an empty folder and build the next one.' 'cyan'
    Add-Blank 3
    Add-Center 'press any key' 'yellow'
    Show-Frame
    [void](Read-GameKey)
    $script:State = 'tower'
}

# --- entry point -----------------------------------------------------

function Start-Adventure {
    param([string]$ScriptedKeys)

    if ($ScriptedKeys) {
        $script:Keys = [System.Collections.Queue]::new()
        foreach ($tok in ($ScriptedKeys -split ',')) {
            if ($tok.Trim()) { $script:Keys.Enqueue($tok.Trim()) }
        }
        Initialize-Screen -Scripted
    } else {
        Initialize-Screen
        Clear-Screen
    }

    if (-not (Initialize-Toolchain)) { Show-NoCompiler; return }

    try {
        while ($script:State -ne 'quit') {
            switch ($script:State) {
                'title'   { Show-Title }
                'tower'   { Invoke-Tower }
                'lesson'  { Invoke-Lesson }
                'trial'   { Invoke-Trial }
                'victory' { Invoke-Victory }
                'ending'  { Invoke-Ending }
                default   { $script:State = 'quit' }
            }
            if ($script:Scripted -and $script:Keys.Count -eq 0) { break }
        }
    } finally {
        Restore-Screen
    }

    if (-not $script:Scripted) {
        Clear-Screen
        $p = Get-Progress
        Write-Host ''
        Write-Host ('  The tower waits. ' + (@($p.completed).Count) + ' of 25 floors cleared.') -ForegroundColor DarkGray
        Write-Host '  Come back with .\play.cmd' -ForegroundColor Cyan
        Write-Host ''
    }
}

function Show-NoCompiler {
    Reset-Frame
    Add-Blank 4
    Add-Center 'No C++ compiler found on this machine.' 'red'
    Add-Blank 2
    Add-Center 'This game compiles the code you write, so it needs one.' 'gray'
    Add-Blank 2
    Add-Center 'winget install Microsoft.VisualStudio.2022.Community' 'cyan'
    Add-Center 'then tick "Desktop development with C++"' 'dim'
    Add-Blank 1
    Add-Center 'or' 'dim'
    Add-Blank 1
    Add-Center 'winget install MSYS2.MSYS2' 'cyan'
    Add-Center 'pacman -S mingw-w64-ucrt-x86_64-gcc' 'dim'
    Add-Blank 3
    Add-Center 'press any key' 'yellow'
    Show-Frame
    [void](Read-GameKey)
    Restore-Screen
}
