---
title: "UV-PAM B-scan / C-scan 自己上手操作手册（测试信号版）"
subtitle: "Yumeng Chen · 2026-10-15 · 依据 bscan_test.m（327 行）、cscan_test.m（1036 行）、docs/13、14、15"
---

> **用途**：不靠 AI，自己能改参数、算频率、跑脚本、看结果、演示、改新需求。
> 行号按仓库里 10/14 版；实验室电脑上 `bscan_test.m` 第 51 行 `recordsPerBuffer` 可能是 2（做 3.1 时改的），用前看一眼。
> 标签沿用 master §0：[实测] [文件确认] [条件计算] [待确认]。

# 0　一页总览：只记这 5 个公式

所有频率都从**位置**推出来，你只定 2–3 个数，其余是算的。

| # | 公式 | 数值（默认） | 出处 |
|---|---|---|---|
| ① | 每脉冲距离 = 导程 ÷ 每转步数 = 2000 µm ÷ 4000 | **0.5 µm/脉冲**（X、Y 都是）[实测 10/4、10/14] | B:36–37、C:50–51 |
| ② | K = Δx ÷ 0.5 µm（每个像素走几步，**必须整数**） | Δx 5 → K 10；Δx 10 → K 20 | B:55、C:88 |
| ③ | 步频 = 速度 ÷ 0.5 µm；速度 = Δx × 触发频率 | 4 mm/s ↔ **8000 Hz** | B:58–59、C:97 |
| ④ | 触发频率（每秒 A-line 数）= 步频 ÷ K | K 10 → 800 Hz；K 20 → 400 Hz | B:24 直接设；C:100 算出 |
| ⑤ | DO 时钟 fs = 步频 × floor(250 000 ÷ 步频) | 8000 × 31 = **248 000 S/s** | B:70–72、C:104–106 |

记法：**B 定触发频率，C 定速度**。B 里速度 = Δx × TRIG_RATE_HZ；C 里触发频率 = 8000 ÷ K。两者都不能让速度超过 4 mm/s（`MAX_SPEED_MM_S`）。

**ATS 侧**（和位置无关）：180 MS/s，每点 5.556 ns；1024 点 = **5.69 µs** 窗口；触发门槛 code 150 → (150 − 128)/127 × 5 V ≈ **0.87 V**；每个 buffer 字节 = 2 × 点数 × rpb，**必须是 4096 的倍数**（1024 点时 rpb 取偶数）。

**判定一次扫描成功的三个数必须相等**：`ctr1`（P0.6 发了几个）= `收到条数`（ATS 收了几条）= `计划条数`（Nx 或 NX × NY）。

---

# 1　信号链和时间轴（演示时指着示波器说）

```
Dev1 同一个硬件时钟（fs = 248 kS/s）同时输出 4（B）/ 6（C）条数字线：
  P0.0 X STEP ──→ SR2(X) ──→ X 滑台         每个下降沿走 0.5 µm
  P0.1 X DIR                                 1 = 朝电机 [实测]
  P0.2 Y STEP ──→ SR2(Y) ──→ Y 滑台         （C 才有）
  P0.3 Y DIR
  P0.6 DAQ 触发 ──→ USER 1 端子 ─┬─→ 发生器 CH1/CH2 AUX IN（外触发）
                                  └─→ PFI3 → ctr1 计数（COUNT_CHECK）
  P0.7 激光触发（LASER_ENABLE=false 时恒 0）

发生器 DG852：CH1 = G1 → ATS TRIG IN（50 Ω）；CH2 = G2 → ATS CH A（50 Ω，假信号）
```

以 P0.6 上升沿为 0 [实测 10/14]：

| 时刻 | 事件 | 来源 |
|---|---|---|
| 0 | P0.6 ↑（示波器 CH1 触发点，Top ≈ 4.3–4.5 V） | Dev1 |
| +0.55 µs | G1 ↑（CH2，Top 2.00 V，宽 5.000 µs） | 发生器外触发反应时间 |
| +0.55 + 0.87 V 处 | **ATS 开始计时** | G1 过门槛 |
| +2.56 µs | G2 ↑（CH3，Top 1.0 V，宽 200 ns） | G1 + Delay 2 µs |
| +8.06 µs | P0.6 ↓（2 行 ÷ 248 kS/s，屏幕外） | wTrig = 2 行 |

ATS 数据里看到的上升沿 ≈ **1.926–1.933 µs**（比 2 µs 早约 70 ns，固定偏差，来源 [待确认]）；散布约 2 ns = 5.556 ns ÷ √12 ≈ 1.6 ns 的采样量化，不是抖动。

---

# 2　B-scan：`bscan_test.m`

## 2.1 要改的参数（按行号）

| 行 | 名字 | 默认 | 含义 / 规则 |
|---|---|---|---|
| 15 | `RUN_HARDWARE` | false | **跑完一定改回 false** |
| 16 | `LASER_ENABLE` | false | true 时 P0.7 和 P0.6 同时发；激光安全确认前别开 |
| 17 | `RETURN_TO_START` | true | 扫完以 `RETURN_SPEED_MM_S` 退回 |
| 18 | `SAVE_DATA` | false | 存到 `bscan_data/`（不进 git） |
| 19 | `COUNT_CHECK` | true | ctr1 数 P0.6；需要 USER 1 并一根线到 PFI3 |
| 22 | `SCAN_LENGTH_UM` | 2000 | B-scan 长度 |
| 23 | `DX_UM` | 5 | A-line 间距，**0.5 的整数倍** |
| 24 | `TRIG_RATE_HZ` | 800 | 触发频率；速度 = DX × 它 ≤ 4 mm/s |
| 26 | `RAMP_UM` | 200 | 加速、减速各多长（不采数据） |
| 27 | `START_FREQ_HZ` | 500 | 加速起点步频 |
| 28 | `RETURN_SPEED_MM_S` | 2 | 回程速度 |
| 35 | `STEPS_PER_REV` | 200×20 = 4000 | 拨码；改了就全错 |
| 37 | `MAX_SPEED_MM_S` | 4 | 上限，别改大 |
| 38 | `MAX_TRAVEL_UM` | 20000 | 单次行程上限 |
| 46 | `ATS.samplesPerALine` | 1024 | 32 的倍数、≥ 256 |
| 47 | `ATS.sampleRate_Hz` | 180e6 | 只能 100/160/180 M |
| 48 | `ATS.inputRange_V` | 4 | CH A 量程 0.2/0.4/0.8/2/4 |
| 49 | `ATS.triggerLevelCode` | 150 | ≈ 0.87 V（ETR_5V） |
| 51 | `ATS.recordsPerBuffer` | 50 | 每个 buffer 几条；**Nx 会被凑成它的整数倍**（第 64 行） |
| 260–262 | CH A 阻抗 / 带宽限制 / TRIG IN 量程 | 50 Ω / 关 / ETR_5V | 在 `runBscan` 里，硬编码 |

## 2.2 默认参数怎么算出来（自己能重现这几行打印）

```
K        = 5 / 0.5 = 10
步频      = 10 × 800 = 8000 Hz          → 速度 = 8000 × 0.5 µm = 4 mm/s ✓ ≤ 4
Nx       = 2000 / 5 = 400 → 凑成 50 的倍数 = 400 → 8 个 buffer
nRamp    = 200 / 0.5 = 400 步（加速、减速各）
总行程    = (2×400 + 400×10) × 0.5 = 2400 µm
pScan    = floor(250000 / 8000) = 31 行/步 → fs = 248 000 S/s
wTrig    = round(10 µs × 248000) = 2 行 = 8.06 µs
buffer   = 2 × 1024 × 50 = 102 400 B = 25 × 4096 ✓
```
检查模式打印应为：`A-line 数 400，间距 5.00 um … 扫描速度 4.00 mm/s，步频 8000 Hz，触发 800 Hz，DO 采样率 248000 S/s；总行程 2.40 mm，总用时约 2.3 s`。

## 2.3 运行步骤

1. **准备**（docs/13 §7.5）：关 LabVIEW；MATLAB 当前文件夹 = `…\Research-PAM\07_MATLAB`（`which bscan_test` 确认）；示波器 Probe 全 1X、D = 0；发生器三通在 CH1 AUX（不是 10MHz REF）、CH2 是 Square、**不要 Recall `PAM_bscan`**；KORAD 开；滑台在中间、朝电机留 ≥ 5 mm。
2. **命令行打 5 发验证计数链**（和 docs/14 阶段 0 一样）：
   ```matlab
   clear d dq cnt; daqreset
   cnt = daq("ni"); addinput(cnt,"Dev1","ctr1","EdgeCount"); resetcounters(cnt);
   d = daq("ni"); addoutput(d,"Dev1","port0/line6","Digital");
   for i = 1:5, write(d,1); pause(0.01); write(d,0); pause(0.01); end
   read(cnt,"OutputFormat","Matrix")      % 应为 5
   write(d,0); clear d cnt
   ```
   数到 89、121 这种 → 三通插在 10MHz REF 上（10/14 上午踩过）。
3. **检查模式**：`RUN_HARDWARE = false` 运行，看三行打印和计划图（红点只在直线段）。
4. **硬件**：改 true 运行。顺序是 ATS 先 arm → `readwrite` 输出整张表（MATLAB 卡约 2.3 s，正常）→ 取 8 个 buffer。
5. **看打印**：
   ```
   ctr1 实测 P0.6 上升沿：400（应为 400）     ← 发送端
   完成：采到 400 条 A-line，rail 点数 0        ← 接收端
   每条正好 1 个沿：400/400
   上升沿 1.926 ~ 1.933 us，标准差 ≈ 1.9 ns，峰峰 ≈ 6.6 ns
   脉冲高 1.04 ~ 1.06 V
   ```
6. **两张图**：plan 图 = 位置随时间，红点匀速段；包络图 = 亮带在约 2 µs、连续平直、背景干净。
7. **收工**：`RUN_HARDWARE = false`；发生器 Output 关；KORAD 关；SR2 断电。

## 2.4 三个数不相等时怎么查

| ctr1 | 收到条数 | 最可能 | 先查 |
|---|---|---|---|
| 400 | 400 | 正常 | — |
| 400 | < 400 或超时 | G1 → TRIG IN 这段 | G1 幅度（2 Vpp/1 V，示波器 CH2 Top ≈ 2 V）；三通；TRIG IN 线 |
| < 400 | < 400 | P0.6 没发够 / 计数线 | 时序表（检查模式 Nx）；USER 1 → PFI3 线；发生器三通是否在 10MHz REF |
| 0 | 超时 | 没有 P0.6 | Dev1 被占（LabVIEW）；`daqreset`；接线 |
| 400 | 400 但沿 ≠ 1 | 假信号 | 发生器 CH2 关了 / 改成 Sine；CH A 线 |
| — | rail > 0 | 量程 | `inputRange_V` 太小，或 CH A 不是 50 Ω（示波器 CH3 2.3 V 就是这个） |

---

# 3　C-scan：`cscan_test.m`

## 3.1 和 B 的关系
行内 = B 的匀速扫（同一张行扫描表，`buildRowTable`，C:341）；行间 = X 回程 + Y 走一步（`buildMoveTable`，C:365）。每行：**arm → 行扫描 → 取数 + Abort + ctr1 → 存盘 → 看停止按钮 → 回程 + Y**。行间没有 P0.6，所以重新 arm 不漏触发。

## 3.2 要改的参数

| 行 | 名字 | 默认 | 规则 |
|---|---|---|---|
| 20 | `RUN_HARDWARE` | false | 跑完改回 |
| 22 | `ATS_ENABLE` | true | false = 只动电机 + ctr1（阶段 4.1） |
| 24 | `SAVE_DATA` | false | 每行写一次 `cscan_data/`（不进 git） |
| 25 | `MOCK_DATA` | true | 检查模式下用假数据走一遍存盘 / MAP / 重读 |
| 26 | `PAUSE_BETWEEN_ROWS` | false | 每行前后停、回车继续（看手轮、关 CH2 做行顺序测试） |
| 27 | `Y_CALIBRATED` | true | 10/14 标定后改的，别动 |
| 30–31 | `NX` / `NY` | 10 / 10 | NX 必须是 rpb 的整数倍 |
| 32–33 | `DX_UM` / `DY_UM` | 10 / 10 | 0.5 的整数倍 |
| 34 | `SCAN_SPEED_MM_S` | 4 | ≤ 4；步频 = 速度/0.5 必须整数 Hz |
| 37–38 | `X_RETURN_SPEED_MM_S` / `Y_SPEED_MM_S` | 2 / 1 | 不加速，步频 ≤ 8000 Hz |
| 40 | `SETTLE_S` | 0.05 | 回程前、Y 后各停多久 |
| 51–53 | Y 的 µm/脉冲、方向、序列号 | 0.5 / 1 / 243106105 | [实测 10/14]，别动 |
| 58 | `SOFT_LIMIT_UM` | 5000 | 累计命令位置 ±5 mm |
| 64 | `NOTE` | 字符串 | **每次测试前改**，存进文件 |
| 68–72 | CH A 量程 / 阻抗 / 带宽 / TRIG IN 量程 | 4 V / 50 Ω / 关 / 5 V | 命名参数，上真信号时要改 |
| 76 | `ATS.recordsPerBuffer` | 2 | 每行 buffer 数 = NX ÷ rpb；每行 > 64 个 buffer 会警告 → 改 10 |
| 77 | `ATS.postedBuffers` | Inf | Inf = 每行全部预先 Post；数字 = ring buffer 轮流用几个（5 跑过 60/60） |

## 3.3 默认 10 × 10 怎么算

```
K = 10/0.5 = 20；Ky = 10/0.5 = 20
步频 = 4 mm/s ÷ 0.5 µm = 8000 Hz → 触发 = 8000/20 = 400 Hz → fs = 248 000
每行 X 走 = 2×200 + 10×10 = 500 µm（≤ 5000 ✓）；Y 共 = 9×10 = 90 µm
每行 buffer = 10/2 = 5 个，每个 4096 B ✓；每秒装满 400/2 = 200 个 < 2000 ✓
时长（表算）：行扫描 0.32 s + 回程+Y 0.36 s = 0.68 s/行，全程 6.9 s
实测 [10/14]：每行 = 1.13 s + NX × 7.40 ms → 10×10 约 12 s；多出的 0.5 s 是 readwrite 启动 + arm/取数/存盘
```
7.4 ms/像素怎么来：扫描 10 µm ÷ 4 mm/s = 2.5 ms，回程 10 µm ÷ 2 mm/s = 5 ms，合计 7.5 ms。

## 3.4 运行步骤

1. 准备同 B（§2.3 第 1–2 步）；两轴都在行程中间，Y 胶带记号在联轴器上方。
2. **检查模式**（`RUN_HARDWARE = false`，`MOCK_DATA = true`）：看打印 `K = 20，Ky = 20，fs = 248000 …`、`每行 0.683 s，全程 6.91 s`、假数据 `MAP(3,7) = 3.07（应为 3.07）`、`逐点核对 100/100`，计划图三色路径。
3. **第一次上硬件顺序**（docs/14）：`ATS_ENABLE = false` 只动电机（每行 ctr1 = 10、回到 0/0）→ `ATS_ENABLE = true` 跑 NY = 2 → 10 × 10。已经验证过的台架可以直接 10 × 10。
4. **每行一句打印**怎么读：
   ```
   第 3/10 行：A-line 10/10，1 个沿 10/10，上升沿中位数 1.9290 us，脉冲高 1.041 ~ 1.048 V；
             ctr1 = 10（应为 10）；用时 1.19 s（arm 0.02 / 扫描 0.52 / 取数 0.05 / 存 0.00 / 回程+Y 0.58）
   ```
   行与行之间中位数应差 < 1 ns；`ctr1` 每行都等于 NX。
5. **结束打印**：`完成 10/10 行，A-line 100 条；每条正好 1 个沿 100/100；rail 0；上升沿 … 标准差 ≈ 1.9 ns；MAP 1.04 ~ 1.05 V；重读 isequal(raw) = 1, isequal(MAP) = 1`。
6. **停止**：只点小窗口的"停止"按钮（行间生效，做完当前行 → 回程 → Y 退回）。**不要 Ctrl+C**（不进 catch、不退回、要手摇回记号）。小窗口在屏幕左下角，容易被挡；`PAUSE_BETWEEN_ROWS = true` 时按回车前先点命令行窗口。
7. 收工：`RUN_HARDWARE = false`、`SAVE_DATA = false`、NX/NY 改回 10；发生器 Output 关；KORAD 关。

## 3.5 出错时程序做什么
Abort DMA → 读 ctr1 → 把 `errorMessage / failedRow / failedPhase` 存进文件 → **位置已知**（不是在 readwrite 中间出错）才自动退回起点，否则不动、手摇回记号。拔触发线的表现：`第 4 行（取数）出错：buffer 1/5 未完成（ApiWaitTimeout）`，前 3 行已存，自动退回 [实测 10/14 6.7]。

## 3.6 怎么证明"第 k 行数据 = 第 k 行位置"
测试信号下 MAP 均匀，证明不了。两种办法：① 检查模式假数据（每行亮度 = 行号 + 列号/100，逐点核对）；② `PAUSE_BETWEEN_ROWS = true`，第 3 行前关发生器 CH2 的 Output，第 4 行前打开 → MAP 第 3 行一条**横的**暗线 [实测 10/14 6.5]。

## 3.7 不碰硬件重画
```matlab
REPLOT_FILE = 'C:\...\Research-PAM\06_控制程序\docs\data\cscan_1014\cscan_20261014_175112.mat';
cscan_replot
```
通过标准：`isequal(MAP) = 1`、`isequal(nEdge) = 1`、`isequaln(tEdge) = 1`。不设 `REPLOT_FILE` 就读 `cscan_data/` 里最新的。`docs/data/cscan_1014/README.md` 列了 10 个文件各是哪次测试。

---

# 4　明天演示剧本（约 10 分钟，台架被占就跳到第 6 步）

| 步 | 做什么 | 指给他看 | 一句话 |
|---|---|---|---|
| 1 | 示波器静态打 1 发（§2.3 第 2 步的代码只发 1 次） | CH1 4.4 V、CH2 2 V/5 µs/晚 0.55 µs、CH3 1 V/200 ns/晚 2 µs | "P0.6 经发生器整形成 2 V 触发；G2 是 2 µs 后的假光声信号" |
| 2 | `bscan_test` 检查模式 | 三行打印 + 计划图 | "触发按步数发，5 µm 一条，4 mm/s，800 Hz；加速段不采" |
| 3 | `bscan_test` 硬件 | `ctr1 400 = 400/400 = 400`，包络图亮带 | "发送 = 接收 = 计划，没漏没多；2 ns 散布是采样量化" |
| 4 | `cscan_test` 检查模式 | 假数据 MAP(3,7)=3.07、计划图 | "每行单独 arm；行间没触发所以不漏；存盘后重读一致" |
| 5 | `cscan_test` 10 × 10 硬件 | 每行一句、MAP 均匀、`重读 = 1`、每行 1.19 s | "每行 1.13 s + 7.4 ms/点；0.5 s 是软件开销，3×3 mm @1 µm 推算 2.1 h，瓶颈是开销和单向" |
| 6 | 台架被占：`cscan_replot` 读 `docs/data/cscan_1014/…175112.mat`；行顺序文件 `…205841.mat`；拔线文件 `…210855.mat` | MAP、第 3 行暗线、errorMessage | 同上 |
| 7 | 主动说限制 | — | 假信号；激光没接；位置是命令值；放大器 + 换能器链路没测 |

要问他的：行内匀速扫还是 step-and-settle；激光 P0.7（5 V TTL）原来怎么接 NPL45C（手册 0.2–2 V）；放大器/换能器型号。

---

# 5　有新需求时改哪里

| 想做的 | 改什么 | 要重新算 / 注意 |
|---|---|---|
| B 换间距 Δx | B:23 `DX_UM` | K = Δx/0.5 必须整数；速度 = Δx × TRIG_RATE ≤ 4 → 同时调 B:24 |
| B 换长度 | B:22 | Nx = 长度/Δx 会凑成 rpb 倍数（B:64）；行程 = 400 + 长度 ≤ 20000 µm |
| B 想要 1 µm 间距、4 mm/s | DX 1，TRIG 4000 | K 2，步频 8000，fs 248k 不变；Nx = 2000 → 40 个 buffer（rpb 50） |
| C 换视场 | C:30–33 | X 每行 400 + NX×Δx ≤ 5000；Y (NY−1)×Δy ≤ 5000；NX 是 rpb 倍数；每行 buffer ≤ 64，否则 C:76 改 10 |
| C 3 × 3 mm @ 10 µm | NX 300、NY 300、rpb 10 | 每行 30 个 buffer；约 17 min [条件计算]；`raw_u16` 全在内存 1024×300×300×2 B = 184 MB，还行；@1 µm 要改成只留当前行（C:224 注释） |
| 扫慢一点 | B:24 调小 / C:34 调小 | C 里步频 = 速度/0.5 要是整数 Hz（3 mm/s → 6000 ✓；3.3 → 6600 ✓；1.234 → 2468 ✓，几乎都行） |
| 扫快于 4 mm/s | 先别改 `MAX_SPEED_MM_S` | 要先做：SR2 电流（现 0.3 A，额定 1.7 A）、加速段验证 [导师 10/12：逐个试] |
| 接激光 | B:16 / C:21 `LASER_ENABLE = true` | P0.7 和 P0.6 同一时刻（do 第 4/6 列 = trigScan）；**先确认** NPL45C 触发电平（手册 0.2–2 V vs P0.7 5 V）[待确认]；Class 3B，Rui 在场 |
| CH A 接放大器输出 | C:68 `inputRange_V`、C:69 `inputImpedance_ohm` | 先不开激光看背景；量程按放大器输出幅度选（±0.4 V 起试）；rail > 0 就加大量程；B 在 B:48 和 B:260 |
| 开 20 MHz 低通 | C:70 `bandwidthLimit = 1`（B:261 第三个参数改 1） | 取决于换能器带宽 [待确认]；Rui 估信号 10–35 MHz → 开了会削 20–35 MHz |
| A-line 采更长 | `samplesPerALine` 2048 | 11.4 µs ≈ 17 mm 声程 [条件计算 1.5 mm/µs]；buffer = 4096 × rpb，任意 rpb 都对齐 |
| 触发门槛 | `triggerLevelCode` | 电压 = (code − 128)/127 × 量程；ETR_1V 时同一个 150 只有 0.17 V |
| 改成 step-and-settle | 只换 C:341 `buildRowTable` | 每像素：走 K 步 → 停 settle → 发 P0.6 → 下一像素；其余不变（docs/14 附 B） |
| 双向扫描（去掉回程） | `buildMoveTable` + 偶数行翻转 DIR 和 x_um | 还没写；要先确认反向扫描的位置一致性 |
| 后台输出、去掉 0.5 s 开销 | `readwrite` → `preload` + `start` | 还没写；6.10 测的开销里 readwrite 启动占 2 × 0.18 s |

改完任何参数的固定流程：**检查模式跑一遍 → 核对打印的 K / 步频 / fs / 行程 / 时长 → 再上硬件 → 三个数相等**。

---

# 6　发生器 / 示波器速查（docs/13 §2、§7）

| | CH1 = G1 | CH2 = G2 |
|---|---|---|
| 波形 | Square 100 kHz | Square 2.5 MHz |
| 幅度 | 2 Vpp，Offset 1 V（0 → 2 V） | 1 Vpp，Offset 0.5 V（0 → 1 V） |
| Burst | NCycle 1，Ext（AUX IN），Idle Bottom | 同左 + **Delay 2 µs** |
| 输出阻抗 | Load（50 Ω） | Load |
| 结果 | 5 µs 高（100 kHz 半周期） | 200 ns 脉冲，G1 后 2 µs |
| 接到 | 三通 → 示波器 CH2 + ATS TRIG IN | 三通 → 示波器 CH3 + ATS CH A |

为什么 2 V：Load 模式假定另一头 50 Ω，开路会翻倍。示波器 CH2 读 2 V、CH3 读 1 V 本身就证明 TRIG IN、CH A 是 50 Ω。G1 只给 1 V 时离门槛 0.87 V 太近 → 漏触发 [实测 10/9]。

示波器 7 步：底栏 2 V / 1 V / 500 mV，Probe 全 **1X** → D = 0 → 不运行时 CH1 平线、WAIT → 触发 CH1 ↑ 约 1.4 V、Normal → 1 µs/格 → 打 1 发看 CH1 Top 4.3–4.5 V → CH2 Top 2.0 V、+Wid 5.000 µs、Dly 1→2 约 550 ns → CH3 Top 1.0 V、+Wid 200 ns。

---

# 7　踩过的坑（开工先扫一遍）

- 发生器背面三通插到 **10MHz REF** → ctr1 乱数（89、121）。要在 CH1 AUX。
- CH2 被改成 Sine / 关掉 → 每条 0 个沿、脉冲高 3 mV。
- 示波器 Probe 设成 2X / 10X → 电压读错一倍（10/9 "高阻、门槛 2–3 V"全是这个）。
- 示波器 D ≠ 0（39 ms、480 ms）→ 看不到波形。
- MATLAB 当前文件夹是旧的 `PAM_controlProgram\Matlab` → 跑的是旧代码。
- 发生器 Recall `PAM_bscan` → 旧的 1.5 Vpp。
- 停止小窗口抢焦点 → 回车按成停止。
- `Hardware is reserved` → 命令行有残留 daq 对象或 LabVIEW 没关：`clear d dq cnt; daqreset`。
- 误点断点停在调试器 → `dbclear all; dbcont`。
- 5 mm/s 起步失步（0.3 A）；DX 不是 0.5 倍数被 assert 拦下；NX 不是 rpb 倍数被拦下（B 会悄悄凑，C 直接报错）。
- 收工 `bscan_test.m:15` 忘改回 false（10/14 就留了一次）。

---

# 8　自测题（会前自己做，答案在最后）

1. B：`DX_UM = 2`，`TRIG_RATE_HZ = 2000`。K、步频、速度、fs、Nx（长度 2000）、buffer 数（rpb 50）各是多少？能跑吗？
2. B：想 Δx = 0.7 µm，会怎样？Δx = 3 µm 呢？
3. B：`TRIG_RATE_HZ = 1000`、DX 5，速度多少？程序会怎样？
4. C：`SCAN_SPEED_MM_S = 2`、DX 10，触发频率多少？每行时间大约多少（用实测公式）？
5. C：NX 50、NY 50、Δ 10 µm：X 每行走多远、Y 共多远、每行几个 buffer、全程大约多久？
6. C：NX 300、rpb 2 会出什么提示？该改什么？
7. ATS：`samplesPerALine = 1536`，rpb 该取什么？窗口多长？
8. 跑完 ctr1 = 400，但程序报 `Buffer 3/8 未完成`，收到的触发在 100–149 之间。先查哪里？
9. 示波器 CH3 读 2.3 V 而不是 1 V，说明什么？
10. 3 × 3 mm @ 1 µm 的像素数、30 min 对应每像素多少时间、按现流程多久？

**答案**
1. K = 4；步频 8000；4 mm/s ✓；fs 248 000；Nx 1000（50 的倍数）；20 个 buffer。能跑。
2. 0.7/0.5 = 1.4 非整数 → B:56 assert 拦下。3/0.5 = 6 ✓。
3. 5 × 1000 = 5 mm/s > 4 → B:60 assert "扫描速度 5.00 mm/s 超过上限"。
4. 步频 4000，K 20 → 200 Hz。每行 ≈ 1.13 + NX × (10/2 + 10/2) ms = 1.13 + 10 × 10 ms = 1.23 s（Δx/速度 5 ms + 回程 5 ms）。
5. X 400 + 500 = 900 µm；Y 490 µm；25 个 buffer；每行 1.13 + 50 × 7.4 ms = 1.5 s → 50 行 ≈ 75 s。
6. 每行 150 个 buffer > 64 → 红字建议；改 C:76 rpb = 10（300/10 = 30 个），或 postedBuffers = 4。
7. 2 × 1536 = 3072 B/条；4096/gcd(4096, 3072) = 4 → rpb 取 4 的倍数。窗口 1536/180 M = 8.53 µs。
8. ctr1 对、ATS 少 → G1 → TRIG IN 段：示波器 CH2 Top 是不是 2 V（不是就是发生器幅度 / Probe 倍率），三通和 TRIG IN 线。
9. CH A 还没被程序设成 50 Ω（发生器 Load 模式开路翻倍）；跑一次 B 后应回到 1 V。
10. 3000 × 3000 = 900 万；1800 s ÷ 9×10⁶ = 0.2 ms/像素；每行 ≈ 2.0 s 电机 + 0.52 s 开销，3000 行 ≈ 2.1 h。
