#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoScripts = Split-Path -Parent $MyInvocation.MyCommand.Path
$launcher = Join-Path (Split-Path -Parent $repoScripts) 'scripts\codex-cli-windows.ps1'
if (-not (Test-Path -LiteralPath $launcher)) {
    $launcher = Join-Path $env:USERPROFILE '.agents\skills\codex-cli-windows.ps1'
}
$stubPy = Join-Path $repoScripts 'codex-cli-windows-stub.py'
$failures = 0

function Get-ArgLines([string]$Raw) {
    return @($Raw -split '\r?\n' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}
function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) {
        Write-Host "FAIL: $Message"
        $script:failures++
    } else {
        Write-Host "ok: $Message"
    }
}

$python = $null
foreach ($candidate in @(
    (Join-Path $env:USERPROFILE 'miniconda3\envs\WAVER\python.exe'),
    'C:\ProgramData\miniconda3\envs\WAVER\python.exe',
    (Get-Command python -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source)
)) {
    if ($candidate -and (Test-Path -LiteralPath $candidate)) { $python = $candidate; break }
}
if (-not $python) { throw 'python.exe not found for stub tests' }

$stubDir = Join-Path $env:TEMP 'codex-cli-windows-test'
New-Item -ItemType Directory -Force -Path $stubDir | Out-Null
$stubCmd = Join-Path $stubDir 'codex-stub.cmd'
@(
    '@echo off',
    "set CODEX_STUB_DIR=$stubDir",
    "`"$python`" `"$stubPy`" %*"
) | Set-Content -Path $stubCmd -Encoding ascii

function Invoke-Launcher {
    param(
        [Parameter(Mandatory = $true)][ValidateSet('review', 'exec')][string]$Mode,
        [switch]$Uncommitted,
        [string]$PromptFile = ''
    )
    $out = Join-Path $stubDir 'out.md'
    $err = Join-Path $stubDir 'err.log'
    Remove-Item -Force -ErrorAction SilentlyContinue $out, $err, "$err.stdout.log", (Join-Path $stubDir 'args.txt'), (Join-Path $stubDir 'stdin.txt')
    $env:CODEX_STUB_DIR = $stubDir
    $splat = @{
        Mode              = $Mode
        OutPath           = $out
        ErrPath           = $err
        WorkingDirectory  = $stubDir
        CodexExe          = $stubCmd
    }
    if ($Uncommitted) { $splat.Uncommitted = $true }
    if ($PromptFile) { $splat.PromptFile = $PromptFile }
    & $launcher @splat
    return @{
        ExitCode = $LASTEXITCODE
        Out      = $out
        Err      = $err
        Args     = $(if (Test-Path (Join-Path $stubDir 'args.txt')) { Get-Content (Join-Path $stubDir 'args.txt') -Raw } else { '' })
        Stdin    = $(if (Test-Path (Join-Path $stubDir 'stdin.txt')) { Get-Content (Join-Path $stubDir 'stdin.txt') -Raw } else { '' })
        ErrText  = $(if (Test-Path $err) { Get-Content $err -Raw } else { '' })
    }
}

try {
    & $launcher -Mode review -OutPath (Join-Path $stubDir 'x.md') -ErrPath (Join-Path $stubDir 'x.err') -CodexExe $stubCmd
    Assert-True $false 'review without scope should throw'
} catch {
    Assert-True ($_.Exception.Message -match 'exactly one of') 'review without scope throws'
}

try {
    & $launcher -Mode exec -OutPath (Join-Path $stubDir 'x.md') -ErrPath (Join-Path $stubDir 'x.err') -CodexExe $stubCmd
    Assert-True $false 'exec without prompt should throw'
} catch {
    Assert-True ($_.Exception.Message -match 'PromptFile') 'exec without prompt throws'
}

$prompt = Join-Path $stubDir 'prompt.txt'
[System.IO.File]::WriteAllText($prompt, "review these paths:`nweb/a.tsx", [System.Text.UTF8Encoding]::new($false))

$result = Invoke-Launcher -Mode exec -PromptFile $prompt
$execArgs = Get-ArgLines $result.Args
Assert-True ($result.ExitCode -eq 0) "exec exit 0, got $($result.ExitCode)"
Assert-True ($execArgs -contains 'exec' -and $execArgs -notcontains 'review') 'exec mode has exec, not review'
Assert-True ($execArgs[-1] -eq '-') 'exec feeds prompt via -'
Assert-True ($result.Stdin -match 'web/a.tsx') 'exec stdin is prompt file'

$env:CODEX_STUB_MUTEX = $null
$result = Invoke-Launcher -Mode review -Uncommitted
$reviewArgs = Get-ArgLines $result.Args
Assert-True ($result.ExitCode -eq 0) "review exit 0, got $($result.ExitCode)"
Assert-True ($reviewArgs -contains 'review' -and $reviewArgs -contains '--uncommitted') 'review uncommitted args'
Assert-True ($reviewArgs[-1] -ne '-') 'review without prompt has no -'

$env:CODEX_STUB_MUTEX = '1'
$result = Invoke-Launcher -Mode review -Uncommitted -PromptFile $prompt
Assert-True ($result.ExitCode -eq 0) "mutex retry exit 0, got $($result.ExitCode)"
Assert-True ($result.ErrText -match 'dropped PROMPT') 'mutex retry notes dropped prompt'
$env:CODEX_STUB_MUTEX = $null

if ($failures -gt 0) {
    Write-Host "$failures failure(s)"
    exit 1
}
Write-Host 'all launcher tests passed'
exit 0
