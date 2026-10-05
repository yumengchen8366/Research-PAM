# Maria 的 control_py（参考用，不改）

- 来源：Maria 的 Google Drive `control_py`，2026-10-05 下载；代码修改时间 2026-10-03。
- 没复制：`.venv`（Windows 虚拟环境）、`__pycache__`、`.vscode`；`data/`、`data_aquisition/` 下载下来是空的（0 B）。
- 语言：Python（nidaqmx + AlazarTech SDK 自带的 `atsapi`）+ 一个 MATLAB 分析脚本。只能在 CAOLAB1 上跑，路径写死为 `C:\Users\Caolab\...`。
- 依赖（从 `.venv` 看）：`numpy 2.5.3`、`nidaqmx 1.6.0`；`atsapi` 来自 `C:\Users\Caolab\Desktop\daq\23.3.0\Samples_Python\Library\atsapi`，不能 pip 装。

## 文件
| 文件 | 作用 |
|---|---|
| `unScan_TS.py` | 生成 6 路 DO 波形（X/Y STEP、DIR，DAQ，LASER），nidaqmx 1000 Hz 硬件定时输出；单向扫描，每个位置一次激光触发，每行一次 DAQ 触发 |
| `TS_aq.py` | ATS9462 配置 + 每行一次 triggered streaming 采集，存 `PA_data/scan_*/row_001.bin`（3 位编号） |
| `TS_aq_stream.py` | 同上 + 写盘线程和 RAM 池，可长时间连续采；存 `row_00001.bin`（5 位编号） |
| `scriptControl_TS.py` | 总控：先启动 ATS，等到打印 "Acquisition started"（已 arm）后再启动 NI DO |
| `signalAnalysis_TS.m` | MATLAB 用 memmapfile 读 `row_%05d.bin`（uint16），按 (raw−32768)/32768×0.2 V 换算电压并画图 |
| `Screenshot 2026-10-03 175222.png` | Row 1，0.26–0.28 s 的电压波形 |

## 关键参数（全部是 [文件确认]，即 Maria 代码里的设定；用到我们系统前要核对）
| 参数 | 值 | 出处 |
|---|---|---|
| X STEP / X DIR | `Dev1/port0/line0` / `line1` | `unScan_TS.py:13-14`（与 10/2 确认的 P0.0/P0.1 一致） |
| Y STEP / Y DIR | `line2` / `line3` | `unScan_TS.py:16-17` |
| DAQ / LASER | `line6` / `line7` | `unScan_TS.py:19-20`（与 B-scan 时序图 v4 的 Bit6/Bit7 一致） |
| 丝杠导程 | 4 mm/圈 | `unScan_TS.py:23` |
| 步距 | 200 步/圈（1.8°） | `unScan_TS.py:24` |
| 细分 | 1/4（写死在代码里，不是读拨码得到的） | `unScan_TS.py:25` |
| 每脉冲位移 | 4/200×1/4 = 0.005 mm = 5 µm [条件计算] | `unScan_TS.py:27` |
| 扫描范围 / 步长 | X、Y 各 0.5 mm / 0.01 mm → 每位置 2 个脉冲，每行 50 个位置，共 50 行 | `unScan_TS.py:29-38` |
| DO 采样率 | 1000 Hz（STEP 脉冲 1 ms 高 + 1 ms 低） | `unScan_TS.py:26` |
| 每行记录长度 | 300 个 DO 采样 = 0.3 s [条件计算] | `unScan_TS.py:89-97` |
| ATS 采样率 | 180 MS/s，内部时钟 | `TS_aq.py:30-34` |
| CH A | AC 耦合，±200 mV，50 Ω | `TS_aq.py:38-41` |
| 外部触发 | TRIG IN，DC 耦合，ETR_5V，上升沿，level 150 → (150−128)/128×5 V ≈ 0.86 V [条件计算] | `TS_aq.py:51-62`（和我们 10/3 实测阈值 0.6–1.2 V、公式 0.87 V 吻合） |
| 数据率 | 180 MS/s × 2 B = 360 MB/s；一行 0.3 s ≈ 108 MB | `TS_aq.py:22`、`TS_aq_stream.py:13` |

## 和我们 MATLAB 计划的区别
- Maria：每行只 arm 一次，ATS 用 triggered streaming 录完整一行（含电机移动的时间），之后再从长记录里切出每个位置。
- 我们（docs/07）：移动–停–触发，每个位置录一条短 A-line。
- Maria 在 Python nidaqmx 里直接给 DO 配了采样时钟；我们 10/2 的结论是 MATLAB 里定时 DO 要借 AI 时钟。差别是不是 MATLAB 工具箱的限制 —— 待确认。

## 注意（不要照抄）
- `TS_aq.py:76-84` 那段计算没被用到，`TIME_ROW` 的公式也是错的。
- `unScan_TS.py:212-224` 长度检查重复了两遍。
- `TS_aq.py` 存 3 位编号，`signalAnalysis_TS.m` 读 5 位编号（对应 stream 版）。
- 截图里很多尖峰停在 −0.2 V，也就是 ±200 mV 量程的下限 → 削顶了；这些尖峰是 PA 信号还是噪声，待确认。

## 要问 Maria
1. 截图里的尖峰是什么信号？量程要不要加大？
2. 1/4 细分是测过的，还是照着拨码写的？
3. Python DO 硬件定时有没有用示波器验证过？
