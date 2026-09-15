# ---------------------------------------------------------------
#  Ui.ps1 - everything that draws to the screen.
# ---------------------------------------------------------------

$script:Ranks = @(
    @{ Xp =    0; Name = 'Null Pointer'      }
    @{ Xp =  120; Name = 'Bit Squire'        }
    @{ Xp =  300; Name = 'Byte Knight'       }
    @{ Xp =  560; Name = 'Loop Warden'       }
    @{ Xp =  900; Name = 'Function Adept'    }
    @{ Xp = 1300; Name = 'Struct Artificer'  }
    @{ Xp = 1800; Name = 'Class Sorcerer'    }
    @{ Xp = 2400; Name = 'Pointer Magus'     }
    @{ Xp = 3100; Name = 'Engine Architect'  }
)

function Get-Rank {
    param([int]$Xp)
    $rank = $script:Ranks[0]
    foreach ($r in $script:Ranks) { if ($Xp -ge $r.Xp) { $rank = $r } }
    return $rank.Name
}

function Write-Banner {
    $rows = @(
        '#####  ###  #   # ##### #### ',
        '  #   #   # #   # #     #   #',
        '  #   #   # # # # ####  #### ',
        '  #   #   # ## ## #     #  # ',
        '  #    ###  #   # ##### #   #'
    )
    Write-Host ''
    for ($i = 0; $i -lt $rows.Count; $i++) {
        $shade = if ($i -le 1) { 'DarkCyan' } elseif ($i -eq 2) { 'Cyan' } else { 'DarkCyan' }
        Write-Host ('      ' + $rows[$i]) -NoNewline -ForegroundColor $shade
        if ($i -eq 2) { Write-Host '     of  T U R I N G' -ForegroundColor Yellow } else { Write-Host '' }
    }
    Write-Host ''
    Write-Host '          learn C++ by building a game, one floor at a time' -ForegroundColor DarkGray
    Write-Host ''
}

function Write-Rule {
    param([string]$Text = '', [string]$Color = 'DarkGray')
    $width = 68
    if ($Text) {
        $line = '-- ' + $Text + ' ' + ('-' * [Math]::Max(3, $width - $Text.Length - 4))
    } else {
        $line = '-' * $width
    }
    Write-Host $line -ForegroundColor $Color
}

function Write-XpBar {
    param([int]$Xp, [int]$MaxXp)
    $width = 34
    $ratio = if ($MaxXp -gt 0) { [Math]::Min(1.0, $Xp / $MaxXp) } else { 0 }
    $fill  = [int][Math]::Round($ratio * $width)
    Write-Host '  [' -NoNewline -ForegroundColor DarkGray
    Write-Host ('#' * $fill) -NoNewline -ForegroundColor Green
    Write-Host ('.' * ($width - $fill)) -NoNewline -ForegroundColor DarkGray
    Write-Host '] ' -NoNewline -ForegroundColor DarkGray
    Write-Host "$Xp" -NoNewline -ForegroundColor Green
    Write-Host " / $MaxXp XP" -NoNewline -ForegroundColor DarkGray
    Write-Host "   rank: " -NoNewline -ForegroundColor DarkGray
    Write-Host (Get-Rank $Xp) -ForegroundColor Yellow
}

# A small markdown renderer. The briefs are written in plain markdown so
# they read fine in an editor too, but this makes them pleasant in a shell.
function Show-Markdown {
    param([Parameter(Mandatory)][string]$Path)

    $inCode = $false
    foreach ($line in (Get-Content $Path)) {

        if ($line -match '^\s*```') {
            $inCode = -not $inCode
            Write-Host ''
            continue
        }

        if ($inCode) {
            Write-Host ('      ' + $line) -ForegroundColor Cyan
            continue
        }

        switch -Regex ($line) {
            '^# (.*)'   { Write-Host ''; Write-Rule $Matches[1] 'Cyan'; break }
            '^## (.*)'  { Write-Host ''; Write-Host ("  " + $Matches[1]) -ForegroundColor Yellow; break }
            '^### (.*)' { Write-Host ("  " + $Matches[1]) -ForegroundColor DarkYellow; break }
            '^\s*[-*] (.*)' {
                Write-Host '   * ' -NoNewline -ForegroundColor DarkCyan
                Write-Inline $Matches[1]
                break
            }
            '^\s*(\d+)\. (.*)' {
                Write-Host ("   " + $Matches[1] + '. ') -NoNewline -ForegroundColor DarkCyan
                Write-Inline $Matches[2]
                break
            }
            '^\s*>(.*)' { Write-Host ('   | ' + $Matches[1].Trim()) -ForegroundColor DarkGray; break }
            '^\s*$'     { Write-Host ''; break }
            default     { Write-Host '  ' -NoNewline; Write-Inline $line }
        }
    }
    Write-Host ''
}

# Renders `inline code` in colour inside a normal paragraph line.
function Write-Inline {
    param([string]$Text)
    $parts = [regex]::Split($Text, '(`[^`]*`)')
    foreach ($p in $parts) {
        if ($p -match '^`(.*)`$') {
            Write-Host $Matches[1] -NoNewline -ForegroundColor Cyan
        } else {
            Write-Host ($p -replace '\*\*', '') -NoNewline -ForegroundColor Gray
        }
    }
    Write-Host ''
}

function Write-Ok    { param($m) Write-Host "  [ OK ] " -NoNewline -ForegroundColor Green;   Write-Host $m -ForegroundColor Gray }
function Write-Fail  { param($m) Write-Host "  [FAIL] " -NoNewline -ForegroundColor Red;     Write-Host $m -ForegroundColor Gray }
function Write-Info  { param($m) Write-Host "  [ .. ] " -NoNewline -ForegroundColor DarkCyan;Write-Host $m -ForegroundColor Gray }
function Write-Warn  { param($m) Write-Host "  [ !! ] " -NoNewline -ForegroundColor Yellow;  Write-Host $m -ForegroundColor Gray }

function Show-Diff {
    param([string[]]$Expected, [string[]]$Actual)

    $max = [Math]::Max($Expected.Count, $Actual.Count)

    # On long outputs, show a window around the first difference rather than
    # dumping two hundred lines of identical map at the player.
    $first = 0
    while ($first -lt $max) {
        $a = if ($first -lt $Actual.Count)   { $Actual[$first] }   else { $null }
        $e = if ($first -lt $Expected.Count) { $Expected[$first] } else { $null }
        if ($a -cne $e) { break }
        $first++
    }
    $from = [Math]::Max(0, $first - 3)
    $to   = [Math]::Min($max - 1, $first + 14)

    Write-Host ''
    if ($from -gt 0) { Write-Host "         ... $from earlier lines matched" -ForegroundColor DarkGray }
    Write-Host '         your output                        | expected' -ForegroundColor DarkGray
    Write-Host ('         ' + ('-' * 58)) -ForegroundColor DarkGray
    for ($i = $from; $i -le $to; $i++) {
        $a = if ($i -lt $Actual.Count)   { $Actual[$i] }   else { $null }
        $e = if ($i -lt $Expected.Count) { $Expected[$i] } else { $null }
        $same = ($a -ceq $e)

        $aShow = if ($null -eq $a) { '(nothing)' } else { $a }
        $eShow = if ($null -eq $e) { '(nothing)' } else { $e }
        if ($aShow.Length -gt 36) { $aShow = $aShow.Substring(0,33) + '...' }
        if ($eShow.Length -gt 36) { $eShow = $eShow.Substring(0,33) + '...' }

        $mark  = if ($same) { '  ' } else { '->' }
        $color = if ($same) { 'DarkGray' } else { 'Red' }

        Write-Host ('   ' + $mark + ' ') -NoNewline -ForegroundColor Red
        Write-Host $aShow.PadRight(38) -NoNewline -ForegroundColor $color
        Write-Host '| ' -NoNewline -ForegroundColor DarkGray
        Write-Host $eShow -ForegroundColor $(if ($same) { 'DarkGray' } else { 'Green' })
    }
    if ($to -lt $max - 1) {
        Write-Host ("         ... and " + ($max - 1 - $to) + " more lines") -ForegroundColor DarkGray
    }
    Write-Host ''
    Write-Host "  first difference is on line $($first + 1) of your output." -ForegroundColor DarkCyan
    Write-Host ''
}
