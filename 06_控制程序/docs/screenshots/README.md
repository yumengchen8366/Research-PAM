# 截图和照片清单

## 怎么用
1. 按下表的文件名保存到本文件夹（png 或 jpg 都可以）。框图太大就分块截，在文件名后加 `_1`、`_2`；case 结构的**每个分支**都要截。
2. 在当前窗口说"读一下新截图"。Claude 读图后，把要点写进 `../02_LabVIEW程序地图.md` 的"截图转写"部分（或 `../01_硬件与接线.md`），再把下表的状态改成"已转写"。
3. 以后的新窗口直接读 md 文字就行，不用每次重新看图。图片会一直留着，需要时可以再看。

## LabVIEW 截图
| 文件名 | 内容 | 状态 |
|---|---|---|
| `LV_Main_FP_Settings.png` | Main.vi 前面板 Settings 页，填好平时用的参数 | 待截 |
| `LV_Main_FP_IO.png` | 前面板 I/O 页（DO 采样率、线路、触发等） | 待截 |
| `LV_Main_FP_Scan.png` | 前面板 Scan 页（delta_x、Motor Pulse Rate、Trig Rate、Subpixel Num 等） | 待截 |
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
| `HW_BNC2110_terminals.jpg` | BNC-2110 弹簧端子区，能看清每根线接在哪 | 待拍 |
| `HW_SR2_X.jpg`（以及 `_Y`、`_Z`） | 各 SR2 驱动器的接线和拨码开关 | 待拍 |
| `HW_ATS9462_back.jpg` | ATS9462 背板：CH A、CH B、TRIG IN、AUX 各接了什么 | 待拍 |
| `HW_laser_trigger.jpg` | 激光的外触发输入 | 待拍 |
