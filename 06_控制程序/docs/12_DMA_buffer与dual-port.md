# 12 DMA buffer 怎么定，以及 dual-port（导师 10/6 的提示）

导师的提示（用户转述，10/6）：buffer 要"成倍"地用；buffer 的数量和 DMA、电脑的 RAM、采集的数据量有关；还要看一下和 digitizer 有关的 "dual ..."。下面是 10/6 在 SDK 自带文件里查到的内容，以及按我们的参数算出来的数。

## 一、SDK 里的原话要点（ATS-SDK 23.3.0，本机文件）
来源：`C:\AlazarTech\ATS-SDK\23.3.0\Samples_MATLAB\ATS9462\ReadMe.htm`、`...\DualPort\NPT_StreamToMemory\ATS9462_NPT_StreamToMemory.m`（第 179–250 行）、`Include\AlazarDefs.m`

| 要点 | 内容 |
|---|---|
| **dual-port AutoDMA** | ATS9462 的 MATLAB 示例全部在 `DualPort` 文件夹里，我们的 A-line、多条采集也是照它写的。意思是：板卡一边把采样写进**板载内存**，一边用 DMA 把板载内存里的数据搬到电脑内存的 buffer 里。板载内存起到"中间水箱"的作用 |
| 什么时候用 AutoDMA | ① 平均数据率低于 PCIe 上限（ATS9462 是 PCIe Gen1 ×8，最高约 1.6 GB/s）；② 不能漏掉传数据或重新 arm 时来的触发；③ 一次要采的点数或记录数超过板载内存能装的量。SDK 写明扫描类应用（超声、OCT 等）应该用 AutoDMA |
| **每个 DMA buffer 的字节数必须是 4096 的倍数** | 因为 DMA buffer 要按内存页（4096 字节）对齐。这很可能就是导师说的"成倍" |
| 每个 buffer 装几条 | 要让"每秒装满的 buffer 数"（触发频率 ÷ 每个 buffer 的记录数）**低于 2 kHz**，否则操作系统可能漏掉"buffer 装满"的中断 |
| buffer 不能太大 | 太大会因为操作系统给不出内存而报 `ApiInsufficient...`；非常大的 buffer 要用 `*_VLB` 示例的写法。非流式 AutoDMA 里，一条记录的长度受 DMA buffer 最大值限制（通常 64 MB） |
| 同时交给板卡几个 buffer | 示例默认 `postedBufferCount = 4`，注释说这个默认值对所有应用都够用 |
| stream to memory 写法 | 一次申请一块能装下**整个采集**的大内存（受电脑 RAM 限制），切成小段，按顺序轮流交给板卡 |
| 其他带 dual 的名词 | `ADMA_DUAL_BUFFER_MODE`（ADMA 标志）、`OPTION_DUAL_PORT_MEMORY`、`OPTION_DUAL_EDGE_SAMPLING`（板卡选项）、dual-channel（CH A + CH B 一起采）。导师指的是哪一个，**待确认**，最可能是 dual-port |

## 二、我们系统的数
- 板载内存：`AlazarGetChannelInfo` 报告 **67,108,864 个采样点（64 M）**（10/3 的文件 `aline_20261003_180050_544.mat` 里存的 `memorySize_samples`）。是每个通道 64 M，还是两个通道合计，**待确认**（查 ATS9462 用户手册）
- 一条记录：1024 点 × 2 字节 = **2048 字节**（只采 CH A）；CH A + CH B 一起采 = 4096 字节
- 电脑内存：64 GB（01）

| 场景 | 记录数 | 数据量（只采 CH A） | 板载内存装得下吗 | 电脑 RAM |
|---|---|---|---|---|
| B-scan：2 mm、5 µm 一条 | 400 | 0.8 MB（41 万个点，板载内存的 0.6%） | 装得下 | 没问题 |
| C-scan：400 × 400 | 160,000 | 328 MB（1.64 亿个点） | **装不下**（是 64 M 点的约 2.4 倍） | 没问题 |

| 检查项 | 计算 |
|---|---|
| 4096 的倍数 | 只采 CH A 时，每条 2048 字节，所以**每个 buffer 的记录数要取偶数**。`bscan_test.m` 现在 512 点 × 50 条 × 2 字节 = 51,200 字节 = 12.5 × 4096，**不是整数倍**；改成 1024 点后是 102,400 = 25 × 4096 ✔。`ats9462_multi_aline.m`：10 条 × 2048 = 20,480 = 5 × 4096 ✔。`revised.m` 单条 2048 字节不是整数倍，但它是单独申请的 buffer，10/3、10/4 都能正常采，这条规定对它是否必要，**待确认** |
| 每秒 buffer 数 < 2 kHz | B-scan 800 Hz ÷ 50 条 = 16 个/秒 ✔；10/4 的 1.4 ⑤：100 kHz ÷ 100 条 = 1 kHz ✔ |
| 数据率 < PCIe 上限 | 800 Hz × 2 KB = 1.6 MB/s；100 kHz × 2 KB = 205 MB/s；都远低于 1.6 GB/s ✔ |

## 三、对 B-scan / C-scan 设计的影响
- **B-scan：** `readwrite` 输出时序时 MATLAB 是卡住的，没法中途交还 buffer。但板载内存（dual-port）会先接住这段时间的数据，B-scan 只有 41 万个点，远小于 64 M。所以"所有 buffer 预先提交"和"4 个轮流"两种写法**都应该能用**（之前担心 4 个轮流会出问题，看了 SDK 后要修正这个说法；**待实测**：用 4 个轮流跑一次 B-scan，看会不会报 `ApiBufferOverflow`）。
- **C-scan：** 整个扫描的数据装得进电脑 RAM，但装不进板载内存。所以扫描过程中必须有人把数据取走：要么每行单独 arm、在回程时把这一行取完（Control_py 是每行重新 arm），要么改成后台输出时序（`start`/`preload`），让 MATLAB 在扫描时继续取 buffer。第 3 周再定。
- **如果以后加采 CH B（光电二极管）：** 数据量翻倍，buffer 里两个通道的数据怎么排列，要查 SDK 手册的 buffer 格式（**待确认**）。

## 四、待确认
1. 导师说的 "dual" 是 dual-port、dual-channel，还是别的（问导师）
2. 64 M 点是每个通道还是合计（ATS9462 用户手册）
3. 4096 的倍数对单独申请的 buffer 是否必须（SDK 手册 `AlazarAllocBuffer`、`AlazarPostAsyncBuffer` 两节）
4. B-scan 用 4 个轮流的 buffer 实测会不会溢出
