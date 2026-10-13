# PAM 学习与科研进度（learning-progress 记录）

> 最近更新：2026-10-13（America/New_York）· 更新标识：2026-10-13-fact-fix
> 2026-10-13 用户要求：所有和 PAM 相关的学习进度从 `yumengchen8366/learning_skill` 的 `progress/current.md` 搬到这里，之后 PAM 主题只在本文件更新；learning_skill 里只留指向本文件的链接（课程等非 PAM 主题仍在那边）。
> 证据代号和写法沿用 learning-progress 技能：讲 = 助手讲解/用户阅读（不证明掌握）；述 = 用户自述懂；独 = 用户独立解释；迁 = 条件变化下预测正确；验 = 实际运行/实测核对。计划和实际执行分开写。
> 和本仓库其他文件的关系：事实以 `06_控制程序/docs/`、工作日志、master 为准；本文件只记录「我理解到哪、卡在哪、下一步练什么」。

## 活动主题

### research-cscan-week：10/13 这周完成 C-scan（测试信号版），并熟悉全部代码和流程
- 目标：本周 C-scan（每行硬件定时"移动–停–触发"，行间程序控制 X 回程 + Y 步进，10 × 10 起步）能准确运行并通过 07 第 3 周测试 ①–⑥；合上资料能讲出下表每个知识点的"定义 → 位置 → 因果 → 依据"。
- 范围（用户 10/13 确定）：只用函数发生器做测试信号，真实光声信号先不开始；采集卡可以用 dual-port（板载内存当缓冲）。
- 资料：Research-PAM 仓库 `07_MATLAB/`（bscan_test.m、ats9462_multi_aline.m、test2.m、aline_edge_time.m、ats9462_aline_test_revised.m）；`06_控制程序/docs/` 01、07、12、13；Rui Phase 1 计划 `02_笔记与上下文/UVPAM_Phase1_Weekly_中英对照与解释.md`。
- 证据代号：讲 = 助手讲解/用户阅读（不证明掌握）；述 = 用户自述懂；独 = 用户独立解释（白纸回忆/口述）；迁 = 条件变化下预测正确；验 = 实际运行/实测核对。

| # | 知识点 | 资料位置 | 当前证据 | 每日进度（逐日追加） | 下次白纸回忆 |
|---|---|---|---|---|---|
| K1 | `bscan_test.m` 6 段的执行顺序（参数 → 换算 → 时序 → 检查 → 运行 → 快速检查） | bscan_test.m §1–6 | 未知（本周未检验） | 10/13 计划建立 | 讲解后当天 |
| K2 | 时序表：DO 各列（STEP/DIR/DAQ 触发/激光）、每 K 步一个触发、借 AI 时钟 ≤250 kS/s | bscan_test.m §4；docs/13 | 10/11 部分：行数计算（pScan）没内化（见 research-bscan-report Q4） | 10/13 计划建立 | 讲解后当天 |
| K3 | 触发链：P0.6 → USER 1 → DG852 → G1 → TRIG IN（50 Ω，阈值约 0.87 V）/ G2 → CH A | docs/13 §1–3.3 | 10/11 部分：阈值余量因果答错后已讲（Q3） | 10/13 计划建立；10/12 Rui 要求知道阻抗在哪设、写进程序；10/13 晚确认：本行「TRIG IN 50 Ω」正确，依据是实测 50.2 Ω；但 TRIG IN 的阻抗代码选不了（`AlazarSetExternalTrigger` 只有耦合和量程，ETR_5V = ETR_5V_50OHM = 0，无 1 MΩ 选项）；能在代码里选阻抗的是 CH A（bscan_test.m 第 260 行）。用户 10/13 晚自述同一结论：「CH A 可以设置阻抗，TRIG IN 不可以」（述）。规格书写 1 MΩ，与实物不符，原因待确认 | — |
| K4 | ATS NPT AutoDMA：Post → StartCapture → Wait → Abort；buffer 字节数；dual-port 板载内存在 readwrite 阻塞时接住数据 | ats9462_multi_aline.m；docs/12 | 10/11 自述不了解，已讲（Q6）；10/12 会上 record/buffer/ring buffer 说不清，已讲 | 10/13 计划建立；dual-port 代码核对进行中；10/12 Rui 要求 dual-port 一边采一边存；10/13 核对代码和 SDK：NPT AutoDMA 就是 dual-port，一直在用，没有单独开关；bscan_test.m 8 个 buffer 一次性 Post，正好装 400 条，不需要重新 Post；「约 3 s 卡住」是 readwrite 期间 MATLAB 被占住，不是报错（出自 10/12 PPT "MATLAB blocked ~2.3 s"）；C-scan 要做成「Wait → 存 → 再 Post」的循环 | — |
| K5 | Y 轴：接线（P0.2/P0.3 待核对）、拨码、µm/脉冲、方向、速度上限 | docs/01；test2.m | 未开始 | 10/13 计划建立；10/12 会上用户说本周检查 Y 方向 | — |
| K6 | C-scan 结构：每行 arm → 输出一行时序 → 取数据 → X 回程 + Y 步进 → 检查停止；数据排成 时间 × X × Y | 待写 `cscan_test.m`；Maria C_scan.py 作对照 | 未开始 | 10/13 计划建立 | — |
| K7 | C-scan 测试 ①–⑥ 和检查手段（ctr1 计数、nEdge/tEdge、四角位置、MAP、重读、中途停止、拔线超时） | 07 第 3 周；docs/13 §4 | 未开始 | 10/13 计划建立 | — |
| K8 | 每像素/每行用时 → 估算 3 mm × 3 mm 扫描时间 | Rui Phase 1 W4；中英对照第三部分 ① | 未开始 | 10/13 计划建立 | — |

- 每日安排（建议，尚未执行）：第 1 天 K1–K4 讲解 + 白纸回忆，实验室确认 Y 接线（K5）；第 2 天 Y 标定 + `cscan_test.m` 检查模式（K5、K6）；第 3 天硬件 10 × 10 + 测试（K7、K8）；第 4 天剩余测试、文档、第 2 轮回忆。
- 复习（建议，尚未执行）：每个知识点讲完当天回忆一次 → 第二天 → 3–4 天后（约 10/17）。
- 卡点：暂无本周新证据。
- 需 Rui 判断：10/12 会议的要求和待办见 research-rui-1012。

### research-rui-1012：10/12（周一）与 Rui 一对一会议
- 来源：用户 10/12 上传的会议转录（无说话人标记，语音识别错误多）；用户 10/12 校正：程序名为 MATLAB/LabVIEW、DO 时钟 248 kS/s、一条 A-line 1024 点、「外方向」= Y 方向、「Doppler」= dual-port（指 Maria 用 dual-port 做）、Jennifer 负责切片和 H&E 染色。
- 完整整理稿（按原对话顺序，含待办与手册核对结果）：Research-PAM 仓库 `02_笔记与上下文/会谈记录/2026-10-12_Rui会谈整理.md`（原始转录 `2026-10-12_Rui会谈转录.txt`）；在线版 claude.ai 文档 https://claude.ai/code/artifact/c9b0725f-20da-4df0-9669-d8c70689acc5
- 用户在会上汇报的结果（用户自述 + 此前实测，不是本次新测）：
  - A-line 延迟：信号发生器设 1 µs 和 3 µs，测得差值约 1.97 µs（每个测 10–11 条）。（10/13 更正：记录是 1.9997 µs（ATS）/ 1.990 µs（示波器），docs/10 第 33 行）
  - B-scan：采到 400 条 A-line，叠图无明显延迟；4 mm/s、trigger 1000 Hz、1024 点 = 5.69 µs @ 180 MS/s；每 buffer 50 条 = 102400 字节；8 个 buffer 预先申请，运行约 3 s 卡住。（10/13 更正：代码是 800 Hz、间距 5 µm（bscan_test.m 第 23–24 行）；「卡住」不是报错，见 K4）
  - 电机：电流设置 0.3（单位待确认），最高 4.8 mm/s，设 5 mm/s 时几乎不转；未设加减速。
- Rui 明确要求 [导师要求]：
  1. 知道采集卡阻抗在哪设，并在 MATLAB 程序里写成明确参数（现状不必改）。
  2. 把 sampling frequency 和 bandwidth 的区别写下来；20 MHz 滤波开不开取决于信号范围（他估计信号约 10–35 MHz）。
  3. 电机：逐个试电流、加速、减速；先算一个 B-scan 实际需要多快，4.8 mm/s 不一定是问题。
  4. 采集：用 dual-port，一边采一边存（C-scan 可能采一小时，不可能全存在 DMA 里）；先自己理解 ring buffer 再试，不照搬 GPT。
  5. 查 DAQ 手册里 record 的定义：一个 trigger = 一个 record；records per buffer 上限约 8000。
  6. 采集方式：「一直走按 trigger 采」与「走停采」只是间隔不同，先按他画的那种做（10/13 重读转录：口头说两种都行、最常规是「每个触发采一条」；但他的书面 Phase 1 计划第 30 行写第一版用 step-and-settle，两者不一致，待当面确认）。
  7. 切片：成像和 H&E 染色是两回事（先拿一片成像，再交 Jennifer 染色）；先写 workflow 给他看；回复 Jennifer；找多余载玻片，找不到就买。
  8. 做实验前告诉他，他要来看（会上说明天或后天）。
- 会上暴露的卡点（会后助手已讲解，用户尚未独立解释）：采样率 vs 带宽 vs 带宽限制；「10 ns」是 100 MS/s 的采样间隔而不是 A-line 长度；record / records per buffer / buffer 的定义与由谁决定；ring buffer 怎么实现；DO 时钟的用途；phase → 延时的换算说不清；切片 workflow 没想好。
- 10/13 助手对照 ATS9462 手册核对 [文件确认；前提：卡是 ATS9462，型号待确认]：
  - TRIG IN：规格书写 1.01 MΩ，实测 50.2 Ω（10/9）→ 实际是 50 Ω [实测]。TRIG IN 的阻抗代码选不了：`AlazarSetExternalTrigger` 只有耦合和量程，ETR_5V = ETR_5V_50OHM = 0，没有 1 MΩ 选项 [文件确认，SDK 指南 §6.85、AlazarDefs.m]。CH A 第 260 行 50 Ω，可改成 1 MΩ；带宽限制第 261 行为 0（关）；第 282 行 NPT；第 284 行 8 个 buffer 一次性 Post。
  - CH A/B 带宽 DC–65 MHz（±4 V 量程为 50 MHz）；带宽限制约 20 MHz，SDK 文档称默认关（AlazarSetBWLimit）。
  - RecordsPerBuffer 1–8191；「512」是 Traditional 模式下未传到电脑的 buffer 超过 512 时报 BUFFER_OVERFLOW，不是可申请上限；手册推荐成像用 NPT AutoDMA。
  - dual-port AutoDMA 即手册推荐模式：等 buffer 满 → 处理/存盘 → AlazarPostAsyncBuffer 交回 → 等下一个；建议 ≥ 3 个 buffer。
  - record 长度 ≥ 256 点且为 32 的倍数（1024 符合）。
- 冲突已解决（10/13 晚再更正）：K3「TRIG IN 50 Ω」正确，依据是 10/9 万用表 50.2 Ω [实测]。「程序设了 ETR_5V_50OHM」不能当依据，因为 TRIG IN 阻抗代码选不了。CH A 的阻抗由 SDK 代码设置（第 260 行），TRIG IN 的不是。用户 10/13 晚自述的结论与此一致。规格书 1 MΩ 与实物不符的原因待确认。
- phase 换算：延时测试时发生器两路都是 100 kHz（周期 10 µs）[文件确认，docs/09 第 117、120 行]，324° 与 252° 对应 1 µs 与 3 µs，差 2 µs，与实测 1.9997 µs（ATS）/ 1.990 µs（示波器）吻合。
- 待确认：换能器中心频率与带宽；SR2 细分、额定电流、「0.3」单位、丝杠导程；「这一方向」是否为 Z；Jennifer 的切片厚度与交接方式；采集方式（口头说两种都行，书面计划写 step-and-settle，待当面确认）。（已解决、从这里移除：buffer 是否重新 Post——不需要；延时测试频率——100 kHz；发生器输出模式——Imped Load，docs/09 第 125、155 行；「约 3 s 卡住」有无报错——没有，出自 10/12 PPT "MATLAB blocked ~2.3 s"）
- 下一步（会上定的待办，尚未执行）：
  - 阻抗位置已由代码确认（bscan_test.m 第 260–262 行），不必进实验室再测；剩下的是自己看懂这三行，能说出每个参数的含义（完成标准：不看代码讲出 CH A、带宽限制、TRIG IN 各设成什么、在哪一行）。
  - 采集卡：写下采样率/带宽区别；查换能器带宽 → 定每条 A-line 点数。
  - 电机：查手册标称速度；逐个试电流/加减速；算 B-scan 所需速度；检查 Y 方向。
  - 程序：查 record 定义与 records per buffer；先弄懂 AutoDMA 与 ring buffer；问 Maria 她的 dual-port 怎么设；C-scan 改成每行存盘、buffer 轮流交回（一边采一边存）；本周争取写完 C-scan 代码。
  - 切片：写 workflow 给 Rui；回复 Jennifer；问切片厚度；找载玻片或买。
  - 实验：定时间并提前告诉 Rui。
- 证据状态：会议内容为转录整理；概念为助手讲解与手册核对，用户尚未做白纸回忆或独立解释。


### research-bscan-report：10/12 向 Rui 汇报 B-scan（测试信号版）
- 目标：能自己讲清 PPT 主线第 3–6 页（时序链条、1.84 ns 来源、触发余量、匀速扫描是否可行），应对追问。
- 最近活动：2026-10-11 第一轮 8 题检查（用户不查文档作答）。
- 资料来源：Research-PAM 仓库 `06_控制程序/docs/13_B-scan记录.md`（§3.1–3.3、§4）、`10_A-line测试总结.md`、`12_DMA_buffer与dual-port.md`；`07_MATLAB/bscan_test.m`。
- 证据维度（第一轮）：
  - 独立解释（部分正确）：Q1 "360 点 × 5.56 ns = 2 µs 说明延迟/时间轴对"（未说出"没验证绝对零点"）；Q5 "触发和采样不完全同步"（未量化、未给 100 MS/s 预测）；Q7 0.5 µm/脉冲的两条证据（手轮 5 圈 + 细分拨码）正确，5 mm/s 失步的原因和验证没答。
  - 独立解释（模糊）：Q2 ATS 比示波器早 53–75 ns，只答"传输速度不同、示波器不参与"，未说出固定偏差 → 相对时间不受影响 → 只影响绝对深度标定。
  - 错误（已讲解）：Q3 把"阈值 0.87 ≈ 1 V 的 3/4"当成"漏掉 3/4 的原因"；实际 1 V × 3/4 = 0.75 V，阈值比例 ≠ 漏触发比例，机理待确认，可说的是实测：1.0 V → 100–149/400，1.5 V 和 2 V → 400/400，规则是余量 ≥ 0.5 V。
  - 未给出数字（已讲解）：Q4 链条（1 STEP = 31 行 = 125 µs，1 触发 = 2 行 = 8.06 µs，K = 10；改 Δx 4 µm / 6 mm/s → K 8、1500 Hz、12 kHz、20 行、240 kS/s，先出问题的是电机加速段）；Q8（一条 A-line 内滑台走 22.8 nm，一个触发周期走 5 µm = Δx）。
  - 自述不了解（已讲解）：Q6 buffer 为什么现在够、C-scan 哪里先撑不住（板载内存 64 M 点 vs 164 M 点；readwrite 阻塞导致扫描中不能收 buffer；环形 buffer）。
  - 实际验证：以上数字均来自 10/7–10/9 实测记录（见资料来源），不是本轮新测。
- 卡点：链条的行数计算没有内化（pScan = floor(250k/步频)）；阈值余量的因果；√12 量化散布的量化表达；DMA/板载内存与阻塞输出的关系。
- 下一步（用户选定，尚未执行）：对 Q3、Q4、Q5 预测、Q8 用自己的话再答一次（完成标准：数字和因果都对、不看文档）；然后按 6 页大纲做 PPT。
- 需 Rui 判断（来源：10/05 未讲 PPT 第 9 页 + 13 §5，2026-10-11 整理）：匀速扫描 + 每 K 步触发是否符合目标；位置/时序验收容差；SR2 0.3 A 是否改；P0.7 5 V 与激光输入 ≤ 2 V 原来怎么接。

## 历史（按日期追加；10/13 之前的条目从 learning_skill `progress/history.md` 复制）

## 2026-10-11 · 2026-10-11-bscan-check1
- 主题 research-bscan-report：10/12 向 Rui 汇报 B-scan 前，用 8 题检查用户对 PPT 主线内容的理解（用户不查文档作答）。
- 结果：Q1、Q5、Q7 部分独立解释正确；Q2 模糊；Q3 推理错误（阈值比例 ≠ 漏触发比例）；Q4、Q8 未给数字；Q6 自述不了解。助手针对 Q2–Q4、Q6、Q8 做了定向讲解（链条行数、阈值余量实测事实、√12、板载内存与阻塞输出、匀速扫描内的位移）。
- 同日新增用户偏好：PPT 尽量短。大纲定为主线 6 页 + backup。
- 证据状态：讲解为助手提供；用户第二轮独立作答尚未进行。

## 2026-10-13 · 2026-10-13-cscan-week-setup
- 新主题 research-cscan-week：本周完成 C-scan（函数发生器测试信号，真实 PA 先不做；采集卡可用 dual-port）并熟悉全部代码。用户同意使用技能，并要求按知识点逐日记录进度。
- 建立 K1–K8 知识点表（bscan_test 流程、时序表、触发链、ATS DMA/dual-port、Y 轴、C-scan 结构、C-scan 测试、像素时间）；K2/K3/K4 带入 10/11 research-bscan-report 的已有证据。
- 证据状态：本周尚无用户独立解释；每日安排和复习时间为建议，尚未执行。

## 2026-10-13 · 2026-10-13-rui-meeting-1012
- 新主题 research-rui-1012：整理 10/12（周一）与 Rui 一对一会议。来源为用户上传的会议转录，用户 10/12 校正了程序名、DO 时钟 248 kS/s、A-line 1024 点、Y 方向、「Doppler」= dual-port（Maria）等术语。完整整理稿在 claude.ai 文档「2026-10-12 与教授组会记录」。
- 记录 Rui 的 8 条明确要求（阻抗设置写进程序、采样率/带宽写清楚、电机逐项试并先算所需速度、dual-port 一边采一边存、查 record 定义、采集方式按他画的做、切片先写 workflow 并回复 Jennifer、做实验前通知他）和会议待办。
- 助手 10/13 对照 ATS9462 手册核对：TRIG IN 固定 1.01 MΩ（与 research-cscan-week K3「TRIG IN 50 Ω」冲突，标待确认）；RecordsPerBuffer 1–8191；512 是 Traditional 模式溢出条件；dual-port AutoDMA 需处理完重新 Post buffer（推测为卡住原因）。research-cscan-week K3/K4/K5 每日进度同步追加。
- 证据状态：会议内容为转录整理；概念为助手讲解，用户尚未独立解释或白纸回忆。

## 2026-10-13 · 2026-10-13-rui-meeting-1012b
- research-rui-1012：针对 TRIG IN 阻抗冲突，用户判断阻抗是在 SDK 代码里设置的（未核对代码），选定进实验室时确认：查 AlazarInputControl（CH A）和 AlazarSetExternalTrigger（TRIG IN）的实际参数和代码行。已加入该主题待办，冲突仍为待确认。

## 2026-10-13 · 2026-10-13-rui-meeting-1012c
- research-rui-1012：会议整理稿和原始转录已存入 Research-PAM 仓库 `02_笔记与上下文/会谈记录/`。
- 更正：原判断（助手按 ATS9462 规格书 v1.5P：TRIG IN 固定 1.01 MΩ，与 K3「50 Ω」冲突）→ 修正（TRIG IN 是 50 Ω）→ 依据：bscan_test.m 第 262 行 ETR_5V = ETR_5V_50OHM（AlazarDefs.m 第 524/527 行）、10/9 万用表 50.2 Ω。用户 10/13「阻抗由 SDK 代码设置」的判断正确。「进实验室确认阻抗」待办改为「看懂 bscan_test.m 第 260–262 行」。

## 2026-10-13 · 2026-10-13-pam-move
- 用户要求把 PAM 相关进度搬到 Research-PAM。research-cscan-week、research-rui-1012、research-bscan-report 三节和对应历史条目移入本文件；learning_skill 只留链接。内容未改。

## 2026-10-13 · 2026-10-13-fact-fix
- research-rui-1012 / research-cscan-week K3、K4：事实更正（用户 10/13 晚同意；同时改了会谈整理稿和 master）。
  - TRIG IN：原判断「程序设 ETR_5V_50OHM，所以 50 Ω；阻抗由 SDK 代码设置」→ 修正「50 Ω 对，依据是实测 50.2 Ω；TRIG IN 阻抗代码选不了，代码能选阻抗的是 CH A」→ 依据：SDK 指南 §6.85、AlazarDefs.m（ETR_5V = ETR_5V_50OHM = 0）、SDK 自带 ATS9462 示例。用户 10/13 晚自述同一结论（述）。
  - 「约 3 s 卡住」：原判断「8 个 buffer 用完没交回」→ 修正「readwrite 期间 MATLAB 被占住，不是报错」→ 依据：bscan_test.m 第 281 行 recordsPerAcquisition = 400、第 296 行 readwrite；10/12 PPT 原文 "MATLAB blocked ~2.3 s"（对话记录 b51e694e 第 3040 行）；用户不记得有报错，记录里正常运行也没有报错。
  - 采集方式：原写「基本已答」→ 修正「口头两种都行，书面 Phase 1 计划第 30 行写第一版 step-and-settle，待当面确认」。
  - 会上汇报的数字：1.97 µs → 1.9997 µs（docs/10）；1000 Hz / 4 µm → 800 Hz / 5 µm（bscan_test.m）；phase 换算的频率 100 kHz 已确认（docs/09）。
- 证据状态：以上是事实核对，不是学习检验；按用户 10/13 要求，学习方法暂停，没有安排回忆。
