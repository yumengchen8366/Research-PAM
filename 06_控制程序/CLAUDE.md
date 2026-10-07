# PAM 控制程序：用 MATLAB 写自己的版本

> 2026-10-04 起本文件夹并入 Research-PAM 仓库（原实验室电脑 `C:\Users\2031\Desktop\PAM_controlProgram`）。通用规则和收工流程见仓库根目录 `CLAUDE.md`；下面的路径已改成仓库内路径，`LabviewPAM\`、`Control_py\` 只在实验室电脑本地。

## 协作方式
- 我是 PhD 学生。目标是读懂现有 LabVIEW 程序 SlowScan_ENdaq，并用 MATLAB 写出**我自己的版本**。不要求和 LabVIEW 一样，但每个模块都要能说清两者的异同和原因。
- 一步一步来：先讲原理和每个参数，再写代码；写完的代码要讲到我能自己修改。
- 一个窗口只做一个模块。计划有三份：`docs/07_给导师的四周计划.md`（对导师的承诺，英文版 `docs/07_Four_Week_Plan_EN.md`，两者要同步修改；第 1 周 A-line 全部测试，第 2–4 周电机/时序、B-scan、C-scan，不含 LabVIEW）、`docs/08_我的LabVIEW清单.md`（自己读 LabVIEW 的任务）、`docs/04_四周计划.md`（早先的内部版本，保留）。
- 不确定的事写"待确认"，不要当成事实。
- 每个窗口结束前，在 `docs/工作日志.md` 末尾加三行：做了什么、结果、下次第一步。新确认的事实同步写进 docs 里对应的文件。

## 开新窗口先读
1. `docs/工作日志.md` 的最后几条
2. 和本模块相关的 docs 文件

## 文件位置
| 位置 | 内容 | 规则 |
|---|---|---|
| `LabviewPAM\`（仅实验室电脑本地，不进 git；Mac 上对应 `../03_LabVIEW代码/`） | 5 个 LabVIEW 原程序，主要看 `SlowScan_ENdaq\Main.vi` | 只读，不改、不移动。5 个文件夹互相引用，要放在一起 |
| `docs/` | 项目知识库（硬件、LabVIEW 地图、对照、计划、参数字典、日志） | 新信息写这里 |
| `docs/screenshots/` | LabVIEW 截图和接线照片，清单见其中的 README.md | 读完截图后把要点转写进 md |
| `docs/tools/vi_dump.py` | 从 .vi 文件提取控件名、子 VI、常量（只读） | 用法见文件开头 |
| `../07_MATLAB/` | 现有 MATLAB 代码和 `aline_data/`（原 `Desktop\Matlab\`） | 状态见 `docs/06_现有代码与进度.md` |
| `../07_MATLAB/System_test_09_25/` | LabVIEW Forward DO 导出数据 | |
| `../07_MATLAB/AlazarInclude/` | ATS SDK 的 AlazarDefs.m 等（查常量用）；脚本里 `sdkInclude` 仍指向实验室的 `C:\AlazarTech\ATS-SDK\23.3.0\...` | |
| `C:\Users\2031\Desktop\Control_py\`（仅实验室电脑，22 GB） | 同学写的 Python 版本 | 只作参考，只读 |
| `../01_硬件资料/` | 手册：CXP 滑台、SR2 驱动器、激光测试报告、ATS9462 规格书、ATS-SDK-Guide | |

## 硬件速查（详见 `docs/01_硬件与接线.md`）
- NI PCIe-6323 = `Dev1`，经 BNC-2110（接在 Connector 0）引出。
- AlazarTech ATS9462：CH A 接信号，TRIG IN 接外触发。SDK 在 `C:\AlazarTech\ATS-SDK\23.3.0`。
- 数字输出位：P0.0 X STEP、P0.1 X DIR（已实测确认）；P0.6 采集触发（10/7 实测：不带负载 4.97 V，直接推 50 Ω 的 TRIG IN 时 2.84 V；测试时经 BNC-2110 USER 1 → 函数发生器外触发 → TRIG IN，见 `docs/13_B-scan记录.md`）；P0.2/3 Y、P0.4/5 Z、P0.7 激光触发（LabVIEW 前面板标注，实物待核对）。
- 滑台 CXPF50-80100：行程 50 mm，导程 2 mm；SR2 每转 4000 步，**0.5 µm/脉冲**（10/4 实测）。`MOVE_UM > 0`（DIR = 1）= 朝电机走。不加速直接起步 ≤4 mm/s，5 mm/s 会失步。驱动器是共阳极接法（STEP−/DIR− 接 P0.x，STEP+/DIR+ 接 +5 V）。限位没接。
- MATLAB 的定时数字输出要借 AI 时钟（≤250 kS/s）；LabVIEW 用板载时钟 500 kS/s。

## 安全规则
- 硬件脚本默认"检查模式"（`RUN_HARDWARE = false`），确认后才改成 true。
- 激光触发默认关闭。
- 运行 MATLAB 前，先关闭占用 Dev1 或 ATS9462 的 LabVIEW 程序。
