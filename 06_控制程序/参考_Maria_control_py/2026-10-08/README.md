# Maria 的 control_py — 10/8 版（参考用，不改）

- 来源：Maria 的 Google Drive `control_py`，2026-10-11 下载，`control_py-20261011T185333Z-1-001.zip`（Drive 分卷下载的第 1 卷，共 2.6 GB，几乎全是 `data/`）。代码修改时间 10/8 11:05–21:39；`pyproject.toml`、`uv.lock` 是 10/1。
- 没复制：`.venv`、`__pycache__`、`.vscode`、`data/`（数据见第 5 节）。
- 依赖：Python 3.12（`.python-version`）；`nidaqmx ≥ 1.6.0`、`numpy ≥ 2.5.3`（`pyproject.toml`）；`atsapi` 来自 `C:\Users\Caolab\Desktop\daq\23.3.0\Samples_Python\Library\atsapi`，不能 pip 装。
- 数据路径写死为 `C:\Users\Caolab\Desktop\control_py\data`（`digitizer/NPT_Aline.py:14`、`digitizer/TS_BC.py:19`）。
- 10/11 在 Mac 上读代码和数据，没有上硬件。下文 [条件计算] 是把 Maria 的波形生成部分离线跑一遍（nidaqmx 换成空模块）得到的。

## 1. 文件结构
| 入口 | Dev1 DO 脚本 | ATS9462 脚本 | 做什么 |
|---|---|---|---|
| `scriptControl_Aline.py` | `control_card/A_scan.py` | `digitizer/NPT_Aline.py` | 电机不动；P0.6、P0.7 同时发 1 个 1 ms 脉冲；ATS 用 NPT 采 1 条 12,800 点（71.1 µs） |
| `scriptControl_Bline.py` | `control_card/B_scan.py` | `digitizer/TS_BC.py` | X 走 50 个位置，每个位置 P0.7 发 1 次；整行只发 1 次 P0.6，ATS 连续录 0.3 s；最后退回起点 |
| `scriptControl_Cline.py` | `control_card/C_scan.py` | `digitizer/TS_BC.py` | 50 行 × 50 个位置，单向扫；每行回程，Y 再走一格 |

- 三个入口流程相同：先启动 ATS 脚本，等它打印 `Acquisition started.`（已 arm）再启动 DO 脚本；ATS 每 arm 一次打印一次，总控数次数。
- 扫描参数只在 DO 脚本里定义；总控 import DO 脚本算出每行要录多久，用环境变量传给 ATS 脚本（`scriptControl_Cline.py:30-52`）。
- `control_card/one_line_trigger.py`：P0.6 单线测试（第 5 行把数据改成了全 False，只输出低电平）。
- `analysis/signalAnalysis_TS.m`：memmapfile 读 TS 的一行画电压（现在指向 `data\kk` 第 16 行）；`waveformCheck.py`：把 A-line 的 daq/laser 波形存成 `.mat`；`waveformAnalysis.m`：画 6 条 DO 线。

## 2. 默认参数（[文件确认] = Maria 代码里的设定，不是我们系统的实测）
| 参数 | 值 | 出处 |
|---|---|---|
| DO 线 | P0.0/0.1 X STEP/DIR，P0.2/0.3 Y STEP/DIR，P0.6 DAQ，P0.7 LASER | `C_scan.py:10-17` [文件确认] |
| DO 时钟 | 1000 Hz，DO 任务自己的采样时钟 | `C_scan.py:27`、`:166` [文件确认] |
| 步距（Maria 的假设） | 4/200 × 1/4 = 0.005 mm = **5 µm/脉冲** | `C_scan.py:24-26`、`:36` [文件确认]；⚠ 我们 10/4 实测 0.5 µm/脉冲、导程 2 mm（`06_控制程序/CLAUDE.md`），差 10 倍，是不是同一套滑台/SR2 待确认 |
| 扫描 | X、Y 各 0.5 mm，每位置 0.01 mm → 2 脉冲/位置，50 × 50 | `C_scan.py:28-41` [文件确认] |
| 每个位置 | 停 2 个采样（激光触发 + 等 1 个）+ 2 个脉冲 × 2 个采样 = 6 ms，约 167 Hz | `C_scan.py:55` + [条件计算] |
| 一行 | 300 个采样 = 0.3 s（`DAQ_ACQUIRE_SAMPLES`） | `C_scan.py:58` + [条件计算] |
| C-scan 全程 | 25,347 个采样 ≈ 25.3 s；激光触发 2,500 个，DAQ 触发 50 个；行周期 507 ms → 回程里重新 arm 约 207 ms | [条件计算] |
| B-line 全程 | 504 个采样 ≈ 0.5 s；激光 50 个，DAQ 1 个 | [条件计算] |
| ATS 输入 | 180 MS/s 内部时钟；CH A AC、±200 mV、50 Ω；TRIG IN DC、ETR_5V、电平 150（≈ 0.87 V）；trigger timeout 0 | `TS_BC.py:46-74`、`NPT_Aline.py:39-67` [文件确认] |
| TS | DMA 8 MiB × 32；RAM 池 4 GiB + 写盘线程；每行 13 个 buffer（多录约 2.9 ms 不存）；108 MB/行，50 行 5.4 GB | `TS_BC.py:25-31` [文件确认] + [条件计算] |
| NPT A-line | 12,800 点/条（71.1 µs），trigger delay 0，2 个 buffer，每"行"重新 arm；出错或 Ctrl+C 也保存已采到的 | `NPT_Aline.py:20-24`、`:119-133`、`:141` [文件确认] |

## 3. 相对 10/3 版改了什么
- `digitizer/TS_BC.py` ≈ 10/3 的 `TS_aq_stream.py`：只改了数据路径（`PA_data` → `data`），删了开头注释。
- `control_card/C_scan.py` ≈ `unScan_TS.py` 删注释改名；`PULSE_RATE` 改叫 `SAMPLE_RATE`；删了"激光/DAQ 触发应有几个"的打印和 `.mat` 波形导出；每行录制长度改成 `DAQ_ACQUIRE_SAMPLES`（写死了 `+ 2`，见第 4 节）。
- `scriptControl_Cline.py` ≈ `scriptControl_TS.py`，只换了脚本路径。
- 新增：A-line（`A_scan.py` + `NPT_Aline.py`）、B-line（`B_scan.py`）、`analysis/`、`one_line_trigger.py`。
- 10/3 的 `TS_aq.py`（不带写盘线程的 TS）这版没有了。

## 4. 问题（参考或要跑时注意）
- **没有检查模式**：一运行就动 X/Y 电机、发 P0.7。
- `scriptControl_Bline.py:13-15` 多了一层 `.parent`，会去找 `Desktop\digitizer\TS_BC.py`，直接 FileNotFoundError（A、C 的路径是对的）。佐证：`__pycache__` 里只有 A_scan、C_scan；`data/b/` 里是 `row_00037`、`row_00044`，B-line 只会生成 `row_00001`。所以 B-line 很可能没用这个入口跑起来过（推测）。
- `C_scan.py:58`、`B_scan.py:51` 的 `+ 2` 其实是 `ACQUIRE_BLOCK_SAMPLES`，写成了常数：改 `MOTOR_WAIT_AFTER_LASER_SAMPLES` 后 ATS 录制长度不会跟着变，每行最后几个位置会被截掉。10/3 版（`2026-10-03/unScan_TS.py:89-92`）是用变量算的。
- `REVOLUTION_MM`（`C_scan.py:24`）没被用到，`STAGE_STEP` 直接写成 `4 / 200`；`LASER_FREQ`、`X_SAMPLES_PER_POSITION` 等也没用到。
- `TS_BC.py:23` 单独运行时默认录 0.42 s（更早版本的值），只有经总控调用才对。
- `analysis/waveformCheck.py:8` 要 scipy，但 scipy 不在 `pyproject.toml`/`uv.lock` 里；它现在只存 daq、laser 两条线，`waveformAnalysis.m:4` 却要 6 条。
- `C_scan.py:181` 结束时打印 "A line finished."（复制粘贴）。
- TS 的时间基准只有每行第一发：后 49 发的位置靠 NI 时钟的毫秒数换算成 ATS 时钟的点数。两张卡各用各的晶振，一行最后一发在行触发后 294 ms；若两时钟差 10 ppm（假设值，实际精度待查规格书），错开约 2.9 µs [条件计算]。切 A-line 要在数据里找每一发，不能只按时间算。
- 和我们 `docs/12` §四 第 3 条有关：`NPT_Aline` 的 buffer 是 25,600 B = 6.25 × 4096，不是 4096 的整数倍，照样采到了数据；还存过 128 点的记录（我们的脚本 assert ≥ 256 点）。可作为这两个待确认项的旁证。

## 5. 数据（zip 分卷 1 里有的，没存进仓库）
[实测：10/11 在 Mac 上用 Python 读 `.bin` 算的；uint16，按 ±200 mV 换算]
| 文件夹 | 文件 | 日期 | 内容 |
|---|---|---|---|
| `Nosignal_bug/` | 4 行，各 108 MB | 10/5 | 没看 |
| `NoSignal_debugged/` | 2 行（`row_013` 只有 96 MiB，不完整） | 10/6 | `row_009`：噪声，std 0.11 mV |
| `SineContinous_debugged/` | 4 行 | 10/6 | `row_016`：整行 20 MHz 连续正弦，约 ±87 mV |
| `aline/`、`aa/` | 各 128 点 | 10/8 上午 | 噪声 |
| `a/`、`x/`、`y/` | 各 12,800 点 | 10/8 上午 | 噪声，std 0.13 mV，最大偏离约 1 mV，看不到 PA 信号 |
| `b/` | `row_00037`、`row_00044`，各 108 MB | 10/8 12:27 | 没看；编号像 C-scan 的行 |
| `kk/` | `row_00028` | 10/8 21:27 | 整行 50 MHz 连续正弦，约 ±75 mV |
| `scan_20261008_213819/` | 50 行里的 11 行 | 10/8 21:38 | 第 2 行：噪声（std 0.11 mV，300 ms 内最大偏离 2.3 mV），50 个激光时刻都没有脉冲；第 21、50 行：整行 30 MHz 连续正弦，约 ±91 mV，和激光时刻无关 |

- 每个 TS 行文件开头第 2–4 个采样点都是 −200 mV（ADC 码 0）：看过的 6 个行文件都正好有 3 个这样的点（查了其中 4 个的位置，都是第 2–4 个）→ TS 开始时的伪数据，处理时要丢掉。
- 第 50 行文件完整（108,000,000 字节）→ 10/8 那次 50 行都采到了，每行在回程里重新 arm 是成功的。
- 结论：这个 zip 里没有 PA 信号，Maria 在用发生器的连续正弦测整条链路。其他分卷或别处可能还有数据，待问 Maria。

## 6. 和我们 MATLAB 版（`07_MATLAB/bscan_test.m`、`ats9462_multi_aline.m`）的对比
| | 我们 | Maria |
|---|---|---|
| 运动 | 匀速扫 + 线性加减速 | 移动–停–触发，不加速，步频 500 Hz |
| 采集触发 | P0.6 每条 A-line 一个硬件触发 | P0.6 每行 1 个；P0.7 每个位置 1 个 |
| ATS | NPT，每条 1,024 点 | B/C 用 TS 整行连续录；A-line 用 NPT |
| CH A | DC ±4 V（目前接发生器测试脉冲） | AC ±200 mV |
| 自检 | ctr1 计数、每条沿数和上升沿统计 | 数 `Acquisition started.` 的次数 |
| 2,500 个位置的数据量 | 约 5 MB | 5.4 GB [条件计算] |
| DO 时钟 | 借 AI1，≤ 250 kS/s | 板载时钟，1 kHz |

可以借鉴（思路，MATLAB 版自己写）：
- 每行重新 arm 的循环（`TS_BC.py:192-234`、`NPT_Aline.py:91-118`）→ 我们 C-scan 要"每行单独 arm、回程里取完"（docs/12 §三）。
- 用小函数拼波形（`C_scan.py:72-138`：addSample / addIdle / addXStepBurst / addYStepBurst / addTriggerBlock），6 条线一起加，不会错位，加 Y 轴和回程方便。
- 参数只在一处定义，总控推算 ATS 录制长度（`scriptControl_Cline.py:30-52`）。
- 出错或 Ctrl+C 也保存已采到的数据（`NPT_Aline.py:119-133`）→ 对应四周计划测试 ④"中途停"。

## 7. 要问 Maria 的
1. 我们用的是不是同一台滑台、同一个 SR2？5 µm/脉冲（4 mm 导程、1/4 细分）实测过吗？
2. TS 数据怎么切成每个位置的 A-line？按时间算还是在数据里找脉冲？
3. 为什么 B/C 用 TS、A-line 用 NPT？是不是激光一个触发打一串 burst（`LASER_FREQ = 50_000`）？
4. `Nosignal_bug` → `debugged` 修好的是什么？10/8 C-scan 输入 30 MHz 正弦是在测什么？激光接了吗、看到过 PA 信号吗？
5. 每行开头那 3 个 −200 mV 的点知道吗？
6. Dev1、ATS、SR2 和发生器是共用的，以后怎么约定？（10/9 到实验室时接线和发生器参数被改过。）
