---
name: uv-pam-project-records
description: "UV-PAM(CWRU, 导师Rui Cao)项目记录的本机位置; research-progress skill 要求的 master/账本在 ~/Research-PAM, 不在 Projects 工具里"
metadata:
  node_type: memory
  type: reference
  originSessionId: 0a5af2e7-39f3-4c8d-bdfb-4a9723e940a5
  modified: 2026-10-01T20:48:07.097Z
---

UV-PAM 项目（见 [[user-profile-yumeng]]）的记录在本机 `~/Research-PAM/02_笔记与上下文/`：

- `UV-PAM-master.md` —— 唯一主文件（硬件、两个程序版本 ENlaser/ENdaq、§19 当前进度、§20 待确认/问 Rui、§21 已撤回说法）。
- `context-conflicts.md` —— 参数账本与冲突清单（标「⚠ 待确认」的数值不进计算）。
- `meeting-prep/` —— 每次周一会前稿。

`anthropic-skills:research-progress` skill 第 0 步写「用 Projects 工具读」，但 Claude Code 里没有该工具，直接用 Read/grep 读上面路径即可。写入 master/账本前必须先经用户同意。

相关材料常放在 `~/Downloads/`：ATS9462 规格书 `ATS9462v15Q.pdf`、`UV-PAM 导师会谈整理（定稿）.md`（2026-09-28 会，含 Rui 的 26 个追问）、`ats9462_aline_test*.m`、`ATS9462_NPT.m`（官方 sample）。本机没有 pdftotext/pypdf，抽 PDF 文字用 swift + PDFKit。

采集卡官方文档有与实验室 SDK 同版本的页面：`https://docs.alazartech.com/ats-sdk-user-guide/23-3-0/`（路径用连字符，带点的 23.3.0 会 404）。
