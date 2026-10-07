# setup_git_sync.ps1  -  ONE-TIME setup of git sync on a PC (safe to run again).
#
# Lab PC (first time, the project folder is not a git repo yet):
#   powershell -ExecutionPolicy Bypass -File docs\tools\setup_git_sync.ps1 -GitName "<name>" -GitEmail "<email>" -RemoteUrl https://github.com/<you>/<repo>.git
#
# Another PC: install Git, then (rename an old Desktop\PAM_controlProgram first, e.g. to PAM_controlProgram_old)
#   git clone https://github.com/<you>/<repo>.git "%USERPROFILE%\Desktop\PAM_controlProgram"
#   powershell -ExecutionPolicy Bypass -File "%USERPROFILE%\Desktop\PAM_controlProgram\docs\tools\setup_git_sync.ps1" -GitName "<name>" -GitEmail "<email>"
#   then quit the Claude app and double-click sync_pam_sidebar.cmd
#
# What it does
#   1. git init (if needed) and repo settings (no line-ending conversion, UTF-8 file names, big pushes)
#   2. Desktop\Matlab, Desktop\New folder, Desktop\System_test_09_25 live INSIDE the project; the Desktop
#      keeps a junction (a transparent link), so old paths like C:\Users\2031\Desktop\Matlab\... still work.
#        real folder on Desktop, none in the project -> moved into the project, junction left behind
#        real folder on Desktop AND one in the project (e.g. from a clone) -> Desktop one renamed to
#                                                    <name>_before_git_<time> (compare/merge it yourself)
#   3. %USERPROFILE%\.claude\projects\<project>\memory -> junction to claude\memory (same rules)
#   4. sets the GitHub remote (-RemoteUrl)
# Nothing is deleted. This file is ASCII-only on purpose.

param(
    [string]$RemoteUrl      = '',
    [string]$GitName        = '',
    [string]$GitEmail       = '',
    [string]$DesktopDir     = [Environment]::GetFolderPath('Desktop'),
    [string]$UserProfileDir = $env:USERPROFILE,
    [switch]$SkipProcessCheck                                              # testing only
)
$ErrorActionPreference = 'Stop'
$repo  = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path.TrimEnd('\')
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'

function Find-Git {
    $c = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    foreach ($p in (Join-Path $env:ProgramFiles 'Git\cmd\git.exe'), (Join-Path $env:LOCALAPPDATA 'Programs\Git\cmd\git.exe')) {
        if (Test-Path -LiteralPath $p) { return $p }
    }
    throw 'Git is not installed. Install it (winget install --id Git.Git -e), then run this again.'
}
$gitExe = Find-Git
function Invoke-Git {
    $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try { $out = & $gitExe -C $repo @args 2>&1 | ForEach-Object { "$_" } }
    finally { $ErrorActionPreference = $old }
    if ($LASTEXITCODE -ne 0) { throw "git $($args -join ' ') failed: $($out -join ' ')" }
    return $out
}

if (-not $SkipProcessCheck) {
    $busy = Get-Process | Where-Object { $_.ProcessName -match '^(MATLAB|LabVIEW|EXCEL|POWERPNT|WINWORD)$' }
    if ($busy) {
        Write-Host "Close these programs first (they may hold files in the folders being moved): $(($busy.ProcessName | Sort-Object -Unique) -join ', ')" -ForegroundColor Red
        exit 1
    }
}

# $link = where the old path is; $real = the folder inside the repo.
function Set-Junction([string]$link, [string]$real, [bool]$createIfMissing) {
    $li = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
    if ($li -and $li.LinkType -eq 'Junction') {
        $t = @($li.Target)[0]
        if ($t -and ($t.TrimEnd('\') -eq $real.TrimEnd('\'))) { Write-Host "  ok        $link"; return }
        Write-Host "  WARNING   $link is a junction to $t, not to $real - left alone" -ForegroundColor Yellow; return
    }
    if ($li) {
        if (Test-Path -LiteralPath $real) {
            $bak = "${link}_before_git_$stamp"
            Rename-Item -LiteralPath $link -NewName (Split-Path $bak -Leaf)
            Write-Host "  RENAMED   $link -> $bak  (the repo already has this folder; compare and merge by hand)" -ForegroundColor Yellow
        } else {
            [void][IO.Directory]::CreateDirectory((Split-Path $real -Parent))
            Move-Item -LiteralPath $link -Destination $real
            Write-Host "  MOVED     $link -> $real"
        }
    }
    if (-not (Test-Path -LiteralPath $real)) {
        if (-not $createIfMissing) { Write-Host "  (not found, skipped) $link" -ForegroundColor Yellow; return }
        [void][IO.Directory]::CreateDirectory($real)
    }
    [void][IO.Directory]::CreateDirectory((Split-Path $link -Parent))
    [void](New-Item -ItemType Junction -Path $link -Target $real)
    Write-Host "  JUNCTION  $link -> $real"
}

Write-Host "Project: $repo"
Write-Host '== 1. git repository =='
if (-not (Test-Path -LiteralPath (Join-Path $repo '.git'))) {
    [void](Invoke-Git init -q -b main)
    Write-Host '  created'
} else { Write-Host '  exists' }
# Folder owned by another Windows user (e.g. copied in by the "CAO LAB" account): git refuses it
# ("dubious ownership") until this one folder is marked safe.
try { [void](Invoke-Git rev-parse --git-dir) } catch {
    if ("$_" -notmatch 'dubious ownership') { throw }
    $safe = $repo.Replace('\', '/')
    $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    & $gitExe config --global --add safe.directory $safe 2>&1 | Out-Null
    $ErrorActionPreference = $old
    Write-Host "  folder is owned by another Windows user: added git safe.directory $safe"
}
[void](Invoke-Git config core.autocrlf false)
[void](Invoke-Git config core.quotepath false)
[void](Invoke-Git config http.postBuffer 524288000)
if ($GitName)  { [void](Invoke-Git config user.name $GitName) }
if ($GitEmail) { [void](Invoke-Git config user.email $GitEmail) }

Write-Host '== 2. folders on the Desktop =='
foreach ($n in 'Matlab', 'New folder', 'System_test_09_25') {
    Set-Junction (Join-Path $DesktopDir $n) (Join-Path $repo $n) $false
}

Write-Host '== 3. Claude memory =='
$slug = $repo -replace '[^A-Za-z0-9]', '-'
Set-Junction (Join-Path $UserProfileDir ".claude\projects\$slug\memory") (Join-Path $repo 'claude\memory') $true

Write-Host '== 4. GitHub remote =='
if ($RemoteUrl) {
    $remotes = @(Invoke-Git remote)
    if ($remotes -contains 'origin') { [void](Invoke-Git remote set-url origin $RemoteUrl) } else { [void](Invoke-Git remote add origin $RemoteUrl) }
    Write-Host "  origin = $RemoteUrl"
} else {
    $remotes = @(Invoke-Git remote)
    if ($remotes -contains 'origin') { Write-Host "  origin = $(Invoke-Git remote get-url origin)" } else { Write-Host '  (none yet; run again with -RemoteUrl https://github.com/<you>/<repo>.git)' -ForegroundColor Yellow }
}
$who = ''
try { $who = (Invoke-Git config user.name) } catch { }
if (-not $who) { Write-Host '  NOTE: no git user name/email yet; run again with -GitName and -GitEmail' -ForegroundColor Yellow }

Write-Host ''
Write-Host 'Setup done. From now on: double-click sync_pam.cmd when you start AND when you finish working.' -ForegroundColor Green
