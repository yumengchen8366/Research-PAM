# 17 MATLAB 练习计划（用自己的代码学）

> 2026-10-15 建。起因：10/15 Rui 说我对 MATLAB 不熟悉，要我先学会自己 plot 一条 A-line，并且能逐行讲清 `bscan_test.m`。
> 配套：`18_bscan_test逐行讲解.md`（逐行讲解，当参考书查，不是用来背的）；练习在单独的「MATLAB 练习」窗口里做，Claude 先让我预测、再运行核对，不直接给答案。
> 每天 30–45 分钟，约一周。每天结束在本文末尾「练习记录」加一行：做了什么、哪里卡住、明天从哪开始。

## 0 目标（做到这些就算"熟悉"）
1. 不看资料，在命令行里画出任意一条 A-line（横轴 µs、纵轴 V），并能改成看第 k 条、看几条叠在一起、看 B-scan 图。
2. 能逐行讲 `bscan_test.m`：每一行在做什么、变量是什么形状（`size`）和类型（`class`）、改了会怎样。
3. 改参数前能先算出结果：K、步频、速度、触发频率、A-line 条数、DO 采样率；程序报 assert 时知道是哪条规则、怎么改。
4. 自己从零写一个约 20 行的脚本：读存好的 B-scan / C-scan 文件，画 A-line 和 MAP。

## 1 三个看代码的工具（第一天先学会）
| 工具 | 怎么用 | 用来干什么 |
|---|---|---|
| 分节运行 | 光标放进 `%%` 开头的一节，按 **Ctrl+Enter** | 只跑这一节，看这一节产生了哪些变量 |
| 断点 | 点行号左边出现红点 → 运行 → 停在那一行；**F10** 走一行，**F5** 继续，`dbquit` 退出，`dbclear all` 清所有断点 | 看着程序一步步跑 |
| 看变量 | `size(x)`、`class(x)`、`whos`、`x(1:10,:)`、双击工作区里的变量 | 知道变量是几行几列、什么类型、里面是什么数 |

命令行出现 `K>>` = 停在断点里；不想调试了就 `dbquit`。

## 2 你代码里用到的 MATLAB 概念（按出现顺序，每次弄懂 3–4 个）
| 代码里的例子 | 概念 | 一句话 |
|---|---|---|
| `RUN_HARDWARE = false;` | 变量、分号 | 行尾 `;` = 不打印结果 |
| `ATS.sampleRate_Hz = 180e6` | 结构体 struct | 一个变量里装多个有名字的字段；`180e6` = 180 × 10⁶ |
| `round`、`floor`、`ceil`、`mod`、`abs` | 取整和余数 | `mod(7,3) = 1`；`floor(31.25) = 31` |
| `assert(条件, '消息', 值)` | 检查 | 条件为假就报错停下，消息里 `%.2f` 被后面的值替换 |
| `false(N, 4)`、`do(rA, 1) = ...` | 逻辑矩阵、行列索引 | `do(行, 列)`；`:` = 全部；`end` = 最后一个 |
| `repmat`、`[a; b; c]`、`flipud` | 拼接 | 竖着拼用 `;`，横着拼用 `,` |
| `cumsum`、`diff`、`find` | 累加、相邻差、找位置 | 时序表的位置、触发点就是这三个算出来的 |
| `fprintf('%d 条，%.2f um\n', a, b)` | 格式化输出 | `%d` 整数、`%.2f` 两位小数、`\n` 换行 |
| `figure`、`plot`、`subplot`、`stairs`、`imagesc`、`xlabel` | 画图 | `plot(x, y)`；给一个矩阵时每一**列**画一条线 |
| `function y = f(x) ... end` | 本地函数 | 写在脚本最后；变量只在函数里有效 |
| `daq`、`addinput`、`addoutput`、`readwrite` | NI 采集卡 | 建对象 → 加通道 → 一次输出整张表 |
| `onCleanup`、`try ... catch ... end` | 出错保护 | 不管怎样结束都执行清理（释放 ATS buffer） |
| `uint16` / `double`、`reshape`、`raw(:, :, iy)` | 数据类型、多维数组 | ATS 给的是 0–65535 的整数码，要先变成 double 才能算电压 |
| `save`、`load`、`matfile` | 存取数据 | 存的是变量，读回来名字不变 |

## 3 今天就要会的两件事（Rui 10/15）
**3.1 画一条 A-line**（跑完 `bscan_test` 后工作区里有 `bscan`）
```matlab
size(bscan.volts)                 % 1024 x 400：行 = 时间点，列 = 第几条 A-line
k = 1;                            % 看第 1 条
figure; plot(bscan.t_us, bscan.volts(:, k));
xlabel('Time after trigger (\mus)'); ylabel('Voltage (V)');
title(sprintf('A-line %d', k)); grid on
```
- `plot` 什么都不给 → 报 "Not enough input arguments"：它不知道画什么。
- `plot(bscan.raw_u16)` 一下子画了 400 条：给 plot 一个矩阵，它把**每一列**各画一条线，而且纵轴是原始码（0–65535），横轴是点的序号。
- 读存好的文件：`load('...\bscan_20261007_005104.mat')` 之后工作区里就有 `bscan`，同样画。

**3.2 原始码 → 电压**（bscan_test.m 第 176 行）
```matlab
bscan.volts = (double(raw) / 65535 * 2 - 1) * ATS.inputRange_V;
```
记成四步「转、比、移、乘」：
| 步 | 写法 | 范围 | 例：raw = 40960 |
|---|---|---|---|
| 转成小数能算的类型 | `double(raw)` | 0 … 65535 | 40960 |
| 占满量程的比例 | `/ 65535` | 0 … 1 | 0.625 |
| 移到以 0 为中心 | `* 2 - 1` | −1 … +1 | 0.25 |
| 乘量程 | `* ATS.inputRange_V`（±4 V） | −4 … +4 V | **1.0 V** |
- 为什么要 `double`：`uint16` 只能存 0–65535 的整数，`/ 65535` 会被取整成 0 或 1。
- 和触发电平是同一个思路：8 位的码 0–255，128 = 0 V，`(code − 128) / 127 × 5 V`；150 → 0.87 V。
- 自测：raw = 32768 是多少伏？（≈ 0 V）raw = 0？（−4 V）量程改成 ±0.4 V 时 raw = 40960 是多少？（0.1 V）

## 4 改触发频率的规则（10/15 碰到 "扫描速度 500.00 mm/s 超过上限"）
- `bscan_test` 的触发是"走 K 步发一次"：**扫描速度 = DX_UM × TRIG_RATE_HZ**，必须 ≤ 4 mm/s（第 37 行）。
- 所以 **TRIG_RATE_HZ ≤ 4000 / DX_UM**：DX = 5 µm → 最多 800 Hz；DX = 4 → 1000 Hz；DX = 2 → 2000 Hz；DX = 0.5（一步一个触发）→ 8000 Hz。
- DX 还必须是 0.5 µm 的整数倍（第 56 行 assert）。
- 500 mm/s = 5 µm × 100 kHz：100 kHz 在这种"每个位置一条 A-line"的写法里做不到（要 0.04 µm 一步，比一步 0.5 µm 还小）。要 100 kHz（LabVIEW 的 Trig Rate、激光重复频率那一类），就要换方案：触发和电机步分开，每个位置采多条再平均，或者连续运动、按时间换算位置。这是要和 Rui 确认的设计问题，不是改一个数能解决的。
- 练习：先在纸上算，再用检查模式（`RUN_HARDWARE = false`）核对打印的「扫描速度、步频、触发」。

## 5 每天安排
| 天 | 内容 | 完成标准 |
|---|---|---|
| 1 | MATLAB Onramp（matlabacademy.mathworks.com，免费，约 2 h）+ 第 1 节三个工具 | 能用 Ctrl+Enter、断点、`size/class/whos` |
| 2 | 第 3 节：画 A-line、电压换算；读一个存好的 bscan 文件画第 1、200、400 条 | 不看文档写出 3.1 的 4 行 |
| 3 | `bscan_test.m` 第 1–3 节（参数、换算、assert）+ 第 4 节的改频率练习 | 改 DX / TRIG 前先算对 K、速度、条数 |
| 4 | 第 4–5 节（时序表、位置检查）；断点停在第 116 行（`do` 已经建好），看 `do(1:100,:)` | 指出 STEP 第一次变 1 和第一个触发在哪一行；不看原文写出 `stepColumn` |
| 5 | 第 6 节和 `runBscan`（daq、ATS、onCleanup） | 能说出 ATS 为什么要在 readwrite 之前 arm |
| 6 | 快速检查段（nEdge、tEdge）+ 存盘；`cscan_test.m` 的主循环 | 能解释 tEdge 的插值那一行 |
| 7 | 从零写读文件、画 A-line 和 MAP 的脚本（不看 `cscan_replot.m`） | 拿给 Rui 看，每一行都能讲 |

## 练习记录
（每天一行：日期｜做了什么｜卡在哪｜明天第一步）
