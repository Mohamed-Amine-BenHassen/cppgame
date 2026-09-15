# ---------------------------------------------------------------
#  Screen.ps1 - a tiny flicker-free text renderer.
#
#  Frames are built up as rows of coloured segments, then written to
#  the console in ONE call with the cursor parked at the top-left.
#  Nothing is ever cleared, so nothing ever flashes.
# ---------------------------------------------------------------

$script:ScreenW  = 78
$script:ScreenH  = 30
$script:Rows     = New-Object System.Collections.ArrayList
$script:Scripted = $false
$script:FrameNo  = 0

$script:Ansi = @{
    reset   = "`e[0m"
    dim     = "`e[38;5;242m"
    gray    = "`e[38;5;250m"
    white   = "`e[97m"
    cyan    = "`e[38;5;44m"
    deep    = "`e[38;5;30m"
    blue    = "`e[38;5;68m"
    green   = "`e[38;5;77m"
    lime    = "`e[38;5;155m"
    yellow  = "`e[38;5;221m"
    gold    = "`e[38;5;179m"
    orange  = "`e[38;5;209m"
    red     = "`e[38;5;203m"
    magenta = "`e[38;5;176m"
    purple  = "`e[38;5;141m"
}

function Initialize-Screen {
    param([switch]$Scripted)

    $script:Scripted = [bool]$Scripted
    if ($script:Scripted) { return }

    try {
        $w = [Console]::WindowWidth
        if ($w -lt $script:ScreenW) { $script:ScreenW = [Math]::Max(60, $w - 1) }
        [Console]::CursorVisible = $false
    } catch { }
}

function Restore-Screen {
    if ($script:Scripted) { return }
    try {
        [Console]::CursorVisible = $true
        [Console]::Write($script:Ansi.reset)
    } catch { }
}

# --- building a frame ------------------------------------------------

function Reset-Frame {
    $script:Rows = New-Object System.Collections.ArrayList
}

# A segment is @('text', 'colourname'). A row is an array of segments.
function Add-Row {
    param([object[]]$Segments)
    [void]$script:Rows.Add($Segments)
}

function Add-Blank {
    param([int]$Count = 1)
    for ($i = 0; $i -lt $Count; $i++) { [void]$script:Rows.Add(@()) }
}

function Add-Text {
    param([string]$Text, [string]$Color = 'gray', [int]$Indent = 0)
    $pad = ' ' * $Indent
    Add-Row @(, @("$pad$Text", $Color))
}

function Add-Center {
    param([string]$Text, [string]$Color = 'gray')
    $pad  = [Math]::Max(0, [int](($script:ScreenW - $Text.Length) / 2))
    $line = (' ' * $pad) + $Text
    Add-Row @(, @($line, $Color))
}

function Add-Rule {
    param([string]$Color = 'dim', [string]$Char = '-', [int]$Indent = 2)
    $n = $script:ScreenW - ($Indent * 2)
    Add-Text ($Char * $n) $Color $Indent
}

# --- drawing helpers -------------------------------------------------

function New-Bar {
    param(
        [int]$Value, [int]$Max, [int]$Width = 20,
        [string]$FullColor = 'green', [string]$EmptyColor = 'dim',
        [string]$Full = '#', [string]$Empty = '.'
    )
    if ($Max -le 0) { $Max = 1 }
    $ratio = [Math]::Max(0.0, [Math]::Min(1.0, $Value / $Max))
    $n = [int][Math]::Round($ratio * $Width)
    return @(
        @('[', 'dim'),
        @(($Full * $n), $FullColor),
        @(($Empty * ($Width - $n)), $EmptyColor),
        @(']', 'dim')
    )
}

# --- flushing --------------------------------------------------------

function Get-RowText {
    param([object[]]$Segments)
    $sb  = [System.Text.StringBuilder]::new()
    $len = 0
    foreach ($s in $Segments) {
        # A segment is @('text','colour'). Tolerate a bare string too, so one
        # malformed row degrades to plain text instead of leaking a colour name.
        if ($s -is [string]) { $text = $s; $color = 'gray' }
        else {
            $text  = [string]$s[0]
            $color = if ($s.Count -gt 1) { [string]$s[1] } else { 'gray' }
        }
        $code  = $script:Ansi[$color]
        if (-not $code) { $code = $script:Ansi.gray }
        [void]$sb.Append($code).Append($text)
        $len += $text.Length
    }
    return @{ Text = $sb.ToString(); Len = $len }
}

function Show-Frame {
    $script:FrameNo++

    if ($script:Scripted) {
        Write-Output ("=== frame $($script:FrameNo) " + ('=' * 40))
        foreach ($row in $script:Rows) {
            $r = Get-RowText $row
            Write-Output ($r.Text -replace "`e\[[0-9;]*m", '')
        }
        return
    }

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append("`e[H")                    # cursor to top-left

    $count = [Math]::Min($script:Rows.Count, $script:ScreenH)
    for ($i = 0; $i -lt $count; $i++) {
        $r   = Get-RowText $script:Rows[$i]
        $pad = [Math]::Max(0, $script:ScreenW - $r.Len)
        [void]$sb.Append($r.Text).Append(' ' * $pad).Append($script:Ansi.reset).Append("`n")
    }
    # wipe any rows left over from a taller previous frame
    for ($i = $count; $i -lt $script:ScreenH; $i++) {
        [void]$sb.Append(' ' * $script:ScreenW).Append("`n")
    }

    [Console]::Write($sb.ToString())
}

function Clear-Screen {
    if ($script:Scripted) { return }
    [Console]::Write("`e[2J`e[H")
}
