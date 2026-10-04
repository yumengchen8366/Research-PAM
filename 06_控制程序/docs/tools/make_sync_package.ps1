# make_sync_package.ps1  -  run on the LAB PC to carry the current state to the other computer.
#
#   powershell -ExecutionPolicy Bypass -File docs\tools\make_sync_package.ps1
#
# Makes Desktop\PAM_sync_<date>_<time>.zip with:
#   project\PAM_controlProgram\      the project (CLAUDE.md, docs, LabviewPAM, Alazartech_sampleCode)
#   extra\Matlab\, extra\New folder\, extra\System_test_09_25\
#   extra\ATS-SDK-23.3.0\            ATS-SDK-Guide.pdf + Samples_MATLAB\Include (AlazarDefs.m etc., for reading the code)
#   claude\projects\                 Claude Code memory + all transcripts of this project
#   claude\desktop-sessions\         the desktop app's session list
#   changed_since_previous.txt       files that are new/changed since the previous package
#   restore.ps1, README_先看我.txt
# Not included: Control_py (22 GB), SDK7.30, SDK_NPT7.25 (large .dat), session-export-*.
# The previous package (newest PAM_sync_*.zip on the Desktop, or -PrevZip) is only read, never changed.

param(
    [string]$OutZip  = '',
    [string]$PrevZip = '',
    [string]$StageRoot = (Join-Path $env:TEMP 'PAM_sync_stage')
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$desktop = [Environment]::GetFolderPath('Desktop')
$project = Join-Path $desktop 'PAM_controlProgram'
$tools   = Join-Path $project 'docs\tools'
$slug    = $project -replace '[^A-Za-z0-9]', '-'
if (-not $OutZip) { $OutZip = Join-Path $desktop ('PAM_sync_{0:yyyy-MM-dd_HHmm}.zip' -f (Get-Date)) }
if (-not $PrevZip) {
    $p = Get-ChildItem -LiteralPath $desktop -Filter 'PAM_sync_*.zip' -File | Where-Object { $_.FullName -ne $OutZip } |
         Sort-Object LastWriteTime | Select-Object -Last 1
    if ($p) { $PrevZip = $p.FullName }
}
if (Test-Path -LiteralPath $OutZip) { throw "Output already exists: $OutZip" }

$stage = Join-Path $StageRoot 'PAM_sync'
if (Test-Path -LiteralPath $StageRoot) { Remove-Item -LiteralPath $StageRoot -Recurse -Force }
New-Item -ItemType Directory -Force $stage | Out-Null

function Copy-Tree([string]$src, [string]$dst) {
    if (-not (Test-Path -LiteralPath $src)) { Write-Host "  (missing, skipped) $src" -ForegroundColor Yellow; return }
    robocopy $src $dst /E /COPY:DT /DCOPY:T /XF '~$*' /NFL /NDL /NJH /NJS /NP | Out-Null   # ~$* = Office lock files
    if ($LASTEXITCODE -ge 8) { throw "robocopy failed ($LASTEXITCODE): $src -> $dst" }
    Write-Host "  $src"
}

Write-Host 'Staging...'
Copy-Tree $project (Join-Path $stage 'project\PAM_controlProgram')
foreach ($n in 'Matlab', 'New folder', 'System_test_09_25') { Copy-Tree (Join-Path $desktop $n) (Join-Path $stage "extra\$n") }
$sdk = 'C:\AlazarTech\ATS-SDK\23.3.0'
$sdkDst = Join-Path $stage 'extra\ATS-SDK-23.3.0'
Copy-Tree (Join-Path $sdk 'Samples_MATLAB\Include') (Join-Path $sdkDst 'Samples_MATLAB\Include')
if (Test-Path -LiteralPath (Join-Path $sdk 'ATS-SDK-Guide.pdf')) {
    Copy-Item -LiteralPath (Join-Path $sdk 'ATS-SDK-Guide.pdf') -Destination $sdkDst
}
Copy-Tree (Join-Path $env:USERPROFILE ".claude\projects\$slug") (Join-Path $stage 'claude\projects')
Copy-Tree (Join-Path $env:APPDATA 'Claude\claude-code-sessions') (Join-Path $stage 'claude\desktop-sessions')
Copy-Item -LiteralPath (Join-Path $tools 'restore.ps1') -Destination $stage
Copy-Item -LiteralPath (Join-Path $tools 'README_sync.txt') -Destination (Join-Path $stage 'README_先看我.txt')

# ---- what changed since the previous package (by content hash) ----
$sha = [Security.Cryptography.SHA256]::Create()
$prev = @{}
if ($PrevZip) {
    $z = [IO.Compression.ZipFile]::OpenRead($PrevZip)
    foreach ($e in $z.Entries) {
        if ($e.FullName.EndsWith('/') -or $e.FullName.EndsWith('\')) { continue }   # folder entries
        $rel = $e.FullName.Replace('/', '\')
        if ($rel.StartsWith('PAM_sync\')) { $rel = $rel.Substring(9) }
        $s = $e.Open(); try { $prev[$rel] = [BitConverter]::ToString($sha.ComputeHash($s)) } finally { $s.Close() }
    }
    $z.Dispose()
}
$changedList = New-Object Collections.Generic.List[string]
foreach ($f in Get-ChildItem -LiteralPath $stage -Recurse -File -Force) {
    $rel = $f.FullName.Substring($stage.Length).TrimStart('\')
    if ($rel -notmatch '\\') { continue }   # restore.ps1, README: not synced
    if (-not $prev.ContainsKey($rel)) { $changedList.Add($rel); continue }
    $s = [IO.File]::OpenRead($f.FullName)
    try { $h = [BitConverter]::ToString($sha.ComputeHash($s)) } finally { $s.Close() }
    if ($h -ne $prev[$rel]) { $changedList.Add($rel) }
}
$header = @("# Files new or changed on the lab PC since the previous package.",
            "# previous package: $(if ($PrevZip) { Split-Path $PrevZip -Leaf } else { '(none)' })",
            "# made: $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
if (-not $PrevZip) { $header += '*' }   # no previous package: treat every file as changed
[IO.File]::WriteAllLines((Join-Path $stage 'changed_since_previous.txt'), [string[]]($header + $changedList), (New-Object Text.UTF8Encoding($false)))

Write-Host 'Zipping...'
[IO.Compression.ZipFile]::CreateFromDirectory($stage, $OutZip, [IO.Compression.CompressionLevel]::Optimal, $true)
Remove-Item -LiteralPath $StageRoot -Recurse -Force
$mb = [math]::Round((Get-Item -LiteralPath $OutZip).Length / 1MB, 1)
Write-Host "Done: $OutZip ($mb MB). Changed since previous package: $($changedList.Count) files." -ForegroundColor Green
$changedList | ForEach-Object { "  $_" }
