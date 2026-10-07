# 11 Maria 的 Control_py 对照，以及导师说的 "hardware timing"

（10/3 在会话"B-scan"里读代码和讨论，10/4 晚整理成文。Control_py 在 `C:\Users\2031\Desktop\Control_py`，原版在 `C:\Users\CAO LAB\Desktop\Control_py`，只读、不进 GitHub。注释是英文，**是不是 Maria 写的、她现在用的是不是这一版，待问她**。）

## 导师的原话（10/3 Slack）
> chat with Maria and ask what she is using. you will need to use the hardware timing

我的理解（待和导师/Maria 确认）：hardware timing 是 NI-DAQ 的术语。先把整段波形算好放进缓冲区，由采集卡自己的时钟逐点输出，每个边沿的时间由晶振决定。与之相对的是软件定时：在 Python/MATLAB 里用循环 + pause 一根一根地写线，Windows 会带来毫秒级抖动。导师的意思应该是：**电机步进、激光触发、采集触发都要由同一个硬件时钟产生**。按这个标准，`bscan_test.m`（`dq.Rate` + `readwrite` 整张表输出）、Control_py、LabVIEW（500 kS/s）都是硬件定时。剩下靠软件保证的只有"ATS 先 arm、再开始输出"的先后顺序。

## Control_py 怎么用
- 入口 `scriptControl_TS.py`：先启动 `TS_aq_stream.py`（ATS9462），等它打印 `Acquisition started.`（已 arm），再启动 `unScan_TS.py`（Dev1 输出整个扫描波形）。顺序和 `bscan_test.m` 一样。
- 扫描参数只改 `unScan_TS.py` 顶部，`scriptControl_TS.py` 通过环境变量传给 ATS 脚本。没有"只检查不运行"的开关，运行就会动 X/Y 电机、发 P0.7。
- 用 `.venv\Scripts\python.exe` 运行（Python 3.13，nidaqmx、numpy、SDK 自带的 atsapi）。
- 数据路径写死在 `TS_aq_stream.py`：`C:\Users\CAO LAB\Desktop\Control_py\PA_data`。每行 151 MB，默认 50 行约 7.6 GB。
- `scriptControl.py`（NPT 版本）调用的 `unScan_NPT_single.py` 不在文件夹里，跑不了。

## 默认参数下它做什么（10/3 只读 import 算出，没碰硬件）
| 项目 | Control_py（`unScan_TS.py` + `TS_aq_stream.py`） |
|---|---|
| NI 定时 | 一个硬件定时 DO 任务，**5 kS/s，用板卡自己的采样时钟**（Python nidaqmx 在 X 系列上可以直接给 DO 设时钟；MATLAB 要借 AI 时钟） |
| 线路 | P0.0/0.1 X STEP/DIR，P0.2/0.3 Y STEP/DIR，**P0.6 DAQ，P0.7 激光**（和 LabVIEW 前面板、`bscan_test.m` 一致） |
| 运动 | **移动–停–触发**：每个位置停下 → 激光触发 1 次 → 走 20 个微步 = 10 µm（2.5 kHz，1.25 mm/s）。每个位置 8.4 ms（约 119 Hz）。50 × 50 个位置（0.5 × 0.5 mm），单向扫、每行回程，共 41.4 s |
| 激光 | 每个位置 1 个触发（共 2500 个）。注释说一个触发让激光打一串 burst（`LASER_FREQ = 50_000`），但这几个常数没输出到任何线上，burst 应该在激光那边设置（待问） |
| ATS | **触发流式（Triggered Streaming）**：每行只有 1 个 DAQ 触发（共 50 个），之后连续采 0.42 s（180 MS/s），整行存成一个文件；哪段对应哪个位置，事后按"距行触发的时间"切。每行在回程（约 0.4 s）里软件重新 arm，靠数 `Acquisition started.` 的次数检查有没有漏行 |
| ATS 输入 | CH A，AC 耦合，±200 mV，50 Ω；外触发 DC、ETR_5V、电平 150 |

## 和 `bscan_test.m` 对照
| | `bscan_test.m` | Control_py |
|---|---|---|
| NI 定时 | 硬件定时，248 kS/s（借 AI1 时钟） | 硬件定时，5 kS/s |
| 运动 | 匀速飞扫，有线性加速 | 移动–停–触发 |
| ATS 模式 | NPT：每个触发采 1 条 512 点 A-line | TS：每行 1 个触发，整行连续流 |
| A-line 和位置 | 每条记录天然对应一个位置 | 事后按时间切 |
| ATS 输入 | DC，±4 V | AC，±200 mV |
| arm | 一次 arm 收全部 A-line，所有 buffer 预先提交 | 每行重新 arm，必须在回程内完成 |
| 激光 | 每条 A-line 1 发（默认 800–1000 Hz） | 每个位置 1 个 burst |

旧 LabVIEW 系统的激光是连续 100 kHz 触发（`System_test_09_25\bscantest.m`），三种方式都不一样；NPL45C 规格是外触发、输入 0.2–2 V、最高 50 kHz（见 09 第 4 部分）。

## 要问 Maria 的
1. 她现在实际跑的是 `scriptControl_TS.py`（流式）还是 NPT 版本？`unScan_NPT_single.py` 在哪？
2. 激光怎么设的：外触发 burst 模式吗？每个触发几发、什么频率？P0.7 的 5 V 怎么接到只能接受 0.2–2 V 的激光输入？
3. P0.6 → ATS TRIG IN、P0.7 → 激光，实物接线是不是这样？（10/4 晚：BNC-2110 上那根悬空的红头蓝线不是 P0.6，大概率是 P0.7。）
4. SR2 运行电流为什么设成 0.3 A（SW1–3 = ON ON ON，电机额定 1.7 A）？
5. 放大器输出多大，为什么用 AC ±200 mV？流式数据怎么切成每个位置的 A-line？
6. 为什么选移动–停–触发，而不是匀速扫？速度上有没有遇到过丢步？

## 要问导师的（只问要他拍板的，先问完 Maria）
1. 在 Maria 那套上继续，还是继续做自己的匀速扫描版本？
2. B-scan 目标：扫描速度、步长、范围是多少？（决定用匀速扫还是移动–停–触发）
3. SR2 电流能不能从 0.3 A 调大？
