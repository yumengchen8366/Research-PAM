#!/usr/bin/env python3
"""把 claude.ai「导出数据」里的网页对话（conversations.json）转成 Markdown，放进 08_对话记录/网页/。

claude.ai 的网页对话（包括 Project「cao meeting」里的）不能直接搬到另一个账号。办法：
  旧账号 claude.ai → Settings → Privacy → Export data → 邮件里下载 zip → 解压，
  然后在仓库根目录运行：
    python3 tools/import_claudeai_export.py <解压目录或 conversations.json> --list
    python3 tools/import_claudeai_export.py <同上> --keyword PAM Rui ATS LabVIEW 光声 导师
    python3 tools/import_claudeai_export.py <同上> --project "cao meeting"   # 需要导出里有 projects.json

导出格式不是公开的固定格式，这里按常见字段（name / created_at / chat_messages[].sender/.text/.content）
宽松解析；字段对不上时会打印提示，不会写坏仓库里的其他文件。
"""
import argparse, json, re, sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
OUT = REPO / "08_对话记录" / "网页"


def msg_text(m):
    if isinstance(m.get("content"), list):
        parts = []
        for b in m["content"]:
            if not isinstance(b, dict):
                continue
            if b.get("type") == "text" and b.get("text"):
                parts.append(b["text"])
            elif b.get("type") == "tool_use":
                parts.append(f"> 🔧 {b.get('name', '?')}")
        if parts:
            return "\n\n".join(parts)
    return m.get("text") or ""


def safe(s, n=40):
    return re.sub(r'[\\/:*?"<>|\s]+', "_", s or "无标题").strip("_")[:n]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("--keyword", nargs="*", default=[])
    ap.add_argument("--project", help="只要某个 Project 里的对话（按名字）")
    ap.add_argument("--list", action="store_true")
    a = ap.parse_args()

    src = Path(a.src).expanduser()
    conv_file = src / "conversations.json" if src.is_dir() else src
    convs = json.loads(conv_file.read_text(encoding="utf-8"))
    proj_uuid = None
    if a.project:
        pf = conv_file.parent / "projects.json"
        if not pf.exists():
            sys.exit("导出里没有 projects.json，改用 --keyword 过滤")
        for p in json.loads(pf.read_text(encoding="utf-8")):
            if a.project.lower() in (p.get("name") or "").lower():
                proj_uuid = p.get("uuid")
                # 顺便把 Project 的说明和知识文件也存下来
                OUT.mkdir(parents=True, exist_ok=True)
                body = [f"# Project: {p.get('name')}\n", p.get("description") or "",
                        "\n## Instructions\n", p.get("prompt_template") or "(导出里没有)"]
                for d in p.get("docs") or []:
                    body += [f"\n## 知识文件: {d.get('filename')}\n", d.get("content") or ""]
                (OUT / f"_project_{safe(p.get('name'))}.md").write_text("\n".join(body), encoding="utf-8")
        if not proj_uuid:
            sys.exit(f"projects.json 里找不到名字含「{a.project}」的 Project")

    kw = re.compile("|".join(map(re.escape, a.keyword)), re.I) if a.keyword else None
    n = 0
    for c in convs:
        msgs = c.get("chat_messages") or []
        title = c.get("name") or "(无标题)"
        alltext = title + "\n" + "\n".join(msg_text(m) for m in msgs)
        in_proj = proj_uuid and (c.get("project_uuid") == proj_uuid or
                                 (c.get("project") or {}).get("uuid") == proj_uuid)
        hits = len(kw.findall(alltext)) if kw else 0
        if a.list:
            print(f"{(c.get('created_at') or '')[:10]}  msgs={len(msgs):<4} hits={hits:<4} {title}")
            continue
        if not (in_proj or (kw and hits >= 3)):
            continue
        OUT.mkdir(parents=True, exist_ok=True)
        date = (c.get("created_at") or "0000-00-00")[:10]
        lines = [f"---\nsession: {c.get('uuid')}\ntitle: {title}\nmachine: claude.ai网页(旧账号)\n---\n", f"# {title}\n"]
        for m in msgs:
            who = "🧑 用户" if m.get("sender") == "human" else "🤖 Claude"
            ts = (m.get("created_at") or "")[:16].replace("T", " ")
            files = [f.get("file_name") for f in (m.get("attachments") or []) + (m.get("files") or [])
                     if isinstance(f, dict) and f.get("file_name")]
            extra = f"\n\n📎 附件: {', '.join(files)}" if files else ""
            lines.append(f"\n### {who} · {ts}\n\n{msg_text(m).strip()}{extra}")
        (OUT / f"{date}_{safe(title)}_{str(c.get('uuid'))[:8]}.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
        n += 1
    if not a.list:
        print(f"导入 {n} 个网页对话 → {OUT}；再运行 python3 tools/export_pam_chats.py --reindex 更新索引")


if __name__ == "__main__":
    main()
