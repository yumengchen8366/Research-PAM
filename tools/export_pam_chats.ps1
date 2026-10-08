# export_pam_chats.py 的 PowerShell 版（Windows PowerShell 5.1 能跑，不用装 Python）。
# 输出格式和 .py 一样：08_对话记录/<日期>_<标题>_<id前8位>.md，并重建 INDEX.md。
#
# 用法（在仓库根目录）:
#   powershell -ExecutionPolicy Bypass -File tools\export_pam_chats.ps1 -List
#   powershell -ExecutionPolicy Bypass -File tools\export_pam_chats.ps1 -Ids 08539d41 -Machine "LabPC(新账号)"
#   powershell -ExecutionPolicy Bypass -File tools\export_pam_chats.ps1 -Reindex
#   ... -Src <目录> -All -Changed      # sync_pam.cmd 用：该目录下所有会话，只导出 .jsonl 比已有 .md 新的
# 默认在 ~/.claude/projects 下所有子目录里找 .jsonl；-Src 可指定别的目录。
param(
    [string[]]$Src,
    [string[]]$Ids = @(),
    [switch]$All,
    [switch]$Changed,
    [switch]$List,
    [switch]$Reindex,
    [string]$Machine = "LabPC",
    [int]$ToolChars = 600
)
$ErrorActionPreference = "Stop"
$Repo = Split-Path -Parent $PSScriptRoot
$Out = Join-Path $Repo "08_对话记录"
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$Reminder = [regex]::new("<system-reminder>.*?</system-reminder>", "Singleline")

function CpLen([string]$s) {  # 按 Unicode 码点计数，和 Python len() 一致
    return $s.Length - [regex]::Matches($s, "[\uD800-\uDBFF]").Count
}
function Cut([string]$s, [int]$n) {
    if ($null -eq $s) { $s = "" }
    if ($s.Length -le $n) { return $s }
    $total = CpLen $s
    if ($total -le $n) { return $s }
    $i = 0; $k = 0
    while ($k -lt $n) { if ([char]::IsHighSurrogate($s[$i])) { $i += 2 } else { $i += 1 }; $k++ }
    return $s.Substring(0, $i) + "`n…[截断，共 $total 字符]"
}
function Blocks($content) {
    if ($content -is [string]) { return ,@([pscustomobject]@{ type = "text"; text = $content }) }
    if ($null -eq $content) { return ,@() }
    return ,@($content | Where-Object { $_ -is [System.Management.Automation.PSCustomObject] })
}
function ResultText($b) {
    $c = $b.content
    if ($c -is [array]) {
        $c = ($c | Where-Object { $_ -is [System.Management.Automation.PSCustomObject] } | ForEach-Object {
            if ($_.type -eq "text") { if ($null -ne $_.text) { $_.text } else { "[图片]" } } else { "[图片]" }
        }) -join "`n"
    }
    if ($null -eq $c) { return "" }
    return [string]$c
}
function ToolBrief($name, $inp) {
    if ($inp -isnot [System.Management.Automation.PSCustomObject]) { return $name }
    foreach ($k in "description", "file_path", "command", "pattern", "url", "query", "prompt") {
        if ($inp.PSObject.Properties.Name -contains $k) {
            return "$name · ${k}: " + (Cut (([string]$inp.$k) -replace "`n", " ") 300)
        }
    }
    return $name
}
function Load($path) {
    $r = @{ title = $null; recs = New-Object System.Collections.ArrayList; first = $null; bad = 0 }
    foreach ($line in [IO.File]::ReadLines($path, $Utf8)) {
        try { $d = $line | ConvertFrom-Json } catch { $r.bad++; continue }
        $t = $d.type
        if ($t -eq "custom-title") { if ($d.customTitle) { $r.title = $d.customTitle } }
        elseif ($t -eq "ai-title" -and -not $r.title) { $r.title = $d.aiTitle }
        elseif (($t -eq "user" -or $t -eq "assistant") -and -not $d.isSidechain -and -not $d.isMeta) {
            [void]$r.recs.Add($d)
            if (-not $r.first) { $r.first = $d.timestamp }
        }
    }
    return $r
}
function Render($path, $title, $recs) {
    $sid = [IO.Path]::GetFileNameWithoutExtension($path)
    $tt = if ($title) { $title } else { "(无标题)" }
    $out = New-Object System.Collections.Generic.List[string]
    $out.Add("---`nsession: $sid`ntitle: $tt`nmachine: $Machine`nsource: $([IO.Path]::GetFileName($path))`nexported: $(Get-Date -Format 'yyyy-MM-dd HH:mm')`n---`n")
    $out.Add("# $tt`n")
    foreach ($d in $recs) {
        $role = $d.type
        $ts = [string]$d.timestamp
        if ($ts.Length -gt 16) { $ts = $ts.Substring(0, 16) }
        $ts = $ts.Replace("T", " ")
        $parts = New-Object System.Collections.Generic.List[string]
        foreach ($b in (Blocks $d.message.content)) {
            $bt = $b.type
            if ($bt -eq "text") {
                $txt = $Reminder.Replace([string]$b.text, "").Trim()
                if ($txt -and -not ($txt.StartsWith("<local-command") -or $txt.StartsWith("<command-") -or $txt.StartsWith("<task-notification"))) {
                    $parts.Add($txt)
                }
            } elseif ($bt -eq "tool_use") {
                $nm = if ($b.name) { $b.name } else { "?" }
                $parts.Add("> 🔧 " + (ToolBrief $nm $b.input))
            } elseif ($bt -eq "tool_result" -and $ToolChars -gt 0) {
                $res = (ResultText $b).Trim()
                if ($res) { $parts.Add("<details><summary>工具输出</summary>`n`n```````n" + (Cut $res $ToolChars) + "`n```````n</details>") }
            }
        }
        if ($parts.Count -gt 0) {
            $allDetails = @($parts | Where-Object { -not $_.StartsWith("<details>") }).Count -eq 0
            $who = if ($role -eq "user" -and -not $allDetails) { "🧑 用户" } elseif ($role -eq "assistant") { "🤖 Claude" } else { "⚙️ 工具" }
            $out.Add("`n### $who · $ts`n`n" + ($parts -join "`n`n"))
        }
    }
    return ($out -join "`n") + "`n"
}
function SafeName([string]$s, [int]$n = 40) {
    if (-not $s) { $s = "无标题" }
    $s = ([regex]::Replace($s, '[\\/:*?"<>|\s]+', "_")).Trim("_")
    if ((CpLen $s) -gt $n) { $s = (Cut $s $n).Split("`n")[0] }
    return $s
}
function RebuildIndex {
    $files = @(Get-ChildItem -LiteralPath $Out -Filter *.md -File)
    $web = Join-Path $Out "网页"
    if (Test-Path -LiteralPath $web) { $files += @(Get-ChildItem -LiteralPath $web -Filter *.md -File) }
    $rows = New-Object System.Collections.Generic.List[string]
    foreach ($f in $files) {
        if ($f.Name -eq "INDEX.md" -or $f.Name.StartsWith("_")) { continue }
        $meta = @{}
        $txt = [IO.File]::ReadAllText($f.FullName, $Utf8) -split "---", 3
        if ($txt.Count -gt 2) {
            foreach ($line in $txt[1] -split "\r?\n") {
                $i = $line.IndexOf(":")
                if ($i -ge 0) { $meta[$line.Substring(0, $i).Trim()] = $line.Substring($i + 1).Trim() }
            }
        }
        $rel = $f.FullName.Substring($Out.Length + 1).Replace("\", "/")
        $m = if ($meta.ContainsKey("machine")) { $meta["machine"] } else { "?" }
        $t = if ($meta.ContainsKey("title")) { $meta["title"] } else { "?" }
        $rows.Add(($f.Name.Substring(0, [Math]::Min(10, $f.Name.Length)), $m, $t, $rel) -join [char]0)
    }
    $rows.Sort([StringComparer]::Ordinal)  # 和 Python 的 sorted() 一样按码点排
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# PAM 对话记录索引`n")
    $lines.Add("由 ``tools/export_pam_chats.py`` 自动生成，不要手改。新会话导出后会重建。")
    $lines.Add("按日期排序；machine = 在哪台电脑/哪个账号的 Claude Code 里聊的。`n")
    $lines.Add("| 日期 | 机器 | 标题 | 文件 |")
    $lines.Add("|---|---|---|---|")
    foreach ($r in $rows) {
        $d, $m, $t, $n = $r -split [char]0
        $lines.Add("| $d | $m | $t | [$n]($($n.Replace(' ', '%20'))) |")
    }
    [IO.File]::WriteAllText((Join-Path $Out "INDEX.md"), ($lines -join "`n") + "`n", $Utf8)
}

if ($Reindex) { RebuildIndex; "INDEX.md 已重建"; return }
if (-not $Src) { $Src = @(Get-ChildItem -LiteralPath (Join-Path $HOME ".claude\projects") -Directory | ForEach-Object FullName) }
$files = @($Src | ForEach-Object { Get-ChildItem -LiteralPath $_ -Filter *.jsonl -File } | Sort-Object LastWriteTime)
if (-not (Test-Path -LiteralPath $Out)) { New-Item -ItemType Directory $Out | Out-Null }
$n = 0
foreach ($f in $files) {
    $stem = $f.BaseName
    if ($List) {
        if ($Ids.Count -eq 0 -or ($Ids | Where-Object { $stem.StartsWith($_) })) {
            $r = Load $f.FullName
            "{0}  {1}  {2}" -f ([string]$r.first).PadRight(10).Substring(0, 10), $stem.Substring(0, 8), $r.title
        }
        continue
    }
    if (-not $All -and -not ($Ids | Where-Object { $stem.StartsWith($_) })) { continue }
    $old = @(Get-ChildItem -LiteralPath $Out -Filter "*_$($stem.Substring(0, 8)).md" -File)
    if ($Changed -and $old.Count -gt 0 -and ($old | Where-Object { $_.LastWriteTime -ge $f.LastWriteTime })) { continue }
    $r = Load $f.FullName
    if ($r.recs.Count -eq 0) { continue }  # 空会话不导出
    $old | Remove-Item -Confirm:$false  # 同一会话重新导出时覆盖
    $date = if ($r.first) { ([string]$r.first).Substring(0, 10) } else { "0000-00-00" }
    $name = "{0}_{1}_{2}.md" -f $date, (SafeName $r.title), $stem.Substring(0, 8)
    [IO.File]::WriteAllText((Join-Path $Out $name), (Render $f.FullName $r.title $r.recs), $Utf8)
    "导出 $name" + $(if ($r.bad) { "（$($r.bad) 行 JSON 解析失败，已跳过）" } else { "" })
    $n++
}
if (-not $List) { RebuildIndex; "共导出 $n 个会话 → $Out" }
