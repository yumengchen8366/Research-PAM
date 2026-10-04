# restore.ps1  -  run on the OTHER computer (works for a first restore AND for later updates).
#
# Before running:
#   1. Install the Claude desktop app, sign in with the SAME account, open the Code tab once.
#   2. Quit the app completely (tray icon -> Quit). The script refuses to run while it is open.
#
# Run (from the folder where you unzipped the package):
#   powershell -ExecutionPolicy Bypass -File .\restore.ps1
#
# What it does, file by file:
#   - File missing here                      -> copied.
#   - File identical (after path rewrite)    -> left alone.
#   - File differs AND it changed on the lab PC since the previous package
#                                            -> your copy is backed up to Desktop\PAM_sync_backup_<time>\, then replaced.
#   - File differs but did NOT change on the lab PC (you edited it here)
#                                            -> your copy is kept.
#   Nothing is ever deleted. A log is written to Desktop\PAM_sync_restore_log_<time>.txt.
#
# Targets: Desktop\PAM_controlProgram, Desktop\<each folder in extra\>,
#          %USERPROFILE%\.claude\projects\<slug> (memory + transcripts),
#          %APPDATA%\Claude\claude-code-sessions (sidebar session list).
# If your Desktop is not C:\Users\2031\Desktop, old paths inside copied text files are rewritten.

param(
    [string]$DesktopDir     = [Environment]::GetFolderPath('Desktop'),
    [string]$UserProfileDir = $env:USERPROFILE,
    [string]$AppDataDir     = $env:APPDATA,
    [switch]$SkipAppCheck   # testing only
)
$ErrorActionPreference = 'Stop'
$pkg   = $PSScriptRoot
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'

$oldUserRoot = 'C:\Users\2031'
$oldDesktop  = 'C:\Users\2031\Desktop'
$oldProject  = 'C:\Users\2031\Desktop\PAM_controlProgram'
$newProject  = Join-Path $DesktopDir 'PAM_controlProgram'

# Claude Code names its per-project folder after the path: every non-alphanumeric char -> '-'
function Get-Slug([string]$p) { return ($p -replace '[^A-Za-z0-9]', '-') }
$oldSlug = Get-Slug $oldProject
$newSlug = Get-Slug $newProject
$pathChanged = ($newProject -ne $oldProject)

# Old -> new paths, both as plain text and JSON-escaped (\ -> \\). One regex pass, longest first,
# so text that was already replaced is never replaced again.
$map = @{}
foreach ($pr in @(@($oldDesktop, $DesktopDir), @($oldUserRoot, $UserProfileDir), @($oldSlug, $newSlug))) {
    $a = $pr[0]; $b = $pr[1]
    if ($a -eq $b) { continue }
    $map[$a.Replace('\', '\\')] = $b.Replace('\', '\\')
    $map[$a] = $b
}
$pattern = (@($map.Keys) | Sort-Object Length -Descending | ForEach-Object { [regex]::Escape($_) }) -join '|'

# Files that changed on the lab PC since the previous package (written by make_sync_package.ps1).
$changed = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
$changedFile = Join-Path $pkg 'changed_since_previous.txt'
$allChanged = -not (Test-Path -LiteralPath $changedFile)
if (-not $allChanged) {
    foreach ($line in [IO.File]::ReadAllLines($changedFile, [Text.Encoding]::UTF8)) {
        $l = $line.Trim()
        if ($l -eq '*') { $allChanged = $true }
        elseif ($l -and -not $l.StartsWith('#')) { [void]$changed.Add($l.Replace('/', '\')) }
    }
}

$utf8NoBom = New-Object Text.UTF8Encoding($false)
$sha = [Security.Cryptography.SHA256]::Create()
function Get-Hash([byte[]]$b) { return [BitConverter]::ToString($sha.ComputeHash($b)) }

# Bytes the target SHOULD contain: the source, with old paths rewritten when needed.
function Get-Desired([string]$srcFile, [bool]$rewrite) {
    $bytes = [IO.File]::ReadAllBytes($srcFile)
    if (-not $rewrite -or $map.Count -eq 0) { return ,$bytes }
    $text = [IO.File]::ReadAllText($srcFile)
    $new  = [regex]::Replace($text, $pattern, { param($m) $map[$m.Value] })
    if ($new -eq $text) { return ,$bytes }
    return ,$utf8NoBom.GetBytes($new)
}

$log = New-Object Collections.Generic.List[string]
$stats = @{ added = 0; same = 0; updated = 0; kept = 0 }
$backupRoot = Join-Path $DesktopDir "PAM_sync_backup_$stamp"

# Sync one file. $relPkg = path inside the package (key for changed_since_previous.txt).
function Sync-File([string]$srcFile, [string]$target, [string]$relPkg, [bool]$rewrite) {
    $desired = Get-Desired $srcFile $rewrite
    $srcTime = (Get-Item -LiteralPath $srcFile).LastWriteTimeUtc
    if (Test-Path -LiteralPath $target) {
        $current = [IO.File]::ReadAllBytes($target)
        if ($current.Length -eq $desired.Length -and (Get-Hash $current) -eq (Get-Hash $desired)) {
            $stats.same++; return
        }
        if (-not ($allChanged -or $changed.Contains($relPkg))) {
            $stats.kept++; $log.Add("KEPT (edited on this PC, unchanged on lab PC): $target"); return
        }
        $bak = Join-Path $backupRoot $relPkg
        New-Item -ItemType Directory -Force (Split-Path $bak) | Out-Null
        Copy-Item -LiteralPath $target -Destination $bak -Force
        $stats.updated++; $log.Add("UPDATED (old copy backed up to $bak): $target")
    } else {
        New-Item -ItemType Directory -Force (Split-Path $target) | Out-Null
        $stats.added++; $log.Add("ADDED: $target")
    }
    [IO.File]::WriteAllBytes($target, $desired)
    (Get-Item -LiteralPath $target).LastWriteTimeUtc = $srcTime
}

function Sync-Tree([string]$srcRoot, [string]$dstRoot, [string]$pkgPrefix, [scriptblock]$shouldRewrite) {
    foreach ($f in Get-ChildItem -LiteralPath $srcRoot -Recurse -File -Force) {
        $rel = $f.FullName.Substring($srcRoot.Length).TrimStart('\')
        Sync-File $f.FullName (Join-Path $dstRoot $rel) ($pkgPrefix + '\' + $rel) ([bool](& $shouldRewrite $rel $f))
    }
}

if (-not $SkipAppCheck -and (Get-Process -Name 'claude' -ErrorAction SilentlyContinue)) {
    Write-Host 'The Claude app is still running. Quit it completely (tray icon -> Quit), then run this again.' -ForegroundColor Red
    exit 1
}

Write-Host "Desktop:      $DesktopDir"
Write-Host "Project path: $newProject"
if ($pathChanged) { Write-Host 'Path differs from the lab PC -> old paths in text files will be rewritten.' -ForegroundColor Yellow }
Write-Host ''

# ---------- 1. Project + extra folders ----------
Write-Host '== 1. Project files =='
Sync-Tree (Join-Path $pkg 'project\PAM_controlProgram') $newProject 'project\PAM_controlProgram' {
    param($rel, $f) $pathChanged -and $f.Extension -eq '.md' -and ($rel -notmatch '\\' -or $rel -like 'docs\*')
}
foreach ($d in Get-ChildItem -LiteralPath (Join-Path $pkg 'extra') -Directory) {
    Sync-Tree $d.FullName (Join-Path $DesktopDir $d.Name) ('extra\' + $d.Name) { param($rel, $f) $false }
}

# ---------- 2. Memory + transcripts ----------
Write-Host '== 2. Claude Code memory and transcripts =='
$dstProj = Join-Path $UserProfileDir ".claude\projects\$newSlug"
Sync-Tree (Join-Path $pkg 'claude\projects') $dstProj 'claude\projects' {
    param($rel, $f) $pathChanged -and ($f.Extension -in '.jsonl', '.json', '.md', '.txt')
}

# ---------- 3. Desktop app session list ----------
Write-Host '== 3. Claude desktop session list =='
$srcMetaRoot = Join-Path $pkg 'claude\desktop-sessions'
$dstMetaRoot = Join-Path $AppDataDir 'Claude\claude-code-sessions'
foreach ($acctDir in Get-ChildItem -LiteralPath $srcMetaRoot -Directory) {
    foreach ($orgDir in Get-ChildItem -LiteralPath $acctDir.FullName -Directory) {
        $dst = Join-Path $dstMetaRoot (Join-Path $acctDir.Name $orgDir.Name)
        if (-not (Test-Path -LiteralPath $dst)) {
            # Same account should give the same folder ids; if not, fall back to the only existing one.
            $existing = @()
            if (Test-Path -LiteralPath $dstMetaRoot) {
                foreach ($a in Get-ChildItem -LiteralPath $dstMetaRoot -Directory) { $existing += @(Get-ChildItem -LiteralPath $a.FullName -Directory) }
            }
            if ($existing.Count -eq 1) {
                $dst = $existing[0].FullName
                Write-Host "  NOTE: account folder id differs, using $dst" -ForegroundColor Yellow
            }
        }
        foreach ($f in Get-ChildItem -LiteralPath $orgDir.FullName -Filter 'local_*.json' -File) {
            Sync-File $f.FullName (Join-Path $dst $f.Name) ('claude\desktop-sessions\' + $acctDir.Name + '\' + $orgDir.Name + '\' + $f.Name) $pathChanged
        }
    }
}

$logFile = Join-Path $DesktopDir "PAM_sync_restore_log_$stamp.txt"
$summary = "added $($stats.added), updated $($stats.updated), kept your version $($stats.kept), unchanged $($stats.same)"
[IO.File]::WriteAllLines($logFile, [string[]](@("restore $stamp : $summary", '') + $log), $utf8NoBom)
Write-Host ''
Write-Host "Done: $summary" -ForegroundColor Green
if ($stats.updated -gt 0) { Write-Host "Backups of replaced files: $backupRoot" -ForegroundColor Yellow }
if ($stats.kept -gt 0) { Write-Host "Some files were kept because you edited them on this PC. See the log." -ForegroundColor Yellow }
Write-Host "Log: $logFile"
Write-Host 'Open the Claude app -> Code tab; the PAM sessions should be in the sidebar.'
