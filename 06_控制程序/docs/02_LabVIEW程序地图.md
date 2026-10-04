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
