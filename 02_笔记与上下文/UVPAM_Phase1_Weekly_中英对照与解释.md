# UV-PAM Phase 1 每周里程碑 —— 中英逐句对照 + 中文解释 + 进度对照

> **整理日期**：2026-10-13（周二，按原计划属于 Week 6）
> **原件**：Rui 给的 *UV-PAM Phase 1 — Weekly Milestones*；英文原件同目录 `UVPAM_Phase1_Weekly_Integrated_MATLAB_EN.md`（本文件不改动原件）。
> **结构**：第一部分 逐句对照（英文原文 → 中文直译）；第二部分 每周要做什么（中文解释）+ 你现在做到哪；第三部分 原文里几处要和 Rui 对齐的地方；第四部分 术语表。
> **进度依据**：`06_控制程序/docs/工作日志.md`（最新到 10/11）、docs/10、docs/13、`01_硬件与接线.md`、master §1.2 / §16 / §19。master §19 还停在 9/23，本文件**没有**改 master。
> **进度标记**：✅ 有记录证明已完成 · 🟡 部分完成 · ⬜ 未开始 · ❓ 仓库里没有记录（不等于没做，需要你确认）
> **证据标签**沿用 master §0：[文件确认] [实测] [历史解释] [导师要求] [条件计算] [待确认]

---

## 第一部分 逐句对照

### 标题与总则

> **UV-PAM Phase 1 — Weekly Milestones**
> UV-PAM 第一阶段 —— 每周里程碑

> Week 1 starts 2026-09-07.
> 第 1 周从 2026-09-07 开始。

> One experimental goal per week.
> 每周一个实验目标。

> A week is done when its Done when condition is demonstrated and recorded.
> 当某一周「完成标准（Done when）」里的条件被演示出来并记录下来时，这一周才算完成。

> MATLAB development starts from scratch and supports the experiments listed below.
> MATLAB 开发从零开始，并为下面列出的实验服务。

### Before Week 1 / 第 1 周之前

> Complete laser safety training and the SOP; check goggles for 266 nm and the independent laser interlocks, emergency stop and mechanical limits before the relevant powered work.
> 完成激光安全培训和 SOP（标准操作规程）；在进行相关的通电工作之前，检查适用于 266 nm 的护目镜，以及独立的激光联锁、急停和机械限位。

> Contact the histology core now.
> 现在就联系组织学核心实验室（histology core）。

> Confirm sectioning onto our own 1.00 mm quartz slides, deparaffinization, and H&E staining of the same section after imaging.
> 确认以下几件事：把切片切到我们自己的 1.00 mm 石英载玻片上；脱蜡；以及在成像之后对同一张切片做 H&E 染色。

> Open the billing account and arrange a pilot slide before Week 9.
> 开通计费账户，并在第 9 周之前安排一张试验（pilot）切片。

### 表头

| Week | Dates (2026) | Experimental milestone | Done when | MATLAB work needed for this experiment |
|---|---|---|---|---|
| 周 | 日期（2026） | 实验里程碑 | 完成标准 | 本实验需要的 MATLAB 工作 |

---

### Week 1 · 09-07–09-11

**Milestone / 里程碑**
> Motors move correctly
> 电机运动正确

**Done when / 完成标准**
> Both axes home/reference, make nominal 1 µm moves, and complete a 3 mm × 3 mm raster from software.
> 两个轴都能回原点/找参考位置（home/reference），能做名义 1 µm 的移动，并能由软件完成一次 3 mm × 3 mm 的光栅扫描（raster）。

> Measured travel and return-position repeatability meet the agreed tolerance.
> 实测的行程和回位重复性满足商定的容差。

**MATLAB work / MATLAB 工作**
> Build basic motion control: device/wiring configuration, home/reference, jog, distance-to-step conversion, hardware-counter STEP output, raster commands and Stop/limit cleanup.
> 搭建基本运动控制：设备/接线配置、回原点/参考、点动（jog）、距离到步数的换算、由硬件计数器（counter）输出 STEP、光栅扫描命令，以及停止/限位时的清理（cleanup）。

> Test the commands with mock hardware before bench use.
> 在上台架使用之前，先用模拟硬件（mock hardware）测试这些命令。

---

### Week 2 · 09-14–09-18

**Milestone / 里程碑**
> Optics and transducer aligned; first A-line on the scope
> 光路和换能器对准；示波器上出现第一条 A-line

**Done when / 完成标准**
> Optical and acoustic focus overlap; the signal is peaked in X, Y and Z.
> 光学焦点与声学焦点重合；信号在 X、Y、Z 三个方向上都调到峰值。

> Black tape gives a repeatable bipolar signal, and a known axial displacement produces the expected one-way acoustic delay.
> 黑胶带能给出可重复的双极性（bipolar）信号，并且一个已知的轴向位移会产生预期的单程声学延迟。

**MATLAB work / MATLAB 工作**
> Add convenient small-step positioning for alignment and save position/settings.
> 为对准加入方便的小步距定位功能，并保存位置/设置。

> Prepare the PD-triggered digitizer interface and NI PD-count/PRF readout for Week 3; neither is required to see the first A-line on the scope.
> 为第 3 周准备由 PD（光电二极管）触发的数字化仪接口，以及 NI 的 PD 计数 / PRF（脉冲重复频率）读出；这两者都不是在示波器上看到第一条 A-line 的必要条件。

---

### Week 3 · 09-21–09-25

**Milestone / 里程碑**
> DAQ working; A-lines saved and reconstructed
> 采集（DAQ）工作正常；A-line 能保存并重建

**Done when / 完成标准**
> With the stage stationary, PD-triggered acquisition works at 100-200 kHz in the selected batch-record mode with no unexplained missing records or overflow.
> 在平台静止的情况下，PD 触发的采集能在所选的批量记录（batch-record）模式下以 100–200 kHz 工作，且没有无法解释的丢记录或溢出（overflow）。

> Saved raw data can be reopened to reproduce the A-line and envelope; each processing step can be explained.
> 保存的原始数据可以重新打开，复现出 A-line 及其包络（envelope）；每一个处理步骤都能解释清楚。

**MATLAB work / MATLAB 工作**
> Build batch DMA acquisition, timeout/abort handling, raw-data and metadata storage, and a reader.
> 搭建批量 DMA 采集、超时/中止处理、原始数据与元数据（metadata）的存储，以及一个读取程序（reader）。

> Write basic ADC conversion, baseline removal, filtering, averaging and envelope scripts.
> 编写基本的 ADC 换算、基线去除、滤波、平均和包络脚本。

> Test missing-trigger/incomplete-data behavior.
> 测试缺失触发 / 数据不完整时的行为。

---

### Week 4 · 09-28–10-02

**Milestone / 里程碑**
> First 2D image
> 第一张二维图像

**Done when / 完成标准**
> A 7 µm carbon fiber or hair phantom appears as one continuous line in a small raster image, with no unexplained missing rows.
> 一根 7 µm 碳纤维或头发仿体（phantom）在一张小范围光栅图像里显示为一条连续的线，且没有无法解释的缺行。

> The image can be regenerated from saved raw data.
> 这张图像能从保存的原始数据重新生成。

**MATLAB work / MATLAB 工作**
> Combine motion and acquisition into a move–settle–acquire loop with pixel coordinates, raw-data commit, Stop and progress display.
> 把运动和采集合并成一个「移动–稳定–采集」（move–settle–acquire）循环，带像素坐标、原始数据提交（写入磁盘）、停止和进度显示。

> Build basic B-scan/MAP reconstruction.
> 搭建基本的 B-scan / MAP（最大幅度投影）重建。

> Measure the complete pixel cycle and estimate full-field scan time.
> 测量一个完整的像素周期，并估算全视场扫描时间。

---

### Week 5 · 10-05–10-09

**Milestone / 里程碑**
> Scan geometry correct
> 扫描几何正确

**Done when / 完成标准**
> A ruled target measures the correct size in X and Y; row alignment and return positioning meet agreed tolerances.
> 一个刻线靶标（ruled target）在 X 和 Y 方向测出正确的尺寸；行对齐和回位定位满足商定的容差。

> No unexplained zipper artifact remains.
> 不残留无法解释的拉链状伪影（zipper artifact）。

> Use single-direction rows with flyback for the baseline.
> 基准方案采用单向逐行扫描加快速回程（flyback）。

**MATLAB work / MATLAB 工作**
> Add coordinate/scale calibration, verify pixel order and integer-step mapping, and save calibration settings.
> 加入坐标/比例标定，验证像素顺序和整数步映射，并保存标定设置。

> Add pixel-boundary Pause and test interruption handling.
> 加入在像素边界处暂停（Pause）的功能，并测试中断处理。

> If bidirectional scanning is later introduced, measure backlash and verify its coordinate mapping first.
> 如果以后引入双向扫描，要先测量回差（backlash）并验证其坐标映射。

---

### Week 6 · 10-12–10-16（本周）

**Milestone / 里程碑**
> Resolution measured
> 测量分辨率

**Done when / 完成标准**
> Edge measurements on a chrome-on-quartz target give a reproducible lateral line-spread FWHM in both X and Y, using sufficiently fine sampling.
> 在石英基底镀铬（chrome-on-quartz）靶标上做边缘测量，在足够精细的采样下，X 和 Y 两个方向都得到可重复的横向线扩展（line-spread）FWHM（半高全宽）。

**MATLAB work / MATLAB 工作**
> Write edge-profile extraction, edge-to-line-spread analysis and FWHM reporting.
> 编写边缘剖面提取、由边缘到线扩展的分析，以及 FWHM 报告。

> Save raw profiles, physical axes and processing settings; check the analysis with known synthetic profiles.
> 保存原始剖面、物理坐标轴和处理设置；用已知的合成剖面检验这套分析。

---

### Week 7 · 10-19–10-23

**Milestone / 里程碑**
> Resolution optimized to approximately 1 µm
> 分辨率优化到约 1 µm

**Done when / 完成标准**
> The final UV objective, NA and beam fill are set; focus and sample tilt are optimized.
> 最终的 UV 物镜、NA 和光束填充（beam fill）确定下来；焦点和样品倾斜已优化。

> Measured X/Y FWHM reaches the agreed approximately 1 µm range, supported by repeat measurements and two independent methods.
> 实测 X/Y FWHM 达到商定的约 1 µm 范围，并有重复测量和两种独立方法支持。

**MATLAB work / MATLAB 工作**
> Make repeated small-ROI scans and comparison plots easy to run.
> 让重复的小 ROI（感兴趣区）扫描和对比图便于运行。

> Record objective, sampling, focus position and processing settings with each measurement so the best result can be reproduced.
> 每次测量都记录物镜、采样、焦点位置和处理设置，以便能复现最好的结果。

---

### Week 8 · 10-26–10-30

**Milestone / 里程碑**
> Field quality checked
> 检查视场质量

**Done when / 完成标准**
> Uniformity, flatness and focus remain within agreed tolerances across the full 3 mm × 3 mm field.
> 在整个 3 mm × 3 mm 视场内，均匀性、平整度和聚焦都保持在商定的容差之内。

> The pilot quartz-slide workflow is ready for tissue imaging.
> 试验用石英载玻片的工作流程已为组织成像准备就绪。

**MATLAB work / MATLAB 工作**
> Add multi-position/ROI measurements and field-quality maps.
> 加入多位置 / ROI 测量和视场质量分布图。

> Check full-field data size, disk space and memory use; implement chunked reading/reconstruction if required before processing the full field.
> 检查全视场的数据量、磁盘空间和内存占用；如有需要，在处理全视场之前实现分块读取/重建。

---

### Week 9 · 11-02–11-06

**Milestone / 里程碑**
> First tissue image
> 第一张组织图像

**Done when / 完成标准**
> An unstained fixed section on a quartz slide produces an image with individually distinguishable nuclear features.
> 石英载玻片上一张未染色的固定切片，成像后能分辨出单个的细胞核特征。

> Save the section orientation and ROI landmarks for later H&E comparison.
> 保存切片方向和 ROI 标志点，供之后与 H&E 对比。

**MATLAB work / MATLAB 工作**
> Add sample IDs, repeatable acquisition presets and physically scaled image export.
> 加入样品编号、可重复使用的采集预设，以及带物理比例尺的图像导出。

> Provide a simple setup/start/stop/status interface, using scripts or a minimal GUI.
> 提供一个简单的设置/开始/停止/状态界面，用脚本或最简 GUI 都可以。

> Save raw data, acquisition settings and exposure information for every scan.
> 每次扫描都保存原始数据、采集设置和曝光信息。

---

### Week 10 · 11-09–11-13

**Milestone / 里程碑**
> Throughput usable
> 通量（扫描速度）可用

**Done when / 完成标准**
> A 3 mm × 3 mm field is scanned in under 30 minutes at stated pixel pitch, shots/pixel and image-quality settings.
> 在注明的像素间距、每像素发数（shots/pixel）和图像质量设置下，3 mm × 3 mm 视场能在 30 分钟以内扫完。

> Five slides can be exchanged without optical/acoustic realignment; record refocusing and handling time separately.
> 能更换五张载玻片而不需要重新对准光学/声学；重新对焦和操作的时间分开记录。

**MATLAB work / MATLAB 工作**
> Profile motion, settling, acquisition, writing and display.
> 对运动、稳定、采集、写入和显示分别做耗时分析（profile）。

> Optimize measured bottlenecks and recheck data integrity.
> 优化测出来的瓶颈，并重新检查数据完整性。

> Add clear remaining-time estimates and reusable slide-scan presets.
> 加入清楚的剩余时间估计和可重复使用的载玻片扫描预设。

---

### Week 11 · 11-16–11-20

**Milestone / 里程碑**
> H&E comparison
> H&E 对比

**Done when / 完成标准**
> The same section is stained after imaging; corresponding ROIs are aligned side by side and matching nuclear features are checked.
> 同一张切片在成像后染色；把对应的 ROI 并排对齐，并核对相互匹配的细胞核特征。

> Record registration quality.
> 记录配准（registration）质量。

**MATLAB work / MATLAB 工作**
> Build an offline paired-image workflow: load H&E, select landmarks, register images, and export paired/overlay views with saved transformation settings.
> 搭建一个离线的配对图像流程：载入 H&E、选择标志点、配准图像，并导出配对/叠加视图，同时保存变换设置。

---

### Week 12–14 · 11-23–12-11

**Milestone / 里程碑**
> Buffer and repeatability
> 缓冲期与可重复性

**Done when / 完成标准**
> Finish delayed experiments and repeat the tissue-to-H&E dataset on another section/session so the result is not a one-off.
> 完成被推迟的实验，并在另一张切片 / 另一次实验中重复「组织—H&E」数据集，使结果不是一次性的。

**MATLAB work / MATLAB 工作**
> Fix problems exposed by use.
> 修复使用中暴露的问题。

> Test Stop, trigger loss, overflow and write failure; verify saved-data reopening.
> 测试停止、触发丢失、溢出和写入失败；验证保存的数据能重新打开。

> Add retry/checkpoint recovery if needed for repeat runs, retaining failed attempts and requiring position verification before resuming.
> 如果重复运行需要，加入重试 / 断点（checkpoint）恢复，保留失败的尝试，并在恢复前要求核实位置。

---

### Week 15 · 12-14–12-18

**Milestone / 里程碑**
> Wrap up before the holiday
> 假期前收尾

**Done when / 完成标准**
> Acceptance experiments are complete, measured results are recorded, the report is signed, and data/code are archived and can be reopened.
> 验收实验完成，测量结果已记录，报告已签字，数据/代码已归档并且可以重新打开。

> Record unmet targets explicitly.
> 明确记录未达成的目标。

**MATLAB work / MATLAB 工作**
> Package the MATLAB program, configuration templates, operating instructions, mock tests and explicitly enabled hardware checks.
> 打包 MATLAB 程序、配置模板、操作说明、mock 测试，以及需要显式启用的硬件检查。

> Verify that archived raw data reproduce the reported images and measurements.
> 验证归档的原始数据能复现报告中的图像和测量结果。

---

### Notes / 注意事项

**1.**
> **Week 2 is a scope experiment.**
> **第 2 周是示波器实验。**

> Do not delay optical/acoustic alignment while waiting for the MATLAB acquisition program.
> 不要为了等 MATLAB 采集程序而推迟光学/声学对准。

> For a 500 µm increase in acoustic path and an assumed sound speed of 1,480 m/s, the expected delay is approximately 338 ns; use the actual geometry and measurement uncertainty.
> 声程增加 500 µm、假设声速为 1,480 m/s 时，预期延迟约为 338 ns；要使用实际几何和测量不确定度。

**2.**
> **MATLAB supports the experiment.**
> **MATLAB 为实验服务。**

> Build only the functions needed for the current and next experimental step.
> 只编写当前和下一个实验步骤需要的功能。

> Start with scripts and a small control interface; GUI polish does not determine whether an experimental milestone passes.
> 先用脚本和一个小的控制界面；GUI 做得是否精美，不决定实验里程碑是否通过。

> Each new function needs mock-based `matlab.unittest` coverage; hardware tests are explicitly enabled.
> 每个新函数都需要基于 mock 的 `matlab.unittest` 测试覆盖；硬件测试要显式启用。

**3.**
> **Use hardware timing.**
> **使用硬件定时。**

> The free-running laser is referenced by conditioned PD pulses.
> 自由运行（free-running）的激光，以经过调理（conditioned）的 PD 脉冲作为时间参考。

> NI counters generate STEP and count PD; the digitizer acquires records in batches.
> 由 NI 计数器生成 STEP 并对 PD 计数；数字化仪按批次采集记录。

> MATLAB loops, timers and UI callbacks must not provide pulse synchronization.
> 不得用 MATLAB 循环、定时器和界面回调来提供脉冲同步。

> The initial scan is step-and-settle; continuous motion needs a separate validated pulse-to-position scheme.
> 初始扫描采用「步进–稳定」（step-and-settle）；连续运动需要另一套经过验证的「脉冲—位置」对应方案。

**4.**
> **Keep the raw evidence.**
> **保留原始证据。**

> Save raw data, coordinates, settings and acquisition status before generating images.
> 在生成图像之前，先保存原始数据、坐标、设置和采集状态。

> Do not silently fill missing data.
> 不要悄悄填补缺失的数据。

> Stop STEP output first on faults, then abort acquisition and preserve available data.
> 出故障时先停止 STEP 输出，再中止采集，并保留已有的数据。

> Software does not replace independent safety layers.
> 软件不能取代独立的安全层。

**5.**
> **Check speed early, in Week 4.**
> **尽早检查速度，在第 4 周。**

> At 1 µm pitch, a 3 mm × 3 mm field contains approximately one million pixels: the 30-minute target allows less than 1.8 ms per pixel once frame overhead is included.
> 在 1 µm 间距下，3 mm × 3 mm 视场约有一百万个像素：算上帧开销后，30 分钟的目标允许每个像素少于 1.8 ms。
> *（译注：这句的像素数和第三部分 ① 的复算对不上，见下文。）*

> At 0.5 µm pitch, it allows less than 0.45 ms.
> 在 0.5 µm 间距下，允许少于 0.45 ms。

> Pixel pitch and measured optical resolution are separate quantities.
> 像素间距和实测光学分辨率是两个不同的量。

> If the measured budget fails, record the required change in field, time or architecture before Week 10.
> 如果实测的时间预算不达标，要在第 10 周之前记录需要在视场、时间或架构上做的改变。

**6.**
> **Qualify the chosen PRF.**
> **对所选的 PRF 做合格验证。**

> Start at 100 or 200 kHz; higher rates up to 2 MHz require separate checks of trigger timing, record window, acoustic overlap and throughput.
> 从 100 或 200 kHz 开始；更高的频率（最高 2 MHz）需要另外检查触发时序、记录窗口、声学重叠和吞吐量。

> Count illumination during motion/settling/idle time when assessing exposure; disabling acquisition does not stop the laser.
> 评估曝光时，要把运动 / 稳定 / 空闲时间里的照射也算进去；关闭采集并不会让激光停下。

**7.**
> **Protect the three buffer weeks.**
> **保护好三个缓冲周。**

> First light, hardware integration and tissue preparation may slip.
> 首次出光、硬件集成和组织准备都可能延误。

> If a Friday acceptance condition is unmet, record the blocker and finish it before starting dependent experiments; independent preparation can continue.
> 如果某个周五的验收条件没有达到，要记录卡点，并在开始依赖它的实验之前把它完成；不依赖它的准备工作可以继续。

---

## 第二部分 每周要做什么 + 你现在做到哪

### 先看全局（截至 10/13）

| 原计划周 | 里程碑 | 你的状态 | 一句话 |
|---|---|---|---|
| 第 1 周前 | 安全培训 + 组织学 | 🟡 | 组织学已联系、收到回复；pilot 没定；安全培训仓库里无记录 ❓ |
| W1 | 电机运动正确 | 🟡 | X 轴标定、方向、速度上限做了；Y 轴、home、1 µm 小步、3×3 mm raster 没做 |
| W2 | 光路+换能器对准，示波器见 A-line | ⬜ | **还没有真实光声信号**——这是目前最大的缺口 |
| W3 | 采集正常，A-line 保存重建 | 🟡 | 用函数发生器做完了采集卡全套测试；PD 触发只验证过能触发；包络/滤波脚本无记录 |
| W4 | 第一张 2D 图 | 🟡 | B-scan 用**测试信号**跑通 400/400；还没有仿体图像、没有 C-scan |
| W5–W6 | 扫描几何 / 分辨率 | ⬜ | 依赖 W2 的真实信号和 W4 的图像 |
| W7–W15 | — | 未到期 | — |

**怎么理解这个差距**：原计划默认第 2 周就有真实光声信号，后面 W4–W11 全部建立在「能成像」之上。你现在的工作量主要花在 W1、W3、W4 的**电子学与时序部分**（这部分做得比较扎实、有数据），但 W2 的光学/声学部分一直没推进，所以按原计划日历看落后约 2–3 周。另外你 10/4 自己写的四周计划（`06_控制程序/docs/07_给导师的四周计划.md`，10/5–11/1：电机 → B-scan → C-scan → 真实信号）是另一套时间线，Rui 有没有认可它，仓库里没有记录。

---

### 第 1 周之前：安全 + 组织学

**要做什么**：(1) 动激光、电机之前先拿到安全资格：激光安全培训、读 SOP，确认 266 nm 护目镜、激光联锁、急停、机械限位都在。(2) 组织学最费时间、又不受你控制，所以要最早联系：确认切片能放在我们 1 mm 厚的石英片上、能脱蜡、成像后能对同一片做 H&E；开账户；第 9 周前做一张试验片。

**你现在到哪**
- 组织学 🟡：Jenifer 已回复 [文件确认，master §16]——没用过石英片、46 °C 水浴、xylene/ethanol 脱蜡、H&E 架子只适配 1 in × 3 in × 1 mm、走 iLab 计费。
- ⚠ **Jenifer 十月底退休**，她要 Week 9 的具体日期。今天 10/13，离月底只剩约 2.5 周。pilot 没定、billing 没开 ⬜。这是全表里**时间最紧**的一项。
- 激光安全培训 / SOP ❓：仓库里没找到记录。做过的话补一行记录即可。
- 机械限位 ⬜：滑台 DB9 里疑似限位的线悬空没接 [实测，01_硬件与接线]。

---

### Week 1：电机运动正确

**要做什么**：让 X、Y 两个轴「听话」。具体是：
- **home/reference**：每次开机能回到一个已知的物理零点（不是软件把数字清零）。
- **名义 1 µm 移动**：按你的标定 0.5 µm/脉冲，1 µm = 2 个 STEP；要实测这个小步真的走了。
- **3 mm × 3 mm raster**：软件一键完成一整面（X 来回、Y 逐行）。
- **行程与回位重复性**：走出去再回来，偏差在「商定容差」以内。
- MATLAB 侧：把接线写成配置、写 home/jog/距离换算/raster/停止清理；**STEP 由 NI 硬件计数器产生**；先用 mock（假硬件）测试命令逻辑，再上台架。

**为什么**：后面每一张图的坐标都来自电机。电机不准，图就是歪的、拉伸的。

**你现在到哪**
- ✅ X 轴：每转 4000 步，**0.5 µm/脉冲**（20000 脉冲 ≈ 10 mm）；方向确认；不加速 ≤ 4.8 mm/s 正常，**5 mm/s 起步失步** [实测 10/4]。
- ✅ X 往返：`RETURN_TO_START = false` 跑 3 次每次约 2.4 mm，往返回到原位 [实测 10/7，卡尺粗测]。
- 🟡 SR2 拨码：X 驱动器读到 SW1–3 = 0.3 A（电机额定 1.7 A，可能是 5 mm/s 失步的原因，没改）[实测 10/4]；Y、Z 驱动器没读。
- ⬜ Y 轴标定：没做。
- ⬜ home/reference：限位没接，目前靠「SR2 断电 → 手轮摇到一端 → 回摇 13.5 圈到中间」人工归零。
- ⬜ 1 µm 小步实测、3 × 3 mm raster、正式的重复性数据（容差也没商定）。
- MATLAB：🟡 `test2.m` 能动电机；STEP 目前用 DO（借 AI 时钟硬件定时）输出，**不是原计划要求的 counter STEP**；⬜ 没有 mock 单元测试。

**还缺的最小一步**：Y 轴按 X 的方法标一次；限位线问清 Maria/Rui 能不能接。

---

### Week 2：光路与换能器对准，示波器上看到第一条 A-line

**要做什么**：在示波器上（不用 MATLAB）看到真实的光声信号：
- 让激光焦点和超声换能器的声学焦点落在同一点；在 X、Y、Z 三个方向分别微调，找到信号最大的位置。
- 用黑胶带（强吸收体）做样品，看到一个先正后负（或先负后正）的**双极性**脉冲，而且每次都一样。
- 把样品沿轴向移一个已知距离，信号到达时间的变化要符合声速：Δt = Δz / c，**单程，不除 2**（光是瞬时到达的，只有声音要走）。例：500 µm / 1480 m/s ≈ 338 ns [条件计算，已复算]。
- MATLAB 侧只需方便小步挪位置、存位置；PD 触发采集和 PRF 计数是为第 3 周提前准备的，不是本周必需。

**为什么**：这一步证明你采到的是「光被吸收产生的声音」，而不是电噪声或触发串扰。没有它，后面所有图像都没有意义。

**你现在到哪**
- ⬜ 还没有真实光声信号。9/28 会上 Rui 说过：放进水里不等于有信号，还需要对准 [导师要求]。
- ⬜ 黑胶带、焦点重合、声延迟验证都没做。早期 CH4 有/无激光对照里放大器状态没控制，不能算 PA [历史解释，master §12]。
- 参考：Maria 10/8 版的数据里也没有 PA 信号 [实测，Mac 10/11 分析]。
- 🟡 为 W3 准备的部分：PD 触发 ATS 已成功、挡光则超时 [实测 10/4]；ctr1 在 PFI3 上能计数 P0.6 上升沿 200/200、400/400 [实测 10/7、10/9]——计的是触发线，还不是 PD。
- ⚠ 现在台架上是 NPL45C 450 nm，不是 266 nm UV。用它能不能先做黑胶带实验，要问 Rui（见第三部分）。

**还缺的最小一步**：请 Rui 或会对准的人现场演示一次对准流程；先固定激光、换能器、放大器状态，按 master §12.4 的顺序做对照。

---

### Week 3：采集正常，A-line 能保存和重建

**要做什么**：
- 平台不动，用 PD（光电二极管看到的真实光脉冲）触发采集卡，在 100–200 kHz 下连续采，选定一种批量记录模式（ATS9462 上通常是 NPT），**一条都不丢、不溢出**；万一丢了，必须能解释原因。
- 存下来的原始数据能重新打开，画出同一条 A-line 和它的包络；每一步处理（ADC 码 → 电压、去基线、滤波、平均、包络）都说得出在干什么。
- MATLAB 侧：批量 DMA 采集、超时/中止处理、数据+元数据存储和读取程序、上述处理脚本；故意制造「缺触发 / 数据不完整」，看程序怎么反应。

**为什么**：这是把「示波器上看到」变成「电脑里存下、可复现」的一步。

**你现在到哪**
- ✅ 采集卡测试 1.1–1.4（函数发生器做信号）[实测 10/3–10/4，docs/10]：无触发约 5 s 报 `ApiWaitTimeout (579)` 可重复；TRIG IN 50 Ω；阈值 code 150 ≈ 0.87 V；触发延迟 2 µs 测得 1.9997 µs；batch DMA 在 **100 kHz 下 1000 条不漏**；只给 95 个触发时报告 90 条并保存（数据不完整的行为已测）。
- ✅ 保存 → 重开 → 复算：`aline_edge_time.m`、`analyze_delay_1003.m` 从 .mat 复算边沿时间 [文件确认]。
- 🟡 PD 触发：能触发 [实测 10/4]，但**没有在 100–200 kHz 下做 PD 触发的连续采集**。而且 NPL45C 最高 50 kHz [文件确认，手册]，用现在的激光做不到原文的 100–200 kHz。
- ⬜/❓ 去基线、滤波、平均、包络脚本：仓库日志里没有记录。

**还缺的最小一步**：在已有采集代码上加一个「读 .mat → 换电压 → 去基线 → 包络」的小脚本（你自己写，用测试信号先验证）；PD 频率问题问 Rui。

---

### Week 4：第一张 2D 图

**要做什么**：
- 把电机和采集合成一个循环：**移动一格 → 等它停稳 → 采集 → 存数据 → 下一格**，每条数据带像素坐标，可以随时停、看进度。
- 扫一根 7 µm 碳纤维或头发，图上应该是一条连续的线，没有莫名其妙缺掉的行；图能从原始数据重新算出来。
- 写最简单的 B-scan / MAP 重建（MAP = 每条 A-line 取最大幅度，拼成平面图）。
- **测一个像素从移动到采完总共花多少时间**，用它估算整个 3 × 3 mm 要扫多久（见 Notes 第 5 条）。

**为什么**：这是系统第一次真正「成像」，也是第一次能看出扫描时间够不够。

**你现在到哪**
- ✅ B-scan（测试信号）：P0.6 → 函数发生器 → TRIG IN / CH A，**400/400 条每条都有测试脉冲**，上升沿标准差约 1.84 ns；拔触发线 → 超时、清理正常 [实测 10/7，docs/13]。之后多次复测 400/400、ctr1 计数一致 [实测 10/7 晚、10/9]。
- ⬜ 仿体（碳纤维/头发）图像：没有——依赖 W2 的真实信号。
- ⬜ C-scan（二维面）：没有。
- ⬜ 像素周期时间和全视场时间估算：没有。设计问题「匀速扫描 vs 移动–停–采集」还没讲完 [docs/13]。
- 🟡 环形 buffer（ring buffer）：方案写在 docs/12 §三点五，还没改进 `bscan_test.m`。

**还缺的最小一步**：按计划做 ring buffer 第 1 步；同时把「一个像素的时间」量出来，这一步不需要真实信号。

---

### Week 5：扫描几何正确

**要做什么**：扫一个有已知刻度的靶标（比如刻线板），图上量出来的 X、Y 尺寸要和真实尺寸一致；每一行要对齐、回到行首的位置要准；不能有「拉链」一样左右错开的伪影。先用最稳的方式：每行同方向扫，扫完快速退回行首（flyback），不要来回双向扫。MATLAB 侧加坐标标定、检查像素顺序、处理「1 µm = 2 个 STEP」这种整数步映射，加「在像素之间暂停」并测试中断。

**为什么**：分辨率、组织图像的尺寸都要靠正确的几何。

**你现在到哪**：⬜ 未开始（依赖 W4 的图像）。相关已知：X 0.5 µm/脉冲，回差、Y 轴未测。

---

### Week 6（本周）：测量分辨率

**要做什么**：用一块石英上镀铬的靶标，扫过一条「明—暗」的锐利边缘。边缘在图上会被系统「抹开」，抹开的曲线叫边缘扩展函数（ESF）；对它求导得到线扩展函数（LSF）；LSF 的半高全宽（FWHM）就是横向分辨率。X、Y 各做，结果要可重复；采样间距要比分辨率细得多（否则量的是像素，不是光斑）。MATLAB 侧写边缘提取 → 求导 → FWHM，并先用自己造的已知宽度的合成数据检验程序算得对不对。

**为什么**：分辨率是论文对比的核心指标（论文横向 1.3 µm [文件确认，master §2]）。头发只能证明有信号、形状对，**证明不了 1 µm 分辨率**。

**你现在到哪**：⬜ 未开始。不需要硬件就能先做的部分：用合成边缘数据写 ESF → LSF → FWHM 的脚本。

---

### Week 7：把分辨率优化到约 1 µm

**要做什么**：选定最终的 UV 物镜、NA，以及光束要把物镜入瞳填多满（beam fill：光束越粗 → 会聚角越大 → NA 越大 → 光斑越小，这就是 9/28 会上 Rui 讲的扩束与 NA）；调焦、调样品倾斜。重复测量并用两种独立方法（例如边缘法 + 小颗粒/细线法）确认 X/Y 都在约 1 µm。每次测量都把物镜、采样、焦点位置、处理参数记下来。

**你现在到哪**：未到期。需要 266 nm 光路。

---

### Week 8：检查视场质量

**要做什么**：在整个 3 × 3 mm 里，不只看中间：各处信号强弱是否均匀、样品面是否平、焦点是否一直对着。把石英载玻片从上样到成像的流程走顺，准备好接组织。MATLAB 侧做多点测量和视场质量图；估算全视场数据有多大、硬盘和内存够不够，不够就分块读、分块重建。

**你现在到哪**：未到期。已知参考：B-scan 400 条装得进板载内存，C-scan 400 × 400 装不进，扫描中必须边采边取 [条件计算，docs/12]。

---

### Week 9：第一张组织图像

**要做什么**：拿一张未染色、已固定的组织切片（在石英片上）成像，要能看出一个个的细胞核（266 nm 主要被 DNA/RNA 吸收，所以核会亮）。记下切片朝向和标志点，方便之后和 H&E 对位置。MATLAB 侧加样品编号、采集预设、带比例尺导出、简单的开始/停止/状态界面；每次扫描都存原始数据、设置和曝光。

**你现在到哪**：未到期。依赖组织学 pilot（见「第 1 周之前」的 Jenifer 退休问题）。

---

### Week 10：速度可用

**要做什么**：3 × 3 mm 在 30 分钟内扫完（写明像素间距、每像素几发、画质设置）；连换 5 张片子不用重新对准，换片和对焦时间单独记。MATLAB 侧量清楚时间都花在哪（移动、稳定、采集、写盘、显示），优化最慢的那一环，并确认优化后数据没丢。

**你现在到哪**：未到期。注意第三部分 ① 的时间预算问题。

---

### Week 11：H&E 对比

**要做什么**：成像后把同一张切片送去 H&E 染色；把 PAM 图和 H&E 图的对应区域并排对齐（配准），核对细胞核是不是一一对上，并记录对得有多准。MATLAB 侧做离线配对流程：读 H&E → 选标志点 → 配准 → 导出并排/叠加图，并保存变换参数。

**你现在到哪**：未到期。

---

### Week 12–14：缓冲期 + 可重复性

**要做什么**：补前面延误的实验；在另一张切片或另一天再做一遍「组织 → H&E」，证明不是偶然。MATLAB 侧补齐异常测试（停止、丢触发、溢出、写盘失败），必要时加断点续扫——续扫前必须核对位置，失败记录也要保留。

### Week 15：假期前收尾

**要做什么**：验收实验做完，结果写进报告并签字；数据和代码归档且能重新打开；没达成的目标明确写出来。MATLAB 程序打包（配置模板、说明、mock 测试、需手动开启的硬件测试），并验证用归档数据能复现报告里的图和数字。

---

### Notes 用中文说清楚

1. **第 2 周只靠示波器**：对准不要等程序。声延迟用实际几何算，并给出测量误差。
2. **MATLAB 是工具**：只写当前和下一步需要的；界面好不好看不算分；每个函数配 mock 测试；真机测试必须手动打开（你现在 `RUN_HARDWARE = false` 默认关，就是这个思路）。
3. **硬件定时**：激光自由跑，用 PD 脉冲当「时钟」；STEP 和 PD 计数都交给 NI 计数器；采集卡按批收数据；**MATLAB 的循环和定时器不能负责对齐脉冲**（软件时间不稳定）。先做「走一步、停稳、再采」；想边走边采，要另外证明每个脉冲对应哪个位置。
4. **保留证据**：先存原始数据再出图；缺的数据不能偷偷补；出故障先停电机 STEP，再停采集，保住已采的数据；软件安全不能代替急停、联锁等硬件安全。
5. **第 4 周就量速度**：见第三部分 ①。像素间距 ≠ 分辨率：间距是你每隔多远采一次，分辨率是光斑本身多大。
6. **PRF 要验证**：先 100 或 200 kHz；往上到 2 MHz 时，要检查触发时序、每条记录的时间窗、前后两发的声波会不会叠在一起、数据吞吐量。算样品受光量时，电机移动、等待、空闲时激光也在照，关了采集不等于关了激光。
7. **缓冲周别提前用掉**：出光、硬件集成、组织准备都可能拖。周五验收没过 → 记下卡点，先解决，再做依赖它的实验；不依赖它的准备可以并行。

---

## 第三部分 原文里要和 Rui 对齐的几处

以下是我核对原文时发现的，**不是 Rui 的说法**，带去会上确认。

① **像素数和时间预算** [条件计算]
- 3 mm ÷ 1 µm = 3000 → 3000 × 3000 ≈ **900 万**像素，不是「约一百万」。
- 30 min = 1800 s → 每像素 < 1800 s ÷ 9×10⁶ ≈ **0.2 ms**（原文 1.8 ms）。
- 0.5 µm 间距：6000 × 6000 = 3600 万像素 → 每像素 < **0.05 ms = 50 µs**（原文 0.45 ms）。
- 原文两个数之间的 4 倍关系是对的，只是基数差 9 倍。一百万像素对应 1 mm × 1 mm @ 1 µm，或 3 mm × 3 mm @ 3 µm。
- 影响：0.2 ms 在 100 kHz 下最多 20 发，且要包含移动和稳定时间——单焦点「走一步、停一下」很可能不够快。值得问 Rui：是按哪种视场/间距，还是默认要用多焦点（论文是 8 个并行焦点）。

② **激光与 PRF** [文件确认 + 待确认]：原文按自由运行的 266 nm UV 激光、100–200 kHz 写。现在台架上是 NPL45C 450 nm，只能外触发、最高 50 kHz。W2/W3 用哪台激光、什么频率算达标？

③ **「商定的容差」**：W1、W5、W8 都写了 agreed tolerance，但具体数值从来没定过（master §1.2，10/5 会上那三个问题也没得到回答 [工作日志 10/11]）。

④ **STEP 的产生方式**：原文要求 NI counter 产生 STEP；现在 `bscan_test.m` 用的是硬件定时的 DO 波形。两者都是硬件定时，但不是同一种实现。现阶段 DO 方式是否可以接受？

⑤ **时间线以哪个为准**：原计划今天是 W6；你 10/4 写的四周计划（10/5–11/1）是另一套节奏。建议会上说清「按原计划我在 W3–W4 的电子学部分，W2 光学部分还没开始」，请 Rui 决定接下来是先补 W2 还是继续 C-scan。

⑥ **组织学 pilot 的日期**：Jenifer 十月底退休，pilot 要不要提前到这两周、谁负责送样？

---

## 第四部分 术语表

| 英文 | 中文 | 在本项目里指什么 |
|---|---|---|
| home / reference | 回原点 / 参考位置 | 开机后找到一个物理零点；软件清零不算 |
| nominal 1 µm move | 名义 1 µm 移动 | 命令上要求走 1 µm；实际走多少要测 |
| raster | 光栅扫描 | 逐行扫一个面 |
| repeatability / tolerance | 重复性 / 容差 | 多次回到同一位置的偏差 / 允许的偏差上限 |
| jog | 点动 | 手动小步挪 |
| mock hardware | 模拟硬件 | 假的设备对象，不接真机也能测程序逻辑 |
| A-line | A-line | 一个位置、一次触发得到的一条声信号随时间的波形 |
| bipolar signal | 双极性信号 | 光声脉冲典型的一正一负形状 |
| one-way acoustic delay | 单程声延迟 | 声音从样品到换能器走一趟的时间（不除 2） |
| PD | 光电二极管 | 探测每发激光的到来，当时间参考 |
| PRF | 脉冲重复频率 | 激光每秒发多少发 |
| batch-record mode / DMA | 批量记录模式 / 直接内存传输 | 采集卡攒一批记录再整体送进电脑内存 |
| overflow | 溢出 | 数据来得比电脑取得快，缓冲区装满 |
| envelope | 包络 | 振荡信号的外轮廓，常用来取幅度 |
| baseline removal | 去基线 | 减掉信号的直流偏置 |
| move–settle–acquire / step-and-settle | 移动–稳定–采集 | 走一格、等振动消失、再采 |
| MAP | 最大幅度投影 | 每条 A-line 取最大值拼成平面图 |
| ruled target | 刻线靶标 | 有已知间距刻线的标定板 |
| zipper artifact | 拉链伪影 | 相邻行左右交错错位 |
| flyback | 快速回程 | 每行扫完不采集、直接退回行首 |
| backlash | 回差 | 换方向时丝杆空走的那一段 |
| chrome-on-quartz target | 石英镀铬靶 | 有锐利明暗边缘的分辨率靶 |
| edge / line-spread / FWHM | 边缘扩展 / 线扩展 / 半高全宽 | ESF 求导得 LSF，LSF 的半高宽 = 分辨率 |
| NA / beam fill | 数值孔径 / 光束填充 | 会聚角大小 / 光束占物镜入瞳的比例 |
| ROI | 感兴趣区 | 选出来专门扫或分析的一小块 |
| chunked reading | 分块读取 | 数据太大时一块一块读 |
| pixel pitch | 像素间距 | 相邻采样点的距离（≠ 分辨率） |
| shots/pixel | 每像素发数 | 每个位置打几发激光（用于平均） |
| registration | 配准 | 把两张图的同一结构对到同一位置 |
| checkpoint recovery | 断点恢复 | 中断后从记录的位置继续 |
| H&E | 苏木精–伊红染色 | 病理标准染色，用作 PAM 图像的对照 |
| deparaffinization | 脱蜡 | 去掉石蜡包埋的蜡 |
| histology core | 组织学核心实验室 | 学校负责切片和染色的服务平台 |
