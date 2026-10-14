---
session: 39c1b058-7d7e-4e2f-b00b-4222fef61888
title: Pre-lab briefing + guidance: Y axis and B-scan
machine: LabPC
source: 39c1b058-7d7e-4e2f-b00b-4222fef61888.jsonl
exported: 2026-10-14 14:26
---

# Pre-lab briefing + guidance: Y axis and B-scan


### 🧑 用户 · 2026-10-14 13:35

这个窗口只做一个模块：今天（2026-10-14 周三）实验前的讲解 + 现场指导，内容是「Y 轴」和「B-scan 巩固」。对应 `06_控制程序/docs/14_C-scan测试流程.md` 的阶段 0、阶段 2（含 2.6）和阶段 3.1。C-scan 本身（cscan_test.m）不在这里做，另有「C-scan module」窗口。

重要：用户的 MATLAB 从主目录 `C:\Users\2031\Desktop\Research-PAM\07_MATLAB` 运行。本窗口如果开在 `.claude\worktrees\...` 里，读写用户要用的文件和 docs 一律用主目录的绝对路径；不要只改 worktree 里的副本。

开工先做（按 Research-PAM 根目录 CLAUDE.md）：
1. 提醒用户先双击 `C:\Users\2031\Desktop\Research-PAM\sync_pam.cmd`（已双击过就 `git pull`）。
2. 读主目录 `06_控制程序/docs/工作日志.md` 最后 3 条、docs/14 阶段 0/2/3、docs/13 §1–3.3（B-scan 接线、发生器设置、结果）、docs/01（硬件）、`07_MATLAB/bscan_test.m`、`07_MATLAB/test2.m`。

用户的要求：在做任何现场实验之前，先让他了解四件事——
(1) 大致流程：今天按什么顺序做、每一步在做什么、为什么；
(2) 预期结果：每一步看到什么数才算通过；
(3) 设定的参数：每个参数的值、单位、含义、在哪一行；
(4) 要用的代码：用哪个文件、改哪几行、怎么切换检查模式和硬件模式。
先讲，再现场一步步带。协作方式：教，不替用户做——用户自己改 MATLAB（例如 test2.m 的 Y 版、bscan_test.m 第 37 行），你给 `文件:行号` 和检查清单；硬件脚本默认 `RUN_HARDWARE = false`，用完改回。用户说学习方法（白纸回忆）暂时先别用。

已确认的事实（不用再查）：
- X：P0.0 STEP−、P0.1 DIR−，共阳极；0.5 µm/脉冲（4000 步/转、导程 2 mm）；不加速 ≤4 mm/s，5 mm/s 起步失步；X 端到端约 27 圈 ≈ 54 mm，中间 = 从一端回摇 13.5 圈。
- Y：用户 10/13 看线确认 P0.2 → Y STEP−、P0.3 → Y DIR−，和 X 一样共阳极。还没做：通电静态检查（写 0 时 Y 的 STEP− 约 0 V，X、Z 不变）、拨码、µm/脉冲、方向、行程。Y 上没装东西；水槽托盘在 Z 上；Y 前后约 15 cm（用户估计）——和 X 的 CXPF50（50 mm）不同，可能是别的型号，导程和 µm/脉冲不能沿用 X，先看铭牌再改 test2 Y 版第 24–25 行的每转步数，然后才走第一步；拨码读不清就先用约 200 Hz 的低步频。
- 用户 10/13 同意：bscan_test.m 第 37 行 `MAX_SPEED_MM_S` 由用户自己从 20 改成 4（test2 Y 版第 26 行也建议改成 4）；量位置用手轮记号 + 卡尺（手轮一圈 2 mm，1° ≈ 5.6 µm）。
- 触发链：P0.6 → BNC-2110 USER 1 → DG852 背面 AUX → G1 → 示波器 CH2 + ATS TRIG IN；G2 → 示波器 CH3 + CH A；USER 1 端子并线到 PFI3（ctr1 数 P0.6）。发生器按 docs/13 §2 逐项设（CH1 Square 100 kHz 2 Vpp Offset 1 V；CH2 Square 2.5 MHz 1 Vpp Offset 0.5 V Delay 2 µs；Burst NCycle 1、Ext Leading、Idle Bottom、Load、Sync Off、Trig Out Off）；不要 Recall `PAM_bscan`（那是 1.5 Vpp 误读时存的旧版）。示波器各通道 Probe 1X。
- 阻抗：CH A 能在代码里设（bscan_test.m:260），TRIG IN 不能（实测 50.2 Ω）。dual-port：NPT AutoDMA 本身就是 dual-port。会上说的「约 3 秒卡住」是 readwrite 阻塞，不是报错。
- B-scan 默认参数：800 Hz、Δx 5 µm、4 mm/s、DO 时钟 248 kS/s、1024 点、rpb 50、8 个 buffer。

今天的预期结果（讲解时用，也是通过标准）：
- 2.2 静态检查：写 0 时 Y 的 STEP−、DIR− 约 0 V；X、Z 不变。
- 2.3 小步：+200 µm、1 mm/s，只有 Y 动；记下 MOVE_UM > 0 时 Y 朝哪边。
- 2.4 标定：如果 Y 也是 4000 步/转、导程 2 mm，20000 脉冲 = 5 圈 = 10 mm；ctr1 = 20000（计数时 PFI3 临时挪到 P0.2，测完接回 USER 1）。
- 2.5 速度：1–4 mm/s 往返回到记号（±5°）。
- 2.6：PFI3 接回 USER 1；只让 Y 走时 ctr1 = 0；bscan_test.m 原样跑 400 条：ctr1 = 400、400/400、rail 0、每条 1 个沿、上升沿约 1.927–1.933 µs、标准差约 2 ns、脉冲高约 1.05 V；X 回到记号。
- 3.1：bscan_test.m 设 DX_UM = 10、TRIG_RATE_HZ = 400、SCAN_LENGTH_UM = 100、recordsPerBuffer = 2 → Nx = 10、5 个 buffer，ctr1 = 10、10/10。跑完把参数改回默认。

拍照清单：Y 滑台铭牌、Y 驱动器标签（序列号、电流表）、Y 拨码 SW1–12、BNC-2110 上 P0.2/P0.3 的孔、Y 驱动器 STEP−/DIR−/+5 V 接线、Z 上的水槽托盘和周围空间。照片放 `06_控制程序/docs/screenshots/`（主目录），要点写进 docs/01（Y 接线表、拨码、µm/脉冲、方向、行程）和 docs/14 末尾的实测记录。

Rui：用户已经给 Rui 发了消息。建议他周五（10/16）来看 10 × 10；如果他今天来，可以给他看现场 B-scan（触发链 + 400/400 + ctr1）和 Y 轴结果，并当面问「行内用匀速扫还是 step-and-settle」（他书面 Phase 1 计划第 30 行写的是 step-and-settle）。

收工：工作日志（主目录）加一条：做了什么 / 结果 / 下次第一步；新事实写进 docs/01、docs/14；按 CLAUDE.md 导出本次对话、commit 到 main（在主目录提交，或把 worktree 分支合并进 main），然后提醒用户双击 sync_pam.cmd。收工前确认 bscan_test.m、test2.m 都是 `RUN_HARDWARE = false`，SR2 断电。

### 🤖 Claude · 2026-10-14 13:36

先读材料。主目录路径：`C:\Users\2031\Desktop\Research-PAM`。

### 🤖 Claude · 2026-10-14 13:36

> 🔧 Bash · description: Check main repo status and read worklog tail

### 🤖 Claude · 2026-10-14 13:36

> 🔧 Glob · pattern: 06_控制程序/docs/*.md

### ⚙️ 工具 · 2026-10-14 13:36

<details><summary>工具输出</summary>

```
56be758 2026-10-13 C-scan: docs/14 写入用户对「还要确认的」的回答；Y 接线看线确认（docs/01、14）
3a82166 Merge remote-tracking branch 'origin/main'
5ac8b5b 2026-10-13 C-scan: docs/14 测试流程（workflow 调查 + 复核）；补正采集方式与「约3s卡住」出处
e56aab4 2026-10-13 对话记录: 从旧 PAM_research 补入较新的 LabPC Claude 记忆（5 个文件）
4cbe841 Merge remote-tracking branch 'origin/main'
---
�§19.3 dual-port 和阻抗待办、§20.1 采集方式和 trigger 频率、§20.2 TRIG IN；头部改 v1.2）、`PAM学习进度.md`（K3/K4、research-rui-1012 的核对和待确认，加一条历史）。另外查了 SDK 指南、SDK 自带 MATLAB/Python 示例和 bscan_test.m。
- 结果：
  - **阻抗：CH A 可以在代码里设（`AlazarInputControlEx`，bscan_test.m:260，`IMPEDANCE_50_OHM` ↔ `IMPEDANCE_1M
…[截断，共 3824 字符]
```
</details>

### ⚙️ 工具 · 2026-10-14 13:36

<details><summary>工具输出</summary>

```
C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\02_LabVIEW程序地图.md
C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\03_写法对照.md
C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\04_四周计划.md
C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\05_参数字典.md
C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\06_现有代码与进度.md
C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\07_Four_Week_Plan_EN.md
C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\07_给导师的四周计划.md
C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\08_我的LabVIEW清单.md
C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\09_两天冲刺清单_1003-1004.md
C:\Users\2031\Desktop\R
…[截断，共 1106 字符]
```
</details>

### 🤖 Claude · 2026-10-14 13:36

> 🔧 Bash · description: Count lines and list docs/14 headings

### ⚙️ 工具 · 2026-10-14 13:36

<details><summary>工具输出</summary>

```
331 06_控制程序/docs/14_C-scan测试流程.md
  197 06_控制程序/docs/13_B-scan记录.md
   95 06_控制程序/docs/01_硬件与接线.md
  327 07_MATLAB/bscan_test.m
  105 07_MATLAB/test2.m
 1055 total
1:# 14 C-scan 测试流程（测试信号版，第一版 10 × 10）
8:## 先定的两件事
16:## 安全（每次上硬件都适用）
27:## 附 A　第一版 10 × 10 的参数 [条件计算]
51:## 附 B　如果行内改成 step-and-settle
58:## 阶段 0　开工检查
94:## 阶段 1　离线检查模式（不碰硬件，Mac 上也能做）
132:## 阶段 2　Y 轴（照 X 轴的做法，docs/07 第 1 周 1.2）
180:## 阶段 3　单行 C-scan = B-scan 回归
195:## 阶段 4　两行（Rui 来看可以从这里开始）
215:## 阶段 5　10 × 10
224:## 阶段 6　测试（07 第 3 周 ①–⑥ + 加做）
303:## 阶段 7　收尾和记录
317:## 还要和你（或 Rui）确认的
Shell cwd was reset to C:\Users\2031\Desktop\Resea
…[截断，共 645 字符]
```
</details>

### 🤖 Claude · 2026-10-14 13:36

> 🔧 Read · file_path: C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\14_C-scan测试流程.md

### ⚙️ 工具 · 2026-10-14 13:36

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
…[截断，共 16288 字符]
```
</details>

### 🤖 Claude · 2026-10-14 13:36

> 🔧 Read · file_path: C:\Users\2031\Desktop\Research-PAM\07_MATLAB\bscan_test.m

### ⚙️ 工具 · 2026-10-14 13:36

<details><summary>工具输出</summary>

```
1	%% B-scan：X 滑台匀速扫描 + 激光触发 + ATS9462 每个触发采一条 A-line
2	%
3	%  原理（全部由 Dev1 同一个硬件时钟产生，严格同步）：
4	%    P0.0 X STEP   ：加速 → 匀速 → 减速（→ 可选自动返回起点）
5	%    P0.1 X DIR    ：扫描方向，返回时翻转
6	%    P0.6 DAQ 触发 ：匀速段内每走 K 个脉冲（= DX_UM）发一次 → ATS9462 TRIG IN 采一条 A-line
7	%    P0.7 激光触发 ：与 DAQ 触发同一时刻（LASER_ENABLE = false 时不发）
8	%  因为触发是按"走了多少步"来发的，每条 A-line 的位置都正好间隔 DX_UM，不会出现 6.25 这类非整数关系。
9	%
10	%  先用 RUN_HARDWARE = false 检查时序和位置图；
11	%  再用 RUN_HARDWARE = true、LASER_ENABLE = false 测通 电机 + ATS 采集（采到的是无激光背景）；
12	%  最后确认激光安全后再 LASER_ENABLE = true。
13	%  运行前关闭 LabVIEW 和其他占用 Dev1 / ATS9462 的程序；滑台留出 扫描长度 + 2 x 加速距离 的余量。
14
…[截断，共 13166 字符]
```
</details>

### 🤖 Claude · 2026-10-14 13:36

> 🔧 Read · file_path: C:\Users\2031\Desktop\Research-PAM\07_MATLAB\test2.m

### ⚙️ 工具 · 2026-10-14 13:36

<details><summary>工具输出</summary>

```
1	%% 步进电机移动测试：Dev1 数字线输出 STEP/DIR → 鸣志 SR2 驱动器 → 卓立汉光 CXPF50-80100 电动滑台
2	%
3	%  原理：SR2 在 STEP 线的每个下降沿走一步（一个微步）；DIR 线高/低决定方向。
4	%        移动距离 = 脉冲数 × 每个脉冲的距离；速度 = 脉冲频率 × 每个脉冲的距离。
5	%        脉冲由采集卡按硬件时钟产生，个数和间隔是精确的。
6	%
7	%  CXPF50-80100：行程 50 mm，丝杠导程 2 mm，电机 200 整步/转 → 整步 10 um，最大速度 20 mm/s
8	%
9	%  使用前必须确认：
10	%   1. SR2 拨码开关的细分（每转步数），算出 UM_PER_PULSE
11	%   2. 滑台在行程中间，留有余量；已关闭占用 Dev1 的 LabVIEW 程序；激光处于安全状态
12	
13	RUN_HARDWARE = false;              % false：只计算并画图；确认无误后再改成 true
14	COUNT_CHECK  = false;              % true：用 ctr1 实测发出的脉冲数，需先用导线把 P0.0 并接到 P1.3 (PFI3)
15	
16	%% 1. 每次移动只改这两行
17	MOVE
…[截断，共 4396 字符]
```
</details>

### 🤖 Claude · 2026-10-14 13:36

> 🔧 Read · file_path: C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\01_硬件与接线.md

### ⚙️ 工具 · 2026-10-14 13:36

<details><summary>工具输出</summary>

```
1	# 01 硬件与接线
2	
3	状态标记：✔ 已确认（实测或驱动查询）　◐ 有文字依据，实物未核对　? 待确认
4	
5	## 电脑和软件
6	| 项目 | 内容 | 状态 |
7	|---|---|---|
8	| 电脑 | 实验室 PC "CAOLAB1"（MSI Codex R2，i5-14400F，64 GB，Windows 11） | ✔ |
9	| 账户 | 现在用 `2031` 账户。LabVIEW 原程序最初在 `CAO LAB` 账户的 Downloads，已复制到 `PAM_controlProgram\LabviewPAM\` | ✔ |
10	| NI 软件 | NI-DAQmx 24.5、NI MAX、LabVIEW 2021–2024 | ✔ |
11	| MATLAB | R2024b + Data Acquisition Toolbox；NI-DAQmx 支持包在 CAO LAB 账户下装好并测试过 | ✔（2031 账户下先运行 `daqlist("ni")` 确认） |
12	| Alazar | ATS-SDK 23.3.0（`C:\AlazarTech\ATS-SDK\23.3.0`），ATS-VI 6.3.0 | ✔ |
13	
14	## 采集和控制设备
15	| 设备 | 要点 | 状态 |
16	|---|---|---|
17	
…[截断，共 9328 字符]
```
</details>

### 🤖 Claude · 2026-10-14 13:36

> 🔧 Read · file_path: C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\13_B-scan记录.md

### ⚙️ 工具 · 2026-10-14 13:36

<details><summary>工具输出</summary>

```
1	# 13 B-scan 测试记录（07 第 2 周：测试信号版）
2	
3	## 一句话
4	10/6 晚–10/7 凌晨：找到并量了 P0.6，定了触发链路（P0.6 → 发生器外触发 → TRIG IN + 测试脉冲 → CH A），`bscan_test.m` 第一次真正采到 B-scan：滑台 4 mm/s 移动、400 条、每条都有测试脉冲且位置一致（标准差 1.84 ns）。给导师的图：`docs/figures/bscan_test_20261007.png`。
5	
6	## 1 接线（10/7 测试用，激光不接）
7	```
8	NI P0.6 ─ 蓝线 ─ BNC-2110 端子 USER 1 ─ 面板 USER 1 BNC ─ 三通（示波器 CH1）─ 三通（发生器背面 CH1 AUX IN/OUT）─ 发生器背面 CH2 AUX IN/OUT
9	发生器 G1（CH1 输出）─ 三通（示波器 CH2）─ ATS9462 TRIG IN
10	发生器 G2（CH2 输出）─ 三通（示波器 CH3）─ ATS9462 CH A
11	```
12	- P0.6 原来的蓝线另一头是空的（10/6 晚确认），现在插在 BNC-2110 上排 USER 1 端子（D GND 右边一个，`HW_BNC2110_P06_in_USER1.jpg`）。
13	- DG8
…[截断，共 13555 字符]
```
</details>

### 🤖 Claude · 2026-10-14 13:36

> 🔧 Read · file_path: C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\13_B-scan记录.md

### ⚙️ 工具 · 2026-10-14 13:36

<details><summary>工具输出</summary>

```
120	  每次 ctr1 = 400，400/400，rail 0，脉冲高 1.046–1.062 V。
121	- **结论：今天的条件下复现不出约 10 ns 的跳变**——不动发生器、关开 Output、重输 Ampl、改 Ampl 再改回，G1→G2（示波器）和 ATS 上升沿都不变（变化 < 0.1 ns / 示波器 5 ns 一档以内）。所以"改 Ampl 会让发生器两路延迟变"这个推测不成立。以前的两次跳变都还没有解释（待确认）：10/7 凌晨 → 晚上早了约 9.5 ns（中间隔了很久，可能重启过电脑或发生器）；§3.2 那次早了约 12 ns，正好发生在**连续两次超时（漏触发、`AlazarAbortAsyncRead`）之后**的第一次运行，之后又回到 1.9264 µs。新线索（待验证）：ATS 在一次超时/中止之后，触发点可能会偏一次。验证办法：拔掉 TRIG IN 故意超时一次（测试 ⑤），插回后连跑 2–3 次，看上升沿是否变。
122	
123	## 4 07 第 2 周 6 项测试的进度
124	| 测试 | 状态 |
125	|---|---|
126	| ① 记录数 = 位置数，每条都有测试脉冲 | ✔ 50 条、400 条、200 条；10/7 晚加了 ctr1 计数：P0.6 正好 200 个沿 |
127	| ② 量最终位置 = 起点 
…[截断，共 6624 字符]
```
</details>

### 🤖 Claude · 2026-10-14 13:36

> 🔧 Bash · description: List hardware screenshots and MATLAB folder

### ⚙️ 工具 · 2026-10-14 13:36

<details><summary>工具输出</summary>

```
HW_5V_wago_STEPplus.jpg
HW_BNC2110_P06_in_USER1.jpg
HW_BNC2110_bnc_adapter.jpg
HW_BNC2110_bnc_adapter_2.jpg
HW_BNC2110_terminals.jpg
HW_BNC2110_terminals_2.jpg
HW_BNC2110_terminals_3.jpg
HW_BNC2110_terminals_motor.jpg
HW_BNC2110_wago_ground.jpg
HW_DG852_burst_settings_1007.jpg
HW_SR2_DB9_loose_wires.jpg
HW_SR2_SW9-12.jpg
HW_SR2_X_label_tables.jpg
HW_SR2_X_label_wiring.jpg
HW_SR2_control_wiring.jpg
HW_SR2_terminal_face_SW1-8.jpg
HW_SR2_terminal_face_SW1-8_clear.jpg
HW_X_stage_ruler.jpg
HW_laser_NPL45C_back.jpg
HW_laser_NPL45C_label.jpg
HW_motor_SST43D2126_1.jpg
HW_motor_SST43D2126_2.jpg
HW_moto
…[截断，共 1066 字符]
```
</details>

### 🤖 Claude · 2026-10-14 13:38

> 🔧 Read · file_path: C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\screenshots\HW_SR2_X_label_tables.jpg

### 🤖 Claude · 2026-10-14 13:38

> 🔧 PowerShell · description: Check whether MATLAB is installed

### ⚙️ 工具 · 2026-10-14 13:38

<details><summary>工具输出</summary>

```
[图片]
```
</details>

### ⚙️ 工具 · 2026-10-14 13:38

<details><summary>工具输出</summary>

```
C:\Program Files\MATLAB\R2024b\bin\matlab.exe

Name  
----  
R2024b
```
</details>

### 🤖 Claude · 2026-10-14 13:39

> 🔧 Bash · description: Create check-mode copies of scripts in scratchpad

### ⚙️ 工具 · 2026-10-14 13:39

<details><summary>工具输出</summary>

```
10:%  先用 RUN_HARDWARE = false 检查时序和位置图；
11:%  再用 RUN_HARDWARE = true、LASER_ENABLE = false 测通 电机 + ATS 采集（采到的是无激光背景）；
15:RUN_HARDWARE    = false;   % false：只生成时序并画图，不碰任何硬件
22:SCAN_LENGTH_UM    = 100;  % B-scan 长度
23:DX_UM             = 10;    % A-line 间距（必须是 UM_PER_PULSE 的整数倍）
24:TRIG_RATE_HZ      = 400;  % 激光 / 采集触发频率 = 每秒 A-line 数；扫描速度 = DX_UM x TRIG_RATE_HZ
37:MAX_SPEED_MM_S = 4;
51:ATS.recordsPerBuffer  = 2;         % 每个 DMA buffer 的 A-line 数
150:if ~RUN_HARDWARE
151:    fprintf('\n*** 检查模式：没有向硬件发送任何信号。确认无误后把 RUN_HARDWARE 改成 true ***\n');
13:RUN_HARDWARE = false;              % false：只计算并画图
…[截断，共 1073 字符]
```
</details>

### 🤖 Claude · 2026-10-14 13:39

正在用 MATLAB 跑副本的检查模式（只算时序、不碰硬件），拿到准确的预期打印值后就开始讲解。

### 🤖 Claude · 2026-10-14 13:39

> 🔧 PowerShell · description: Run check-mode copies in MATLAB batch mode

### ⚙️ 工具 · 2026-10-14 13:39

<details><summary>工具输出</summary>

```
===== b_default =====
A-line  400 5.00 um 5.00 ~ 5.00 umB-scan  2.00 mm
 4.00 mm/s 8000 Hz 800 HzDO  248000 S/s
 2.40 mm 2.32 s +0.0 umfalse

***  RUN_HARDWARE  true ***

===== b_31 =====
A-line  10 10.00 um 10.00 ~ 10.00 umB-scan  0.09 mm
 4.00 mm/s 8000 Hz 400 HzDO  248000 S/s
 0.50 mm 0.90 s +0.0 umfalse

***  RUN_HARDWARE  true ***

===== t2_200 =====
 400 2000.0 Hz 0.200 s
 DIR = 1 +200.0 um 1.000 mm/s 4 mm/s

**
…[截断，共 1164 字符]
```
</details>

### 🤖 Claude · 2026-10-14 13:42

开工前请先双击 `C:\Users\2031\Desktop\Research-PAM\sync_pam.cmd`（已经双击过就告诉我，我来 `git pull`）。我已经读完：工作日志最后 3 条、docs/14 阶段 0/2/3、docs/13 §1–3.3、docs/01、`bscan_test.m`、`test2.m`。主目录在 main 分支，没有未提交的改动。

下面的预期打印值是我在 scratchpad 里拿**副本**跑检查模式得到的［条件计算］，你的文件一行没动。所有文件都在 `C:\Users\2031\Desktop\Research-PAM\07_MATLAB`。

---

## 一、今天的顺序

| # | 步骤 | 在做什么 / 为什么 | SR2 | PFI3 并线接在 |
|---|---|---|---|---|
| 1 | 0.1 开工检查 | 确认用的是主目录的代码，Dev1/ATS 没被占用 | 断 | USER 1 |
| 2 | 0.4 + 2.1 | X 摇到中间；看 Y 铭牌、拨码，拍照，给两个手轮贴记号。µm/脉冲 要靠铭牌和拨码算出来 | 断 | USER 1 |
| 3 | 2.2 静态电平 | 用电确认 P0.2/P0.3 真的接在 Y 上，不是 Z，免得一动就撞别的轴 | 断 | USER 1 |
| 4 | 0.2/0.3 | 示波器设 1X，发生器逐项设好。2.6 要用这条触发链 | 断 | USER 1 |
| 5 | 上电 | KORAD 23.88 V、C.V 模式，驱动器绿灯闪 | **通** | USER 1 |
| 6 | 2.3 小步 | +200 µm：先确认动的是 Y，再定方向，顺便初查拨码 | 通 | USER 1 |
| 7 | 2.4 标定 | ±10 mm × 3 次：圈数验证每转步数，卡尺验证导程，ctr 验证脉冲数 | 通 | **P0.2** |
| 8 | 2.5 速度 | 1–4 mm/s 往返，看 Y 会不会起步失步 | 通 | **P0.2** |
| 9 | 2.6 | 并线接回 USER 1 → 查串扰 → 跑 B 默认参数作为回归基准 | 通 | USER 1 |
| 10 | 3.1 短行 | 用 B 只改参数，证明「短行 + 小 buffer」能收齐 | 通 | USER 1 |
| 11 | 收尾 | 开关改回、断电、写记录 | 断 | USER 1 |

可选：第 5 步之后先跑一次 B 当「开工基准」。台架和 Maria 共用，这样能把「别人动过线」和「我的 Y 改动弄坏了」分开。你到时候决定跑不跑。

---

## 二、每一步：参数、代码、预期

### 0.1 开工检查
- 关掉 LabVIEW 和 Python。MATLAB 里运行 `cd C:\Users\2031\Desktop\Research-PAM\07_MATLAB`，再用 `which bscan_test` 和 `which test2` 确认指向这个路径（不是旧的 PAM_controlProgram）。
- 通过：`bscan_test.m:15` RUN_HARDWARE = false、`:16` LASER_ENABLE = false、`:19` COUNT_CHECK = true；`test2.m:13` = false。

### 0.4 + 2.1（SR2 断电）
- X：摇到一端轻轻顶住，回摇 13.5 圈，手轮贴记号。
- Y：先看铭牌，记下型号、行程、导程。今天 Y 最远单向走 10 mm，两边各留 ≥ 10 mm 就够，不用精确摇到中间。贴记号。
- 读 Y 拨码时对照 SR2 标签上的表（ON 的方向 = 箭头指向数字的一侧）：
  - SW1–3 设电流。X 是 ON ON ON = 0.3 A。
  - SW4：ON = 空闲半电流。
  - SW5–8 设细分。**ON OFF ON OFF = 4000 步/转**（X 就是这样）。反着读会变成 OFF ON OFF ON = 6400，这是最容易踩的坑。
- 写进 `test2_Y.m`：
  - 第 24 行 `STEPS_PER_REV = <每转步数>;`
  - 第 25 行 `UM_PER_PULSE = <导程 µm> / STEPS_PER_REV;`。原来的 2000 是 X 的 2 mm 导程，Y 以铭牌为准。
- 拨码读不清：先按 4000 步/转、2 mm 导程写，2.3 的速度改用 0.1 mm/s（200 Hz），用手轮读数反推。

### 2.2 静态电平（SR2 断电也能测）
- 原理：共阳极接法下，STEP+ 接 BNC-2110 的 +5 V。P0.2 写 0 时光耦 LED 导通，STEP− 被拉到约 0 V。线没接上时，STEP− 会经过 LED 被拉向 +5 V，看起来也是「高」。所以**只有「写 0 时约 0 V」能证明线接对了**。LED 这一侧的电来自 NI，不来自 KORAD，所以 SR2 断电也能测。
- 代码（命令行里敲）：
  ```matlab
  d = daq("ni"); addoutput(d,"Dev1","port0/line2","Digital");
  write(d,0)   % 量 Y STEP−
  write(d,1)   % 再量
  write(d,0)
  clear d
  ```
  然后把 `line2` 换成 `line3`，同样量 Y DIR−。
- 万用表打 DC V 档：黑表笔接 BNC-2110 的 D GND，红表笔接 SR2(Y) 的 STEP− 螺丝。
- 通过：写 0 时约 0 V，写 1 时约 5 V；X、Z 的 STEP− 读数在翻转前后不变。
- 失败：写 0 时还是 4–5 V，说明端子可能插在相邻的孔里，先停下查线。

### 2.3 小步（`test2_Y.m`）
- 在 MATLAB 里把 `test2.m` 另存为 `test2_Y.m`，原来的 `test2.m` 不动。

| 行 | 改成 | 含义 |
|---|---|---|
| 13 | `false`（先跑检查模式） | 硬件开关 |
| 14 | `false` | 计数开关，这一步不用 |
| 17 | `200` | MOVE_UM，单位 µm |
| 18 | `1`（拨码不清用 `0.1`） | SPEED_MM_S，单位 mm/s |
| 21 / 22 | `"port0/line2"` / `"port0/line3"` | Y 的 STEP / DIR |
| 23 | `1`，不改 | 方向以实测为准 |
| 24 / 25 | 按 2.1 填 | 每转步数、µm/脉冲 |
| 26 | `4` | MAX_SPEED_MM_S |
| 27 | `1000` | 单次最多走 1 mm，防止打错数字 |

- 检查模式应打印：`脉冲数 400，实际频率 2000.0 Hz，用时 0.200 s` 和 `方向 DIR = 1，预计移动 +200.0 um，速度 1.000 mm/s（上限 4 mm/s）`。用 0.1 mm/s 时是 `200.0 Hz，2.000 s`。
- 然后第 13 行改 `true` 再跑，眼睛盯着三台滑台。
- 通过：只有 Y 动；手轮转约 **36°**（400 脉冲 ÷ 4000 步/转 = 0.1 圈）。
- 手轮角度能直接反推拨码：22.5° → 6400 步/转，72° → 2000，90° → 1600。角度不是 36° 就先停下，改第 24 行，**再进 2.4**。
- 记下 MOVE_UM > 0 时 Y 往哪走（朝电机还是远离电机；以人站的位置算朝前还是朝后）。然后 MOVE_UM = −200 走回来。

### 2.4 标定（PFI3 并线挪到 P0.2）
- 把并线从 USER 1 端子拔下，插进 P0.2 端子，和 Y STEP 那根线挤在同一个孔里。两根都拧紧、轻拉一下确认不松。
- 改 `test2_Y.m`：第 14 行 `true`、第 27 行 `10000`、第 17 行 `+10000` 和 `−10000` 轮流、第 18 行 `1`。
- 每次应打印：`脉冲数 20000，实际频率 2000.0 Hz，用时 10.000 s` 和 `ctr1 实测上升沿：20000（应为 20000）`。
- 通过（前提是 4000 步/转、2 mm 导程）：手轮正好 **5 圈**，卡尺约 **10.0 mm**，最后回到记号。
- 三个数各查一件事：
  - **ctr** 查脉冲有没有真的从卡发出去。
  - **圈数**查拨码（第 24 行）。
  - **mm** 查导程（第 25 行）。
- 每次记一行：MOVE、ctr、圈数、卡尺读数、量的是哪个面。正反各 3 次，共 6 行。

### 2.5 速度（并线仍在 P0.2）
- 第 18 行依次设 `1`、`2`、`3`、`4`，每个速度 ±10000 往返一次。4 mm/s 时打印 `20000，8000.0 Hz，2.500 s`。
- 通过：每次 ctr = 20000，手轮回到记号 ±5°（约 ±28 µm）。4 mm/s 通过就停，不往上试。
- **失步的样子：ctr 还是 20000，但手轮只转了一点、声音变大。** 这说明脉冲都发出去了，是电机没跟上。
- docs/14 2.5 后半段「连走 9 次 Δy」要用 cscan_test 的时序表，今天不做，留给 C-scan 窗口。

### 2.6 并线接回 + 串扰检查 + B 基准
1. 并线插回 **USER 1 端子**。
2. `test2_Y.m` 计数开着，以 4 mm/s ±10000 走一次。应看到 `ctr1 实测上升沿：0`。后面括号里的「应为 20000」这次不对，忽略：ctr1 现在数的是 P0.6，Y 走的时候它应该是 0。不是 0 的话，先记下数字和当时动了什么，别急着改线。做完第 13 行改回 `false`。
3. B：你自己把 `bscan_test.m:37` 改成 `MAX_SPEED_MM_S = 4;`。检查模式应打印：
   ```
   A-line 数 400，间距 5.00 um（实际 5.00 ~ 5.00 um），B-scan 长度 2.00 mm
   扫描速度 4.00 mm/s，步频 8000 Hz，触发 800 Hz，DO 采样率 248000 S/s
   总行程 2.40 mm，总用时 2.32 s，结束位置 +0.0 um，激光触发：false
   ```
4. 第 15 行改 `true` 跑一次，然后改回 `false`。硬件模式应打印：`ctr1 … 400（应为 400）`、`rail 点数 0`、`每条正好 1 个沿：400/400；异常的列：zeros(1,0)`；上升沿约 1.927–1.933 µs，标准差约 2 ns，峰峰约 6.3 ns；脉冲高约 1.05–1.06 V（docs/13 §3.3 [实测]）。示波器上：CH1 约 4.3 V、8.06 µs；CH2 Top 约 1.96 V；CH3 约 1 V、200 ns。X 回到记号。
5. 上升沿的绝对时间重设发生器后可能整体跳约 10 ns（docs/13 有两次，原因还没查清）。跳了就记下来，**不算失败**。算失败的是：条数不对、rail ≠ 0、nEdge ≠ 1、标准差明显变大。

### 3.1 短行（只改 B 的参数）
- 改 `bscan_test.m`：第 22 行 `100`、第 23 行 `10`、第 24 行 `400`、第 51 行 `2`。
- 为什么 rpb = 2：第 64 行会把 Nx 向上凑成 rpb 的整数倍（rpb = 50 时 Nx 会变成 50）。rpb = 2 时 Nx = 10，一共 5 个 buffer，每个 2 × 1024 × 2 B = 4096 B。
- 检查模式应打印：
  ```
  A-line 数 10，间距 10.00 um（实际 10.00 ~ 10.00 um），B-scan 长度 0.09 mm
  扫描速度 4.00 mm/s，步频 8000 Hz，触发 400 Hz，DO 采样率 248000 S/s
  总行程 0.50 mm，总用时 0.90 s，结束位置 +0.0 um，激光触发：false
  ```
- 硬件模式：`等待 10 个触发` → ctr1 = 10、10/10、rail 0。X 手轮先转出 90°（500 µm）再回来。
- 跑完改回第 22/23/24/51 行 = 2000 / 5 / 800 / 50，第 15 行 = `false`，**第 37 行保持 4**。

---

## 三、收尾检查清单
- `bscan_test.m`：第 15 行 false；第 22–24、51 行是默认值；第 37 行 = 4。`test2_Y.m`：第 13 行 false。原来的 `test2.m` 没动过。
- 并线在 USER 1；SR2 断电；发生器 Output 关。

## 四、拍照清单
照片放主目录的 `06_控制程序/docs/screenshots/`，文件名建议：
- `HW_Y_stage_nameplate.jpg`：Y 滑台铭牌
- `HW_SR2_Y_label.jpg`：Y 驱动器标签（序列号、电流表）
- `HW_SR2_Y_SW1-8.jpg`、`HW_SR2_Y_SW9-12.jpg`：Y 拨码
- `HW_BNC2110_P02_P03.jpg`：BNC-2110 上 P0.2/P0.3 的孔
- `HW_SR2_Y_control_wiring.jpg`：Y 驱动器 STEP−/DIR−/+5 V 接线
- `HW_Z_tank_tray.jpg`：Z 上的水槽托盘和周围空间

拍完告诉我，我打开照片和你一起读拨码。

## 五、如果 Rui 今天来
给他看 2.6 现场跑的 B-scan（示波器上的触发链 + 400/400 + ctr1 = 400）和 Y 轴结果，然后问：
- 中：「第一版 C-scan 行内我想先沿用 B-scan 已验证的匀速扫（每个触发采一条）；您书面计划写的是 step-and-settle，第一版您希望用哪种？」
- EN: "For the first C-scan I'd like to keep the constant-velocity scan within each row, as validated in the B-scan. Your Phase 1 plan says step-and-settle. Which one would you like for the first version?"

---

**现在第一步：** 双击 sync_pam.cmd，然后做 0.1。告诉我 `which bscan_test` 显示的路径，以及第 15、16、19 行和 `test2.m:13` 的值。

### 🧑 用户 · 2026-10-14 13:56

好的 那我现在可以怎么开始连线 现在所有的连线都打乱了  然后可以开始做什么

### 🤖 Claude · 2026-10-14 14:05

先看一下以前接线的参考照片，这样能按原样一根根接回去。

> 🔧 Read · file_path: C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\screenshots\HW_BNC2110_P06_in_USER1.jpg

> 🔧 Read · file_path: C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\screenshots\HW_BNC2110_terminals_motor.jpg

> 🔧 Read · file_path: C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\screenshots\HW_SR2_control_wiring.jpg

> 🔧 Read · file_path: C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\screenshots\HW_5V_wago_STEPplus.jpg

### ⚙️ 工具 · 2026-10-14 14:05

<details><summary>工具输出</summary>

```
[图片]
```
</details>

### ⚙️ 工具 · 2026-10-14 14:05

<details><summary>工具输出</summary>

```
[图片]
```
</details>

### ⚙️ 工具 · 2026-10-14 14:05

<details><summary>工具输出</summary>

```
[图片]
```
</details>

### ⚙️ 工具 · 2026-10-14 14:05

<details><summary>工具输出</summary>

```
[图片]
```
</details>

### 🤖 Claude · 2026-10-14 14:07

先别急着拔插。现在线已经乱了，第一件事是**把现状拍下来**，然后按「先电机、后触发」的顺序接。下面的目标接法是我对照 10/4–10/7 的旧照片整理的（BNC-2110 端子排、SR2 控制端子、+5 V WAGO）。

## 第 0 步：断电，拍现状（约 5 分钟）
- **KORAD 的 Output 关掉**，三台 SR2 的灯全灭；发生器两路 Output 关；激光不碰。
- 拍 5 张照片，直接贴进对话就行：
  1. BNC-2110 端子排，上下两排都要拍清楚；
  2. 三台 SR2 的控制端子和电源端子；
  3. 发生器的背面 AUX 和正面输出；
  4. ATS 挡板；
  5. 示波器的输入口。
- 为什么先拍：台架和 Maria 共用，如果是她为自己的实验改的线，拍了才能恢复；能问到她的话，问一句她还要不要用这套接法。我拿照片和旧照片对比，告诉你哪几根变了，比全部拆了重接快。

**拍照的同时，可以在电脑上先做 0.1**（不碰线）：关 LabVIEW，在 MATLAB 里 `cd C:\Users\2031\Desktop\Research-PAM\07_MATLAB`，再 `which bscan_test`。

## 目标接法（按 A→E 的顺序接，A–C 全程 KORAD 关着）

**A. 电源线和电机线**
- 电源：KORAD V+（红）→ WAGO → 三台 SR2 的 **V+**；V−（黑）→ 三台的 **V−**。极性别接反（SR2 只能接 12–48 VDC）。KORAD 负极另外接 BNC-2110 的 D GND。
- 电机线：每个滑台的 DB9 线接到它自己那台驱动器的 A+/A−/B+/B−。X 是 B− 白、B+ 灰、A− 蓝、A+ 绿（docs/01）。
- 认驱动器：顺着 DB9 线从滑台找到驱动器。X 那台贴着「X motor」（243107344）；Y、Z 今天顺手贴上胶带，记下序列号。

**B. 控制线**（BNC-2110 以面板印字为准，下面的位置是旧照片里的样子）
- **上排**从左到右：P0.7、P0.6、P0.5、P0.4、P0.3、P0.2、P0.1、P0.0、PFI13、D GND、USER 1 …
- **下排**右端：+5 V、+5 V、D GND；PFI 3/P1.3 在下排左起第 7 个（正好在 P0.1 下面）。

| 从 | 到 | 旧线色 |
|---|---|---|
| P0.0 / P0.1 | X 的 STEP− / DIR− | 黄 / 绿 |
| P0.2 / P0.3 | Y 的 STEP− / DIR− | 黄 / 绿 |
| P0.4 / P0.5 | Z 的 STEP− / DIR− | 黄 / 绿 |
| 下排 +5 V | 白线 → WAGO → 三台的 STEP+ 和 DIR+ | 白 |
| EN+ / EN− | 空着（悬空 = 使能） | — |

旧接法里黄色都是 STEP、绿色都是 DIR，但以端子名为准，不以颜色为准。

**C. 静态检查，6 根线一起查**（KORAD 还关着；因为 X、Z 的线也被动过，所以不只查 Y）
- 原理：共阳极接法下，哪根线写 0，哪个端子就变成约 0 V；其余写 1 的约 5 V。「写 0 那一格变 0 V」才能证明这根线接到了对的地方。光耦 LED 那一侧的电来自 NI 的 +5 V，所以 SR2 断电也能测。
- 代码：
  ```matlab
  d = daq("ni"); addoutput(d,"Dev1","port0/line0:5","Digital");
  write(d,[1 1 1 1 1 1])   % 6 个端子都应约 5 V
  write(d,[0 1 1 1 1 1])   % 只有 X STEP− 约 0 V
  write(d,[1 0 1 1 1 1])   % 只有 X DIR− 约 0 V
  % ……0 依次往右挪：第 3 位 Y STEP−，第 4 位 Y DIR−，第 5 位 Z STEP−，第 6 位 Z DIR−
  write(d,[0 0 0 0 0 0]); clear d
  ```
- 万用表打 DC V 档，黑表笔接 BNC-2110 的 D GND。第一行要量 6 个端子；后面每一行只量那一个该变 0 V 的端子。一共 12 个读数。
- 通过：12 个读数都对。某一行该变 0 的端子还是 5 V，就说明那根线接错了孔、或者 STEP 和 DIR 对调了。**12 个都过了才能给 KORAD 上电。**

**D. 触发链**（接 BNC 之前，先在发生器上把两路都设成 Burst Source = Ext、Sync Off、Trig Out Off，Output 保持关）
- P0.6 的深蓝线 → **上排 USER 1 端子**（D GND 右边那一格）。
- USER 1 BNC → 三通（示波器 CH1）→ 发生器背面 CH1 AUX → 三通 + 短线 → 背面 CH2 AUX。
- 发生器正面 CH1（G1）→ 三通（示波器 CH2）→ ATS **TRIG IN**。
- 发生器正面 CH2（G2）→ 三通（示波器 CH3）→ ATS **CH A**。
- ATS 挡板从上到下是 ECLK、CH A、CH B、TRIG IN、AUX I/O，CH A 和 TRIG IN 别插反。
- 并线：USER 1 端子 → 下排 PFI3。
- 不要接：P0.6 直接进 TRIG IN（约 57 mA，超过 DIO 的能力）；P0.7 和激光今天都空着。

**E. 设置**：示波器 CH1–3 的 Probe 都设 1X；发生器按 docs/13 §2 逐项设（参数在我上一条消息里）。

---

**现在先做第 0 步**：断电，拍那 5 张照片贴给我，同时在电脑上做 0.1。接 A、B 的时候 KORAD 一直关着，可以顺手拍 Y 的铭牌和拨码（2.1），两件事一起做。

### 🧑 用户 · 2026-10-14 14:11

这个bnc没有变化 只是这个连接的电源的电压和电流需要确认一下 然后就是示波器和信号发生器 和user端子和计数功能的pfi3要确认一下

### 🤖 Claude · 2026-10-14 14:12

> 🔧 Read · file_path: C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\screenshots\HW_motor_power_KORAD.jpg

### ⚙️ 工具 · 2026-10-14 14:12

<details><summary>工具输出</summary>

```
[图片]
```
</details>

### 🤖 Claude · 2026-10-14 14:12

> 🔧 Grep · pattern: KORAD|限流|C\.C

### ⚙️ 工具 · 2026-10-14 14:12

<details><summary>工具输出</summary>

```
C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\01_硬件与接线.md:43:| 电机电源 | KORAD KD3005D（0–30 V，0–5 A），设 23.88 V，三台驱动器空闲合计 0.098 A，C.V 模式。V+ 红线、V− 黑线经 WAGO 分到三台驱动器。运动时如果 C.C 灯亮，说明限流太低，可能欠压 | ✔（10/4 照片） |
C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\01_硬件与接线.md:57:| 电机电源 | KORAD V+ 红 / V− 黑 | 三台 SR2 的 V+ / V− | 23.88 V | ✔ |
C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\01_硬件与接线.md:58:| 电源地 | KORAD 负极 | BNC-2110 D GND（用户说明） | 地 | ✔。⚠ 这样把光耦隔离的两侧连在了一起，电机电流的噪声可能进到 NI/ATS 的地。为什么这样接、要不要断开，待讨论 |
C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\01_硬件与接线.md:82:**10/4 晚用 `bscan_test.m` 判断悬空蓝线：** 运行时 P0
…[截断，共 1637 字符]
```
</details>

### 🤖 Claude · 2026-10-14 14:13

好，BNC-2110 的端子没动，那就不用重接，只把这三样确认一遍。先更正我上一条的一处错误：这台 KORAD KD3005D 照片上只有 **POWER** 键，没有单独的 Output 键。所以「关输出」就是关 POWER，一开机电压就加到三台 SR2 上。

## 建议顺序
1. **2.2 Y 的静态检查**（SR2 断电，约 3 分钟）。这是今天唯一还没用电确认过的线，放在 KORAD 开机之前。
2. **发生器 + 示波器 + USER 1/PFI3**：手动打 5 发，一次查完整条触发链。不用给 SR2 上电，也不用 ATS。
3. **KORAD 开机核对**。

## 1. 发生器 + 示波器（先查设置，再打 5 发）

**发生器 DG852**：先关两路 Output，**先查 Sync 和 Trig Out**。AUX 线现在接着，如果哪个口被设成了输出，会和 P0.6 顶在一起。然后按 docs/13 §2 逐项核对：
- CH1：Square 100 kHz、2 Vpp、Offset 1 V、Duty 50%
- CH2：Square 2.5 MHz、1 Vpp、Offset 0.5 V、Duty 50%、Burst Delay 2 µs
- 两路都是：Burst NCycle、Cycles 1、Source Ext、Leading、Idle Bottom；Imped Load；**Sync Off、Trig Out Off**
- 不要 Recall `PAM_bscan`。核对完再打开两路 Output。

**示波器**：
- CH1–3 的 **Probe 都设 1X**，DC 耦合。
- 水平 1 µs/格，水平位移归零（按一下水平 POSITION 旋钮）。
- 触发：Edge、CH3 上升沿、约 0.5 V、**Normal**。
- Measure 加这几项：CH1–3 的 Top 和 +Width，Delay CH1→CH2。

**线**（只看，不动）：
- USER 1 BNC → 三通（CH1）→ 背面 CH1 AUX → 三通 + 短线 → 背面 CH2 AUX
- G1 → 三通（CH2）→ ATS TRIG IN
- G2 → 三通（CH3）→ ATS CH A
- USER 1 端子 → 下排 PFI3 的并线

**手动打 5 发**（在命令行敲；每次 P0.6 从 0 变 1，发生器出一组脉冲，ctr1 加 1）：
```matlab
clear d dq cnt; daqreset
cnt = daq("ni"); addinput(cnt,"Dev1","ctr1","EdgeCount"); resetcounters(cnt);
d = daq("ni"); addoutput(d,"Dev1","port0/line6","Digital");
write(d,0); c0 = read(cnt,"OutputFormat","Matrix");
for k = 1:5, write(d,1); pause(0.2); write(d,0); pause(0.2); end
c1 = read(cnt,"OutputFormat","Matrix"); fprintf('ctr1：%d（应为 5）\n', c1 - c0);
clear d cnt
```

**预期**（依据 docs/13 §3.2–3.3 [实测]）：

| 看哪里 | 应该是 | 不对时先查 |
|---|---|---|
| MATLAB | `ctr1：5` | 0：并线没插在 PFI3 或 USER 1 端子上 |
| CH1（P0.6） | 0 → 约 4.3 V 的台阶 | 平线：P0.6 蓝线不在 USER 1 端子，或 CH1 的三通不在 USER 1 BNC 上 |
| CH2（G1） | 约 2 V、5.000 µs，比 CH1 晚约 570–590 ns | 没有脉冲：Source 不是 Ext、Output 没开、AUX 线没插。**约 4 V**：TRIG IN 那头没接上（线末端开路，电压翻倍） |
| CH3（G2） | 约 1 V、200 ns，比 G1 晚约 1.98 µs | 没有脉冲：CH1 AUX 到 CH2 AUX 的短线。**约 2 V**：CH A 可能还不是 50 Ω（见下） |

CH3 约 2 V 不一定是接错了。CH A 的阻抗是程序设的（`bscan_test.m:260`）；电脑重启以后、还没跑过 B 之前，CH A 是不是 50 Ω，我不确定（待确认）。等跑完第一次 B 再看一眼：变回约 1 V 就没问题。TRIG IN 不一样，它本身就是 50 Ω（实测 50.2 Ω），CH2 应该一直是约 2 V。

## 2. KORAD 开机核对（做完 2.2 之后）
- 开机前看一眼：红线 + → WAGO → 三台的 V+；黑线 − → 三台的 V−，另外还有一根接 BNC-2110 的 D GND。
- 开机后应该看到（10/4 照片 [实测]）：**23.88 V、约 0.098 A、C.V 灯亮、C.C 不亮**；三台驱动器绿灯**闪**。
- C.V 和 C.C 的意思：
  - C.V 是正常状态：电源稳住电压，负载要多少电流就给多少。
  - C.C 表示负载要的电流超过了限流值，电源只好把电压降下来。SR2 欠压会报红灯（2 绿 + 4 红 = 电源电压低）。
- 限流设的是多少，以前没记过（待确认）。今天不用知道具体值，只要**空闲时和 2.5 跑 4 mm/s 时都是 C.V**，限流就够了。
- 如果 C.C 亮、电压低于 23.88 V：慢慢往上调 CURRENT 旋钮，直到 C.V 亮回来，然后记下数值。
- 电流和 0.098 A 差得多一点也正常：Y、Z 的电流拨码可能和 X 不同，等 2.1 读完拨码就能解释。
- 确认完长按 VOLTAGE 旋钮锁定（LOCK 灯亮），防止碰到旋钮。

---

**现在第一步：做 2.2（Y 的静态检查）。** 命令在我第一条消息的 2.2 里，`line2` 量 Y STEP−，`line3` 量 Y DIR−。把写 0 和写 1 时的读数告诉我，然后做发生器那一段。

### 🧑 用户 · 2026-10-14 14:29

KORAD 开机核对（做完 2.2 之后）

* 开机前看一眼：红线 + → WAGO → 三台的 V+；黑线 − → 三台的 V−，另外还有一根接 BNC-2110 的 D GND。
* 开机后应该看到（10/4 照片 [实测]）：23.88 V、约 0.098 A（ 现在是0.1-0.098 左右可以么）、C.V 灯亮、C.C 不亮；三台驱动器绿灯闪。 是的cv亮 其他驱动都在闪动
* C.V 和 C.C 的意思：
   * C.V 是正常状态：电源稳住电压，负载要多少电流就给多少。
   * C.C 表示负载要的电流超过了限流值，电源只好把电压降下来。SR2 欠压会报红灯（2 绿 + 4 红 = 电源电压低）。
* 限流设的是多少，以前没记过（待确认）。今天不用知道具体值，只要空闲时和 2.5 跑 4 mm/s 时都是 C.V，限流就够了。
* 如果 C.C 亮、电压低于 23.88 V：慢慢往上调 CURRENT 旋钮，直到 C.V 亮回来，然后记下数值。
* 电流和 0.098 A 差得多一点也正常：Y、Z 的电流拨码可能和 X 不同，等 2.1 读完拨码就能解释。
* 确认完长按 VOLTAGE 旋钮锁定（LOCK 灯亮），防止碰到旋钮。 

<pasted_content id="4d1c">
>> clear d dq cnt; daqreset
cnt = daq("ni"); addinput(cnt,"Dev1","ctr1","EdgeCount"); resetcounters(cnt);
d = daq("ni"); addoutput(d,"Dev1","port0/line6","Digital");
write(d,0); c0 = read(cnt,"OutputFormat","Matrix");
for k = 1:5, write(d,1); pause(0.2); write(d,0); pause(0.2); end
c1 = read(cnt,"OutputFormat","Matrix"); fprintf('ctr1：%d（应为 5）\n', c1 - c0);
clear d cnt
ctr1：89（应为 5）
>>
</pasted_content id="4d1c">

  现在连线都是对的  得到这个结果  我是在命令行运行的

### 🤖 Claude · 2026-10-14 14:31

**KORAD：通过。** 0.098–0.100 A 在读数正常的跳动范围内，C.V 亮、三台驱动器绿灯都在闪，和 10/4 一样。记得长按 VOLTAGE 旋钮锁上。

**ctr1 = 89（应为 5）：不通过，先查清楚再往下做。** 这件事不影响安全，但在原因找到之前，ctr1 的数不能拿来判断 2.4、2.6、3.1。

## 为什么值得查
以前 B-scan 在同样的接线下每次都数得一个不差（400/400）。现在多出 84 个，说明 PFI3 上出现了 P0.6 以外的边沿。

ctr1 的工作方式：PFI3 上的电压每从低跳到高一次，它就加 1，不管这个沿是谁产生的。

可能的来源有三个：
- ① 发生器背面的某个 AUX 口被设成了输出（Trig Out 或 Sync 开着，或者 Burst 的 Source 不是 Ext），它在往 USER 1 这条线上送信号；
- ② P0.6 每次跳变时，跟着发生器出脉冲又耦合回 USER 1 线；
- ③ PFI3 的并线没压实，或插错了孔。

下面每一步只改一样东西，把这三个分开。

## 测试 A：P0.6 一直保持 0，数 2 秒
示波器触发改成 **CH1 上升沿、约 1.5 V、Normal**，这样 USER 1 线上只要有边沿，示波器就会触发。
```matlab
clear d dq cnt; daqreset
cnt = daq("ni"); addinput(cnt,"Dev1","ctr1","EdgeCount"); resetcounters(cnt);
d = daq("ni"); addoutput(d,"Dev1","port0/line6","Digital"); write(d,0);
c0 = read(cnt,"OutputFormat","Matrix"); pause(2);
c1 = read(cnt,"OutputFormat","Matrix"); fprintf('P0.6 保持 0、2 s：ctr1 = %d（应为 0）\n', c1 - c0);
clear d cnt
```
- **结果 > 0，或者示波器触发了**：P0.6 没动，线上却有边沿，那就是别的东西在往 USER 1 上送信号，最可能是 ①。
  1. 逐项看发生器 CH1、CH2 两路的 **Trig Out、Sync 是不是 Off**，Burst Source 是不是 **Ext**。
  2. 再把 USER 1 三通到背面 CH1 AUX 的那根 BNC 拔掉，重跑 A。变成 0，就确定是发生器的问题。
- **结果 = 0**：做测试 B。

## 测试 B：两路发生器 Output 都关掉，再打 5 发
用你刚才那段代码，什么都不改。
- **= 5**：多出来的边沿是发生器出脉冲时带出来的（②）。下一步我们一起在示波器上看 CH1 的边沿。
- **还是远大于 5**：先查 ③。轻拉一下 USER 1 端子和 PFI3 端子上的线，看压实了没有；对照面板印字，确认并线确实插在下排「PFI 3/P1.3」那一格。

## 另外请告诉我
1. 刚才打 5 发的时候，示波器上 CH2、CH3 是每发都出一个脉冲吗？读数大约多少？
2. 发生器那张设置清单（尤其是 Sync Off、Trig Out Off）已经逐项核对过了吗？
3. 2.2（Y 的静态电平）做了吗？读数是多少？现在 SR2 已经上电，照样可以做：P0.2 每从 1 变到 0 一次，Y 只走 1 个微步（如果是 4000 步/转，就是 0.5 µm），没有影响。

先跑测试 A，把打印结果和示波器有没有触发告诉我。

### 🤖 Claude · 2026-10-14 14:32

这张图说明示波器现在**根本看不到脉冲**，所以图上没有东西不代表线上没有信号。从屏幕上能读出这几点：

1. **右上角 `D 39.0003544ms`：水平位移被设成了 39 ms。** 屏幕显示的是触发之后 39 ms 那一小段，而脉冲在触发后 3 µs 内就结束了，所以只能看到平线。测量表里 tVmax、tVmin 都是 38.97 ms，也说明窗口在 39 ms 那里。10/9 那次 D 被设成 480 ms，也是这个现象（docs/13 §3.2）。
2. **触发源是 CH3、540 mV**（右上角紫色字），不是测试 A 要的 CH1。左上角 `WAIT` 是 Normal 模式下还在等触发。所以测试 A 里「示波器有没有触发」这一项这次不算数。
3. 测量表里的 `*****` 表示窗口里没有边沿、量不出来。CH1 Vpp 40 mV 这些数是 39 ms 处的底噪，没有意义。
4. 底栏的 CH2 看起来是 `10.0V`/格，我看不太清。如果真是 10 V/格，多半是 Probe 被设成了 10X，和 10/9 那次 CH2 被设成 2X 是同一类问题。另外 AX/BX 光标是开着的，应该是别人用过留下的。

## 改法（按顺序）
1. **按一下水平 POSITION 旋钮**，D 回到 0。水平 SCALE 调到 **1 µs/格**。
2. 依次按 CH1、CH2、CH3，每个通道的菜单里设 **Probe = 1X**、Coupling = DC。然后看底栏，应该显示约：CH1 2.00 V、CH2 1.00 V、CH3 500 mV（每格）。
3. 触发：Source = **CH1**，上升沿，Level 约 **1.5 V**，Sweep 选 **Normal**。CH1 触发两个测试都能用：P0.6 的沿在屏幕中间，G1 在它右边约 0.58 µs，G2 在约 2.56 µs，1 µs/格下都在屏幕里。
4. 可选：按 Cursor 键把 Mode 设成 OFF，关掉光标。

## 改完以后重跑
1. **先确认能看到 P0.6**：命令行运行
   ```matlab
   d = daq("ni"); addoutput(d,"Dev1","port0/line6","Digital"); write(d,0); write(d,1)
   ```
   示波器应该触发一次：CH1 从 0 跳到约 4.3 V，CH2、CH3 各出一个脉冲。看完运行 `write(d,0); clear d`。
2. **再跑测试 A**（P0.6 保持 0，数 2 s）。预期：ctr1 = 0，示波器一直停在 WAIT。
3. **最后再打 5 发**。每一发都应该看到：CH1 约 4.3 V 的台阶；CH2（G1）约 2 V、宽 5 µs；CH3（G2）约 1 V、宽 200 ns。

另外，上一次测试 A 的 ctr1 打印出来是多少？请把那个数字也告诉我。这张截图我先留着，收工时放进 screenshots，作为「今天示波器被人改过」的记录。

### 🧑 用户 · 2026-10-14 14:32

示波器结果放上来了
vpp 40mv 800mv 432mv

### 🤖 Claude · 2026-10-14 14:32

> 🔧 Bash · description: Look for newly uploaded scope photos

### ⚙️ 工具 · 2026-10-14 14:32

<details><summary>工具输出</summary>

```
total 1180
-rw-r--r-- 1 2031 197121 1206064 Oct 14 10:29 ff9f5e23-image.jpg
---
total 43104
-rw-r--r-- 1 2031 197121 1467674 Oct  7 20:01 SCOPE_P06_into_TRIGIN_1007.jpg
-rw-r--r-- 1 2031 197121 1474031 Oct  7 20:01 SCOPE_P06_DG852_chain_1007.jpg
-rw-r--r-- 1 2031 197121   33941 Oct  7 20:01 LV_SendCOPulses_FP.png
-rw-r--r-- 1 2031 197121    4728 Oct  7 20:01 README.md
-rw-r--r-- 1 2031 197121   30051 Oct  7 20:01 LV_SendCOPulses_BD.png
-rw-r--r-- 1 2031 197121  358345 Oct  7 20:01 LV_Main_FP_Settings.png
-rw-r--r-- 1 2031 197121  333173 Oct  7 20:01 LV_Main_FP_Scan.png
---
/c/Users/2031/Deskto
…[截断，共 927 字符]
```
</details>

### 🤖 Claude · 2026-10-14 14:33

这条消息里没有收到新照片。你报的 Vpp 是 40 mV、800 mV、432 mV，和上一张截图里的数一模一样。如果你改过设置后又拍了一张，它没传上来，请再发一次。

如果说的还是上一张，那这三个数**不是脉冲的读数**。当时示波器的水平位移 D 是 39 ms，看的是触发后 39 ms 的那一段，脉冲早就结束了，量到的只是底噪：

| | 上一张（底噪） | 看到脉冲时应该是 |
|---|---|---|
| CH1（P0.6） | Vpp 40 mV | Top 约 4.3 V |
| CH2（G1） | Vpp 800 mV | Top 约 2 V，宽 5 µs |
| CH3（G2） | Vpp 432 mV | Top 约 1 V，宽 200 ns |

请按顺序做这三步，然后拍一张：
1. **按一下水平 POSITION 旋钮**（HORIZONTAL 区里较小的那个旋钮），看右上角的 `D` 变成 0。
2. 触发 Source 改成 **CH1**，Level 约 **1.5 V**，Normal 模式。
3. 命令行运行：
   ```matlab
   d = daq("ni"); addoutput(d,"Dev1","port0/line6","Digital"); write(d,0); write(d,1)
   ```
   示波器应该触发一次。拍下屏幕后运行 `write(d,0); clear d`。

照片里请把右上角（D 和触发设置）、底栏（每个通道的 V/格）和测量表都拍进去。

另外还差一个数：**测试 A（P0.6 一直保持 0，数 2 秒）打印出来的 ctr1 是多少？** 这个数决定下一步查发生器还是查 PFI3 的线。

另外有件事先说一下：主目录里 `cscan_test.m`、`docs/01`、`docs/14` 在过去一个多小时里被改过，应该是另一个 C-scan 窗口在写。我这边都没碰。收工写记录前，我会先读一遍最新版本再往上加，不会覆盖那边写的内容。

### 🧑 用户 · 2026-10-14 14:37

现在这样设置的 发生器后面连线对么

### 🤖 Claude · 2026-10-14 14:39

先把发生器背面那张照片放大，看清楚每个口插的是什么。

### 🤖 Claude · 2026-10-14 14:39

> 🔧 PowerShell · description: Crop rear-panel photo around generator ports

### ⚙️ 工具 · 2026-10-14 14:39

<details><summary>工具输出</summary>

```
size: 1512 x 2016
saved
```
</details>

### 🤖 Claude · 2026-10-14 14:39

> 🔧 Read · file_path: C:\Users\2031\AppData\Local\Temp\claude\C--Users-2031-Desktop-Research-PAM--claude-worktrees-sad-poincare-cd40d6\39c1b058-7d7e-4e2f-b00b-4222fef61888\scratchpad\rear_crop.jpg

### ⚙️ 工具 · 2026-10-14 14:39

<details><summary>工具输出</summary>

```
[图片]
```
</details>

### 🤖 Claude · 2026-10-14 14:40

**发生器背面接错了，这就是 ctr1 = 89 的原因。** 放大照片后看得很清楚：

| 背面的口 | 现在 | 应该（docs/13 §1） |
|---|---|---|
| 10MHz REF IN/OUT | **插着三通** | **空着** |
| CH1 AUX IN/OUT | 一根线直接插着 | 三通：一边接从 USER 1 来的线，另一边接短线 |
| CH2 AUX IN/OUT | **空着** | 短线的另一头 |

## 为什么会多数出 84 个
- 10MHz REF 是发生器内部 10 MHz 参考时钟的进出口。三通插在这里，等于把一个 **10 MHz 方波直接送进了 USER 1 / P0.6 这条线**。
- 你拍的示波器读数印证了这一点：CH1 显示 **Freq 10.0 MHz、Peri 100.0 ns**，Vpp 2.4–2.56 V，最高约 1.5 V。
- 1.5 V 左右正好落在 PFI3 判断高低的灰色区间，所以 ctr1 时数时不数，多出 84 个。这一条是推测：PFI3 门槛的具体数值我没有查到。
- 另外，`write(d,1)` 时 P0.6 是在和这个参考时钟输出硬顶，这正是 docs/13 提醒过的「两个输出顶在一起」。
- CH2 AUX 空着，所以 G2 根本不会被触发。

## 改法
1. **背面接线整组往下挪一格**：三通从 10MHz REF 拔下，插到 **CH1 AUX**；原来插在 CH1 AUX 上的短线改插 **CH2 AUX**。10MHz REF 留空。插之前顺着线看一眼，确认三通上那根长线是从 BNC-2110 的 USER 1 来的。
2. **发生器 CH2 波形改成 Square**：现在是 **Sine** 2.5 MHz（第 5、7 张照片），按 docs/13 §2 应该是 Square、Duty 50%；1 Vpp、Offset 0.5 V 不用动。Sine 出来的测试脉冲形状不一样，B-scan 快速检查里的上升沿和 nEdge 都会跟着变。
3. 可选：CH1 的 Polarity 是 Negative，CH2 是 Positive。从页面位置看，它属于 Sync 那一组，Sync 关着的时候不起作用；输出反相由下面的 Invert 控制，现在是 Off。这是我从界面布局推断的，待确认。为了和 CH2 一致，可以改回 Positive。
4. **示波器的 D 还是 39.0003544 ms**：HORIZONTAL 区**上面那个旋钮**（旁边有 Zero 图标）按一下，D 应该变成 0。

## 已经对了的
- CH1：Square 100 kHz、2 Vpp、Offset 1 V、Duty 50%。
- 两路 Burst：NCycle、Cycles 1、Ext Leading、Idle Bottom；CH2 Delay 2 µs。
- 两路 Sync Off、Trig Out Off、Imped Load 50 Ω。
- 示波器：1 µs/格；CH1 2 V、CH2 1 V、CH3 500 mV（每格）；触发 CH1 上升沿、1.48 V、Normal；光标已关。

## 改完以后按顺序验证
1. **什么都不运行，先看 CH1**：应该是一条约 0 V 的平线，示波器停在 WAIT。如果还有 10 MHz，说明 REF 口还接在这条线上。
2. **静态打一发**：
   ```matlab
   d = daq("ni"); addoutput(d,"Dev1","port0/line6","Digital"); write(d,0); write(d,1)
   ```
   预期：CH1 跳到约 **4.3 V**；CH2（G1）约 2 V、宽 5 µs，比 CH1 晚约 0.58 µs；CH3（G2）约 1 V、宽 200 ns，比 G1 晚约 2 µs。拍一张，然后运行 `write(d,0); clear d`。

   CH1 的高电平要特别看：10/9–10/10 量到的是 4.28–4.34 V。刚才 P0.6 和参考时钟顶了约 1 秒，如果高电平明显低于这个范围，告诉我。
3. **测试 A**（P0.6 一直保持 0，数 2 s）：ctr1 应为 **0**。
4. **再打 5 发**：ctr1 应为 **5**。

今天发现的几处改动（10MHz REF 上的三通、CH2 被改成 Sine、示波器 D = 39 ms），收工时我会写进记录。照片我先留着，放进 screenshots。

### 🧑 用户 · 2026-10-14 14:42

要不要补上一个示波器

### 🤖 Claude · 2026-10-14 14:42

先查一下 MATLAB 当前文件夹指向哪里（截图地址栏是 `PAM_controlProgram\Matlab`）：

### 🤖 Claude · 2026-10-14 14:43

> 🔧 PowerShell · description: Check whether old MATLAB folder is a link to 07_MATLAB

### ⚙️ 工具 · 2026-10-14 14:43

<details><summary>工具输出</summary>

```
FullName : C:\Users\2031\Desktop\PAM_controlProgram\Matlab
LinkType : 
Target   : {}




Name                         LastWriteTime         Length
----                         -------------         ------
aline_edge_time.m            10/4/2026 12:51:17 AM   1851
analyze_delay_1003.m         10/4/2026 9:16:24 PM    7457
ats9462_aline_once.m         10/1/2026 7:18:27 PM   12342
ats9462_aline_test.m         9/30/2026 5:23:26 PM   14956
ats9462_aline_test_revised.m 10/4/2026 3:27:28 PM   20568
ats9462_multi_aline.m        10/4/2026 2:39:29 PM   15511
bscan_test.m                 10/
…[截断，共 1739 字符]
```
</details>

### 🤖 Claude · 2026-10-14 14:43

**先做一件事**：你最后运行的是静态打一发，执行到了 `write(d,1)`，workspace 里 `d` 还在，所以 **P0.6 现在停在高电平**。如果背面的三通还插在 10MHz REF 上，P0.6 就在一直和参考时钟输出硬顶。请马上运行：
```matlab
write(d,0); clear d
```
然后再去挪背面的线。

## 测试 A = 121：证实了上面的判断
P0.6 一直保持 0，PFI3 在 2 秒里还是数到 121 个沿。这说明边沿是从外面送进来的（10MHz REF 的参考时钟），不是 P0.6 发的。背面的线改对以后，测试 A 应该是 0。

## 另一个问题：MATLAB 当前文件夹是旧的
截图地址栏是 `C:\Users\2031\Desktop\PAM_controlProgram\Matlab`。我查了，这是一个**独立的旧副本**，不是链接：
- 里面的 `bscan_test.m` 是 10/7 的，`test2.m` 是 10/4 的，也没有 `cscan_test.m`；
- 在命令行敲 `bscan_test`，MATLAB 会先跑当前文件夹里的**旧版**。

编辑器里打开的 `bscan_test.m` 是对的（Research-PAM），`test2.m` 那个标签请把鼠标停在上面，看一下路径。改法：
```matlab
cd C:\Users\2031\Desktop\Research-PAM\07_MATLAB
which bscan_test
which test2
```
两个都应该显示 `...\Research-PAM\07_MATLAB\...`。`test2_Y.m` 要从这里的 `test2.m` 另存。

## 那段 6 根线的命令
那是给「线全乱了」准备的；端子没动，就不需要。SR2 现在上着电，每根 STEP 线从 1 变 0 一次，电机走 1 个微步（按 4000 步/转算是 0.5 µm），对位置没有影响。如果当时没拿万用表量，这段就等于没做，也没关系。Y 的 2.2 还要单独做，只量 P0.2 和 P0.3 两根。

## 要不要补示波器
- **不用再加示波器通道**：CH1 接在 USER 1 上，和两个 AUX 口是同一条线，已经能看到。CH2 AUX 只需要插上那根短线。
- **但要补一张示波器照片**：做完下面 1–4 步之后，静态打一发，拍那一刻的屏幕。

顺序：
1. `write(d,0); clear d`
2. 背面接线：三通移到 CH1 AUX，短线插到 CH2 AUX，10MHz REF 留空
3. 示波器 D 归零，发生器 CH2 改成 Square
4. `cd` 到 07_MATLAB
5. 静态打一发，拍照发给我
6. 测试 A，应为 0
7. 打 5 发，应为 5

### 🧑 用户 · 2026-10-14 14:44

<pasted_content id="4d1c">
>> d = daq("ni"); addoutput(d,"Dev1","port0/line6","Digital"); write(d,0); write(d,1)
>> write(d,0); clear d
>> cd C:\Users\2031\Desktop\Research-PAM\07_MATLAB
which bscan_test
which test2
C:\Users\2031\Desktop\Research-PAM\07_MATLAB\bscan_test.m
C:\Users\2031\Desktop\Research-PAM\07_MATLAB\test2.m
>>
</pasted_content id="4d1c">

 发生器怎么改 详细一点

### 🤖 Claude · 2026-10-14 14:45

MATLAB 文件夹对了，两个 `which` 都指向 07_MATLAB。下面是发生器的详细步骤，分两部分：背面接线和前面设置。

## A. 背面接线（3 分钟）
P0.6 现在是 0，背面两个 AUX 口都设成了外触发输入（Source = Ext），所以现在拔插没有风险。

背面从上到下三个 BNC 口：**10MHz REF IN/OUT → CH1 AUX IN/OUT → CH2 AUX IN/OUT**。

1. **先认线**：三通上有两根线。顺着摸一下：
   - 一根是**长线**，通到 BNC-2110 的 USER 1（中间经过示波器 CH1 的三通）；
   - 另一根是**短线**，它的另一头应该就是现在插在 CH1 AUX 上的那个头。
   - 如果摸下来不是这样，先别插，告诉我。
2. 把 **CH1 AUX 上的线头**拔下来：按住往里推一点，逆时针转，再拔。
3. 把**三通**从 **10MHz REF** 上拔下来。
4. 三通插到 **CH1 AUX**：对准，往里推，顺时针转到卡住。
5. 把第 2 步拔下的短线头插到 **CH2 AUX**。
6. 检查：**10MHz REF 空着**；CH1 AUX 上是三通（长线 + 短线）；CH2 AUX 插着短线的另一头。

## B. 前面设置（CH2 改成 Square）
1. 按面板上的通道键 **「2」**，CH2 那一半屏幕会高亮。
2. 按面板右上的 **「Square」** 键。也可以点屏幕上 CH2 那半边左上角的 **「Sine ▼」** 下拉框，改选 Square。
3. 屏幕会跳到 CH2 的波形参数页，逐项核对：
   - **Freq = 2.500 MHz**：一般会沿用原值；不对就点 Freq，键盘输入 `2.5`，再按 **M/µ** 键（MHz）。
   - **Ampl = 1.000 Vpp**：不对就点 Ampl，输入 `1`，选单位 Vpp。
   - **Offset = 500 mVdc**：不对就点 Offset，输入 `500`，按 **k/m** 键（mV）。
   - **Duty Cycle = 50 %**：Square 才有这一项。点它，输入 `50`，确认。
   - Phase = 0.00°。
4. 点 CH2 底部的 **「Burst」** 标签，再核对一遍（改波形后保险起见）：Delay **2.000 µs**、Cycles **User 1**、Source **Ext Leading**、Idle Level **Bottom**、Phase **0°**。Burst Period 是 100 µs，外触发时用不到，不用管。
5. 点 CH2 底部的 **「Channel」** 标签：Sync **Off**、Trig Out **Off**、Imped **Load 50 Ω**、Invert **Off**。
6. 可选：按通道键 **「1」** → 点 **「Channel」** 标签 → **Polarity 从 Negative 改成 Positive**，这样和 CH2 一致。按页面位置看，它属于 Sync 那一组，Sync 关着时不起作用（这是我的推断，待确认），所以改不改都不影响今天的测试。

**改完以后，CH2 底部三个标签应该显示：**
```
Square  Freq:2.500MHz  Ampl:1.000Vpp
Burst   Period:100.0µs  Delay:2.000µs
Channel Sync:OFF
```
CH1 不用动。现在已经是 Square 100 kHz、2 Vpp、Offset 1 V、Duty 50%、Delay 0。两路 Output 键保持亮着，屏幕上显示「1 ON」「2 ON」。

**这几个键别按：**
- **Default**：所有设置恢复出厂；
- **Channel Copy**：会用一个通道的设置覆盖另一个；
- **Store/Recall** 里的 `PAM_bscan`：那是 1.5 Vpp 的旧版；
- **Align Phase**。

## C. 改完以后验证
1. 示波器：HORIZONTAL 区上面那个旋钮按一下，**D 归零**（如果还没做）。什么都不运行时，CH1 应该是一条约 0 V 的平线，示波器停在 **WAIT**。不能再有 10 MHz。
2. 静态打一发，然后拍示波器屏幕：
   ```matlab
   d = daq("ni"); addoutput(d,"Dev1","port0/line6","Digital"); write(d,0); write(d,1)
   ```
   预期：CH1 约 4.3 V；CH2 约 2 V、宽 5 µs；CH3 约 1 V、宽 200 ns。拍完运行 `write(d,0); clear d`。
3. 测试 A：ctr1 应为 **0**；打 5 发：ctr1 应为 **5**。

照片和两个 ctr1 读数发给我。

### 🧑 用户 · 2026-10-14 14:49

示波器好像还是不太对 你可以告诉我要怎么设置么 还有为什么要2.5mhz 这两个频率为啥这样设置

### 🤖 Claude · 2026-10-14 14:50

先查一下 10/7 当时为什么选 2.5 MHz 和 100 kHz，看对话记录里有没有写原因：

### 🤖 Claude · 2026-10-14 14:50

> 🔧 Grep · pattern: 2\.5 ?MHz

### ⚙️ 工具 · 2026-10-14 14:50

<details><summary>工具输出</summary>

```
C:\Users\2031\Desktop\Research-PAM\08_对话记录\2026-10-03_B-scan_电机采集测试_f2984300.md:3230:| 频率 | 100 kHz → 一个周期的高电平 5 µs | 2.5 MHz → 高电平 200 ns |
C:\Users\2031\Desktop\Research-PAM\08_对话记录\2026-10-03_B-scan_电机采集测试_(fork)_1bbf2651.md:3230:| 频率 | 100 kHz → 一个周期的高电平 5 µs | 2.5 MHz → 高电平 200 ns |
C:\Users\2031\Desktop\Research-PAM\08_对话记录\2026-10-03_B-scan_电机采集测试_(fork)_1bbf2651.md:3486:   - Freq = **2.5 MHz**
C:\Users\2031\Desktop\Research-PAM\08_对话记录\2026-10-03_B-scan_电机采集测试_(fork)_1bbf2651.md:3513:- 两个通道的波形参数：CH1 是 100 kHz、2 Vpp、偏置 1 V、占空比 50%；CH2 是 2.5 MHz、1 Vpp、偏置 0.5 V、占空比 50%。
C:\Users\2031\Desk
…[截断，共 2606 字符]
```
</details>

### 🤖 Claude · 2026-10-14 14:50

> 🔧 Read · file_path: C:\Users\2031\Desktop\Research-PAM\08_对话记录\2026-10-03_B-scan_电机采集测试_f2984300.md

### ⚙️ 工具 · 2026-10-14 14:50

<details><summary>工具输出</summary>

```
3215	**P0.6 → 发生器外触发 → 发生器 CH1 → TRIG IN；发生器 CH2（延时测试脉冲）→ CH A**
3216	
3217	为什么选这个：
3218	- 发生器的输出本来就是按带 50 Ω 负载设计的。这样 P0.6 只需要推发生器的外触发口；那个口应该是高阻的，接上以后验证。
3219	- CH2 的测试脉冲本来就需要发生器来出，而且和 CH1 用的是同一个触发。
3220	- 真实系统里 ATS 打算用光电二极管触发（LabVIEW 就是这么做的，用 CH B），所以"P0.6 直接接 TRIG IN"本来就只是测试时的接法。
3221	- 代价：发生器会在 P0.6 和 TRIG IN 之间加一段固定延迟，具体多少待量。这对位置没有影响：4 mm/s 下 1 µs 只走 4 nm。
3222	
3223	## 2a 先设好发生器（接线先不动）
3224	
3225	两个通道都先设 **Imped = Load**，再填幅度。10/3 的经验是先设阻抗，屏幕上显示的电压才等于实际电压。
3226	
3227	| | CH1（以后接 TRIG IN） | CH2（以后接 CH A） |
3228	|---|---|---|
3229	| 波形 | Square（这台的 Pulse 不能 burst） | Square |
3230	| 频率 | 100
…[截断，共 1769 字符]
```
</details>

### 🤖 Claude · 2026-10-14 14:51

你最后一次运行的是静态打一发，执行到 `write(d,1)` 为止，**P0.6 现在是高电平，`d` 还在**。三通已经不在 10MHz REF 上了，P0.6 高着没有问题，拍完照再 `write(d,0); clear d` 就行。

中间那个 `Unrecognized function or variable 'd'` 不用管：那时 `d` 已经被清掉了，`write(d,0)` 找不到它。那一行你敲的是 `clear`（后面没带 `d`），会把 workspace 里所有变量都清掉，现在没什么要保留的，所以也没影响。

## 发生器：现在全对了
CH2 是 Square 2.5 MHz、1 Vpp、Delay 2 µs；两路 Polarity 都是 Positive，Sync Off，Trig Out Off，Imped Load，两路 Output 都开着。还有两项这张图上看不到：点 CH2 底部的「Square」标签，确认 **Offset 500 mV、Duty 50%**。

## 示波器：只差一项，D 还是 39 ms
你这张图其实说明了三件好事：
- CH1 上的 10 MHz 没有了（Freq 显示 `*****`），背面线改对了；
- CH1 的 Avg 是 **4.47 V**（4.32–4.64 V），这就是 P0.6 的高电平。10/9–10/10 量到的是 4.28–4.34 V，所以刚才和参考时钟顶的那一下没有把 P0.6 弄坏；
- CH2、CH3 是平的，不是没有脉冲，而是屏幕显示的是触发后 **39 ms** 的那一段。G1（5 µs）和 G2（200 ns）早就结束了，只有 P0.6 还一直高着。

| 项 | 应该设成 | 现在 |
|---|---|---|
| 水平位移 D | **0** | 39.0003544 ms ✗ |
| 水平时基 H | 1 µs/格 | ✓ |
| CH1 / CH2 / CH3 | 2 V / 1 V / 500 mV 每格，Probe 都是 1X | ✓ |
| 触发 | Edge、CH1、上升沿、约 1.5 V、Normal | ✓（1.44 V） |
| 测量 | Measure All（CH1–3）+ 底栏 Dly↑1→2 | ✓ |

**D 归零的方法**：HORIZONTAL 区有两个旋钮，**上面小的是 POSITION**（旁边有一个 Zero 图标），下面大的是 SCALE。**把上面那个旋钮往下按一下**，右上角应该显示 `D 0.00000000s`。

按了没变的话，换一个办法：先把下面的 SCALE 转到 10 ms/格，再转上面的旋钮把 D 转到 0 附近（时基大的时候 D 走得快），然后按一下上面的旋钮，最后把 SCALE 转回 1 µs/格。

D 归零以后，命令行运行 `write(d,0); write(d,1)`，再打一发，然后拍照。应该看到：
- **CH1**：在屏幕中间跳到约 4.3 V；
- **CH2（G1）**：比中间晚约 0.58 µs 出现，约 2 V，持续约 5 格；底栏 Dly↑1→2 约 570–590 ns；
- **CH3（G2）**：在中间右边约 2.6 格处，一根约 1 V 的窄脉冲，+Wid 约 200 ns。

  1 µs/格下 CH3 的 Top 可能读得偏高（会量到过冲，docs/13 §3.3 遇到过），以 +Wid 为准。

拍完照：`write(d,0); clear d` → 测试 A（应为 0）→ 打 5 发（应为 5）。

## 为什么是 100 kHz 和 2.5 MHz
来源：10/3 设计这套测试信号时的说明（`08_对话记录/2026-10-03_B-scan_电机采集测试_f2984300.md` 第 3227–3242 行），以及 docs/13 §2。

**关键是 Burst NCycle、Cycles = 1 这个模式。** 平时输出停在低电平（Idle Bottom = 0 V）。每来一个外触发（P0.6 上升沿，Ext Leading），发生器只输出**一个周期**，然后回到 0 V。所以这里的「频率」**不是每秒重复多少次**，它只决定这一个周期有多长。方波占空比 50%，高电平就是半个周期：

| | CH1 → TRIG IN（触发） | CH2 → CH A（假的光声信号） |
|---|---|---|
| 频率 → 一个周期 | 100 kHz → 10 µs | 2.5 MHz → 400 ns |
| 高电平宽度 | **5 µs** | **200 ns** |
| 幅度 / Offset | 2 Vpp / 1 V → 0 到 2 V | 1 Vpp / 0.5 V → 0 到 1 V |
| Delay | 0 | **2 µs** |
| 作用 | ATS 只用它的**上升沿**：从这一刻开始记 1024 点 = 5.69 µs | 在触发后 2 µs 出现一个短脉冲，正好落在 5.69 µs 窗口里 |

- **CH1 的 5 µs 宽度本身不关键**［条件计算］，满足三件事就行：
  - 边沿要陡：方波上升约 20 ns；
  - 幅度要明显高于 ATS 的门槛 0.87 V：2 V 可以，1 V 会漏触发（docs/13 §3.3）；
  - 要在下一个触发之前结束：800 Hz 时两个触发隔 1.25 ms，远大于 10 µs。
- **CH2 的 200 ns** 在 180 MS/s 下是 36 个采样点（每点 5.56 ns），图上看得很清楚。它的上升沿很陡，所以能量出每条 A-line 里脉冲到达的时刻，精度在 ns 级（就是那个约 2 ns 的标准差）。可以把它当成一把「时间尺」，检查每条 A-line 有没有错位、有没有漏触发。
- **Delay 2 µs 的物理含义**：水里声速约 1.5 mm/µs，所以相当于约 3 mm 外传来的信号（条件计算，只是帮助理解）。
- **为什么用 Square**：这台发生器的 Pulse 波形不能 burst（docs/01）。Sine 没有陡的边沿，一个周期还从中间电平开始，B-scan 快速检查里「0.5 V 处的上升沿」和 nEdge 就都不准了。所以今天必须把 Sine 改回来。
- **Offset = Ampl/2**：这样低电平正好是 0 V。**Imped = Load**：TRIG IN 和 CH A 都是 50 Ω，设成 Load 后屏幕上显示的电压就等于实际电压。

### 🧑 用户 · 2026-10-14 14:54

咋还是有这种毛刺一样的东西

### 🤖 Claude · 2026-10-14 14:56

**这次静态打一发是通过的**，毛刺也不是新问题。逐项对照：

| 通道 | 今天 | 以前（docs/13 [实测]） | 判断 |
|---|---|---|---|
| CH1 P0.6 | Top **4.48 V**，Rise 30 ns | 4.28–4.34 V | ✓ P0.6 正常 |
| CH2 G1 | Top **2.00 V**，+Wid **5.000 µs** | 1.96–2.0 V，5.000 µs | ✓ TRIG IN 有 50 Ω |
| CH1→CH2 延迟 | **550 ns** | 570–590 ns | ✓ 差 20–40 ns，先记下来 |
| CH3 G2 | +Wid **200 ns**，在 G1 后约 2.0 µs | 200 ns，1.98 µs | ✓ 时间对 |
| CH3 高度 | **约 2.3 V** | 约 1.0 V | ⚠ 见下面 |

## 那些「毛刺」是什么
1. **CH2 上升沿顶上的尖、下降沿下面的尖**：这是边沿的**过冲和振铃**，以前每次都有（10/9 Over 49%/51%，10/10 56%），今天是 51%/55%，基本一样。
   - 原因：示波器那根线是一段末端没有端接的分支（示波器输入是 1 MΩ），20 ns 的快边沿在这段线里来回反射。
   - 10/9 把三通直接插在 TRIG IN 上量过，那一头的过冲小一些（37%，峰值 2.72 V），离 TRIG IN 的 5 V 量程很远。ATS 只看信号往上穿过 0.87 V 的那一下，以前 400/400 的结果都是带着这些尖量出来的。**不用处理。**
2. **CH3 那根又细又高的「针」**：这就是 200 ns 的测试脉冲本身。在 1 µs/格下它只占 0.2 格，看起来像毛刺。想看清楚形状（可选）：触发 Source 改 CH3、Level 0.5 V，H 调到 50 ns/格，再打一发。
3. **基线上 mV 级的细碎小刺**：环境噪声，SR2 上电后的斩波噪声也在里面（docs/13 §3.1 记过）。CH1、CH2 的 Base 只有 −31 mV 和 −18 mV，没有影响。

## 要留意的一点：CH3 约 2.3 V，以前是约 1 V
发生器设的是 Load（按 50 Ω 负载输出 1 Vpp）。如果另一头没有 50 Ω，电压就会翻倍，变成约 2 V。所以现在多半是：
- **CH A 还不是 50 Ω**：程序在 `bscan_test.m:260` 才把它设成 50 Ω，今天还没跑过 B；或者
- G2 那根线没插到 ATS 的 **CH A**（挡板从上往下第 2 个口）。

先看一眼挡板。线插着的话，等第一次跑 B 之后再看 CH3：变回约 1 V，就是阻抗的原因，没问题；还是约 2 V，就要查线。

## 下一步
1. `write(d,0); clear d`
2. 测试 A（P0.6 保持 0，数 2 s）：应为 **0**
3. 打 5 发：应为 **5**

把两个 ctr1 的读数发给我。这两个都对了，触发链和 PFI3 计数就确认完了，接下来做 Y 的 2.2。

### 🧑 用户 · 2026-10-14 14:57

我现在要确认什么什么都还没改基于现在的情况 现在是cha 连接g2 trigger in连接g1

### 🤖 Claude · 2026-10-14 14:58

ATS 那边接对了：G1 → TRIG IN，G2 → CH A。所以 CH3 约 2.3 V 只是因为今天还没跑过 B，CH A 还没被程序设成 50 Ω（`bscan_test.m:260`），**现在不用处理**。第一次跑 B 之后再看一眼 CH3，应该回到约 1 V。

代码现在也不用改：下面两个测试都在命令行里敲。`test2_Y.m` 和 `bscan_test.m:37` 等做到 Y 和 B 的时候再改。

## 已经确认的
- MATLAB 在 07_MATLAB
- KORAD：23.88 V、约 0.1 A、C.V 灯亮；三台驱动器绿灯闪
- 发生器设置；背面接线：10MHz REF 空着（CH1 上的 10 MHz 没有了），CH2 AUX 接上了（G2 能触发）
- 示波器设置（D = 0，各通道 1X）
- 静态打一发：P0.6 4.48 V，G1 2.00 V、5 µs，G2 200 ns、比 G1 晚约 2 µs
- ATS 接线：G1 → TRIG IN，G2 → CH A

## 现在只剩两件要确认：PFI3 计数
**1. 测试 A**：P0.6 一直保持 0，数 2 秒，应该是 **0**。
```matlab
clear d dq cnt; daqreset
cnt = daq("ni"); addinput(cnt,"Dev1","ctr1","EdgeCount"); resetcounters(cnt);
d = daq("ni"); addoutput(d,"Dev1","port0/line6","Digital"); write(d,0);
c0 = read(cnt,"OutputFormat","Matrix"); pause(2);
c1 = read(cnt,"OutputFormat","Matrix"); fprintf('P0.6 保持 0、2 s：ctr1 = %d（应为 0）\n', c1 - c0);
clear d cnt
```

**2. 打 5 发**：应该是 **5**。
```matlab
clear d dq cnt; daqreset
cnt = daq("ni"); addinput(cnt,"Dev1","ctr1","EdgeCount"); resetcounters(cnt);
d = daq("ni"); addoutput(d,"Dev1","port0/line6","Digital");
write(d,0); c0 = read(cnt,"OutputFormat","Matrix");
for k = 1:5, write(d,1); pause(0.2); write(d,0); pause(0.2); end
c1 = read(cnt,"OutputFormat","Matrix"); fprintf('ctr1：%d（应为 5）\n', c1 - c0);
clear d cnt
```
每段开头的 `clear d dq cnt; daqreset` 会先把 P0.6 现在的高电平放掉，所以不用另外再运行 `write(d,0)`。

把两个打印结果发给我。都对的话，触发链就确认完了，下一步做 Y：先看铭牌和拨码、拍照（2.1），再量 P0.2/P0.3 的静态电平（2.2）。

### 🧑 用户 · 2026-10-14 14:59

>> d = daq("ni"); addoutput(d,"Dev1","port0/line6","Digital"); write(d,0); write(d,1)
>> clear d dq cnt; daqreset
cnt = daq("ni"); addinput(cnt,"Dev1","ctr1","EdgeCount"); resetcounters(cnt);
d = daq("ni"); addoutput(d,"Dev1","port0/line6","Digital"); write(d,0);
c0 = read(cnt,"OutputFormat","Matrix"); pause(2);
c1 = read(cnt,"OutputFormat","Matrix"); fprintf('P0.6 保持 0、2 s：ctr1 = %d（应为 0）\n', c1 - c0);
clear d cnt
P0.6 保持 0、2 s：ctr1 = 0（应为 0）>> clear d dq cnt; daqreset
cnt = daq("ni"); addinput(cnt,"Dev1","ctr1","EdgeCount"); resetcounters(cnt);
d = daq("ni"); addoutput(d,"Dev1","port0/line6","Digital");
write(d,0); c0 = read(cnt,"OutputFormat","Matrix");
for k = 1:5, write(d,1); pause(0.2); write(d,0); pause(0.2); end
c1 = read(cnt,"OutputFormat","Matrix"); fprintf('ctr1：%d（应为 5）\n', c1 - c0);
clear d cnt
ctr1：5（应为 5）现在可以了不 电阻要再确认一下不 示波器结果还要给你不

### 🤖 Claude · 2026-10-14 14:59

**可以了，触发链和 PFI3 计数都确认完了。** 测试 A = 0，打 5 发 = 5：PFI3 只数 P0.6 发出的沿，外面没有东西再往这条线上送信号。

三个问题：
1. **可以了吗**：可以了。今天触发链上找到的问题有：三通插在了 10MHz REF 上、CH2 被改成了 Sine、示波器 D 是 39 ms、CH2 的 Probe 被改过。都已经改回来了。
2. **电阻要不要再确认**：不用。TRIG IN 上 G1 的 Top 是 **2.00 V**，这本身就证明 TRIG IN 那头有 50 Ω：没有 50 Ω 的话会翻倍到约 4 V（docs/13 §3.3 用万用表量过，是 50.2 Ω）。CH A 是程序设的，不用万用表；第一次跑 B 之后看一眼 CH3 回到约 1 V 就行。
3. **示波器结果还要不要发**：现在不用。做 Y 的时候用不到示波器。下次要看是在第一次跑 B 的时候：CH1 约 4.3 V、宽约 8 µs；CH3 回到约 1 V。那时候拍一张就行。

---

## 下一步：Y 轴（先断电）
**为什么要断电**：要用手摇滑台。SR2 上着电时，空闲电流会把电机锁住，硬摇会伤电机（docs/01）。

**① KORAD 关 POWER**，三台驱动器的灯全灭。

**② 摆位置（0.4）**
- **X**：手轮摇到一端，轻轻顶住，再往回摇 **13.5 圈**，在手轮上贴一个记号。
- **Y**：先找铭牌，记下型号、行程、导程。再看一下 Y 两边各留了多少：都 ≥ 10 mm 就够了，不用摇到正中间。同样贴一个记号。

**③ 看 Y 的驱动器和拨码，拍照（2.1）**
- 顺着 Y 滑台的 DB9 线找到 Y 的驱动器，记下序列号，贴上「Y」的胶带。
- 拍照：Y 铭牌、Y 驱动器标签、SW1–8（端子那一面）、SW9–12（侧面）、BNC-2110 上 P0.2/P0.3 的孔、Y 驱动器的 STEP−/DIR−/+5 V 接线、Z 上的水槽托盘。
- 拨码**只看，不要拨**。照片发给我，我对照标签上的表和你一起读：SW1–3 是电流，SW4 是空闲电流，SW5–8 是细分。

**④ 静态电平（2.2，SR2 断电也能测）**

万用表打 DC V 档，黑表笔接 BNC-2110 的 D GND，红表笔接 Y 驱动器的 **STEP−**：
```matlab
d = daq("ni"); addoutput(d,"Dev1","port0/line2","Digital");
write(d,0)   % 量：应约 0 V
write(d,1)   % 量：应约 5 V
write(d,0); clear d
```
然后把 `line2` 换成 `line3`，红表笔换到 Y 的 **DIR−**，再做一遍。顺便看一眼：P0.2 翻转的时候，X、Z 的 STEP− 读数不变。

最后把**照片 + 4 个电压读数**发给我。两样都对了，再给 KORAD 上电，做 2.3（`test2_Y.m` 走第一步）。

### 🧑 用户 · 2026-10-14 15:00

ymotor 跟xmotor是一样的厂家型号 只是接线不同

### 🤖 Claude · 2026-10-14 15:01

这条有用，但它只定下了一半。

## 电机型号一样，说明了什么
- 三台电机都是信浓 **SST43D2126**（docs/01 已记），1.8°/步，所以每转 **200 个整步**，和 X 一样。`test2_Y.m` 第 24 行 `200 * …` 里的 **200 不用改**。
- 但 **µm/脉冲 = 导程 ÷ 每转脉冲数**，还有两样跟电机型号无关：
  1. **细分**：每台驱动器的 SW5–8 是单独拨的，Y 的不一定和 X 一样（X 是 ON OFF ON OFF = 4000 步/转）。所以还是要看 **Y 驱动器的拨码**。
  2. **导程**：要看**滑台**的铭牌，不是电机的铭牌。docs/01 是靠「这个电机只配 CXPF 系列」推断三台都是 2 mm 导程，这是推断，没有核对过实物。你估计 Y 行程约 15 cm，X 的 CXPF50 只有 50 mm，所以 Y 的滑台很可能是另一个型号。
- 两样都按 X 的值写也可以，但第一次移动要小（2.3：+200 µm）。手轮转了多少度，能直接反推细分：36° 就是 4000 步/转。2.4 再用卡尺量 10 mm 核对导程。

## 「接线不同」是哪里不同？
想确认一下你说的是哪一种：
- **电机线**（驱动器上 A+/A−/B+/B− 的线色和 X 不一样）：
  - 只是同一组线圈的两根对调，影响的**只是转向**，2.3 会测出来，`POSITIVE_DIR` 照实测写就行；
  - 如果两组线圈接混了，电机会嗡嗡响、抖、不正常转，2.3 第一步就能看出来；
  - 你上电时三台都是绿灯闪，说明线圈都接上了（线圈断开会报 1 绿 + 6 红）。
- **信号线**（P0.2/P0.3 → Y 的 STEP−/DIR−）：这正是 2.2 要用万用表确认的。

两种情况都**先别改线**，拍一张 Y 驱动器电机端子的照片，我和 X 对照着记进 docs/01。X 的线色是：B− 白、B+ 灰、A− 蓝、A+ 绿。

## 还差的
1. KORAD 关了吗？关了再摇手轮。
2. Y **滑台**铭牌（型号、行程、导程）
3. Y 驱动器的 SW1–8、SW9–12，和序列号
4. Y 驱动器的接线照片（电机端和信号端）
5. 2.2 的 4 个电压读数

拍好就发给我，拨码我来对照标签上的表一起读。

### 🧑 用户 · 2026-10-14 15:09

好了

### 🤖 Claude · 2026-10-14 15:09

先把两张拨码照片放大，读清楚每个开关的位置：

### 🤖 Claude · 2026-10-14 15:09

> 🔧 PowerShell · description: Crop and enlarge DIP switch regions

### ⚙️ 工具 · 2026-10-14 15:09

<details><summary>工具输出</summary>

```
ok
```
</details>

### 🤖 Claude · 2026-10-14 15:09

> 🔧 Read · file_path: C:\Users\2031\AppData\Local\Temp\claude\C--Users-2031-Desktop-Research-PAM--claude-worktrees-sad-poincare-cd40d6\39c1b058-7d7e-4e2f-b00b-4222fef61888\scratchpad\y_sw1-8.jpg

### ⚙️ 工具 · 2026-10-14 15:09

<details><summary>工具输出</summary>

```
[图片]
```
</details>

### 🤖 Claude · 2026-10-14 15:09

> 🔧 Read · file_path: C:\Users\2031\AppData\Local\Temp\claude\C--Users-2031-Desktop-Research-PAM--claude-worktrees-sad-poincare-cd40d6\39c1b058-7d7e-4e2f-b00b-4222fef61888\scratchpad\y_sw9-12.jpg

### ⚙️ 工具 · 2026-10-14 15:09

<details><summary>工具输出</summary>

```
[图片]
```
</details>

### 🤖 Claude · 2026-10-14 15:09

> 🔧 Read · file_path: C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\screenshots\HW_SR2_terminal_face_SW1-8_clear.jpg

### ⚙️ 工具 · 2026-10-14 15:09

<details><summary>工具输出</summary>

```
[图片]
```
</details>

### 🤖 Claude · 2026-10-14 15:10

照片读出来了。**Y 驱动器的拨码和 X 完全一样**，所以 `test2_Y.m` 第 24–25 行可能都不用改：

| 项 | Y（你拍的 243106105） | X（docs/01） |
|---|---|---|
| SW1–3 | ON ON ON → **0.3 A** | 同 |
| SW4 | ON → 空闲时半电流 | 同 |
| SW5–8 | **ON OFF ON OFF → 4000 步/转** | 同 |
| SW9–12 | OFF ON OFF OFF | 同 |
| 电机线 | B− 白、B+ 灰、A− 蓝、A+ 绿；V− 黑、V+ 红 | 看起来一样 |
| 信号线 | DIR− 绿、DIR+ 蓝、STEP− 黄、STEP+ 白 | — |

读法：SW1–8 旁边印的是「ON ↑」，开关拨向数字那一侧是 ON。放大后看得很清楚，6 号和 8 号是拨下去的（OFF），其余都是 ON。照片读反的话会变成 OFF ON OFF ON = 6400 步/转。到底读没读反，2.3 第一步看手轮角度就能确定：400 个脉冲，转 **36°** 就是 4000 步/转；转 22.5° 就是 6400 步/转。

KORAD：**23.88 V、0.112 A、C.V 亮**，正常。比之前的 0.098–0.100 A 多了约 12 mA，可能是刚上电不久（待确认），只要 C.V 亮着就没问题。

## 还差的四样
1. **这台 243106105 确定是 Y 吗？** 是顺着 Y 滑台的 DB9 线找到的吗？docs/01 里这台和 243106317 哪台是 Y、哪台是 Z 还没记。
2. **Y 滑台的铭牌**：要看的是滑台，不是电机。记下型号、行程、导程。导程是 2 mm 的话，第 25 行 `2000 / STEPS_PER_REV` 不用改。
3. **2.2 的 4 个电压读数**：现在 SR2 上着电也可以测（每次从 1 变 0，Y 只走 1 个微步，0.5 µm）。万用表黑表笔接 D GND，红表笔接 Y 的 STEP−：
   ```matlab
   d = daq("ni"); addoutput(d,"Dev1","port0/line2","Digital");
   write(d,0)   % 应约 0 V
   write(d,1)   % 应约 5 V
   write(d,0); clear d
   ```
   再把 `line2` 换成 `line3`，红表笔换到 DIR−，重复一遍。
4. **X 摇到中间、Y 两边留够余量、两个手轮贴记号（0.4）做了吗？** 摇手轮必须先关 KORAD。

## 这四样确认后：做 `test2_Y.m`（2.3）
在 07_MATLAB 里把 `test2.m` **另存为** `test2_Y.m`，原来的 `test2.m` 不动。拨码已经确认，现在只要改 6 行：

| 行 | 原来 | 改成 |
|---|---|---|
| 17 | `MOVE_UM = -2400;` | `200` |
| 18 | `SPEED_MM_S = 4;` | `1` |
| 21 | `"port0/line0"` | `"port0/line2"` |
| 22 | `"port0/line1"` | `"port0/line3"` |
| 26 | `MAX_SPEED_MM_S = 20;` | `4` |
| 27 | `MAX_MOVE_UM = 20000;` | `1000` |

第 13 行保持 `false`，第 14 行保持 `false`，第 23–25 行不动。第 14 行和第 21–22 行的注释里写的是 P0.0/P0.1，可以顺手改成 P0.2/P0.3。

改完先跑检查模式，应打印：
```
脉冲数 400，实际频率 2000.0 Hz，用时 0.200 s
方向 DIR = 1，预计移动 +200.0 um，速度 1.000 mm/s（上限 4 mm/s）
```
把 2.2 的读数、铭牌，和检查模式的打印一起发给我，确认以后再把第 13 行改成 `true`，走第一步。

### 🧑 用户 · 2026-10-14 15:11

是的 是一样的 可以不做记号么我手动摇可以么 还有怎么测电压读数详细一点还有为什么要测

### 🤖 Claude · 2026-10-14 15:13

我理解你说的是：**这台 243106105 就是 Y，Y 滑台铭牌和 X 一样**（CXPF50-80100：行程 50 mm，导程 2 mm）。如果是这样：
- `test2_Y.m` 第 25 行 `2000 / STEPS_PER_REV` **不用改**，Y 也是 0.5 µm/脉冲（待 2.4 实测确认）。
- Y 的行程是 50 mm（X 实测端到端约 27 圈 ≈ 54 mm），**不是之前估的 15 cm**。2.4 要单向走 10 mm，所以 Y 需要大致在中间。

理解错了告诉我。

## 记号能不能不做？手动摇可以吗？
**手动摇可以，摇之前先关 KORAD。** SR2 上电时，空闲电流会把电机锁住，硬摇会伤电机。

**记号不能省**，但只要 1 分钟。滑台没有限位、没有编码器，手轮记号是我们判断位置的唯一参照，后面每一步都靠它：
- 2.3：400 个脉冲，手轮要转 **36°**，才能证明是 4000 步/转；
- 2.4：正好 **5 圈**；
- 2.5、2.6：**回到记号 ±5°**（±5° ≈ ±28 µm，1° ≈ 5.6 µm）。

没有记号，就只知道「它动了」，量不出动了多少，也看不出有没有回到原位。

最简单的做法是做**两个记号对齐**：
1. 手轮边缘贴一小条胶带当指针，它会跟着转；
2. 电机外壳上、正对着这条胶带的地方再贴一条，或者用记号笔画一条线，它固定不动。
3. 两条对齐的位置就是「零」。

顺序：
1. KORAD 关
2. 摇到位置：Y 摇到一端轻轻顶住，再往回摇 13.5 圈。X 如果看着已经离两端都有好几 mm，可以不摇。
3. KORAD 开，等驱动器绿灯闪
4. **再贴记号**

为什么要上电以后再贴：上电那一下，电机可能会自己跳几度。

## 2.2 量电压
### 为什么要测
P0.2/P0.3 接到 Y，到现在只是**看线**确认的。如果其实插到了 Z 的线上（Z 上放着水槽），或者插在旁边的孔里，2.3 一跑，动的就是别的轴。量电压不会让任何轴动起来，是最便宜的确认方法。

### 原理（共阳极接法）
驱动器里，STEP+ 和 STEP− 之间是一个光耦的 LED，STEP+ 接 +5 V。
- **线接对了**：写 0 时，P0.2 把 STEP− 拉到**约 0 V**（LED 亮）；写 1 时变成**约 5 V**。
- **线没接上**：STEP− 悬空，经过 LED 被拉向 +5 V，不管写什么，读数都是高的。

所以「读到高电平」证明不了什么，**只有「写 0 就变成 0 V，写 1 又回到 5 V」才能证明 P0.2 真的接在 Y 的 STEP− 上**。DIR 同理：DIR 要是没接上，电机只会往一个方向走，2.3 往回走 −200 µm 时会继续往前跑。

### 具体步骤（万用表 AstroAI AM33D）
1. 旋钮拨到**直流电压档（V 旁边是直线的那一组）的 20 V 档**。
2. 黑表笔插 **COM**，红表笔插 **VΩmA**。
3. **黑表笔**接 **KORAD 的黑色 − 接线柱**。它和 BNC-2110 的 D GND 是连在一起的（docs/01），接线柱大，旁边没有别的端子，不容易碰错。
4. 先验一下表：红表笔点 **Y 驱动器的 STEP+ 螺丝**（白线那颗），应该读到**约 5 V**。读到了，说明表和地都没问题。
5. MATLAB：
   ```matlab
   d = daq("ni"); addoutput(d,"Dev1","port0/line2","Digital");
   write(d,0)
   ```
   红表笔点 **Y 的 STEP− 螺丝**（黄线那颗），记下读数，应**约 0 V**。
6. `write(d,1)`，再读，应**约 5 V**。
7. `write(d,0)`，再读，应回到约 0 V。
8. 红表笔换到 **X 驱动器**（贴着 X motor 胶带的那台）的 STEP−，`write(d,1)`、`write(d,0)` 各读一次，两次读数应该**一样**（不跟着变）。**Z 驱动器**（243106317）的 STEP− 也这样读一次。
9. `clear d`。把第 5 步的 `line2` 改成 `line3`，红表笔换到 **Y 的 DIR−**（绿线那颗），重复第 5–7 步。

注意：
- 红表笔每次只碰**一颗**螺丝，别同时碰到旁边的。STEP− 旁边就是 STEP+（+5 V）；电源端子那边 V+ 和 V− 挨着，碰在一起就是把 24 V 短路。
- SR2 上着电的时候，P0.2 每从 1 变到 0 一次，Y 就走 1 个微步（0.5 µm），没有影响。

把结果按这个表发给我：

| | 写 0 | 写 1 | 再写 0 |
|---|---|---|---|
| Y STEP−（line2） | | | |
| X STEP−（P0.2 翻转时） | — | | |
| Z STEP−（P0.2 翻转时） | — | | |
| Y DIR−（line3） | | | |

### 🧑 用户 · 2026-10-14 15:18

是的前后是0.2 和5 能不能记录一下 还有就是y轴没办法量做记号 和x大概率是一样的 可以用手摇测么 我要去上课了 存一下

### 🤖 Claude · 2026-10-14 15:19

先看主目录现在的状态（另一个 C-scan 窗口也在改 docs/01 和 docs/14），再写记录。

### 🤖 Claude · 2026-10-14 15:19

> 🔧 Bash · description: Check main repo status, docs headings, export tool

### ⚙️ 工具 · 2026-10-14 15:19

<details><summary>工具输出</summary>

```
0fab09a 2026-10-14 C-scan: cscan_test.m / cscan_replot.m 第一版草稿（检查模式 + 假数据离线测试通过，硬件路径未运行）
0ba1bf5 2026-10-14 C-scan: 06_控制程序/CLAUDE.md 硬件速查标 Y 接线已看线确认（用户同意）
56be758 2026-10-13 C-scan: docs/14 写入用户对「还要确认的」的回答；Y 接线看线确认（docs/01、14）
---
8:## 先定的两件事
16:## 安全（每次上硬件都适用）
27:## 附 A　第一版 10 × 10 的参数 [条件计算]
51:## 附 B　如果行内改成 step-and-settle
58:## 阶段 0　开工检查
94:## 阶段 1　离线检查模式（不碰硬件，Mac 上也能做）
132:## 阶段 2　Y 轴（照 X 轴的做法，docs/07 第 1 周 1.2）
180:## 阶段 3　单行 C-scan = B-scan 回归
195:## 阶段 4　两行（Rui 来看可以从这里开始）
215:## 阶段 5　10 × 10
224:## 阶段 6　测试（07 第 3 周 ①–⑥ + 加做）
303:## 阶段 7　收尾和记录
317:## 还要和你（或 Rui）确认的
---
  331 06_控制程序/do
…[截断，共 1540 字符]
```
</details>

### 🤖 Claude · 2026-10-14 15:19

You've hit your session limit · resets 2:20pm (America/New_York)

### 🧑 用户 · 2026-10-14 18:21

I hit my usage limit while you were working, but it has reset now. Please continue from where you left off.

### 🤖 Claude · 2026-10-14 18:22

主目录是干净的，最新提交是 C-scan 窗口的 `0fab09a`。下面开始写记录：先存照片，再更新 docs，最后提交。

### 🤖 Claude · 2026-10-14 18:22

> 🔧 Bash · description: Read screenshots README format and safety flags

### ⚙️ 工具 · 2026-10-14 18:22

<details><summary>工具输出</summary>

```
# 截图和照片清单

## 怎么用
1. 按下表的文件名保存到本文件夹（png 或 jpg 都可以）。框图太大就分块截，在文件名后加 `_1`、`_2`；case 结构的**每个分支**都要截。
2. 在当前窗口说"读一下新截图"。Claude 读图后，把要点写进 `../02_LabVIEW程序地图.md` 的"截图转写"部分（或 `../01_硬件与接线.md`），再把下表的状态改成"已转写"。
3. 以后的新窗口直接读 md 文字就行，不用每次重新看图。图片会一直留着，需要时可以再看。

## LabVIEW 截图
| 文件名 | 内容 | 状态 |
|---|---|---|
| `LV_Main_FP_Settings.png` | Main.vi 前面板 Settings 页，填好平时用的参数 | 10/4 已转写（02） |
| `LV_Main_FP_IO.png` | 前面板 I/O 页（DO 采样率、线路、触发等） | 10/4 已转写（02） |
| `LV_Main_FP_Scan.png` | 前面板 Scan 页（delta_x、Motor Pulse Rate、Trig Rate、Subpixel Num 等） | 10/4 已转写（02） |
| `LV_GenerateSkipPulses_FP/BD_1–4.png`、`
…[截断，共 2911 字符]
```
</details>

### 🤖 Claude · 2026-10-14 18:22

先把今天的照片缩小后存进 screenshots（长边 1600 px，每张约几百 KB）：

### 🤖 Claude · 2026-10-14 18:22

> 🔧 PowerShell · description: Downscale and save today's photos to screenshots

### ⚙️ 工具 · 2026-10-14 18:22

<details><summary>工具输出</summary>

```
SCOPE_1014_before_D39ms.jpg  384 KB
HW_DG852_rear_tee_on_10MHzREF_1014.jpg  275 KB
SCOPE_1014_CH1_10MHz_from_REF.jpg  345 KB
HW_DG852_1014_before_channel.jpg  295 KB
HW_DG852_1014_before_main.jpg  339 KB
HW_DG852_1014_after_channel.jpg  322 KB
SCOPE_1014_static_shot_measure.jpg  320 KB
SCOPE_1014_static_shot_wave.jpg  287 KB
HW_BNC2110_P02_P03_1014.jpg  353 KB
HW_SR2_Y_label.jpg  406 KB
HW_SR2_Y_terminals.jpg  390 KB
HW_SR2_Y_SW1-8.jpg  363 KB
HW_SR2_Y_SW9-12.jpg  291 KB
HW_KORAD_1014.jpg  248 KB
HW_Y_static_check_1014_5V.jpg  365 KB
HW_Y_static_check_1014_0V.jpg  344 KB
```
</details>

### 🤖 Claude · 2026-10-14 18:22

照片存好了（16 张，每张 250–400 KB）。下面更新 docs/01（Y 轴的事实）：

### 🤖 Claude · 2026-10-14 18:22

> 🔧 Bash · description: Check recent changes to docs I will edit

### ⚙️ 工具 · 2026-10-14 18:23

<details><summary>工具输出</summary>

```
0fab09a 2026-10-14 C-scan: cscan_test.m / cscan_replot.m 第一版草稿（检查模式 + 假数据离线测试通过，硬件路径未运行）
56be758 2026-10-13 C-scan: docs/14 写入用户对「还要确认的」的回答；Y 接线看线确认（docs/01、14）
3a82166 Merge remote-tracking branch 'origin/main'
  - 结构：开关（默认 RUN_HARDWARE = false、MOCK_DATA = true、Y_CALIBRATED = false）→ §1 参数（docs/14 附 A：10×10、Δ 10 µm、4 mm/s）→ §2 硬件参数（CH A 阻抗、TRIG I
  - 离线测试全部通过：T1 10×10（K = 20、fs = 248000、wTrig = 2、每行 0.683 s、全程 6.91 s、MAP(3,7) = 3.07、存盘重读 isequal = 1）、T2 10×4、T6 20×5、T7 重画；T3/T4/T
  - 和 docs/14 附 A 的差别：每行总时长一样（0.68 s），但拆分是行扫描 0.32 s + 回程 + Y 0.36 s（两次停稳都在回程表里）；3.2 的判据应是 readwrite ≥ 0.32 s。
  -
…[截断，共 925 字符]
```
</details>

### 🤖 Claude · 2026-10-14 18:23

> 🔧 Bash · description: List files changed in latest C-scan commit

### ⚙️ 工具 · 2026-10-14 18:23

<details><summary>工具输出</summary>

```
0fab09a 2026-10-14 C-scan: cscan_test.m / cscan_replot.m 第一版草稿（检查模式 + 假数据离线测试通过，硬件路径未运行）

 06_控制程序/docs/工作日志.md |    9 +
 07_MATLAB/cscan_replot.m     |  132 ++++++
 07_MATLAB/cscan_test.m       | 1034 ++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 1175 insertions(+)
Shell cwd was reset to C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6
```
</details>

### 🤖 Claude · 2026-10-14 18:23

> 🔧 Edit · file_path: C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\01_硬件与接线.md

### ⚙️ 工具 · 2026-10-14 18:23

<details><summary>工具输出</summary>

```
PreToolUse:Edit hook error: This session is running in an isolated git worktree at `C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6`, but `C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\01_硬件与接线.md` is in the base repo checkout. Edits there do not land on this session's branch and may corrupt the user's primary working copy. Use the worktree path instead: `C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6\06_控制程序\docs\01_硬件与接线.md`
```
</details>

### 🤖 Claude · 2026-10-14 18:23

> 🔧 Edit · file_path: C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\01_硬件与接线.md

### ⚙️ 工具 · 2026-10-14 18:23

<details><summary>工具输出</summary>

```
PreToolUse:Edit hook error: This session is running in an isolated git worktree at `C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6`, but `C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\01_硬件与接线.md` is in the base repo checkout. Edits there do not land on this session's branch and may corrupt the user's primary working copy. Use the worktree path instead: `C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6\06_控制程序\docs\01_硬件与接线.md`
```
</details>

### 🤖 Claude · 2026-10-14 18:23

> 🔧 Edit · file_path: C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\01_硬件与接线.md

### ⚙️ 工具 · 2026-10-14 18:23

<details><summary>工具输出</summary>

```
PreToolUse:Edit hook error: This session is running in an isolated git worktree at `C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6`, but `C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\01_硬件与接线.md` is in the base repo checkout. Edits there do not land on this session's branch and may corrupt the user's primary working copy. Use the worktree path instead: `C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6\06_控制程序\docs\01_硬件与接线.md`
```
</details>

### 🤖 Claude · 2026-10-14 18:23

> 🔧 Edit · file_path: C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\01_硬件与接线.md

### ⚙️ 工具 · 2026-10-14 18:23

<details><summary>工具输出</summary>

```
PreToolUse:Edit hook error: This session is running in an isolated git worktree at `C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6`, but `C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\01_硬件与接线.md` is in the base repo checkout. Edits there do not land on this session's branch and may corrupt the user's primary working copy. Use the worktree path instead: `C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6\06_控制程序\docs\01_硬件与接线.md`
```
</details>

### 🤖 Claude · 2026-10-14 18:23

> 🔧 Edit · file_path: C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\01_硬件与接线.md

### ⚙️ 工具 · 2026-10-14 18:23

<details><summary>工具输出</summary>

```
PreToolUse:Edit hook error: This session is running in an isolated git worktree at `C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6`, but `C:\Users\2031\Desktop\Research-PAM\06_控制程序\docs\01_硬件与接线.md` is in the base repo checkout. Edits there do not land on this session's branch and may corrupt the user's primary working copy. Use the worktree path instead: `C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6\06_控制程序\docs\01_硬件与接线.md`
```
</details>

### 🤖 Claude · 2026-10-14 18:23

> 🔧 PowerShell · description: Move today's photos from main checkout into worktree

### 🤖 Claude · 2026-10-14 18:23

> 🔧 ToolSearch · query: select:mcp__ccd_host__sync_with_base_branch

### ⚙️ 工具 · 2026-10-14 18:24

<details><summary>工具输出</summary>

```
main untracked left:
worktree:
16
```
</details>

### ⚙️ 工具 · 2026-10-14 18:24

<details><summary>工具输出</summary>

```
[图片]
```
</details>

### 🤖 Claude · 2026-10-14 18:24

> 🔧 Bash · description: Compare worktree branch, local main, origin/main

### ⚙️ 工具 · 2026-10-14 18:24

<details><summary>工具输出</summary>

```
Exit code 128
fatal: Needed a single revision
```
</details>

### 🤖 Claude · 2026-10-14 18:24

> 🔧 Bash · description: Inspect branch refs and remotes

### ⚙️ 工具 · 2026-10-14 18:24

<details><summary>工具输出</summary>

```
56be758
0fab09a
  origin/HEAD -> origin/main
  origin/main
origin	https://github.com/yumengchen8366/Research-PAM.git (fetch)
origin	https://github.com/yumengchen8366/Research-PAM.git (push)
 07_MATLAB/cscan_replot.m     |  132 ++++++
 07_MATLAB/cscan_test.m       | 1034 ++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 1176 insertions(+), 1 deletion(-)
```
</details>

### 🤖 Claude · 2026-10-14 18:24

正在把 worktree 快进到本地 main 的最新版本（含 C-scan 窗口今天的提交），然后在 worktree 里写记录。

### 🤖 Claude · 2026-10-14 18:24

> 🔧 Bash · description: Fast-forward worktree branch to local main

### ⚙️ 工具 · 2026-10-14 18:24

<details><summary>工具输出</summary>

```
Updating 56be758..0fab09a
Fast-forward
 06_控制程序/CLAUDE.md        |    2 +-
 06_控制程序/docs/工作日志.md |    9 +
 07_MATLAB/cscan_replot.m     |  132 ++++++
 07_MATLAB/cscan_test.m       | 1034 ++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 1176 insertions(+), 1 deletion(-)
 create mode 100644 07_MATLAB/cscan_replot.m
 create mode 100644 07_MATLAB/cscan_test.m
0fab09a 2026-10-14 C-scan: cscan_test.m / cscan_replot.m 第一版草稿（检查模式 + 假数据离线测试通过，硬件路径未运行）
0ba1bf5 2026-10-14 C-scan: 06_控制程序/CLAUDE.md 硬件速查标 Y 接线已看线确认（用户同意）
```
</details>

### 🤖 Claude · 2026-10-14 18:24

Now I'll read the worktree copies of the files to be edited (the Edit tool requires reading them first):

### 🤖 Claude · 2026-10-14 18:24

> 🔧 Read · file_path: C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6\06_控制程序\docs\01_硬件与接线.md

### ⚙️ 工具 · 2026-10-14 18:24

<details><summary>工具输出</summary>

```
29	| 项目 | 内容 | 状态 |
30	|---|---|---|
31	| 滑台 | 卓立汉光 CXPF50-80100：行程 50 mm，丝杠导程 2 mm，最高 20 mm/s。X 轴实测端到端约 **27 圈 ≈ 54 mm**（10/7 晚 SR2 断电手轮摇，两个方向一致，±半圈） | ✔（铭牌）+ 实测 |
32	| 驱动器 | 鸣志 SR2，STEP/DIR 光耦输入；手册：`New folder\SR2 Driver.pdf` | ✔ |
33	| 电机 | 三个滑台都是信浓 **SST43D2126**（42 型，1.8°/步，1.65 Ω，额定 1.7 A/相；批号 15770G、13610G、13610G，`HW_motor_SST43D2126_*.jpg`）。按 CXP 手册选型表，这个电机只配 CXPF 系列（2 mm 导程），所以 X/Y/Z 都是 2 mm 导程。电机尾部有滚花手轮，和电机轴一起转 | ✔（铭牌） |
34	| 整步距离 | 每转 200 整步时，1 个脉冲 = 10 µm（LabVIEW 前面板原文 "1 pulse = 10 um under 200 step setting"） | ◐ |
35	| **细分 / µm/脉冲（X）** | **每转 4000 步，0.5 µm/脉冲。** 10/4 实测：`test2.m
…[截断，共 3537 字符]
```
</details>

### 🤖 Claude · 2026-10-14 18:24

> 🔧 Read · file_path: C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6\06_控制程序\docs\14_C-scan测试流程.md

### ⚙️ 工具 · 2026-10-14 18:24

<details><summary>工具输出</summary>

```
315	- 通过：能拿给 Rui 的三样都有了：MAP 图、①–⑥ 测试记录表、计时表 + 3×3 mm 推算。
316	
317	## 还要和你（或 Rui）确认的
318	
319	1. 行内用匀速扫还是 step-and-settle（见开头；问 Rui）。
320	2. 哪天请 Rui 来看；和 Maria 怎么约台架时间。
321	   - 10/13 用户：Rui 来看的日期还没定，要用户去约。用户 10/13 晚回实验室，10/14 晚复习、不做实验。
322	3. ~~Y 台上装了什么（换能器、水槽、线缆），两边各能走多远。~~
323	   - 10/13 用户：Y 台上没有装东西，水槽和托盘在 Z 上；Y 前后约 15 cm（用户估计，未测）。行程和导程按 0.4、2.1 看铭牌和实测确认。
324	4. ~~实验室有没有千分表或百分表；没有就用手轮记号 + 卡尺。~~
325	   - 10/13 用户：好像有，不确定。量位置继续用手轮记号 + 卡尺（以前就是这样做的）。
326	5. 位置容差的数值（问 Rui）；本周暂用 ±5°（约 ±28 µm）。
327	6. ~~停止用 uifigure 按钮，还是检测 STOP 文件。~~ → 10/13 用户定：uifigure"停止"按钮，行与行之间检查 + `drawnow`。
328	7. ~~同意把 B:
…[截断，共 800 字符]
```
</details>

### 🤖 Claude · 2026-10-14 18:24

> 🔧 Read · file_path: C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6\06_控制程序\docs\13_B-scan记录.md

### ⚙️ 工具 · 2026-10-14 18:24

<details><summary>工具输出</summary>

```
20	| Channel 页 | Imped **Load**（50 Ω），Sync Off，Trig Out Off | 同左 |
21	
22	10/10 补充（**已更正，见 §3.3**）：§3.2 里"TRIG IN 是高阻、改用 1.5 Vpp / 0.75 V"是误读——示波器 CH2 的 Probe 被设成了 2X，所有 CH2 读数都翻了倍。实测 TRIG IN 是 **50 Ω**（万用表 50.2 Ω；TRIG IN 端示波器 Top 1.96 V）。**G1 仍用上表的 2 Vpp / 1 V**（TRIG IN 上 0→2 V，峰值约 2.7 V）。不要用 1 Vpp / 0.5 V：TRIG IN 上只有 1.0 V，只比门槛 0.87 V（code 150）高 0.13 V，§3.2 里三次都漏触发。改 Ampl 时 Offset 要一起改（Offset = Ampl/2，低电平才是 0 V）。示波器每次开始前先看各通道 Probe 是不是 1X。
23	
24	注意：AUX IN/OUT 是双向口。先把 Source 设成 Ext、Sync/Trig Out 关掉，再接 P0.6，否则两个输出会顶在一起。
25
```
</details>

### 🤖 Claude · 2026-10-14 18:24

> 🔧 Bash · description: Read worklog tail and screenshots README tail

### ⚙️ 工具 · 2026-10-14 18:24

<details><summary>工具输出</summary>

```
- 做了什么：逐文件（SHA-1）比对 Mac 的 `~/PAM_research-latest`（旧仓库 PAM_research 的本地副本，最后提交 bc87195，10/7）和 `~/Research-PAM`。1940 个文件里 1711 个在 Research-PAM 有完全相同的副本；docs、MATLAB 不同的那几个都是 Research-PAM 里更新过的版本（旧版多出的几行已被改写，不是丢失）。22 个会话的原始 jsonl 都已导出成 08_对话记录 的 Markdown。
- 结果：旧文件夹里 LabPC 的 Claude 记忆比本仓库新（10/4–10/5 vs 10/3），并多一条 `project-bscan-1007.md`，已把这 5 个文件更新进 `08_对话记录/claude-memory/LabPC/`。旧文件夹里只剩原始会话 jsonl（350 MB）和会话里上传的照片（243 MB）没有逐字节副本，没搬。
- 下次第一步：用户决定 `~/PAM_research-latest` 删还是留（照片要的话先挑出来）；GitHub 上的 PAM_research 可以归档。

**2026-10-14｜cscan_test.m 第一版草稿（LabPC，会话 67ed74c7「提前完成 cscan 的计划调整」；用户要求 Claude 先
…[截断，共 2159 字符]
```
</details>

### 🤖 Claude · 2026-10-14 18:24

现在在 worktree 里改 docs/01：

### 🤖 Claude · 2026-10-14 18:24

> 🔧 Edit · file_path: C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6\06_控制程序\docs\01_硬件与接线.md

### 🤖 Claude · 2026-10-14 18:24

> 🔧 Edit · file_path: C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6\06_控制程序\docs\01_硬件与接线.md

### 🤖 Claude · 2026-10-14 18:24

> 🔧 Edit · file_path: C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6\06_控制程序\docs\01_硬件与接线.md

### 🤖 Claude · 2026-10-14 18:24

> 🔧 Edit · file_path: C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6\06_控制程序\docs\01_硬件与接线.md

### 🤖 Claude · 2026-10-14 18:24

> 🔧 Edit · file_path: C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6\06_控制程序\docs\01_硬件与接线.md

### ⚙️ 工具 · 2026-10-14 18:24

<details><summary>工具输出</summary>

```
The file C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6\06_控制程序\docs\01_硬件与接线.md has been updated successfully.
```
</details>

### ⚙️ 工具 · 2026-10-14 18:24

<details><summary>工具输出</summary>

```
The file C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6\06_控制程序\docs\01_硬件与接线.md has been updated successfully.
```
</details>

### ⚙️ 工具 · 2026-10-14 18:24

<details><summary>工具输出</summary>

```
The file C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6\06_控制程序\docs\01_硬件与接线.md has been updated successfully.
```
</details>

### ⚙️ 工具 · 2026-10-14 18:24

<details><summary>工具输出</summary>

```
The file C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6\06_控制程序\docs\01_硬件与接线.md has been updated successfully.
```
</details>

### ⚙️ 工具 · 2026-10-14 18:24

<details><summary>工具输出</summary>

```
The file C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6\06_控制程序\docs\01_硬件与接线.md has been updated successfully.
```
</details>

### 🤖 Claude · 2026-10-14 18:25

docs/13 §2（发生器设置）加一条今天踩到的坑：

### 🤖 Claude · 2026-10-14 18:25

> 🔧 Edit · file_path: C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6\06_控制程序\docs\13_B-scan记录.md

### ⚙️ 工具 · 2026-10-14 18:25

<details><summary>工具输出</summary>

```
The file C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6\06_控制程序\docs\13_B-scan记录.md has been updated successfully.
```
</details>

### 🤖 Claude · 2026-10-14 18:25

docs/14 末尾加今天的实测记录，「还要确认的」第 3、4 条补上今天的回答：

### 🤖 Claude · 2026-10-14 18:25

> 🔧 Edit · file_path: C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6\06_控制程序\docs\14_C-scan测试流程.md

### 🤖 Claude · 2026-10-14 18:26

> 🔧 Edit · file_path: C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6\06_控制程序\docs\14_C-scan测试流程.md

### ⚙️ 工具 · 2026-10-14 18:26

<details><summary>工具输出</summary>

```
The file C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6\06_控制程序\docs\14_C-scan测试流程.md has been updated successfully.
```
</details>

### ⚙️ 工具 · 2026-10-14 18:26

<details><summary>工具输出</summary>

```
The file C:\Users\2031\Desktop\Research-PAM\.claude\worktrees\sad-poincare-cd40d6\06_控制程序\docs\14_C-scan测试流程.md has been updated successfully.
```
</details>

### 🤖 Claude · 2026-10-14 18:26

Worklog entry and the screenshots README:

### 🤖 Claude · 2026-10-14 18:26

> 🔧 Bash · description: Append worklog entry and screenshots README rows

### ⚙️ 工具 · 2026-10-14 18:26

<details><summary>工具输出</summary>

```
M 06_控制程序/docs/01_硬件与接线.md
 M 06_控制程序/docs/13_B-scan记录.md
 M 06_控制程序/docs/14_C-scan测试流程.md
 M 06_控制程序/docs/screenshots/README.md
 M 06_控制程序/docs/工作日志.md
?? 06_控制程序/docs/screenshots/HW_BNC2110_P02_P03_1014.jpg
?? 06_控制程序/docs/screenshots/HW_DG852_1014_after_channel.jpg
?? 06_控制程序/docs/screenshots/HW_DG852_1014_before_channel.jpg
?? 06_控制程序/docs/screenshots/HW_DG852_1014_before_main.jpg
?? 06_控制程序/docs/screenshots/HW_DG852_rear_tee_on_10MHzREF_1014.jpg
?? 06_控制程序/docs/screenshots/HW_KORAD_1014.jpg
?? 06_控制程序/docs/screenshots/HW_SR2_Y_SW1-8.jpg
?? 06_控制程序/docs/screenshots/HW_SR2_Y_SW9-12.jpg
?? 0
…[截断，共 1050 字符]
```
</details>

### 🤖 Claude · 2026-10-14 18:26

导出本次对话。先看一下导出脚本的参数和输出位置：

### 🤖 Claude · 2026-10-14 18:26

> 🔧 Bash · description: Read export script usage and paths

### ⚙️ 工具 · 2026-10-14 18:26

<details><summary>工具输出</summary>

```
﻿# export_pam_chats.py 的 PowerShell 版（Windows PowerShell 5.1 能跑，不用装 Python）。
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
    
…[截断，共 2011 字符]
```
</details>

### 🤖 Claude · 2026-10-14 18:26

> 🔧 PowerShell · description: Export this conversation to 08_对话记录
