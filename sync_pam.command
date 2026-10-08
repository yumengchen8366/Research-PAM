#!/bin/bash
# 一键同步 Research-PAM（Mac）：开工、收工各双击一次。和 Windows 的 sync_pam.cmd 做同样的事：
# 导出本机有更新的 Claude Code 会话 → commit → 从 GitHub 取回并合并（merge）→ 重建对话索引 → push。
# 合并有冲突时不推送，停下来交给 Claude 逐段对比。
cd "$(dirname "$0")" || exit 1
MACHINE="Mac"
done_wait() { echo; read -r -p "按回车关闭窗口" _; exit "$1"; }

if [ -f .git/MERGE_HEAD ]; then
  echo "上一次合并还没解决完（有冲突）。在 Claude Code 里打开 Research-PAM，说：sync 有冲突，帮我逐段对比合并。"; done_wait 1
fi

echo "[1/5] 导出本机有更新的 Claude 会话"
SRC="$HOME/.claude/projects/$(pwd | sed 's/[^A-Za-z0-9]/-/g')"
if [ -d "$SRC" ]; then
  python3 tools/export_pam_chats.py --src "$SRC" --auto --min-hits 0 --changed --machine "$MACHINE"
else
  echo "  （本机还没有在 Research-PAM 里开过 Claude Code 会话）"
fi

echo "[2/5] 提交本机改动"
git add -A
if ! git diff --cached --quiet; then
  git commit -q -m "$(date '+%Y-%m-%d %H:%M') sync from $MACHINE" && git log -1 --format="  %h %s"
else
  echo "  没有改动"
fi

echo "[3/5] 取回 GitHub 上的新内容并合并"
git fetch -q origin || { echo "连不上 GitHub。本机改动已经 commit，联网后再双击一次。"; done_wait 1; }
if ! git merge --no-edit origin/main; then
  echo; echo "冲突文件："; git diff --name-only --diff-filter=U
  echo "合并有冲突，没有推送。在 Claude Code 里打开 Research-PAM，说：sync 有冲突，帮我逐段对比合并。"; done_wait 1
fi

echo "[4/5] 重建对话索引"
python3 tools/export_pam_chats.py --reindex >/dev/null
git add "08_对话记录/INDEX.md"
git diff --cached --quiet || git commit -q -m "$(date '+%Y-%m-%d %H:%M') reindex from $MACHINE"

echo "[5/5] 推送到 GitHub"
git push -q origin main || { echo "推送失败。等一会儿再双击一次；还不行就把这个窗口的内容发给 Claude。"; done_wait 1; }

echo; echo "同步完成："; git log -3 --format="  %h %ad %s" --date=format:"%m-%d %H:%M"
done_wait 0
