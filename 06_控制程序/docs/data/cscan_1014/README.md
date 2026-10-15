# C-scan 关键数据（2026-10-14，测试信号，激光关）

从 LabPC 的 `07_MATLAB/cscan_data/`（不进 git）挑出来的 10 个文件，共约 3 MB，Mac 上也能看。
重画：MATLAB 里先设 `REPLOT_FILE = '<这个文件夹>/cscan_20261014_xxxxxx.mat'`，再运行 `07_MATLAB/cscan_replot.m`。
文件里的变量 = `cscan_test.m` 的 `cscan` 结构：`raw_u16`（1024 × NX × NY）、`x_um`、`y_um`、`MAP`、`nEdge`、`tEdge`、`trigCount`、`timing`、`params`、`rowsDone`、`stopReason`、`errorMessage` 等。

| 文件 | 测试 | 参数 | 结果 |
|---|---|---|---|
| `cscan_20261014_175112.mat` | 5.1 第一次 10 × 10 | Δ 10 µm、400 Hz | 100/100、ctr1 100、MAP 1.041–1.048 V |
| `cscan_20261014_205841.mat` | 6.5 行顺序 | 第 3 行时关发生器 CH2 | 第 3 行 0/10 个沿、MAP 约 3 mV；其余 90/100 |
| `cscan_20261014_210705.mat` | 6.6 停止按钮 | 第 4 行时点停止 | rowsDone 4、ctr1 40、`stopReason = "停止按钮"` |
| `cscan_20261014_210855.mat` | 6.7 拔触发线 | 第 4 行前拔 G1 三通 | 第 4 行 buffer 1/5 超时；前 3 行已存；`errorMessage` 有记录 |
| `cscan_20261014_212504.mat` | 6.9 换参数 | 20 × 5、Δx 5 µm、Δy 20 µm、800 Hz | 100/100、ctr1 100 |
| `cscan_20261014_213044.mat` | 6.11 小规模 ring buffer | NX 20、rpb 2、postedBuffers = 5（每行 10 个 buffer 轮流用 5 个） | 60/60、ctr1 60、无 ApiBufferOverflow |
| `cscan_20261014_213400.mat`、`212934`、`213432`、`213548` | 6.10 计时 | NY 3；NX = 10 / 20 / 50 / 200（200 时 rpb 10） | 斜率 7.40 ms/像素、截距 1.13 s（计划 7.50 ms、0.61 s） |

6.2（Δ 200 µm、2 mm × 2 mm）那次 SAVE_DATA 关着，没有文件，只有截图 `screenshots/MATLAB_1014_cscan_6.2_2mm.png`。
