# Research-PAM 文件夹索引

> 整理于 2026-09-23；9/23 晚合并上下文后更新索引；**10/4 并入实验室电脑的控制程序知识库，变成 GitHub 私有仓库，两个 Claude 账号共用**（见 `CLAUDE.md`、`tools/同步与多账号使用说明.md`）。新文件请按下面的分类放。

## 01_硬件资料/
| 文件 | 内容 |
|---|---|
| CXP Motorized stage.pdf | 电动位移台资料 |
| PAM item list.pdf | 系统器件清单 |
| PAM proj contacts.pdf | 项目联系人 |

## 02_笔记与上下文/
**⭐ 当前在用（9/23 合并后）——只维护这四样，别再另起新的上下文包**
| 文件 | 内容 | 什么时候改 |
|---|---|---|
| **UV-PAM-master.md** | **唯一主文件**：8/30 版 + GPT 9/21、9/23 三份 + Drive 交接笔记 8/07 版合并，带六档证据标签；§19 当前进度、§20 待确认/问 Rui、§21 已撤回说法、§22 计划 | 每次会后只改 §19、§20；改动更新文件头日期 |
| **context-conflicts.md** | 参数账本 + 13 条冲突清单（#2、#5 已解开：两个程序版本；#1 10 µm vs 0.5 µm 待拍拨码） | 冲突有结论先写这里，再同步 master |
| **meeting-prep/YYYY-MM-DD.md** | 每次周一会前一份（周四晚前完成）；会后归档不改 | 2026-09-28.md 已建 |
| project-instructions.md | 复制到 Claude project 「Set instructions」的文字 | 规则变了才改 |

claude.ai 网页 Project 通过 GitHub 集成直接读本仓库（10/4 起，不再手动上传副本）。**本仓库是主；网页 Project 只读。** push 后在 Project 里点同步。

**会谈记录/**（10/4 从 Downloads 复制）：`UV-PAM 导师会谈整理（定稿）.md`（9/28）、`PAM_advisor_meeting_complete_summary_2026-09-28.md`、`PAM导师会谈整理稿.docx`、`Rui Cao Jan 8th.txt`、`ruicao last.txt`（转录稿；录音不进仓库）；`2026-10-12_Rui会谈整理.md`（10/12 一对一：要点、待办、概念、ATS9462 核对、逐段对话）+ `2026-10-12_Rui会谈转录.txt`（原始转录）

**PAM学习进度.md**（10/13 从 learning_skill 搬来）：学习/理解进度——每个知识点到哪、卡点、下一步练什么（learning-progress 技能的 PAM 记录）

**参考（内容已进 master，留原件）**
| 文件 | 内容 |
|---|---|
| PAM_LabVIEW_交接笔记.md | v0.9 **7/24 版**（23 KB）。⚠ Google Drive 里有 **8/07 版（38 KB）更全**，含 §24 五步走、§25 时序破案（200005 栅栏效应、共享时钟定论、门 0.4 s vs 电机 1 s 矛盾）——master 引用的是 8/07 版 |
| UVPAM_Phase1_Weekly_Integrated_MATLAB_EN.md | Phase 1 每周里程碑 + MATLAB 任务 |
| GPT原件_已并入master/ | ChatGPT 9/21、9/23 四份 + Claude 8/30 版 `UV-PAM-context.md`。全部内容已逐节并入 master（对照表见 master 文件头和 meeting-prep 附录）。**不要再拿这些开新对话** |

## 03_LabVIEW代码/
- **SlowScan_ENdaq/** — 原始 LabVIEW 工程（ERPAM_Yide.lvproj，入口 Main.vi）。**内部结构未改动**，VI 之间靠相对路径引用，不要在里面挪文件。
  - `SubVIs/`：脉冲生成（GeneratePulses / GenerateSkipPulses）、DAQ、扫描、保存等子 VI
  - `ATS9462-VI/`：AlazarTech 驱动 VI（工程里同时引用 ATS9350 和 ATS9462，实际板卡型号未确认）
  - `OneDrive_1_2-1-2022/`：galvo 步长平滑 MATLAB 脚本与采样表
  - `scan_pattern.mat`：扫描路径

## 04_示意图/
**系统结构HTML/**（浏览器打开）：MainVI 地图、模块地图、信号流向图、扫描层级与时钟、从波形到图像

**时序图片/**
| 文件 | 内容 |
|---|---|
| 01_Week1_准备清单与引导问题 | 激光安全、组织学核心、第 1 周计划 |
| 02_Week1目标_电机运动正常 | 回零 / 1 µm 移动 / 3×3 mm 栅格 / 重复性验收 |
| 03_3mm栅格扫描_参数推导_v1 | 扫描路径、步数计算、参数确定顺序 |
| 04_3mm栅格扫描_参数与时序详解_v2 | 同上的修订版（Xn=301 覆盖 3 mm、蛇形扫描流程） |
| 05–08_B-scan时序图 v1→v4 | 0–200 µs DO 时序：Bit7 激光 / Bit6 DAQ / Bit1 DIR / Bit0 STEP；**v4 为最终版** |

## 05_汇报/
- UV-PAM_Progress_Aug31.pptx — 8/31 进度汇报
- 10/4 从 Downloads 复制：Journal Club PAM 综述（final / with_notes）、Meeting with Dr. Cao.pptx、PAM_Speed_Methods_*、PAM 综述组会背景知识 pdf、PAM 扫描控制手册.html
- `研究计划与文书/`：UVPAM Research Plan / Statement 各版本、UV_PAM_Literature_Guide

## 06_控制程序/ （原实验室电脑 `Desktop\PAM_controlProgram`，10/3 19:34 快照）
- `CLAUDE.md`：MATLAB 重写项目的规则和文件位置
- `docs/`：01 硬件与接线、02 LabVIEW 程序地图、03 写法对照、04/07 四周计划（07 有英文版）、05 参数字典、06 现有代码与进度、08 LabVIEW 清单、09 两天冲刺清单、**工作日志.md（跨账号进度接力棒）**
- `LabviewPAM/`：只在实验室电脑本地，不进 git
- `参考_Maria_control_py/`：Maria 的 Python 版扫描+采集代码，按代码日期分文件夹存快照（`2026-10-03/`、`2026-10-08/`），参考用不改；根目录 `README.md` 是版本表和更新步骤，各版本 `README.md` 里有参数表、问题和要问 Maria 的

## 07_MATLAB/
- A-line 脚本（`ats9462_aline_test_revised.m` 是当前版）、`bscan_test.m`、`test2.m`（X 电机）、`aline_data/`（10/1、10/3 数据）
- `System_test_09_25/`、`AlazarInclude/`（AlazarDefs.m 等）、`_Mac下载版本/`（Downloads 里的早期版本和 ATS9462_NPT 官方样例，参考用）

## 08_对话记录/
- 所有 PAM 的 Claude Code 对话导出成 Markdown，`INDEX.md` 是目录；`网页/` 放旧账号 claude.ai 对话；`claude-memory/` 是两台电脑旧账号的 Claude 记忆备份

## tools/
- `同步与多账号使用说明.md` —— **换账号、换电脑先看这个**
- `export_pam_chats.py`（导出 Code 对话）、`import_claudeai_export.py`（导入网页对话）、`claudeai_upload/research-progress.zip`（网页上传用）

## .claude/skills/research-progress/
- 9/28 版 skill（含 pam-technical-checks），Claude Code 打开本仓库自动可用

## _to_delete/
- SlowScan_ENdaq.zip — 与 03 里的工程文件夹重复的压缩包，确认不需要后手动删除
- 根目录重复副本_已并入02/ — 9/23 曾散在文件夹根目录的四份 GPT 文件，和 02/GPT原件_已并入master 里的逐字节相同（cmp 核对过），确认后手动删除
