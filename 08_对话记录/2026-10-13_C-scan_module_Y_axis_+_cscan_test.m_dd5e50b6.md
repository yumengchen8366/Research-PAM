---
session: dd5e50b6-cf1b-42d5-9426-841a66229aa5
title: C-scan module: Y axis + cscan_test.m
machine: LabPC
source: dd5e50b6-cf1b-42d5-9426-841a66229aa5.jsonl
exported: 2026-10-14 21:47
---

# C-scan module: Y axis + cscan_test.m


### 🧑 用户 · 2026-10-13 23:03

这个窗口只做一个模块：C-scan（测试信号版，函数发生器当信号，激光关，真实光声信号这周先不做）。用户本周的目标是让 C-scan 准确运行，并熟悉全部代码和流程。

开工先做（按仓库根目录 CLAUDE.md）：
1. 提醒用户先双击 Research-PAM 根目录的 `sync_pam.cmd`；已经双击过就直接 `git pull`。
2. 读 `06_控制程序/docs/工作日志.md` 最后 3 条（最新两条是 2026-10-13 晚和 2026-10-13 深夜）。
3. 读 `06_控制程序/docs/14_C-scan测试流程.md`（本模块的主计划：阶段 0–7，每步有「在做什么 / 为什么」两句），再按需读 docs/13（B-scan 记录）、docs/12（DMA 与 dual-port）、docs/01（硬件）、`07_MATLAB/bscan_test.m`、`07_MATLAB/test2.m`、`07_MATLAB/ats9462_multi_aline.m`。

已经确认的事实（10/13，不用再查）：
- dual-port：NPT AutoDMA（`AlazarBeforeAsyncRead` + `AlazarPostAsyncBuffer`，flags `ADMA_EXTERNAL_STARTCAPTURE | ADMA_NPT`）本身就是 dual-port，代码里没有、也不需要单独开关（SDK 指南 §3.4.1）。板载内存在 readwrite 阻塞时先接住数据，写满约 65,536 条（800 Hz 下约 82 s）才报 ApiBufferOverflow。C-scan 每行单独 arm、每行写盘没问题；整个 C-scan 只用一次阻塞的 readwrite 不行。
- 阻抗：CH A 可以在代码里设（`AlazarInputControlEx`，bscan_test.m:260）；TRIG IN 不可以（`AlazarSetExternalTrigger` 只有耦合和量程，ETR_5V = ETR_5V_50OHM = 0）。TRIG IN 实测 50.2 Ω。
- 10/12 会上说的「约 3 秒卡住」是 readwrite 阻塞（PPT 原文 "MATLAB blocked ~2.3 s"），不是报错。
- B-scan 现在的参数：800 Hz、Δx 5 µm、4 mm/s、DO 时钟 248 kS/s、1024 点、rpb 50；发生器 G1 用 2 Vpp / 1 V（不要 Recall `PAM_bscan`，那是 1.5 Vpp 误读时存的旧版）。
- 还没确认：Y 轴接线（P0.2/P0.3 只是 LabVIEW 前面板标注）、Y 的拨码和 µm/脉冲、方向、行程；行内用匀速扫（bscan_test 现在的写法）还是 Rui 书面计划第 30 行写的 step-and-settle（docs/14 默认先用匀速扫，等 Rui 当面确认）。

协作方式（仓库 CLAUDE.md）：教，不替用户做——先讲原理和每个参数，由用户自己写/改 MATLAB；Claude 指出 `文件:行号` 的问题、给测试步骤和检查清单，没让改就不改用户的 MATLAB 文件。硬件脚本默认 `RUN_HARDWARE = false`。用户 10/13 说学习方法（白纸回忆）暂时先别用，等用户说再用。

建议从这里开始：先问用户今天在不在实验室。
- 在家/离线：按 docs/14 阶段 1，帮用户把 bscan_test.m 复制成 cscan_test.m 后写检查模式（1.1 参数和 assert、1.2 六线时序表、1.3 计划图、1.4 假数据走数据通路），逐段讲解。
- 在实验室：按 docs/14 阶段 0（开工检查）和阶段 2（Y 轴：读拨码、静态电平检查「写 0 时约 0 V」、小步看方向、标定、串扰检查 ctr1 = 0、接回 PFI3 后重跑 B 基准）。
另外提醒用户约 Rui 来看实验（他 10/12 要求做实验前通知他），建议给他看阶段 4–6，并当面问行内运动方式。

收工：工作日志加一条（做了什么 / 结果 / 下次第一步），新事实写进 docs（01 补 Y 轴、14 追加实测结果），按 CLAUDE.md 导出对话、commit，然后提醒用户双击 `sync_pam.cmd`。

### 🤖 Claude · 2026-10-13 23:03

> 🔧 Bash · description: Check git state and locate log entries

### ⚙️ 工具 · 2026-10-13 23:03

<details><summary>工具输出</summary>

```
3a82166 Merge remote-tracking branch 'origin/main'
5ac8b5b 2026-10-13 C-scan: docs/14 测试流程（workflow 调查 + 复核）；补正采集方式与「约3s卡住」出处
e56aab4 2026-10-13 对话记录: 从旧 PAM_research 补入较新的 LabPC Claude 记忆（5 个文件）
226 06_控制程序/docs/工作日志.md
196:**2026-10-13 晚｜master §19/§20 会后更新 + PAM 学习进度搬家（claude.ai 云端会话）**
201:**2026-10-13 晚｜会谈整理稿、master、PAM学习进度 事实更正（LabPC，会话 67ed74c7，开在旧文件夹 PAM_controlProgram）**
210:**2026-10-13 晚｜删 claude.ai「cao meeting」项目里的旧副本（claude.ai 云端会话）**
215:**2026-10-13 深夜｜C-scan 测试流程（docs/14）+ 两处补正（LabPC，会话 67ed74c7）**
223:**2026-10-13 晚｜Mac 上旧文件夹 PAM_research-latest 核对（claude.ai 云端会话，连 Mac）**
01_硬
…[截断，共 912 字符]
```
</details>

### 🤖 Claude · 2026-10-13 23:03

> 🔧 Bash · description: Read last work log entries

### 🤖 Claude · 2026-10-13 23:03

> 🔧 Read · file_path: C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e\06_控制程序\docs\14_C-scan测试流程.md

### ⚙️ 工具 · 2026-10-13 23:03

<details><summary>工具输出</summary>

```
**2026-10-13 晚｜master §19/§20 会后更新 + PAM 学习进度搬家（claude.ai 云端会话）**
- 做了什么：经用户同意，更新 master §19（分成 9/23 前原记录 + 9/24–10/12 新完成 + 10/12 会后本周待办三块，旧条目全保留、补状态）、§20.1（10/12 新增 3 问；9/23 的问题标状态，型号和 SR2 电流两条划掉）、§20.2 加 TRIG IN 阻抗一条；context-conflicts #6 型号改为已解开（ATS9462）。按用户要求，把 learning_skill 里的 PAM 学习进度（C-scan 本周知识点表、B-scan 汇报检查、10/12 会议）搬到 `02_笔记与上下文/PAM学习进度.md`，learning_skill 只留链接。
- 结果：master 头部日期改为 10/13 v1.1。没有新的实验数据。
- 下次第一步：按 §19.3 做——先 ring buffer（docs/12 §三点五），再写切片 workflow 给 Rui、回复 Jenifer。

**2026-10-13 晚｜会谈整理稿、master、PAM学习进度 事实更正（LabPC，会话 67ed74c7，开在旧文件夹 PAM_controlProgram）**
- 做了什么：经用户同意，更正三个
…[截断，共 4120 字符]
```
</details>

### ⚙️ 工具 · 2026-10-13 23:03

<details><summary>工具输出</summary>

```
1	# 14 C-scan 测试流程（测试信号版，第一版 10 × 10）
2	
3	> 2026-10-13 整理。依据：`07_MATLAB/bscan_test.m`（下称 B）、`test2.m`（T2）、docs 01/07/12/13、Rui 的 Phase 1 计划（`02_笔记与上下文/UVPAM_Phase1_Weekly_Integrated_MATLAB_EN.md`，下称 P1）、10/12 会谈整理、Maria 10/8 版 `C_scan.py` / `TS_BC.py`、ATS-SDK 指南。先由 4 个调查代理分头写，再由 4 个复核代理逐条挑错，本文已合并复核意见。
4	> 每一步都有两句话：「在做什么」「为什么」，可以直接写进程序的 `fprintf`，运行时就知道它在干什么。
5	> 标 [条件计算] 的数是按代码和已知参数算出来的，不是实测；**涉及 Y 的数都以「Y 也是 0.5 µm/脉冲」为前提，阶段 2 标定前不算数。**
6	> 本文只设计测试，代码由用户自己写。实测结果另写 `14_C-scan记录.md`（或在本文末尾追加）。
7	
8	## 先定的两件事
9	
10	1. **行内运动方式**
11	   - 口头（10/12 会谈）：Rui 说一直走和走停"只是间隔不一样、两种都可以"，最常规的是每个触发采一条；他也确认现在
…[截断，共 15401 字符]
```
</details>

### 🤖 Claude · 2026-10-13 23:03

> 🔧 Bash · description: Inspect sync script and worktree list

### ⚙️ 工具 · 2026-10-13 23:03

<details><summary>工具输出</summary>

```
@echo off
rem One-click sync for Research-PAM. Double-click at start and end of work. See tools\README in the sync guide, section 6.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\sync_pam.ps1"
pause
C:/Users/2031/Desktop/Research-PAM                                           3a82166 [main]
C:/Users/2031/Desktop/Research-PAM/.claude/worktrees/wizardly-wozniak-c7af7e 3a82166 [claude/wizardly-wozniak-c7af7e]
```
</details>

### 🤖 Claude · 2026-10-13 23:03

开工检查做完了：

- **同步**：我刚 fetch 过 GitHub，`origin/main` 没有比本地更新的提交，主目录和这个 worktree 都在 `3a82166`。如果你在 Mac 或网页上还有没 push 的改动，先双击 Research-PAM 根目录的 `sync_pam.cmd`；没有就不用管。
- **工作日志最后 3 条**：10/13 深夜写好了 docs/14（C-scan 测试流程，阶段 0–7）。下次第一步写的是：离线就做阶段 1（`cscan_test.m` 检查模式），进实验室就做阶段 0 和阶段 2（Y 轴）。另外两条是删 claude.ai 旧副本、核对 Mac 旧文件夹，和 C-scan 无关。
- **docs/14 已读**。这周的卡点在 Y 轴：接线、拨码、µm/脉冲、方向、行程都还没确认。

**先问一句：你今天在实验室（CAOLAB1）吗？**

- **在实验室**：做阶段 0（开工检查）和阶段 2（Y 轴）。顺序是读拨码 → 静态电平「写 0 时约 0 V」→ 小步看方向 → 标定 → 串扰检查（ctr1 = 0）→ 接回 PFI3，重跑 B 基准。
- **不在实验室**：做阶段 1。把 `bscan_test.m` 复制成 `cscan_test.m`，然后按 1.1 参数和 assert → 1.2 六线时序表 → 1.3 计划图 → 1.4 假数据的顺序，一段一段讲，你自己写。

另外别忘了**约 Rui**。10/12 他说做实验前要通知他。建议约在阶段 4（两行）之前，让他看阶段 4–6，并当面问他行内用匀速扫还是 step-and-settle。

### 🤖 Claude · 2026-10-13 23:05

> 🔧 Bash · description: Check bscan_test.m speed line and test2.m header

### ⚙️ 工具 · 2026-10-13 23:05

<details><summary>工具输出</summary>

```
%% 2. 硬件参数
STEP_LINE     = "port0/line0";
DIR_LINE      = "port0/line1";
DAQTRIG_LINE  = "port0/line6";      % → ATS9462 TRIG IN（请确认接线）
LASER_LINE    = "port0/line7";      % → 激光外触发输入（请确认接线和激光的触发要求）
STEPS_PER_REV = 200 * 20;           % SR2 细分设置（以 test2.m 实测校准过的值为准）
UM_PER_PULSE  = 2000 / STEPS_PER_REV;
MAX_SPEED_MM_S = 20;
MAX_TRAVEL_UM  = 20000;             % 单次扫描总行程上限（滑台行程 50 mm）
TRIG_WIDTH_S   = 10e-6;             % 触发脉宽
CLOCK_AI       = "ai1";             % 给数字输出提供时钟的 AI 通道（只读）
FS_MAX         = 250e3;             % AI 时钟上限
DIR_SETUP_S    = 100e-6;
PAUSE_S        = 0.05;              % 扫描结
…[截断，共 2269 字符]
```
</details>

### 🤖 Claude · 2026-10-13 23:05

> 🔧 Bash · description: Search hardware doc for Y-axis info

### ⚙️ 工具 · 2026-10-13 23:05

<details><summary>工具输出</summary>

```
31:| 滑台 | 卓立汉光 CXPF50-80100：行程 50 mm，丝杠导程 2 mm，最高 20 mm/s。X 轴实测端到端约 **27 圈 ≈ 54 mm**（10/7 晚 SR2 断电手轮摇，两个方向一致，±半圈） | ✔（铭牌）+ 实测 |
33:| 电机 | 三个滑台都是信浓 **SST43D2126**（42 型，1.8°/步，1.65 Ω，额定 1.7 A/相；批号 15770G、13610G、13610G，`HW_motor_SST43D2126_*.jpg`）。按 CXP 手册选型表，这个电机只配 CXPF 系列（2 mm 导程），所以 X/Y/Z 都是 2 mm 导程。电机尾部有滚花手轮，和电机轴一起转 | ✔（铭牌） |
41:| SR2 拨码 SW9–12 | 在驱动器另一侧面，ON 朝下。三台都是 **SW9 OFF、SW10 ON、SW11 OFF、SW12 OFF**（`HW_SR2_SW9-12.jpg`）。功能参考 SR2-Plus 资料（SR2 待确认）：SW9 自检（ON 会自己正反转 2 圈）、SW10 步进平滑、SW11 负载惯量、SW12 输入数字滤波 | ✔ 位置 / ◐ 功能 |
53:| Y STEP / DIR | P0.2 / P0.3 | SR2(Y) STEP− / DIR− | TTL | ✔（用户 10/4 说明）
…[截断，共 602 字符]
```
</details>

### 🤖 Claude · 2026-10-13 23:06

> 🔧 Bash · description: Read hardware table section of docs/01

### ⚙️ 工具 · 2026-10-13 23:06

<details><summary>工具输出</summary>

```
| 示波器（另一台？） | 用户报的是 RIGOL DS1104Z-S Plus（100 MHz，带 Source 1/2 输出口）。和 DS1054Z 是不是两台，待确认 | ? |
| 激光 | **Thorlabs NPL45C** 纳秒脉冲激光二极管：450 nm，**Class 3B**，最大平均功率 65 mW，标签写最大单脉冲 650 nJ / 260 ns（官网写脉宽 6–129 ns 可调）。背板：POWER 钥匙开关、INTERLOCK、LASER ON 灯、PULSE WIDTH 旋钮（MIN–MAX）、**TRIGGER IN**（`docs/screenshots/HW_laser_NPL45C_*.jpg`）。**没有内部触发，必须外部触发。** 用户手册 p.11 的触发输入：**AC 耦合，200 mV–2 V，输入阻抗 5 kΩ，最高 50 kHz**；p.9：边沿最慢 1 ms。⚠ 待确认：① 手册写输入电压 200 mV–2 V，P0.7 的 5 V TTL 直接接是否超标，以前是怎么接的；② LabVIEW 的 Trig Rate 100 kHz 超过激光上限 50 kHz，激光位（第 7 位）应该是隔几个触发才发一次（GenerateSkipPulses 的 skip），待读框图确认 | ✔ 铭牌 + 手册 |

## 电机和滑台
| 项目
…[截断，共 4529 字符]
```
</details>

### 🤖 Claude · 2026-10-13 23:06

> 🔧 Edit · file_path: C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e\06_控制程序\docs\14_C-scan测试流程.md

### 🤖 Claude · 2026-10-13 23:06

> 🔧 Edit · file_path: C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e\06_控制程序\docs\14_C-scan测试流程.md

### 🤖 Claude · 2026-10-13 23:06

> 🔧 Edit · file_path: C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e\06_控制程序\docs\14_C-scan测试流程.md

### 🤖 Claude · 2026-10-13 23:06

> 🔧 Edit · file_path: C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e\06_控制程序\docs\14_C-scan测试流程.md

### ⚙️ 工具 · 2026-10-13 23:06

<details><summary>工具输出</summary>

```
The file C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e\06_控制程序\docs\14_C-scan测试流程.md has been updated successfully. (file state is current in your context — no need to Read it back)
```
</details>

### ⚙️ 工具 · 2026-10-13 23:06

<details><summary>工具输出</summary>

```
The file C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e\06_控制程序\docs\14_C-scan测试流程.md has been updated successfully. (file state is current in your context — no need to Read it back)
```
</details>

### ⚙️ 工具 · 2026-10-13 23:06

<details><summary>工具输出</summary>

```
The file C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e\06_控制程序\docs\14_C-scan测试流程.md has been updated successfully. (file state is current in your context — no need to Read it back)
```
</details>

### ⚙️ 工具 · 2026-10-13 23:06

<details><summary>工具输出</summary>

```
The file C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e\06_控制程序\docs\14_C-scan测试流程.md has been updated successfully. (file state is current in your context — no need to Read it back)
```
</details>

### 🤖 Claude · 2026-10-13 23:06

Now the final "还要确认的" list:

### 🤖 Claude · 2026-10-13 23:06

> 🔧 Edit · file_path: C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e\06_控制程序\docs\14_C-scan测试流程.md

### ⚙️ 工具 · 2026-10-13 23:06

<details><summary>工具输出</summary>

```
The file C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e\06_控制程序\docs\14_C-scan测试流程.md has been updated successfully. (file state is current in your context — no need to Read it back)
```
</details>

### 🤖 Claude · 2026-10-13 23:06

> 🔧 ToolSearch · query: select:SendMessage

### ⚙️ 工具 · 2026-10-13 23:06

<details><summary>工具输出</summary>

```
[图片]
```
</details>

### 🤖 Claude · 2026-10-13 23:06

> 🔧 SendMessage

### ⚙️ 工具 · 2026-10-13 23:06

<details><summary>工具输出</summary>

```
{"success":false,"message":"Failed to send to uds:\\\\.\\pipe\\LOCAL\\cc-msg-d206c15f82afdfb129be995b4ceec2b9: No running session has registered an inbox at \\\\.\\pipe\\LOCAL\\cc-msg-d206c15f82afdfb129be995b4ceec2b9 (ENOINBOX: no-key) — refusing to send to an unvouched pipe — the peer process may have restarted, so this socket path is stale. Call ListAgents to get the current address."}
```
</details>

### 🤖 Claude · 2026-10-13 23:07

那 5 条回答已经写进 docs/14（还没 commit）。我想回给那个会话确认一下，但它已经关了，消息没发出去，不影响。

**docs/14 改了这几处**
- **安全**：在 `MAX_SPEED_MM_S` 那条后面注明你同意改成 4（B 和 cscan_test 都用 4）。
- **0.4、2.1**：加了 Y 约 15 cm（你的估计，还没量）、先看 Y 滑台铭牌、看 Y 动时会不会带动 Z 上的水槽。
- **6.6**：中途停止定为 uifigure 的"停止"按钮。
- **末尾待确认清单**：第 2–7 条写上了你的回答，并注明是从哪个会话转来的。

**需要你自己改的 MATLAB**
- `07_MATLAB/bscan_test.m:37`：`MAX_SPEED_MM_S = 20` 改成 `4`。
- `07_MATLAB/test2.m:26` 也是 `20`。今晚另存的 Y 版建议同样改成 `4`。这一处你没明确说过，你来决定。

**Y 的行程有个矛盾**

docs/01 第 33 行的推理是：三个电机都是 SST43D2126，这种电机只配 CXPF（2 mm 导程），所以 X、Y、Z 都是 2 mm 导程。但 CXPF50 的行程是 50 mm，你估计 Y 能走约 15 cm，所以 Y 至少不是同一个型号。导程可能还是 2 mm，也可能不是，**µm/脉冲不能沿用 X 的 0.5**。今晚先找 Y 的铭牌。如果导程是 2 mm，15 cm 端到端约 75 圈，不用全摇一遍：摇到一端轻轻顶住，再按铭牌行程回摇一半，就是中间。

**今晚在实验室：阶段 0 → 阶段 2**

| 步骤 | 做什么 | 为什么 / 要记下的 |
|---|---|---|
| 0.1–0.4 | 关 LabVIEW；按 docs/13 §1–2 逐项设发生器（不要 Recall `PAM_bscan`）；把 X、Y 都摇到中间 | 台架和 Maria 共用，每次都要重做 |
| 2.1 | SR2 断电后找到 Y 驱动器：拍序列号、SW1–8 和铭牌；顺着线确认 P0.2 → STEP−、P0.3 → DIR− | SW5–8 决定每转步数；Y 是 243106105 还是 243106317，到现在还没记过 |
| 2.2 | 用 `write` 把 P0.2 翻 0/1，量 Y 驱动器 STEP− 对地电压 | 见下面的原理 |
| 2.3 | `test2.m` 另存为 Y 版：改 21–23 行（线和方向）、24–25 行（细分和导程）、26–27 行（速度上限和单次上限，单次先设 500 µm 左右）；先跑检查模式，再走 +200 µm | 定下"正数 = 朝哪边"，写进 docs/01 |
| 2.4 | 正反各走 3 次 ±10 mm，ctr 计数 + 数手轮圈数 + 卡尺 | 圈数 × 导程 ÷ 脉冲数 = µm/脉冲 |
| 2.5–2.6 | 有时间再做：速度 1–4 mm/s；接回 PFI3；Y 单独走时看 ctr1 是否为 0；B 重跑 400/400 | 动过接线以后要证明链路和以前一样 |

**2.2 的原理：为什么"写 0 时约 0 V"才算数**

驱动器是共阳极接法：STEP+ 接 +5 V，STEP− 接 P0.2，中间是光耦里的 LED。
- 写 1：P0.2 = 5 V，LED 两端都是 5 V，不导通，STEP− 读到约 5 V。但线根本没接上时，STEP− 也会被 LED 拉到接近 5 V，两种情况分不开。
- 写 0：P0.2 拉到 0 V，LED 导通，STEP− 被拉到约 0 V。只有线真的接到这个端子才会出现这个结果。

所以要看写 0 时是不是 0 V，同时 X、Z 的 STEP− 不跟着变，才能证明 P0.2 接的是 Y。

**注意**：`test2.m:14` 的注释写的是把 P0.0 并到 PFI3。做 Y 计数时，要把 P0.2 并到 PFI3（docs/14 2.4），做完 2.6 再接回 USER 1。

你到实验室开始 0.1 的时候告诉我。读到 Y 的拨码和铭牌，把照片发过来，我和你一起换算每转步数和 µm/脉冲。另外，Rui 来看的日期还没定，可以趁今晚先发消息约他。

### 🤖 Claude · 2026-10-13 23:07

> 🔧 Edit · file_path: C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e\06_控制程序\docs\01_硬件与接线.md

### 🤖 Claude · 2026-10-13 23:07

> 🔧 Edit · file_path: C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e\06_控制程序\docs\14_C-scan测试流程.md

### ⚙️ 工具 · 2026-10-13 23:07

<details><summary>工具输出</summary>

```
The file C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e\06_控制程序\docs\01_硬件与接线.md has been updated successfully.
```
</details>

### ⚙️ 工具 · 2026-10-13 23:07

<details><summary>工具输出</summary>

```
<tool_use_error>String to replace not found in file.
String: - 操作：断电后找到 Y 的 SR2，记下序列号，拍下 SW1–8，顺线核对 P0.2 → STEP−、P0.3 → DIR−。
(note: Edit also tried swapping \uXXXX escapes and their characters; neither form matched, so the mismatch is likely elsewhere in old_string. Re-read the file and copy the exact surrounding text.)</tool_use_error>
```
</details>

### 🤖 Claude · 2026-10-13 23:07

> 🔧 Bash · description: Locate wiring-check line in docs/14

### ⚙️ 工具 · 2026-10-13 23:07

<details><summary>工具输出</summary>

```
135:- 「在做什么」断电后找到 Y 的 SR2，记下序列号，拍下 SW1–8，顺线核对 P0.2 → STEP−、P0.3 → DIR−。
 M 06_控制程序/docs/01_硬件与接线.md
 M 06_控制程序/docs/14_C-scan测试流程.md
```
</details>

### 🤖 Claude · 2026-10-13 23:07

> 🔧 Edit · file_path: C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e\06_控制程序\docs\14_C-scan测试流程.md

### ⚙️ 工具 · 2026-10-13 23:07

<details><summary>工具输出</summary>

```
The file C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e\06_控制程序\docs\14_C-scan测试流程.md has been updated successfully. (file state is current in your context — no need to Read it back)
```
</details>

### 🤖 Claude · 2026-10-13 23:07

看线确认 Y 接线的结果，写进了两个 docs 文件：

- **docs/01 接线表 Y 那一行**：原来就是 ✔（你 10/4 说的），这次补上「10/13 晚看线确认，和 X 一样共阳极，STEP+/DIR+ 接 +5 V」，并注明还要用 2.2 的静态电平检查再用电确认一次。
- **docs/14 2.1**：「顺线核对 P0.2 → STEP−、P0.3 → DIR−」后面标上你已经看线确认。

**`06_控制程序/CLAUDE.md` 我没改。** 那是项目说明文件，我不会因为别的会话转话就去改它，要你自己点头。第 32 行现在是这样：

> P0.2/3 Y、P0.4/5 Z、P0.7 激光触发（LabVIEW 前面板标注，实物待核对）

建议改成：

> P0.2/3 Y（10/13 用户看线确认，共阳极）、P0.4/5 Z、P0.7 激光触发（Z 和激光是 LabVIEW 前面板标注，实物待核对）

同意的话回一句，我就改。

2.2 的静态电平检查我同意留着。看线只能说明线插在了哪个端子上；只有写 0 时 Y 的 STEP− 约 0 V、X 和 Z 的 STEP− 不跟着变，才算用电证明 P0.2 真的通到 Y 的驱动器。这几分钟值得花。

剩下要今晚实测的还是这几样：Y 的方向（DIR = 1 时朝哪边）、SW1–8、铭牌（行程和导程）、µm/脉冲。

### 🤖 Claude · 2026-10-14 13:32

> 🔧 Bash · description: Check main checkout state and my diff

### ⚙️ 工具 · 2026-10-14 13:32

<details><summary>工具输出</summary>

```
3a82166 Merge remote-tracking branch 'origin/main'
5ac8b5b 2026-10-13 C-scan: docs/14 测试流程（workflow 调查 + 复核）；补正采集方式与「约3s卡住」出处
e56aab4 2026-10-13 对话记录: 从旧 PAM_research 补入较新的 LabPC Claude 记忆（5 个文件）
---
---
 06_控制程序/docs/01_硬件与接线.md     |  2 +-
 06_控制程序/docs/14_C-scan测试流程.md | 22 +++++++++++++++-------
 2 files changed, 16 insertions(+), 8 deletions(-)
```
</details>

### 🤖 Claude · 2026-10-14 13:32

主目录是干净的，还在 `3a82166`，可以直接快进合并（fast-forward）。

### 🤖 Claude · 2026-10-14 13:32

> 🔧 Bash · description: Commit docs changes and fast-forward main

### ⚙️ 工具 · 2026-10-14 13:32

<details><summary>工具输出</summary>

```
56be758 2026-10-13 C-scan: docs/14 写入用户对「还要确认的」的回答；Y 接线看线确认（docs/01、14）
Updating 3a82166..56be758
Fast-forward
 06_控制程序/docs/01_硬件与接线.md     |  2 +-
 06_控制程序/docs/14_C-scan测试流程.md | 22 +++++++++++++++-------
 2 files changed, 16 insertions(+), 8 deletions(-)
56be758 2026-10-13 C-scan: docs/14 写入用户对「还要确认的」的回答；Y 接线看线确认（docs/01、14）
3a82166 Merge remote-tracking branch 'origin/main'
```
</details>

### 🤖 Claude · 2026-10-14 13:33

> 🔧 SendMessage

### ⚙️ 工具 · 2026-10-14 13:33

<details><summary>工具输出</summary>

```
{"success":true,"message":"“Ack: committed and ff-merged into main” → uds:\\\\.\\pipe\\LOCAL\\cc-msg-57dbf6809ae8cd32cc7a5599a2625b12; in that session's inbox, not yet read by its Claude — a [Cross-session delivery notice] follows if that session holds it (usually a different permission mode) or refuses it","msg_id":"1b78edd3-4481-4c99-8bc2-31d6b201966b"}
```
</details>

### 🤖 Claude · 2026-10-14 13:33

docs/01 和 docs/14 的修改已经提交（`56be758`），并且合并进了主目录 Research-PAM 的 main。主目录原来没有别的改动，所以是直接快进，没有冲突。你下次双击 `sync_pam.cmd` 时会一起推上 GitHub。

另一个会话转来的分工，我按下面这样理解，你看对不对：

- **今天 Y 轴和 B-scan 巩固**（docs/14 阶段 0、2、2.6、3.1）：去新窗口「Pre-lab briefing + guidance: Y axis and B-scan」做。
- **`cscan_test.m` 草稿**：由「提前完成 cscan 的计划调整」那个会话写，放在主目录 `07_MATLAB/cscan_test.m`，另附 `cscan_replot.m`。我这边不另写，免得出两份。以后读写你要用的文件，我都用主目录的绝对路径，不改 worktree 里的副本。
- **回到这个窗口**：等 Y 的 µm/脉冲和方向写进 docs/01、草稿也写好以后，我逐段讲 `cscan_test.m`，再带你按 docs/14 上硬件，顺序是 3.2 → 4 → 5 → 6。目标是 10/20（周二）前做完；如果请 Rui 周五 10/16 来看 10 × 10，现在就该约他了。

**还有一件事等你决定：** 改不改 `06_控制程序/CLAUDE.md` 第 32 行，也就是把 Y 接线标成「10/13 看线确认，共阳极」（具体改法见上一条）。那是 CLAUDE.md，我不会因为别的会话转话就改，同意的话回一句。

工作日志我这边还没写，因为另一个会话可能同时往日志末尾追加，两边会冲突。等这个窗口真正收工时再写一条。

### 🧑 用户 · 2026-10-14 13:36

这个改不改 06_控制程序/CLAUDE.md 第 32 行，也就是把 Y 接线标成「10/13 看线确认，共阳极」（具体改法见上一条）。那是 CLAUDE.md，我不会因为别的会话转话就改，同意的话回一句是哪一行 要改什么我没找到

### 🤖 Claude · 2026-10-14 13:37

> 🔧 Bash · description: Find the Y wiring line in project CLAUDE.md

### ⚙️ 工具 · 2026-10-14 13:37

<details><summary>工具输出</summary>

```
32:- 数字输出位：P0.0 X STEP、P0.1 X DIR（已实测确认）；P0.6 采集触发（10/7 实测：不带负载 4.97 V，直接推 50 Ω 的 TRIG IN 时 2.84 V；测试时经 BNC-2110 USER 1 → 函数发生器外触发 → TRIG IN，见 `docs/13_B-scan记录.md`）；P0.2/3 Y、P0.4/5 Z、P0.7 激光触发（LabVIEW 前面板标注，实物待核对）。
```
</details>

### 🤖 Claude · 2026-10-14 13:37

在 [06_控制程序/CLAUDE.md:32](06_控制程序/CLAUDE.md:32)，「硬件速查」下面「数字输出位：」那一条。这一行很长，要改的只是**最后一小段**。

**现在的写法**（行尾）：
> ……；P0.2/3 Y、P0.4/5 Z、P0.7 激光触发（LabVIEW 前面板标注，实物待核对）。

**改成：**
> ……；P0.2/3 Y（STEP−/DIR−，10/13 用户看线确认，共阳极）、P0.4/5 Z、P0.7 激光触发（Z 和激光是 LabVIEW 前面板标注，实物待核对）。

前面 P0.0、P0.1、P0.6 的部分一个字都不动。

**为什么要改：** 括号里的「实物待核对」现在把 Y、Z、激光三样都包进去了。你昨晚已经看线确认了 Y，Y 就不该再算待核对；Z 和激光还没人看过实物，所以还是待核对。这个文件每个新窗口开工都会读，不改的话，下一个窗口会以为 Y 的接线还没确认过。

同意就回「改」，我就照上面改，再 commit 合并进 main。不想改也行，docs/01 的接线表已经写了 10/13 看线确认，事实不会丢。

### 🧑 用户 · 2026-10-14 13:38

是的现在的是对的 z目前先不用但是和labview是一样的到时候可以再确认 P0.2/3 Y（STEP−/DIR−，10/13 用户看线确认，共阳极）这个是对的可以更新一下

### 🤖 Claude · 2026-10-14 13:38

> 🔧 Bash · description: Check whether main moved since last merge

### 🤖 Claude · 2026-10-14 13:38

> 🔧 Read · file_path: C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e\06_控制程序\CLAUDE.md

### ⚙️ 工具 · 2026-10-14 13:38

<details><summary>工具输出</summary>

```
56be758 2026-10-13 C-scan: docs/14 写入用户对「还要确认的」的回答；Y 接线看线确认（docs/01、14）
3a82166 Merge remote-tracking branch 'origin/main'
5ac8b5b 2026-10-13 C-scan: docs/14 测试流程（workflow 调查 + 复核）；补正采集方式与「约3s卡住」出处
---
56be758 2026-10-13 C-scan: docs/14 写入用户对「还要确认的」的回答；Y 接线看线确认（docs/01、14）
```
</details>

### ⚙️ 工具 · 2026-10-14 13:38

<details><summary>工具输出</summary>

```
32	- 数字输出位：P0.0 X STEP、P0.1 X DIR（已实测确认）；P0.6 采集触发（10/7 实测：不带负载 4.97 V，直接推 50 Ω 的 TRIG IN 时 2.84 V；测试时经 BNC-2110 USER 1 → 函数发生器外触发 → TRIG IN，见 `docs/13_B-scan记录.md`）；P0.2/3 Y、P0.4/5 Z、P0.7 激光触发（LabVIEW 前面板标注，实物待核对）。
```
</details>

### 🤖 Claude · 2026-10-14 13:38

> 🔧 Edit · file_path: C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e\06_控制程序\CLAUDE.md

### ⚙️ 工具 · 2026-10-14 13:38

<details><summary>工具输出</summary>

```
The file C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e\06_控制程序\CLAUDE.md has been updated successfully.
```
</details>

### 🤖 Claude · 2026-10-14 13:38

> 🔧 Bash · description: Commit CLAUDE.md edit and fast-forward main

### ⚙️ 工具 · 2026-10-14 13:38

<details><summary>工具输出</summary>

```
Updating 56be758..0ba1bf5
Fast-forward
 06_控制程序/CLAUDE.md | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
0ba1bf5 2026-10-14 C-scan: 06_控制程序/CLAUDE.md 硬件速查标 Y 接线已看线确认（用户同意）
56be758 2026-10-13 C-scan: docs/14 写入用户对「还要确认的」的回答；Y 接线看线确认（docs/01、14）
P0.2/3 Y（STEP−/DIR−，10/13 用户看线确认，共阳极）、P0.4/5 Z、P0.7 激光触发（Z 和激光是 LabVIEW 前面板标注，实物待核对）。
```
</details>

### 🤖 Claude · 2026-10-14 13:38

改好了：[06_控制程序/CLAUDE.md:32](06_控制程序/CLAUDE.md:32) 的行尾现在是

> P0.2/3 Y（STEP−/DIR−，10/13 用户看线确认，共阳极）、P0.4/5 Z、P0.7 激光触发（Z 和激光是 LabVIEW 前面板标注，实物待核对）。

这次改动已提交（`0ba1bf5`），并且合并进了主目录的 main，主目录里打开的那个文件已经是新版本。双击 `sync_pam.cmd` 时会和前面 docs 的改动一起推上去。

Z 按你说的先不管，括号里留着「待核对」，等用到 Z 的时候再看线确认。

下一行 [06_控制程序/CLAUDE.md:33](06_控制程序/CLAUDE.md:33) 写的「滑台 CXPF50-80100，0.5 µm/脉冲」其实只是 X 的数据。Y 可能是别的型号（行程约 15 cm），这次先不改。等新窗口把 Y 的铭牌和 µm/脉冲测出来，再一起改成分轴写。

### 🤖 Claude · 2026-10-14 14:39

> 🔧 Bash · description: Check main log and cscan_test.m structure

### ⚙️ 工具 · 2026-10-14 14:39

<details><summary>工具输出</summary>

```
0fab09a 2026-10-14 C-scan: cscan_test.m / cscan_replot.m 第一版草稿（检查模式 + 假数据离线测试通过，硬件路径未运行）
0ba1bf5 2026-10-14 C-scan: 06_控制程序/CLAUDE.md 硬件速查标 Y 接线已看线确认（用户同意）
56be758 2026-10-13 C-scan: docs/14 写入用户对「还要确认的」的回答；Y 接线看线确认（docs/01、14）
3a82166 Merge remote-tracking branch 'origin/main'
---
 1034 C:/Users/2031/Desktop/Research-PAM/07_MATLAB/cscan_test.m
  132 C:/Users/2031/Desktop/Research-PAM/07_MATLAB/cscan_replot.m
 1166 total
---
1:%% C-scan：逐行扫描。行内 = bscan_test 的匀速扫描；行与行之间 = X 回程 + Y 走一步
29:%% 1. 扫描参数（docs/14 附 A：第一版 10 x 10）
43:%% 2. 硬件参数
82:%% 3. 换算与检查（docs/14 1.1）
182:%% 4. 生成时序表（docs/14 1.2）：每
…[截断，共 2302 字符]
```
</details>

### 🤖 Claude · 2026-10-14 14:39

> 🔧 Bash · description: Fast-forward worktree and read table builders

### ⚙️ 工具 · 2026-10-14 14:39

<details><summary>工具输出</summary>

```
0fab09a 2026-10-14 C-scan: cscan_test.m / cscan_replot.m 第一版草稿（检查模式 + 假数据离线测试通过，硬件路径未运行）
function T = buildRowTable(P)
% 行扫描表：和 bscan_test 第 4 节一样（加速 → 匀速 + 每 K 步一个触发 → 减速），只是没有返回段，列数变成 6。
% 以后改成 step-and-settle（docs/14 附 B）只换这个函数：输出仍然是"开头 lead 行、NX 个触发、最后一行全 0"。
    C = P.COL;
    up     = rampPeriods(P.nRamp, P.START_FREQ_HZ, P.stepFreq, P.fs, P.pScan);
    seg    = [up; repmat(P.pScan, P.nScan, 1); flipud(up)];         % 每一步占几行
    trigOn = [false(P.nRamp, 1); mod((0:P.nScan-1)', P.K) == 0; false(P.nRamp, 1)];
    stepX  = stepColumn(seg);
    starts = [0; cumsum(seg(1:end-1))];            
…[截断，共 2351 字符]
```
</details>

### 🤖 Claude · 2026-10-14 14:39

`cscan_test.m` 的草稿已经写好，提交到了主目录的 main（`0fab09a`），我这个 worktree 也已同步到这一版。

**草稿的状态**（那个会话报告的，我还没逐行复核）
- 文件：[07_MATLAB/cscan_test.m](07_MATLAB/cscan_test.m)（1034 行）和 [07_MATLAB/cscan_replot.m](07_MATLAB/cscan_replot.m)（132 行）。
- 检查模式和假数据离线都通过：10 × 10 时 K = 20、fs = 248000、每行 0.683 s、全程 6.91 s、MAP(3,7) = 3.07，重读后 `isequal` 为 1。
- 真正跑硬件的 `runCscan` 从来没运行过。

**要你决定：docs/14 附 A 要不要按代码改**

草稿把 50 ms 停稳都放进了「回程 + Y 表」，所以时长的分法和 docs/14 写的不一样。每行总时长还是 0.68 s，没变：

| | docs/14 现在写的 | 代码里实际的 |
|---|---|---|
| 行扫描表 | 约 0.37 s | 约 0.32 s（加减速各 0.149 s + 200 脉冲 @ 8 kHz 0.025 s + DIR 建立） |
| 回程 + Y 表 | 约 0.31 s | 约 0.36 s（前后两次停稳 0.1 s + X 回程 0.25 s + Y 0.01 s） |
| 3.2 的通过标准 | readwrite ≥ 0.37 s | readwrite ≥ 0.32 s |

我看了 `buildRowTable` / `buildMoveTable`（[cscan_test.m:341](07_MATLAB/cscan_test.m:341)），按代码算出来确实是这样。另外代码在每一段 DIR 的**前后**各留 25 行，bscan_test 只在开头留，docs/14 1.2 也要顺带写上这一点。**同意的话回一句，我就改 docs/14 的附 A、1.2 和 3.2 这三处。**

**等你做完 Y 轴、回到这个窗口时**
1. 先在 `cscan_test.m` 里填 `Y_UM_PER_PULSE`、`Y_POSITIVE_DIR`、`Y_DRIVER_SN`，再把 `Y_CALIBRATED` 改成 `true`（§8 和 `runCscan` 都会 assert 这一项，不填跑不了）。
2. 按 §1 → §9、再按函数的顺序一段一段讲，每段先由你说出它在做什么。讲之前我会先自己通读一遍，挑出要特别注意的地方。
3. 然后上硬件，从阶段 3.2（NY = 1）开始。那个会话列了第一次要盯的几件事：每行重新 arm 是否正常、`fsActual` 有没有被取整、结束时会不会出现 `Cscan:Abort` 警告、Y 不动。

还有两个点要记住：
- **停止只用停止按钮**。按 Ctrl+C 不会进 catch，清理代码不会执行。
- **STEP 在哪个边沿走步**：审查发现 bscan_test 的注释把边沿数错了，代码没动。这件事影响触发和步进的相位，适合带去问 Rui。

### 🧑 用户 · 2026-10-14 21:03

这个窗口只做一个模块：C-scan 上硬件（cscan_test.m），对应 06_控制程序/docs/14_C-scan测试流程.md 的阶段 3.2 → 4.1 → 4.2（时间够再 5）。Y 轴标定和 B-scan 巩固已在另一个窗口做完（会话 39c1b058 / 0dbc3483），这里不重做。

重要：我的 MATLAB 从主目录 C:\Users\2031\Desktop\Research-PAM\07_MATLAB 运行。如果本窗口开在 .claude\worktrees\... 里，先把分支同步到 main（GitHub 已在 7f65958），读写我要用的文件和 docs 一律以主目录为准，不要只改 worktree 里的副本。

开工先做：
1. sync_pam.cmd 我已经双击过（7f65958）；本窗口先 git pull / 同步 main。
2. 读：工作日志最后 3 条（含「2026-10-14 下午｜Y 轴 + B-scan 巩固」和「cscan_test.m 第一版草稿」）；docs/14 附 A、阶段 3–5、末尾「实测记录 2026-10-14」上午 + 下午；docs/13 §3.4、§7（示波器读数）、§8（bscan 两张图怎么读）；07_MATLAB/cscan_test.m 全文、cscan_replot.m。

我的要求：上硬件之前先让我了解四件事——(1) 流程：3.2/4.1/4.2 各在做什么、为什么；(2) 预期结果：每一步看到什么数才算通过；(3) 参数：值、单位、含义、在哪一行；(4) 代码：cscan_test.m 按段讲，我要能说清每段干什么（硬件路径 runCscan 从没跑过，重点讲 arm 顺序、每行 Abort、catch 顺序、停止按钮）。先讲，再现场一步步带。教，不替我做：cscan_test.m 由我自己改，你给 文件:行号 和检查清单；每个阶段先检查模式，RUN_HARDWARE = false 是默认，用完改回。

我要自己填的（行号以当前文件为准，先核对）：
- Y_UM_PER_PULSE = 0.5（第 51 行附近；注释里「行程约 15 cm」作废）
- Y_POSITIVE_DIR：cscan_test 定义是「行号增加时 DIR 的电平」；实测 DIR = 1 → Y 朝电机走。先和我讨论行号朝哪边增加，再填 1 或 0
- Y_DRIVER_SN = "243106105"
- 然后 Y_CALIBRATED = true（第 27 行附近）

已确认的事实（不用再查，出处 docs/01、docs/14 10/14 记录）：
- Y：SR2 243106105，拨码同 X（0.3 A、4000 步/转），导程 2 mm（手摇 27 圈 ≈ 54 mm），0.5 µm/脉冲（20000 脉冲 = 10 mm，ctr1 = 20000）；MOVE_UM > 0 / DIR = 1 = 朝电机；不加速 1–4 mm/s 来回不失步；PFI3 在 USER 1 时 Y 以 4 mm/s 走 ctr1 = 0（无串扰）。P0.2 → Y STEP−、P0.3 → Y DIR−，共阳极。
- X：P0.0/P0.1，0.5 µm/脉冲，DIR = 1 朝电机，不加速 ≤ 4 mm/s。
- 触发链：P0.6 → USER 1 → DG852 背面 CH1 AUX（三通）→ 短线 → CH2 AUX；10MHz REF 必须空着；G1 → 示波器 CH2 + TRIG IN；G2 → 示波器 CH3 + CH A；USER 1 端子并线到 PFI3（ctr1 数 P0.6）。发生器按 docs/13 §2（CH2 必须 Square）。示波器开工检查按 docs/13 §7.5。
- 10/14 基准：bscan_test.m 默认参数（第 37 行已改 4）ctr1 400、400/400、rail 0、上升沿 1.9261–1.9327 µs、标准差 1.92 ns、脉冲高 1.045–1.054 V；CH3 1.06 V（CH A 50 Ω 由程序设置）。3.1（100 µm、10 µm、400 Hz、rpb 2）：ctr1 10、10/10、rail 0、1.9265–1.9317 µs。
- 现在台架：并线在 USER 1；X、Y 都在胶带记号上（Y 胶带贴在联轴器上，钢尺 0 点顶跟 Y 走的那块件，原点约 4.3 cm）；KORAD 23.88 V C.V；发生器两路 Output 开。
- cscan_test.m（工作日志）：硬件路径没跑过；Ctrl+C 不会进 catch，停止只用窗口按钮、行间生效；每行约 0.32 s 扫描 + 0.36 s 回程 + Y，所以 3.2 的判据是 readwrite ≥ 0.32 s。
- ⚠ test2_y.m 用 07_MATLAB/pos_Y.mat 记 Y 的累计命令位置（现在 = 0，不进 git）。cscan_test 动 Y 时这个文件不会更新：C-scan 跑完 Y 必须回到起点，否则之后用 test2_y 前先手摇回记号并 pos_um = 0; save('pos_Y.mat','pos_um')。

各阶段预期（讲解时用，也是通过标准）：
- 3.2（Ny = 1，参数同 3.1）：ctr1 = 10、10/10、rail 0，上升沿和 3.1 同一区间；Y 不动；X 回到记号；readwrite ≥ 0.32 s。
- 4.1（Ny = 2，ATS_ENABLE = false，Δy 先 200 µm = 400 脉冲 ≈ Y 联轴器转 36°，PAUSE_BETWEEN_ROWS = true）：每行 ctr1 = 10；X 每行回记号；Y 方向和预期一致；结束两轴都回记号。
- 4.2（ATS 每行重新 arm）：每行 10/10、ctr1 每行 10、合计 20；两行上升沿区间一致；无 ApiBufferOverflow。
- docs/14 2.5 后半「连走 9 次 Δy、每次停 50 ms」还没做，可用 cscan_test 的「回程 + Y」表补。

Rui：建议他从阶段 4 开始看；当面问「行内用匀速扫还是 step-and-settle」（他 Phase 1 计划第 30 行写 step-and-settle）。第一版先用匀速扫跑 3.2 / 4.1 没问题。

收工：工作日志（主目录）加一条；结果写进 docs/14（新开「实测记录」小节或 14_C-scan记录.md）；按 CLAUDE.md 导出本次对话、commit 到 main，然后提醒我双击 sync_pam.cmd。收工前确认 cscan_test.m、bscan_test.m、test2_y.m 都是 RUN_HARDWARE = false，Y 回到起点，KORAD 关、发生器 Output 关。我来了朋友

### 🤖 Claude · 2026-10-14 21:03

> 🔧 Bash · description: Check main checkout against GitHub

### ⚙️ 工具 · 2026-10-14 21:04

<details><summary>工具输出</summary>

```
## main...origin/main
7f65958 2026-10-14 Y 轴: bscan_test.m:37 MAX_SPEED_MM_S 改 4（用户改）；新增 test2_y.m（Y 轴移动 + 累计位置 + ±12 mm 软件限位）
71354f4 2026-10-14 Y 轴: 导出下午会话 0dbc3483；.gitignore 忽略 07_MATLAB/pos_*.mat（本机滑台位置记录）
7d9fe7f 2026-10-14 Y 轴: 3.1 短行 10/10；docs/13 §8 bscan 两张图怎么读；工作日志
4538030 2026-10-14 Y 轴: 2.2–2.6 完成（Y 0.5 µm/脉冲、朝电机为正、1–4 mm/s 不失步、串扰 0）；B-scan 基准 400/400；docs/13 §7 示波器读数说明
4a49ccc 2026-10-14 Y 轴 pre-lab: 台架找回（REF 三通、CH2 Sine、示波器 D）；Y 驱动器 243106105 拨码同 X；2.2 STEP− 确认（docs/01、13、14）
0fab09a 2026-10-14 C-scan: cscan_test.m / cscan_replot.m 第一版草稿（检查模式 + 假数据离线测试通过，硬件路径未运行）

7f65958 2026-1
…[截断，共 690 字符]
```
</details>

### 🤖 Claude · 2026-10-14 21:04

> 🔧 Bash · description: Fast-forward worktree; locate last log entries

### ⚙️ 工具 · 2026-10-14 21:04

<details><summary>工具输出</summary>

```
7f65958 2026-10-14 Y 轴: bscan_test.m:37 MAX_SPEED_MM_S 改 4（用户改）；新增 test2_y.m（Y 轴移动 + 累计位置 + ±12 mm 软件限位）
223:**2026-10-13 晚｜Mac 上旧文件夹 PAM_research-latest 核对（claude.ai 云端会话，连 Mac）**
228:**2026-10-14｜cscan_test.m 第一版草稿（LabPC，会话 67ed74c7「提前完成 cscan 的计划调整」；用户要求 Claude 先写一版，复习时用户自己重写）**
237:**2026-10-14｜Pre-lab：Y 轴 + B-scan 巩固（LabPC，会话 39c1b058）**
245:**2026-10-14 下午｜Y 轴 + B-scan 巩固 现场（LabPC，会话 0dbc3483，接上午 39c1b058）**
```
</details>

### 🤖 Claude · 2026-10-14 21:04

> 🔧 Bash · description: Read last 3 work log entries

### ⚙️ 工具 · 2026-10-14 21:04

<details><summary>工具输出</summary>

```
**2026-10-14｜cscan_test.m 第一版草稿（LabPC，会话 67ed74c7「提前完成 cscan 的计划调整」；用户要求 Claude 先写一版，复习时用户自己重写）**
- 做了什么：用 workflow 写 `07_MATLAB/cscan_test.m`（1034 行）和 `cscan_replot.m`（132 行）：1 个代理按 docs/14 写代码，3 个代理分别从时序/安全、ATS DMA/清理、数据/可读性三方面挑错，1 个代理只改确认过的问题并重测。全程只在 scratchpad 的副本上用 `matlab -batch` 跑检查模式和假数据，没有调用任何 daq/Alazar 函数；bscan_test.m、test2.m 没动。
- 结果：
  - 结构：开关（默认 RUN_HARDWARE = false、MOCK_DATA = true、Y_CALIBRATED = false）→ §1 参数（docs/14 附 A：10×10、Δ 10 µm、4 mm/s）→ §2 硬件参数（CH A 阻抗、TRIG IN 量程写成命名参数；postedBuffers = Inf，4 = ring buffer）→ §3 换算和 assert → §4 生成 4 张表（行扫描、回程 + Y、最后一行、退回起点）→ §5 逐表检查和计划图 → §
…[截断，共 3573 字符]
```
</details>

### 🤖 Claude · 2026-10-14 21:04

> 🔧 Read · file_path: C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_test.m

### ⚙️ 工具 · 2026-10-14 21:04

<details><summary>工具输出</summary>

```
1	%% C-scan：逐行扫描。行内 = bscan_test 的匀速扫描；行与行之间 = X 回程 + Y 走一步
2	%
3	%  原理（每张表都由 Dev1 同一个硬件时钟输出，6 条线严格同步）：
4	%    行扫描表（每行都一样）：X 加速 → 匀速（每走 K 个脉冲 = DX_UM，P0.6 发一个触发 → ATS 采一条 A-line）→ 减速
5	%                            这一段和 bscan_test 完全相同（400/400、ctr1 = 400 已验证，docs/13 §3.1–3.3）
6	%    回程 + Y 表：停稳 → X 以 X_RETURN_SPEED 退回本行起点（不加速）→ Y 前进 DY_UM（不加速）→ 停稳
7	%    退回起点表：全部扫完（或中途停止）后，按累计命令位置让 X、Y 都回到开工时的位置
8	%  单向光栅：每行都朝同一个方向扫（X 是快轴，Y 是慢轴），回程不采数据。
9	%  每行的步骤（docs/14 4.2）：① arm ATS → ② 行扫描表 → ③ 取数、Abort、读 ctr1 → ④ 存盘 → ⑤ 看停止按钮 → ⑥ 回程 + Y。
10	%  行与行之间没有 P0.6，所以每行重新 arm 的空档不会漏触发；数据在电机再动之前就存好。
11	%
12	%  使用顺序
…[截断，共 19292 字符]
```
</details>

### 🤖 Claude · 2026-10-14 21:04

> 🔧 Read · file_path: C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_test.m

### ⚙️ 工具 · 2026-10-14 21:04

<details><summary>工具输出</summary>

```
320	end
321	
322	function p = rampPeriods(n, f0, f1, fs, pMin)
323	% 线性加速：步频从 f0 增加到 f1，返回每一步的行数（同 bscan_test）
324	    if n == 0
325	        p = zeros(0, 1);
326	        return
327	    end
328	    f = linspace(min(f0, f1), f1, n)';
329	    p = max(pMin, round(fs ./ f));
330	end
331	
332	function col = stepColumn(periods)
333	% 每一步：前一半行为高，后一半为低（同 bscan_test）
334	    starts = [0; cumsum(periods(1:end-1))];
335	    col = false(sum(periods), 1);
336	    for i = 1:numel(periods)
337	        col(starts(i) + (1:max(1, floor(periods(i) / 2)))) = true;
338	    end
339	end
340	
341	function T = buildRow
…[截断，共 18577 字符]
```
</details>

### 🤖 Claude · 2026-10-14 21:04

正在通读 `cscan_test.m`（已读到第 730 行，剩硬件路径 `runCscan` 和 ATS 函数），读完就整理成讲解。

### 🤖 Claude · 2026-10-14 21:04

> 🔧 Read · file_path: C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_test.m

### ⚙️ 工具 · 2026-10-14 21:04

<details><summary>工具输出</summary>

```
730	end
731	
732	function cscan = runCscan(plan, P, ATS, cscan, f)
733	% 真正上硬件。循环外只准备一次；循环里每行：arm → 行扫描 → 取数 → 存盘 → 看停止按钮 → 回程 + Y。
734	% 写成函数（同 bscan_test 的 runBscan），这样不管正常结束、报错还是 Ctrl+C，onCleanup 都会释放 ATS 的 buffer。
735	    assert(P.RUN_HARDWARE && P.Y_CALIBRATED, 'Cscan:NotArmed', '检查模式或 Y 未标定：不碰硬件。');
736	    NX = P.NX;  NY = P.NY;
737	
738	    % ---- 循环外只做一次 ----
739	    cnt = [];
740	    if P.COUNT_CHECK
741	        cnt = daq("ni");
742	        addinput(cnt, "Dev1", "ctr1", "EdgeCount");      % 计数输入在 PFI3 (P1.3)
743	        resetcounters(cnt);
744	    end
745	    H = [];
746	    if P.ATS
…[截断，共 14142 字符]
```
</details>

### 🤖 Claude · 2026-10-14 21:04

> 🔧 Bash · description: List docs/14 section headings

### ⚙️ 工具 · 2026-10-14 21:04

<details><summary>工具输出</summary>

```
8:## 先定的两件事
16:## 安全（每次上硬件都适用）
27:## 附 A　第一版 10 × 10 的参数 [条件计算]
51:## 附 B　如果行内改成 step-and-settle
58:## 阶段 0　开工检查
60:**0.1 软件和文件**
67:**0.2 接线和示波器**
74:**0.3 发生器**
86:**0.4 滑台位置和 SR2**
94:## 阶段 1　离线检查模式（不碰硬件，Mac 上也能做）
96:**1.1 参数换算和 assert**
108:**1.2 生成所有时序表并逐表检查**
118:**1.3 计划图和时间表**
125:**1.4 用假数据走一遍数据通路**
132:## 阶段 2　Y 轴（照 X 轴的做法，docs/07 第 1 周 1.2）
134:**2.1 认出 Y 驱动器、读拨码**
143:**2.2 静态电平检查（SR2 断电）**
150:**2.3 小步看方向**
157:**2.4 标定 µm/脉冲 + 计数**
166:**2.5 速度和 C-scan 小步**
173:**2.6 收尾：接回 PFI3 + 串扰检查 + 重跑基准**
180:## 阶段 3　单行 C-scan = B-scan 回归
182:**3.1 先只改参数、不改代码**
188:**3.2 新代码，Ny = 1**
195:## 
…[截断，共 2224 字符]
```
</details>

### 🤖 Claude · 2026-10-14 21:04

> 🔧 Bash · description: Read docs/14 stages 3-5 and measurement records

### ⚙️ 工具 · 2026-10-14 21:04

<details><summary>工具输出</summary>

```
## 阶段 3　单行 C-scan = B-scan 回归

**3.1 先只改参数、不改代码**
- 「在做什么」直接用 B，设 `DX_UM = 10`、`TRIG_RATE_HZ = 400`、`SCAN_LENGTH_UM = 100`、`recordsPerBuffer = 2`，得到 Nx = 10、每行 5 个 buffer。
- 「为什么」每次只改一处：先单独证明"短行 + 小 buffer"这个组合能收齐，再改代码。
- 通过：ctr1 = 10、10/10、rail 0。
- 失败先查：Nx 是不是被 B:64 凑成了别的数。

**3.2 新代码，Ny = 1**
- 「在做什么」`cscan_test.m` 只扫 1 行，参数和 3.1 一样。
- 「为什么」Ny = 1 时新代码必须变回已验证的 B-scan；对不上，就说明问题出在改写上。
- 操作：先检查模式核对打印，再上硬件；用 tic/toc 记下 readwrite 的时间。
- 通过：和 3.1 结果一致；Y 手轮不动；X 回到记号；readwrite 时间 ≥ 0.37 s。
- 失败先查：ATS 是不是在 readwrite **之前** arm 的（B:283-296 的顺序）。

## 阶段 4　两行（Rui 来看可以从这里开始）

**4.1 两行，只动电机（ATS 不 arm）**

…[截断，共 8212 字符]
```
</details>

### 🤖 Claude · 2026-10-14 21:04

> 🔧 Bash · description: List docs/13 headings

### ⚙️ 工具 · 2026-10-14 21:04

<details><summary>工具输出</summary>

```
1:# 13 B-scan 测试记录（07 第 2 周：测试信号版）
3:## 一句话
6:## 1 接线（10/7 测试用，激光不接）
15:## 2 发生器设置（DG852 Pro，`HW_DG852_burst_settings_1007.jpg`）
31:## 3 测试结果
50:### 3.1 10/7 晚（约 20:45–22:45，LabPC）：测试 ⑥、计数、测试 ②
72:### 3.2 10/9 晚–10/10 凌晨（LabPC）：接线被改动后按 §1–2 重新接回
95:### 3.3 10/9 下午（LabPC，电脑时钟约 13:00 起）：TRIG IN 阻抗和门槛、约 10 ns 跳变
128:### 3.4 10/14 下午（LabPC）：台架复原后重跑基准（docs/14 2.6）
158:## 4 07 第 2 周 6 项测试的进度
168:## 5 还没做 / 待确认
177:## 6 全部 B-scan 测试总览（10/7 整理）
187:### 6.1 10/6–10/7 补充：各设备干什么、实际参数、复核
201:### 6.2 9/25 LabVIEW Forward DO 解码（只用电脑）
216:### 6.3 10/3 `bscan_test.m` 离线检查（只用电脑）
222:### 6.4 10/4 晚：电机标定 + B-sca
…[截断，共 930 字符]
```
</details>

### 🤖 Claude · 2026-10-14 21:04

> 🔧 Bash · description: Read docs/13 sections 3.4, 7, 8

### ⚙️ 工具 · 2026-10-14 21:04

<details><summary>工具输出</summary>

```
### 3.4 10/14 下午（LabPC）：台架复原后重跑基准（docs/14 2.6）
背景：上午发现台架被人动过（发生器背面三通插在 10MHz REF、CH2 被改成 Sine、示波器 D = 39 ms），按 §1–2 改回（docs/14 末尾 10/14 记录）。下午又因为 Y 标定挪过两次 PFI3 并线。这次用 `bscan_test.m` 默认参数原样跑一次，证明整条链和 10/9 一样。
- 改动：`bscan_test.m:37` `MAX_SPEED_MM_S` 20 → **4**（用户自己改，10/13 同意的永久改动）；`SAVE_DATA = true` 存了基准文件。
- 检查模式 [条件计算]：`A-line 数 400，间距 5.00 um，B-scan 长度 2.00 mm`；`4.00 mm/s，8000 Hz，800 Hz，248000 S/s`；`总行程 2.40 mm，总用时 2.32 s，结束位置 +0.0 um`。
- 硬件 [实测]（`MATLAB_1014_bscan_baseline.jpg`，数据 `07_MATLAB\bscan_data\bscan_20261014_164707.mat`，bscan_data 不进 git，只在 LabPC 本地）：

  | 项 | 10/14 | 10/9（§3.3） |
 
…[截断，共 6750 字符]
```
</details>

### 🤖 Claude · 2026-10-14 21:04

> 🔧 Bash · description: Read bscan_test.m hardware function for comparison

### 🤖 Claude · 2026-10-14 21:04

> 🔧 Read · file_path: C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_replot.m

### ⚙️ 工具 · 2026-10-14 21:04

<details><summary>工具输出</summary>

```
function col = stepColumn(periods)
% 每一步：前一半行为高，后一半为低
    starts = [0; cumsum(periods(1:end-1))];
    col = false(sum(periods), 1);
    for i = 1:numel(periods)
        col(starts(i) + (1:max(1, floor(periods(i) / 2)))) = true;
    end
end

function raw = runBscan(do, fs, doLines, clockAI, Nx, P)
% 先把 ATS9462 准备好（所有 DMA buffer 预先提交），再让 Dev1 输出整个时序。
    addpath(P.sdkInclude);
    AlazarDefs;
    alazarLoadLibrary();
    board = AlazarGetBoardBySystemID(int32(1), int32(1));
    [~, bits] = AlazarGetChannelInfo(board);
    assert(double(bits) == 16, 'Expected 16-bit ATS9462.');

    rateIds  = co
…[截断，共 3361 字符]
```
</details>

### ⚙️ 工具 · 2026-10-14 21:04

<details><summary>工具输出</summary>

```
1	%% C-scan 重读：只用文件里的 raw 重新算 MAP 和上升沿时间，再和运行时存的值逐点比较（docs/14 6.4）
2	%
3	%  不调用任何采集代码，不碰硬件，别的电脑上也能跑。
4	%  注意：cscan_data 不进 git（.gitignore），sync_pam 不会同步数据文件，要在别的电脑上看得自己拷过去。
5	%  用法：
6	%    1. 直接运行：读当前文件夹下 cscan_data 里最新的 cscan_*.mat（假数据文件叫 cscan_mock_*.mat，也会被找到）
7	%    2. 先在命令行设 REPLOT_FILE = '完整路径\cscan_xxx.mat'，再运行本脚本
8	%  通过：isequal(MAP)、isequal(nEdge)、isequaln(tEdge) 都是 1；MAP 图和运行时的一样。
9	%  computeMAP / quickCheckRow / toVolts 是从 cscan_test.m 原样抄过来的，改一边要同时改另一边。
10	
11	%% 1. 选文件
12	if ~exist('REPLOT_FILE', 'var') || isempty(REPLOT_FILE)
13	    dataDir = fullfile(pwd, 'cscan_data');
14	    
…[截断，共 5400 字符]
```
</details>

### 🤖 Claude · 2026-10-14 21:05

> 🔧 Bash · description: Compare counter handling and locate MATLAB

### ⚙️ 工具 · 2026-10-14 21:05

<details><summary>工具输出</summary>

```
19:COUNT_CHECK     = true;    % true：用 ctr1 数 P0.6 的上升沿，需先用导线把 USER 1 端子（P0.6）并接到 PFI3 (P1.3)
155:clear d dq cnt
156:daqreset
158:if COUNT_CHECK
159:    cnt = daq("ni");
160:    addinput(cnt, "Dev1", "ctr1", "EdgeCount");   % 计数输入在 PFI3 (P1.3)
161:    resetcounters(cnt);
162:    c0 = read(cnt, "OutputFormat", "Matrix");
168:if COUNT_CHECK
169:    c1 = read(cnt, "OutputFormat", "Matrix");
171:    fprintf('ctr1 实测 P0.6 上升沿：%d（应为 %d）\n', nTrigCount, Nx);
172:    clear cnt
184:if COUNT_CHECK
185:    bscan.trigCount = nTrigCount;               % ctr1 数到的 P0.6 上升沿个数
297:    clear dq
---
16:RUN_HARDW
…[截断，共 2274 字符]
```
</details>

### 🤖 Claude · 2026-10-14 21:05

> 🔧 Bash · description: Make scratch copies with stage parameters

### ⚙️ 工具 · 2026-10-14 21:05

<details><summary>工具输出</summary>

```
== c32
RUN_HARDWARE       = false;  % false：只算时序、检查
LASER_ENABLE       = false;  % false：P0.7 一直是 0
ATS_ENABLE         = true;   % false：只动电机 + ctr1 �
NY                  = 1;       % 行数 = Y 方向像素数
DX_UM               = 10;      % X 像素间距（必须是 
DY_UM               = 10;      % Y 像素间距（必须是 
== c41
RUN_HARDWARE       = false;  % false：只算时序、检查
LASER_ENABLE       = false;  % false：P0.7 一直是 0
ATS_ENABLE         = false;  % false：只动电机 + ctr1 �
NY                  = 2;       % 行数 = Y 方向像素数
DX_UM               = 10;      % X 像素间距（必须是 
DY_UM               = 200;      % Y 像素间距（必须是
== c42
RUN_HARDWARE       
…[截断，共 1146 字符]
```
</details>

### 🤖 Claude · 2026-10-14 21:05

> 🔧 Bash · description: Run check mode for stages 3.2/4.1/4.2/5 offline

### ⚙️ 工具 · 2026-10-14 21:05

<details><summary>工具输出</summary>

```
######## c32
== 3. docs/14 1.1 ==
 assert 

== 4. docs/14 1.2 ==
   +    + Y Y 
 readwrite  ATS arm
== 5. docs/14 1.21.3 ==
 XY  assert
 6.10 
 10  20 X  =  = 1000 Y  0 x 20  10P0.7  0true
K = 20Ky = 20Y fs = 248000NX = 10NY = 1wTrig = 2 8.06 uslead = 25 
 400.0 Hz 8000 Hz 4
…[截断，共 8024 字符]
```
</details>

### 🤖 Claude · 2026-10-14 21:08

开工的同步和阅读都做完了：

- **同步**：主目录和 GitHub 都在 `7f65958`；这个 worktree 也快进到了 `7f65958`。下面讲到的文件都以主目录 `C:\Users\2031\Desktop\Research-PAM\07_MATLAB` 为准。
- **已读**：工作日志最后 3 条、docs/14（附 A、阶段 3–5、10/14 上午和下午的实测记录）、docs/13 §3.4、§7、§8，`cscan_test.m` 全部 1034 行，`cscan_replot.m`。
- **预期值**：把 `cscan_test.m` 复制到 scratchpad，改成 3.2、4.1、4.2、5.1 的参数，用 `matlab -batch` 跑了一遍检查模式（RUN_HARDWARE = false，没碰硬件）。下面标 [条件计算] 的数就是这样跑出来的。

你朋友在，不急，回来再看。

---

## (1) 流程：每一步在做什么、为什么

| 阶段 | 在做什么 | 为什么 |
|---|---|---|
| **3.2** NY = 1 | 用新代码只扫一行，参数和 3.1 一样 | NY = 1 时新代码应该完全退回到已经验证过的 B-scan。结果和 3.1 对不上，问题就出在改写上，而不是硬件 |
| **4.1** NY = 2，ATS 关 | 只动电机：扫一行 → X 回程 + Y 走一步 → 再扫一行 → Y 退回。每一步停下来看胶带 | 「回程 + Y」和「退回起点」是 C-scan 新加的运动。先在没有 ATS 的情况下单独验证它们 |
| **4.2** NY = 2，ATS 开 | 和 4.1 一样，只是 ATS 每行重新 arm 一次 | 「每行 arm、每行 Abort」是 C-scan 新加的采集逻辑，B-scan 只 arm 过一次 |
| 5.1（时间够再做） | 完整 10 × 10，每行存盘 | 07 计划第 3 周测试 ① 的规模 |

每一步只加一样新东西：3.2 只换代码，4.1 只加运动，4.2 只加每行重新 arm。出了问题，就知道是哪一样。

## (2) 预期结果：看到这些数才算通过

**3.2 检查模式** [条件计算]
```
K = 20，Ky = 20，fs = 248000，NX = 10，NY = 1，wTrig = 2 行（8.06 us），lead = 25 行
触发 400.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
第一个像素在本行起点 + 200 um；每行 X 走 500 um，Y 共 0 um
ATS：每个 buffer 2 条（4096 B），每行 5 个 buffer，一次 Post 5 个；IMPEDANCE_50_OHM，ETR_5V
时长：行扫描表 0.322 s，最后一行的回程 0.350 s，Y 退回表 0.000 s；全程 0.67 s
```

**3.2 上硬件** [实测时对照]
- `DO 时钟：设 248000，实际 ___`：248000 或接近的数都算正常。6323 的时钟是 100 MHz 整数分频，可能变成 248139（= 100 MHz ÷ 403，只差 0.06%）[条件计算，待确认]。差得多就停下。
- `第 1/1 行：A-line 10/10，1 个沿 10/10，上升沿中位数约 1.93 us，脉冲高约 1.05 V；ctr1 = 10`
- 用时里的「扫描」≥ **0.322 s**（多出来的是 readwrite 的启动开销，记下来），「回程+Y」≥ 0.350 s。
- `回到起点：X +0.0 um，Y +0.0 um；ctr1 全程 10`
- §9 汇总：10/10、rail 0；上升沿落在 3.1 的 1.9265–1.9317 µs 附近，标准差约 1.5–2 ns。
- **台架上**：Y 的胶带不动；X 转 90°（500 µm）又回到记号。
- **不应该出现**黄色的 `Cscan:Abort` 警告（见 (4) 第 2 点）。

**4.1**（NY = 2，DY = 200，ATS 关，PAUSE 开）
- 检查模式 [条件计算]：`Ky = 400`；`Y 共 200 um`；`回程 + Y 表 0.550 s`；`Y 退回表 0.200 s`；`全程 1.75 s`。
- 上硬件：一共停 4 次，每次按回车（先点一下命令行窗口，焦点可能在停止按钮的小窗上）。
  1. 第 1 行开始前：两条胶带都在记号上。
  2. 第 1 行扫完：X 转了 90°，还没回来。
  3. 第 2 行开始前：X 回到记号；**Y 转 36°**（400 脉冲 = 0.1 圈），方向见 (3) 的 Y_POSITIVE_DIR。
  4. 第 2 行扫完：X 又转了 90°。
  之后 X 回程，Y 退回 36°，回到记号。
- 打印：每行 `ATS 关（只动电机）；ctr1 = 10`；最后 `回到起点 X +0.0，Y +0.0；ctr1 全程 20`。没有 §9 的汇总，因为 ATS 关着。

**4.2**（同 4.1，ATS 开；PAUSE 建议关掉，计时更干净）
- 每行 `A-line 10/10，1 个沿 10/10，ctr1 = 10`。两行的上升沿中位数应该在同一个区间，差不到 1 ns。
- §9：`完成 2/2 行，A-line 20 条，20/20，rail 0`。MAP 是一张 10 × 2 的图，每个像素约 1.05 V，相差在 ±10 mV 以内。
- 没有 ApiBufferOverflow，没有 Cscan:Abort。两条胶带都回到记号。

**5.1**（10 × 10，DY = 10）[条件计算]：每行 0.683 s，全程 ≥ 6.91 s，Y 一共走 90 µm。上硬件要看到 100/100、ctr1 = 100。

docs/14 2.5 后半还没做的「连走 9 次 Δy、每次停 50 ms」，正好等于用 `ATS_ENABLE = false` 跑一次 5.1，可以顺便补上。

## (3) 参数：值、单位、含义、行号

**开关（[cscan_test.m:20-27](07_MATLAB/cscan_test.m:20)）**

| 行 | 名字 | 默认 | 3.2 / 4.1 / 4.2 |
|---|---|---|---|
| 20 | RUN_HARDWARE | false | 检查模式核对完才改 true，跑完马上改回 |
| 22 | ATS_ENABLE | true | true / **false** / true |
| 23 | COUNT_CHECK | true | 保持 true（USER 1 并线到 PFI3） |
| 24 | SAVE_DATA | false | 3.2–4.2 可以关；5.1 打开 |
| 26 | PAUSE_BETWEEN_ROWS | false | false / **true** / false |
| 27 | Y_CALIBRATED | false | **你来改 true** |

**扫描参数（[cscan_test.m:30-41](07_MATLAB/cscan_test.m:30)）**

| 行 | 名字 | 值 | 含义 → 换算出来的量 |
|---|---|---|---|
| 30 | NX | 10 | 每行 A-line 数，必须是 rpb 的整数倍 |
| 31 | NY | 10 | 行数。**3.2 改 1，4.x 改 2** |
| 32 | DX_UM | 10 µm | X 像素间距 → K = 20 脉冲/像素 |
| 33 | DY_UM | 10 µm | Y 像素间距 → Ky = 20。**4.x 改 200**（Ky = 400，36°，看得清） |
| 34 | SCAN_SPEED_MM_S | 4 mm/s | → 步频 8000 Hz；触发频率 = 8000 / 20 = 400 Hz |
| 35 | DIR_SCAN | 1 | 扫描时 X DIR = 1 = 朝电机 |
| 36–37 | RAMP_UM / START_FREQ_HZ | 200 µm / 500 Hz | 加速、减速各 400 步，每段约 0.149 s，这段不触发 |
| 38 | X_RETURN_SPEED_MM_S | 2 mm/s | 回程不加速：4 kHz，1000 步，0.25 s |
| 39 | Y_SPEED_MM_S | 1 mm/s | Y 不加速：2 kHz |
| 40 | DIR_SETUP_S | 100 µs | DIR 变化**前后**各留 25 行不发 STEP（bscan_test 只在开头留） |
| 41 | SETTLE_S | 0.05 s | 回程前、Y 走完后各停 0.05 s（12400 行），都算在「回程 + Y 表」里 |

**硬件参数（[cscan_test.m:44-80](07_MATLAB/cscan_test.m:44)）**
- 第 44–49 行：6 条线 P0.0 / P0.1 / P0.2 / P0.3 / P0.6 / P0.7。它们的顺序就是时序表的 6 列（第 160 行 `doLines`）。
- **第 51–53 行要你填**：
  - `Y_UM_PER_PULSE = 0.5;`，注释里「行程约 15 cm」删掉。
  - `Y_POSITIVE_DIR`：见下面的讨论。
  - `Y_DRIVER_SN = "243106105";`
- 第 54 行 MAX_SPEED 4 mm/s；第 55 行 MAX_START_FREQ 8000 Hz（不加速起步的步频上限）；第 57 行 SOFT_LIMIT ±5000 µm。
- 第 58 行 TRIG_WIDTH 10 µs，取整后 wTrig = 2 行 = 8.06 µs。
- ATS（第 66–79 行）和 bscan_test 相同，只有 rpb 改成 2：每个 buffer 2 × 1024 × 2 B = 4096 B，每行 5 个 buffer。postedBuffers = Inf，表示每行 5 个全部一次 Post。
- 还有几处旧注释可以顺手更新（不改也不影响运行）：
  - 第 46 行「还要用电确认」：10/14 已经确认过了。
  - 第 56 行「Y 待 2.5 实测」：已测，1–4 mm/s 都正常。

**Y_POSITIVE_DIR：先讨论再填**

代码里 +y 的定义是「行号增加时 Y 走的方向」，Y_POSITIVE_DIR 是这时 DIR 输出的电平。你实测 DIR = 1 时 Y 朝电机走。

- **填 1（我建议）**：行号朝电机方向增加。这样 X、Y、test2_y 三处都是同一条规则：「+ = DIR 1 = 朝电机」。`pos_Y.mat` 的符号也一致，不容易记反。
- **填 0**：行号背离电机增加。只有当你想让图的方向对应某个物理视角时才有理由选它（比如以后放样品，要和相机看到的方向一致）。
- 行程不是问题：Y 在中间，两边各约 27 mm，这次最多走 200 µm。

你定了以后，4.1 第 2 行开始前，Y 应该朝你选的那个方向转 36°。

## (4) 代码：按段讲

**整体结构**

| 段 | 行 | 一句话 |
|---|---|---|
| 开关 | 20–27 | 决定这次碰不碰硬件、开不开 ATS、停不停 |
| §1 / §2 | 29–80 | 你能改的物理参数（µm、mm/s、s）和接线 |
| §3 换算与检查 | 82–180 | µm 和 mm/s 换算成脉冲数和行数，不合法的组合用 assert 拦下；最后把所有参数打包成 `P` |
| §4 生成时序表 | 182–189 | 只生成一次：行扫描表、回程 + Y 表、最后一行的回程表、Y 退回表 |
| §5 逐表检查 | 191–221 | 从表里反推位置和触发，逐条 assert；打印时长，画计划图 |
| §6 数据结构 | 223–250 | `cscan` 里放什么：raw (uint16)、命令位置、每行的 ctr1、计时 |
| §7 检查模式 | 252–291 | 用假数据把数据通路走一遍，第 290 行 `return`，**检查模式到这里就结束** |
| §8 上硬件 | 293–306 | 再 assert 一次 → `daqreset` → 调 `runCscan` |
| §9 结果 | 308–314 | 汇总、MAP、存过盘的话重读一遍比较 |
| 函数 | 317–1034 | 表生成器（341–391）、检查（393–509）、画图、数据、`runCscan`（732）、ATS 三个函数（946–1017）、`releaseAll`（1019） |

**`runCscan` 的 4 个重点（硬件路径从没跑过）**

**① arm 的顺序（第 786–803 行）：先 arm，再 readwrite**
- arm 由 `atsArmRow` 完成（第 982 行）：`BeforeAsyncRead`（告诉板卡这次要 NX 条）→ 5 个 buffer 都 `Post` → `StartCapture`（开始等触发）。
- 为什么必须在 readwrite **之前**：readwrite 一调用，MATLAB 就被占住，直到整张表输出完。第一个 P0.6 在开始后约 0.149 s 发出（加速段之后）。如果 arm 放在 readwrite 之后，10 个触发早就发完了，buffer 永远等不满，2 s 后报「第 1 行 buffer 1/5 未完成」。
- 循环外只做一次的事（第 738–770 行）：ctr1、ATS 配置和分配 buffer、dq 加 AI 时钟和 6 条线、停止按钮。每行重复的只有 arm 和 readwrite，所以每行的软件开销小。

**② 每行都 Abort（第 808–811 行）**
- 取完 5 个 buffer 后立刻 `AlazarAbortAsyncRead`。上一次 async read 没有结束，下一行的 `BeforeAsyncRead` 就不会被接受，这正是 docs/14 4.2 写的失败首查项。
- 为什么行与行之间不会漏触发：回程 + Y 表里 P0.6 那一列全是 0（第 456 行 assert 了 0 个触发）。ATS 没 arm 的这段时间本来就没有触发要接。
- 3.2 要盯的一点：正常结束时，`releaseAll`（第 1019 行）会再 Abort 一次，也就是第二次 Abort。如果出现 `Cscan:Abort` 警告，说明第二次 Abort 报了错，buffer 没有被释放，要重启 MATLAB，这段代码也要改。

**③ catch 的顺序（第 881–941 行）**
1. **先 Abort DMA**（第 885 行）。随后 onCleanup 会释放 buffer；板卡如果还在往里写，就是写进已经释放的内存。
2. **读 ctr1**（第 894 行）。它决定往哪边查：ctr1 = NX 而 ATS 少了，查 G1 → TRIG IN 这段；ctr1 也少了，查时序表或 PFI3 的线。
3. **记下出错的行和步骤，补写进文件**。已经完成的行，在完成时就存过盘了。
4. **只有 `posKnown = true` 才自动退回**（第 921 行）。readwrite 前后会把 posKnown 设成 false 再改回 true（第 799–801 行）。
   - 出错时 readwrite 已经跑完（比如取数时超时，6.7 拔线就是这种）：位置已知，自动退回。
   - 出错时 readwrite 正在跑：位置未知，**不动**。SR2 断电，用手摇回胶带记号。
5. `rethrow`：把红色的报错显示出来。

**④ 停止按钮（第 764–770 行、第 834–858 行）**
- 按钮只把 `UserData` 设成 true。MATLAB 是单线程的：readwrite 期间点的按钮先排队，到第 835 行 `drawnow` 时才处理。所以**只在行与行之间生效**。
- 在第 iy 行时点停止，会发生：这一行扫完、存好 → 只回程（`moveLast`，Y 不再前进）→ `break` → 用累计命令位置算出退回表，Y 回到起点。直接关掉这个小窗口，也等于点了停止。
- **不要用 Ctrl+C**：它不会进 catch。onCleanup 还是会释放 ATS，但不会自动退回；如果按在 readwrite 中途，电机停在哪里也不知道。

**和 bscan_test 不一样、第一次上硬件要留意的两点**（读代码时发现的）
- bscan_test 的 ctr1 只在 dq 不存在的时候读（`bscan_test.m:162`、`:169`）。cscan_test 在 dq 一直存在的情况下每行都读（第 789、812 行），这是新情况。看 3.2 是不是 `ctr1 = 10` 就知道。
- `pos_Y.mat` 不会被 cscan_test 更新。正常结束时 Y 会回到 0，所以没关系；但如果出错时 posKnown = false，之后用 test2_y 之前要先手摇回记号，再执行 `pos_um = 0; save('pos_Y.mat','pos_um')`。

---

**你回来后的顺序**
1. 定下 Y_POSITIVE_DIR（我建议 1），自己改第 27、51、52、53 行。
2. 开工复核约 2 分钟：MATLAB 地址栏是 `07_MATLAB`；示波器按 docs/13 §7.5 看一遍。
3. 第 31 行改成 `NY = 1`，跑检查模式，和上面 3.2 的打印逐行对照。
4. 对上了再改 RUN_HARDWARE = true，跑完马上改回 false。

**两件事等你回一句：**
- Y_POSITIVE_DIR 填 1 还是 0？
- 收工时 docs/14 要改三处：附 A 的时长拆分改成 0.32 + 0.36 s，1.2 写上 DIR 前后各留 25 行，3.2 的通过标准改成 readwrite ≥ 0.32 s。可以改吗？

另外，Rui 适合从 4.x 开始看。见面时问他：行内用匀速扫还是 step-and-settle？

### 🧑 用户 · 2026-10-14 21:12

你给我发这一大串是在干什么呢

### 🤖 Claude · 2026-10-14 21:12

这是你上一条要的「上硬件前先了解的四件事」：流程、预期结果、参数、代码，我一次全倒出来了，太长，而且你朋友还在。

换个做法：**一次只讲一步，每次几行**。那一大段我可以存成一个复习文件放进 docs，想看的时候再看，不用现在读。

现在只需要你定一件事：

**Y_POSITIVE_DIR 填 1 还是 0？**
- 填 1：行号往电机方向走，和 X、test2_y 的规定一样（DIR 1 = 朝电机）。我建议填这个。
- 填 0：行号背离电机走。

定了以后，你自己在 `cscan_test.m` 改 4 行（第 27、51、52、53 行），然后我们做 3.2。

### 🧑 用户 · 2026-10-14 21:13

可以跟x的设置是一样的么

### 🤖 Claude · 2026-10-14 21:13

可以，填 1 就和 X 一样：

- X：`DIR_SCAN = 1`（第 35 行），扫描时朝电机走。
- Y：`Y_POSITIVE_DIR = 1`，行号增加时也朝电机走。

两个轴是同一条规则：DIR = 1 就是朝电机。

你在 `07_MATLAB/cscan_test.m` 改这 4 行：

| 行 | 改成 |
|---|---|
| 27 | `Y_CALIBRATED = true;` |
| 51 | `Y_UM_PER_PULSE = 0.5;` |
| 52 | `Y_POSITIVE_DIR = 1;` |
| 53 | `Y_DRIVER_SN = "243106105";` |

改完告诉我，我们接着做 3.2。

### 🧑 用户 · 2026-10-14 21:16

好的

### 🤖 Claude · 2026-10-14 21:16

> 🔧 Bash · description: Check whether the four Y lines were edited

### ⚙️ 工具 · 2026-10-14 21:16

<details><summary>工具输出</summary>

```
RUN_HARDWARE       = false;  % false：只算时序、检查、画图�
LASER_ENABLE       = false;  % false：P0.7 一直是 0
ATS_ENABLE         = true;   % false：只动电机 + ctr1 计数，AT
COUNT_CHECK        = true;   % true：用 ctr1 数 P0.6 的上升沿�
SAVE_DATA          = false;  % true：每行做完就写进 cscan_data
MOCK_DATA          = true;   % 只在 RUN_HARDWARE = false 时有用�
PAUSE_BETWEEN_ROWS = false;  % true：每行开始前、扫完后各�
Y_CALIBRATED       = true;  % Y 的 um/脉冲 和方向在 docs/14 阶
NY                  = 10;      % 行数 = Y 方向像素数
Y_UM_PER_PULSE = 0.5;             % ⚠ 没标定：暂时沿用 X 的
Y_POSITIVE_DIR = 1;               % Y 前进（行号增加）时 DIR 
Y_DRIVER_SN    = "243106
…[截断，共 636 字符]
```
</details>

### 🤖 Claude · 2026-10-14 21:16

看到了，4 行都改好、也存盘了。第 51 行后面的注释还写着「没标定」，不影响运行，以后有空再改。

**下一步：3.2 的检查模式（不碰硬件）**
1. 第 31 行改成 `NY = 1;`
2. 第 20 行保持 `RUN_HARDWARE = false`，运行 `cscan_test`。
3. 看打印里这几行，应该是：
   - `K = 20，Ky = 20，fs = 248000，NX = 10，NY = 1`
   - `行扫描表 0.322 s`
   - `全程 0.67 s`
   - 最后一行：`*** 检查模式：没有向硬件发送任何信号 ***`

跑完把打印截图或者贴给我。

### 🧑 用户 · 2026-10-14 21:17

<pasted_content id="416e">
>> cscan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 10 个触发、间隔 20 步；X 去程 = 回程 = 1000 步；Y 前进 0 x 20 步后退回；总触发 10；P0.7 全 0：true
K = 20，Ky = 20（Y 未标定时只是假设），fs = 248000，NX = 10，NY = 1，wTrig = 2 行（8.06 us），lead = 25 行
触发 400.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 10 x 1，间距 10.00 x 10.00 um；第一个像素在本行起点 + 200 um；每行 X 走 500 um，Y 共 0 um
ATS：每条 1024 点，每个 buffer 2 条（4096 B），每行 5 个 buffer，一次 Post 5 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.322 s（不含停稳），回程 + Y 表 0.360 s（含 2 次停稳；最后一行 0.350 s），Y 退回表 0.000 s
每行 0.683 s，全程 0.67 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
数据：raw uint16 1024 x 10 x 1 = 20480 B（20.0 kB）

== 7. 假数据走一遍数据通路（docs/14 1.4） ==
【在做什么】造一组已知图案的 raw（第 iy 行第 ix 条的脉冲高 = iy + ix/100 个单位），走一遍 快速检查 → 逐行存盘 → MAP → 重读。
【为什么】测试信号下 MAP 本来就是均匀的，行列排错了看不出来；用已知图案才能逐点核对。
假数据没有 ctr1 和计时，下面每行的 ctr1、用时显示 NaN。
第 1/1 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9389 us，脉冲高 0.303 ~ 0.330 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
完成 1/1 行，A-line 10 条；每条正好 1 个沿：10/10；rail 点数 0
上升沿 1.9373 ~ 1.9414 us，标准差 1.23 ns，峰峰 4.07 ns；MAP 0.3030 ~ 0.3300 V（标准差 9.08 mV）
MAP(1,7) = 1.07（应为 1.07）；MAP(1,1) = 1.01（应为 1.01）
逐点核对：10/10 个像素对得上（误差 < 0.005 个单位）

*** 检查模式：没有向硬件发送任何信号。确认无误后把 RUN_HARDWARE 改成 true ***
>>
</pasted_content id="416e">

### 🤖 Claude · 2026-10-14 21:17

对上了。打印的每个数都和预期一致：K 20、fs 248000、NY 1、行扫描表 0.322 s、全程 0.67 s，假数据 10/10。

两张图怎么看：
- **Figure 1**：红点在 X = 200–290 µm，Y 一直是 0。只扫一行，计划是对的。
- **Figure 2 是假数据，不是测量。** MAP 那条斜线是故意造出来的图案（第 ix 条高 1 + ix/100），用来证明数据没有排错位。上硬件后这里应该是一条平线，约 1.05 V。

**下一步：3.2 上硬件**
1. 先花 1 分钟看台架：
   - 示波器底栏是 2 V / 1 V / 500 mV，D = 0。
   - 发生器两路 Output 开。
   - KORAD 开着。
   - X、Y 都在胶带记号上。
2. 第 20 行改成 `RUN_HARDWARE = true`，运行。
3. 跑的时候看两件事：
   - X 的胶带转约 90° 再转回来。
   - **Y 的胶带不动。**
   - 会弹出一个带停止按钮的小窗口，这次不用点。
4. 跑完马上把第 20 行改回 `false`。
5. 把打印贴给我。重点看四处：
   - `DO 时钟` 那一行的「实际」是多少。
   - `ctr1 = 10`、`10/10`。
   - 「扫描」的用时 ≥ 0.322 s。
   - 有没有黄色的 `Cscan:Abort` 警告。

### 🧑 用户 · 2026-10-14 21:18

是的

### 🤖 Claude · 2026-10-14 21:18

台架没问题，和 docs/13 §7.5 逐项对上了：

- **发生器**：CH1 Square 100 kHz、2 Vpp、Offset 1 V；CH2 Square 2.5 MHz、1 Vpp、Offset 0.5 V、Delay 2 µs；两路都是 Burst NCycle、Sync OFF、Imped Load，Output 开。
- **示波器**：D = 0，底栏 2 V / 1 V / 500 mV。CH1 Top 4.48 V；CH2 Top 2.00 V、宽 5.000 µs；CH3 Top 1.06 V、宽 200 ns；Dly 550 ns。都和下午的基准一样。屏幕上这一发是之前留下的最后一次触发。

可以上硬件了：
1. 第 20 行改成 `RUN_HARDWARE = true`，运行 `cscan_test`。
2. 跑的时候看 X 的胶带转约 90° 再回来，**Y 的胶带不动**。
3. 跑完马上把第 20 行改回 `false`。
4. 把打印贴给我。

### 🧑 用户 · 2026-10-14 21:19

<pasted_content id="416e">
>> clear
>> cscan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 10 个触发、间隔 20 步；X 去程 = 回程 = 1000 步；Y 前进 0 x 20 步后退回；总触发 10；P0.7 全 0：true
K = 20，Ky = 20（Y 未标定时只是假设），fs = 248000，NX = 10，NY = 1，wTrig = 2 行（8.06 us），lead = 25 行
触发 400.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 10 x 1，间距 10.00 x 10.00 um；第一个像素在本行起点 + 200 um；每行 X 走 500 um，Y 共 0 um
ATS：每条 1024 点，每个 buffer 2 条（4096 B），每行 5 个 buffer，一次 Post 5 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.322 s（不含停稳），回程 + Y 表 0.360 s（含 2 次停稳；最后一行 0.350 s），Y 退回表 0.000 s
每行 0.683 s，全程 0.67 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
数据：raw uint16 1024 x 10 x 1 = 20480 B（20.0 kB）

== 8. 上硬件（docs/14 阶段 3–6） ==
【在做什么】循环外准备一次 Dev1、ctr1、ATS；每行 arm → 行扫描 → 取数 → 存盘 → 看停止按钮 → 回程 + Y。
【为什么】DMA buffer 每行重复使用，这一行在电机再动之前就存好；只在行间停，电机不会停在半路，退回距离按累计命令位置算。
DO 时钟：设 248000 S/s，实际 248000.0 S/s（不一样的话，所有时长和扫描速度按比例变）
停止按钮只在行与行之间检查：按下后做完当前这一行再停，然后退回起点。不要用 Ctrl+C（不会自动退回）。
第 1/1 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9294 us，脉冲高 1.046 ~ 1.049 V；ctr1 = 10（应为 10）；用时 1.30 s（arm 0.042 / 扫描 0.636 / 取数 0.052 / 存 0.003 / 回程+Y 0.566）
回到起点：命令位置 X +0.0 um，Y +0.0 um（应为 0 / 0）；ctr1 全程 10（应为 10）

== 9. 结果（docs/14 6.1、6.3、6.4） ==
【在做什么】汇总每条 A-line 的快速检查，算 MAP；存过盘的话把文件读回来逐点比较。
【为什么】条数、ctr1、计划位置三个数对上，才能说第 k 条记录 = 第 k 个位置；重读一致才说明存的东西能用。
完成 1/1 行，A-line 10 条；每条正好 1 个沿：10/10；rail 点数 0
上升沿 1.9273 ~ 1.9323 us，标准差 2.04 ns，峰峰 5.00 ns；MAP 1.0402 ~ 1.0438 V（标准差 1.29 mV）
>>
</pasted_content id="416e">

 这个对么

### 🤖 Claude · 2026-10-14 21:19

> 🔧 Bash · description: Check current switch values in cscan_test.m

### ⚙️ 工具 · 2026-10-14 21:19

<details><summary>工具输出</summary>

```
RUN_HARDWARE       = true;  % false：只算�
ATS_ENABLE         = true;   % false：只动
PAUSE_BETWEEN_ROWS = false;  % true：每行�
NY                  = 1;      % 行数 = Y �
DY_UM               = 10;      % Y 像素间�
```
</details>

### 🤖 Claude · 2026-10-14 21:19

**对，3.2 通过了。** 新代码只扫一行时，结果和 3.1 一样：

| | 3.2（刚才） | 3.1（下午，bscan_test） |
|---|---|---|
| ctr1 / 条数 / rail | 10 / 10/10 / 0 | 10 / 10/10 / 0 |
| 上升沿 | 1.9273–1.9323 µs | 1.9265–1.9317 µs |
| 标准差 / 峰峰 | 2.04 / 5.00 ns | 1.52 / 5.18 ns |
| 脉冲高 | 1.046–1.049 V | 1.046–1.051 V |

另外几项也都对：
- DO 时钟实际是 248000.0，没有被改。
- 回到起点 0 / 0。
- 没有出现 `Cscan:Abort` 警告，说明正常结束时的第二次 Abort 不会出问题。

**图看起来乱跳，其实没事。** 两张图的纵轴是自动缩放的：MAP 一共只差 3.6 mV；上升沿一共只差 5 ns，不到一个采样点（180 MS/s，每点 5.56 ns）。这是噪声和触发抖动，和 3.1 一样。

**一个新发现，记下来就行：** readwrite 的实际用时比计划长。
- 扫描：计划 0.322 s，实际 0.636 s，多了约 0.31 s。
- 回程：计划 0.350 s，实际 0.566 s，多了约 0.22 s。

每行一共多出约 0.5 s，所以这一行用了 1.30 s，计划是 0.68 s。这就是 6.10 要测的「每行软件开销」，以后估算 3×3 mm 要多久时会用到。

**先确认两件事：**
1. 第 20 行现在还是 `RUN_HARDWARE = true`，先改回 `false`。
2. 刚才跑的时候，Y 的胶带没动、X 回到了记号，对吗？

确认后做 4.1，下一条再给你要改哪几行。

### 🧑 用户 · 2026-10-14 21:21

该回来了但是胶带我还需要再确认一下

### 🤖 Claude · 2026-10-14 21:21

> 🔧 Bash · description: Confirm RUN_HARDWARE is false again

### ⚙️ 工具 · 2026-10-14 21:21

<details><summary>工具输出</summary>

```
RUN_HARDWARE       = false;  % false：�
```
</details>

### 🤖 Claude · 2026-10-14 21:21

第 20 行已经是 `false` 了。

确认胶带的方法：
- **X**：胶带应该正对着记号。这一行 X 只走了 500 µm，也就是 1/4 圈（90°），去和回都是 1000 步。如果偏了，偏多少就说明丢了多少步：1° ≈ 5.6 µm。
- **Y**：联轴器上的胶带应该还对着窗口边框，和跑之前一样。NY = 1 时 Y 一步都不走。

如果刚才没盯着看、不确定它有没有回来，就再跑一次 3.2：第 20 行改 `true`，运行，这次眼睛盯着 X 的胶带，看它转 90° 再转回来；跑完改回 `false`。参数都不用动。

确认完告诉我 X、Y 是不是都对准了。

### 🧑 用户 · 2026-10-14 21:23

是的回来了

### 🤖 Claude · 2026-10-14 21:23

3.2 全部通过，X、Y 都回到了记号。

**下一步：4.1，两行，只动电机（ATS 不采数据）**

先改 4 行：

| 行 | 改成 | 为什么 |
|---|---|---|
| 22 | `ATS_ENABLE = false;` | 这一步只看运动，不采数据 |
| 26 | `PAUSE_BETWEEN_ROWS = true;` | 每一步停下来，看胶带 |
| 31 | `NY = 2;` | 扫两行，中间 Y 要走一步 |
| 33 | `DY_UM = 200;` | Y 一步走 200 µm，联轴器转 36°，看得清 |

第 20 行保持 `false`，先跑检查模式，应该看到：
- `Ky = 400`
- `Y 共 200 um`
- `回程 + Y 表 0.550 s`
- `Y 退回表 0.200 s`
- `全程 1.75 s`

跑完把打印贴给我。

### 🧑 用户 · 2026-10-14 21:23

但是现在y的胶带在下面可以给挪上来么

### 🤖 Claude · 2026-10-14 21:23

可以，但要**挪胶带，不要转滑台**。

胶带只是一个角度记号。Y 现在就在 0 位（pos_Y.mat = 0，3.2 里 Y 也没动），所以在当前角度重新贴一个记号就行，位置不变：

1. **不要手摇、不要跑程序**。KORAD 开着，电机有保持电流锁着，贴胶带时手轻一点就不会转。
2. 在联轴器**上面、看得见的地方**贴一条新胶带，边沿对齐开口窗口的边框（就是以前当固定参照的那条边）。
3. 看一眼钢尺，还是约 4.3 cm，说明位置没变。
4. 旧胶带可以撕掉，免得以后看错。拍张照，收工时放进 docs/screenshots。

新胶带就是新的 0 位记号，pos_Y.mat 不用改。贴好后改 4.1 那 4 行，先跑检查模式。

### 🧑 用户 · 2026-10-14 21:24

好的我改了刚吃还是4.3

### 🤖 Claude · 2026-10-14 21:25

> 🔧 Bash · description: Check whether the 4.1 lines were edited

### ⚙️ 工具 · 2026-10-14 21:25

<details><summary>工具输出</summary>

```
RUN_HARDWARE       = true;  % false：只算�
ATS_ENABLE         = true;   % false：只动
PAUSE_BETWEEN_ROWS = false;  % true：每行�
NY                  = 1;      % 行数 = Y �
DY_UM               = 10;      % Y 像素间�
```
</details>

### 🤖 Claude · 2026-10-14 21:25

钢尺还是 4.3 cm，位置没变，新胶带就是 0 位。

不过我看了磁盘上的 `cscan_test.m`，现在是这样：

| 行 | 现在 | 应该改成 |
|---|---|---|
| 20 | `RUN_HARDWARE = true` | **`false`**（先改这一行） |
| 22 | `ATS_ENABLE = true` | `false` |
| 26 | `PAUSE_BETWEEN_ROWS = false` | `true` |
| 31 | `NY = 1` | `2` |
| 33 | `DY_UM = 10` | `200` |

第 20 行又是 `true` 了，可能是刚才为了确认胶带又跑了一次 3.2。也可能你在编辑器里已经改了但还没存盘，按 Ctrl+S 存一下。

存好后跑检查模式，把打印贴给我。

### 🧑 用户 · 2026-10-14 21:27

<pasted_content id="416e">
cscan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 10 个触发、间隔 20 步；X 去程 = 回程 = 1000 步；Y 前进 0 x 400 步后退回；总触发 10；P0.7 全 0：true
K = 20，Ky = 400（Y 未标定时只是假设），fs = 248000，NX = 10，NY = 1，wTrig = 2 行（8.06 us），lead = 25 行
触发 400.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 10 x 1，间距 10.00 x 200.00 um；第一个像素在本行起点 + 200 um；每行 X 走 500 um，Y 共 0 um
ATS：每条 1024 点，每个 buffer 2 条（4096 B），每行 5 个 buffer，一次 Post 5 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.322 s（不含停稳），回程 + Y 表 0.550 s（含 2 次停稳；最后一行 0.350 s），Y 退回表 0.000 s
每行 0.873 s，全程 0.67 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
数据：raw uint16 1024 x 10 x 1 = 20480 B（20.0 kB）

== 7. 假数据走一遍数据通路（docs/14 1.4） ==
【在做什么】造一组已知图案的 raw（第 iy 行第 ix 条的脉冲高 = iy + ix/100 个单位），走一遍 快速检查 → 逐行存盘 → MAP → 重读。
【为什么】测试信号下 MAP 本来就是均匀的，行列排错了看不出来；用已知图案才能逐点核对。
假数据没有 ctr1 和计时，下面每行的 ctr1、用时显示 NaN。
第 1/1 行：ATS 关（只动电机）；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
完成 1/1 行，A-line 10 条；每条正好 1 个沿：10/10；rail 点数 0
上升沿 1.9373 ~ 1.9414 us，标准差 1.23 ns，峰峰 4.07 ns；MAP 0.3030 ~ 0.3300 V（标准差 9.08 mV）
MAP(1,7) = 1.07（应为 1.07）；MAP(1,1) = 1.01（应为 1.01）
逐点核对：10/10 个像素对得上（误差 < 0.005 个单位）

*** 检查模式：没有向硬件发送任何信号。确认无误后把 RUN_HARDWARE 改成 true ***
>>
</pasted_content id="416e">

  好了

### 🤖 Claude · 2026-10-14 21:27

> 🔧 Bash · description: Check the 4.1 switch lines on disk

### ⚙️ 工具 · 2026-10-14 21:27

<details><summary>工具输出</summary>

```
RUN_HARDWARE       = false;  % false：只算
ATS_ENABLE         = false;   % false：只�
PAUSE_BETWEEN_ROWS = true;  % true：每行�
NY                  = 1;      % 行数 = Y �
DY_UM               = 200;      % Y 像素间
```
</details>

### 🤖 Claude · 2026-10-14 21:27

还差一行：**第 31 行还是 `NY = 1`**，要改成 `NY = 2`。

打印里也能看出来：`NY = 1`、`Y 共 0 um`、`Y 退回表 0.000 s`、`全程 0.67 s`，都还是一行的结果。

其余几行已经对了：第 20 行 false、第 22 行 ATS 关、第 26 行 PAUSE 开、第 33 行 DY 200（`Ky = 400` 对上了）。

改完第 31 行再跑一次检查模式，这次应该看到：
- `NY = 2`
- `Y 共 200 um`
- `Y 退回表 0.200 s`
- `全程 1.75 s`
- 计划图左上是**两条**蓝线，上下相隔 200 µm。

### 🧑 用户 · 2026-10-14 21:29

<pasted_content id="416e">
cscan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 10 个触发、间隔 20 步；X 去程 = 回程 = 1000 步；Y 前进 1 x 400 步后退回；总触发 20；P0.7 全 0：true
K = 20，Ky = 400（Y 未标定时只是假设），fs = 248000，NX = 10，NY = 2，wTrig = 2 行（8.06 us），lead = 25 行
触发 400.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 10 x 2，间距 10.00 x 200.00 um；第一个像素在本行起点 + 200 um；每行 X 走 500 um，Y 共 200 um
ATS：每条 1024 点，每个 buffer 2 条（4096 B），每行 5 个 buffer，一次 Post 5 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.322 s（不含停稳），回程 + Y 表 0.550 s（含 2 次停稳；最后一行 0.350 s），Y 退回表 0.200 s
每行 0.873 s，全程 1.75 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
数据：raw uint16 1024 x 10 x 2 = 40960 B（40.0 kB）

== 7. 假数据走一遍数据通路（docs/14 1.4） ==
【在做什么】造一组已知图案的 raw（第 iy 行第 ix 条的脉冲高 = iy + ix/100 个单位），走一遍 快速检查 → 逐行存盘 → MAP → 重读。
【为什么】测试信号下 MAP 本来就是均匀的，行列排错了看不出来；用已知图案才能逐点核对。
假数据没有 ctr1 和计时，下面每行的 ctr1、用时显示 NaN。
第 1/2 行：ATS 关（只动电机）；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 2/2 行：ATS 关（只动电机）；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
完成 2/2 行，A-line 20 条；每条正好 1 个沿：20/20；rail 点数 0
上升沿 1.9338 ~ 1.9414 us，标准差 2.01 ns，峰峰 7.54 ns；MAP 0.3030 ~ 0.6299 V（标准差 154.15 mV）
MAP(2,7) = 2.07（应为 2.07）；MAP(2,1) = 2.01（应为 2.01）
逐点核对：20/20 个像素对得上（误差 < 0.005 个单位）

*** 检查模式：没有向硬件发送任何信号。确认无误后把 RUN_HARDWARE 改成 true ***
>>
</pasted_content id="416e">

  为啥改成2了就不一样了

### 🤖 Claude · 2026-10-14 21:29

检查模式对上了：`NY = 2`、`Y 共 200 um`、`Y 退回表 0.200 s`、`全程 1.75 s`。

**图变了，是因为现在有两行：**

- **Figure 3（计划路径）**：NY = 1 时只有一条蓝线（Y = 0）；现在有两条，第 1 行在 Y = 0，第 2 行在 Y = 200 µm。左边 X = 0 处那条竖着的灰虚线就是「回程 + Y 一步」：X 先退回起点，Y 再往上走 200 µm；全部扫完后，Y 沿同一条线退回 0。
- **像素网格**：两排红点，在 Y = 0 和 Y = 200。看起来很窄，是因为 X 只有 90 µm 宽、Y 有 200 µm 高，图是按真实比例画的（`axis equal`）。
- **Figure 4（假数据）**：只有一行时代码画曲线；两行以上改画成彩色图（`imagesc`，[cscan_test.m:707](07_MATLAB/cscan_test.m:707)）。假数据第 1 行约 0.30 V（蓝），第 2 行约 0.60 V（黄），**两行颜色不同，说明行没有排错**。同一行里每列只差 3 mV，颜色上看不出来。右图是假数据随机加的上升沿抖动，不用管。

真正跑 4.1 时 ATS 是关的，**不会出现 MAP 图**，只有打印。

**下一步：4.1 上硬件**
1. 第 20 行改成 `true`，运行。会停 4 次，每次先点一下命令行窗口再按回车：
   1. 第 1 行开始前：X、Y 都在记号上。
   2. 第 1 行扫完：X 转了 90°，还没回来。
   3. 第 2 行开始前：X 回到记号；**Y 转 36°，朝电机方向**（和 2.3 的 +1000 µm 同方向）。
   4. 第 2 行扫完：X 又转了 90°。
   之后程序自己让 X 回程、Y 退回 36°，不再停。
2. 跑完把第 20 行改回 `false`。
3. 告诉我：Y 转的方向对不对，最后两条胶带是不是都对准；再把打印贴给我。

### 🧑 用户 · 2026-10-14 21:31

cscan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 10 个触发、间隔 20 步；X 去程 = 回程 = 1000 步；Y 前进 1 x 400 步后退回；总触发 20；P0.7 全 0：true
K = 20，Ky = 400（Y 未标定时只是假设），fs = 248000，NX = 10，NY = 2，wTrig = 2 行（8.06 us），lead = 25 行
触发 400.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 10 x 2，间距 10.00 x 200.00 um；第一个像素在本行起点 + 200 um；每行 X 走 500 um，Y 共 200 um
ATS：每条 1024 点，每个 buffer 2 条（4096 B），每行 5 个 buffer，一次 Post 5 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.322 s（不含停稳），回程 + Y 表 0.550 s（含 2 次停稳；最后一行 0.350 s），Y 退回表 0.200 s
每行 0.873 s，全程 1.75 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
数据：raw uint16 1024 x 10 x 2 = 40960 B（40.0 kB）

== 8. 上硬件（docs/14 阶段 3–6） ==
【在做什么】循环外准备一次 Dev1、ctr1、ATS；每行 arm → 行扫描 → 取数 → 存盘 → 看停止按钮 → 回程 + Y。
【为什么】DMA buffer 每行重复使用，这一行在电机再动之前就存好；只在行间停，电机不会停在半路，退回距离按累计命令位置算。
DO 时钟：设 248000 S/s，实际 248000.0 S/s（不一样的话，所有时长和扫描速度按比例变）
停止按钮只在行与行之间检查：按下后做完当前这一行再停，然后退回起点。不要用 Ctrl+C（不会自动退回）。
【暂停】第 1 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）这个对么 胶带好像没动啊

### 🤖 Claude · 2026-10-14 21:32

对的，现在什么都还没动。程序停在**第 1 次暂停**（第 1 行开始前），这一步本来就是让你先确认两条胶带都在记号上，电机还没收到任何脉冲。

接下来：
1. 确认 X、Y 的胶带都对准记号。
2. 点一下 MATLAB 命令行窗口，按**回车**，第 1 行开始扫：X 的胶带会转约 90°，然后停在第 2 次暂停。
3. 后面每次停下来，先看胶带再按回车。第 2 行开始前那次停，要看到 **Y 朝电机方向转了 36°**。

### 🧑 用户 · 2026-10-14 21:34

第 1 行扫完了，X 转了 90° 停住 

<pasted_content id="416e">
cscan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 10 个触发、间隔 20 步；X 去程 = 回程 = 1000 步；Y 前进 1 x 400 步后退回；总触发 20；P0.7 全 0：true
K = 20，Ky = 400（Y 未标定时只是假设），fs = 248000，NX = 10，NY = 2，wTrig = 2 行（8.06 us），lead = 25 行
触发 400.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 10 x 2，间距 10.00 x 200.00 um；第一个像素在本行起点 + 200 um；每行 X 走 500 um，Y 共 200 um
ATS：每条 1024 点，每个 buffer 2 条（4096 B），每行 5 个 buffer，一次 Post 5 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.322 s（不含停稳），回程 + Y 表 0.550 s（含 2 次停稳；最后一行 0.350 s），Y 退回表 0.200 s
每行 0.873 s，全程 1.75 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
数据：raw uint16 1024 x 10 x 2 = 40960 B（40.0 kB）

== 8. 上硬件（docs/14 阶段 3–6） ==
【在做什么】循环外准备一次 Dev1、ctr1、ATS；每行 arm → 行扫描 → 取数 → 存盘 → 看停止按钮 → 回程 + Y。
【为什么】DMA buffer 每行重复使用，这一行在电机再动之前就存好；只在行间停，电机不会停在半路，退回距离按累计命令位置算。
DO 时钟：设 248000 S/s，实际 248000.0 S/s（不一样的话，所有时长和扫描速度按比例变）
停止按钮只在行与行之间检查：按下后做完当前这一行再停，然后退回起点。不要用 Ctrl+C（不会自动退回）。
【暂停】第 1 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 1 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 1/2 行：ATS 关（只动电机）；ctr1 = 10（应为 10）；用时 9.51 s（arm 0.012 / 扫描 0.777 / 取数 0.008 / 存 0.000 / 回程+Y 0.604）
收到停止：完成 10/20 条 A-line（1/2 行），不再扫下一行。
回到起点：命令位置 X +0.0 um，Y +0.0 um（应为 0 / 0）；ctr1 全程 10（应为 10）
>> cscan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 10 个触发、间隔 20 步；X 去程 = 回程 = 1000 步；Y 前进 1 x 400 步后退回；总触发 20；P0.7 全 0：true
K = 20，Ky = 400（Y 未标定时只是假设），fs = 248000，NX = 10，NY = 2，wTrig = 2 行（8.06 us），lead = 25 行
触发 400.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 10 x 2，间距 10.00 x 200.00 um；第一个像素在本行起点 + 200 um；每行 X 走 500 um，Y 共 200 um
ATS：每条 1024 点，每个 buffer 2 条（4096 B），每行 5 个 buffer，一次 Post 5 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.322 s（不含停稳），回程 + Y 表 0.550 s（含 2 次停稳；最后一行 0.350 s），Y 退回表 0.200 s
每行 0.873 s，全程 1.75 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
数据：raw uint16 1024 x 10 x 2 = 40960 B（40.0 kB）

== 8. 上硬件（docs/14 阶段 3–6） ==
【在做什么】循环外准备一次 Dev1、ctr1、ATS；每行 arm → 行扫描 → 取数 → 存盘 → 看停止按钮 → 回程 + Y。
【为什么】DMA buffer 每行重复使用，这一行在电机再动之前就存好；只在行间停，电机不会停在半路，退回距离按累计命令位置算。
DO 时钟：设 248000 S/s，实际 248000.0 S/s（不一样的话，所有时长和扫描速度按比例变）
停止按钮只在行与行之间检查：按下后做完当前这一行再停，然后退回起点。不要用 Ctrl+C（不会自动退回）。
【暂停】第 1 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 1 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 1/2 行：ATS 关（只动电机）；ctr1 = 10（应为 10）；用时 39.00 s（arm 0.003 / 扫描 0.689 / 取数 0.002 / 存 0.000 / 回程+Y 0.574）
收到停止：完成 10/20 条 A-line（1/2 行），不再扫下一行。
回到起点：命令位置 X +0.0 um，Y +0.0 um（应为 0 / 0）；ctr1 全程 10（应为 10）
>>
</pasted_content id="416e">

  我看到了x转了

### 🤖 Claude · 2026-10-14 21:35

**X 转了是对的，但这两次都没跑到第 2 行：程序在第 1 行之后收到了「停止」**，两次打印里都有这一句：

```
收到停止：完成 10/20 条 A-line（1/2 行），不再扫下一行。
```

所以 Y 一直没动，X 回程后就结束了。按停止的逻辑来说，这样处理完全正确：做完当前这一行 → 只回程、Y 不前进 → 回到起点 0 / 0，ctr1 = 10。等于顺便验证了 6.6「行间停止」。

**为什么会收到停止：** 有两种可能，都不是你故意点的。
1. **回车按到了停止按钮上（最可能）。** 程序开始时会弹出带停止按钮的小窗口，它会抢走键盘焦点。焦点在那个窗口上时按回车，等于点了按钮。你第一次问「胶带好像没动」，很可能就是那次回车按到了按钮上，后来点了命令行窗口再按回车，才继续往下走。
2. 把那个小窗口关掉了。关窗口也算停止。

看一眼那个小窗口：按钮上的字如果变成了「收到：这一行做完就停」，就是第 1 种。

**怎么避免，两个办法你选：**
- **不改代码**：每次暂停时，先**用鼠标点一下命令行窗口**再按回车；小窗口挪到旁边，不要关。
- **改代码（我建议）**：在 3 个地方各加一行 `commandwindow;`，它会把键盘焦点交还给命令行窗口：
  - [cscan_test.m:769](07_MATLAB/cscan_test.m:769) `drawnow;` 的下一行；
  - [cscan_test.m:781](07_MATLAB/cscan_test.m:781) 和 [cscan_test.m:831](07_MATLAB/cscan_test.m:831) 的 `input(...)` 前面各一行。

不管选哪个，再跑 4.1 都不用改别的参数。第 20 行现在应该还是 `true`，先确认胶带都在记号上，然后运行。

### 🧑 用户 · 2026-10-14 21:36

那我怎么改最合适

### 🤖 Claude · 2026-10-14 21:36

> 🔧 Bash · description: Show stop-button and pause lines for edit guidance

### ⚙️ 工具 · 2026-10-14 21:36

<details><summary>工具输出</summary>

```
1	    stopFig = uifigure('Name', 'C-scan', 'Position', [100 100 320 120]);
       2	    stopBtn = uibutton(stopFig, 'push', 'Text', '停止（做完当前这一行）', 'Position', [30 35 260 50], ...
       3	        'ButtonPushedFcn', @(src, ~) set(src, 'UserData', true, 'Text', '收到：这一行做完就停', 'Enable', 'off'));
       4	    stopBtn.UserData = false;
       5	    figGuard = onCleanup(@() delete(stopFig));           % 窗口已经被关掉也没关系，delete 不报错
       6	    drawnow;                                             % 先把窗口画出来，第 1 行就能按
       7	    fprintf('停止按钮只在行与行之间检查：按下后做完当前这一行再停，然后退回起点。不要用 Ctrl+C（不会自动退回）。\n');
       8	
 
…[截断，共 1880 字符]
```
</details>

### 🤖 Claude · 2026-10-14 21:36

最合适的改法是**在两个 `input(...)` 前面各加一行 `commandwindow;`**，一共 2 行。

**为什么这样改：** `commandwindow` 会把键盘焦点交还给命令行窗口。加了它，每次暂停时回车都会进到 `input`，不会按到停止按钮上；停止按钮用鼠标点照样有效。

改在暂停的那两处就够了。只有暂停时才需要按回车；PAUSE 关着的时候根本不按键，小窗口抢不抢焦点都无所谓。所以 `drawnow` 后面那处可以不加。

**第 1 处**：第 780–782 行，改成

```matlab
            if P.PAUSE_BETWEEN_ROWS
                commandwindow;   % 把键盘焦点还给命令行，回车才不会按到停止按钮
                input(sprintf('【暂停】第 %d 行开始前：……', iy), 's');
            end
```

**第 2 处**：原来的第 830–832 行。第 1 处加了一行，所以现在是第 831–833 行。同样在 `input` 前面加 `commandwindow;`。

`input` 那一行原样保留，我上面用「……」省略了提示文字。

改完存盘，再跑一次 4.1，第 20 行还是 `true`，其他参数都不用动。每次暂停时看一眼小窗口：按钮上应该一直是「停止（做完当前这一行）」。

### 🧑 用户 · 2026-10-14 21:38

你可以帮我改和帮我加么

### 🤖 Claude · 2026-10-14 21:38

> 🔧 Read · file_path: C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_test.m

### ⚙️ 工具 · 2026-10-14 21:38

<details><summary>工具输出</summary>

```
778	    try
779	        for iy = 1:NY
780	            if P.PAUSE_BETWEEN_ROWS
781	                input(sprintf('【暂停】第 %d 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）', iy), 's');
782	            end
783	            if isvalid(stopFig), stopFig.Name = sprintf('C-scan 第 %d/%d 行', iy, NY); end   % 窗口标题显示进度
784	            tRow = tic;              % 从第一次暂停之后开始计；6.10 计时的时候 PAUSE 要关
785	
786	            % ① arm（行与行之间没有 P0.6，这时 arm 不会漏触发）
787	            phase = "arm";
788	            t = tic;
789	            cBefore = ctrRead(cnt);
790	            if P.ATS_ENABLE
791	                atsArmRow(H, ATS, NX);

…[截断，共 2348 字符]
```
</details>

### 🤖 Claude · 2026-10-14 21:38

> 🔧 Edit · file_path: C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_test.m

### ⚙️ 工具 · 2026-10-14 21:38

<details><summary>工具输出</summary>

```
PreToolUse:Edit hook error: This session is running in an isolated git worktree at `C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e`, but `C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_test.m` is in the base repo checkout. Edits there do not land on this session's branch and may corrupt the user's primary working copy. Use the worktree path instead: `C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e\07_MATLAB\cscan_test.m`
```
</details>

### 🤖 Claude · 2026-10-14 21:38

> 🔧 Edit · file_path: C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_test.m

### ⚙️ 工具 · 2026-10-14 21:38

<details><summary>工具输出</summary>

```
PreToolUse:Edit hook error: This session is running in an isolated git worktree at `C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e`, but `C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_test.m` is in the base repo checkout. Edits there do not land on this session's branch and may corrupt the user's primary working copy. Use the worktree path instead: `C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e\07_MATLAB\cscan_test.m`
```
</details>

### 🤖 Claude · 2026-10-14 21:38

我这边改不了：这个会话开在 worktree 里，有一条安全规则（hook）禁止我直接改主目录的文件。它报的原因是「可能弄坏你的主工作副本」。我不绕开它，所以这 2 行要麻烦你自己加，复制粘贴就行。

**第 1 处**：点到第 781 行（`input(sprintf('【暂停】第 %d 行开始前……`）的**行首**，按回车新起一行，粘贴：

```matlab
                commandwindow;   % 把键盘焦点还给命令行，回车才不会按到停止按钮
```

**第 2 处**：现在是第 832 行（`input(sprintf('【暂停】第 %d 行扫完（回程前）……`），同样在它前面新起一行，粘贴：

```matlab
                commandwindow;   % 同上
```

改完按 Ctrl+S 存盘，告诉我，我读一下文件确认放对了位置，然后你再跑 4.1。

以后这个窗口里要改的 MATLAB 文件，还是由你来改，我负责给行号、核对。

### 🧑 用户 · 2026-10-14 21:39

<pasted_content id="416e">
try
        for iy = 1:NY
            if P.PAUSE_BETWEEN_ROWS
                             commandwindow;   % 把键盘焦点还给命令行，回车才不会按到停止按钮
                             % input(sprintf('【暂停】第 %d 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）', iy), 's');
            end
            if isvalid(stopFig), stopFig.Name = sprintf('C-scan 第 %d/%d 行', iy, NY); end   % 窗口标题显示进度
            tRow = tic;              % 从第一次暂停之后开始计；6.10 计时的时候 PAUSE 要关
</pasted_content id="416e">

这样可以么
            

<pasted_content id="416e">
end
            cscan.timing.save(iy) = toc(t);
            if P.PAUSE_BETWEEN_ROWS
                                commandwindow;   % 同上
                input(sprintf('【暂停】第 %d 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）', iy), 's');
            end
</pasted_content id="416e">

### 🤖 Claude · 2026-10-14 21:39

第 2 处是对的。**第 1 处有一个问题：`input` 那一行前面多了一个 `%`**：

```matlab
                             % input(sprintf('【暂停】第 %d 行开始前：……
```

MATLAB 里 `%` 后面的都是注释，这一行就不会执行了，「第 1 行开始前」那次暂停会消失。把行首的 `% ` 删掉，改成：

```matlab
            if P.PAUSE_BETWEEN_ROWS
                commandwindow;   % 把键盘焦点还给命令行，回车才不会按到停止按钮
                input(sprintf('【暂停】第 %d 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）', iy), 's');
            end
```

另外，`commandwindow` 前面的空格多了，MATLAB 不在乎缩进，不影响运行。想对齐的话，选中这几行按 **Ctrl+I**，编辑器会自动排好。

改完 Ctrl+S，告诉我，我再读一遍文件确认。

### 🧑 用户 · 2026-10-14 21:40

改好了，存盘了

### 🤖 Claude · 2026-10-14 21:40

> 🔧 Bash · description: Verify the commandwindow edits and switches

### ⚙️ 工具 · 2026-10-14 21:40

<details><summary>工具输出</summary>

```
779-        for iy = 1:NY
780-            if P.PAUSE_BETWEEN_ROWS
781:                             commandwindow;   % 把键盘焦点还给命令行，回�
782-                             input(sprintf('【暂停】第 %d 行开始前：看两�
--
830-            cscan.timing.save(iy) = toc(t);
831-            if P.PAUSE_BETWEEN_ROWS
832:                                commandwindow;   % 同上
833-                input(sprintf('【暂停】第 %d 行扫完（回程前）：看两个
---
RUN_HARDWARE       = true;  % false：�
ATS_ENABLE         = false;   % false：
PAUSE_BETWEEN_ROWS = true;  % true：每
NY                  = 2;      % 行数 =
DY_UM               = 200;      % Y 像�
```
</details>

### 🤖 Claude · 2026-10-14 21:40

确认了，两处都对：
- 第 781–782 行：`commandwindow;`，下一行是 `input(...)`，前面没有 `%` 了。
- 第 832–833 行：同样。

开关也都是 4.1 要的：第 20 行 `true`、ATS 关、PAUSE 开、NY = 2、DY = 200。

可以跑 4.1 了。先看两条胶带都在记号上，再运行 `cscan_test`。会停 4 次：

1. **第 1 行开始前**：先看一眼小窗口，按钮应该是「停止（做完当前这一行）」，然后按回车。
2. **第 1 行扫完**：X 转了 90°，按回车。
3. **第 2 行开始前**：X 回到记号，**Y 朝电机方向转 36°**，按回车。
4. **第 2 行扫完**：X 又转了 90°，按回车。之后 X 回程、Y 退回，自动结束。

跑完把第 20 行改回 `false`，把打印贴给我，再告诉我 Y 转的方向对不对、最后两条胶带是不是都对准了。

### 🤖 Claude · 2026-10-14 21:43

程序没有出错，是 **MATLAB 的调试器停住了**。左下角写着 `Paused in debugger`，提示符变成了 `K>>`，第 833 行有绿色箭头。最可能的原因是你改代码时点到了第 833 行左边的行号栏，留下了一个**断点**（红点）。程序跑到那里就停下来等你，前面按的几次回车只是在 `K>>` 里输入了空命令，没有影响。

现在台架的状态：第 1 行已经扫完，X 停在 +500 µm（转了 90°，还没回来），Y 没动。readwrite 已经跑完了，电机是静止的，**不危险**。

**接着跑下去：** 在 `K>>` 后面依次输入这两条，每条按一次回车：

```matlab
dbclear all
dbcont
```

- `dbclear all`：清掉所有断点，第 2 行就不会再在这里停。
- `dbcont`：从停下的地方继续。接着会出现「第 1 行扫完（回程前）」的暂停提示，按回车，后面照常走完 4.1。

**不要点工具栏的 Stop / Quit Debugging。** 那相当于 Ctrl+C：程序直接退出，不会自动退回，X 会留在 +500 µm。

### 🧑 用户 · 2026-10-14 21:44

好了，继续跑完了 cscan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 10 个触发、间隔 20 步；X 去程 = 回程 = 1000 步；Y 前进 1 x 400 步后退回；总触发 20；P0.7 全 0：true
K = 20，Ky = 400（Y 未标定时只是假设），fs = 248000，NX = 10，NY = 2，wTrig = 2 行（8.06 us），lead = 25 行
触发 400.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 10 x 2，间距 10.00 x 200.00 um；第一个像素在本行起点 + 200 um；每行 X 走 500 um，Y 共 200 um
ATS：每条 1024 点，每个 buffer 2 条（4096 B），每行 5 个 buffer，一次 Post 5 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.322 s（不含停稳），回程 + Y 表 0.550 s（含 2 次停稳；最后一行 0.350 s），Y 退回表 0.200 s
每行 0.873 s，全程 1.75 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
数据：raw uint16 1024 x 10 x 2 = 40960 B（40.0 kB）

== 8. 上硬件（docs/14 阶段 3–6） ==
【在做什么】循环外准备一次 Dev1、ctr1、ATS；每行 arm → 行扫描 → 取数 → 存盘 → 看停止按钮 → 回程 + Y。
【为什么】DMA buffer 每行重复使用，这一行在电机再动之前就存好；只在行间停，电机不会停在半路，退回距离按累计命令位置算。
DO 时钟：设 248000 S/s，实际 248000.0 S/s（不一样的话，所有时长和扫描速度按比例变）
停止按钮只在行与行之间检查：按下后做完当前这一行再停，然后退回起点。不要用 Ctrl+C（不会自动退回）。
【暂停】第 1 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
833                 input(sprintf('【暂停】第 %d 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）', iy), 's');
K>> 
K>> 
K>> dbclear all
dbcont
【暂停】第 1 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 1/2 行：ATS 关（只动电机）；ctr1 = 10（应为 10）；用时 61.73 s（arm 0.002 / 扫描 0.701 / 取数 0.002 / 存 0.000 / 回程+Y 0.731）
【暂停】第 2 行开始前：看两个手轮，回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 2 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 2/2 行：ATS 关（只动电机）；ctr1 = 10（应为 10）；用时 7.74 s（arm 0.003 / 扫描 0.498 / 取数 0.003 / 存 0.000 / 回程+Y 0.536）
回到起点：命令位置 X +0.0 um，Y +0.0 um（应为 0 / 0）；ctr1 全程 20（应为 20） 你这个不能设成自动的么
>>

### 🤖 Claude · 2026-10-14 21:44

**能，自动的就是第 26 行 `PAUSE_BETWEEN_ROWS = false`。** 设成 false 就一次跑完，不停、也不用按回车。4.1 开着它，只是为了让你每一步都能停下来看胶带；4.2 以后都关掉。

**4.1 的打印全部对上了：**
- 每行 ctr1 = 10，全程 20。
- 最后回到起点 X 0 / Y 0。
- 第 1 行的「回程+Y」0.731 s 比第 2 行的 0.536 s 长约 0.2 s，正好是 Y 走 400 步的时间（计划 0.550 对 0.350）。

第 1 行用时 61.73 s 是因为中间停在调试器里，不算数。

**只剩你眼睛看到的两件事要确认：**
1. 第 2 行开始前那次停，Y 是不是**朝电机方向**转了约 36°？
2. 现在 X、Y 两条胶带是不是都对准记号？

确认后做 **4.2**（两行，ATS 每行重新 arm）：
- 第 20 行先改回 `false`。
- 第 22 行改成 `ATS_ENABLE = true`。
- 第 26 行改成 `PAUSE_BETWEEN_ROWS = false`。

NY = 2、DY = 200 不动。先跑一遍检查模式，没问题再改第 20 行为 `true` 上硬件。

### 🧑 用户 · 2026-10-14 21:46

1. 第 2 行开始前那次停，Y 是不是朝电机方向转了约 36°？ 大概是 这也没办法确定
2. 现在 X、Y 两条胶带是不是都对准记号？是的 改完了

### 🤖 Claude · 2026-10-14 21:46

> 🔧 Bash · description: Verify 4.2 switch settings on disk

### ⚙️ 工具 · 2026-10-14 21:46

<details><summary>工具输出</summary>

```
RUN_HARDWARE       = false;  % false：�
ATS_ENABLE         = true;   % false：�
PAUSE_BETWEEN_ROWS = false;  % true：�
NY                  = 2;      % 行数 =
DY_UM               = 200;      % Y 像�
```
</details>

### 🤖 Claude · 2026-10-14 21:46

4.2 的设置都对了：第 20 行 `false`、ATS 开、PAUSE 关、NY = 2、DY = 200。

**关于 Y 的方向，现在不用担心：**
- 从代码上看是对的：Y 前进时 cscan_test 往 P0.3 输出 DIR = 1，和你 2.3 用 test2_y 走 +1000 µm 时一样，那次实测是朝电机走。
- 36°（200 µm）太小，眼睛确实难判断。到 6.2 量四个角的时候，Y 会走 1.8 mm，钢尺能读出来：朝电机走，读数从 4.3 cm 往 4.1 cm 方向变小（2.4 里 +10 mm 就是从 4.3 变到 3.3）。到时候再确认，不挡 4.2。

**4.2：**
1. 先跑一次检查模式（第 20 行保持 `false`）。打印应该和 4.1 一样：`NY = 2`、`全程 1.75 s`。
2. 第 20 行改成 `true`，运行。这次不会停，一次跑完，大约 3 秒。
3. 跑完马上改回 `false`。把打印和 MAP 图贴给我，重点看：
   - 每行 `A-line 10/10，1 个沿 10/10，ctr1 = 10`；
   - 两行的上升沿中位数差不多（约 1.93 µs）；
   - 没有 `ApiBufferOverflow`，也没有黄色的 `Cscan:Abort` 警告。

### 🧑 用户 · 2026-10-14 21:48

<pasted_content id="416e">
cscan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 10 个触发、间隔 20 步；X 去程 = 回程 = 1000 步；Y 前进 1 x 400 步后退回；总触发 20；P0.7 全 0：true
K = 20，Ky = 400（Y 未标定时只是假设），fs = 248000，NX = 10，NY = 2，wTrig = 2 行（8.06 us），lead = 25 行
触发 400.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 10 x 2，间距 10.00 x 200.00 um；第一个像素在本行起点 + 200 um；每行 X 走 500 um，Y 共 200 um
ATS：每条 1024 点，每个 buffer 2 条（4096 B），每行 5 个 buffer，一次 Post 5 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.322 s（不含停稳），回程 + Y 表 0.550 s（含 2 次停稳；最后一行 0.350 s），Y 退回表 0.200 s
每行 0.873 s，全程 1.75 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
数据：raw uint16 1024 x 10 x 2 = 40960 B（40.0 kB）

== 8. 上硬件（docs/14 阶段 3–6） ==
【在做什么】循环外准备一次 Dev1、ctr1、ATS；每行 arm → 行扫描 → 取数 → 存盘 → 看停止按钮 → 回程 + Y。
【为什么】DMA buffer 每行重复使用，这一行在电机再动之前就存好；只在行间停，电机不会停在半路，退回距离按累计命令位置算。
DO 时钟：设 248000 S/s，实际 248000.0 S/s（不一样的话，所有时长和扫描速度按比例变）
停止按钮只在行与行之间检查：按下后做完当前这一行再停，然后退回起点。不要用 Ctrl+C（不会自动退回）。
第 1/2 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9282 us，脉冲高 1.046 ~ 1.052 V；ctr1 = 10（应为 10）；用时 1.41 s（arm 0.046 / 扫描 0.564 / 取数 0.048 / 存 0.002 / 回程+Y 0.751）
第 2/2 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9277 us，脉冲高 1.046 ~ 1.052 V；ctr1 = 10（应为 10）；用时 1.14 s（arm 0.049 / 扫描 0.513 / 取数 0.054 / 存 0.002 / 回程+Y 0.525）
回到起点：命令位置 X +0.0 um，Y +0.0 um（应为 0 / 0）；ctr1 全程 20（应为 20）

== 9. 结果（docs/14 6.1、6.3、6.4） ==
【在做什么】汇总每条 A-line 的快速检查，算 MAP；存过盘的话把文件读回来逐点比较。
【为什么】条数、ctr1、计划位置三个数对上，才能说第 k 条记录 = 第 k 个位置；重读一致才说明存的东西能用。
完成 2/2 行，A-line 20 条；每条正好 1 个沿：20/20；rail 点数 0
上升沿 1.9263 ~ 1.9323 us，标准差 2.19 ns，峰峰 6.01 ns；MAP 1.0403 ~ 1.0460 V（标准差 1.79 mV）
>>
</pasted_content id="416e">

  true 20行跑了

### 🤖 Claude · 2026-10-14 21:48

**4.2 通过。** C-scan 新加的「每行重新 arm、每行 Abort」第一次上硬件就正常：

| 检查项 | 结果 | 判据 |
|---|---|---|
| 每行条数 / ctr1 | 10/10、10；10/10、10；全程 20 | ✔ |
| 两行上升沿中位数 | 1.9282 / 1.9277 µs，只差 0.5 ns | 差 < 1 ns ✔ |
| 全部 20 条 | 1.9263–1.9323 µs，标准差 2.19 ns；rail 0 | 和 3.1、3.2 同一区间 ✔ |
| MAP | 1.0403–1.0460 V，标准差 1.79 mV | ±10 mV 内 ✔ |
| ApiBufferOverflow、Cscan:Abort | 都没有 | ✔ |
| 回到起点 | X 0 / Y 0 | ✔ |

MAP 图上有竖条纹，是因为颜色范围只有 6 mV（1.040–1.046 V），一点噪声就显成不同颜色。两行的颜色分布差不多，说明两行采到的是一样的信号。

**两件事：**
1. 第 20 行改回 `false`。
2. X、Y 的胶带都回到记号了吗？

**接下来你选：**
- **继续做 5.1**（10 × 10，约 15 秒）：改第 31 行 `NY = 10`、第 33 行 `DY_UM = 10`、第 24 行 `SAVE_DATA = true`，其他不动。
- **今天到此收工**：3.2、4.1、4.2 都过了，正好是今天计划的范围。我来写工作日志和 docs/14 的实测记录、导出对话、commit。

### 🧑 用户 · 2026-10-14 21:49

改回false了，胶带都回来了，继续做5.1

### 🤖 Claude · 2026-10-14 21:49

好，做 5.1。

**改 3 行**（第 20 行保持 `false`）：

| 行 | 改成 |
|---|---|
| 24 | `SAVE_DATA = true;` |
| 31 | `NY = 10;` |
| 33 | `DY_UM = 10;` |

第 62 行的 `NOTE` 会存进文件，可以顺手改成 `"测试信号（函数发生器），激光关；docs/14 5.1 第一次 10x10"`，不改也行。

**先跑检查模式**，应该看到：
- `Ky = 20`、`NY = 10`、`Y 共 90 um`
- `回程 + Y 表 0.360 s`、`Y 退回表 0.090 s`、`全程 6.91 s`
- 假数据会存一个 `cscan_mock_….mat`，最后打印 `重读 …：isequal(raw) = 1，isequal(MAP) = 1`。这顺便测了存盘再读回来的通路。

**再上硬件**（第 20 行改 `true`），大约 12–15 秒：
- 每行 `10/10、ctr1 = 10`，一共 10 行；
- X 来回 10 次，每次 90°；Y 每行走一小步，9 步一共 16°，最后退回；
- 最后：`回到起点 0 / 0`、`ctr1 全程 100`、`100/100`、`rail 0`，`重读 … isequal(raw) = 1，isequal(MAP) = 1`。

跑完把第 20 行改回 `false`，把打印和 MAP 图贴给我。

### 🧑 用户 · 2026-10-14 21:50

<pasted_content id="416e">
cscan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 10 个触发、间隔 20 步；X 去程 = 回程 = 1000 步；Y 前进 9 x 20 步后退回；总触发 100；P0.7 全 0：true
K = 20，Ky = 20（Y 未标定时只是假设），fs = 248000，NX = 10，NY = 10，wTrig = 2 行（8.06 us），lead = 25 行
触发 400.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 10 x 10，间距 10.00 x 10.00 um；第一个像素在本行起点 + 200 um；每行 X 走 500 um，Y 共 90 um
ATS：每条 1024 点，每个 buffer 2 条（4096 B），每行 5 个 buffer，一次 Post 5 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.322 s（不含停稳），回程 + Y 表 0.360 s（含 2 次停稳；最后一行 0.350 s），Y 退回表 0.090 s
每行 0.683 s，全程 6.91 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
  对照 docs/14 附 A：每行 0.68 s、全程约 6.9 s 对得上。附 A 把一次停稳算在行扫描里（0.37 + 0.31 s），
  本程序两次停稳都在回程 + Y 表里（0.32 + 0.36 s），所以 docs/14 3.2 的"readwrite >= 0.37 s"应为 >= 0.32 s。
数据：raw uint16 1024 x 10 x 10 = 204800 B（200.0 kB）

== 7. 假数据走一遍数据通路（docs/14 1.4） ==
【在做什么】造一组已知图案的 raw（第 iy 行第 ix 条的脉冲高 = iy + ix/100 个单位），走一遍 快速检查 → 逐行存盘 → MAP → 重读。
【为什么】测试信号下 MAP 本来就是均匀的，行列排错了看不出来；用已知图案才能逐点核对。
数据文件：C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_mock_20261014_175019.mat
假数据没有 ctr1 和计时，下面每行的 ctr1、用时显示 NaN。
第 1/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9389 us，脉冲高 0.303 ~ 0.330 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 2/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9360 us，脉冲高 0.603 ~ 0.630 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 3/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9363 us，脉冲高 0.903 ~ 0.930 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 4/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9351 us，脉冲高 1.203 ~ 1.230 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 5/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9333 us，脉冲高 1.503 ~ 1.530 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 6/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9327 us，脉冲高 1.803 ~ 1.830 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 7/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9340 us，脉冲高 2.103 ~ 2.130 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 8/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9334 us，脉冲高 2.403 ~ 2.430 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 9/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9342 us，脉冲高 2.703 ~ 2.730 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 10/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9333 us，脉冲高 3.003 ~ 3.030 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
完成 10/10 行，A-line 100 条；每条正好 1 个沿：100/100；rail 点数 0
上升沿 1.9290 ~ 1.9414 us，标准差 2.61 ns，峰峰 12.33 ns；MAP 0.3030 ~ 3.0300 V（标准差 866.07 mV）
重读 C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_mock_20261014_175019.mat：isequal(raw) = 1，isequal(MAP) = 1
MAP(3,7) = 3.07（应为 3.07）；MAP(10,1) = 10.01（应为 10.01）
逐点核对：100/100 个像素对得上（误差 < 0.005 个单位）

*** 检查模式：没有向硬件发送任何信号。确认无误后把 RUN_HARDWARE 改成 true ***
>>
</pasted_content id="416e">

### 🤖 Claude · 2026-10-14 21:50

检查模式全部对上了：`Ky = 20`、`NY = 10`、`Y 共 90 um`、`Y 退回表 0.090 s`、`全程 6.91 s`；假数据存盘后读回来 `isequal(raw) = 1、isequal(MAP) = 1`，100/100 个像素都对得上。

**这张假数据的 MAP 图正好说明行的顺序是对的。** 颜色从下到上由深蓝变到黄：第 1 行在 Y = 0（最暗，0.3 V），第 10 行在 Y = 90 µm（最亮，3.0 V）。如果行排反了，就会上暗下亮；如果维度转置了，颜色就会变成左右变化。

**上硬件：**
1. 第 20 行改成 `true`，运行。大约 12–15 秒，不会停。
2. 盯一下 X 来回 10 次，Y 每行一小步。
3. 跑完马上改回 `false`，把打印和 MAP 图贴给我。这次 MAP 应该是**均匀的**，约 1.04–1.05 V，只有噪声色斑，没有整行的条纹。

### 🧑 用户 · 2026-10-14 21:52

我还有一个视频 但是我好像没看见y动

### 🤖 Claude · 2026-10-14 21:52

**MAP 是均匀的，这正是要的结果：** 1.042–1.047 V，只差 5 mV，没有整行的条纹；上升沿 1.927–1.932 µs，色斑随机分布。截图里第 3–8 行都是 10/10、1 个沿 10/10。

**没看见 Y 动，是正常的，因为 Y 每行只走 10 µm：**
- 每行 20 个脉冲，联轴器只转 **1.8°**，用时 10 ms。
- 9 行加起来才 16°，最后 0.09 s 一下子退回去。
- 联轴器表面每行只挪约 0.3 mm，肉眼几乎看不出来。

视频我这边看不了。如果想用它确认，截两帧图发过来：第 1 行时一张、第 10 行时一张，对比 Y 胶带的位置，应该差约 16°。

**还需要两样东西：**
1. 第 20 行改回 `false`。
2. 把**完整的打印**贴给我。截图里只有第 3–8 行，我要看最后几行：`回到起点 0 / 0`、`ctr1 全程 100`、`100/100`、`rail 0`，还有 `重读 … isequal(raw) = 1`。

**建议补一个 1 分钟的 Y 检查**，把「C-scan 里 Y 真的在动、方向朝电机」坐实：

| 行 | 改成 |
|---|---|
| 22 | `ATS_ENABLE = false` |
| 24 | `SAVE_DATA = false` |
| 26 | `PAUSE_BETWEEN_ROWS = true` |
| 31 | `NY = 2` |
| 33 | `DY_UM = 1000` |

这样 Y 一步走 1 mm，联轴器转**半圈（180°）**，一眼就能看到。在「第 2 行开始前」那次暂停看钢尺：应该从 4.3 cm 变成约 **4.2 cm**（朝电机，读数变小）。

先贴完整打印，再决定做不做这个检查。

### 🧑 用户 · 2026-10-14 21:53

@"C:\Users\2031\.claude\uploads\dd5e50b6-cf1b-42d5-9426-841a66229aa5\87cd199c-IMG_3473.MOV" 这个合理么  你找个图是什么图 可i给我解释一下么 电压么

### 🤖 Claude · 2026-10-14 21:53

> 🔧 Bash · description: Check video file and ffmpeg availability

### ⚙️ 工具 · 2026-10-14 21:53

<details><summary>工具输出</summary>

```
Exit code 1
-rw-r--r-- 1 2031 197121 31310618 Oct 14 17:53 C:/Users/2031/.claude/uploads/dd5e50b6-cf1b-42d5-9426-841a66229aa5/87cd199c-IMG_3473.MOV
```
</details>

### 🤖 Claude · 2026-10-14 21:54

> 🔧 Bash · description: Extract frames from the video with MATLAB

### ⚙️ 工具 · 2026-10-14 21:54

<details><summary>工具输出</summary>

```
dur 26.92 s, fps 29.98, 1088x1920
ok
f01_00.20s.jpg
f02_01.97s.jpg
f03_03.74s.jpg
f04_05.50s.jpg
f05_07.27s.jpg
f06_09.04s.jpg
f07_10.81s.jpg
f08_12.58s.jpg
f09_14.34s.jpg
f10_16.11s.jpg
f11_17.88s.jpg
f12_19.65s.jpg
f13_21.42s.jpg
f14_23.19s.jpg
f15_24.95s.jpg
f16_26.72s.jpg
```
</details>

### 🤖 Claude · 2026-10-14 21:54

> 🔧 Read · file_path: C:\Users\2031\AppData\Local\Temp\claude\C--Users-2031-Desktop-Research-PAM--claude-worktrees-wizardly-wozniak-c7af7e\dd5e50b6-cf1b-42d5-9426-841a66229aa5\scratchpad\frames\f01_00.20s.jpg

### ⚙️ 工具 · 2026-10-14 21:54

<details><summary>工具输出</summary>

```
[图片]
```
</details>

### 🤖 Claude · 2026-10-14 21:54

> 🔧 Read · file_path: C:\Users\2031\AppData\Local\Temp\claude\C--Users-2031-Desktop-Research-PAM--claude-worktrees-wizardly-wozniak-c7af7e\dd5e50b6-cf1b-42d5-9426-841a66229aa5\scratchpad\frames\f08_12.58s.jpg

### ⚙️ 工具 · 2026-10-14 21:54

<details><summary>工具输出</summary>

```
[图片]
```
</details>

### 🤖 Claude · 2026-10-14 21:54

**这张图合理。** 它是 **Figure 11「C-scan MAP」**，左右两张都是 10 × 10 的格子。每个小方块 = 一个位置 = 一条 A-line，横轴是 X、纵轴是 Y，单位都是 µm，范围 0–90 µm。

**左图：MAP，单位是伏（V），对，是电压。**
- 每个方块的颜色 = 那条 A-line 的 `max(v − median(v))`：先减掉基线（中值），再取最高点，也就是测试脉冲比基线高多少。
- 测试脉冲就是发生器 G2 的 200 ns、约 1 V 方波，示波器 CH3 量到 1.06 V。这里 100 个点都是 **1.042–1.047 V**，和示波器一致。
- 一共只差 5 mV，是噪声。色条范围只有 5 mV，所以看起来花，其实**每个位置都一样**，测试信号下就该这样。
- 以后换成真实光声信号，颜色就是每个位置的光声信号有多强。这张图就是成像结果，叫「最大幅度投影」。

**右图：上升沿时间，单位是 µs。**
- 每条 A-line 里，脉冲越过 0.5 V 的时刻，从触发开始算。
- 都在 **1.927–1.932 µs**：发生器的 Delay 是 2 µs，减去一段约 70 ns 的固定偏差（docs/13 §7.2 有记录）。
- 前后只差 5 ns，不到一个采样点（5.56 ns），是触发抖动。色斑随机，**没有一整行偏高或偏低**，说明每行重新 arm 之后计时一致。

**视频：** 我把视频拆成了 16 帧来看。画面是俯拍整个台架，镜头会晃，联轴器在画面里很小。Y 每行只转 1.8°，从视频里分辨不出来，这不说明 Y 没动。要确认 Y 在 C-scan 里真的动了，最可靠的还是上一条说的 **DY = 1000 µm 检查**：转半圈，钢尺从 4.3 变到 4.2 cm。

**还差：**
1. 第 20 行改回 `false`。
2. 贴完整打印的最后几行，我要确认 `ctr1 全程 100`、`100/100`、`isequal(raw) = 1`。

### 🧑 用户 · 2026-10-14 21:55

那下面我要做什么

### 🤖 Claude · 2026-10-14 21:55

> 🔧 Bash · description: Check switches and list saved C-scan data files

### ⚙️ 工具 · 2026-10-14 21:55

<details><summary>工具输出</summary>

```
RUN_HARDWARE       = true;  % false：�
ATS_ENABLE         = true;   % false：�
SAVE_DATA          = true;  % true：每
PAUSE_BETWEEN_ROWS = false;  % true：�
NY                  = 10;      % 行数 
DY_UM               = 10;      % Y 像�
total 576
drwxr-xr-x 1 2031 197121      0 Oct 14 17:51 .
drwxr-xr-x 1 2031 197121      0 Oct 14 17:50 ..
-rw-r--r-- 1 2031 197121 447173 Oct 14 17:51 cscan_20261014_175112.mat
-rw-r--r-- 1 2031 197121 128863 Oct 14 17:50 cscan_mock_20261014_175019.mat
```
</details>

### 🤖 Claude · 2026-10-14 21:55

> 🔧 Bash · description: Read the 5.1 data file to verify results

### ⚙️ 工具 · 2026-10-14 21:56

<details><summary>工具输出</summary>

```
rowsDone 10/10; trigCount [10 10 10 10 10 10 10 10 10 10]; total 100
nEdge==1: 100/100; rail 0; tEdge 1.9261-1.9325 us std 1.93 ns; vMax 1.047-1.054 V
MAP 1.0413-1.0480 V std 1.61 mV
stop  err  fsActual 248000
row med 1.192 s; arm 0.047 scan 0.502 collect 0.053 save 0.058 move 0.541; sum rows 12.62 s
row medians tEdge: [1.9286 1.9278 1.9276 1.9284 1.9289 1.9277 1.9277 1.9284 1.9277 1.9291]
```
</details>

### 🤖 Claude · 2026-10-14 21:56

我直接读了刚才存的数据文件 `cscan_data\cscan_20261014_175112.mat`，打印不用贴了。**5.1 第一次完整的 10 × 10 通过：**

| 项 | 结果 |
|---|---|
| 完成行数 / 每行 ctr1 | 10/10；每行都是 10，全程 **100** |
| 每条正好 1 个沿 / rail | **100/100** / 0 |
| 上升沿 | 1.9261–1.9325 µs，标准差 1.93 ns；10 行的中位数都在 1.9276–1.9291 µs |
| MAP | 1.0413–1.0480 V，标准差 1.61 mV |
| 出错 / 停止 | 无 |
| 用时 | 每行约 1.19 s（扫描 0.50 + 回程 0.54 + 其他 0.15），10 行共 12.6 s；计划是 6.91 s |

**下面做这三件事：**

1. **马上把第 20 行改回 `false`**，文件里现在还是 `true`。
2. **（1 分钟，建议做）确认 Y 在 C-scan 里真的动了、方向朝电机。** 改：

   | 行 | 改成 |
   |---|---|
   | 22 | `ATS_ENABLE = false` |
   | 24 | `SAVE_DATA = false` |
   | 26 | `PAUSE_BETWEEN_ROWS = true` |
   | 31 | `NY = 2` |
   | 33 | `DY_UM = 1000` |

   先跑检查模式，再改第 20 行为 `true` 跑。在「第 2 行开始前」那次暂停看：Y 联轴器转了**半圈**，钢尺约 **4.2 cm**（原来 4.3）。跑完第 20 行改回 `false`。
3. **收工**：
   - 你：`cscan_test.m` 第 24 行 `SAVE_DATA` 改回 `false`；KORAD 关，发生器 Output 关。
   - 我：写工作日志、docs/14 的实测记录（3.2、4.1、4.2、5.1，还有回车误按停止、断点这两个坑），导出对话，commit。

阶段 6（量四个角、行顺序、拔线等）下次再做。

### 🧑 用户 · 2026-10-14 21:58

cscan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 10 个触发、间隔 20 步；X 去程 = 回程 = 1000 步；Y 前进 1 x 2000 步后退回；总触发 20；P0.7 全 0：true
K = 20，Ky = 2000（Y 未标定时只是假设），fs = 248000，NX = 10，NY = 2，wTrig = 2 行（8.06 us），lead = 25 行
触发 400.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 10 x 2，间距 10.00 x 1000.00 um；第一个像素在本行起点 + 200 um；每行 X 走 500 um，Y 共 1000 um
ATS：每条 1024 点，每个 buffer 2 条（4096 B），每行 5 个 buffer，一次 Post 5 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.322 s（不含停稳），回程 + Y 表 1.350 s（含 2 次停稳；最后一行 0.350 s），Y 退回表 1.000 s
每行 1.673 s，全程 3.35 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
数据：raw uint16 1024 x 10 x 2 = 40960 B（40.0 kB）

== 8. 上硬件（docs/14 阶段 3–6） ==
【在做什么】循环外准备一次 Dev1、ctr1、ATS；每行 arm → 行扫描 → 取数 → 存盘 → 看停止按钮 → 回程 + Y。
【为什么】DMA buffer 每行重复使用，这一行在电机再动之前就存好；只在行间停，电机不会停在半路，退回距离按累计命令位置算。
DO 时钟：设 248000 S/s，实际 248000.0 S/s（不一样的话，所有时长和扫描速度按比例变）
停止按钮只在行与行之间检查：按下后做完当前这一行再停，然后退回起点。不要用 Ctrl+C（不会自动退回）。
【暂停】第 1 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 1 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 1/2 行：ATS 关（只动电机）；ctr1 = 10（应为 10）；用时 14.81 s（arm 0.003 / 扫描 0.598 / 取数 0.004 / 存 0.000 / 回程+Y 1.493）
 【暂停】第 2 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 2/2 行：ATS 关（只动电机）；ctr1 = 10（应为 10）；用时 7.11 s（arm 0.003 / 扫描 0.508 / 取数 0.005 / 存 0.000 / 回程+Y 0.522）
回到起点：命令位置 X +0.0 um，Y +0.0 um（应为 0 / 0）；ctr1 全程 20（应为 20）
>> 好了都动了回到原点了

### 🤖 Claude · 2026-10-14 21:59

Y 检查通过：
- 第 1 行之后的「回程+Y」用了 1.493 s，计划 1.350 s，其中 Y 走 2000 步、1 mm 占 1.0 s，对得上。
- 每行 ctr1 = 10，最后回到 0 / 0。

C-scan 里 Y 确实在动，也回到了原点。如果当时看了钢尺，告诉我读数是不是约 4.2 cm，这样方向也有了实测记录；没看也没关系，代码和 2.3 的实测都是朝电机。

**今天到这里，收工：**

**你做**
1. `cscan_test.m` 恢复成默认值，下次打开就是安全状态：

   | 行 | 改成 |
   |---|---|
   | 20 | `RUN_HARDWARE = false` |
   | 22 | `ATS_ENABLE = true` |
   | 24 | `SAVE_DATA = false` |
   | 26 | `PAUSE_BETWEEN_ROWS = false` |
   | 31 | `NY = 10` |
   | 33 | `DY_UM = 10` |

   第 27、51–53 行（Y 的标定值）和那两行 `commandwindow` 保留。
2. KORAD 关，发生器两路 Output 关。
3. 存盘后告诉我。

**我做**（你存完盘后开始）
- docs/14 末尾加「实测记录 2026-10-14 晚」：3.2、4.1、4.2、5.1 和 Y 检查的结果；Y 胶带重贴；两个坑（回车按到停止按钮、误点断点）；每行软件开销约 0.5 s。
- docs/14 的 3.2 通过标准改成 readwrite ≥ 0.32 s，附 A 的时长拆分改成 0.32 + 0.36 s。你开工时也是按 0.32 s 写的，没意见我就一起改。
- 工作日志加一条，导出本次对话，commit 进 main。最后提醒你双击 `sync_pam.cmd`。

### 🧑 用户 · 2026-10-14 22:00

好了 那我可以再做一点么 现在我的cscan进行到什么程度了

### 🤖 Claude · 2026-10-14 22:00

> 🔧 Bash · description: Verify cscan_test.m defaults restored

### ⚙️ 工具 · 2026-10-14 22:00

<details><summary>工具输出</summary>

```
RUN_HARDWARE       = false; % false：�
ATS_ENABLE         = true;   % false：�
SAVE_DATA          = false;  % true：�
PAUSE_BETWEEN_ROWS = false;  % true：�
NY                  = 10;      % 行数 
DY_UM               = 10;      % Y 像�
```
</details>

### 🤖 Claude · 2026-10-14 22:01

默认值都恢复了，文件是安全状态。

**C-scan 现在的进度**（按 docs/14 的阶段）

| 阶段 | 状态 |
|---|---|
| 0 开工检查、1 离线检查模式 | ✔ |
| 2 Y 轴（标定、方向、速度、串扰） | ✔（今天下午；Y 在 C-scan 里的小步今晚也验证了） |
| 3.1 / 3.2 单行 | ✔ |
| 4.1 / 4.2 两行（只动电机 / ATS 每行重新 arm） | ✔ |
| **5.1 第一次 10 × 10** | **✔ 100/100，ctr1 100，MAP 均匀** |
| 6 测试 ①–⑥ | 部分完成，见下表 |

阶段 6 的情况：

| 测试 | 状态 |
|---|---|
| 6.1 ① 条数和计数 | 5.1 已满足（100/100、ctr1 100、nEdge 全是 1、rail 0） |
| 6.3 ③ MAP | 5.1 已满足（均匀，差 ±3 mV） |
| 6.8 ⑥ 回到起点 | 每次都回到了 |
| 6.6 ⑤a 行间停止 | 4.1 意外做过一次（两行里停在第 1 行之后），正式版还没做 |
| 6.4 ④ 保存和重读 | 跑时自动重读过；**单独的 `cscan_replot.m` 还没跑** |
| 6.2 四个角、6.5 行顺序、6.7 拔触发线、6.9 重复 3 次、6.10 计时、6.11 ring buffer | 没做 |

**可以再做一点。按要不要开硬件分两类：**

**不开硬件，2 分钟：6.4 重读。** 命令行直接运行 `cscan_replot`，它会自动读最新的数据文件 `cscan_20261014_175112.mat`，不碰任何硬件。通过标准：打印 `isequal(MAP) = 1`、`isequal(nEdge) = 1`、`isequaln(tEdge) = 1`，画出的 MAP 和刚才那张一样。

**要重新开 KORAD 和发生器，各约 5 分钟：**
- **6.5 行顺序**（最有价值）：第 3 行开始前关掉发生器 CH2 的 Output，第 4 行开始前再打开，MAP 上第 3 行应该是一条横的暗线。这是唯一能证明「第 k 行数据 = 第 k 行位置」的测试。
- **6.6 正式行间停止**：10 × 10 跑到第 4 行时点停止按钮，应该打印「完成 40/100」，然后回到原点。

建议先跑 `cscan_replot`，跑完把打印贴给我。

### 🧑 用户 · 2026-10-14 22:02

先存一下 我一会回家看一下bscan 给我一个cscan的plan 今晚回来可以做的

### 🤖 Claude · 2026-10-14 22:02

> 🔧 Bash · description: Inspect export/sync scripts and machine labels

### ⚙️ 工具 · 2026-10-14 22:02

<details><summary>工具输出</summary>

```
2:# 输出格式和 .py 一样：08_对话记录/<日期>_<标题>_<id前8位>.md，并重建 INDEX.md。
6:#   powershell -ExecutionPolicy Bypass -File tools\export_pam_chats.ps1 -Ids 08539d41 -Machine "LabPC(新账号)"
9:# 默认在 ~/.claude/projects 下所有子目录里找 .jsonl；-Src 可指定别的目录。
10:param(
12:    [string[]]$Ids = @(),
17:    [string]$Machine = "LabPC",
22:$Out = Join-Path $Repo "08_对话记录"
---
2:# 顺序：导出本机有更新的 Claude 会话 → commit → 从 GitHub 取回并合并（merge）→ 重建对话索引 → push。
20:    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "export_pam_chats.ps1") -Src $src -All -Changed -Machine $Machine
24:& $git add -A
27:    & $git c
…[截断，共 1865 字符]
```
</details>

### 🤖 Claude · 2026-10-14 22:02

> 🔧 Bash · description: Confirm main is unchanged and locate docs/14 lines

### ⚙️ 工具 · 2026-10-14 22:02

<details><summary>工具输出</summary>

```
7f65958 2026-10-14 Y 轴: bscan_test.m:37 MAX_SPEED_MM_S 改 4（用户改）；新增 test2_y.m（Y 轴移动 + 累计位置 + ±12 mm 软件限位）
7f65958 2026-10-14 Y 轴: bscan_test.m:37 MAX_SPEED_MM_S 改 4（用户改）；新增 test2_y.m（Y 轴移动 + 累计位置 + ±12 mm 软件限位）
47:- **时间**：行扫描表约 0.37 s；回程 + Y 约 0.31 s；每行约 0.68 s；10 行全程约 **6.9 s**（下限，未含 readwrite 启动和 ATS arm 的开销）。
113:  - 每张表 assert：P0.6 上升沿个数（行扫描表 = Nx，回程表 = 0）；相邻两个触发之间正好 K 个脉冲；P0.7 全是 0；DIR 每次变化后至少 25 行才有 STEP；最后一行全 0。
192:- 通过：和 3.1 结果一致；Y 手轮不动；X 回到记号；readwrite 时间 ≥ 0.37 s。
443:**今天计划的阶段 0、2（2.5 的「连走 9 次 Δy」除外）、3.1 全部完成。下一步交给 C-scan 窗口：填 cscan_test.m 第 51–53 行、Y_CALIBRATED = true，做 3.2（Ny = 1
…[截断，共 827 字符]
```
</details>

### 🤖 Claude · 2026-10-14 22:03

> 🔧 Bash · description: Check-mode numbers for 6.2 and 6.9 parameter sets

### ⚙️ 工具 · 2026-10-14 22:03

<details><summary>工具输出</summary>

```
MOCK_DATA          = true;   % 只在 RU
NX                  = 10;      % 每行 
NY                  = 10;      % 行数 
DX_UM               = 10;      % X 像�
DY_UM               = 10;      % Y 像�
MOCK_DATA          = false;  % 只�
NX                  = 10;      % 每
NY                  = 10;      % 行
DX_UM               = 200;      % X 
DY_UM               = 200;      % Y 
MOCK_DATA          = false;  % 只�
NX                  = 20;      % 每
NY                  = 5;       % 行
DX_UM               = 5;       % X �
DY_UM               = 20;      % Y �
######## c62
K = 400Ky = 400Y fs = 248000NX 
…[截断，共 1070 字符]
```
</details>

### 🤖 Claude · 2026-10-14 22:03

> 🔧 Bash · description: Get durations and travel for 6.2 and 6.9 sets

### ⚙️ 工具 · 2026-10-14 22:03

<details><summary>工具输出</summary>

```
######## c62
 10 x 10 200.00 x 200.00 um + 200 um X  2400 umY  1800 um
ATS 1024  buffer 2 4096 B 5  buffer Post 5 CH A IMPEDANCE_50_OHMTRIG IN ETR_5V
 0.797 s + Y  1.500 s 2  1.300 sY  1.800 s
 2.298 s 24.58 s readwrite  ATS arm
raw uint16 1024 x 10 x 10 = 204800 B200.0 kB
######## c69
 20 x 5 5.00 x 20.00 um + 200 um X  500 umY  80 um
ATS 1024  buffer 2 4096 B 10  buffer Post 10 CH A IMPEDANCE_50_OHMTRIG IN ETR_5V
 0.322 s + Y  0.370 s 
…[截断，共 736 字符]
```
</details>

### 🤖 Claude · 2026-10-14 22:04

> 🔧 Read · file_path: C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e\06_控制程序\docs\14_C-scan测试流程.md

### ⚙️ 工具 · 2026-10-14 22:04

<details><summary>工具输出</summary>

```
44	| recordsPerBuffer | **2**：每个 buffer 4096 B，每行 5 个 buffer；400 Hz ÷ 2 = 200 个/s < 2 kHz | 必须整除 Nx；SDK 建议至少 2 个、最好 ≥3 个 buffer（PDF 第 53 页）。B 原来的 50 会把 Nx 凑成 50（B:64） |
45	| Wait 超时 | 2000 ms | B:303 |
46	
47	- **时间**：行扫描表约 0.37 s；回程 + Y 约 0.31 s；每行约 0.68 s；10 行全程约 **6.9 s**（下限，未含 readwrite 启动和 ATS arm 的开销）。
48	- **数据**：只存 uint16 `raw(1024, Nx, Ny)` = 204,800 B。不存 double 电压：3×3 mm 时 uint16 已有 18.4 GB，double 会到 73.7 GB，超过 64 GB 内存。
49	- **附 A2（量四个角用）**：Δx = Δy = 200 µm（K = 400），TRIG = 20 Hz，步频仍是 8 kHz。每行 X 行程 2400 µm，像素角在 X = 200 µm 和 2000 µm；Y 从第 1 行到第 10 行走 1800 µm。每行约 2.3 s，全程约 25 s。手轮一圈 2 m
…[截断，共 614 字符]
```
</details>

### 🤖 Claude · 2026-10-14 22:04

正在把今天的结果和今晚的计划写进 docs/14（worktree 里写，再合并进 main），接着写工作日志、导出对话、commit。

### 🤖 Claude · 2026-10-14 22:04

> 🔧 Edit · file_path: C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e\06_控制程序\docs\14_C-scan测试流程.md

### 🤖 Claude · 2026-10-14 22:04

> 🔧 Edit · file_path: C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e\06_控制程序\docs\14_C-scan测试流程.md

### 🤖 Claude · 2026-10-14 22:04

> 🔧 Edit · file_path: C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e\06_控制程序\docs\14_C-scan测试流程.md

### ⚙️ 工具 · 2026-10-14 22:04

<details><summary>工具输出</summary>

```
The file C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e\06_控制程序\docs\14_C-scan测试流程.md has been updated successfully.
```
</details>

### ⚙️ 工具 · 2026-10-14 22:04

<details><summary>工具输出</summary>

```
The file C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e\06_控制程序\docs\14_C-scan测试流程.md has been updated successfully.
```
</details>

### ⚙️ 工具 · 2026-10-14 22:04

<details><summary>工具输出</summary>

```
The file C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e\06_控制程序\docs\14_C-scan测试流程.md has been updated successfully.
```
</details>

### 🤖 Claude · 2026-10-14 22:04

Now the evening record and tonight's plan, appended at the end of docs/14:

### 🤖 Claude · 2026-10-14 22:05

> 🔧 Bash · description: Append evening record and tonight's plan to docs/14

### ⚙️ 工具 · 2026-10-14 22:05

<details><summary>工具输出</summary>

```
| 4 | **6.7 拔触发线**（约 5 分钟） | SAVE 开、PAUSE 开 | 第 4 行�
| 5 | **6.2 四个角 + Y 方向**（约 10 分钟） | 附 A2：DX_UM = 200、D
| 6 | 6.9 重复 + 换参数（时间够再做） | 附 A 原样再跑 2 次（�

收工：cscan_test.m 恢复默认（同上）；Y 回到记号的话 pos_Y.mat
```
</details>

### 🤖 Claude · 2026-10-14 22:05

Now the work log entry:

### 🤖 Claude · 2026-10-14 22:05

> 🔧 Bash · description: Append work log entry for this session

### ⚙️ 工具 · 2026-10-14 22:05

<details><summary>工具输出</summary>

```
0000260     302 247   7   .   5     347 234 213 347 244 272 346 263 242
0000300 345 231 250 343 200 202  \r  \n
  - 坑：停止按钮的小窗口抢焦点，回车按到�
  - docs/14 改正：附 A 时长拆分（0.32 + 0.36 s）�
- 下次第一步：今晚回实验室按 docs/14 末尾「�
```
</details>

### 🤖 Claude · 2026-10-14 22:05

> 🔧 Bash · description: Check line-ending conventions for edited docs

### ⚙️ 工具 · 2026-10-14 22:05

<details><summary>工具输出</summary>

```
Exit code 1
true
# 两边都会往里追加的文件：合并时两边新加的行都保留，不算冲突
06_控制程序/docs/工作日志.md merge=union
08_对话记录/INDEX.md merge=union
06_控制程序/docs/工作日志.md: CRLF=263 LF-only=0
0
06_控制程序/docs/14_C-scan测试流程.md: CRLF=489 LF-only=0
0
```
</details>

### 🤖 Claude · 2026-10-14 22:05

> 🔧 PowerShell · description: Export this session's conversation to 08_对话记录

### ⚙️ 工具 · 2026-10-14 22:05

<details><summary>工具输出</summary>

```
$Repo = Split-Path -Parent $PSScriptRoot
导出 2026-10-13_C-scan_module_Y_axis_+_cscan_test.m_dd5e50b6.md
共导出 1 个会话 → C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\wizardly-wozniak-c7af7e\08_对话记录
 M 06_控制程序/docs/14_C-scan测试流程.md
 M 06_控制程序/docs/工作日志.md
 M 08_对话记录/INDEX.md
?? 08_对话记录/2026-10-13_C-scan_module_Y_axis_+_cscan_test.m_dd5e50b6.md
```
</details>

### 🤖 Claude · 2026-10-14 22:05

> 🔧 Bash · description: Check screenshots README format and 10/14 files

### ⚙️ 工具 · 2026-10-14 22:05

<details><summary>工具输出</summary>

```
| `HW_Y_static_check_1014_5V.jpg`、`HW_Y_static_check_1014_0V.jpg` | 2.2 静态电平：Y STEP− 5.08 V / 0.38 V | 已转写（01、14 记录） |
| `HW_Y_stage_nameplate.jpg`、`HW_Z_tank_tray.jpg` | Y 滑台铭牌、Z 上的水槽托盘 | 待拍 |

## 2026-10-14 下午照片（会话 0dbc3483）
| 文件名 | 内容 | 状态 |
|---|---|---|
| `HW_Y_coupling_tape_mark_1014.jpg` | Y 联轴器上的胶带记号（窗口边框当固定参照） | 已转写（14 记录） |
| `HW_Y_ruler_0um_1014.jpg`、`HW_Y_ruler_plus10mm_1014.jpg`、`HW_Y_ruler_minus10mm_1014.jpg` | Y 在 0 / +10 mm / −10 mm 时的钢尺读数（约 4.3 / 3.3 / 5.3 cm） | 已转写（01、14 记录） |
| `MATLAB_1014_bscan_baseline.jpg` | 2.6 B-scan 基准：400/400、ctr1 400、包络图 | 已转写（13 §3.4） |
| 
…[截断，共 1540 字符]
```
</details>

### 🤖 Claude · 2026-10-14 22:05

> 🔧 Bash · description: Copy evening photos/screenshots into docs and stage

### ⚙️ 工具 · 2026-10-14 22:05

<details><summary>工具输出</summary>

```
warning: in the working copy of '06_控制程序/docs/14_C-scan测试流程.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of '06_控制程序/docs/screenshots/README.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of '06_控制程序/docs/工作日志.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of '08_对话记录/INDEX.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of '08_对话记录/2026-10-13_C-scan_module_Y_axis_+_cscan_test.m_dd5e50b6.md', LF will be replaced by CRLF
…[截断，共 1193 字符]
```
</details>

### 🤖 Claude · 2026-10-14 22:06

> 🔧 Bash · description: Commit records and fast-forward main

### ⚙️ 工具 · 2026-10-14 22:06

<details><summary>工具输出</summary>

```
a23dde8 2026-10-14 C-scan: 3.2/4.1/4.2/5.1 上硬件通过（10×10 100/100）；docs/14 实测记录 + 阶段 6 计划；导出 dd5e50b6
 M 07_MATLAB/cscan_test.m
 create mode 100644 06_控制程序/docs/screenshots/MATLAB_1014_cscan_5.1_figures.png
 create mode 100644 06_控制程序/docs/screenshots/SCOPE_1014_evening_cscan_check.jpg
 create mode 100644 08_对话记录/2026-10-13_C-scan_module_Y_axis_+_cscan_test.m_dd5e50b6.md
a23dde8 2026-10-14 C-scan: 3.2/4.1/4.2/5.1 上硬件通过（10×10 100/100）；docs/14 实测记录 + 阶段 6 计划；导出 dd5e50b6
7f65958 2026-10-14 Y 轴: bscan_test.m:37 MAX_SPEED_MM_S 改 4（用户改）；新增 test2_y.m（Y 轴移动 + 累计位置 + ±12 mm 软件限位）
 M 07_MATLAB/cscan_test.m
```
</details>

### 🤖 Claude · 2026-10-14 22:06

今天的结果存好了，合并进了主目录的 main（`a23dde8`）：
- **docs/14**：末尾加了「2026-10-14 晚」实测记录。3.2 通过标准改成 readwrite ≥ 0.32 s，附 A 的时长拆分也改了。
- **今晚的计划**：写在 docs/14 末尾「下次接着做（阶段 6）」。
- **工作日志**：加了一条。
- **对话**：已导出到 08_对话记录。
- **截图**：6 张，开工复核的发生器和示波器、3.2、4.2、5.1 的图，放在 docs/screenshots。

**现在请双击 `sync_pam.cmd`。** 你改过的 `cscan_test.m`（Y 标定值、两行 `commandwindow`）还没 commit，这个脚本会一起 commit 再推上 GitHub。推上去以后，在家用别的电脑也能看到计划。

**今晚回实验室的 C-scan 计划**（阶段 6，每一步都是先跑检查模式 → 上硬件 → RUN_HARDWARE 改回 false）：

| # | 做什么 | 约多久 | 看到这些才算过 |
|---|---|---|---|
| 0 | 开工复核：MATLAB 路径、KORAD、发生器、示波器、胶带 | 3 分钟 | 和今晚开工时一样 |
| 1 | **6.4 重读**：运行 `cscan_replot`，不碰硬件，**第一个做** | 2 分钟 | 三个 isequal 都是 1 |
| 2 | **6.5 行顺序**：第 3 行时关掉发生器 CH2 | 5 分钟 | MAP 第 3 行是一条**横的**暗线 |
| 3 | **6.6 停止**：跑到第 4 行时点停止 | 3 分钟 | 「完成 40/100」，回到 0 / 0 |
| 4 | **6.7 拔线**：第 4 行前拔掉 TRIG IN | 5 分钟 | 约 2 s 后报错，前 3 行已存，自动退回 |
| 5 | **6.2 四个角**：Δx = Δy = 200 µm | 10 分钟 | 4 个时刻手轮角度在 ±5° 内；**钢尺 4.3 → 4.12 cm，坐实 Y 的方向** |
| 6 | 6.9 重复 + 换参数（时间够再做） | 10 分钟 | 每次 100/100 |

每一步改哪几行、预期打印是什么，docs/14 里都写了。回来后可以开新窗口，也可以接着用这个窗口，我按这个表一步一步带。

另外，Rui 来看的日期还没定，建议约 10/16 周五看 10 × 10。

### 🧑 用户 · 2026-10-14 22:06

sync_pam 双击好了

### 🤖 Claude · 2026-10-14 22:06

> 🔧 Bash · description: Verify sync pushed main to GitHub

### ⚙️ 工具 · 2026-10-14 22:06

<details><summary>工具输出</summary>

```
## main...origin/main
e22cf63 2026-10-14 18:06 sync from LabPC
a23dde8 2026-10-14 C-scan: 3.2/4.1/4.2/5.1 上硬件通过（10×10 100/100）；docs/14 实测记录 + 阶段 6 计划；导出 dd5e50b6
7f65958 2026-10-14 Y 轴: bscan_test.m:37 MAX_SPEED_MM_S 改 4（用户改）；新增 test2_y.m（Y 轴移动 + 累计位置 + ±12 mm 软件限位）
71354f4 2026-10-14 Y 轴: 导出下午会话 0dbc3483；.gitignore 忽略 07_MATLAB/pos_*.mat（本机滑台位置记录）
e22cf63 2026-10-14 18:06 sync from LabPC
e22cf63 2026-10-14 18:06 sync from LabPC
 07_MATLAB/cscan_test.m | 14 ++++++++------
 1 file changed, 8 insertions(+), 6 deletions(-)
```
</details>

### 🤖 Claude · 2026-10-14 22:06

同步成功了，GitHub 现在是 `e22cf63`。你改过的 `cscan_test.m`（Y 标定值和两行 `commandwindow`）由同步脚本 commit 进去了，和今晚的记录、计划一起推了上去。

今天 C-scan 从 3.2 做到了 5.1，第一次 10 × 10 的结果是 100/100。

今晚回来先看 docs/14 末尾「下次接着做（阶段 6）」。第一步是开工复核，第二步运行 `cscan_replot`。回去好好看 B-scan。

### 🧑 用户 · 2026-10-15 00:49

好的，晚上回来接着做 我又回来了兄弟 晚上有三个小时的时间

### 🤖 Claude · 2026-10-15 00:49

> 🔧 Bash · description: Check sync state and cscan_test defaults

### ⚙️ 工具 · 2026-10-15 00:49

<details><summary>工具输出</summary>

```
## main...origin/main
e02baf1 2026-10-14 18:32 reindex from Mac
RUN_HARDWARE       = false; % false：�
ATS_ENABLE         = true;   % false：�
SAVE_DATA          = false;  % true：�
PAUSE_BETWEEN_ROWS = false;  % true：�
NY                  = 10;      % 行数 
DX_UM               = 10;      % X 像�
DY_UM               = 10;      % Y 像�
```
</details>

### 🤖 Claude · 2026-10-15 00:50

欢迎回来，3 个小时够把阶段 6 做完。主目录已经和 GitHub 同步（含你在 Mac 上那次 `e02baf1`），`cscan_test.m` 也是默认的安全状态。

**第 0 步：开工复核（3 分钟）**
1. MATLAB 地址栏是 `Research-PAM\07_MATLAB`。
2. KORAD 开机：23.88 V、C.V 模式，三台驱动器绿灯闪。
3. 发生器两路 Output 打开，设置和下午的照片一样。
4. 示波器底栏是 2 V / 1 V / 500 mV，D = 0。
5. X、Y 的胶带都在记号上（Y 看新贴的那条）。

**第 1 步：6.4 重读，不碰硬件**

在命令行运行：
```matlab
cscan_replot
```
它会读最新的数据文件 `cscan_20261014_175112.mat`，应该看到：
- `isequal(MAP) = 1`
- `isequal(nEdge) = 1`
- `isequaln(tEdge) = 1`
- 画出来的 MAP 和下午 5.1 那张一样（约 1.04–1.05 V，均匀）

复核完、跑完，把打印贴给我。

### 🧑 用户 · 2026-10-15 00:52

好了

### 🤖 Claude · 2026-10-15 00:52

**6.4 通过。** 只用文件里的 raw 重新算，结果和运行时存的逐点相同：`isequal(MAP) = 1`、`isequal(nEdge) = 1`、`isequaln(tEdge) = 1`；100/100、每行 ctr1 10；图和 5.1 一样。说明存下来的数据能用，在别的电脑上也能复现。

**第 2 步：6.5 行顺序**

为什么做这个：测试信号下每个像素都一样，即使行排错了、数据转置了，MAP 看起来也是均匀的。所以故意让第 3 行没有信号，看暗线出现在哪里。

1. 改两行：第 24 行 `SAVE_DATA = true`，第 26 行 `PAUSE_BETWEEN_ROWS = true`。
2. 先跑检查模式（第 20 行保持 `false`），确认是 10 × 10、全程 6.91 s。
3. 第 20 行改成 `true`，运行。一共停 20 次：
   - **「第 3 行开始前」**那次：按发生器上 **CH2 的 On/Off**，把 CH2 关掉（灯灭）。CH1 不要动。然后回车。
   - **「第 4 行开始前」**那次：再按一下 CH2 的 On/Off 打开，然后回车。
   - 其他暂停直接回车。
4. 预期：
   - 每行 ctr1 = 10、A-line 10/10：ATS 照样被 G1 触发，只是第 3 行没有脉冲。
   - 第 3 行打印「1 个沿 0/10」，上升沿中位数 NaN。
   - 最后「每条正好 1 个沿：90/100」。
   - MAP 第 3 行（Y = 20 µm）是一条**横的**暗线，只有几 mV；其他行约 1.04–1.05 V。
5. 跑完第 20 行改回 `false`，把打印和图贴给我。

### 🧑 用户 · 2026-10-15 00:52

<pasted_content id="416e">
cscan_replot
文件：C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_175112.mat
测试信号（函数发生器），激光关；docs/14 5.1 第一次 10x10；14-Oct-2026 17:51:12；10 x 10 像素，完成 10/10 行；DX 10.00 um，DY 10.00 um（Y 已标定：1）；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
isequal(MAP) = 1（重算 vs 文件里存的）
isequal(nEdge) = 1，isequaln(tEdge) = 1
每条正好 1 个沿：100/100；上升沿 1.9261 ~ 1.9325 us，标准差 1.93 ns；MAP 1.0413 ~ 1.0480 V
每行 ctr1：[10 10 10 10 10 10 10 10 10 10]（应为 10）
每行平均：arm 0.047 / 扫描 0.546 / 取数 0.053 / 存 0.058 / 回程+Y 0.557 / 整行 1.262 s
>>
</pasted_content id="416e">

### 🤖 Claude · 2026-10-15 00:52

收到，文字版和截图一致，6.4 通过。每行平均 1.262 s（中位数 1.19 s）也记下了，6.10 估算时会用到。

接着做 **6.5 行顺序**，按上一条的步骤：
1. 第 24 行改 `SAVE_DATA = true`，第 26 行改 `PAUSE_BETWEEN_ROWS = true`。
2. 先跑检查模式，然后第 20 行改 `true` 运行。
3. 「第 3 行开始前」按发生器 **CH2 的 On/Off** 关掉；「第 4 行开始前」再打开。
4. 跑完第 20 行改回 `false`，把打印和图贴给我。

### 🧑 用户 · 2026-10-15 00:53

<pasted_content id="416e">
cscan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 10 个触发、间隔 20 步；X 去程 = 回程 = 1000 步；Y 前进 9 x 20 步后退回；总触发 100；P0.7 全 0：true
K = 20，Ky = 20（Y 未标定时只是假设），fs = 248000，NX = 10，NY = 10，wTrig = 2 行（8.06 us），lead = 25 行
触发 400.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 10 x 10，间距 10.00 x 10.00 um；第一个像素在本行起点 + 200 um；每行 X 走 500 um，Y 共 90 um
ATS：每条 1024 点，每个 buffer 2 条（4096 B），每行 5 个 buffer，一次 Post 5 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.322 s（不含停稳），回程 + Y 表 0.360 s（含 2 次停稳；最后一行 0.350 s），Y 退回表 0.090 s
每行 0.683 s，全程 6.91 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
  对照 docs/14 附 A：每行 0.68 s、全程约 6.9 s 对得上。附 A 把一次停稳算在行扫描里（0.37 + 0.31 s），
  本程序两次停稳都在回程 + Y 表里（0.32 + 0.36 s），所以 docs/14 3.2 的"readwrite >= 0.37 s"应为 >= 0.32 s。
数据：raw uint16 1024 x 10 x 10 = 204800 B（200.0 kB）

== 7. 假数据走一遍数据通路（docs/14 1.4） ==
【在做什么】造一组已知图案的 raw（第 iy 行第 ix 条的脉冲高 = iy + ix/100 个单位），走一遍 快速检查 → 逐行存盘 → MAP → 重读。
【为什么】测试信号下 MAP 本来就是均匀的，行列排错了看不出来；用已知图案才能逐点核对。
数据文件：C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_mock_20261014_205255.mat
假数据没有 ctr1 和计时，下面每行的 ctr1、用时显示 NaN。
第 1/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9389 us，脉冲高 0.303 ~ 0.330 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 2/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9360 us，脉冲高 0.603 ~ 0.630 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 3/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9363 us，脉冲高 0.903 ~ 0.930 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 4/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9351 us，脉冲高 1.203 ~ 1.230 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 5/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9333 us，脉冲高 1.503 ~ 1.530 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 6/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9327 us，脉冲高 1.803 ~ 1.830 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 7/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9340 us，脉冲高 2.103 ~ 2.130 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 8/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9334 us，脉冲高 2.403 ~ 2.430 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 9/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9342 us，脉冲高 2.703 ~ 2.730 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 10/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9333 us，脉冲高 3.003 ~ 3.030 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
完成 10/10 行，A-line 100 条；每条正好 1 个沿：100/100；rail 点数 0
上升沿 1.9290 ~ 1.9414 us，标准差 2.61 ns，峰峰 12.33 ns；MAP 0.3030 ~ 3.0300 V（标准差 866.07 mV）
重读 C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_mock_20261014_205255.mat：isequal(raw) = 1，isequal(MAP) = 1
MAP(3,7) = 3.07（应为 3.07）；MAP(10,1) = 10.01（应为 10.01）
逐点核对：100/100 个像素对得上（误差 < 0.005 个单位）

*** 检查模式：没有向硬件发送任何信号。确认无误后把 RUN_HARDWARE 改成 true ***
>>
</pasted_content id="416e">

### 🤖 Claude · 2026-10-15 00:53

检查模式对上了：10 × 10、全程 6.91 s、假数据存盘重读 isequal = 1。这次跑的还是假数据，所以 MAP 是从暗到亮的渐变，不用管。

**现在上硬件：**
1. 第 20 行改成 `true`，运行 `cscan_test`。
2. 一共停 20 次，大多数直接回车：
   - **「【暂停】第 3 行开始前」**：按发生器上 **CH2 下面的 On/Off**，灯灭。CH1 不动。然后回车。
   - **「【暂停】第 4 行开始前」**：再按 CH2 的 On/Off，灯亮。然后回车。
3. 跑完第 20 行改回 `false`。

真的 MAP 应该大部分约 1.04–1.05 V，**只有 Y = 20 µm 那一行（从下往上第 3 行）是暗的**。

### 🧑 用户 · 2026-10-15 00:57

<pasted_content id="416e">
>> cscan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 10 个触发、间隔 20 步；X 去程 = 回程 = 1000 步；Y 前进 9 x 20 步后退回；总触发 100；P0.7 全 0：true
K = 20，Ky = 20（Y 未标定时只是假设），fs = 248000，NX = 10，NY = 10，wTrig = 2 行（8.06 us），lead = 25 行
触发 400.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 10 x 10，间距 10.00 x 10.00 um；第一个像素在本行起点 + 200 um；每行 X 走 500 um，Y 共 90 um
ATS：每条 1024 点，每个 buffer 2 条（4096 B），每行 5 个 buffer，一次 Post 5 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.322 s（不含停稳），回程 + Y 表 0.360 s（含 2 次停稳；最后一行 0.350 s），Y 退回表 0.090 s
每行 0.683 s，全程 6.91 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
  对照 docs/14 附 A：每行 0.68 s、全程约 6.9 s 对得上。附 A 把一次停稳算在行扫描里（0.37 + 0.31 s），
  本程序两次停稳都在回程 + Y 表里（0.32 + 0.36 s），所以 docs/14 3.2 的"readwrite >= 0.37 s"应为 >= 0.32 s。
数据：raw uint16 1024 x 10 x 10 = 204800 B（200.0 kB）

== 8. 上硬件（docs/14 阶段 3–6） ==
【在做什么】循环外准备一次 Dev1、ctr1、ATS；每行 arm → 行扫描 → 取数 → 存盘 → 看停止按钮 → 回程 + Y。
【为什么】DMA buffer 每行重复使用，这一行在电机再动之前就存好；只在行间停，电机不会停在半路，退回距离按累计命令位置算。
数据文件：C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_205546.mat
DO 时钟：设 248000 S/s，实际 248000.0 S/s（不一样的话，所有时长和扫描速度按比例变）
停止按钮只在行与行之间检查：按下后做完当前这一行再停，然后退回起点。不要用 Ctrl+C（不会自动退回）。
【暂停】第 1 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 1 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 1/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9270 us，脉冲高 1.047 ~ 1.052 V；ctr1 = 10（应为 10）；用时 2.59 s（arm 0.027 / 扫描 0.625 / 取数 0.052 / 存 0.055 / 回程+Y 0.553）
【暂停】第 2 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 2 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 2/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9271 us，脉冲高 1.049 ~ 1.053 V；ctr1 = 10（应为 10）；用时 2.32 s（arm 0.025 / 扫描 0.500 / 取数 0.046 / 存 0.056 / 回程+Y 0.553）
【暂停】第 3 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 3 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 3/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9274 us，脉冲高 1.048 ~ 1.053 V；ctr1 = 10（应为 10）；用时 2.93 s（arm 0.026 / 扫描 0.506 / 取数 0.054 / 存 0.051 / 回程+Y 0.527）
【暂停】第 4 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 4 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 4/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9274 us，脉冲高 1.047 ~ 1.052 V；ctr1 = 10（应为 10）；用时 1.34 s（arm 0.029 / 扫描 0.509 / 取数 0.052 / 存 0.054 / 回程+Y 0.522）
【暂停】第 5 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 5 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 5/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9269 us，脉冲高 1.048 ~ 1.051 V；ctr1 = 10（应为 10）；用时 1.55 s（arm 0.026 / 扫描 0.495 / 取数 0.053 / 存 0.056 / 回程+Y 0.662）
【暂停】第 6 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 6 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 6/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9270 us，脉冲高 1.049 ~ 1.053 V；ctr1 = 10（应为 10）；用时 1.28 s（arm 0.025 / 扫描 0.501 / 取数 0.053 / 存 0.052 / 回程+Y 0.548）
【暂停】第 7 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 7 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）

第 7/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9271 us，脉冲高 1.048 ~ 1.053 V；ctr1 = 10（应为 10）；用时 1.32 s（arm 0.025 / 扫描 0.507 / 取数 0.046 / 存 0.051 / 回程+Y 0.635）
【暂停】第 8 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 8 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 8/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9271 us，脉冲高 1.048 ~ 1.052 V；ctr1 = 10（应为 10）；用时 1.17 s（arm 0.026 / 扫描 0.496 / 取数 0.055 / 存 0.054 / 回程+Y 0.538）
【暂停】第 9 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）

【暂停】第 9 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 9/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9273 us，脉冲高 1.048 ~ 1.052 V；ctr1 = 10（应为 10）；用时 1.16 s（arm 0.025 / 扫描 0.492 / 取数 0.056 / 存 0.060 / 回程+Y 0.525）
【暂停】第 10 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）


【暂停】第 10 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）


第 10/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9274 us，脉冲高 1.048 ~ 1.052 V；ctr1 = 10（应为 10）；用时 1.16 s（arm 0.025 / 扫描 0.481 / 取数 0.052 / 存 0.055 / 回程+Y 0.539）
回到起点：命令位置 X +0.0 um，Y +0.0 um（应为 0 / 0）；ctr1 全程 100（应为 100）

== 9. 结果（docs/14 6.1、6.3、6.4） ==
【在做什么】汇总每条 A-line 的快速检查，算 MAP；存过盘的话把文件读回来逐点比较。
【为什么】条数、ctr1、计划位置三个数对上，才能说第 k 条记录 = 第 k 个位置；重读一致才说明存的东西能用。
完成 10/10 行，A-line 100 条；每条正好 1 个沿：100/100；rail 点数 0
上升沿 1.9236 ~ 1.9314 us，标准差 1.69 ns，峰峰 7.85 ns；MAP 1.0415 ~ 1.0475 V（标准差 1.47 mV）
重读 C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_205546.mat：isequal(raw) = 1，isequal(MAP) = 1
>>
</pasted_content id="416e">

 你说啥是暗的

### 🤖 Claude · 2026-10-15 00:58

**这次没有暗线，因为第 3 行时 CH2 其实还在输出。** 打印里第 3 行是：

```
第 3/10 行：A-line 10/10，1 个沿 10/10，……脉冲高 1.048 ~ 1.053 V
```

如果 CH2 关掉了，这一行应该是「1 个沿 **0/10**」，脉冲高只有几 mV。

**「暗」是什么意思：** MAP 每个格子的颜色 = 那个位置的脉冲高度。CH2 关掉时 CH A 上没有脉冲，只有噪声，MAP 值约 0.003 V。色条会自动拉到 0–1.05 V，那一行就显示成最深的蓝色，其余 90 个格子是黄色，看起来是一条**横的深色带**。

**这次数据没白跑：** 又是一次干净的 10 × 10（100/100、ctr1 100、isequal = 1），可以算 6.9「重复 3 次」里的第 2 次。

**重做 6.5**，参数都不用改，第 20 行改 `true` 再跑一次：
1. 停在「**第 3 行开始前**」时先不要回车，先按发生器 **CH2 那一路的 On/Off**（屏幕右下，「2」下面那个亮蓝的键）。按下后 CH2 的灯应该灭掉，示波器 CH3 的脉冲也会消失。确认灭了再回车。
2. 停在「**第 4 行开始前**」时再按一次，灯亮了再回车。
3. 第 3 行的打印应该是「1 个沿 0/10」。

刚才是不是没按，还是按了灯没灭？

### 🧑 用户 · 2026-10-15 00:58

还没按呢 你让我按啥

### 🤖 Claude · 2026-10-15 00:58

要按的是**发生器 DG852 右下角、中间那个蓝色发光的「On/Off」键**，它控制 CH2 输出。

对照你下午拍的发生器照片，右下角有两排键：
```
上排：   [ 1 ]      [ 2 ]      [Counter]
下排：  [On/Off]   [On/Off]   [On/Off]
         橙色亮     蓝色亮       不亮
         CH1        CH2 ← 按这个
```

- **橙色**的是 CH1（G1 → TRIG IN），**不要按**。按了 ATS 就收不到触发，会报超时。
- **蓝色**的是 CH2（G2 → CH A 的测试脉冲），**按这个**。

按一下灯就灭，CH2 停止输出；再按一下灯亮，恢复输出。

步骤：
1. 第 20 行改 `true`，运行 `cscan_test`。
2. 停在「第 3 行开始前」：按**蓝色 On/Off**，看灯灭了，再回车。
3. 停在「第 4 行开始前」：再按**蓝色 On/Off**，看灯亮了，再回车。
4. 其他暂停直接回车。跑完第 20 行改回 `false`。

### 🧑 用户 · 2026-10-15 00:59

<pasted_content id="416e">
cscan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 10 个触发、间隔 20 步；X 去程 = 回程 = 1000 步；Y 前进 9 x 20 步后退回；总触发 100；P0.7 全 0：true
K = 20，Ky = 20（Y 未标定时只是假设），fs = 248000，NX = 10，NY = 10，wTrig = 2 行（8.06 us），lead = 25 行
触发 400.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 10 x 10，间距 10.00 x 10.00 um；第一个像素在本行起点 + 200 um；每行 X 走 500 um，Y 共 90 um
ATS：每条 1024 点，每个 buffer 2 条（4096 B），每行 5 个 buffer，一次 Post 5 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.322 s（不含停稳），回程 + Y 表 0.360 s（含 2 次停稳；最后一行 0.350 s），Y 退回表 0.090 s
每行 0.683 s，全程 6.91 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
  对照 docs/14 附 A：每行 0.68 s、全程约 6.9 s 对得上。附 A 把一次停稳算在行扫描里（0.37 + 0.31 s），
  本程序两次停稳都在回程 + Y 表里（0.32 + 0.36 s），所以 docs/14 3.2 的"readwrite >= 0.37 s"应为 >= 0.32 s。
数据：raw uint16 1024 x 10 x 10 = 204800 B（200.0 kB）

== 8. 上硬件（docs/14 阶段 3–6） ==
【在做什么】循环外准备一次 Dev1、ctr1、ATS；每行 arm → 行扫描 → 取数 → 存盘 → 看停止按钮 → 回程 + Y。
【为什么】DMA buffer 每行重复使用，这一行在电机再动之前就存好；只在行间停，电机不会停在半路，退回距离按累计命令位置算。
数据文件：C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_205841.mat
DO 时钟：设 248000 S/s，实际 248000.0 S/s（不一样的话，所有时长和扫描速度按比例变）
停止按钮只在行与行之间检查：按下后做完当前这一行再停，然后退回起点。不要用 Ctrl+C（不会自动退回）。
【暂停】第 1 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 1 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 1/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9290 us，脉冲高 1.048 ~ 1.053 V；ctr1 = 10（应为 10）；用时 3.73 s（arm 0.026 / 扫描 0.584 / 取数 0.054 / 存 0.050 / 回程+Y 0.546）
【暂停】第 2 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 2 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 2/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9293 us，脉冲高 1.048 ~ 1.053 V；ctr1 = 10（应为 10）；用时 3.93 s（arm 0.027 / 扫描 0.510 / 取数 0.052 / 存 0.050 / 回程+Y 0.527）
【暂停】第 3 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 3 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 3/10 行：A-line 10/10，1 个沿 0/10，上升沿中位数 NaN us，脉冲高 0.001 ~ 0.004 V；ctr1 = 10（应为 10）；用时 3.71 s（arm 0.026 / 扫描 0.507 / 取数 0.049 / 存 0.052 / 回程+Y 0.526）
【暂停】第 4 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 4 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 4/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9276 us，脉冲高 1.048 ~ 1.052 V；ctr1 = 10（应为 10）；用时 2.13 s（arm 0.026 / 扫描 0.502 / 取数 0.048 / 存 0.056 / 回程+Y 0.532）
【暂停】第 5 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 5 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 5/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9276 us，脉冲高 1.046 ~ 1.052 V；ctr1 = 10（应为 10）；用时 2.11 s（arm 0.026 / 扫描 0.508 / 取数 0.052 / 存 0.053 / 回程+Y 0.537）
【暂停】第 6 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 6 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 6/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9292 us，脉冲高 1.048 ~ 1.053 V；ctr1 = 10（应为 10）；用时 1.62 s（arm 0.025 / 扫描 0.509 / 取数 0.054 / 存 0.054 / 回程+Y 0.523）
【暂停】第 7 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 7 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 7/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9284 us，脉冲高 1.049 ~ 1.053 V；ctr1 = 10（应为 10）；用时 1.25 s（arm 0.026 / 扫描 0.489 / 取数 0.039 / 存 0.052 / 回程+Y 0.549）
【暂停】第 8 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 8 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 8/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9280 us，脉冲高 1.047 ~ 1.054 V；ctr1 = 10（应为 10）；用时 1.27 s（arm 0.025 / 扫描 0.494 / 取数 0.050 / 存 0.052 / 回程+Y 0.541）
【暂停】第 9 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 9 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 9/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9297 us，脉冲高 1.049 ~ 1.052 V；ctr1 = 10（应为 10）；用时 1.31 s（arm 0.026 / 扫描 0.512 / 取数 0.047 / 存 0.057 / 回程+Y 0.531）
【暂停】第 10 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 10 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 10/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9277 us，脉冲高 1.049 ~ 1.054 V；ctr1 = 10（应为 10）；用时 1.24 s（arm 0.027 / 扫描 0.502 / 取数 0.053 / 存 0.054 / 回程+Y 0.520）

回到起点：命令位置 X +0.0 um，Y +0.0 um（应为 0 / 0）；ctr1 全程 100（应为 100）

== 9. 结果（docs/14 6.1、6.3、6.4） ==
【在做什么】汇总每条 A-line 的快速检查，算 MAP；存过盘的话把文件读回来逐点比较。
【为什么】条数、ctr1、计划位置三个数对上，才能说第 k 条记录 = 第 k 个位置；重读一致才说明存的东西能用。
完成 10/10 行，A-line 100 条；每条正好 1 个沿：90/100；rail 点数 0
上升沿 1.9261 ~ 1.9326 us，标准差 2.04 ns，峰峰 6.52 ns；MAP 0.0028 ~ 1.0446 V（标准差 312.83 mV）
重读 C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_205841.mat：isequal(raw) = 1，isequal(MAP) = 1
>>
</pasted_content id="416e">

### 🤖 Claude · 2026-10-15 01:00

**6.5 通过，这正是要的结果。**

- 第 3 行打印「1 个沿 **0/10**」，脉冲高 0.001–0.004 V（只有噪声），ctr1 仍是 10：触发和采集都正常，只是 CH A 上没有脉冲。
- 其余 9 行都是 10/10，约 1.05 V；全程 90/100、ctr1 100、重读 isequal = 1。
- MAP 上 **Y = 20 µm 那一条是横的深色带**，正好在从下往上第 3 行，不是一列，也不在第 2 行或第 4 行。
- 右边上升沿图同一行也是空的（NaN），位置一致。

这证明了「**第 k 行数据 = 第 k 行位置**」：行没有错位，X、Y 没有转置。这是 MAP 均匀时证明不了的事。

**第 3 步：6.6 正式的行间停止**
1. 第 26 行改回 `PAUSE_BETWEEN_ROWS = false`，第 24 行 `SAVE_DATA = true` 保持。发生器 CH2 确认是亮的。
2. 第 20 行改 `true`，运行。会弹出一个小窗口，**标题**会显示「C-scan 第 1/10 行」「第 2/10 行」……
3. 标题变成「**第 4/10 行**」时，用鼠标点「停止（做完当前这一行）」。每行约 1.2 s，要盯紧。
4. 预期：
   - 打印「**收到停止：完成 40/100 条 A-line（4/10 行）**」；如果点晚了是 50/100，也算通过。
   - 「回到起点 X +0.0，Y +0.0」，ctr1 全程 40（或 50）。
   - 两条胶带回到记号。
5. 跑完第 20 行改回 `false`，把打印贴给我。

### 🧑 用户 · 2026-10-15 01:01

那现在发生器都开么

### 🤖 Claude · 2026-10-15 01:01

对，**两路都要开**：
- **CH1（橙色 On/Off）**：亮着。它负责给 ATS 触发，6.5 全程都没动过。
- **CH2（蓝色 On/Off）**：亮着。6.5 第 4 行开始前你又按开了，后面 7 行都有脉冲（10/10），说明它现在是开的。

看一眼两个 On/Off 灯都亮，就可以做 6.6。

### 🧑 用户 · 2026-10-15 01:01

代码看一下

### 🤖 Claude · 2026-10-15 01:01

> 🔧 Bash · description: Check current switches for 6.6

### ⚙️ 工具 · 2026-10-15 01:01

<details><summary>工具输出</summary>

```
RUN_HARDWARE       = false; % false：只算�
LASER_ENABLE       = false;  % false：P0.7 �
ATS_ENABLE         = true;   % false：只动
COUNT_CHECK        = true;   % true：用 ctr
SAVE_DATA          = true;  % true：每行�
MOCK_DATA          = true;   % 只在 RUN_HAR
PAUSE_BETWEEN_ROWS = false;  % true：每行�
Y_CALIBRATED       = true;  % Y 的 um/脉冲
NX                  = 10;      % 每行 
NY                  = 10;      % 行数 
DX_UM               = 10;      % X 像�
DY_UM               = 10;      % Y 像�
```
</details>

### 🤖 Claude · 2026-10-15 01:01

6.6 要的设置都对了：

| 行 | 现在 | 6.6 要求 |
|---|---|---|
| 20 | `RUN_HARDWARE = false` | 运行前改成 `true` |
| 22 | `ATS_ENABLE = true` | ✔ |
| 23 | `COUNT_CHECK = true` | ✔ |
| 24 | `SAVE_DATA = true` | ✔ 停止后能看到文件里 rowsDone = 4 |
| 26 | `PAUSE_BETWEEN_ROWS = false` | ✔ 不停，一次跑完 |
| 27 | `Y_CALIBRATED = true` | ✔ |
| 30–33 | NX 10、NY 10、DX 10、DY 10 | ✔ |

把第 20 行改成 `true`，存盘，运行。小窗口标题变成「第 4/10 行」时点停止，跑完改回 `false`。

### 🧑 用户 · 2026-10-15 01:02

<pasted_content id="416e">
cscan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 10 个触发、间隔 20 步；X 去程 = 回程 = 1000 步；Y 前进 9 x 20 步后退回；总触发 100；P0.7 全 0：true
K = 20，Ky = 20（Y 未标定时只是假设），fs = 248000，NX = 10，NY = 10，wTrig = 2 行（8.06 us），lead = 25 行
触发 400.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 10 x 10，间距 10.00 x 10.00 um；第一个像素在本行起点 + 200 um；每行 X 走 500 um，Y 共 90 um
ATS：每条 1024 点，每个 buffer 2 条（4096 B），每行 5 个 buffer，一次 Post 5 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.322 s（不含停稳），回程 + Y 表 0.360 s（含 2 次停稳；最后一行 0.350 s），Y 退回表 0.090 s
每行 0.683 s，全程 6.91 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
  对照 docs/14 附 A：每行 0.68 s、全程约 6.9 s 对得上。附 A 把一次停稳算在行扫描里（0.37 + 0.31 s），
  本程序两次停稳都在回程 + Y 表里（0.32 + 0.36 s），所以 docs/14 3.2 的"readwrite >= 0.37 s"应为 >= 0.32 s。
数据：raw uint16 1024 x 10 x 10 = 204800 B（200.0 kB）

== 8. 上硬件（docs/14 阶段 3–6） ==
【在做什么】循环外准备一次 Dev1、ctr1、ATS；每行 arm → 行扫描 → 取数 → 存盘 → 看停止按钮 → 回程 + Y。
【为什么】DMA buffer 每行重复使用，这一行在电机再动之前就存好；只在行间停，电机不会停在半路，退回距离按累计命令位置算。
数据文件：C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_210218.mat
DO 时钟：设 248000 S/s，实际 248000.0 S/s（不一样的话，所有时长和扫描速度按比例变）
停止按钮只在行与行之间检查：按下后做完当前这一行再停，然后退回起点。不要用 Ctrl+C（不会自动退回）。
第 1/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9286 us，脉冲高 1.049 ~ 1.053 V；ctr1 = 10（应为 10）；用时 1.22 s（arm 0.047 / 扫描 0.552 / 取数 0.044 / 存 0.054 / 回程+Y 0.524）
第 2/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9276 us，脉冲高 1.047 ~ 1.053 V；ctr1 = 10（应为 10）；用时 1.19 s（arm 0.042 / 扫描 0.501 / 取数 0.052 / 存 0.053 / 回程+Y 0.542）
第 3/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9277 us，脉冲高 1.049 ~ 1.054 V；ctr1 = 10（应为 10）；用时 1.17 s（arm 0.036 / 扫描 0.501 / 取数 0.048 / 存 0.052 / 回程+Y 0.527）
第 4/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9277 us，脉冲高 1.048 ~ 1.052 V；ctr1 = 10（应为 10）；用时 1.17 s（arm 0.037 / 扫描 0.501 / 取数 0.051 / 存 0.052 / 回程+Y 0.528）
第 5/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9276 us，脉冲高 1.049 ~ 1.052 V；ctr1 = 10（应为 10）；用时 1.20 s（arm 0.056 / 扫描 0.496 / 取数 0.049 / 存 0.055 / 回程+Y 0.543）
第 6/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9300 us，脉冲高 1.049 ~ 1.053 V；ctr1 = 10（应为 10）；用时 1.17 s（arm 0.041 / 扫描 0.500 / 取数 0.049 / 存 0.062 / 回程+Y 0.523）
第 7/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9279 us，脉冲高 1.048 ~ 1.054 V；ctr1 = 10（应为 10）；用时 1.18 s（arm 0.041 / 扫描 0.502 / 取数 0.052 / 存 0.053 / 回程+Y 0.529）
第 8/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9286 us，脉冲高 1.047 ~ 1.053 V；ctr1 = 10（应为 10）；用时 1.20 s（arm 0.049 / 扫描 0.511 / 取数 0.051 / 存 0.052 / 回程+Y 0.531）
第 9/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9274 us，脉冲高 1.049 ~ 1.053 V；ctr1 = 10（应为 10）；用时 1.20 s（arm 0.048 / 扫描 0.502 / 取数 0.052 / 存 0.054 / 回程+Y 0.541）
第 10/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9273 us，脉冲高 1.049 ~ 1.053 V；ctr1 = 10（应为 10）；用时 1.20 s（arm 0.052 / 扫描 0.512 / 取数 0.048 / 存 0.059 / 回程+Y 0.529）
回到起点：命令位置 X +0.0 um，Y +0.0 um（应为 0 / 0）；ctr1 全程 100（应为 100）

== 9. 结果（docs/14 6.1、6.3、6.4） ==
【在做什么】汇总每条 A-line 的快速检查，算 MAP；存过盘的话把文件读回来逐点比较。
【为什么】条数、ctr1、计划位置三个数对上，才能说第 k 条记录 = 第 k 个位置；重读一致才说明存的东西能用。
完成 10/10 行，A-line 100 条；每条正好 1 个沿：100/100；rail 点数 0
上升沿 1.9245 ~ 1.9326 us，标准差 2.02 ns，峰峰 8.15 ns；MAP 1.0407 ~ 1.0468 V（标准差 1.54 mV）
重读 C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_210218.mat：isequal(raw) = 1，isequal(MAP) = 1
>>
</pasted_content id="416e">

### 🤖 Claude · 2026-10-15 01:03

**这次没有停下来，10 行全部跑完了。** 打印里没有「收到停止」，全程 ctr1 100。

先问一下：你点停止按钮了吗？点了的话，按钮上的字有没有变成「收到：这一行做完就停」、变灰？
- **没来得及点**：正常，每行只有 1.2 s，10 行 12 秒就跑完了。
- **点了但字没变**：说明 readwrite 运行期间点击没有被接收，这是要查的问题。告诉我当时的情况。

**这次也没白跑：** 又是一次干净的 10 × 10（100/100、ctr1 100、MAP 1.041–1.047 V、isequal = 1）。加上 5.1 和 6.5 第一次，**6.9「附 A 原样跑 3 次」已经够了**。三次的上升沿区间：

| 次 | 上升沿 |
|---|---|
| 5.1（17:51） | 1.9261–1.9325 µs |
| 20:55 | 1.9236–1.9314 µs |
| 21:02 | 1.9245–1.9326 µs |

最大值三次只差 1 ns，最小值差 2.5 ns，都在约 1 个采样点（5.6 ns）以内，算一致。

**重做 6.6，换个更容易的点法：** 参数不用动，第 20 行还是 `true`。
1. 运行后，小窗口一出来就**马上点停止**，不用等第 4 行。
2. 预期：打印「收到停止：完成 10/100（1/10 行）」，或者 20/100，取决于你点得多快；然后「回到起点 0 / 0」，ctr1 全程等于完成的条数。
3. 这一步要验证的是「按停止 → 做完当前行 → 退回 → 已完成的行都存了」，停在第几行不重要。

跑完第 20 行改回 `false`，把打印贴给我。

### 🤖 Claude · 2026-10-15 01:03

> 🔧 Bash · description: Check newest data file for stop result

### ⚙️ 工具 · 2026-10-15 01:03

<details><summary>工具输出</summary>

```
cscan_20261014_210218.mat
cscan_20261014_205841.mat
cscan_20261014_205546.mat
cscan_20261014_205446.mat
C:/Users/2031/Desktop/Research-PAM/07_MATLAB/cscan_data/cscan_20261014_210218.mat: rowsDone 10, stop , err , ctr total 100, trig [10 10 10 10 10 10 10 10 10 10]
```
</details>

### 🤖 Claude · 2026-10-15 01:03

这张图是**上一次（21:02）的结果**，不是新跑的。我看了 `cscan_data` 文件夹，21:02 之后没有新的数据文件，最新的 `cscan_20261014_210218.mat` 是 10 行全部做完、没有停止记录。所以重做的 6.6 还没跑。

现在：
1. 确认第 20 行是 `true`，运行 `cscan_test`。
2. 小窗口「C-scan」一出来就用鼠标**点停止**，看按钮的字有没有变成「收到：这一行做完就停」。
3. 把**命令行窗口的文字**贴给我，最后几行最要紧：「收到停止：完成 …/100」和「回到起点」。

另外回答我一下：上一次（21:02）你有没有点停止按钮？点了的话，按钮的字变了没有？这关系到停止按钮在 readwrite 运行时能不能收到点击。

### 🧑 用户 · 2026-10-15 01:06

<pasted_content id="416e">
clear
>> cscan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 10 个触发、间隔 20 步；X 去程 = 回程 = 1000 步；Y 前进 9 x 20 步后退回；总触发 100；P0.7 全 0：true
K = 20，Ky = 20（Y 未标定时只是假设），fs = 248000，NX = 10，NY = 10，wTrig = 2 行（8.06 us），lead = 25 行
触发 400.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 10 x 10，间距 10.00 x 10.00 um；第一个像素在本行起点 + 200 um；每行 X 走 500 um，Y 共 90 um
ATS：每条 1024 点，每个 buffer 2 条（4096 B），每行 5 个 buffer，一次 Post 5 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.322 s（不含停稳），回程 + Y 表 0.360 s（含 2 次停稳；最后一行 0.350 s），Y 退回表 0.090 s
每行 0.683 s，全程 6.91 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
  对照 docs/14 附 A：每行 0.68 s、全程约 6.9 s 对得上。附 A 把一次停稳算在行扫描里（0.37 + 0.31 s），
  本程序两次停稳都在回程 + Y 表里（0.32 + 0.36 s），所以 docs/14 3.2 的"readwrite >= 0.37 s"应为 >= 0.32 s。
数据：raw uint16 1024 x 10 x 10 = 204800 B（200.0 kB）

== 8. 上硬件（docs/14 阶段 3–6） ==
【在做什么】循环外准备一次 Dev1、ctr1、ATS；每行 arm → 行扫描 → 取数 → 存盘 → 看停止按钮 → 回程 + Y。
【为什么】DMA buffer 每行重复使用，这一行在电机再动之前就存好；只在行间停，电机不会停在半路，退回距离按累计命令位置算。
数据文件：C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_210538.mat
DO 时钟：设 248000 S/s，实际 248000.0 S/s（不一样的话，所有时长和扫描速度按比例变）
停止按钮只在行与行之间检查：按下后做完当前这一行再停，然后退回起点。不要用 Ctrl+C（不会自动退回）。
第 1/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9275 us，脉冲高 1.048 ~ 1.052 V；ctr1 = 10（应为 10）；用时 1.25 s（arm 0.039 / 扫描 0.566 / 取数 0.050 / 存 0.055 / 回程+Y 0.544）
第 2/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9273 us，脉冲高 1.049 ~ 1.052 V；ctr1 = 10（应为 10）；用时 1.17 s（arm 0.038 / 扫描 0.497 / 取数 0.053 / 存 0.050 / 回程+Y 0.529）
第 3/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9275 us，脉冲高 1.047 ~ 1.053 V；ctr1 = 10（应为 10）；用时 1.18 s（arm 0.053 / 扫描 0.505 / 取数 0.044 / 存 0.050 / 回程+Y 0.528）
第 4/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9275 us，脉冲高 1.047 ~ 1.053 V；ctr1 = 10（应为 10）；用时 1.18 s（arm 0.042 / 扫描 0.503 / 取数 0.048 / 存 0.052 / 回程+Y 0.536）
第 5/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9273 us，脉冲高 1.049 ~ 1.052 V；ctr1 = 10（应为 10）；用时 1.17 s（arm 0.037 / 扫描 0.496 / 取数 0.054 / 存 0.052 / 回程+Y 0.534）
第 6/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9271 us，脉冲高 1.049 ~ 1.053 V；ctr1 = 10（应为 10）；用时 1.20 s（arm 0.045 / 扫描 0.499 / 取数 0.053 / 存 0.053 / 回程+Y 0.547）
第 7/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9272 us，脉冲高 1.046 ~ 1.055 V；ctr1 = 10（应为 10）；用时 1.20 s（arm 0.045 / 扫描 0.498 / 取数 0.048 / 存 0.054 / 回程+Y 0.552）
第 8/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9276 us，脉冲高 1.048 ~ 1.052 V；ctr1 = 10（应为 10）；用时 1.29 s（arm 0.049 / 扫描 0.502 / 取数 0.039 / 存 0.060 / 回程+Y 0.641）
第 9/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9272 us，脉冲高 1.047 ~ 1.052 V；ctr1 = 10（应为 10）；用时 1.20 s（arm 0.045 / 扫描 0.512 / 取数 0.053 / 存 0.053 / 回程+Y 0.537）
第 10/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9270 us，脉冲高 1.047 ~ 1.053 V；ctr1 = 10（应为 10）；用时 1.18 s（arm 0.048 / 扫描 0.500 / 取数 0.053 / 存 0.054 / 回程+Y 0.521）
回到起点：命令位置 X +0.0 um，Y +0.0 um（应为 0 / 0）；ctr1 全程 100（应为 100）

== 9. 结果（docs/14 6.1、6.3、6.4） ==
【在做什么】汇总每条 A-line 的快速检查，算 MAP；存过盘的话把文件读回来逐点比较。
【为什么】条数、ctr1、计划位置三个数对上，才能说第 k 条记录 = 第 k 个位置；重读一致才说明存的东西能用。
完成 10/10 行，A-line 100 条；每条正好 1 个沿：100/100；rail 点数 0
上升沿 1.9235 ~ 1.9315 us，标准差 1.78 ns，峰峰 8.07 ns；MAP 1.0393 ~ 1.0477 V（标准差 1.58 mV）
重读 C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_210538.mat：isequal(raw) = 1，isequal(MAP) = 1
>>
</pasted_content id="416e">

 这样么 还是我一出来就要点停止

### 🤖 Claude · 2026-10-15 01:06

对，**要你用鼠标点那个小窗口里的「停止」按钮**，程序不会自己停。这次没点，所以 10 行都跑完了。这次也是一次干净的 100/100，记下就好。

那个小窗口叫「**C-scan**」，只有 320 × 120 像素，出现在**屏幕左下角**，很容易被 MATLAB 主窗口或图挡住。可能你没看到它。

**换一个不用抢时间的做法：借暂停来点。**
1. 第 26 行改成 `PAUSE_BETWEEN_ROWS = true`，第 20 行保持 `true`，运行。
2. 前几次暂停直接回车。
3. 停在「**【暂停】第 4 行开始前**」时：
   - 找到左下角的「C-scan」小窗口（找不到就看任务栏），**用鼠标点「停止（做完当前这一行）」**，看按钮的字变成「收到：这一行做完就停」、变灰；
   - 再点一下命令行窗口，按回车。
4. 第 4 行会扫完，在「第 4 行扫完」那次暂停再回车。然后它会停下、退回。
5. 预期打印：「**收到停止：完成 40/100 条 A-line（4/10 行）**」，「回到起点 X +0.0，Y +0.0」，ctr1 全程 40。

跑完第 20 行改回 `false`、第 26 行改回 `false`，把打印贴给我。

### 🧑 用户 · 2026-10-15 01:06

第二行

### 🤖 Claude · 2026-10-15 01:06

> 🔧 Bash · description: Read stop result from newest data file

### ⚙️ 工具 · 2026-10-15 01:07

<details><summary>工具输出</summary>

```
C:/Users/2031/Desktop/Research-PAM/07_MATLAB/cscan_data/cscan_20261014_210638.mat: rowsDone 2, stop , err , ctr total 20, trig [10 10 NaN NaN NaN NaN NaN NaN NaN NaN], isfield MAP 1
RUN_HARDWARE       = true; % false：只
PAUSE_BETWEEN_ROWS = false;  % true：�
```
</details>

### 🤖 Claude · 2026-10-15 01:07

> 🔧 Bash · description: Confirm stopReason recorded in data file

### ⚙️ 工具 · 2026-10-15 01:07

<details><summary>工具输出</summary>

```
ERROR: MATLAB error Exit Status: 0x00000001
```
</details>

### 🤖 Claude · 2026-10-15 01:07

> 🔧 Bash · description: Print stopReason length and char codes

### ⚙️ 工具 · 2026-10-15 01:07

<details><summary>工具输出</summary>

```
stopReason len 4, codes [20572 27490 25353 38062]; errLen 0
```
</details>

### 🤖 Claude · 2026-10-15 01:07

**6.6 通过。** 第一次停在第 2 行之后，第二次停在第 4 行之后，两次结果都对：

| | 第 2 行停（21:06） | 第 4 行停（21:07） |
|---|---|---|
| 完成 | 2/10 行，20/20 | **4/10 行，40/40** |
| ctr1 全程 | 20 | 40 |
| 文件 | rowsDone = 2，`stopReason = "停止按钮"`，没有错误 | 存盘重读 isequal = 1 |
| MAP | 10 × 2 | 10 × 4，约 1.04–1.05 V |

停止的流程完整走了一遍：做完当前行 → 只回程、Y 不再前进 → 按累计命令位置退回 → 已完成的行都在文件里。我读了文件确认 `stopReason` 记的是「停止按钮」。两条胶带回到记号了吧？

**第 4 步：6.7 拔触发线**

为什么做这个：确认缺触发时程序会报错、报出第几行、保存已采的行、退回起点，而不是卡住或者存一堆假数据。

1. 第 26 行改成 `PAUSE_BETWEEN_ROWS = true`，第 20 行保持 `true`、第 24 行 SAVE 保持 `true`，运行。
2. 第 1–3 行的暂停直接回车。
3. 停在「**【暂停】第 4 行开始前**」时：把 **ATS 卡 TRIG IN 上的 BNC 三通拔下来**（整个三通带两根线一起拔），然后回车。
4. 预期：
   - 第 4 行照样扫（电机会动），然后约 **2 s** 后出现红字：`*** 第 4 行（取数）出错：第 4 行 buffer 1/5 未完成……`
   - `ctr1：……第 4 行 10 个`：发送端是正常的，ATS 收不到是因为线断了。
   - `出错时没有 readwrite 在跑，命令位置已知……自动退回起点...`，`已在起点`。
   - 文件里前 3 行已经存好。
5. **把三通插回 TRIG IN**，第 26 行改回 `false`，再正常跑一次 10 × 10，要 100/100。同时看上升沿有没有比之前的 1.927 µs 左右**跳了约 10 ns**。
6. 都跑完，第 20 行改回 `false`，两次的打印都贴给我。

### 🧑 用户 · 2026-10-15 01:07

<pasted_content id="416e">
scan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 10 个触发、间隔 20 步；X 去程 = 回程 = 1000 步；Y 前进 9 x 20 步后退回；总触发 100；P0.7 全 0：true
K = 20，Ky = 20（Y 未标定时只是假设），fs = 248000，NX = 10，NY = 10，wTrig = 2 行（8.06 us），lead = 25 行
触发 400.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 10 x 10，间距 10.00 x 10.00 um；第一个像素在本行起点 + 200 um；每行 X 走 500 um，Y 共 90 um
ATS：每条 1024 点，每个 buffer 2 条（4096 B），每行 5 个 buffer，一次 Post 5 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.322 s（不含停稳），回程 + Y 表 0.360 s（含 2 次停稳；最后一行 0.350 s），Y 退回表 0.090 s
每行 0.683 s，全程 6.91 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
  对照 docs/14 附 A：每行 0.68 s、全程约 6.9 s 对得上。附 A 把一次停稳算在行扫描里（0.37 + 0.31 s），
  本程序两次停稳都在回程 + Y 表里（0.32 + 0.36 s），所以 docs/14 3.2 的"readwrite >= 0.37 s"应为 >= 0.32 s。
数据：raw uint16 1024 x 10 x 10 = 204800 B（200.0 kB）

== 8. 上硬件（docs/14 阶段 3–6） ==
【在做什么】循环外准备一次 Dev1、ctr1、ATS；每行 arm → 行扫描 → 取数 → 存盘 → 看停止按钮 → 回程 + Y。
【为什么】DMA buffer 每行重复使用，这一行在电机再动之前就存好；只在行间停，电机不会停在半路，退回距离按累计命令位置算。
数据文件：C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_210638.mat
DO 时钟：设 248000 S/s，实际 248000.0 S/s（不一样的话，所有时长和扫描速度按比例变）
停止按钮只在行与行之间检查：按下后做完当前这一行再停，然后退回起点。不要用 Ctrl+C（不会自动退回）。
第 1/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9277 us，脉冲高 1.048 ~ 1.053 V；ctr1 = 10（应为 10）；用时 1.22 s（arm 0.050 / 扫描 0.552 / 取数 0.045 / 存 0.055 / 回程+Y 0.523）
第 2/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9272 us，脉冲高 1.047 ~ 1.051 V；ctr1 = 10（应为 10）；用时 1.15 s（arm 0.041 / 扫描 0.503 / 取数 0.046 / 存 0.049 / 回程+Y 0.505）
收到停止：完成 20/100 条 A-line（2/10 行），不再扫下一行。
回到起点：命令位置 X +0.0 um，Y +0.0 um（应为 0 / 0）；ctr1 全程 20（应为 20）

== 9. 结果（docs/14 6.1、6.3、6.4） ==
【在做什么】汇总每条 A-line 的快速检查，算 MAP；存过盘的话把文件读回来逐点比较。
【为什么】条数、ctr1、计划位置三个数对上，才能说第 k 条记录 = 第 k 个位置；重读一致才说明存的东西能用。
完成 2/10 行，A-line 20 条；每条正好 1 个沿：20/20；rail 点数 0
上升沿 1.9238 ~ 1.9313 us，标准差 2.05 ns，峰峰 7.46 ns；MAP 1.0410 ~ 1.0464 V（标准差 1.63 mV）
重读 C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_210638.mat：isequal(raw) = 1，isequal(MAP) = 1
>> cscan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 10 个触发、间隔 20 步；X 去程 = 回程 = 1000 步；Y 前进 9 x 20 步后退回；总触发 100；P0.7 全 0：true
K = 20，Ky = 20（Y 未标定时只是假设），fs = 248000，NX = 10，NY = 10，wTrig = 2 行（8.06 us），lead = 25 行
触发 400.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 10 x 10，间距 10.00 x 10.00 um；第一个像素在本行起点 + 200 um；每行 X 走 500 um，Y 共 90 um
ATS：每条 1024 点，每个 buffer 2 条（4096 B），每行 5 个 buffer，一次 Post 5 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.322 s（不含停稳），回程 + Y 表 0.360 s（含 2 次停稳；最后一行 0.350 s），Y 退回表 0.090 s
每行 0.683 s，全程 6.91 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
  对照 docs/14 附 A：每行 0.68 s、全程约 6.9 s 对得上。附 A 把一次停稳算在行扫描里（0.37 + 0.31 s），
  本程序两次停稳都在回程 + Y 表里（0.32 + 0.36 s），所以 docs/14 3.2 的"readwrite >= 0.37 s"应为 >= 0.32 s。
数据：raw uint16 1024 x 10 x 10 = 204800 B（200.0 kB）

== 8. 上硬件（docs/14 阶段 3–6） ==
【在做什么】循环外准备一次 Dev1、ctr1、ATS；每行 arm → 行扫描 → 取数 → 存盘 → 看停止按钮 → 回程 + Y。
【为什么】DMA buffer 每行重复使用，这一行在电机再动之前就存好；只在行间停，电机不会停在半路，退回距离按累计命令位置算。
数据文件：C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_210705.mat
DO 时钟：设 248000 S/s，实际 248000.0 S/s（不一样的话，所有时长和扫描速度按比例变）
停止按钮只在行与行之间检查：按下后做完当前这一行再停，然后退回起点。不要用 Ctrl+C（不会自动退回）。
第 1/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9272 us，脉冲高 1.047 ~ 1.052 V；ctr1 = 10（应为 10）；用时 1.25 s（arm 0.037 / 扫描 0.573 / 取数 0.052 / 存 0.058 / 回程+Y 0.525）
第 2/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9275 us，脉冲高 1.046 ~ 1.052 V；ctr1 = 10（应为 10）；用时 1.27 s（arm 0.038 / 扫描 0.499 / 取数 0.050 / 存 0.057 / 回程+Y 0.626）
第 3/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9276 us，脉冲高 1.046 ~ 1.052 V；ctr1 = 10（应为 10）；用时 1.17 s（arm 0.041 / 扫描 0.497 / 取数 0.048 / 存 0.058 / 回程+Y 0.527）
第 4/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9273 us，脉冲高 1.048 ~ 1.054 V；ctr1 = 10（应为 10）；用时 1.13 s（arm 0.037 / 扫描 0.488 / 取数 0.024 / 存 0.056 / 回程+Y 0.529）
收到停止：完成 40/100 条 A-line（4/10 行），不再扫下一行。
回到起点：命令位置 X +0.0 um，Y +0.0 um（应为 0 / 0）；ctr1 全程 40（应为 40）

== 9. 结果（docs/14 6.1、6.3、6.4） ==
【在做什么】汇总每条 A-line 的快速检查，算 MAP；存过盘的话把文件读回来逐点比较。
【为什么】条数、ctr1、计划位置三个数对上，才能说第 k 条记录 = 第 k 个位置；重读一致才说明存的东西能用。
完成 4/10 行，A-line 40 条；每条正好 1 个沿：40/40；rail 点数 0
上升沿 1.9238 ~ 1.9312 us，标准差 1.49 ns，峰峰 7.33 ns；MAP 1.0403 ~ 1.0471 V（标准差 1.79 mV）
重读 C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_210705.mat：isequal(raw) = 1，isequal(MAP) = 1
>>
</pasted_content id="416e">

### 🤖 Claude · 2026-10-15 01:07

文字版也对上了，两次都清楚打印了：
- 「收到停止：完成 20/100 条 A-line（2/10 行）」，回到 0 / 0，ctr1 全程 20；
- 「收到停止：完成 40/100 条 A-line（4/10 行）」，回到 0 / 0，ctr1 全程 40。

**6.6 正式通过**，胶带回记号的话就记成 ✔。

接着做 **6.7 拔触发线**，步骤在上一条：第 26 行改 `true`，停在「第 4 行开始前」时拔下 TRIG IN 上的三通再回车。等红字报错、自动退回后，插回三通，第 26 行改回 `false`，再正常跑一次 10 × 10。两次的打印都贴给我。

### 🧑 用户 · 2026-10-15 01:10

<pasted_content id="416e">
>> clear
>> cscan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 10 个触发、间隔 20 步；X 去程 = 回程 = 1000 步；Y 前进 9 x 20 步后退回；总触发 100；P0.7 全 0：true
K = 20，Ky = 20（Y 未标定时只是假设），fs = 248000，NX = 10，NY = 10，wTrig = 2 行（8.06 us），lead = 25 行
触发 400.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 10 x 10，间距 10.00 x 10.00 um；第一个像素在本行起点 + 200 um；每行 X 走 500 um，Y 共 90 um
ATS：每条 1024 点，每个 buffer 2 条（4096 B），每行 5 个 buffer，一次 Post 5 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.322 s（不含停稳），回程 + Y 表 0.360 s（含 2 次停稳；最后一行 0.350 s），Y 退回表 0.090 s
每行 0.683 s，全程 6.91 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
  对照 docs/14 附 A：每行 0.68 s、全程约 6.9 s 对得上。附 A 把一次停稳算在行扫描里（0.37 + 0.31 s），
  本程序两次停稳都在回程 + Y 表里（0.32 + 0.36 s），所以 docs/14 3.2 的"readwrite >= 0.37 s"应为 >= 0.32 s。
数据：raw uint16 1024 x 10 x 10 = 204800 B（200.0 kB）

== 8. 上硬件（docs/14 阶段 3–6） ==
【在做什么】循环外准备一次 Dev1、ctr1、ATS；每行 arm → 行扫描 → 取数 → 存盘 → 看停止按钮 → 回程 + Y。
【为什么】DMA buffer 每行重复使用，这一行在电机再动之前就存好；只在行间停，电机不会停在半路，退回距离按累计命令位置算。
数据文件：C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_210855.mat
DO 时钟：设 248000 S/s，实际 248000.0 S/s（不一样的话，所有时长和扫描速度按比例变）
停止按钮只在行与行之间检查：按下后做完当前这一行再停，然后退回起点。不要用 Ctrl+C（不会自动退回）。
【暂停】第 1 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 1 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 1/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9271 us，脉冲高 1.047 ~ 1.053 V；ctr1 = 10（应为 10）；用时 1.84 s（arm 0.026 / 扫描 0.575 / 取数 0.054 / 存 0.053 / 回程+Y 0.526）
【暂停】第 2 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 2 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 2/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9271 us，脉冲高 1.048 ~ 1.052 V；ctr1 = 10（应为 10）；用时 3.04 s（arm 0.026 / 扫描 0.502 / 取数 0.045 / 存 0.054 / 回程+Y 0.645）
【暂停】第 3 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 3 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 3/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9281 us，脉冲高 1.048 ~ 1.052 V；ctr1 = 10（应为 10）；用时 57.75 s（arm 0.026 / 扫描 0.495 / 取数 0.043 / 存 0.052 / 回程+Y 0.554）
【暂停】第 4 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）

*** 第 4 行（取数）出错：第 4 行 buffer 1/5 未完成（ApiWaitTimeout (579)）：这一行收到的触发数在 0 ~ 1 之间，检查 G1 → TRIG IN。
已完成的 3 行在：C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_210855.mat
ctr1：全程 40 个 P0.6 上升沿（已完成的 3 行应为 30）；第 4 行 10 个（这一行扫完应为 10）
出错时没有 readwrite 在跑，命令位置已知：X +500.0 um，Y +30.0 um。
自动退回起点...
已在起点。用手轮记号核对一下。
Error using cscan_test>atsCollectRow (line 1011)
第 4 行 buffer 1/5 未完成（ApiWaitTimeout (579)）：这一行收到的触发数在 0 ~ 1 之间，检
查 G1 → TRIG IN。

Error in cscan_test>runCscan (line 810)
                rawRow = atsCollectRow(H, ATS, NX, iy);
                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Error in cscan_test (line 306)
cscan = runCscan(plan, P, ATS, cscan, f);
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 
>>
</pasted_content id="416e">

 应该是发生器g1上内个三通把我拔下来了 连着示波器和triggerin的

### 🤖 Claude · 2026-10-15 01:10

**6.7 通过，每一项都和预期一样。** 你拔的是发生器 G1 输出上的三通，这一头连着示波器和 TRIG IN，拔掉后 TRIG IN 同样收不到触发，效果和拔 TRIG IN 那一头一样。

| 预期 | 实际 |
|---|---|
| 约 2 s 后报错，指出第几行 | `第 4 行（取数）出错：buffer 1/5 未完成（ApiWaitTimeout）` ✔ |
| 发送端正常 | `第 4 行 10 个`：P0.6 照样发了 10 个，问题在 G1 → TRIG IN 这段，打印也这样提示了 ✔ |
| 已采的行保存好 | `已完成的 3 行在 …210855.mat` ✔ |
| 位置已知，自动退回 | 出错时 X +500 µm、Y +30 µm（第 4 行扫完、Y 走了 3 步）→ `自动退回起点… 已在起点` ✔ |
| 不卡住、不存假数据 | 红字报错后回到 `>>`，第 4 行没有写进文件 ✔ |

第 3 行用时 57.75 s 是暂停时等你回车的时间，不算数。

**接下来：**
1. 把三通**插回发生器 G1 输出**。示波器 CH2 应该又能看到 G1 的方波（平台 2.00 V）。
2. 看两条胶带在记号上。
3. 第 26 行改回 `PAUSE_BETWEEN_ROWS = false`，第 20 行保持 `true`，正常跑一次 10 × 10。
4. 预期 100/100、ctr1 100。这一次能正常跑完，也就证明报错后 ATS 被正确释放了。顺便看上升沿：如果还在 1.924–1.933 µs，就是**没有**跳约 10 ns。
5. 跑完第 20 行改回 `false`，把打印贴给我。

### 🧑 用户 · 2026-10-15 01:12

<pasted_content id="416e">
cscan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 10 个触发、间隔 20 步；X 去程 = 回程 = 1000 步；Y 前进 9 x 20 步后退回；总触发 100；P0.7 全 0：true
K = 20，Ky = 20（Y 未标定时只是假设），fs = 248000，NX = 10，NY = 10，wTrig = 2 行（8.06 us），lead = 25 行
触发 400.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 10 x 10，间距 10.00 x 10.00 um；第一个像素在本行起点 + 200 um；每行 X 走 500 um，Y 共 90 um
ATS：每条 1024 点，每个 buffer 2 条（4096 B），每行 5 个 buffer，一次 Post 5 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.322 s（不含停稳），回程 + Y 表 0.360 s（含 2 次停稳；最后一行 0.350 s），Y 退回表 0.090 s
每行 0.683 s，全程 6.91 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
  对照 docs/14 附 A：每行 0.68 s、全程约 6.9 s 对得上。附 A 把一次停稳算在行扫描里（0.37 + 0.31 s），
  本程序两次停稳都在回程 + Y 表里（0.32 + 0.36 s），所以 docs/14 3.2 的"readwrite >= 0.37 s"应为 >= 0.32 s。
数据：raw uint16 1024 x 10 x 10 = 204800 B（200.0 kB）

== 8. 上硬件（docs/14 阶段 3–6） ==
【在做什么】循环外准备一次 Dev1、ctr1、ATS；每行 arm → 行扫描 → 取数 → 存盘 → 看停止按钮 → 回程 + Y。
【为什么】DMA buffer 每行重复使用，这一行在电机再动之前就存好；只在行间停，电机不会停在半路，退回距离按累计命令位置算。
数据文件：C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_211134.mat
DO 时钟：设 248000 S/s，实际 248000.0 S/s（不一样的话，所有时长和扫描速度按比例变）
停止按钮只在行与行之间检查：按下后做完当前这一行再停，然后退回起点。不要用 Ctrl+C（不会自动退回）。
第 1/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9277 us，脉冲高 1.047 ~ 1.053 V；ctr1 = 10（应为 10）；用时 1.25 s（arm 0.048 / 扫描 0.563 / 取数 0.055 / 存 0.056 / 回程+Y 0.529）
第 2/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9279 us，脉冲高 1.048 ~ 1.053 V；ctr1 = 10（应为 10）；用时 1.18 s（arm 0.042 / 扫描 0.498 / 取数 0.047 / 存 0.058 / 回程+Y 0.530）
第 3/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9278 us，脉冲高 1.047 ~ 1.052 V；ctr1 = 10（应为 10）；用时 1.20 s（arm 0.050 / 扫描 0.496 / 取数 0.051 / 存 0.057 / 回程+Y 0.540）
第 4/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9295 us，脉冲高 1.048 ~ 1.054 V；ctr1 = 10（应为 10）；用时 1.19 s（arm 0.049 / 扫描 0.500 / 取数 0.054 / 存 0.054 / 回程+Y 0.529）
第 5/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9279 us，脉冲高 1.048 ~ 1.052 V；ctr1 = 10（应为 10）；用时 1.29 s（arm 0.052 / 扫描 0.497 / 取数 0.048 / 存 0.059 / 回程+Y 0.627）
第 6/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9285 us，脉冲高 1.048 ~ 1.053 V；ctr1 = 10（应为 10）；用时 1.20 s（arm 0.038 / 扫描 0.505 / 取数 0.054 / 存 0.057 / 回程+Y 0.541）
第 7/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9276 us，脉冲高 1.049 ~ 1.054 V；ctr1 = 10（应为 10）；用时 1.21 s（arm 0.052 / 扫描 0.514 / 取数 0.053 / 存 0.054 / 回程+Y 0.532）
第 8/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9276 us，脉冲高 1.048 ~ 1.053 V；ctr1 = 10（应为 10）；用时 1.20 s（arm 0.052 / 扫描 0.506 / 取数 0.044 / 存 0.055 / 回程+Y 0.539）
第 9/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9285 us，脉冲高 1.049 ~ 1.054 V；ctr1 = 10（应为 10）；用时 1.18 s（arm 0.053 / 扫描 0.501 / 取数 0.052 / 存 0.055 / 回程+Y 0.522）
第 10/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9290 us，脉冲高 1.048 ~ 1.054 V；ctr1 = 10（应为 10）；用时 1.18 s（arm 0.042 / 扫描 0.497 / 取数 0.054 / 存 0.058 / 回程+Y 0.527）
回到起点：命令位置 X +0.0 um，Y +0.0 um（应为 0 / 0）；ctr1 全程 100（应为 100）

== 9. 结果（docs/14 6.1、6.3、6.4） ==
【在做什么】汇总每条 A-line 的快速检查，算 MAP；存过盘的话把文件读回来逐点比较。
【为什么】条数、ctr1、计划位置三个数对上，才能说第 k 条记录 = 第 k 个位置；重读一致才说明存的东西能用。
完成 10/10 行，A-line 100 条；每条正好 1 个沿：100/100；rail 点数 0
上升沿 1.9261 ~ 1.9326 us，标准差 2.00 ns，峰峰 6.46 ns；MAP 1.0401 ~ 1.0477 V（标准差 1.66 mV）
重读 C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_211134.mat：isequal(raw) = 1，isequal(MAP) = 1
>>
</pasted_content id="416e">

 貌似好了我可以怎么把y和x的移动都调节的大一点呢

### 🤖 Claude · 2026-10-15 01:12

**6.7 全部通过。** 插回三通后正常跑：100/100、ctr1 100，上升沿 **1.9261–1.9326 µs**，和 5.1（1.9261–1.9325）几乎一样。所以超时之后上升沿**没有**跳约 10 ns，ATS 也正确释放了。

**把 X、Y 的移动调大，改的就是像素间距：**
- [cscan_test.m:32](07_MATLAB/cscan_test.m:32) `DX_UM`：X 方向相邻两个像素隔多远；
- [cscan_test.m:33](07_MATLAB/cscan_test.m:33) `DY_UM`：Y 每行走多远。

像素数（NX、NY）不变，间距变大，扫的范围就变大。正好下一步 6.2「量四个角」要用这一组：

| 行 | 改成 | 结果 [条件计算] |
|---|---|---|
| 32 | `DX_UM = 200;` | 每像素 400 个脉冲，触发变成 20 Hz（速度还是 4 mm/s）；每行 X 走 **2400 µm**（X 联轴器转 1.2 圈） |
| 33 | `DY_UM = 200;` | Y 每行走 200 µm（36°），10 行一共 **1800 µm**（0.9 圈），钢尺能读出来 |

能调多大有两条限制，程序里有 assert 拦着，超了会直接报错、不会动：
- 软件限位 ±5000 µm（[cscan_test.m:57](07_MATLAB/cscan_test.m:57)）：X 每行 = 400 + NX × DX ≤ 5000；Y 一共 = (NY − 1) × DY ≤ 5000。
- DX、DY 必须是 0.5 µm 的整数倍。

**6.2 的做法：**
1. 改第 32、33 行为 200；第 26 行 PAUSE 改 `true`；第 24 行 SAVE 改 `false`。
2. 先跑检查模式，应该看到：`K = 400`、`触发 20.0 Hz`、`每行 X 走 2400 um，Y 共 1800 um`、`行扫描表 0.797 s`、`回程 + Y 表 1.500 s`、`全程 24.58 s`。
3. 第 20 行改 `true` 上硬件。在 4 个暂停时记下钢尺读数（拍照也行）：
   1. 第 1 行开始前：Y 钢尺 4.3 cm，胶带都在记号；
   2. 第 1 行扫完：X 在 +2400 µm，联轴器比整圈多转 72°；
   3. **第 10 行开始前：X 回到记号；Y 在 +1800 µm，钢尺约 4.12 cm**（朝电机，读数变小）。这一步就是用钢尺确认 Y 的方向；
   4. 第 10 行扫完：X 在 +2400、Y 在 +1800。

   第 2–9 行的暂停直接回车。
4. 跑完第 20 行改回 `false`。

### 🧑 用户 · 2026-10-15 01:19

<pasted_content id="416e">
cscan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 10 个触发、间隔 400 步；X 去程 = 回程 = 4800 步；Y 前进 9 x 400 步后退回；总触发 100；P0.7 全 0：true
K = 400，Ky = 400（Y 未标定时只是假设），fs = 248000，NX = 10，NY = 10，wTrig = 2 行（8.06 us），lead = 25 行
触发 20.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 10 x 10，间距 200.00 x 200.00 um；第一个像素在本行起点 + 200 um；每行 X 走 2400 um，Y 共 1800 um
ATS：每条 1024 点，每个 buffer 2 条（4096 B），每行 5 个 buffer，一次 Post 5 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.797 s（不含停稳），回程 + Y 表 1.500 s（含 2 次停稳；最后一行 1.300 s），Y 退回表 1.800 s
每行 2.298 s，全程 24.58 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
数据：raw uint16 1024 x 10 x 10 = 204800 B（200.0 kB）

== 7. 假数据走一遍数据通路（docs/14 1.4） ==
【在做什么】造一组已知图案的 raw（第 iy 行第 ix 条的脉冲高 = iy + ix/100 个单位），走一遍 快速检查 → 逐行存盘 → MAP → 重读。
【为什么】测试信号下 MAP 本来就是均匀的，行列排错了看不出来；用已知图案才能逐点核对。
假数据没有 ctr1 和计时，下面每行的 ctr1、用时显示 NaN。
第 1/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9389 us，脉冲高 0.303 ~ 0.330 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 2/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9360 us，脉冲高 0.603 ~ 0.630 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 3/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9363 us，脉冲高 0.903 ~ 0.930 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 4/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9351 us，脉冲高 1.203 ~ 1.230 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 5/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9333 us，脉冲高 1.503 ~ 1.530 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 6/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9327 us，脉冲高 1.803 ~ 1.830 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 7/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9340 us，脉冲高 2.103 ~ 2.130 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 8/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9334 us，脉冲高 2.403 ~ 2.430 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 9/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9342 us，脉冲高 2.703 ~ 2.730 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 10/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9333 us，脉冲高 3.003 ~ 3.030 V；ctr1 = NaN（应为 10）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
完成 10/10 行，A-line 100 条；每条正好 1 个沿：100/100；rail 点数 0
上升沿 1.9290 ~ 1.9414 us，标准差 2.61 ns，峰峰 12.33 ns；MAP 0.3030 ~ 3.0300 V（标准差 866.07 mV）
MAP(3,7) = 3.07（应为 3.07）；MAP(10,1) = 10.01（应为 10.01）
逐点核对：100/100 个像素对得上（误差 < 0.005 个单位）

*** 检查模式：没有向硬件发送任何信号。确认无误后把 RUN_HARDWARE 改成 true ***
>>
</pasted_content id="416e">

### 🤖 Claude · 2026-10-15 01:19

检查模式完全对上：`K = 400`、`触发 20.0 Hz`、`每行 X 走 2400 um，Y 共 1800 um`、`行扫描表 0.797 s`、`回程 + Y 表 1.500 s`、`Y 退回表 1.800 s`、`全程 24.58 s`。软件限位也过了（2400、1800 都小于 5000）。

**上硬件**：确认第 26 行 PAUSE 是 `true`，第 20 行改 `true`，运行。在这 4 次暂停时记录 Y 的钢尺读数和两条胶带，最好拍照：

| 暂停 | 应该看到 |
|---|---|
| ① 第 1 行开始前 | 都在记号上，Y 钢尺约 4.3 cm |
| ② 第 1 行扫完 | X 在 +2400 µm：联轴器转了 1 圈多 72°；Y 不动 |
| ③ **第 10 行开始前** | X 回到记号；**Y 在 +1800 µm，钢尺约 4.12 cm**（读数变小 = 朝电机） |
| ④ 第 10 行扫完 | X 又在 +2400，Y 还在 +1800 |

第 2–9 行的暂停直接回车。全程大约 30 秒多一点，加上暂停时间。最后 X、Y 自动退回，再看一次胶带是否回到记号、钢尺是否回到 4.3 cm。

跑完第 20 行改回 `false`，把读数、照片和打印发给我。

### 🧑 用户 · 2026-10-15 01:23

是的

### 🤖 Claude · 2026-10-15 01:23

我没法从这两张照片里可靠地读出数，原因有两个：
- 我不知道哪张是哪个时刻。我猜第 1 张是 ①「第 1 行开始前」、第 2 张是 ③「第 10 行开始前」，对吗？
- 两张照片里钢尺放的位置不一样。第 1 张尺子的 0 顶在右边那块黑色件上，第 2 张的 0 顶在窗口那块板的角上，拍摄距离和角度也不同。1.8 mm 的差别比这些摆放误差还小，照片之间比不出来。

**直接告诉我你眼睛读到的数就行：** ① 和 ③ 两次，联轴器窗口左边内沿对着钢尺的哪个刻度（下午 2.4 一直是这样读的：起点 4.3，+10 mm 时 3.3）。③ 应该比 ① 小约 0.18 cm。只要看到「③ 比 ① 小一点点」，方向就对了。

另外：
1. 最后胶带都回到记号、钢尺回到 4.3 了吗？
2. 把命令行的打印贴给我。我要看每行 ctr1 10、全程 100、`回到起点 0 / 0`。
3. 第 20 行改回 `false`。

### 🧑 用户 · 2026-10-15 01:23

钢尺约 4.12 cm是的 是4.1 左右 

<pasted_content id="416e">
cscan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 10 个触发、间隔 400 步；X 去程 = 回程 = 4800 步；Y 前进 9 x 400 步后退回；总触发 100；P0.7 全 0：true
K = 400，Ky = 400（Y 未标定时只是假设），fs = 248000，NX = 10，NY = 10，wTrig = 2 行（8.06 us），lead = 25 行
触发 20.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 10 x 10，间距 200.00 x 200.00 um；第一个像素在本行起点 + 200 um；每行 X 走 2400 um，Y 共 1800 um
ATS：每条 1024 点，每个 buffer 2 条（4096 B），每行 5 个 buffer，一次 Post 5 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.797 s（不含停稳），回程 + Y 表 1.500 s（含 2 次停稳；最后一行 1.300 s），Y 退回表 1.800 s
每行 2.298 s，全程 24.58 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
数据：raw uint16 1024 x 10 x 10 = 204800 B（200.0 kB）

== 8. 上硬件（docs/14 阶段 3–6） ==
【在做什么】循环外准备一次 Dev1、ctr1、ATS；每行 arm → 行扫描 → 取数 → 存盘 → 看停止按钮 → 回程 + Y。
【为什么】DMA buffer 每行重复使用，这一行在电机再动之前就存好；只在行间停，电机不会停在半路，退回距离按累计命令位置算。
DO 时钟：设 248000 S/s，实际 248000.0 S/s（不一样的话，所有时长和扫描速度按比例变）
停止按钮只在行与行之间检查：按下后做完当前这一行再停，然后退回起点。不要用 Ctrl+C（不会自动退回）。
【暂停】第 1 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 1 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 1/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9280 us，脉冲高 1.048 ~ 1.055 V；ctr1 = 10（应为 10）；用时 4.85 s（arm 0.027 / 扫描 1.015 / 取数 0.057 / 存 0.005 / 回程+Y 1.648）
【暂停】第 2 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 2 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 2/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9278 us，脉冲高 1.049 ~ 1.054 V；ctr1 = 10（应为 10）；用时 3.07 s（arm 0.025 / 扫描 0.928 / 取数 0.043 / 存 0.001 / 回程+Y 1.661）
【暂停】第 3 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 3 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 3/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9275 us，脉冲高 1.048 ~ 1.053 V；ctr1 = 10（应为 10）；用时 4.25 s（arm 0.026 / 扫描 0.942 / 取数 0.050 / 存 0.001 / 回程+Y 1.642）
【暂停】第 4 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 4 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 4/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9297 us，脉冲高 1.047 ~ 1.053 V；ctr1 = 10（应为 10）；用时 4.15 s（arm 0.026 / 扫描 0.947 / 取数 0.052 / 存 0.001 / 回程+Y 1.652）
【暂停】第 5 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 5 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 5/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9298 us，脉冲高 1.049 ~ 1.053 V；ctr1 = 10（应为 10）；用时 3.95 s（arm 0.029 / 扫描 0.954 / 取数 0.051 / 存 0.002 / 回程+Y 1.670）
【暂停】第 6 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 6 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 6/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9279 us，脉冲高 1.047 ~ 1.053 V；ctr1 = 10（应为 10）；用时 3.84 s（arm 0.026 / 扫描 0.952 / 取数 0.047 / 存 0.000 / 回程+Y 1.674）
【暂停】第 7 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 7 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 7/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9282 us，脉冲高 1.048 ~ 1.053 V；ctr1 = 10（应为 10）；用时 3.17 s（arm 0.025 / 扫描 0.937 / 取数 0.037 / 存 0.000 / 回程+Y 1.664）
【暂停】第 8 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 8 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 8/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9298 us，脉冲高 1.047 ~ 1.054 V；ctr1 = 10（应为 10）；用时 4.37 s（arm 0.026 / 扫描 0.925 / 取数 0.042 / 存 0.000 / 回程+Y 1.645）
【暂停】第 9 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 9 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 9/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9278 us，脉冲高 1.047 ~ 1.053 V；ctr1 = 10（应为 10）；用时 6.31 s（arm 0.027 / 扫描 0.940 / 取数 0.038 / 存 0.000 / 回程+Y 1.668）
【暂停】第 10 行开始前：看两个手轮，按回车继续（要停就点停止按钮，不要 Ctrl+C）
【暂停】第 10 行扫完（回程前）：看两个手轮，按回车继续（要停就点停止按钮）
第 10/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9278 us，脉冲高 1.047 ~ 1.052 V；ctr1 = 10（应为 10）；用时 3.13 s（arm 0.026 / 扫描 0.964 / 取数 0.048 / 存 0.001 / 回程+Y 1.449）

回到起点：命令位置 X +0.0 um，Y +0.0 um（应为 0 / 0）；ctr1 全程 100（应为 100）

== 9. 结果（docs/14 6.1、6.3、6.4） ==
【在做什么】汇总每条 A-line 的快速检查，算 MAP；存过盘的话把文件读回来逐点比较。
【为什么】条数、ctr1、计划位置三个数对上，才能说第 k 条记录 = 第 k 个位置；重读一致才说明存的东西能用。
完成 10/10 行，A-line 100 条；每条正好 1 个沿：100/100；rail 点数 0
上升沿 1.9261 ~ 1.9326 us，标准差 1.89 ns，峰峰 6.45 ns；MAP 1.0403 ~ 1.0481 V（标准差 1.71 mV）

>>
</pasted_content id="416e">

### 🤖 Claude · 2026-10-15 01:23

**6.2 通过，Y 的方向也用钢尺坐实了。**

| 项 | 结果 |
|---|---|
| Y 位置 | ① 4.3 cm → ③（+1800 µm）约 **4.1 cm**：读数变小 = **朝电机**，距离约 2 mm，和 1.8 mm 在钢尺精度内对得上 ✔ |
| 数据 | 100/100、ctr1 每行 10、全程 100、rail 0；上升沿 1.9261–1.9326 µs，和 10 µm 版完全一样 |
| MAP | 范围变成 1800 × 1800 µm（第一次扫 2 mm × 2 mm），1.040–1.048 V，均匀 |
| 回到起点 | 0 / 0 |

计时也记一下：扫描表 0.797 s，实测约 0.94 s；回程 + Y 1.500 s，实测约 1.66 s。行变长以后，每次 readwrite 多出的时间还是约 0.15 s，说明开销基本是固定的，不随行长增加。6.10 会用到这一点。

现在 Y 的 µm/脉冲、方向、在 C-scan 里的运动全部有实测了。

**今晚的计划已经完成 6.4、6.5、6.6、6.7、6.2 和 6.9 的「重复 3 次」，还剩 6.9 的「换参数」，约 3 分钟：**

| 行 | 改成 |
|---|---|
| 30 | `NX = 20;` |
| 31 | `NY = 5;` |
| 32 | `DX_UM = 5;` |
| 33 | `DY_UM = 20;` |
| 24 | `SAVE_DATA = true;` |
| 26 | `PAUSE_BETWEEN_ROWS = false;` |

检查模式应该看到：`K = 10`、`触发 800.0 Hz`、`每行 10 个 buffer`、`行扫描表 0.322 s`、`回程 + Y 表 0.370 s`、`全程 3.52 s`、`Y 共 80 um`。
上硬件预期：每行 20/20、ctr1 20，全程 **100**；MAP 是「宽 20、高 5」的图。

这个也做完的话，阶段 6 只剩 6.10（正式计时）和 6.11（ring buffer）。时间还够，可以接着做，也可以收工。

### 🧑 用户 · 2026-10-15 01:25

<pasted_content id="416e">
cscan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 20 个触发、间隔 10 步；X 去程 = 回程 = 1000 步；Y 前进 4 x 40 步后退回；总触发 100；P0.7 全 0：true
K = 10，Ky = 40（Y 未标定时只是假设），fs = 248000，NX = 20，NY = 5，wTrig = 2 行（8.06 us），lead = 25 行
触发 800.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 20 x 5，间距 5.00 x 20.00 um；第一个像素在本行起点 + 200 um；每行 X 走 500 um，Y 共 80 um
ATS：每条 1024 点，每个 buffer 2 条（4096 B），每行 10 个 buffer，一次 Post 10 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.322 s（不含停稳），回程 + Y 表 0.370 s（含 2 次停稳；最后一行 0.350 s），Y 退回表 0.080 s
每行 0.693 s，全程 3.52 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
数据：raw uint16 1024 x 20 x 5 = 204800 B（200.0 kB）

== 8. 上硬件（docs/14 阶段 3–6） ==
【在做什么】循环外准备一次 Dev1、ctr1、ATS；每行 arm → 行扫描 → 取数 → 存盘 → 看停止按钮 → 回程 + Y。
【为什么】DMA buffer 每行重复使用，这一行在电机再动之前就存好；只在行间停，电机不会停在半路，退回距离按累计命令位置算。
数据文件：C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_212504.mat
DO 时钟：设 248000 S/s，实际 248000.0 S/s（不一样的话，所有时长和扫描速度按比例变）
停止按钮只在行与行之间检查：按下后做完当前这一行再停，然后退回起点。不要用 Ctrl+C（不会自动退回）。
第 1/5 行：A-line 20/20，1 个沿 20/20，上升沿中位数 1.9277 us，脉冲高 1.049 ~ 1.053 V；ctr1 = 20（应为 20）；用时 1.24 s（arm 0.048 / 扫描 0.562 / 取数 0.052 / 存 0.058 / 回程+Y 0.524）
第 2/5 行：A-line 20/20，1 个沿 20/20，上升沿中位数 1.9282 us，脉冲高 1.048 ~ 1.054 V；ctr1 = 20（应为 20）；用时 1.18 s（arm 0.051 / 扫描 0.496 / 取数 0.051 / 存 0.051 / 回程+Y 0.527）
第 3/5 行：A-line 20/20，1 个沿 20/20，上升沿中位数 1.9294 us，脉冲高 1.048 ~ 1.055 V；ctr1 = 20（应为 20）；用时 1.18 s（arm 0.040 / 扫描 0.503 / 取数 0.050 / 存 0.063 / 回程+Y 0.521）
第 4/5 行：A-line 20/20，1 个沿 20/20，上升沿中位数 1.9278 us，脉冲高 1.049 ~ 1.055 V；ctr1 = 20（应为 20）；用时 1.17 s（arm 0.041 / 扫描 0.499 / 取数 0.054 / 存 0.056 / 回程+Y 0.518）
第 5/5 行：A-line 20/20，1 个沿 20/20，上升沿中位数 1.9285 us，脉冲高 1.047 ~ 1.054 V；ctr1 = 20（应为 20）；用时 1.19 s（arm 0.040 / 扫描 0.497 / 取数 0.047 / 存 0.064 / 回程+Y 0.537）
回到起点：命令位置 X +0.0 um，Y +0.0 um（应为 0 / 0）；ctr1 全程 100（应为 100）

== 9. 结果（docs/14 6.1、6.3、6.4） ==
【在做什么】汇总每条 A-line 的快速检查，算 MAP；存过盘的话把文件读回来逐点比较。
【为什么】条数、ctr1、计划位置三个数对上，才能说第 k 条记录 = 第 k 个位置；重读一致才说明存的东西能用。
完成 5/5 行，A-line 100 条；每条正好 1 个沿：100/100；rail 点数 0
上升沿 1.9260 ~ 1.9326 us，标准差 1.96 ns，峰峰 6.66 ns；MAP 1.0401 ~ 1.0476 V（标准差 1.59 mV）
重读 C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_212504.mat：isequal(raw) = 1，isequal(MAP) = 1
>>
</pasted_content id="416e">

 我不做ring buffer 我要dualport 这个是自动的 可以帮我查一下么

### 🤖 Claude · 2026-10-15 01:25

**6.9 换参数也通过了**：20 × 5、Δx 5 µm、800 Hz、每行 10 个 buffer → 每行 20/20、ctr1 20、全程 100，上升沿 1.9260–1.9326 µs，重读 isequal = 1。换一组 NX ≠ NY 的参数，程序照样正确。

dual-port 的事我查一下 SDK 指南和 docs/12 的原文。

### 🤖 Claude · 2026-10-15 01:25

> 🔧 Bash · description: Find dual-port notes in docs/12 and SDK files

### ⚙️ 工具 · 2026-10-15 01:25

<details><summary>工具输出</summary>

```
1:# 12 DMA buffer 怎么定，以及 dual-port（导师 10/6 的提示）
3:导师的提示（用户转述，10/6）：buffer 要"成倍"地用；buffer 的数量和 DMA、电脑的 RAM、采集的数据量有关；还要看一下和 digitizer 有关的 "dual ..."。下面是 10/6 在 SDK 自带文件里查到的内容，以及按我们的参数算出来的数。
6:来源：`C:\AlazarTech\ATS-SDK\23.3.0\Samples_MATLAB\ATS9462\ReadMe.htm`、`...\DualPort\NPT_StreamToMemory\ATS9462_NPT_StreamToMemory.m`（第 179–250 行）、`Include\AlazarDefs.m`
10:| **dual-port AutoDMA** | ATS9462 的 MATLAB 示例全部在 `DualPort` 文件夹里，我们的 A-line、多条采集也是照它写的。意思是：板卡一边把采样写进**板载内存**，一边用 DMA 把板载内存里的数据搬到电脑内存的 buffer 里。板载内存起到"中间水箱"的作用 |
11:| 什么时候用 AutoDMA | ① 平均数据率低于 PCIe 上限（ATS9462 是 PCIe Gen1 ×8，最高约 1.6 GB/s）；② 不
…[截断，共 2196 字符]
```
</details>

### 🤖 Claude · 2026-10-15 01:25

> 🔧 Read · file_path: C:\Users\2031\Desktop\Research-PAM\01_硬件资料\ATS-SDK-Guide.pdf

### ⚙️ 工具 · 2026-10-15 01:25

<details><summary>工具输出</summary>

```
pdftoppm is not installed. Install poppler-utils (e.g. `brew install poppler` or `apt-get install poppler-utils`) to enable PDF page rendering.
```
</details>

### 🤖 Claude · 2026-10-15 01:26

> 🔧 Bash · description: Search exported chats for SDK §3.4.1 quotes

### ⚙️ 工具 · 2026-10-15 01:26

<details><summary>工具输出</summary>

```
C:/Users/2031/Desktop/Research-PAM/08_对话记录/2026-10-05_提前完成_cscan_的计划调整_67ed74c7.md
C:/Users/2031/Desktop/Research-PAM/08_对话记录/2026-10-13_C-scan_module_Y_axis_+_cscan_test.m_dd5e50b6.md
1586:3.4.1 Dual port AutoDMA acquisition
1. 用 AutoDMA 这组函数采集：`AlazarBeforeAsyncRead` → `AlazarPostAsyncBuffer` → `AlazarStartCapture` → `AlazarWaitAsyncBufferComplete`。SDK 手册（`ATS-SDK-Guide.pdf` §3.4.1）直接把这组函数叫作 dual-port 的函数。
：NPT AutoDMA（`AlazarBeforeAsyncRead` + `AlazarPostAsyncBuffer`，flags `ADMA_EXTERNAL_STARTCAPTURE | ADMA_NPT`）本身就是 dual-port，代码里没有、也不需要单独开关（SDK 指南 §3.4.1）。板载内存在 readwrite 阻塞时先接住数据，写满约 65,53
…[截断，共 695 字符]
```
</details>

### 🤖 Claude · 2026-10-15 01:26

> 🔧 Bash · description: Locate SDK quotes on dual-port in earlier chat

### ⚙️ 工具 · 2026-10-15 01:26

<details><summary>工具输出</summary>

```
1197:226:being stored in on-board memory or being DMA'd to         External Trigger Input
1472:1573:    � Dual port AutoDMA acquisition mode acquires to on-board memory while, at the same
1474:1580:acquisitions should only be used with PCI bus digitizers that do not have dual-port memory
1475:1581:(i.e. ATS460 and ATS860 without dual-port memory upgrade, ATS310, ATS330, ATS850).
1476:1586:3.4.1 Dual port AutoDMA acquisition
1477:1588:AutoDMA allows a board to capture sample data to on-board dual-port memory while - at
1478:1589:the same time - transferring sample data from on-board dual-port m
…[截断，共 984 字符]
```
</details>

### 🤖 Claude · 2026-10-15 01:26

> 🔧 Bash · description: Read SDK guide excerpt about dual-port AutoDMA

### ⚙️ 工具 · 2026-10-15 01:26

<details><summary>工具输出</summary>

```
### ⚙️ 工具 · 2026-10-13 22:45

<details><summary>工具输出</summary>

```
1573:    � Dual port AutoDMA acquisition mode acquires to on-board memory while, at the same
1578:Note: Dual-port AutoDMA is the recommended acquisition mode for data acquisition with
1580:acquisitions should only be used with PCI bus digitizers that do not have dual-port memory
1581:(i.e. ATS460 and ATS860 without dual-port memory upgrade, ATS310, ATS330, ATS850).
1586:3.4.1 Dual port AutoDMA acquisition
1588:AutoDMA allows a board to capture sample data to on-board dual-port memory while - at
1589:the same time - transferrin
…[截断，共 1820 字符]
```
</details>

### 🤖 Claude · 2026-10-15 01:26

查过了，**是自动的：现在的 `cscan_test.m` 用的就是 dual-port。** 代码里没有、也不需要单独的开关。

**依据：SDK 指南 `01_硬件资料/ATS-SDK-Guide.pdf`**
- §3.4 写明 ATS 板卡只有两种采集模式：
  - **Dual-port AutoDMA**：板卡边采边传，"acquires to on-board memory while, at the same time, transferring data"。采样先写进板载内存，同时用 DMA 搬到电脑内存的 buffer 里。
  - **Single-port**：先全部采进板载内存，采完以后再整体读出来，用的是另一组函数（`AlazarRead`）。
  - 指南推荐用 dual-port；single-port 只给没有 dual-port 内存的老型号用。
- §3.4.1「Dual port AutoDMA acquisition」：用的就是 `AlazarBeforeAsyncRead → AlazarPostAsyncBuffer → AlazarStartCapture → AlazarWaitAsyncBufferComplete` 这一组函数。
- ATS9462 的 SDK MATLAB 示例全部放在 `DualPort` 文件夹里，我们的代码就是照它写的（docs/12 第 10 行）。

**`cscan_test.m` 里对应的行**

| 行 | 代码 | 作用 |
|---|---|---|
| [977](07_MATLAB/cscan_test.m:977) | `ADMA_EXTERNAL_STARTCAPTURE \| ADMA_NPT` | AutoDMA 的 NPT 模式（每个触发采一条，没有触发前的点） |
| [985](07_MATLAB/cscan_test.m:985) | `AlazarBeforeAsyncRead` | 进入 dual-port AutoDMA |
| [987](07_MATLAB/cscan_test.m:987) | `AlazarPostAsyncBuffer` | 把电脑内存的 buffer 交给板卡，DMA 往里写 |
| [989](07_MATLAB/cscan_test.m:989) | `AlazarStartCapture` | 开始等触发 |
| [1003](07_MATLAB/cscan_test.m:1003) | `AlazarWaitAsyncBufferComplete` | 取走已经写满的 buffer |

（第 781、832 行各加了一行 `commandwindow;`，所以这些行号比我早先读的版本往后挪了 1 行。）

**今晚的数据就是它在工作的证据：** readwrite 期间 MATLAB 被占住，什么也干不了，但触发照样进来，数据先进板载内存，同时 DMA 到 buffer 里。所以 readwrite 一结束，取 5 个 buffer 只要约 0.05 s，而且每行都是 10/10。

**ring buffer 和 dual-port 是两回事，不做也没关系：**
- dual-port 是板卡的采集模式，已经在用。
- ring buffer 说的是电脑这边分配几个 buffer、要不要循环使用。现在是每行的 buffer 全部预先交出去（第 77 行 `postedBuffers = Inf`），10 × 10 每行只要 5 个，完全没问题。只有一行要几百个 buffer 时，才需要改成循环用 4 个（6.11）。我在 docs/14 里把 6.11 标成「暂不做」。

这件事 10/12 Rui 提过：dual-port 和 ring buffer 都让你自己先弄懂。给他看的时候可以这样说：dual-port 一直在用；ring buffer 目前用不上，记录多到一定程度才需要。

**到现在，阶段 6 只剩 6.10 正式计时**，接下来做它还是收工？做的话：NY = 3，NX 分别取 10、50、200 各跑一次，拟合「每行固定开销 + 每像素时间」，大约 10 分钟。

### 🧑 用户 · 2026-10-15 01:27

做6.10

### 🤖 Claude · 2026-10-15 01:27

好，做 6.10。

**在测什么：** 每行时间 = **固定开销**（加减速、回程里的停稳、readwrite 启动、arm）+ **NX × 每像素时间**。换三个 NX 各跑一次，画一条直线，斜率就是每像素时间，截距就是每行固定开销。Rui 第 4 周要这个数，用来估算整个视场要扫多久。

**先改成基本设置**（Δ 10 µm、400 Hz，回到附 A）：

| 行 | 改成 |
|---|---|
| 31 | `NY = 3;` |
| 32 | `DX_UM = 10;` |
| 33 | `DY_UM = 10;` |
| 24 | `SAVE_DATA = true;`（计时会存进文件，我直接从文件里读） |
| 26 | `PAUSE_BETWEEN_ROWS = false;` |

**然后只改 NX 跑三次**（每次都先跑检查模式，再第 20 行 `true` 上硬件）：

| 次 | 第 30 行 NX | 第 76 行 recordsPerBuffer | 每行几个 buffer | 计划每行 [条件计算] |
|---|---|---|---|---|
| A | 10 | 2 | 5 | 0.68 s |
| B | 50 | 2 | 25 | 0.98 s |
| C | 200 | **10** | 20 | 2.11 s |

C 要把 recordsPerBuffer 改成 10：rpb = 2 时一行要 100 个 buffer，超过 64，程序会警告可能资源不够，这个情况没测过。改成 10 以后每个 buffer 20 KB、一行 20 个，安全。

计划的每行时间是一条直线：斜率 7.5 ms/像素（每像素扫描 2.5 ms + 回程 5 ms），截距 0.61 s。按今晚的实测，每行还会多出约 0.5 s 软件开销，所以实际大概是 1.2 / 1.5 / 2.6 s。

三次跑完：第 20 行改回 `false`，第 76 行改回 `2`，告诉我一声，我从三个数据文件里读计时、拟合直线。打印不用贴，除非报错。

### 🧑 用户 · 2026-10-15 01:31

<pasted_content id="416e">
cscan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 20 个触发、间隔 20 步；X 去程 = 回程 = 1200 步；Y 前进 2 x 20 步后退回；总触发 60；P0.7 全 0：true
K = 20，Ky = 20（Y 未标定时只是假设），fs = 248000，NX = 20，NY = 3，wTrig = 2 行（8.06 us），lead = 25 行
触发 400.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 20 x 3，间距 10.00 x 10.00 um；第一个像素在本行起点 + 200 um；每行 X 走 600 um，Y 共 20 um
ATS：每条 1024 点，每个 buffer 2 条（4096 B），每行 10 个 buffer，一次 Post 10 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.347 s（不含停稳），回程 + Y 表 0.410 s（含 2 次停稳；最后一行 0.400 s），Y 退回表 0.020 s
每行 0.758 s，全程 2.28 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
数据：raw uint16 1024 x 20 x 3 = 122880 B（120.0 kB）

== 7. 假数据走一遍数据通路（docs/14 1.4） ==
【在做什么】造一组已知图案的 raw（第 iy 行第 ix 条的脉冲高 = iy + ix/100 个单位），走一遍 快速检查 → 逐行存盘 → MAP → 重读。
【为什么】测试信号下 MAP 本来就是均匀的，行列排错了看不出来；用已知图案才能逐点核对。
数据文件：C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_mock_20261014_212909.mat
假数据没有 ctr1 和计时，下面每行的 ctr1、用时显示 NaN。
第 1/3 行：A-line 20/20，1 个沿 20/20，上升沿中位数 1.9389 us，脉冲高 0.303 ~ 0.360 V；ctr1 = NaN（应为 20）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 2/3 行：A-line 20/20，1 个沿 20/20，上升沿中位数 1.9371 us，脉冲高 0.603 ~ 0.660 V；ctr1 = NaN（应为 20）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
第 3/3 行：A-line 20/20，1 个沿 20/20，上升沿中位数 1.9345 us，脉冲高 0.903 ~ 0.960 V；ctr1 = NaN（应为 20）；用时 NaN s（arm NaN / 扫描 NaN / 取数 NaN / 存 NaN / 回程+Y NaN）
完成 3/3 行，A-line 60 条；每条正好 1 个沿：60/60；rail 点数 0
上升沿 1.9319 ~ 1.9415 us，标准差 2.36 ns，峰峰 9.53 ns；MAP 0.3030 ~ 0.9600 V（标准差 247.63 mV）
重读 C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_mock_20261014_212909.mat：isequal(raw) = 1，isequal(MAP) = 1
MAP(3,7) = 3.07（应为 3.07）；MAP(3,1) = 3.01（应为 3.01）
逐点核对：60/60 个像素对得上（误差 < 0.005 个单位）

*** 检查模式：没有向硬件发送任何信号。确认无误后把 RUN_HARDWARE 改成 true ***
>> cscan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 20 个触发、间隔 20 步；X 去程 = 回程 = 1200 步；Y 前进 2 x 20 步后退回；总触发 60；P0.7 全 0：true
K = 20，Ky = 20（Y 未标定时只是假设），fs = 248000，NX = 20，NY = 3，wTrig = 2 行（8.06 us），lead = 25 行
触发 400.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 20 x 3，间距 10.00 x 10.00 um；第一个像素在本行起点 + 200 um；每行 X 走 600 um，Y 共 20 um
ATS：每条 1024 点，每个 buffer 2 条（4096 B），每行 10 个 buffer，一次 Post 10 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.347 s（不含停稳），回程 + Y 表 0.410 s（含 2 次停稳；最后一行 0.400 s），Y 退回表 0.020 s
每行 0.758 s，全程 2.28 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
数据：raw uint16 1024 x 20 x 3 = 122880 B（120.0 kB）

== 8. 上硬件（docs/14 阶段 3–6） ==
【在做什么】循环外准备一次 Dev1、ctr1、ATS；每行 arm → 行扫描 → 取数 → 存盘 → 看停止按钮 → 回程 + Y。
【为什么】DMA buffer 每行重复使用，这一行在电机再动之前就存好；只在行间停，电机不会停在半路，退回距离按累计命令位置算。
数据文件：C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_212934.mat
DO 时钟：设 248000 S/s，实际 248000.0 S/s（不一样的话，所有时长和扫描速度按比例变）
停止按钮只在行与行之间检查：按下后做完当前这一行再停，然后退回起点。不要用 Ctrl+C（不会自动退回）。
第 1/3 行：A-line 20/20，1 个沿 20/20，上升沿中位数 1.9284 us，脉冲高 1.047 ~ 1.053 V；ctr1 = 20（应为 20）；用时 1.28 s（arm 0.048 / 扫描 0.556 / 取数 0.043 / 存 0.062 / 回程+Y 0.572）
第 2/3 行：A-line 20/20，1 个沿 20/20，上升沿中位数 1.9279 us，脉冲高 1.048 ~ 1.052 V；ctr1 = 20（应为 20）；用时 1.26 s（arm 0.050 / 扫描 0.513 / 取数 0.053 / 存 0.055 / 回程+Y 0.593）
第 3/3 行：A-line 20/20，1 个沿 20/20，上升沿中位数 1.9276 us，脉冲高 1.048 ~ 1.052 V；ctr1 = 20（应为 20）；用时 1.25 s（arm 0.047 / 扫描 0.498 / 取数 0.048 / 存 0.057 / 回程+Y 0.594）
回到起点：命令位置 X +0.0 um，Y +0.0 um（应为 0 / 0）；ctr1 全程 60（应为 60）

== 9. 结果（docs/14 6.1、6.3、6.4） ==
【在做什么】汇总每条 A-line 的快速检查，算 MAP；存过盘的话把文件读回来逐点比较。
【为什么】条数、ctr1、计划位置三个数对上，才能说第 k 条记录 = 第 k 个位置；重读一致才说明存的东西能用。
完成 3/3 行，A-line 60 条；每条正好 1 个沿：60/60；rail 点数 0
上升沿 1.9261 ~ 1.9324 us，标准差 1.94 ns，峰峰 6.28 ns；MAP 1.0407 ~ 1.0465 V（标准差 1.45 mV）
重读 C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_212934.mat：isequal(raw) = 1，isequal(MAP) = 1
>>  cscan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 20 个触发、间隔 20 步；X 去程 = 回程 = 1200 步；Y 前进 2 x 20 步后退回；总触发 60；P0.7 全 0：true
K = 20，Ky = 20（Y 未标定时只是假设），fs = 248000，NX = 20，NY = 3，wTrig = 2 行（8.06 us），lead = 25 行
触发 400.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 20 x 3，间距 10.00 x 10.00 um；第一个像素在本行起点 + 200 um；每行 X 走 600 um，Y 共 20 um
ATS：每条 1024 点，每个 buffer 2 条（4096 B），每行 10 个 buffer，一次 Post 10 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.347 s（不含停稳），回程 + Y 表 0.410 s（含 2 次停稳；最后一行 0.400 s），Y 退回表 0.020 s
每行 0.758 s，全程 2.28 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
数据：raw uint16 1024 x 20 x 3 = 122880 B（120.0 kB）

== 8. 上硬件（docs/14 阶段 3–6） ==
【在做什么】循环外准备一次 Dev1、ctr1、ATS；每行 arm → 行扫描 → 取数 → 存盘 → 看停止按钮 → 回程 + Y。
【为什么】DMA buffer 每行重复使用，这一行在电机再动之前就存好；只在行间停，电机不会停在半路，退回距离按累计命令位置算。
数据文件：C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_212934.mat
DO 时钟：设 248000 S/s，实际 248000.0 S/s（不一样的话，所有时长和扫描速度按比例变）
停止按钮只在行与行之间检查：按下后做完当前这一行再停，然后退回起点。不要用 Ctrl+C（不会自动退回）。
第 1/3 行：A-line 20/20，1 个沿 20/20，上升沿中位数 1.9284 us，脉冲高 1.047 ~ 1.053 V；ctr1 = 20（应为 20）；用时 1.28 s（arm 0.048 / 扫描 0.556 / 取数 0.043 / 存 0.062 / 回程+Y 0.572）
第 2/3 行：A-line 20/20，1 个沿 20/20，上升沿中位数 1.9279 us，脉冲高 1.048 ~ 1.052 V；ctr1 = 20（应为 20）；用时 1.26 s（arm 0.050 / 扫描 0.513 / 取数 0.053 / 存 0.055 / 回程+Y 0.593）
第 3/3 行：A-line 20/20，1 个沿 20/20，上升沿中位数 1.9276 us，脉冲高 1.048 ~ 1.052 V；ctr1 = 20（应为 20）；用时 1.25 s（arm 0.047 / 扫描 0.498 / 取数 0.048 / 存 0.057 / 回程+Y 0.594）
回到起点：命令位置 X +0.0 um，Y +0.0 um（应为 0 / 0）；ctr1 全程 60（应为 60）

== 9. 结果（docs/14 6.1、6.3、6.4） ==
【在做什么】汇总每条 A-line 的快速检查，算 MAP；存过盘的话把文件读回来逐点比较。
【为什么】条数、ctr1、计划位置三个数对上，才能说第 k 条记录 = 第 k 个位置；重读一致才说明存的东西能用。
完成 3/3 行，A-line 60 条；每条正好 1 个沿：60/60；rail 点数 0
上升沿 1.9261 ~ 1.9324 us，标准差 1.94 ns，峰峰 6.28 ns；MAP 1.0407 ~ 1.0465 V（标准差 1.45 mV）
重读 C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_212934.mat：isequal(raw) = 1，isequal(MAP) = 1
>> cscan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 20 个触发、间隔 20 步；X 去程 = 回程 = 1200 步；Y 前进 2 x 20 步后退回；总触发 60；P0.7 全 0：true
K = 20，Ky = 20（Y 未标定时只是假设），fs = 248000，NX = 20，NY = 3，wTrig = 2 行（8.06 us），lead = 25 行
触发 400.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 20 x 3，间距 10.00 x 10.00 um；第一个像素在本行起点 + 200 um；每行 X 走 600 um，Y 共 20 um
ATS：每条 1024 点，每个 buffer 2 条（4096 B），每行 10 个 buffer，一次 Post 5 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.347 s（不含停稳），回程 + Y 表 0.410 s（含 2 次停稳；最后一行 0.400 s），Y 退回表 0.020 s
每行 0.758 s，全程 2.28 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
数据：raw uint16 1024 x 20 x 3 = 122880 B（120.0 kB）

== 8. 上硬件（docs/14 阶段 3–6） ==
【在做什么】循环外准备一次 Dev1、ctr1、ATS；每行 arm → 行扫描 → 取数 → 存盘 → 看停止按钮 → 回程 + Y。
【为什么】DMA buffer 每行重复使用，这一行在电机再动之前就存好；只在行间停，电机不会停在半路，退回距离按累计命令位置算。
数据文件：C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_213044.mat
DO 时钟：设 248000 S/s，实际 248000.0 S/s（不一样的话，所有时长和扫描速度按比例变）
停止按钮只在行与行之间检查：按下后做完当前这一行再停，然后退回起点。不要用 Ctrl+C（不会自动退回）。
第 1/3 行：A-line 20/20，1 个沿 20/20，上升沿中位数 1.9285 us，脉冲高 1.048 ~ 1.053 V；ctr1 = 20（应为 20）；用时 1.29 s（arm 0.050 / 扫描 0.563 / 取数 0.052 / 存 0.058 / 回程+Y 0.568）
第 2/3 行：A-line 20/20，1 个沿 20/20，上升沿中位数 1.9281 us，脉冲高 1.047 ~ 1.053 V；ctr1 = 20（应为 20）；用时 1.25 s（arm 0.052 / 扫描 0.478 / 取数 0.049 / 存 0.060 / 回程+Y 0.602）
第 3/3 行：A-line 20/20，1 个沿 20/20，上升沿中位数 1.9294 us，脉冲高 1.049 ~ 1.053 V；ctr1 = 20（应为 20）；用时 1.22 s（arm 0.044 / 扫描 0.498 / 取数 0.049 / 存 0.052 / 回程+Y 0.579）
回到起点：命令位置 X +0.0 um，Y +0.0 um（应为 0 / 0）；ctr1 全程 60（应为 60）

== 9. 结果（docs/14 6.1、6.3、6.4） ==
【在做什么】汇总每条 A-line 的快速检查，算 MAP；存过盘的话把文件读回来逐点比较。
【为什么】条数、ctr1、计划位置三个数对上，才能说第 k 条记录 = 第 k 个位置；重读一致才说明存的东西能用。
完成 3/3 行，A-line 60 条；每条正好 1 个沿：60/60；rail 点数 0
上升沿 1.9262 ~ 1.9326 us，标准差 2.07 ns，峰峰 6.42 ns；MAP 1.0401 ~ 1.0458 V（标准差 1.39 mV）
重读 C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_213044.mat：isequal(raw) = 1，isequal(MAP) = 1
>>
</pasted_content id="416e">

 这个每行几个buffer在哪里哦改77 行么

### 🤖 Claude · 2026-10-15 01:31

> 🔧 Bash · description: Check NX, rpb, postedBuffers settings

### ⚙️ 工具 · 2026-10-15 01:31

<details><summary>工具输出</summary>

```
RUN_HARDWARE       = true; % false：只算时序�
SAVE_DATA          = true;  % true：每行做完�
PAUSE_BETWEEN_ROWS = false;  % true：每行开始
NX                  = 20;      % 每行 A-line 数
NY                  = 3;      % 行数 = Y 方向�
DX_UM               = 10;      % X 像素间距（
DY_UM               = 10;      % Y 像素间距（
ATS.recordsPerBuffer   = 2;       % 每个 DMA buf
ATS.postedBuffers      = 5;     % Inf：每行的
```
</details>

### 🤖 Claude · 2026-10-15 01:31

**不是第 77 行。「每行几个 buffer」不能直接设，是算出来的：**

> 每行 buffer 数 = NX（第 30 行）÷ recordsPerBuffer（第 76 行）

比如 NX = 20、rpb = 2，就是 10 个。要改它，就改第 30 行或第 76 行。

**第 77 行 `postedBuffers` 是另一个意思：** 一次交给板卡几个 buffer。
- `Inf`（默认）：这一行的 buffer 全部预先交出去。今晚之前一直这样用。
- 一个数字，比如你刚改的 **5**：只分配 5 个，用完一个就拷走、再交回去循环用。**这就是 ring buffer。** 打印里「每行 10 个 buffer，一次 Post 5 个」就是这个意思。

顺便的收获：你最后那次（`213044`）其实就是在 ring buffer 模式下跑的，60/60、ctr1 60，没有 ApiBufferOverflow。说明 dual-port 的板载内存在 readwrite 期间接住了数据，循环用 5 个 buffer 也没问题。我会记进 docs/14（6.11 的小规模版）。

**现在先改回来，再按计划跑 6.10：**
1. 第 77 行改回 `ATS.postedBuffers = Inf;`
2. 你跑的 NX = 20 那两次可以当作一个额外的数据点，不浪费。
3. 再跑三次，**每次只改第 30 行和第 76 行**：

| 次 | 第 30 行 NX | 第 76 行 rpb |
|---|---|---|
| A | 10 | 2 |
| B | 50 | 2 |
| C | 200 | 10 |

现在第 20 行是 `true`，所以每次改完可以直接运行。想先看检查模式，就先把它改成 `false`。三次跑完告诉我，第 20 行改回 `false`、第 76 行改回 `2`。

### 🧑 用户 · 2026-10-15 01:36

<pasted_content id="416e">
cscan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 10 个触发、间隔 20 步；X 去程 = 回程 = 1000 步；Y 前进 2 x 20 步后退回；总触发 30；P0.7 全 0：true
K = 20，Ky = 20（Y 未标定时只是假设），fs = 248000，NX = 10，NY = 3，wTrig = 2 行（8.06 us），lead = 25 行
触发 400.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 10 x 3，间距 10.00 x 10.00 um；第一个像素在本行起点 + 200 um；每行 X 走 500 um，Y 共 20 um
ATS：每条 1024 点，每个 buffer 2 条（4096 B），每行 5 个 buffer，一次 Post 5 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.322 s（不含停稳），回程 + Y 表 0.360 s（含 2 次停稳；最后一行 0.350 s），Y 退回表 0.020 s
每行 0.683 s，全程 2.06 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
数据：raw uint16 1024 x 10 x 3 = 61440 B（60.0 kB）

== 8. 上硬件（docs/14 阶段 3–6） ==
【在做什么】循环外准备一次 Dev1、ctr1、ATS；每行 arm → 行扫描 → 取数 → 存盘 → 看停止按钮 → 回程 + Y。
【为什么】DMA buffer 每行重复使用，这一行在电机再动之前就存好；只在行间停，电机不会停在半路，退回距离按累计命令位置算。
数据文件：C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_213400.mat
DO 时钟：设 248000 S/s，实际 248000.0 S/s（不一样的话，所有时长和扫描速度按比例变）
停止按钮只在行与行之间检查：按下后做完当前这一行再停，然后退回起点。不要用 Ctrl+C（不会自动退回）。
第 1/3 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9278 us，脉冲高 1.046 ~ 1.053 V；ctr1 = 10（应为 10）；用时 1.25 s（arm 0.037 / 扫描 0.556 / 取数 0.059 / 存 0.056 / 回程+Y 0.537）
第 2/3 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9280 us，脉冲高 1.048 ~ 1.053 V；ctr1 = 10（应为 10）；用时 1.18 s（arm 0.050 / 扫描 0.501 / 取数 0.050 / 存 0.054 / 回程+Y 0.522）
第 3/3 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9295 us，脉冲高 1.049 ~ 1.054 V；ctr1 = 10（应为 10）；用时 1.31 s（arm 0.041 / 扫描 0.504 / 取数 0.049 / 存 0.057 / 回程+Y 0.655）
回到起点：命令位置 X +0.0 um，Y +0.0 um（应为 0 / 0）；ctr1 全程 30（应为 30）

== 9. 结果（docs/14 6.1、6.3、6.4） ==
【在做什么】汇总每条 A-line 的快速检查，算 MAP；存过盘的话把文件读回来逐点比较。
【为什么】条数、ctr1、计划位置三个数对上，才能说第 k 条记录 = 第 k 个位置；重读一致才说明存的东西能用。
完成 3/3 行，A-line 30 条；每条正好 1 个沿：30/30；rail 点数 0
上升沿 1.9264 ~ 1.9326 us，标准差 1.85 ns，峰峰 6.23 ns；MAP 1.0392 ~ 1.0463 V（标准差 1.47 mV）
重读 C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_213400.mat：isequal(raw) = 1，isequal(MAP) = 1
>>  cscan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 50 个触发、间隔 20 步；X 去程 = 回程 = 1800 步；Y 前进 2 x 20 步后退回；总触发 150；P0.7 全 0：true
K = 20，Ky = 20（Y 未标定时只是假设），fs = 248000，NX = 50，NY = 3，wTrig = 2 行（8.06 us），lead = 25 行
触发 400.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 50 x 3，间距 10.00 x 10.00 um；第一个像素在本行起点 + 200 um；每行 X 走 900 um，Y 共 20 um
ATS：每条 1024 点，每个 buffer 2 条（4096 B），每行 25 个 buffer，一次 Post 25 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.422 s（不含停稳），回程 + Y 表 0.560 s（含 2 次停稳；最后一行 0.550 s），Y 退回表 0.020 s
每行 0.983 s，全程 2.96 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
数据：raw uint16 1024 x 50 x 3 = 307200 B（300.0 kB）

== 8. 上硬件（docs/14 阶段 3–6） ==
【在做什么】循环外准备一次 Dev1、ctr1、ATS；每行 arm → 行扫描 → 取数 → 存盘 → 看停止按钮 → 回程 + Y。
【为什么】DMA buffer 每行重复使用，这一行在电机再动之前就存好；只在行间停，电机不会停在半路，退回距离按累计命令位置算。
数据文件：C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_213432.mat
DO 时钟：设 248000 S/s，实际 248000.0 S/s（不一样的话，所有时长和扫描速度按比例变）
停止按钮只在行与行之间检查：按下后做完当前这一行再停，然后退回起点。不要用 Ctrl+C（不会自动退回）。
第 1/3 行：A-line 50/50，1 个沿 50/50，上升沿中位数 1.9277 us，脉冲高 1.048 ~ 1.054 V；ctr1 = 50（应为 50）；用时 1.54 s（arm 0.040 / 扫描 0.675 / 取数 0.057 / 存 0.054 / 回程+Y 0.712）
第 2/3 行：A-line 50/50，1 个沿 50/50，上升沿中位数 1.9277 us，脉冲高 1.047 ~ 1.054 V；ctr1 = 50（应为 50）；用时 1.46 s（arm 0.040 / 扫描 0.584 / 取数 0.045 / 存 0.055 / 回程+Y 0.735）
第 3/3 行：A-line 50/50，1 个沿 50/50，上升沿中位数 1.9278 us，脉冲高 1.048 ~ 1.055 V；ctr1 = 50（应为 50）；用时 1.45 s（arm 0.048 / 扫描 0.603 / 取数 0.047 / 存 0.056 / 回程+Y 0.697）
回到起点：命令位置 X +0.0 um，Y +0.0 um（应为 0 / 0）；ctr1 全程 150（应为 150）

== 9. 结果（docs/14 6.1、6.3、6.4） ==
【在做什么】汇总每条 A-line 的快速检查，算 MAP；存过盘的话把文件读回来逐点比较。
【为什么】条数、ctr1、计划位置三个数对上，才能说第 k 条记录 = 第 k 个位置；重读一致才说明存的东西能用。
完成 3/3 行，A-line 150 条；每条正好 1 个沿：150/150；rail 点数 0
上升沿 1.9260 ~ 1.9326 us，标准差 1.95 ns，峰峰 6.61 ns；MAP 1.0398 ~ 1.0475 V（标准差 1.62 mV）
重读 C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_213432.mat：isequal(raw) = 1，isequal(MAP) = 1
>> cscan_test

== 3. 换算与检查（docs/14 1.1） ==
【在做什么】把像素数、间距和速度换算成脉冲数和时序表的行数，用 assert 拦住不合法的组合。
【为什么】电机只认整数个脉冲；这些算错了，上硬件时不一定报错，但位置或数据会悄悄错。

== 4. 生成时序表（docs/14 1.2） ==
【在做什么】生成行扫描表（加速 → 匀速 + 触发 → 减速）、回程 + Y 表、Y 退回表；所有行共用同一张行扫描表。
【为什么】硬件执行的就是这些矩阵；表在循环外只算一次，每行的开销就只剩 readwrite 和 ATS arm。

== 5. 逐表检查和计划图（docs/14 1.2、1.3） ==
【在做什么】从表里反推每一行时 X、Y 的位置和每个触发的位置，逐条 assert，再打印时长、画计划图。
【为什么】矩阵错了后面全错；打印的时长就是 6.10 实测时的对照值。
逐表检查通过：每行 200 个触发、间隔 20 步；X 去程 = 回程 = 4800 步；Y 前进 2 x 20 步后退回；总触发 600；P0.7 全 0：true
K = 20，Ky = 20（Y 未标定时只是假设），fs = 248000，NX = 200，NY = 3，wTrig = 2 行（8.06 us），lead = 25 行
触发 400.0 Hz，步频 8000 Hz，扫描 4.00 mm/s；X 回程 2.00 mm/s；Y 1.00 mm/s
像素 200 x 3，间距 10.00 x 10.00 um；第一个像素在本行起点 + 200 um；每行 X 走 2400 um，Y 共 20 um
ATS：每条 1024 点，每个 buffer 10 条（20480 B），每行 20 个 buffer，一次 Post 20 个；CH A IMPEDANCE_50_OHM，TRIG IN ETR_5V
时长：行扫描表 0.797 s（不含停稳），回程 + Y 表 1.310 s（含 2 次停稳；最后一行 1.300 s），Y 退回表 0.020 s
每行 2.108 s，全程 6.33 s（硬件时间下限，不含 readwrite 启动和 ATS arm）
数据：raw uint16 1024 x 200 x 3 = 1228800 B（1200.0 kB）

== 8. 上硬件（docs/14 阶段 3–6） ==
【在做什么】循环外准备一次 Dev1、ctr1、ATS；每行 arm → 行扫描 → 取数 → 存盘 → 看停止按钮 → 回程 + Y。
【为什么】DMA buffer 每行重复使用，这一行在电机再动之前就存好；只在行间停，电机不会停在半路，退回距离按累计命令位置算。
数据文件：C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_213548.mat
DO 时钟：设 248000 S/s，实际 248000.0 S/s（不一样的话，所有时长和扫描速度按比例变）
停止按钮只在行与行之间检查：按下后做完当前这一行再停，然后退回起点。不要用 Ctrl+C（不会自动退回）。
第 1/3 行：A-line 200/200，1 个沿 200/200，上升沿中位数 1.9279 us，脉冲高 1.047 ~ 1.054 V；ctr1 = 200（应为 200）；用时 2.65 s（arm 0.038 / 扫描 1.002 / 取数 0.042 / 存 0.069 / 回程+Y 1.500）
第 2/3 行：A-line 200/200，1 个沿 200/200，上升沿中位数 1.9281 us，脉冲高 1.047 ~ 1.054 V；ctr1 = 200（应为 200）；用时 2.62 s（arm 0.053 / 扫描 0.946 / 取数 0.056 / 存 0.069 / 回程+Y 1.494）
第 3/3 行：A-line 200/200，1 个沿 200/200，上升沿中位数 1.9281 us，脉冲高 1.046 ~ 1.054 V；ctr1 = 200（应为 200）；用时 2.57 s（arm 0.055 / 扫描 0.934 / 取数 0.041 / 存 0.098 / 回程+Y 1.438）
回到起点：命令位置 X +0.0 um，Y +0.0 um（应为 0 / 0）；ctr1 全程 600（应为 600）

== 9. 结果（docs/14 6.1、6.3、6.4） ==
【在做什么】汇总每条 A-line 的快速检查，算 MAP；存过盘的话把文件读回来逐点比较。
【为什么】条数、ctr1、计划位置三个数对上，才能说第 k 条记录 = 第 k 个位置；重读一致才说明存的东西能用。
完成 3/3 行，A-line 600 条；每条正好 1 个沿：600/600；rail 点数 0
上升沿 1.9260 ~ 1.9326 us，标准差 1.89 ns，峰峰 6.68 ns；MAP 1.0399 ~ 1.0475 V（标准差 1.57 mV）
重读 C:\Users\2031\Desktop\Research-PAM\07_MATLAB\cscan_data\cscan_20261014_213548.mat：isequal(raw) = 1，isequal(MAP) = 1
>>
</pasted_content id="416e">

 好了

### 🤖 Claude · 2026-10-15 01:36

> 🔧 Bash · description: Fit per-row time vs NX from the 6.10 data files

### ⚙️ 工具 · 2026-10-15 01:36

<details><summary>工具输出</summary>

```
NX  10 rpb  2: rows [1.245 1.177 1.306]  plan 0.683  scan-plan [0.234 0.178 0.182]
NX  20 rpb  2: rows [1.282 1.264 1.245]  plan 0.758  scan-plan [0.209 0.166 0.151]
NX  20 rpb  2: rows [1.293 1.247 1.223]  plan 0.758  scan-plan [0.216 0.131 0.151]
NX  50 rpb  2: rows [1.539 1.46 1.452]  plan 0.983  scan-plan [0.253 0.162 0.18]
NX 200 rpb 10: rows [2.652 2.619 2.566]  plan 2.108  scan-plan [0.205 0.149 0.137]
measured: 7.40 ms/px, intercept 1.127 s
planned:  7.50 ms/px, intercept 0.608 s
scan overhead mean 0.180 s; arm+collect+save mean 0.156 s
resid std 0.044 s
```
</details>

### 🤖 Claude · 2026-10-15 01:37

> 🔧 Bash · description: Check current settings before wrap-up

### ⚙️ 工具 · 2026-10-15 01:37

<details><summary>工具输出</summary>

```
RUN_HARDWARE       = true; % false：只算�
SAVE_DATA          = true;  % true：每行�
PAUSE_BETWEEN_ROWS = false;  % true：每行�
NX                  = 200;      % 每行 A-li
NY                  = 3;      % 行数 = Y �
DX_UM               = 10;      % X 像素间�
DY_UM               = 10;      % Y 像素间�
ATS.recordsPerBuffer   = 10;       % 每个 D
ATS.postedBuffers      = Inf;     % Inf：每
```
</details>

### 🤖 Claude · 2026-10-15 01:37

**6.10 做完了。** 我从 5 个数据文件里读出每行的计时（NX = 10、20、20、50、200，各 3 行，共 15 个点），拟合「每行时间 = 截距 + 斜率 × NX」：

| | 斜率（每像素） | 截距（每行固定） |
|---|---|---|
| 计划（由时序表算） | 7.50 ms | 0.61 s |
| **实测** | **7.40 ms** | **1.13 s** |

拟合的残差只有 0.04 s，直线拟合得很好。

**怎么理解：**
- **斜率和计划一样**：每多一个像素多 7.5 ms，就是电机多走的时间（扫描 20 步 2.5 ms + 回程 20 步 5 ms）。硬件时序完全按表执行。
- **截距多了约 0.52 s**：这是每行的软件开销，**和行多长无关**（NX = 10 和 NX = 200 时都一样）：
  - 两次 readwrite 的启动，各约 0.18 s；
  - arm + 取数 + 存盘，约 0.16 s。

**3 × 3 mm 推算** [条件计算]：
- Δ = 10 µm（300 × 300）：每行 1.13 + 300 × 7.4 ms ≈ 3.35 s，300 行约 **17 min**。
- Δ = 1 µm（3000 × 3000），回程也提到 4 mm/s：每行约 2.0 s 电机时间 + 0.52 s 开销 ≈ 2.5 s，3000 行约 **2.1 h**。其中光软件开销就占约 26 min。

目标是 30 min，所以 1 µm 的全视场要靠别的办法缩短，比如更快的扫描、提高电流后加速到更高速度、去掉每行一次 readwrite 的开销（改成后台输出）。这适合带去组会讨论。

**阶段 6 到这里都做完了**（6.11 ring buffer 不做；你那次 postedBuffers = 5 的运行算作小规模验证）。

**收工，你做：**
1. `cscan_test.m` 恢复默认：

   | 行 | 改成 |
   |---|---|
   | 20 | `RUN_HARDWARE = false` |
   | 24 | `SAVE_DATA = false` |
   | 30 | `NX = 10` |
   | 31 | `NY = 10` |
   | 76 | `ATS.recordsPerBuffer = 2` |

   第 77 行已经是 `Inf`，不用改。
2. KORAD 关，发生器两路 Output 关，看两条胶带在记号上。

然后告诉我，我来写 docs/14 和工作日志、导出对话、commit。

### 🧑 用户 · 2026-10-15 01:39

好的 你这实验结果和我画的map图和时序图都保留了么

### 🤖 Claude · 2026-10-15 01:39

> 🔧 Bash · description: List saved screenshots and data folder size

### ⚙️ 工具 · 2026-10-15 01:39

<details><summary>工具输出</summary>

```
-rw-r--r-- 1 2031 197121 119030 Oct 14 21:03 14.png
-rw-r--r-- 1 2031 197121 100483 Oct 14 21:06 15.png
-rw-r--r-- 1 2031 197121 262315 Oct 14 21:06 16.png
-rw-r--r-- 1 2031 197121 116509 Oct 14 21:12 17.png
-rw-r--r-- 1 2031 197121 199608 Oct 14 21:23 18.png
-rw-r--r-- 1 2031 197121 141183 Oct 14 21:25 19.png
-rw-r--r-- 1 2031 197121 139523 Oct 14 17:19 2.png
-rw-r--r-- 1 2031 197121 123710 Oct 14 21:31 20.png
-rw-r--r-- 1 2031 197121 106012 Oct 14 21:31 21.png
-rw-r--r-- 1 2031 197121  75549 Oct 14 21:36 22.png
-rw-r--r-- 1 2031 197121  92170 Oct 14 21:36 23.png
-rw-r--r-- 1 2031 197121  662
…[截断，共 1193 字符]
```
</details>

### 🤖 Claude · 2026-10-15 01:39

简单说：**数据都在，图没有单独存，但都能还原；你发给我的截图我会存进 docs。**

| 东西 | 现在在哪 | 保留情况 |
|---|---|---|
| **实验数据** | `07_MATLAB\cscan_data\`，23 个 `.mat`，共 6.3 MB | ✔ 都在。里面有 raw、MAP、上升沿、每行 ctr1、计时、全部参数。⚠ 这个文件夹**不进 git**，只在这台实验室电脑上，Mac 上看不到 |
| **MAP 图** | MATLAB 没有自动存图 | 可以还原：设 `REPLOT_FILE = '…\cscan_xxx.mat'`，再运行 `cscan_replot`，就能从数据重画 |
| **计划图 / 时序图** | 没有存 | 可以还原：同样的参数跑一次检查模式就会重画（它是从参数算出来的，不是测出来的） |
| **你发给我的截图和照片** | 我这边有 | 收工时我放进 `docs/screenshots`，会进 git |

收工时我会存进 docs/screenshots 的截图：
- 6.4 重读；
- 6.5 第 3 行暗线；
- 6.6 停在第 2 行；
- 6.2 的 2 mm × 2 mm 图，和两张钢尺照片；
- 6.9 的 20 × 5；
- 6.10 的 NX = 10 / 50 / 200。

你停在第 4 行那张截图（6.6）在我这边没有存下文件，那次的数据文件 `cscan_20261014_210705.mat` 还在，可以用它重画。

**要你定一件事：数据要不要也放进 git，让 Mac 上也能看？**
- **放几份关键的（推荐）**：约 2 MB。5.1 第一次 10 × 10、6.5 暗线、6.2 的 2 mm、6.10 的 NX = 200，复制到 `docs/data/` 下面。
- **都不放**：数据只留在实验室电脑，自己拷 U 盘或网盘。

你选一个，然后告诉我 `cscan_test.m` 改回默认、KORAD 和发生器关好了没有，我就开始收工。

### 🧑 用户 · 2026-10-15 01:42

放几份关键的，代码改回默认了，都关好了

### 🧑 用户 · 2026-10-15 01:42

[Request interrupted by user]
