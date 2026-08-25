#Requires -Version 5.1
<#
.SYNOPSIS
  Invoke local Codex CLI with a Windows-safe stdin, quoting, and exe resolution.
.DESCRIPTION
  Agents must call this script instead of hand-writing `codex exec` / `< NUL`.
  PowerShell cannot use `< NUL`. Windows PowerShell 5 splits -ArgumentList on spaces.
  Some Codex builds (seen on 0.149.x) make `exec review --uncommitted` mutually
  exclusive with a positional PROMPT; this script retries once without the prompt.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('review', 'exec')]
    [string]$Mode,

    [Parameter(Mandatory = $true)]
    [string]$OutPath,

    [Parameter(Mandatory = $true)]
    [string]$ErrPath,

    [string]$WorkingDirectory = '',

    [switch]$Uncommitted,
    [string]$Base = '',
    [string]$Commit = '',

    [string]$PromptFile = '',
    [string]$Model = '',
    [string]$Effort = '',
    [string]$CodexExe = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-CodexExecutable {
    param([string]$Override)
    if ($Override) {
        if (-not (Test-Path -LiteralPath $Override)) {
            throw "CodexExe not found: $Override"
        }
        return (Resolve-Path -LiteralPath $Override).Path
    }

    $npmWrapper = Join-Path $env:APPDATA 'npm\codex.ps1'
    $codexRoot = Join-Path $env:LOCALAPPDATA 'OpenAI\Codex\bin'
    if (Test-Path -LiteralPath $codexRoot) {
        $found = Get-ChildItem -LiteralPath $codexRoot -Filter 'codex.exe' -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.DirectoryName -ne $codexRoot } |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        if ($found) { return $found.FullName }
    }

    $cmd = Get-Command codex -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source -and (Test-Path -LiteralPath $cmd.Source) -and $cmd.Source -like '*.exe') {
        return $cmd.Source
    }
    if (Test-Path -LiteralPath $npmWrapper) {
        throw "codex is a PowerShell wrapper ($npmWrapper). Pass -CodexExe to a real codex.exe under $codexRoot"
    }
    throw 'codex CLI missing; run `codex login` after install'
}

function New-EmptyStdinFile {
    $path = Join-Path $env:TEMP 'codex-cli-stdin-empty.txt'
    [System.IO.File]::WriteAllText($path, '', [System.Text.UTF8Encoding]::new($false))
    return $path
}

function Test-MutexError {
    param([string]$Text)
    if (-not $Text) { return $false }
    return $Text -match "cannot be used with '\[PROMPT\]'" -or
        $Text -match "cannot be used with '--uncommitted'" -or
        $Text -match "cannot be used with '--base'" -or
        $Text -match "cannot be used with '--commit'"
}

function Invoke-CodexProcess {
    param(
        [string]$Exe,
        [string[]]$ArgumentList,
        [string]$StdinPath,
        [string]$WorkingDirectory,
        [string]$ErrPath
    )

    $stdoutPath = "$ErrPath.stdout.log"
    $cmdPath = Join-Path $env:TEMP ("codex-cli-run-" + [guid]::NewGuid().ToString('N').Substring(0, 8) + ".cmd")
    $quoted = foreach ($arg in $ArgumentList) {
        if ($arg -match '[\s"]' -and $arg -notmatch '^sandbox_mode=') {
            '"' + ($arg -replace '"', '\"') + '"'
        } else {
            $arg
        }
    }
    $argLine = [string]::Join(' ', $quoted)
    $lines = @(
        '@echo off',
        "cd /d `"$WorkingDirectory`"",
        "`"$Exe`" $argLine < `"$StdinPath`" > `"$stdoutPath`" 2> `"$ErrPath`"",
        'exit /b %ERRORLEVEL%'
    )
    $ansi = [System.Text.Encoding]::GetEncoding(437)
    [System.IO.File]::WriteAllLines($cmdPath, $lines, $ansi)
    $proc = Start-Process -FilePath 'cmd.exe' -ArgumentList @('/c', "`"$cmdPath`"") -WorkingDirectory $WorkingDirectory -Wait -PassThru -NoNewWindow
    $stderr = ''
    if (Test-Path -LiteralPath $ErrPath) {
        $stderr = [System.IO.File]::ReadAllText($ErrPath)
    }
    return @{
        ExitCode = $proc.ExitCode
        Stderr   = $stderr
        Stdout   = $(if (Test-Path -LiteralPath $stdoutPath) { [System.IO.File]::ReadAllText($stdoutPath) } else { '' })
    }
}

if (-not $WorkingDirectory) { $WorkingDirectory = (Get-Location).Path }
$scopeCount = 0
if ($Uncommitted) { $scopeCount++ }
if ($Base) { $scopeCount++ }
if ($Commit) { $scopeCount++ }
if ($Mode -eq 'review' -and $scopeCount -ne 1) {
    throw 'review mode requires exactly one of -Uncommitted, -Base, -Commit'
}

$exe = Resolve-CodexExecutable -Override $CodexExe
$codexArgs = [System.Collections.Generic.List[string]]::new()
[void]$codexArgs.Add('exec')
if ($Mode -eq 'review') { [void]$codexArgs.Add('review') }
[void]$codexArgs.Add('-c')
[void]$codexArgs.Add('sandbox_mode="read-only"')
[void]$codexArgs.Add('--ephemeral')
[void]$codexArgs.Add('-o')
[void]$codexArgs.Add($OutPath)
if ($Model) {
    [void]$codexArgs.Add('-m')
    [void]$codexArgs.Add($Model)
}
if ($Effort) {
    [void]$codexArgs.Add('-c')
    [void]$codexArgs.Add("model_reasoning_effort=`"$Effort`"")
}
if ($Uncommitted) { [void]$codexArgs.Add('--uncommitted') }
if ($Base) {
    [void]$codexArgs.Add('--base')
    [void]$codexArgs.Add($Base)
}
if ($Commit) {
    [void]$codexArgs.Add('--commit')
    [void]$codexArgs.Add($Commit)
}

$hasPrompt = $PromptFile -and (Test-Path -LiteralPath $PromptFile) -and ((Get-Item -LiteralPath $PromptFile).Length -gt 0)
$emptyStdin = New-EmptyStdinFile

function Invoke-Once {
    param([bool]$UsePrompt)
    $runArgs = [string[]]$codexArgs.ToArray()
    $stdin = $emptyStdin
    if ($UsePrompt -and $hasPrompt) {
        $runArgs = $runArgs + @('-')
        $stdin = $PromptFile
    }
    Invoke-CodexProcess -Exe $exe -ArgumentList $runArgs -StdinPath $stdin -WorkingDirectory $WorkingDirectory -ErrPath $ErrPath
}

if ($Mode -eq 'exec') {
    if (-not $hasPrompt) { throw 'exec mode requires -PromptFile with UTF-8 content' }
    $result = Invoke-Once -UsePrompt $true
    exit $result.ExitCode
}

# review: prefer scope + prompt-on-stdin. 0.149.x mutex → retry once without prompt.
$result = Invoke-Once -UsePrompt $hasPrompt
if ($hasPrompt -and $result.ExitCode -ne 0 -and (Test-MutexError $result.Stderr)) {
    $result = Invoke-Once -UsePrompt $false
    $note = @(
        $result.Stderr
        ''
        'codex-cli-windows: dropped PROMPT because this Codex build rejects scope+PROMPT; host must filter findings to the focus paths.'
    ) -join [Environment]::NewLine
    [System.IO.File]::WriteAllText($ErrPath, $note, [System.Text.UTF8Encoding]::new($false))
}
exit $result.ExitCode
