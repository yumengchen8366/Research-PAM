# make_sync_package.ps1  -  run on the LAB PC to carry the current state to the other computer.
#
#   powershell -ExecutionPolicy Bypass -File docs\tools\make_sync_package.ps1
#
# Makes Desktop\PAM_sync_<date>_<time>.zip (contents: see README_sync.txt). Every package carries
# package_info.txt (name, time made) and manifest.tsv (SHA-256 of every file). restore.ps1 compares
# them with what the other PC itself received last time, so packages can be skipped or deleted freely.
# Not included: Control_py data/environments (DATA_ts, PA_data, *.bin, .venv ...), SDK7.30, SDK_NPT7.25.
# This file is ASCII-only on purpose (Windows PowerShell 5.1 misreads UTF-8 scripts without a BOM).

param(
    [string]$OutZip         = '',
    [switch]$NoUploads,                                                    # leave out photos attached in the Code tab
    [switch]$Lite,                                                         # small package: no LabviewPAM, transcripts, photos, session list
    [string]$DesktopDir     = [Environment]::GetFolderPath('Desktop'),     # testing only: a fake lab tree
    [string]$UserProfileDir = $env:USERPROFILE,                            # testing only
    [string]$ClaudeAppData  = '',                                          # testing only (default: auto-detect)
    [string]$SdkDir         = 'C:\AlazarTech\ATS-SDK\23.3.0'
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$now     = Get-Date
$project = Join-Path $DesktopDir 'PAM_controlProgram'
$tools   = Join-Path $project 'docs\tools'
$slug    = $project -replace '[^A-Za-z0-9]', '-'
if (-not $OutZip) { $OutZip = Join-Path $DesktopDir ('PAM_sync_{0}{1:yyyy-MM-dd_HHmm}.zip' -f $(if ($Lite) { 'lite_' } else { '' }), $now) }
$OutZip  = [IO.Path]::GetFullPath($OutZip)
$partial = $OutZip + '.partial'      # renamed to $OutZip only after the zip is complete
if (Test-Path -LiteralPath $OutZip) { throw "Output already exists: $OutZip" }
[void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($OutZip))

# The Claude desktop app is an MSIX package: its %APPDATA%\Claude really lives in
# %LOCALAPPDATA%\Packages\Claude_*\LocalCache\Roaming\Claude, which a normal PowerShell window
# cannot see under %APPDATA%. Look there first.
function Find-ClaudeAppData {
    $best = $null; $bestTime = [datetime]::MinValue
    $pk = Join-Path $env:LOCALAPPDATA 'Packages'
    $cands = @()
    if (Test-Path -LiteralPath $pk) {
        foreach ($d in Get-ChildItem -LiteralPath $pk -Directory -Filter 'Claude_*') {
            $cands += (Join-Path $d.FullName 'LocalCache\Roaming\Claude')
        }
    }
    $cands += (Join-Path $env:APPDATA 'Claude')      # non-MSIX install (inside the app this is the same folder)
    foreach ($c in $cands) {
        $s = Join-Path $c 'claude-code-sessions'
        if (-not (Test-Path -LiteralPath $s)) { continue }
        $t = [datetime]::MinValue
        foreach ($f in Get-ChildItem -LiteralPath $s -Recurse -File) { if ($f.LastWriteTimeUtc -gt $t) { $t = $f.LastWriteTimeUtc } }
        if ($null -eq $best -or $t -gt $bestTime) { $best = $c; $bestTime = $t }
    }
    return $best
}

$sha = [Security.Cryptography.SHA256]::Create()
function Get-FileHashHex([string]$p) {
    $s = [IO.File]::OpenRead($p)
    try { return [BitConverter]::ToString($sha.ComputeHash($s)).Replace('-', '') } finally { $s.Close() }
}

function Copy-Tree([string]$src, [string]$dst, [string[]]$xd = @(), [string[]]$xf = @(), [switch]$Required) {
    if (-not (Test-Path -LiteralPath $src)) {
        if ($Required) { throw "Required folder is missing: $src" }
        Write-Host "  (missing, skipped) $src" -ForegroundColor Yellow
        return
    }
    $rc = @($src, $dst, '/E', '/COPY:DT', '/DCOPY:T', '/XF', '~$*') + $xf     # ~$* = Office lock files
    if ($xd.Count -gt 0) { $rc += '/XD'; $rc += $xd }
    $rc += @('/NFL', '/NDL', '/NJH', '/NJS', '/NP')
    & robocopy @rc | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy failed ($LASTEXITCODE): $src -> $dst" }
    Write-Host "  $src"
}

# A fresh, unique staging folder; only this folder is ever deleted.
$stageRoot = Join-Path ([IO.Path]::GetTempPath()) ('PAM_sync_stage_{0:yyyyMMdd_HHmmss_fff}' -f $now)
if (Test-Path -LiteralPath $stageRoot) { throw "Staging folder already exists: $stageRoot" }
$stage = Join-Path $stageRoot 'PAM_sync'
[void][IO.Directory]::CreateDirectory($stage)

try {
    Write-Host 'Collecting...'
    $projXd = @(); if ($Lite) { $projXd = @('LabviewPAM') }
    Copy-Tree $project (Join-Path $stage 'project\PAM_controlProgram') -xd $projXd -Required
    foreach ($n in 'Matlab', 'New folder', 'System_test_09_25') {
        Copy-Tree (Join-Path $DesktopDir $n) (Join-Path $stage "extra\$n")
    }
    # Classmate's Python code only (the data and Python environments are ~22 GB).
    Copy-Tree (Join-Path $DesktopDir 'Control_py') (Join-Path $stage 'extra\Control_py') `
        -xd @('.venv', '.uv-cache', '.uv-python', '.tools', '__pycache__', '.git', 'DATA_ts', 'PA_data') `
        -xf @('*.bin', '*.npy', '*.dat', '*.h5', '*.mat')
    $sdkDst = Join-Path $stage 'extra\ATS-SDK-23.3.0'
    Copy-Tree (Join-Path $SdkDir 'Samples_MATLAB\Include') (Join-Path $sdkDst 'Samples_MATLAB\Include')
    $guide = Join-Path $SdkDir 'ATS-SDK-Guide.pdf'
    if (Test-Path -LiteralPath $guide) { Copy-Item -LiteralPath $guide -Destination $sdkDst }

    $projDir = Join-Path $UserProfileDir ".claude\projects\$slug"
    if ($Lite) {
        # memory only: transcripts, photos and the sidebar session list go in the full package
        Copy-Tree (Join-Path $projDir 'memory') (Join-Path $stage 'claude\projects\memory') -Required
    } else {
        Copy-Tree $projDir (Join-Path $stage 'claude\projects') -Required
        if (-not $NoUploads) {
            foreach ($j in Get-ChildItem -LiteralPath $projDir -Filter '*.jsonl' -File) {
                $up = Join-Path $UserProfileDir ".claude\uploads\$($j.BaseName)"
                if (Test-Path -LiteralPath $up) { Copy-Tree $up (Join-Path $stage "claude\uploads\$($j.BaseName)") }
            }
        }
        if (-not $ClaudeAppData) { $ClaudeAppData = Find-ClaudeAppData }
        if (-not $ClaudeAppData) {
            throw "Cannot find the Claude app's session list (claude-code-sessions). Open the Claude app's Code tab once, then run this again."
        }
        Copy-Tree (Join-Path $ClaudeAppData 'claude-code-sessions') (Join-Path $stage 'claude\desktop-sessions') -Required
    }

    Copy-Item -LiteralPath (Join-Path $tools 'restore.ps1') -Destination $stage
    $readme = 'README_' + [char]0x5148 + [char]0x770B + [char]0x6211 + '.txt'     # README_xian-kan-wo.txt
    Copy-Item -LiteralPath (Join-Path $tools 'README_sync.txt') -Destination (Join-Path $stage $readme)

    # ---- manifest: SHA-256 of every synced file (keys = path inside the package) ----
    $utf8 = New-Object Text.UTF8Encoding($false)
    $lines = New-Object Collections.Generic.List[string]
    $files = @(Get-ChildItem -LiteralPath $stage -Recurse -File -Force)
    foreach ($f in $files) {
        $rel = $f.FullName.Substring($stage.Length + 1)
        if ($rel -notmatch '\\') { continue }      # restore.ps1 and README are not synced
        $lines.Add($rel + "`t" + (Get-FileHashHex $f.FullName))
    }
    [IO.File]::WriteAllLines((Join-Path $stage 'manifest.tsv'), [string[]]$lines, $utf8)
    [IO.File]::WriteAllLines((Join-Path $stage 'package_info.txt'),
        [string[]]@("name=$(Split-Path $OutZip -Leaf)", "made=$($now.ToString('yyyyMMddHHmmss'))", "files=$($lines.Count)", "lite=$([int][bool]$Lite)"), $utf8)

    # ---- zip (entry names use '/', as the zip format requires) ----
    Write-Host 'Zipping...'
    if (Test-Path -LiteralPath $partial) { Remove-Item -LiteralPath $partial -Force }   # left over from an interrupted run
    $fs = New-Object IO.FileStream($partial, [IO.FileMode]::CreateNew)
    try {
        $za = New-Object IO.Compression.ZipArchive($fs, [IO.Compression.ZipArchiveMode]::Create)
        try {
            foreach ($f in Get-ChildItem -LiteralPath $stage -Recurse -File -Force) {
                $name = 'PAM_sync/' + $f.FullName.Substring($stage.Length + 1).Replace('\', '/')
                [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($za, $f.FullName, $name, [IO.Compression.CompressionLevel]::Optimal)
            }
        } finally { $za.Dispose() }
    } finally { $fs.Dispose() }
    Move-Item -LiteralPath $partial -Destination $OutZip

    $mb = [math]::Round((Get-Item -LiteralPath $OutZip).Length / 1MB, 1)
    Write-Host "Done: $OutZip ($mb MB, $($lines.Count) files)." -ForegroundColor Green
    foreach ($g in $files | Where-Object { $_.FullName.Substring($stage.Length + 1) -match '\\' } |
                   Group-Object { ($_.FullName.Substring($stage.Length + 1) -split '\\')[0..1] -join '\' }) {
        "  {0,-40} {1,5} files {2,8:N1} MB" -f $g.Name, $g.Count, (($g.Group | Measure-Object Length -Sum).Sum / 1MB)
    }
} finally {
    if (Test-Path -LiteralPath $stageRoot) { Remove-Item -LiteralPath $stageRoot -Recurse -Force }
}
