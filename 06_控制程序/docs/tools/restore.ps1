# restore.ps1  -  run on the OTHER computer. Use it for the first restore and for every later update.
#
# Before running:
#   1. Install the Claude desktop app, sign in with the SAME account, open the Code tab once.
#   2. Quit the app completely (tray icon -> Quit). Also close Excel / PowerPoint / PDF viewers.
#
# Run (from the PAM_sync folder you unzipped):
#   powershell -ExecutionPolicy Bypass -File .\restore.ps1
#   (add -DryRun to only list what would happen, without changing anything)
#
# This PC remembers what it received last time (%LOCALAPPDATA%\PAM_sync\restore_state.tsv). Per file:
#   missing here                                -> copied
#   same as the lab version                     -> left alone
#   not edited here since the last restore      -> replaced by the lab version
#   edited here, lab version unchanged          -> your version is kept
#   edited here AND changed on the lab PC:
#       your files (project, Matlab, ...)       -> your version is kept; the lab version is saved to
#                                                  Desktop\PAM_sync_conflicts_<time>\ for you to merge
#       Claude data (transcripts, memory, ...)  -> the lab version is used; yours is saved to
#                                                  Desktop\PAM_sync_backup_<time>\
#   exists here, but this PC has no record of it (first restore with this script)
#                                               -> the lab version is used; yours is saved to the backup folder
# Nothing is ever deleted. Each run writes Desktop\PAM_sync_restore_log_<time>.txt.
# Packages may be skipped. A package OLDER than the last one restored is refused (override: -AllowOlder).
# If your Desktop is not C:\Users\2031\Desktop, old paths inside Claude data and docs\*.md are rewritten.
# This file is ASCII-only on purpose.

param(
    [string]$DesktopDir     = [Environment]::GetFolderPath('Desktop'),
    [string]$UserProfileDir = $env:USERPROFILE,
    [string]$ClaudeAppData  = '',                               # default: auto-detect (MSIX-aware)
    [string]$StateFile      = '',                               # default: %LOCALAPPDATA%\PAM_sync\restore_state.tsv
    [string]$SdkCheckPath   = 'C:\AlazarTech\ATS-SDK\23.3.0',   # if this exists here, SDK paths are not rewritten
    [switch]$DryRun,
    [switch]$AllowOlder,
    [switch]$SkipAppCheck                                       # testing only
)
$ErrorActionPreference = 'Stop'
$pkg   = $PSScriptRoot
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss_fff'
if (-not $StateFile) { $StateFile = Join-Path $env:LOCALAPPDATA 'PAM_sync\restore_state.tsv' }
$utf8NoBom = New-Object Text.UTF8Encoding($false)

if (-not $SkipAppCheck -and (Get-Process -Name 'claude' -ErrorAction SilentlyContinue)) {
    Write-Host 'The Claude app is still running. Quit it completely (tray icon -> Quit), then run this again.' -ForegroundColor Red
    exit 1
}

# ---------- package ----------
$infoFile = Join-Path $pkg 'package_info.txt'
$manFile  = Join-Path $pkg 'manifest.tsv'
if (-not ((Test-Path -LiteralPath $infoFile) -and (Test-Path -LiteralPath $manFile))) {
    Write-Host 'This package has no manifest (made by an older make_sync_package.ps1). Make a new package on the lab PC.' -ForegroundColor Red
    exit 1
}
$info = @{}
foreach ($l in [IO.File]::ReadAllLines($infoFile)) {
    $i = $l.IndexOf('=')
    if ($i -gt 0) { $info[$l.Substring(0, $i).Trim()] = $l.Substring($i + 1).Trim() }
}
$pkgName = $info['name']; $pkgMade = $info['made']
$manifest = @{}
foreach ($l in [IO.File]::ReadAllLines($manFile, [Text.Encoding]::UTF8)) {
    $p = $l.Split("`t")
    if ($p.Count -eq 2) { $manifest[$p[0]] = $p[1] }
}

# ---------- what this PC received last time ----------
$state = @{}; $lastMade = ''; $lastName = ''; $stateDesktop = ''
if (Test-Path -LiteralPath $StateFile) {
    foreach ($l in [IO.File]::ReadAllLines($StateFile, [Text.Encoding]::UTF8)) {
        $p = $l.Split("`t")
        if ($l.StartsWith('#')) {
            if ($p.Count -ge 2) {
                switch ($p[0]) { '#made' { $lastMade = $p[1] } '#name' { $lastName = $p[1] } '#desktop' { $stateDesktop = $p[1] } }
            }
        } elseif ($p.Count -eq 3) { $state[$p[0]] = @($p[1], $p[2]) }
    }
    if ($stateDesktop -and $stateDesktop -ne $DesktopDir) {
        Write-Host "Note: the saved record is for $stateDesktop, not $DesktopDir. Treating this as a first restore." -ForegroundColor Yellow
        $state = @{}; $lastMade = ''; $lastName = ''
    }
}
if ($lastMade -and $pkgMade -and ($pkgMade -lt $lastMade) -and -not $AllowOlder) {
    Write-Host "This package ($pkgName) is OLDER than the one restored last time ($lastName). Nothing was changed." -ForegroundColor Red
    Write-Host 'Use the newest package. (To restore it anyway, add -AllowOlder.)' -ForegroundColor Red
    exit 1
}
$newState = @{}
foreach ($k in $state.Keys) { $newState[$k] = $state[$k] }

# ---------- old -> new paths ----------
$oldUserRoot = 'C:\Users\2031'
$oldDesktop  = 'C:\Users\2031\Desktop'
$oldProject  = 'C:\Users\2031\Desktop\PAM_controlProgram'
$oldSdk      = 'C:\AlazarTech\ATS-SDK\23.3.0'
$newProject  = Join-Path $DesktopDir 'PAM_controlProgram'
# Claude Code names its per-project folder after the path: every non-alphanumeric char -> '-'
function Get-Slug([string]$p) { return ($p -replace '[^A-Za-z0-9]', '-') }
$newSlug = Get-Slug $newProject
$pairs = @(@($oldDesktop, $DesktopDir), @($oldUserRoot, $UserProfileDir), @((Get-Slug $oldProject), $newSlug))
$sdkHere = (Test-Path -LiteralPath (Join-Path $pkg 'extra\ATS-SDK-23.3.0')) -or (Test-Path -LiteralPath (Join-Path $DesktopDir 'ATS-SDK-23.3.0'))
if ($sdkHere -and -not (Test-Path -LiteralPath $SdkCheckPath)) {
    $pairs += , @($oldSdk, (Join-Path $DesktopDir 'ATS-SDK-23.3.0'))
}
# plain and JSON-escaped (\ -> \\); one regex pass, longest first, so replaced text is never replaced again
$map = @{}
foreach ($pr in $pairs) {
    $a = $pr[0]; $b = $pr[1]
    if ($a -eq $b) { continue }
    $map[$a.Replace('\', '\\')] = $b.Replace('\', '\\')
    $map[$a] = $b
}
$pattern = (@($map.Keys) | Sort-Object Length -Descending | ForEach-Object { [regex]::Escape($_) }) -join '|'

$sha = [Security.Cryptography.SHA256]::Create()
function Get-Hash([byte[]]$b) { return [BitConverter]::ToString($sha.ComputeHash($b)).Replace('-', '') }

# Bytes the target SHOULD contain: the package file, with old paths rewritten where needed.
function Get-Desired([byte[]]$bytes, [bool]$rewrite) {
    if (-not $rewrite -or $map.Count -eq 0) { return , $bytes }
    $sr = New-Object IO.StreamReader((New-Object IO.MemoryStream(, $bytes)), [Text.Encoding]::UTF8, $true)
    try { $text = $sr.ReadToEnd() } finally { $sr.Close() }
    $new = [regex]::Replace($text, $pattern, { param($m) $map[$m.Value] })
    if ($new -ceq $text) { return , $bytes }
    return , $utf8NoBom.GetBytes($new)
}

# ---------- log (written as we go) ----------
$backupRoot   = Join-Path $DesktopDir "PAM_sync_backup_$stamp"
$conflictRoot = Join-Path $DesktopDir "PAM_sync_conflicts_$stamp"
$logFile = Join-Path $DesktopDir "PAM_sync_restore_log_$stamp.txt"
$logW = New-Object IO.StreamWriter($logFile, $false, $utf8NoBom)
$logW.AutoFlush = $true
function Log([string]$s) { $logW.WriteLine($s) }
$stats = @{ added = 0; updated = 0; same = 0; kept = 0; conflictKept = 0; conflictLab = 0; replaced = 0; failed = 0 }

function Write-Target([string]$target, [byte[]]$data, [datetime]$timeUtc) {
    if ($DryRun) { return }
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target))
    [IO.File]::WriteAllBytes($target, $data)
    [IO.File]::SetLastWriteTimeUtc($target, $timeUtc)
}
function Save-Copy([string]$from, [string]$to) {
    if ($DryRun) { return }
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($to))
    [IO.File]::Copy($from, $to, $true)
}

# One file. $relPkg = path inside the package (manifest / state key).
function Sync-File([string]$srcFile, [string]$target, [string]$relPkg, [bool]$rewrite, [bool]$keepHomeOnConflict) {
    $bytes = [IO.File]::ReadAllBytes($srcFile)
    $sh = Get-Hash $bytes
    if (-not $manifest.ContainsKey($relPkg)) { throw 'not listed in manifest.tsv' }
    if ($manifest[$relPkg] -ne $sh) { throw 'package file is damaged (checksum mismatch) - unzip the package again' }
    $time = [IO.File]::GetLastWriteTimeUtc($srcFile)
    $desired = Get-Desired $bytes $rewrite
    $dh = Get-Hash $desired
    if (-not [IO.File]::Exists($target)) {
        Write-Target $target $desired $time
        $newState[$relPkg] = @($sh, $dh); $stats.added++; Log "ADDED      $target"; return
    }
    $th = Get-Hash ([IO.File]::ReadAllBytes($target))
    if ($th -eq $dh) { $newState[$relPkg] = @($sh, $dh); $stats.same++; return }
    $st = $state[$relPkg]
    if ($st) {
        if ($th -eq $st[1]) {
            # not edited on this PC since the last restore
            Write-Target $target $desired $time
            $newState[$relPkg] = @($sh, $dh); $stats.updated++; Log "UPDATED    $target"; return
        }
        if ($sh -eq $st[0]) {
            $stats.kept++; Log "KEPT       $target   (edited on this PC; the lab version has not changed)"; return
        }
        if ($keepHomeOnConflict) {
            $c = Join-Path $conflictRoot $relPkg
            if (-not $DryRun) { [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($c)); [IO.File]::WriteAllBytes($c, $desired) }
            # This lab version has now been handed over once; until the lab changes it again, treat yours as a home edit.
            $newState[$relPkg] = @($sh, $st[1])
            $stats.conflictKept++; Log "CONFLICT   $target   (changed on BOTH PCs: kept yours; lab version saved to $c)"; return
        }
        $b = Join-Path $backupRoot $relPkg
        Save-Copy $target $b
        Write-Target $target $desired $time
        $newState[$relPkg] = @($sh, $dh); $stats.conflictLab++; Log "CONFLICT   $target   (changed on BOTH PCs: used the lab version; yours saved to $b)"; return
    }
    # No record of this file on this PC (first restore with this script, or a file made here by hand).
    $b = Join-Path $backupRoot $relPkg
    Save-Copy $target $b
    Write-Target $target $desired $time
    $newState[$relPkg] = @($sh, $dh); $stats.replaced++; Log "REPLACED   $target   (no restore record on this PC; your copy saved to $b)"
}

function Sync-Tree([string]$srcRoot, [string]$dstRoot, [string]$prefix, [scriptblock]$rewriteRule, [bool]$keepHome) {
    if (-not (Test-Path -LiteralPath $srcRoot)) { Write-Host "  (not in this package: $prefix)" -ForegroundColor Yellow; return }
    $root = (Get-Item -LiteralPath $srcRoot).FullName.TrimEnd('\')
    foreach ($f in Get-ChildItem -LiteralPath $root -Recurse -File -Force) {
        $rel = $f.FullName.Substring($root.Length + 1)
        Sync-One $f.FullName (Join-Path $dstRoot $rel) ($prefix + '\' + $rel) ([bool](& $rewriteRule $rel $f)) $keepHome
    }
}
function Sync-One([string]$src, [string]$target, [string]$relPkg, [bool]$rewrite, [bool]$keepHome) {
    try { Sync-File $src $target $relPkg $rewrite $keepHome }
    catch {
        $stats.failed++
        Log "FAILED     $target   ($($_.Exception.Message))"
        Write-Host "  FAILED: $target - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# The Claude desktop app is an MSIX package: its %APPDATA%\Claude really lives in
# %LOCALAPPDATA%\Packages\Claude_*\LocalCache\Roaming\Claude. Write the session list there.
function Find-ClaudeAppData {
    $pk = Join-Path $env:LOCALAPPDATA 'Packages'
    $cands = @()
    if (Test-Path -LiteralPath $pk) {
        foreach ($d in Get-ChildItem -LiteralPath $pk -Directory -Filter 'Claude_*') {
            $c = Join-Path $d.FullName 'LocalCache\Roaming\Claude'
            if (Test-Path -LiteralPath $c) { $cands += $c }
        }
    }
    if ($cands.Count -eq 0) { return (Join-Path $env:APPDATA 'Claude') }
    if ($cands.Count -eq 1) { return $cands[0] }
    $best = $cands[0]; $bestTime = [datetime]::MinValue
    foreach ($c in $cands) {
        $t = [datetime]::MinValue
        foreach ($f in Get-ChildItem -LiteralPath $c -Recurse -File -ErrorAction SilentlyContinue) { if ($f.LastWriteTimeUtc -gt $t) { $t = $f.LastWriteTimeUtc } }
        if ($t -gt $bestTime) { $best = $c; $bestTime = $t }
    }
    return $best
}

$completed = $false
try {
    Log "restore $stamp   package $pkgName (made $pkgMade)   last restored here: $(if ($lastName) { $lastName } else { '(none)' })"
    if ($DryRun) { Log 'DRY RUN - nothing was changed'; Write-Host 'DRY RUN - nothing will be changed.' -ForegroundColor Yellow }
    Write-Host "Package:      $pkgName"
    Write-Host "Desktop:      $DesktopDir"
    if ($map.Count -gt 0) { Write-Host 'Old paths inside Claude data and docs will be rewritten for this PC.' -ForegroundColor Yellow }
    if ($state.Count -eq 0) { Write-Host 'No restore record on this PC yet: files that already exist and differ will be backed up, then replaced.' -ForegroundColor Yellow }
    Write-Host ''

    Write-Host '== 1. Project and other folders =='
    Sync-Tree (Join-Path $pkg 'project\PAM_controlProgram') $newProject 'project\PAM_controlProgram' {
        param($rel, $f) $f.Extension -eq '.md' -and ($rel -notmatch '\\' -or $rel -like 'docs\*')
    } $true
    $extra = Join-Path $pkg 'extra'
    if (Test-Path -LiteralPath $extra) {
        foreach ($d in Get-ChildItem -LiteralPath $extra -Directory) {
            Sync-Tree $d.FullName (Join-Path $DesktopDir $d.Name) ('extra\' + $d.Name) { param($rel, $f) $false } $true
        }
    }

    Write-Host '== 2. Claude Code memory, transcripts, attached photos =='
    Sync-Tree (Join-Path $pkg 'claude\projects') (Join-Path $UserProfileDir ".claude\projects\$newSlug") 'claude\projects' {
        param($rel, $f) $f.Extension -in '.jsonl', '.json', '.md', '.txt'
    } $false
    Sync-Tree (Join-Path $pkg 'claude\uploads') (Join-Path $UserProfileDir '.claude\uploads') 'claude\uploads' { param($rel, $f) $false } $false

    Write-Host '== 3. Claude desktop session list =='
    $srcMetaRoot = Join-Path $pkg 'claude\desktop-sessions'
    if (Test-Path -LiteralPath $srcMetaRoot) {
        if (-not $ClaudeAppData) { $ClaudeAppData = Find-ClaudeAppData }
        $dstMetaRoot = Join-Path $ClaudeAppData 'claude-code-sessions'
        Write-Host "  into $dstMetaRoot"
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
                    $rel = 'claude\desktop-sessions\' + $acctDir.Name + '\' + $orgDir.Name + '\' + $f.Name
                    Sync-One $f.FullName (Join-Path $dst $f.Name) $rel $true $false
                }
            }
        }
    } else {
        Write-Host '  (not in this package: claude\desktop-sessions)' -ForegroundColor Yellow
    }
    $completed = $true
} finally {
    if (-not $DryRun) {
        try {
            [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($StateFile))
            $out = New-Object Collections.Generic.List[string]
            if ($completed -or -not $lastMade) {
                $out.Add("#made`t$pkgMade"); $out.Add("#name`t$pkgName")
            } else {
                $out.Add("#made`t$lastMade"); $out.Add("#name`t$lastName")
            }
            $out.Add("#desktop`t$DesktopDir")
            foreach ($k in $newState.Keys) { $out.Add($k + "`t" + $newState[$k][0] + "`t" + $newState[$k][1]) }
            [IO.File]::WriteAllLines($StateFile + '.tmp', [string[]]$out, $utf8NoBom)
            Move-Item -LiteralPath ($StateFile + '.tmp') -Destination $StateFile -Force
        } catch { Write-Host "Could not save the restore record: $($_.Exception.Message)" -ForegroundColor Red; Log "STATE NOT SAVED: $($_.Exception.Message)" }
    }
    $summary = "added $($stats.added), updated $($stats.updated), unchanged $($stats.same), kept your edits $($stats.kept), " +
               "conflicts kept-yours $($stats.conflictKept), conflicts lab-version $($stats.conflictLab), " +
               "replaced (no record) $($stats.replaced), FAILED $($stats.failed)"
    if (-not $completed) { $summary += '   (STOPPED EARLY - see the error above; run it again)' }
    Log ''; Log "SUMMARY: $summary"
    $logW.Close()
    Write-Host ''
    Write-Host "Done: $summary" -ForegroundColor Green
    if (($stats.conflictLab + $stats.replaced) -gt 0 -and -not $DryRun) { Write-Host "Your previous copies of replaced files: $backupRoot" -ForegroundColor Yellow }
    if ($stats.conflictKept -gt 0 -and -not $DryRun) { Write-Host "Lab versions of files changed on BOTH PCs (merge by hand): $conflictRoot" -ForegroundColor Yellow }
    if ($stats.failed -gt 0) { Write-Host 'Some files FAILED (open in another program?). Close them and run this again.' -ForegroundColor Red }
    Write-Host "Log: $logFile"
}
Write-Host 'Open the Claude app -> Code tab; the PAM sessions should be in the sidebar.'
