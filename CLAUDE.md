# UV-PAM 项目（CWRU BME，Rui Cao 组）

这个文件夹是一个**私有 GitHub 仓库**，是 PAM 项目唯一的“真相来源”。我（Yumeng，PhD 一年级）在
**两个 Claude 账号**、**三个地方**（Mac、实验室 Windows 电脑 CAOLAB1、claude.ai 网页）上推进它。
Claude 的对话记录和记忆**不跟账号走、也不跨电脑**，所以：**凡是下次还要用的事实，都必须写进这个仓库的文件里**，
不能只留在对话或本机记忆里。

## 开工先做
1. 提醒我先双击仓库根目录的 `sync_pam.cmd`（Mac：`sync_pam.command`），取回别处的最新内容；我已经双击过就直接 `git pull`。
2. 读 `06_控制程序/docs/工作日志.md` 的最后 3 条 —— 这是跨账号、跨电脑的进度接力棒。
3. 按任务再读：
   - 会议、参数、进度、要问 Rui 的：`02_笔记与上下文/UV-PAM-master.md`（§19 当前进度、§20 待确认）+ `context-conflicts.md`（参数账本）。只读相关节。
   - 写代码、做实验：`06_控制程序/docs/` 里对应模块的文件（目录见 `06_控制程序/CLAUDE.md`）。
   - 想知道以前聊过什么：`08_对话记录/INDEX.md`，再用 grep 搜具体文件。
4. 会前准备 / 和导师沟通 / 排查卡点：用项目 skill `research-progress`（在 `.claude/skills/`）。

## 收工必做（每个窗口结束前）
1. 在 `06_控制程序/docs/工作日志.md` 末尾加一条：`**日期｜模块（机器/账号）**` + 做了什么 / 结果 / 下次第一步。
2. 新确认的事实写进 docs 里对应的文件；改 `UV-PAM-master.md` 或 `context-conflicts.md` **前先问我同意**，并更新文件头日期。
3. 导出本次对话：`python3 tools/export_pam_chats.py --ids <本会话id前8位> --machine <Mac新号|LabPC旧号|…>`（Windows 用 `python`；实验室电脑没装 Python，用 `powershell -ExecutionPolicy Bypass -File tools/export_pam_chats.ps1 -Ids <id前8位> -Machine <…>`，输出格式相同）。
4. `git add -A && git commit -m "<日期> <模块>: <一句话>"`，然后提醒我双击 `sync_pam.cmd` / `sync_pam.command`（它会再导出一遍有更新的会话、和 GitHub 合并（merge）、push）。合并有冲突时脚本会停下、不推送：逐段对比两边，列给我确认后再合并，不要直接选一边。

## 协作方式
- 中文为主，保留英文术语；对导师说的话给中英两版。
- **教，不替我做**：先讲原理和每个参数，让我自己写/改代码；你指出 `文件:行号` 的问题、给测试步骤和检查清单。没让你改就不改我的 MATLAB 文件。一个窗口只做一个模块。
- 每个数字带单位和出处；用 master §0 的六档标签：[文件确认] [实测] [历史解释] [导师要求] [条件计算] [待确认]。标「⚠ 待确认」的数值不进计算。
- 不确定的写“待确认”，不当成事实；不把建议写成已完成。
- 给我的输出 = 数据摘要 + 结论/建议要点，不替我写整段发言（除非我要）。

## 在哪台机器上
| 机器 | 能做 | 不能做 |
|---|---|---|
| 实验室 CAOLAB1（Windows，有 ATS9462、NI PCIe-6323/Dev1、SR2、示波器、发生器） | 跑硬件脚本、采数据 | — |
| Mac | 读 `.mat` 分析、写代码、整理文档、会前准备 | 不能跑任何硬件脚本（没有卡，SDK 路径 `C:\AlazarTech\...` 也不存在） |
| claude.ai 网页（Project 连这个 GitHub 仓库） | 讨论、会前准备、读文档 | 不能写仓库；网页里得出的结论要回到 Code 里写进文件 |

## 安全规则（硬件）
- 硬件脚本默认 `RUN_HARDWARE = false`，确认后才改 true；激光触发默认关闭。
- 运行 MATLAB 前先关掉占用 Dev1 或 ATS9462 的 LabVIEW。

## 目录
| 目录 | 内容 |
|---|---|
| `00_README.md` | 文件夹索引 |
| `01_硬件资料/` | 器件清单、联系人、滑台/SR2/激光报告、ATS9462 规格书、ATS-SDK-Guide.pdf |
| `02_笔记与上下文/` | master、参数账本、meeting-prep/、会谈记录/ |
| `03_LabVIEW代码/` | LabVIEW 原工程（**不进 git**，只在本机；见 `.gitignore`） |
| `04_示意图/`、`05_汇报/` | 时序图、系统结构 HTML；汇报 pptx、研究计划文书 |
| `06_控制程序/` | MATLAB 重写项目的知识库（原实验室电脑 `PAM_controlProgram`）：docs/01–09、工作日志、tools |
| `07_MATLAB/` | A-line/B-scan 脚本、`aline_data/`、`System_test_09_25/`、`AlazarInclude/`（查常量）、`_Mac下载版本/` |
| `08_对话记录/` | 所有 PAM 对话导出的 Markdown + `INDEX.md`；`claude-memory/` 是两台机器旧账号的 Claude 记忆 |
| `tools/` | `export_pam_chats.py` / `.ps1`（导出对话；.ps1 给没装 Python 的 Windows）、`同步与多账号使用说明.md` |
| `.claude/skills/research-progress/` | 项目 skill（Claude Code 打开本文件夹自动可用） |
