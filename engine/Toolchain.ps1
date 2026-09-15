# ---------------------------------------------------------------
#  Toolchain.ps1 - finds a C++ compiler and makes it fast to use.
# ---------------------------------------------------------------

$script:ToolchainReady = $false

function Get-VcVarsPath {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (-not (Test-Path $vswhere)) { return $null }
    $install = & $vswhere -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
                          -latest -format value -property installationPath 2>$null
    if (-not $install) { return $null }
    $bat = Join-Path $install 'VC\Auxiliary\Build\vcvars64.bat'
    if (Test-Path $bat) { return $bat }
    return $null
}

# Running vcvars64.bat costs ~2 seconds. We run it once, capture the
# environment it produces, and cache it. After that, builds are instant.
function Import-MsvcEnvironment {
    param([switch]$Force)

    $cache = Join-Path $GameRoot '.state\msvc-env.json'

    if (-not $Force -and (Test-Path $cache)) {
        $data = Get-Content $cache -Raw | ConvertFrom-Json
        if ((Test-Path $data.ClPath) -and ((Get-Date) - [datetime]$data.Captured).TotalDays -lt 30) {
            foreach ($p in $data.Vars.PSObject.Properties) {
                Set-Item -Path "env:$($p.Name)" -Value $p.Value
            }
            return $data.ClPath
        }
    }

    $bat = Get-VcVarsPath
    if (-not $bat) { return $null }

    Write-Host '  Waking up the MSVC toolchain (one time only)...' -ForegroundColor DarkGray
    $raw = cmd /c "call `"$bat`" >nul 2>&1 && set" 2>$null

    $vars = @{}
    foreach ($line in $raw) {
        if ($line -match '^([^=]+)=(.*)$') {
            $name = $Matches[1]
            if ($name -in @('PATH','INCLUDE','LIB','LIBPATH','VCToolsInstallDir','WindowsSdkDir','UCRTVersion','VSINSTALLDIR')) {
                $vars[$name] = $Matches[2]
            }
        }
    }
    if (-not $vars.ContainsKey('INCLUDE')) { return $null }

    foreach ($k in $vars.Keys) { Set-Item -Path "env:$k" -Value $vars[$k] }

    $cl = (Get-Command cl.exe -ErrorAction SilentlyContinue).Source
    if (-not $cl) { return $null }

    New-Item -ItemType Directory -Force -Path (Split-Path $cache) | Out-Null
    [pscustomobject]@{
        ClPath   = $cl
        Captured = (Get-Date).ToString('o')
        Vars     = $vars
    } | ConvertTo-Json -Depth 4 | Set-Content -Path $cache -Encoding UTF8

    return $cl
}

function Initialize-Toolchain {
    param([switch]$Force)
    if ($script:ToolchainReady -and -not $Force) { return $true }

    # Preference order: whatever is already on PATH, then MSVC via vcvars.
    foreach ($name in 'g++','clang++') {
        $found = (Get-Command $name -ErrorAction SilentlyContinue).Source
        if ($found) {
            $script:Compiler = @{ Kind = 'gnu'; Path = $found; Name = $name }
            $script:ToolchainReady = $true
            return $true
        }
    }

    $cl = Import-MsvcEnvironment -Force:$Force
    if ($cl) {
        $script:Compiler = @{ Kind = 'msvc'; Path = $cl; Name = 'cl' }
        $script:ToolchainReady = $true
        return $true
    }

    return $false
}

function Get-CompilerLabel {
    if (-not $script:Compiler) { return 'none' }
    if ($script:Compiler.Kind -eq 'msvc') { return 'MSVC (Visual Studio)' }
    return $script:Compiler.Name
}

# Compiles every .cpp in $SourceDir into a single executable.
# Returns @{ Ok = bool; Exe = path; Output = compiler diagnostics }
function Build-Project {
    param(
        [Parameter(Mandatory)][string]$SourceDir,
        [Parameter(Mandatory)][string]$ExeName
    )

    if (-not (Initialize-Toolchain)) {
        return @{ Ok = $false; Output = 'No C++ compiler found.'; Exe = $null }
    }

    $sources = @(Get-ChildItem -Path $SourceDir -Filter *.cpp -File | Sort-Object Name)
    if ($sources.Count -eq 0) {
        return @{ Ok = $false; Output = "No .cpp files found in $SourceDir"; Exe = $null }
    }

    $buildDir = Join-Path $SourceDir '.build'
    New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
    $exe = Join-Path $buildDir "$ExeName.exe"
    if (Test-Path $exe) { Remove-Item $exe -Force -ErrorAction SilentlyContinue }

    $names = $sources | ForEach-Object { $_.FullName }
    $prev = Get-Location
    Set-Location $SourceDir
    try {
        if ($script:Compiler.Kind -eq 'msvc') {
            $args = @('/nologo','/EHsc','/std:c++20','/Zc:__cplusplus','/W3','/diagnostics:caret',
                      "/Fe:$exe", "/Fo:$buildDir\") + $names
        } else {
            $args = @('-std=c++20','-Wall','-o',$exe) + $names
        }
        $out = & $script:Compiler.Path @args 2>&1 | Out-String
    } finally {
        Set-Location $prev
    }

    return @{
        Ok     = (Test-Path $exe)
        Exe    = $exe
        Output = $out.Trim()
    }
}

# Some levels write save files. Clear them between trials so that a case
# never inherits state from the case - or the run - before it.
function Reset-RunArtifacts {
    param([Parameter(Mandatory)][string]$Dir)
    foreach ($name in 'dungeon.sav', 'save.txt') {
        $p = Join-Path $Dir $name
        if (Test-Path $p) { Remove-Item $p -Force -ErrorAction SilentlyContinue }
    }
}

# Runs an executable with piped stdin and a hard timeout, so an
# accidental infinite loop never freezes the game.
function Invoke-Program {
    param(
        [Parameter(Mandatory)][string]$Exe,
        [string]$StdIn = '',
        [int]$TimeoutMs = 10000,
        [string]$WorkDir
    )

    $tmp     = Join-Path $env:TEMP ("tot-" + [guid]::NewGuid().ToString('N'))
    $inFile  = "$tmp.in"
    $outFile = "$tmp.out"
    $errFile = "$tmp.err"
    Set-Content -Path $inFile -Value $StdIn -Encoding ascii -NoNewline

    if (-not $WorkDir) { $WorkDir = Split-Path $Exe }

    $timedOut = $false
    try {
        $p = Start-Process -FilePath $Exe -WorkingDirectory $WorkDir -PassThru -NoNewWindow `
                           -RedirectStandardInput $inFile `
                           -RedirectStandardOutput $outFile `
                           -RedirectStandardError $errFile
        if (-not $p.WaitForExit($TimeoutMs)) {
            $timedOut = $true
            try { $p.Kill($true) } catch { }
            $p.WaitForExit(2000) | Out-Null
        }
        $code = if ($timedOut) { -1 } else { $p.ExitCode }

        $stdout = if (Test-Path $outFile) { Get-Content $outFile -Raw } else { '' }
        $stderr = if (Test-Path $errFile) { Get-Content $errFile -Raw } else { '' }
    } finally {
        Remove-Item $inFile,$outFile,$errFile -Force -ErrorAction SilentlyContinue
    }

    return @{
        StdOut   = [string]$stdout
        StdErr   = [string]$stderr
        ExitCode = $code
        TimedOut = $timedOut
    }
}
