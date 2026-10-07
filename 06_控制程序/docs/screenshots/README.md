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
| `LV_GenerateSkipPulses_FP/BD_1–4.png`、`LV_SendCOPulses_FP/BD.png`、`LV_InitDODAQ_FP/BD_1–4.png`、`LV_GateTrig_FP/BD_1–2.png` | 子 VI 前面板和框图 | 10/4 已转写（02） |
| `LV_Main_BD_kx.png` | Settings 页右键 kx → 查找接线端，截 kx/ky/kz 在框图里接到哪里（判断是不是加速度系数） | 待截 |
| `LV_Hierarchy.png` | 查看 » VI 层次结构 | 待截 |
| `LV_Main_BD_StartBScan_*.png` | 框图中 "Start B-Scan" 事件分支（包括里面的每个子分支） | 待截 |
| `LV_Main_BD_StartAScan_*.png` | "Start A-Scan / A-Line" 分支 | 待截 |
| `LV_Main_BD_Move_*.png` | "Move X/Y/Z" 分支 | 待截 |
| `LV_GeneratePulses_BD.png` | GeneratePulses.vi 框图 | 待截 |
| `LV_GenerateSkipPulses_BD.png` | GenerateSkipPulses.vi 框图 | 待截 |
| `LV_GenerateDiffPulses_BD.png` | GenerateDiffPulses.vi 框图 | 待截 |
| `LV_InitDODAQ_BD.png` | InitDODAQ.vi 框图 | 待截 |
| `LV_Digitizer_initialization_BD_*.png` | ATS9462-VI\Digitizer_initialization.vi 框图 | 待截 |
| `LV_GetDAQAsyncData_BD.png` | GetDAQAsyncData.vi 框图 | 待截 |

## 硬件照片
| 文件名 | 内容 | 状态 |
|---|---|---|
| `HW_BNC2110_terminals.jpg`（另有 `_2`、`_3`） | BNC-2110 弹簧端子区，能看清每根线接在哪 | 10/4 已拍，初步转写进 01（待逐根核对） |
| `HW_SR2_X_label_wiring.jpg` | X 轴 SR2（贴 "X motor"，序列号 243107344）正面标签和两排端子 | 10/4 已拍，已转写（01） |
| `HW_SR2_control_wiring.jpg`、`HW_5V_wago_STEPplus.jpg`、`HW_BNC2110_terminals_motor.jpg` | 控制端子接线；+5 V 白线经 WAGO 分到三台驱动器的 STEP+/DIR+；BNC-2110 上 P0.0–P0.5、+5 V、D GND 的线 | 10/4 已拍，已转写（01） |
| `HW_SR2_SW9-12.jpg` | 驱动器侧面的 SW9–12（ON 朝下）：OFF ON OFF OFF，三台一样 | 10/4 已拍，已转写（01） |
| `HW_SR2_terminal_face_SW1-8.jpg` | 端子面上的 SW1–8（两排端子中间）。太糊，读不出 | 已被下一张取代 |
| `HW_SR2_terminal_face_SW1-8_clear.jpg` | X 驱动器 SW1–8 重拍：SW1–3 = ON ON ON（0.3 A）、SW4 ON、SW5–8 = ON OFF ON OFF | 10/4 晚已拍，已转写（01） |
| `HW_SR2_X_label_tables.jpg` | X 驱动器标签清晰版：电流表、细分表、SW4 含义（ON = Half Current，OFF = 90%）、LED 代码 | 10/4 晚已拍，已转写（01） |
| `HW_SR2_DB9_loose_wires.jpg` | 滑台 DB9 线拆开后，除电机 4 根外的几根线头悬空（推测是限位/原点传感器） | 10/4 已拍，已转写（01） |
| `HW_motor_power_KORAD.jpg` | 电机电源 KORAD KD3005D，23.88 V，空闲 0.098 A | 10/4 已拍，已转写（01） |
| `HW_motor_SST43D2126_1/2/3.jpg` | 三个滑台的电机铭牌（SST43D2126，1.8°/步，1.65 Ω） | 10/4 已拍，已转写（01） |
| `HW_X_stage_ruler.jpg` | X 滑台旁边放钢尺（标定时用钢尺读位移） | 10/4 已拍 |
| `HW_BNC2110_P06_in_USER1.jpg` | P0.6 的蓝线插进上排 USER 1 端子（D GND 右边），10/7 测试接法 | 10/7 已拍，已转写（01、13） |
| `HW_DG852_burst_settings_1007.jpg` | DG852 Pro Burst 页：两通道 NCycle 1、Ext Leading、Idle Bottom；CH2 Delay 2 µs | 10/7 已拍，已转写（13） |
| `SCOPE_P06_into_TRIGIN_1007.jpg` | P0.6 直接接 TRIG IN（50 Ω）的脉冲：Top 2.84 V、宽 8 µs | 10/7 已拍，已转写（01、13） |
| `SCOPE_P06_DG852_chain_1007.jpg` | P0.6 → 发生器 G1（晚 580 ns，宽 5 µs）→ G2 测试脉冲（再晚约 2 µs），发生器接 1 MΩ 时 | 10/7 已拍，已转写（13） |
| `HW_ATS9462_back.jpg` | ATS9462 背板：CH A、CH B、TRIG IN、AUX 各接了什么 | 待拍 |
| `HW_laser_trigger.jpg` | 激光的外触发输入 | 待拍 |
