#!/usr/bin/env python3
"""把 Claude Code 的 PAM 会话 (.jsonl) 导出成可读 Markdown，放进 08_对话记录/，并重建 INDEX.md。

Mac 和 Windows 都能跑（只用标准库）。换 Claude 账号、换电脑时，原生会话不会跟过去，
所以每次结束一段重要对话后跑一次，把记录变成仓库里的文件，再 git push。

用法（在仓库根目录）:
    python3 tools/export_pam_chats.py --list                 # 列出本机所有会话及 PAM 关键词命中数，先看
    python3 tools/export_pam_chats.py --ids 0a5af2e7 d6499ffd --machine Mac
    python3 tools/export_pam_chats.py --auto --machine LabPC # 自动挑：用户消息里 PAM 关键词 >= --min-hits
    python3 tools/export_pam_chats.py --src <某个 projects 子目录或解压出的 jsonl 目录> --auto --machine LabPC

Windows 上把 python3 换成 python 或 py。
"""
import argparse, json, re, sys
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
OUT = REPO / "08_对话记录"
PAT = re.compile(r"UV-PAM|ATS9462|Alazar|LabVIEW|SlowScan|ENdaq|ENlaser|A-line|B-scan|C-scan|galvo|"
                 r"PCIe-6323|BNC-2110|SR2|CXP|photoacoustic|光声|Rui|meeting-prep|Research-PAM|PAM_control", re.I)
REMINDER = re.compile(r"<system-reminder>.*?</system-reminder>", re.S)


def blocks(content):
    if isinstance(content, str):
        return [{"type": "text", "text": content}]
    return [b for b in content or [] if isinstance(b, dict)]


def result_text(b):
    c = b.get("content")
    if isinstance(c, list):
        c = "\n".join(x.get("text", "[图片]") if x.get("type") == "text" else "[图片]"
                      for x in c if isinstance(x, dict))
    return str(c or "")


def cut(s, n):
    s = s or ""
    return s if len(s) <= n else s[:n] + f"\n…[截断，共 {len(s)} 字符]"


def tool_brief(name, inp):
    if not isinstance(inp, dict):
        return name
    for k in ("description", "file_path", "command", "pattern", "url", "query", "prompt"):
        if k in inp:
            return f"{name} · {k}: {cut(str(inp[k]).replace(chr(10), ' '), 300)}"
    return name


def load(path):
    title, recs, hits, first_ts = None, [], 0, None
    for line in open(path, encoding="utf-8", errors="replace"):
        try:
            d = json.loads(line)
        except Exception:
            continue
        t = d.get("type")
        if t == "custom-title":
            title = d.get("customTitle") or title
        elif t == "ai-title" and not title:
            title = d.get("aiTitle")
        elif t in ("user", "assistant") and not d.get("isSidechain") and not d.get("isMeta"):
            recs.append(d)
            first_ts = first_ts or d.get("timestamp")
            if t == "user":
                for b in blocks(d.get("message", {}).get("content")):
                    if b.get("type") == "text" and not b["text"].lstrip().startswith("<"):
                        hits += len(PAT.findall(b["text"]))
    return title, recs, hits, first_ts


def render(path, title, recs, machine, tool_chars):
    sid = path.stem
    out = [f"---\nsession: {sid}\ntitle: {title or '(无标题)'}\nmachine: {machine}\n"
           f"source: {path.name}\nexported: {datetime.now():%Y-%m-%d %H:%M}\n---\n",
           f"# {title or '(无标题)'}\n"]
    for d in recs:
        role = d["type"]
        ts = (d.get("timestamp") or "")[:16].replace("T", " ")
        parts = []
        for b in blocks(d.get("message", {}).get("content")):
            bt = b.get("type")
            if bt == "text":
                txt = REMINDER.sub("", b["text"]).strip()
                if txt and not txt.startswith(("<local-command", "<command-", "<task-notification")):
                    parts.append(txt)
            elif bt == "tool_use":
                parts.append(f"> 🔧 {tool_brief(b.get('name', '?'), b.get('input'))}")
            elif bt == "tool_result" and tool_chars > 0:
                r = result_text(b).strip()
                if r:
                    parts.append("<details><summary>工具输出</summary>\n\n```\n" + cut(r, tool_chars) + "\n```\n</details>")
        if parts:
            who = "🧑 用户" if role == "user" and not all(p.startswith("<details>") for p in parts) else (
                "🤖 Claude" if role == "assistant" else "⚙️ 工具")
            out.append(f"\n### {who} · {ts}\n\n" + "\n\n".join(parts))
    return "\n".join(out) + "\n"


def safe(s, n=40):
    return (re.sub(r'[\\/:*?"<>|\s]+', "_", s or "无标题").strip("_"))[:n]


def rebuild_index():
    rows = []
    for f in sorted(list(OUT.glob("*.md")) + list(OUT.glob("网页/*.md"))):
        if f.name == "INDEX.md" or f.name.startswith("_"):
            continue
        meta = {}
        txt = f.read_text(encoding="utf-8", errors="replace").split("---", 2)
        if len(txt) > 2:
            for line in txt[1].splitlines():
                if ":" in line:
                    k, v = line.split(":", 1)
                    meta[k.strip()] = v.strip()
        rows.append((f.name[:10], meta.get("machine", "?"), meta.get("title", "?"), f.relative_to(OUT).as_posix()))
    lines = ["# PAM 对话记录索引\n",
             "由 `tools/export_pam_chats.py` 自动生成，不要手改。新会话导出后会重建。",
             "按日期排序；machine = 在哪台电脑/哪个账号的 Claude Code 里聊的。\n",
             "| 日期 | 机器 | 标题 | 文件 |", "|---|---|---|---|"]
    for d, m, t, n in sorted(rows):
        lines.append(f"| {d} | {m} | {t} | [{n}]({n.replace(' ', '%20')}) |")
    (OUT / "INDEX.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", nargs="*", help="jsonl 所在目录；默认 ~/.claude/projects 下全部子目录")
    ap.add_argument("--ids", nargs="*", default=[], help="会话 id 前缀")
    ap.add_argument("--auto", action="store_true", help="按 PAM 关键词自动挑")
    ap.add_argument("--min-hits", type=int, default=5)
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--reindex", action="store_true", help="只重建 INDEX.md（导入网页对话后用）")
    ap.add_argument("--machine", default="Mac")
    ap.add_argument("--tool-chars", type=int, default=600, help="工具输出保留字符数，0 = 不导出")
    a = ap.parse_args()

    if a.reindex:
        rebuild_index()
        return print("INDEX.md 已重建")
    srcs = [Path(s).expanduser() for s in a.src] if a.src else \
        [p for p in (Path.home() / ".claude" / "projects").glob("*") if p.is_dir()]
    files = sorted({f for s in srcs for f in s.glob("*.jsonl")}, key=lambda f: f.stat().st_mtime)
    OUT.mkdir(exist_ok=True)
    n = 0
    for f in files:
        title, recs, hits, ts = load(f)
        if a.list:
            print(f"{(ts or '')[:10]}  hits={hits:<4} {f.stem[:8]}  {title}")
            continue
        if not (any(f.stem.startswith(i) for i in a.ids) or (a.auto and hits >= a.min_hits)):
            continue
        for old in OUT.glob(f"*_{f.stem[:8]}.md"):  # 同一会话重新导出时覆盖
            old.unlink()
        name = f"{(ts or '0000-00-00')[:10]}_{safe(title)}_{f.stem[:8]}.md"
        (OUT / name).write_text(render(f, title, recs, a.machine, a.tool_chars), encoding="utf-8")
        print("导出", name)
        n += 1
    if a.reindex or not a.list:
        rebuild_index()
        print(f"共导出 {n} 个会话 → {OUT}")


if __name__ == "__main__":
    sys.exit(main())
