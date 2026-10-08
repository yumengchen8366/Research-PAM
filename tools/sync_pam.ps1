# 一键同步 Research-PAM（Windows）。由仓库根目录的 sync_pam.cmd 调用，开工、收工各双击一次。
# 顺序：导出本机有更新的 Claude 会话 → commit → 从 GitHub 取回并合并（merge）→ 重建对话索引 → push。
# 合并有冲突时不会推送，也不会自己选版本：停下来，列出冲突文件，交给 Claude 逐段对比。
$ErrorActionPreference = "Continue"
$Repo = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $Repo
$git = (Get-Command git -ErrorAction SilentlyContinue).Source
if (-not $git) { $git = Join-Path $env:LOCALAPPDATA "Programs\Git\cmd\git.exe" }
$Machine = if ($env:COMPUTERNAME -eq "CAOLAB1") { "LabPC" } else { $env:COMPUTERNAME }
function Stop-Sync([string]$msg) { Write-Host "`n$msg" -ForegroundColor Red; exit 1 }

if (Test-Path -LiteralPath (Join-Path $Repo ".git\MERGE_HEAD")) {
    Stop-Sync "上一次合并还没解决完（有冲突）。在 Claude Code 里打开 Research-PAM，说：sync 有冲突，帮我逐段对比合并。"
}

Write-Host "[1/5] 导出本机有更新的 Claude 会话" -ForegroundColor Cyan
$slug = $Repo -replace '[^A-Za-z0-9]', '-'
$src = Join-Path $HOME ".claude\projects\$slug"
if (Test-Path -LiteralPath $src) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "export_pam_chats.ps1") -Src $src -All -Changed -Machine $Machine
} else { Write-Host "  （本机还没有在 Research-PAM 里开过 Claude Code 会话）" }

Write-Host "[2/5] 提交本机改动" -ForegroundColor Cyan
& $git add -A
& $git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
    & $git commit -q -m "$(Get-Date -Format 'yyyy-MM-dd HH:mm') sync from $Machine"
    & $git log -1 --format="  %h %s"
} else { Write-Host "  没有改动" }

Write-Host "[3/5] 取回 GitHub 上的新内容并合并" -ForegroundColor Cyan
& $git fetch -q origin
if ($LASTEXITCODE -ne 0) { Stop-Sync "连不上 GitHub（网络或登录）。本机改动已经 commit，联网后再双击一次。" }
& $git merge --no-edit origin/main
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n冲突文件：" -ForegroundColor Yellow
    & $git diff --name-only --diff-filter=U
    Stop-Sync "合并有冲突，没有推送。别手动选“用我的版本”。在 Claude Code 里打开 Research-PAM，说：sync 有冲突，帮我逐段对比合并。"
}

Write-Host "[4/5] 重建对话索引" -ForegroundColor Cyan
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "export_pam_chats.ps1") -Reindex | Out-Null
& $git add "08_对话记录/INDEX.md"
& $git diff --cached --quiet
if ($LASTEXITCODE -ne 0) { & $git commit -q -m "$(Get-Date -Format 'yyyy-MM-dd HH:mm') reindex from $Machine" }

Write-Host "[5/5] 推送到 GitHub" -ForegroundColor Cyan
& $git push -q origin main
if ($LASTEXITCODE -ne 0) { Stop-Sync "推送失败。等一会儿再双击一次；还不行就把这个窗口的内容发给 Claude。" }

Write-Host "`n同步完成：" -ForegroundColor Green
& $git log -3 --format="  %h %ad %s" --date=format:"%m-%d %H:%M"
