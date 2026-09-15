<#
    Tower of Turing - learn C++ by climbing a tower.

    Just run it:      .\play.cmd
    Maintenance:      .\play.cmd verify
#>

[CmdletBinding()]
param(
    [string]$Command = 'play',
    [string]$Arg
)

$ErrorActionPreference = 'Stop'
$GameRoot = $PSScriptRoot

. (Join-Path $GameRoot 'engine\Adventure.ps1')

switch ($Command.ToLower()) {

    # the game
    { $_ -in 'play', '', 'game', 'start' } {
        Start-Adventure
        break
    }

    # drives the game with a canned key sequence and prints the frames
    # as plain text. Used to check the screens without a keyboard.
    'demo' {
        Start-Adventure -ScriptedKeys $Arg
        break
    }

    # maintenance: every reference solution must still pass its trials
    'verify' {
        if (-not (Initialize-Toolchain)) { Write-Host 'no compiler found'; break }
        Test-AllSolutions $Arg
        break
    }

    'reset' {
        $level = if ($Arg) { Get-Level $Arg } else { $null }
        if (-not $level) { Write-Host '  usage: .\play.cmd reset <floor number>' -ForegroundColor Yellow; break }
        Reset-Level $Arg
        break
    }

    { $_ -in 'help', '-h', '--help', '/?' } {
        Write-Host ''
        Write-Host '  .\play.cmd            play' -ForegroundColor Cyan
        Write-Host '  .\play.cmd reset <n>  restore one floor to its starter code' -ForegroundColor DarkGray
        Write-Host '  .\play.cmd verify     check every reference solution (maintenance)' -ForegroundColor DarkGray
        Write-Host ''
        Write-Host '  Everything else happens inside the game.' -ForegroundColor DarkGray
        Write-Host ''
        break
    }

    default {
        Write-Host ''
        Write-Host "  Unknown command: $Command" -ForegroundColor Red
        Write-Host '  Just run .\play.cmd to play.' -ForegroundColor DarkGray
        Write-Host ''
    }
}
