# 02 LabVIEW 程序地图：SlowScan_ENdaq

## 来源说明
- 2026-10-03 用 `docs/tools/vi_dump.py` 从 .vi 文件中提取。✔ 表示文件里直接读到的文字，? 表示根据名字推断。
- 读不到框图连线（参数具体怎么算成脉冲）。这部分要靠截图补，清单见 `screenshots/README.md`。截图读完后，要点写进本文件末尾的"截图转写"部分。

## 基本信息
- 主程序：`LabviewPAM\SlowScan_ENdaq\Main.vi`（2.1 MB，最后修改于 2025-12-05）。前面板署名 "PATER @ COILab by Yide Zhang" ✔
- 项目文件：`ERPAM_Yide.lvproj`
- 跨文件夹引用：GateTrig.vi 来自 `PAM_NPTDAQ\SubVIs\`；ClockRate.ctl 来自 `202100521_UVPAM_DAQstream_Average_Pattern\ATS9350\` ✔
- 其他 4 个项目（PAM_NPTDAQ、PAM_TriStream、SlowUVscan_ENlaser、2021 UVPAM）结构类似。名字推断：NPT 采集版、触发流式版、激光触发版、旧版 ?

## 程序结构
- 界面是一个事件结构，响应这些按钮 ✔：
  - Start A-Scan / Start A-Line、Start B-Scan、Start C-Scan、Start V-Scan
  - Move X / Move Y / Move Z、Set Origin、Set Pos0、Go2Pos0
  - Save Params、Save Image、STOP Program
- 采集数据通过名为 "Raw A-Line Data" 的队列，从采集部分传给处理和显示部分（生产者-消费者结构）✔
- 保存的 .dat 文件头：Header=0 A-Line、1 B-Scan、2 C-Scan、3 V-Scan ✔

## 子 VI 分工
| 子 VI | 做什么 | 依据 | 对应我的模块 |
|---|---|---|---|
| Initialization | 打开 ATS9462、校验板卡，建队列 | ✔ 控件名 | 2 |
| Digitizer_initialization（`ATS9462-VI\`） | 设置 ATS：时钟、量程、阻抗、触发源/电平/斜率、`Trig. Delay (us)`、RecordLength、RecordsPerBuffer、Subpixel Num、DMA 模式（Continuous / Triggered / No-Pre-Trigger / Traditional）。框图注释："1 record = 1 trigger"、"Whether use on-board memory or not: T=Y, F=N" | ✔ | 2、3 |
| GetDAQAsyncData | 从 DMA 取数据（Get_Stream），送进队列 | ✔ | 3 |
| GeneratePulses（+ load_S_curve、acc_delta.dat） | 给一个位（bit）生成 STEP 脉冲串，参数有 pulses、samples、dir，可选 S 曲线加减速 | ✔ 控件名；算法 ? | 4 |
| GenerateSkipPulses | 生成触发位（bit6/7），参数 Skip_Period。前面板注释："Bits 6 and 7 skips pulses, the 1st pulse not skipped" | ✔ 控件名；含义 ? | 4 |
| GenerateDiffPulses + current_pos | 从 Curr_Pos 走到 Target_Pos，X/Y/Z 可分别启用 | ✔ 控件名 | 5 |
| GateTrig | "Laser Enable Trigger"：按 bit num 控制触发位开或关 | ✔ | 4（安全） |
| InitDODAQ | 建数字输出任务：通道 `Dev1/port0/line0:7`，板载时钟，按整个端口写入（U32）。可选 AO 振镜任务 `Dev1/ao0:1`，数字输出用 `/Dev1/ao/StartTrigger` 同步启动（注释 "Synchronization with AO for Galvo scan"） | ✔ | 5 |
| RunDODAQ / StopDODAQ | 启动任务 → 等待完成 → 停止 → 清除 | ✔ | 5 |
| SendDOPulses | 单独发一段数字脉冲（有限样本、板载时钟）。推断用于手动 Move | ✔ / ? | 5 |
| SendCOPulses | 用计数器产生触发（Trig Rate、Trig Num、Laser/DAQ Trig Terminal）。**Main 没有调用它** | ✔ | 参考 |
| ScanXY、ReturnGalvo、scan_pattern.mat、MATLAB 脚本节点 | 振镜图案扫描，从 UV-PAM 继承。脚本节点读取 `E:\UV-PAM_Data\...\sampling_rows_smoothed_300.mat`。推断你的系统不用 | ✔ / ? | 跳过 |
| ProcessDAQData、AverageRawData、RawData2Range、BScanProjection、DisplayAvgAline、Array2GrayPic | 数据整形（reshape）、平均、取窗口、最大减最小投影、显示 | ✔ 控件名 | 7 |
| CreateFolder、CreateBinaryFile、SaveBinaryData、SaveMatrix、Save2RealTIF（CTIFF） | 建文件夹、写二进制 .dat、存矩阵和 TIFF | ✔ | 7 |

## 前面板参数名 ✔（默认值待截图）
- **ATS 端：** DAQ Sample Rate、A-Line Points、Trig Delay (us)、Trig Level、Trig Slope、Triger Source、CH1 Range、CH2 Range、Subpixel Num、RecordsPerBuffer
- **扫描端：** delta_x / delta_y / delta_z、xdir / ydir / zdir、Motor Pulse Rate（"Number of DO pulses per second"）、Trig Rate (Hz)、DO Sample Rate、Motor and Trigger Lines、Pulses/Buffer、Use S Curve?、Continous B-Scan?、Pos0
- **显示和保存：** A-Line Start、A-Line Window Size、Chan1/Chan2 Display?、B-Scan/C-Scan Display?、Save Directory、Data Name、Save Data?
- **其他前面板文字：** "Reference Clock = 10 MHz"；位分配 Bit0 X Pulse (P0.0) … Bit7 Laser Trigger (P0.7)

## 已有的 LabVIEW 时序实测（`Desktop\System_test_09_25\`）
- 从 LabVIEW Probe 导出的 Forward DO（U8）：电机 16 / 8 / 4 kHz，Xn = 200，dX = 8，触发 100 kHz，DO 500 kS/s，kx = 0.25。分析脚本是 `bscantest.m`。
- 用途：作为 LabVIEW 时序的"实测样本"，和我自己的时序做对照。

## 待截图确认的问题
1. Start B-Scan 分支里，delta_x、Motor Pulse Rate、Trig Rate、Subpixel Num 是怎么算成整段时序的？
2. GenerateSkipPulses 的 Skip_Period 是什么意思？触发频率和 DO 采样率是什么关系？
3. S 曲线（acc_delta.dat）怎么用？
4. ATS 的 RecordsPerBuffer 和 Subpixel Num、每条线的 A-line 数有什么关系？
5. 平时实际用的参数值（前面板默认值）。

## 截图转写
（每读完一张截图，在这里按"文件名 → 看到了什么 → 结论"记录。）

### 10/4 第一批（Main 前面板 + 4 个子 VI，`docs/screenshots/LV_*.png`）

**Main 前面板，平时用的参数**（`LV_Main_FP_Settings/IO/Scan.png`，是打开时保存的默认值，不一定是最后一次实验用的）

| 页 | 参数 | 值 | 和 MATLAB 版本的对照 |
|---|---|---|---|
| Settings | DAQ Sample Rate | **100 MS/s** | MATLAB 用 180 MS/s |
| Settings | Trig Delay (us) | **3.5 µs** | MATLAB 用 0。3.5 µs ≈ 350 点（100 MS/s） |
| Settings | A-Line Points | 64（显示被截断，待核对） | MATLAB 1024 |
| Settings | CH1 Range / CH2 Range | **200 mV / 4 V** | CH1 = 光声信号（小）；CH2 = 光电二极管（大） |
| Settings | kx / ky / kz | 0.25 / 0.9 / 0.25 | **含义待确认。** 10/4 电机标定实测 0.5 µm/脉冲，三台驱动器、电机都一样，而 ky = 0.9，所以 kx/ky/kz 很可能**不是** µm/脉冲（用户推测和加速度 / S 曲线有关）。确认方法：在 Settings 页右键 kx → "查找接线端"，看框图里接到哪个子 VI（是否进 GeneratePulses / load_S_curve），截图 `LV_Main_BD_kx.png`。只打开、不运行、不保存 |
| Settings | 文字 | "1 pulse = 10 um under 200 step setting" | — |
| I/O | Motor and Trigger Lines | `Dev1/port0/line0:7` | Bit0 X Pulse (P0.0)、Bit1 X Dir (P0.1)、Bit2/3 Y、Bit4/5 Z、**Bit6 DAQ Trigger (P0.6)、Bit7 Laser Trigger (P0.7)**；"Bits 6 and 7 skips pulses, the 1st pulse not skipped" |
| I/O | DO Sample Rate | **500000** | MATLAB 方式上限 250 kS/s |
| I/O | Reference Clock | 10 MHz | — |
| I/O | Motor Pulse Rate | **16000**（每秒 DO 脉冲数） | = 电机步频 16 kHz |
| I/O | **Triger Source** | **Chan_B** | ⚠ **不是 TRIG IN！** ATS 用 CH B 上的信号（光电二极管）当触发源 |
| I/O | **Trig Level** | **144** | CH B 量程 ±4 V 下：(144−128)/127 × 4 ≈ **0.50 V** |
| I/O | Trig Slope | Positive | 同 MATLAB |
| I/O | Scan AO Channel(s) | Dev1/ao0:1 | 振镜（galvo），本项目暂不用 |
| Scan | Subpixel Num | 20 | — |
| Scan | Trig Rate (Hz) | **100000** | 即 100 kHz |
| Scan | Pulses/Buffer | 2400 | — |
| Scan | Laser Freq (Hz)（Galvo 参数） | 200000 | 振镜用，待确认 |

**结论 1（重要）：LabVIEW 原程序的 ATS 触发源是 CH B，不是 TRIG IN。** 推测接法：光电二极管 → ATS **CH B**（±4 V），换能器/放大器 → **CH A**（±200 mV）。触发电平 144 ≈ 0.5 V，然后再等 Trig Delay 3.5 µs 才开始记录（跳过激光刚发出后、声波还没到的那段）。这就是导师说的"两个通道分别是什么"：一个是光电二极管（触发和时间零点），一个是光声信号。MATLAB 现在用 TRIG IN 外触发，两种做法都能用：CH B 触发的好处是可以同时把光电二极管波形记下来（能量监测）；TRIG IN 的好处是不占一个模拟通道。

**GenerateSkipPulses.vi**（`LV_GenerateSkipPulses_*.png`）
- 输入：xn（脉冲数）、samples、Use S Curve?、**Bit**（第几位）、**Skip_Period**、en。输出：pulsetrain（U8 数组，每个元素是一个 DO 采样点上 8 根线的状态）。
- 做法：先算出 xn 个脉冲各自间隔几个 DO 采样点（Use S Curve? = False：samples ÷ xn，均匀分布；True：LOAD S CURVE，按加减速曲线分布），累加得到每个脉冲的位置；然后逐个采样点循环，**到了第 k 个脉冲的位置，就看 k mod Skip_Period 是否等于 0**：是，就在这个采样点输出 2^Bit（en 为真时）；否则输出 0。
- 结论 2（10/4 修正）：GenerateSkipPulses 是一个**通用的脉冲串生成器**：在 samples 个 DO 采样点里放 xn 个单点脉冲（每个只有 1 个 DO 采样点宽，500 kS/s 下 2 µs），每 Skip_Period 个保留一个，第 1 个一定保留（前面板注释 "the 1st pulse not skipped"）。**它本身不决定触发是"固定频率"还是"跟着电机步"，要看 Main 传进来的 xn、samples、Use S Curve?。** 根据 ForwardDO 实测数据（`System_test_09_25`）的分析，触发是固定 100 kHz，和 16 kHz 步频是非整数比 6.25（见 03），也就是**按时间均匀，不和电机步一一对应**。待截 Start B-Scan 分支确认。Skip_Period 的一个用途可能是让激光位（bit 7）降频：激光 NPL45C 最高 50 kHz，100 kHz 的触发要隔一个发一个。

**SendCOPulses.vi**（`LV_SendCOPulses_*.png`）
- 用计数器 `Dev1/ctr0` 产生 **CO Pulse Freq**（占空比 0.5），Finite Samples，个数 = Trig Num，频率 = Trig Rate；用 `CO.Pulse.Term` 把计数器输出**路由到 DAQ Trig Terminal 和 Laser Trig Terminal**（默认都是 `/Dev1/PFI0`，也就是 BNC-2110 上的 **PFI 0/P1.0** BNC 口）。
- **Main 没有调用它**（见上文子 VI 分工）。
- 结论 3（回答导师"terminal 是什么"）：terminal 是 NI 卡上**输出触发脉冲的物理端子**。在 SendCOPulses 里，它是计数器输出被路由到的 PFI 端子（默认 PFI0）；在 Main 实际用的 DO 方式里，"端子"就是 port0 的 line6（P0.6，DAQ 触发）和 line7（P0.7，激光触发）。导师/你记得的"terminal 7"最可能是 **P0.7（激光触发）**，待和导师确认。

**InitDODAQ.vi**（`LV_InitDODAQ_*.png`）
- DO 任务：通道 = DO lines（port0/line0:7），**时钟 = OnboardClock，频率 = DO sample rate**，Finite Samples；写入 Digital 1D U32（整个端口一次写一个字）；**开始触发 = `/Dev1/ao/StartTrigger` 上升沿**（注释 "Synchronization with AO for Galvo scan"），也就是 DO 等 AO（振镜）开始时一起开始。
- AO 任务：`Dev1/ao0:1`，±10 V，Finite Samples，写 Analog 2D DBL；PatternScan 时按 pattern_rows 生成振镜波形，否则按 Galvo Parameters 生成。
- 结论 4：LabVIEW 的 DO 用**板载时钟**（500 kS/s），不借 AI 时钟，所以能比 MATLAB 的 `daq` 方式快一倍；DO 和 AO 用 StartTrigger 硬件同步。（前面板 error out 里的 −200099 是打开时保存的旧值，不是这次运行出的错。）

**GateTrig.vi**（`LV_GateTrig_*.png`）
- 输入 samples num、bit num、enable；对每个采样点输出 2^bit（enable 为真时），**但第 0 个和最后一个采样点输出 0**。
- 结论 5：它生成"激光允许"门控：整段扫描期间这一位一直为高，开头和结尾各留一个低电平，保证有一个干净的上升沿和下降沿。

**还没截的：** Main 的框图（Start B-Scan 分支、A-Scan 分支），Digitizer_initialization.vi 框图。要回答"整段时序怎么算出来"（上面问题 1），需要 Start B-Scan 分支。
