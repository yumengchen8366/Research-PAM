# pam_sync.ps1  -  two-way sync of the PAM project through a private GitHub repo.
#
# Run it when you START and when you FINISH working, on any PC, under any Claude account:
#   double-click sync_pam.cmd in the project folder
#   or:  powershell -ExecutionPolicy Bypass -File docs\tools\pam_sync.ps1 [-ImportSidebar] [-NoPush]
#
# Steps
#   1. copy this PC's Claude transcripts, attached photos and sidebar entries INTO the repo (claude\...)
#   2. commit everything that changed (docs, Matlab, memory, ...)
#   3. fetch from GitHub and merge
#   4. copy transcripts and photos from the repo INTO this PC's Claude folder (%USERPROFILE%\.claude)
#      -ImportSidebar: also add the sessions to the desktop-app sidebar of the account signed in NOW
#                      (quit the Claude app first: tray icon -> Quit)
#   5. push to GitHub
#
# Memory is not copied: %USERPROFILE%\.claude\projects\<project>\memory is a junction to claude\memory
# (made by setup_git_sync.ps1), so git sees it directly.
#
# Claude files are compared with what this PC synced last time (%LOCALAPPDATA%\PAM_sync\git_state_*.tsv):
#   only one side changed                 -> that side wins
#   both changed, one continues the other -> the longer one wins (transcripts only ever grow)
#   both changed differently              -> nothing is overwritten; this PC's copy goes to
#                                            claude\conflicts\<PC name>\ in the repo, and a warning is shown
# Paths inside Claude data are stored in the repo as on the lab PC (C:\Users\2031\...) and rewritten for this PC.
# This file is ASCII-only on purpose (Windows PowerShell 5.1 misreads UTF-8 scripts without a BOM).

param(
    [switch]$ImportSidebar,
    [string]$SidebarFolder  = '',                                          # default: the account folder the app wrote to last
    [switch]$NoPush,
    [switch]$NoPull,                                                       # offline: only commit locally
    [string]$DesktopDir     = [Environment]::GetFolderPath('Desktop'),
    [string]$UserProfileDir = $env:USERPROFILE,
    [string]$ClaudeAppData  = '',                                          # default: auto-detect (MSIX-aware)
    [string]$StateFile      = '',
    [switch]$SkipAppCheck                                                  # testing only
)
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch { }

$repo  = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path.TrimEnd('\')
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$pc    = $env:COMPUTERNAME
$utf8  = New-Object Text.UTF8Encoding($false)
$sha   = [Security.Cryptography.SHA256]::Create()
$maxBytes = 90MB                                                           # GitHub refuses files over 100 MB

# ---------- git ----------
function Find-Git {
    $c = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    foreach ($p in (Join-Path $env:ProgramFiles 'Git\cmd\git.exe'), (Join-Path $env:LOCALAPPDATA 'Programs\Git\cmd\git.exe')) {
        if (Test-Path -LiteralPath $p) { return $p }
    }
    throw 'Git is not installed. Install it (winget install --id Git.Git -e), then run this again.'
}
$gitExe = Find-Git
$script:gitCode = 0
function Invoke-Git {
    $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try { $out = & $gitExe -C $repo @args 2>&1 | ForEach-Object { "$_" } }
    finally { $ErrorActionPreference = $old }
    $script:gitCode = $LASTEXITCODE
    return $out
}
function Show([object[]]$lines) { foreach ($l in $lines) { if ("$l".Trim()) { Write-Host "    $l" } } }

if (-not (Test-Path -LiteralPath (Join-Path $repo '.git'))) {
    Write-Host "$repo is not a git repository yet. Run docs\tools\setup_git_sync.ps1 first." -ForegroundColor Red
    exit 1
}

# ---------- paths: this PC <-> repo (lab PC) ----------
$canonDesktop = 'C:\Users\2031\Desktop'
$canonHome    = 'C:\Users\2031'
$canonProject = 'C:\Users\2031\Desktop\PAM_controlProgram'
function Get-Slug([string]$p) { return ($p -replace '[^A-Za-z0-9]', '-') }   # Claude Code's per-project folder name
$localSlug = Get-Slug $repo
$canonSlug = Get-Slug $canonProject

function New-PathMap([object[]]$pairs) {
    $m = @{}
    foreach ($pr in $pairs) {
        $a = $pr[0].TrimEnd('\'); $b = $pr[1].TrimEnd('\')
        if ($a -eq $b) { continue }
        $m[$a.Replace('\', '\\')] = $b.Replace('\', '\\')                    # as written inside JSON
        $m[$a] = $b
    }
    $pat = (@($m.Keys) | Sort-Object Length -Descending | ForEach-Object { [regex]::Escape($_) }) -join '|'
    return @{ map = $m; pattern = $pat }
}
$toRepo  = New-PathMap @(@($repo, $canonProject), @($DesktopDir, $canonDesktop), @($UserProfileDir, $canonHome), @($localSlug, $canonSlug))
$toLocal = New-PathMap @(@($canonProject, $repo), @($canonDesktop, $DesktopDir), @($canonHome, $UserProfileDir), @($canonSlug, $localSlug))

$script:curMap = $null
function Convert-Bytes([byte[]]$bytes, $pm) {
    if ($pm.map.Count -eq 0) { return , $bytes }
    $text = $utf8.GetString($bytes)
    $script:curMap = $pm.map
    $new = [regex]::Replace($text, $pm.pattern, { param($x) $script:curMap[$x.Value] })
    if ($new -ceq $text) { return , $bytes }
    return , $utf8.GetBytes($new)
}
function Convert-Text([string]$text, $pm) {
    if ($pm.map.Count -eq 0) { return $text }
    $script:curMap = $pm.map
    return [regex]::Replace($text, $pm.pattern, { param($x) $script:curMap[$x.Value] })
}

function Get-Hash([byte[]]$b) { return [BitConverter]::ToString($sha.ComputeHash($b)).Replace('-', '') }
# $short is the beginning of $long?
function Test-Prefix([byte[]]$short, [byte[]]$long) {
    if ($short.Length -gt $long.Length) { return $false }
    $h1 = [BitConverter]::ToString($sha.ComputeHash($long, 0, $short.Length))
    $h2 = [BitConverter]::ToString($sha.ComputeHash($short))
    return $h1 -eq $h2
}
# A transcript may be half-written right now: keep only complete lines.
function Get-CompleteLines([byte[]]$b) {
    $i = [Array]::LastIndexOf($b, [byte]10)
    if ($i -eq $b.Length - 1) { return , $b }
    $n = $i + 1
    $c = New-Object byte[] $n
    if ($n -gt 0) { [Array]::Copy($b, $c, $n) }
    return , $c
}
function Write-Bytes([string]$path, [byte[]]$b) {
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path))
    [IO.File]::WriteAllBytes($path, $b)
}

# ---------- what this PC synced last time ----------
if (-not $StateFile) { $StateFile = Join-Path $env:LOCALAPPDATA "PAM_sync\git_state_$localSlug.tsv" }
$state = @{}
if (Test-Path -LiteralPath $StateFile) {
    foreach ($l in [IO.File]::ReadAllLines($StateFile, [Text.Encoding]::UTF8)) {
        $p = $l.Split("`t"); if ($p.Count -eq 2) { $state[$p[0]] = $p[1] }
    }
}
function Save-State {
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($StateFile))
    $out = foreach ($k in $state.Keys) { $k + "`t" + $state[$k] }
    [IO.File]::WriteAllLines($StateFile + '.tmp', [string[]]@($out), $utf8)
    Move-Item -LiteralPath ($StateFile + '.tmp') -Destination $StateFile -Force
}

$stats = @{ exported = 0; imported = 0; conflicts = 0; tooBig = 0; failed = 0 }
$textExt = @('.jsonl', '.json', '.md', '.txt', '.js')

# One Claude file. $key = path inside the repo. $dir = 'export' (this PC -> repo) or 'import' (repo -> this PC).
function Sync-ClaudeFile([string]$key, [string]$localPath, [string]$repoPath, [string]$dir, [bool]$rewrite) {
    $ext = [IO.Path]::GetExtension($localPath).ToLower()
    $isText = $rewrite -and ($textExt -contains $ext)
    $L = $null; $R = $null
    if ([IO.File]::Exists($localPath)) {
        $lb = [IO.File]::ReadAllBytes($localPath)
        if ($ext -eq '.jsonl') { $lb = Get-CompleteLines $lb }
        if ($isText) { $L = Convert-Bytes $lb $toRepo } else { $L = $lb }
    }
    if ([IO.File]::Exists($repoPath)) { $R = [IO.File]::ReadAllBytes($repoPath) }
    if ($null -eq $L -and $null -eq $R) { return }
    $lh = $null; $rh = $null
    if ($null -ne $L) { $lh = Get-Hash $L }
    if ($null -ne $R) { $rh = Get-Hash $R }
    if ($lh -eq $rh) { $state[$key] = $lh; return }
    $base = $state[$key]

    if ($dir -eq 'export') {
        if ($null -eq $L) { return }                                       # only in the repo: import handles it
        if ($L.Length -gt $maxBytes) {
            $stats.tooBig++; Write-Host "  TOO BIG for GitHub, not synced (use the zip package): $localPath" -ForegroundColor Yellow; return
        }
        if ($null -eq $R -or ($base -and $rh -eq $base) -or (Test-Prefix $R $L)) {
            Write-Bytes $repoPath $L; $state[$key] = $lh; $stats.exported++; return
        }
        if (($base -and $lh -eq $base) -or (Test-Prefix $L $R)) { return }  # the repo has the newer version
        $c = Join-Path $repo ("claude\conflicts\$pc\" + $key.Substring(7))   # key starts with 'claude\'
        Write-Bytes $c $L
        $stats.conflicts++
        Write-Host "  CONFLICT (changed on this PC AND elsewhere): $key" -ForegroundColor Yellow
        Write-Host "    kept both: this PC's copy is also saved as $c" -ForegroundColor Yellow
        return
    }

    # import
    if ($null -eq $R) { return }
    if ($null -eq $L -or ($base -and $lh -eq $base) -or (Test-Prefix $L $R)) {
        if ($isText) { $out = Convert-Bytes $R $toLocal } else { $out = $R }
        Write-Bytes $localPath $out; $state[$key] = $rh; $stats.imported++; return
    }
    # repo unchanged, or this PC's copy continues it, or a conflict already reported at export: keep this PC's copy
}

function Get-RelFiles([string]$root, [string[]]$skipTop = @()) {
    $res = @()
    if (-not (Test-Path -LiteralPath $root)) { return $res }
    $r = (Get-Item -LiteralPath $root -Force).FullName.TrimEnd('\')
    foreach ($f in Get-ChildItem -LiteralPath $r -Recurse -File -Force) {
        $rel = $f.FullName.Substring($r.Length + 1)
        $top = ($rel -split '\\')[0]
        if ($skipTop | Where-Object { $top -like $_ }) { continue }
        $res += $rel
    }
    return $res
}

$localProj = Join-Path $UserProfileDir ".claude\projects\$localSlug"
$localUp   = Join-Path $UserProfileDir '.claude\uploads'
$repoTr    = Join-Path $repo 'claude\transcripts'
$repoUp    = Join-Path $repo 'claude\uploads'
$repoSide  = Join-Path $repo 'claude\desktop-sessions'

function Sync-AllClaude([string]$dir) {
    # transcripts, sub-agent logs, tool results (everything in the project folder except memory)
    $rels = if ($dir -eq 'export') { Get-RelFiles $localProj @('memory', 'memory_before_git_*') } else { Get-RelFiles $repoTr }
    foreach ($rel in $rels) {
        try { Sync-ClaudeFile ('claude\transcripts\' + $rel) (Join-Path $localProj $rel) (Join-Path $repoTr $rel) $dir $true }
        catch { $stats.failed++; Write-Host "  FAILED: $rel - $($_.Exception.Message)" -ForegroundColor Red }
    }
    # photos attached in these sessions: .claude\uploads\<session id>\...
    $ids = @{}
    foreach ($d in @($localProj, $repoTr)) {
        if (Test-Path -LiteralPath $d) { foreach ($j in Get-ChildItem -LiteralPath $d -Filter '*.jsonl' -File) { $ids[$j.BaseName] = 1 } }
    }
    foreach ($id in $ids.Keys) {
        $rels = if ($dir -eq 'export') { Get-RelFiles (Join-Path $localUp $id) } else { Get-RelFiles (Join-Path $repoUp $id) }
        foreach ($rel in $rels) {
            $r2 = "$id\$rel"
            try { Sync-ClaudeFile ('claude\uploads\' + $r2) (Join-Path $localUp $r2) (Join-Path $repoUp $r2) $dir $false }
            catch { $stats.failed++; Write-Host "  FAILED: $r2 - $($_.Exception.Message)" -ForegroundColor Red }
        }
    }
}

# ---------- desktop-app sidebar entries (claude-code-sessions\<account>\<org>\local_*.json) ----------
function Find-ClaudeAppData {
    $pk = Join-Path $env:LOCALAPPDATA 'Packages'
    $cands = @()
    if (Test-Path -LiteralPath $pk) {
        foreach ($d in Get-ChildItem -LiteralPath $pk -Directory -Filter 'Claude_*') { $cands += (Join-Path $d.FullName 'LocalCache\Roaming\Claude') }
    }
    $cands += (Join-Path $env:APPDATA 'Claude')
    foreach ($c in $cands) { if (Test-Path -LiteralPath (Join-Path $c 'claude-code-sessions')) { return $c } }
    return $null
}
function Get-JsonField([string]$text, [string]$name) {
    $m = [regex]::Match($text, '"' + $name + '"\s*:\s*("((?:[^"\\]|\\.)*)"|-?\d+)')
    if (-not $m.Success) { return $null }
    if ($m.Groups[2].Success) { return $m.Groups[2].Value.Replace('\\', '\') }
    return $m.Groups[1].Value
}
function Get-Activity([string]$text) { $v = Get-JsonField $text 'lastActivityAt'; if ($v) { return [int64]$v } else { return [int64]0 } }
function Get-SessionDirs([string]$sessRoot) {
    $res = @()
    if (Test-Path -LiteralPath $sessRoot) {
        foreach ($a in Get-ChildItem -LiteralPath $sessRoot -Directory) { $res += @(Get-ChildItem -LiteralPath $a.FullName -Directory) }
    }
    return $res
}
function Test-ThisProject([string]$cwd) {
    if (-not $cwd) { return $false }
    $c = $cwd.TrimEnd('\')
    return ($c -eq $repo) -or $c.StartsWith($repo + '\', [StringComparison]::OrdinalIgnoreCase)
}

function Export-Sidebar {
    if (-not $ClaudeAppData) { $script:ClaudeAppData = Find-ClaudeAppData }
    if (-not $ClaudeAppData) { Write-Host '  (Claude desktop app data not found; sidebar entries skipped)' -ForegroundColor Yellow; return }
    $best = @{}
    foreach ($d in Get-SessionDirs (Join-Path $ClaudeAppData 'claude-code-sessions')) {
        foreach ($f in Get-ChildItem -LiteralPath $d.FullName -Filter 'local_*.json' -File) {
            $t = [IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8)
            if (-not (Test-ThisProject (Get-JsonField $t 'cwd'))) { continue }
            $act = Get-Activity $t
            if (-not $best.ContainsKey($f.Name) -or $act -gt $best[$f.Name][0]) { $best[$f.Name] = @($act, $t) }
        }
    }
    foreach ($n in $best.Keys) {
        $rp = Join-Path $repoSide $n
        if ((Test-Path -LiteralPath $rp) -and ((Get-Activity ([IO.File]::ReadAllText($rp, [Text.Encoding]::UTF8))) -ge $best[$n][0])) { continue }
        Write-Bytes $rp ($utf8.GetBytes((Convert-Text $best[$n][1] $toRepo)))
        $stats.exported++
    }
}

function Import-Sidebar {
    if (-not (Test-Path -LiteralPath $repoSide)) { Write-Host '  (no sidebar entries in the repo yet)'; return }
    if (-not $SkipAppCheck -and (Get-Process -Name 'claude' -ErrorAction SilentlyContinue)) {
        Write-Host '  The Claude app is running: sidebar NOT updated. Quit it (tray icon -> Quit), then run: sync_pam_sidebar.cmd' -ForegroundColor Yellow
        return
    }
    $target = $SidebarFolder
    if (-not $target) {
        if (-not $ClaudeAppData) { $script:ClaudeAppData = Find-ClaudeAppData }
        $newest = $null; $nt = [datetime]::MinValue
        if ($ClaudeAppData) {
            foreach ($d in Get-SessionDirs (Join-Path $ClaudeAppData 'claude-code-sessions')) {
                $t = $d.LastWriteTimeUtc
                foreach ($f in Get-ChildItem -LiteralPath $d.FullName -File) { if ($f.LastWriteTimeUtc -gt $t) { $t = $f.LastWriteTimeUtc } }
                if ($t -gt $nt) { $nt = $t; $newest = $d.FullName }
            }
        }
        if (-not $newest) { Write-Host '  No account folder yet: sign in to the Claude app, open the Code tab once, quit, run again.' -ForegroundColor Yellow; return }
        $target = $newest
    }
    Write-Host "  into $target"
    Write-Host '  (the account folder the app used most recently; if that is the wrong account, pass -SidebarFolder <folder>)'
    $n = 0
    foreach ($f in Get-ChildItem -LiteralPath $repoSide -Filter 'local_*.json' -File) {
        $t = Convert-Text ([IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8)) $toLocal
        $t = [regex]::Replace($t, '"bridgeSessionIds"\s*:\s*\[[^\]]*\]', '"bridgeSessionIds":[]')   # Remote Control links belong to the old account
        $lp = Join-Path $target $f.Name
        if ((Test-Path -LiteralPath $lp) -and ((Get-Activity ([IO.File]::ReadAllText($lp, [Text.Encoding]::UTF8))) -ge (Get-Activity $t))) { continue }
        Write-Bytes $lp ($utf8.GetBytes($t)); $n++
    }
    Write-Host "  $n sidebar entries added or updated."
}

# ================= run =================
$exitCode = 0
try {
    Write-Host "PAM sync on $pc   repo: $repo"
    $unmerged = @(Invoke-Git diff --name-only --diff-filter=U)
    if ($unmerged.Count -gt 0) {
        foreach ($p in $unmerged) { Write-Host "    $p" -ForegroundColor Red }
        throw 'an earlier merge still has unresolved conflicts (files above). Fix them first, or: git merge --abort'
    }
    Write-Host '== 1. Claude data of this PC -> repo =='
    Sync-AllClaude 'export'
    try { Export-Sidebar } catch { $stats.failed++; Write-Host "  sidebar export FAILED: $($_.Exception.Message)" -ForegroundColor Red }
    Save-State

    Write-Host '== 2. commit =='
    # Big data files (e.g. future C-scan .mat) would make every push fail: keep NEW ones out of git (this PC only).
    $excl = Join-Path $repo '.git\info\exclude'
    foreach ($l in @(Invoke-Git status --porcelain -uall)) {
        if ($l.Length -lt 4) { continue }
        $code = $l.Substring(0, 2); $p = $l.Substring(3)
        if ($p -like '* -> *') { $p = ($p -split ' -> ')[1] }
        $p = $p.Trim('"')
        $fp = Join-Path $repo $p.Replace('/', '\')
        if (-not (Test-Path -LiteralPath $fp -PathType Leaf)) { continue }
        if ((Get-Item -LiteralPath $fp).Length -le $maxBytes) { continue }
        if ($code -ne '??') { throw "$p is over 90 MB and already in git: GitHub would refuse the push. Ask Claude how to move it out." }
        [void][IO.Directory]::CreateDirectory((Split-Path $excl -Parent))
        [IO.File]::AppendAllText($excl, "/$p`n", $utf8)
        $stats.tooBig++
        Write-Host "  TOO BIG for GitHub, kept on this PC only (copy it by OneDrive/USB): $p" -ForegroundColor Yellow
    }
    $o = Invoke-Git add -A
    if ($script:gitCode -ne 0) { Show $o; throw 'git add failed (see above; a file open in another program?)' }
    $changes = @(Invoke-Git status --porcelain)
    if ($changes.Count -gt 0) {
        Write-Host "  $($changes.Count) changed files"
        Show (Invoke-Git commit -q -m "sync from $pc $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
        if ($script:gitCode -ne 0) { throw 'git commit failed' }
    } else { Write-Host '  nothing new on this PC' }

    $branch = (Invoke-Git rev-parse --abbrev-ref HEAD | Select-Object -First 1)
    $hasRemote = @(Invoke-Git remote) -contains 'origin'
    if (-not $hasRemote) { Write-Host '  (no GitHub remote yet: committed locally only. Run setup_git_sync.ps1 -RemoteUrl ...)' -ForegroundColor Yellow }

    Write-Host '== 3. fetch + merge from GitHub =='
    if ($hasRemote -and -not $NoPull) {
        Show (Invoke-Git fetch origin)
        if ($script:gitCode -ne 0) { throw 'git fetch failed (offline? not signed in to GitHub?)' }
        [void](Invoke-Git rev-parse --verify -q "origin/$branch")
        if ($script:gitCode -eq 0) {
            Show (Invoke-Git merge --no-edit "origin/$branch")
            if ($script:gitCode -ne 0) {
                $conf = @(Invoke-Git diff --name-only --diff-filter=U)
                $other = @()
                foreach ($p in $conf) {
                    if ($p -like 'claude/*') {
                        # Claude data changed on both PCs: keep this PC's version, save the other one beside it
                        $save = Join-Path $repo ("claude\conflicts\merge_$stamp\" + $p.Substring(7).Replace('/', '\'))
                        [void](Invoke-Git checkout --theirs -- $p)
                        if ($script:gitCode -eq 0) { Write-Bytes $save ([IO.File]::ReadAllBytes((Join-Path $repo $p.Replace('/', '\')))) }
                        [void](Invoke-Git checkout --ours -- $p)
                        [void](Invoke-Git add -- $p)
                        $stats.conflicts++
                        Write-Host "  CONFLICT in $p : kept this PC's version, the other one saved to $save" -ForegroundColor Yellow
                    } else { $other += $p }
                }
                if ($other.Count -gt 0) {
                    Write-Host '  MERGE CONFLICT in these files (changed on both PCs):' -ForegroundColor Red
                    foreach ($p in $other) { Write-Host "    $p" -ForegroundColor Red }
                    Write-Host '  Fix them (or ask Claude: "resolve the git merge conflicts"), then run this again.' -ForegroundColor Red
                    Write-Host '  To cancel the merge instead:  git merge --abort' -ForegroundColor Red
                    throw 'merge stopped at the conflicts listed above (nothing was pushed)'
                }
                [void](Invoke-Git add -A)
                Show (Invoke-Git commit -q --no-edit)
                if ($script:gitCode -ne 0) { throw 'git commit after merge failed' }
            }
        } else { Write-Host '  (GitHub repo is still empty)' }
    } else { Write-Host '  skipped' }

    Write-Host '== 4. repo -> Claude data of this PC =='
    Sync-AllClaude 'import'
    Save-State
    if ($ImportSidebar) { Import-Sidebar } else { Write-Host '  (sidebar not touched; to show the sessions in the app sidebar: quit Claude, run sync_pam_sidebar.cmd)' }

    Write-Host '== 5. push to GitHub =='
    if ($hasRemote -and -not $NoPush) {
        Show (Invoke-Git push -u origin $branch)
        if ($script:gitCode -ne 0) { throw 'git push failed (see above)' }
    } else { Write-Host '  skipped' }
} catch {
    $exitCode = 1
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    try { Save-State } catch { Write-Host "Could not save the sync record: $($_.Exception.Message)" -ForegroundColor Red }
    Write-Host ''
    $msg = "Claude files: exported $($stats.exported), imported $($stats.imported), conflicts $($stats.conflicts), too big $($stats.tooBig), failed $($stats.failed)"
    if ($exitCode -eq 0) { Write-Host "Done. $msg" -ForegroundColor Green } else { Write-Host "NOT finished. $msg" -ForegroundColor Red }
}
exit $exitCode
