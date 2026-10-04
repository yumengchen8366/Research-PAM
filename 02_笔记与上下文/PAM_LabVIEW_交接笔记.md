# UV-PAM 系统交接 / 上手笔记 — v0.9

> 紫外光声显微镜(UV Photoacoustic Microscopy)控制系统 — LabVIEW 部分
> 项目:UV-PAM 用于无标记、无切片的术中组织学(乳腺组织)
> 代码作者:Yide Zhang @ COILab（前面板标题 "PATER @ COILab by Yide Zhang"）
>
> **阅读须知(重要)**:本笔记基于对前面板/框图截图 + README + 项目文档的解读整理。
> 凡标 **[已确认]** 的是从截图/文档直接可读的事实;标 **[假设/待验证]** 的是推断,**必须在实验室用实际运行参数或示波器核对后才能当结论**。请勿把假设当定论去改代码。

---

## 0. 一句话概览 [已确认框架 / 细节待验证]

系统是一台**光栅扫描(raster scan)光声显微镜**:激光逐点激发样品 → 换能器收超声信号 → Alazar 采集卡把每个点的波形(A-line)采下来 → 取峰峰值(或 RMS)当作该像素值 → 拼成 B-scan / C-scan 图像。
LabVIEW 主程序 `Main.vi` 负责三件事的**同步**:电机光栅扫描、DAQ 采集触发、激光时序。
**当前核心待办**:定位一个"每行采集点数不准(设 ~2000 实采 ~2010)"导致图像错位的时序问题。**成因尚未确认**,见 §4。

---

## 1. 成像原理速查（A-line / B-scan / C-scan / Volume）[已修正为精确表述]

| 概念 | 精确含义 |
|------|------|
| **A-line** | 某个横向位置采集的**一条时间波形**;时间轴可对应声学**深度**。 |
| **传统 B-scan** | 多条 A-line 组成的"**横向位置 × 深度**"截面(保留深度信息)。 |
| **本系统的投影** | 若每条 A-line 只取 `max−min`(或某深度窗口投影),得到一个**像素标量**;一行标量 = 一条横向投影线(1D)。 |
| **Volume / V-scan** | 完整 X–Y 扫描且**保留全部 A-line 深度**时,才形成 X–Y–depth **三维数据体**(软件里的 Volume 标签页)。 |
| **显示的 C-scan** | 对 A-line 取峰峰值/深度窗口投影后的 **X–Y 二维图**。(所以"C-scan = 三维体"是不准确的说法。) |
| **快轴/慢轴** | 光栅来回扫:快轴来回扫得快,慢轴每行走一步。**回程不发触发、不采数据**(代码里回程波形无触发位)。 |
| **像素值的意义** | 绝对幅度无意义(取决于光照、放大)。系统对不对看:已知样品能否还原正确**形状** + 分辨率达标 + 目标/背景**对比度**高。 |
| **焦平面** | 先把样品摆到焦平面。平样品只扫 X–Y;斜/立体样品才需 Z。目前暂不扫 Z。 |

---

## 2. ⭐ 8 个 NI I/O 管脚定义 [已确认,抄自 I/O 页]

设备线:`Dev1/port0/line0:7`

| Bit | 端口 | 功能 |
|-----|------|------|
| 0 | P0.0 | X Pulse（X 电机步进脉冲） |
| 1 | P0.1 | X Dir（X 方向） |
| 2 | P0.2 | Y Pulse |
| 3 | P0.3 | Y Dir |
| 4 | P0.4 | Z Pulse |
| 5 | P0.5 | Z Dir |
| 6 | P0.6 | **DAQ Trigger** |
| 7 | P0.7 | **Laser Trigger** |

> 注:Bit 6、7 采用 "skip pulses",**第一个脉冲不跳过**。
> 8 路信号本质是一个数字波形数组,由 NI 卡按 DO Sample Rate 硬件定时播出。搞懂这 8 路时序 = 懂大半个程序。

---

## 3. 关键参数 [已确认为截图可读值 / 但需在故障时复核]

| 参数 | 截图值 | 备注 |
|------|--------|------|
| DO Sample Rate | **200 kHz** [I/O 页明确可读] | 注:**参考时钟 10 MHz ≠ DO 采样率**,勿混。另注:曾有"2 MHz"说法,极可能是与**激光可调重复频率上限(100 kHz–2 MHz)**记混——待核实故障时实际 DO 率。 |
| Motor Pulse Rate | 16 kHz | = 每秒 DO 脉冲数 |
| Trig Rate (Hz) | 100 kHz | |
| Laser Freq(Galvo 参数区) | 200 kHz | ⚠️ **与 Trig Rate 100k 不一致**,bit7 激光触发到底按哪个频率,待实验室确认 |
| 触发源 / Level / Slope | External / 144 / Positive | |
| CH1 / CH2 Range | 200 mV / 4 V | 16-bit 映射,见 §5 |
| A-Line Points | 1024 | |
| Pulses/Buffer | 2400 | Alazar 每 buffer 的 record 数(≠ 必然等于一行,见 §4) |
| 电机换算 | 1 pulse = 10 μm(200 step 设置) | Zolix KA/CXP stage + SR2 步进驱动 |

---

## 4. ⭐ 时序问题:并列假设与逐级定位法 [核心待验证内容]

### 4.1 波形怎么生成的 [已确认结构]
一行波形由三个子 VI 输出**相加**合成(`Forward DO Pulse`,U8 数组):
- **GenerateSkipPulses(bit=6)** → DAQ 触发串
- **GenerateSkipPulses(bit=7)** → 激光触发串(两者共用 Trig Rate / DO Sample Rate 那组运算,理论上**同频同相**,只是输出到不同 bit)
- **GeneratePulses(电机)** → X Pulse + Dir(单独用 Motor Pulse Rate/dX/kx 计算,长度**独立**)

回程 `Backward DO Pulse`:只有电机 GEN PULSE,方向位取反,**不含任何触发** → 回程不采数据。
前面板有 **Forward Pulse # / Backward Pulses #** 显示件,跑程序时对照即可自检。

> ⚠️ 待验证:forward 波形可能是"一个扫描单元被循环重复 Xn 次";backward 用 `dX × Xn` 一次性回行首。三条波形是否等长、samples 如何在三者间分配,**尚未从截图确认**(需要 R/IQ 节点放大图 + Probe)。

### 4.2 GenerateSkipPulses 算法 [已确认逻辑]
1. `samples ÷ xn` **整数除法** → 每个脉冲间隔(Use S Curve=True 时用于加减速;现为等间隔)
2. 间隔数组累积和 → 每个脉冲落在第几个样本
3. for 循环逐样本:是脉冲位置就计数 +1,再对 `Skip_Period` 取余;余 0 输出 `2^Bit × en`,否则输出 0

### 4.3 "2000 → 2010" 的并列假设(不预设单一成因)
- **H1**:`GeneratePulses/GenerateSkipPulses` 存在 off-by-one、首脉冲特例或取整问题
- **H2**:`Xn / Subpixel Num / Pulses per Buffer` 经商余数分块时,最后一组多/少执行
- **H3**:Laser Enable、photodiode 与 DAQ gate 之间存在启动延迟/相位偏移
- **H4**:AND gate 输出的实际触发数量不是 2000
- **H5**:Alazar 的 records-per-acquisition 或 buffer 结束条件多采 records
- **H6**:硬件采集正确,但文件写入、双通道拆分或 MATLAB reshape 时产生额外 A-line

> 关于非整除:**若**故障时 DO=200k、Motor=16k,则 200000/16000 = 12.5(每电机脉冲 12.5 个 DO 样本),可能涉及取整/相位误差;**若**为 2 MHz 则 = 125,无此问题。**必须以故障运行时的实际参数为准。**
> 关于 buffer:Pulses/Buffer=2400 与一行 ~2000 不整除**本身通常允许**;只有当程序把一个 buffer 当一行、buffer 交界丢/重 record、末个不完整 buffer 余数处理错、或 reshape 默认每行从 buffer 边界开始时,才会出错。列为假设,勿当定论。

### 4.4 逐级定位法(定位原则)
从 LabVIEW 数组 → NI 物理输出 → photodiode → AND gate → Alazar records → DAT 文件 → MATLAB 重建,**逐级数脉冲/records 数量**;**第一次从 2000 变成 2010 的环节,就是最可能的错误位置。** 用 §12 的逐级计数表记录。

### 4.5 验证方法
- `GenerateSkipPulses.vi` / `GeneratePulses.vi` 前面板**能独立运行**:填入真实值 → 运行 → 看 `pulsetrain` 数组长度和脉冲数 vs 理论值。
- 对两个 R/IQ 输出加 **Probe**,读商/余数。
- 延迟稳定性测试:确认多采点数是否**恒定且位置固定**(见 §4.6)。

### 4.6 关于后端"扔点" [降级为诊断手段]
MATLAB 端可先加入 **records 计数、余数检查和可选裁剪**,用于**诊断及临时验证**;**在确认额外 records 稳定且位置明确之前,不作为最终修复**——否则相位漂移/丢包会被掩盖。

### 4.7 为什么多采点会毁掉图 [重建代码印证]
重建脚本是**逐像素/逐行按固定长度顺序切**的:每像素严格读 `[ALength, Subpx]`,每行严格 `Xn×Subpx` 条 A-line,**没有任何对多余 record 的检测或余数处理**。因此只要硬件某行多采了 k 条,从那行起后面全部**累积错位 k**(逐行增大)→ 图像倾斜/撕裂,正是之前看到的坏图症状。
推论:**重建代码本身没错**(计数正确时是对的);根因在硬件计数。修复二选一:
- (a) 从源头修 LabVIEW 计数(更干净);
- (b) 让重建对每行实际长度稳健:但原始 .dat 是裸 uint16 流、**无逐行 header 标记**,只能靠"总 A-line 数(= 文件大小 / (2×ALength))vs 期望数(Xn×Yn×Subpx)"推每行 overcount。**若 overcount 每行恒定 = k**,用"修正行长 = Xn×Subpx + k"重切,看图是否回正——这是一个不进实验室、光靠 .dat 就能做的诊断实验。

---

## 5. 数据格式与后端 [已由重建代码确认]

路径:`Documents\MATLAB\DataProcessingCode\`。以下从实际重建脚本读到,原先的"待确认"项现已定案:

- **数据类型 [已确认]**:`fread(..., 'uint16')` → **无符号 16-bit**(不是 signed)。每 sample 2 字节。→ 由此可算总 A-line 数 = 文件大小 / (2 × ALength)。
- **单/双通道排列 [已确认]**:双换能器数据按"**整块通道**"排——每次读 `[ALength, Galvo_step×2]`,前 `Galvo_step` 列 = Channel1,后 `Galvo_step` 列 = Channel2(即一条 B-scan 线:先全部 Ch1 的 A-line,再全部 Ch2)。单通道测试数据无此拆分。
- **`−3300` 的真实含义 [已确认]**:`max(Ch)−min(Ch)−3300` —— 它是对**峰峰值(pk-pk)幅度图**减去的一个**恒定背景偏移**(背景噪声 pk-pk ≈ 3300 counts,用于把背景归零)。**不是对原始波形去噪、也不是滤波**;背景以下会出现负值。单通道测试脚本里没有这步。(教授当年记不清的这个数,现已澄清。)
- **Subpixel 平均 [已确认]**:`Subpixel Num`(如 20)= 每个像素重复采多少条 A-line;重建时先对这 N 条求 `mean`,再取 `max−min` 当像素值。
- **投影 [已确认]**:`projection = max(ave)−min(ave)`,即前面板 Projection = Max−Min。
- **重建的脆弱点**:见 §4.7 —— 逐行固定长度死切,不检测多余点,所以硬件多采会累积错位毁图。

---

## 6. 两个"最终版"对比 [已升级为框图+前面板实测]

两版都在 `PAM_controlProgram\LabviewPAM\`,都用 legacy **ATS-VI**,采样率封顶 100 MHz。
**重要实测发现**:两版的 **LabVIEW 框图结构几乎完全相同**(都用 bit6/bit7 两个 GenerateSkipPulses + 电机 GeneratePulses)。真正的区别不在代码,在**触发源和硬件接线**。

| 项 | **SlowUVscan_ENlaser** | **SlowScan_ENdaq** |
|---|---|---|
| **Trig Source** [已确认] | External | **Chan_B**（触发于 photodiode 实测激光脉冲） |
| DO Sample Rate [已确认] | 200 kHz | **500 kHz** |
| Laser warmup 字段 [已确认] | 有,= **1.00024 s** | **无此字段** |
| A-Line Points [已确认] | 1024 | 64 |
| 激光状态 [README] | 脉冲式,Bit 7 开关 | **常亮** |
| 同步机制 [README] | 软件:Bit 7 直接控激光 I/O + 延迟补偿 | 硬件:Bit 6 + photodiode 经 **AND gate** → DAQ 触发(NPT) |
| 根因处理 [推断] | 命令激光后赌固定延迟 | **探到真光才采** → 从根上绕开延迟不确定性 |
| 主要风险 | 软件延迟是否稳定 | AND 门 / photodiode 触发信号质量 |

> **判断 [推断,待实测]**:ENdaq 触发于 Chan_B(真实光脉冲),不需要 warmup 补偿,**原理上是更稳的方案**,契合教授"激光以内部 DAQ"的倾向。但:① 非整除问题仍在(500000/16000 = **31.25**);② bit7 激光触发在"激光常亮"的 ENdaq 里可能沿用代码但未实际接线,待确认;③ AND 门电路质量是其新风险点。
> **关于 1.00024 s [部分确认]**:ENlaser 里**确实存在**这个 warmup 值 [已确认];1.00024 − 1 = **240 μs**,与口述中"约 240 微秒"延迟**高度吻合**,是有力旁证;但"它就是激光物理启动延迟""导致多 10 点"这层**因果仍待示波器验证**(同测 Bit7 命令沿与实际出光沿)。ENdaq 无此字段,进一步支持"ENdaq 用硬件绕开了该延迟"的解读。

---

## 7. 软件版本注意（战略层面）[已确认]

README 明确:**ATS-VI 6.3.0 是 legacy 软件(约 10 年前停更),AlazarTech 官方不再支持;推荐 ATS-SDK。**
- ATS-VI 采样率封顶 **100 MHz**(现设 100 MS/s 已顶格);设 >100 MHz 有效率折半(180→90 MS/s)。
- **迁移 ATS-SDK 的价值**:采集卡支持、buffer/trigger 管理、调试能力、更高数据吞吐。
- **迁移不会直接提高空间分辨率**:UV-PAM **横向分辨率主要由光学焦点决定,轴向分辨率主要受换能器带宽影响**。更高采样率只改善轴向数字化保真度,不改变根本分辨率。

各版本:`20210051`(依赖损坏,不能跑)、`PAM_NPTDAQ`(修好依赖,non-pre-triggered)、`PAM_TriStream`(triggered streaming)、`SlowScan_ENdaq` / `SlowUVscan_ENlaser`(**本项目最终两版**)。

---

## 8. 项目背景 & IRB [已确认]

- 课题:**UV Photoacoustic Microscopy for Label-free and Slide-free Intraoperative Histology**(术中乳腺组织学)
- PI:**Aparna Harbhajanka**(UH 病理科);co-investigator:**Rui Cao**(方法来源,参考文献多为 Cao R. + Wang LV 的 Nature 系列)
- 样本:福尔马林固定人乳腺组织,最多 100 例;光声组织学 ↔ H&E 交叉验证 + 训练虚拟染色神经网络
- 流程:系统 ready(先扫头发/phantom 调形状、对齐、对比度)→ 再扫病理组织

---

## 9. 硬件清单要点 [已确认]

| 类别 | 型号/规格 | 位置 |
|------|-----------|------|
| 电机 stage | Zolix KA / CXP 系列 + SR2 步进驱动 | 光学台上方架子 |
| 采集/IO | NI 多功能 I/O DAQ、Galvo 伺服驱动 + 电源 | 光学台上方下层架 |
| 换能器 | 平面 30 MHz / 聚焦 37 MHz(5mm,58%) / 环形 31.7 MHz(8.8mm,77%) / 小型 30 MHz(5mm,60%) | 架子 / 光学台 |
| 光电二极管 | Amplified photodiode(ENdaq 版 AND 门用) | PAM 光学台 |
| 激光 | UV 激光头(手册在 TOOL 抽屉下方);重复频率 100 kHz–2 MHz | — |

> 换能器频响图在 Google Drive(manual → ultrasound transducer)。

---

## 10. 联系人 & 门禁 [密码已按安全要求移除]

- **病理/组织获取**:Carlo De Salvo `carlo.desalvo@case.edu`;Jenifer Mikulan `jenifer.mikulan@case.edu`;Wendi Barrett `wxb8@case.edu`;Adam Kresak `amk41@case.edu`
- **AlazarTech 技术支持**(迁 ATS-SDK 找他们):`Support@alazartech.com`;Gabriel Fettu `Gabriel@alazartech.com`;Muneeb Khalid `Muneeb@alazartech.com`
- **CWRU IRB**:Kimberly Volarcik `kav6@case.edu`
- **PAM 电脑远程登录凭据**:**由 PI / 实验室管理员单独提供**(不写入本文档;若此前已泄露,建议更换)。

---

## 11. 分辨率验证注意 [新增,纠正"头发证明分辨率"]

- **头发适合验证**:有无信号、扫描方向/形状是否正确、是否逐行错位、对比度/重复性。
- **头发不能证明 ~1 μm 分辨率**(头发直径 ~50–80 μm)。证分辨率需:已知尺寸靶标 / 细纤维 / edge 或 line-spread function + **FWHM 测量**。
- 先确认"**1 μm**"是系统设计指标、论文指标还是教授要求。

---

## 12. 待办清单（TODO）

- [ ] **读懂 8 管脚时序**:ENlaser 版 `Main.vi` 框图,理清三个生成器输入连线(尤其 R/IQ 节点 + Probe)
- [ ] **验证点数问题**:独立运行两个生成器 VI,对比 pulsetrain 长度 vs 理论值
- [ ] **逐级计数**(§12 表):找出第一次从 2000 变 2010 的环节
- [ ] **测延迟稳定性**:多采点数是否恒定且位置固定;1.00024 s 是否真对应出光延迟(示波器)
- [ ] **确认关键参数**:故障时实际 DO 率、激光实际重复频率(100k vs 200k)、采集卡型号(ATS9350? ATS9462?)
- [ ] **读后端代码**:`decipherDATFile.m` + `Reconstruction_2y.m`,确认数据类型/编码与 −3300 含义
- [ ] **对比两版**:截 ENdaq 的 B-Scan 框图,比对同步机制,实测决定用哪版
- [ ] **分辨率测试**:用靶标测 FWHM,确认 1 μm 指标来源
- [ ] （长期）评估采集迁移到 ATS-SDK

---

## 13. 可复现参数表（每次测试都填一行）[新增]

| 日期 | 程序版本 | DO Rate | Trig Rate | Motor Rate | dX | Xn | Subpixel | Pulses/Buffer | Alazar 参数 | 激光频率 | 文件大小 | 备注/问题 |
|------|---------|---------|-----------|------------|----|----|----------|---------------|------------|---------|---------|-----------|
| | | | | | | | | | | | | |

## 14. 逐级计数表（定位点数异常用）[新增]

| 环节 | 期望值 | 实测值 | 备注 |
|------|--------|--------|------|
| Bit 6 (DAQ trig) LabVIEW 数组脉冲数 | 2000 | | |
| Bit 7 (Laser trig) 数组脉冲数 | 2000 | | |
| Photodiode 实际脉冲数(示波器) | | | |
| AND gate 输出脉冲数 | 2000 | | |
| Alazar records/acquisition | | | |
| DAT 文件中 A-line 数 | | | |
| MATLAB reshape 后每行 A-line 数 | | | |

## 15. 运行 SOP 与安全(待补全)[新增框架]

- **开机顺序**:(待填 — 电源/驱动/激光/DAQ/软件先后)
- **激光安全**:UV 激光,佩戴激光安全镜/面罩;确认光路遮挡;人员离场规则
- **样品安装 & 聚焦**:样品摆到焦平面(平样品只需 X-Y)
- **运行扫描 → 停机**:正常停止流程
- **异常停止**:急停按钮、stage **限位/碰撞风险**处理
- (到实验室后按实操补全)

## 16. 版本与结果追踪 [新增]

为每次实验保存对应关系:**程序版本 — 参数(§13)— 原始 DAT — 重建图 — 问题描述**,避免不同版本/参数的截图和数据混淆。

---

## 17. 待补充材料(优先级)

1. **故障发生时的完整 Front Panel 参数截图**(确认 §3 各值)
2. 两个 `R/IQ` 节点放大图,商/余数输出加 **Probe**
3. Alazar 初始化/读取 VI 中:samples per record、records per buffer、records per acquisition、channel mask、保存数据类型
4. `decipherDATFile.m`、`Reconstruction_2y.m` 及直接调用的子函数
5. 一份**无患者信息**的小型 DAT + 对应参数 + 错误图
6. 示波器同时测 **Bit 6 / photodiode / AND 输出 / Alazar EXT TRIG**

---

## 18. 触发机制与连线(信号流向)[核心理解]

> 配套可视化:`UV-PAM_信号流向图.html`(能点开看的流程图)。

### 18.1 一次 B-scan 到底怎么发生(六步)
1. **LabVIEW 预先算好一整条 DO 波形数组**(`Forward DO Pulse`,U8):数组每个采样点(按 DO Sample Rate 的节奏)规定 8 根线此刻各自高/低。
2. **NI 数字 I/O 卡**把这条数组按 DO Sample Rate **一次性播出去**;同时 Alazar 卡进入"等触发"。
3. 播的过程中:P0.0–P0.5 让**电动台横着走完一行**;P0.6/P0.7 按触发率发脉冲。
4. **每个触发 → Alazar 抓一条 A-line**(ALength 个点 @ DAQ Sample Rate)。
5. 走完一行 → 换行 + **回程(只走电机、不发触发、不采数据)**。
6. A-line 流回 LabVIEW → `max−min` → 存 .dat。逐行重复成图。

### 18.2 8 根线的物理去向(连线)
- **P0.0–P0.5(6 根)→ 三个 Zolix SR2 步进驱动器**:每轴两根(脉冲 + 方向)。X=P0.0/P0.1,Y=P0.2/P0.3,Z=P0.4/P0.5。
- **P0.6 → DAQ 触发线**;**P0.7 → 激光触发线**。
- **换能器 → 放大器 → Alazar CH1**(200mV);**光电二极管 → CH2 / Channel B**。

### 18.3 两版触发机制的本质(最关键)
两版 **LabVIEW 代码几乎相同**,区别全在"Alazar 听谁的触发"(前面板 Trig Source):

- **ENlaser(Trig Source = External)——命令式 · 开环 ⚠**
  P0.7 **命令激光发光**,P0.6 **命令 Alazar 采集**。但激光有启动延迟(~240 μs),"命令采集"与"光真正到达"对不齐,只能加延迟补偿去凑。**开环——赌延迟恒定**,一旦漂移就错位。

- **ENdaq(Trig Source = Chan_B)——探真光 · 闭环 ✓**
  激光**常亮**;**光电二极管**探到每一发真实光脉冲。**P0.6 与 photodiode 接 AND 与门两输入**(P0.6 = 扫描时为高的"使能窗口",photodiode = 真实脉冲时刻),AND 输出 = 使能窗口内放行的真实脉冲 → 接 **Alazar Channel B**,Trig Source=Chan_B 即 Alazar 探到 Chan B 越过电平(144)就采。**跟着真实出光走 → 延迟问题被硬件绕过**。

一句话:**ENlaser =「我命令、赌延迟」(开环);ENdaq =「等真光、真光来了才采」(闭环、自校正)。**

---

## 19. 附录:看懂 LabVIEW 框图(图标 + 连线机制)[入门词典]

### 19.1 最重要的原则:数据流(Dataflow),不是从上往下
LabVIEW **不按行、不按位置**执行。一个节点(框/图标)**等它所有输入的数据都到齐了才执行**,数据沿连线流动。**没有连线连着的两块 = 无先后依赖 = 可并行**。所以"顺序"靠**连线**和**结构框**来控制,不是靠位置。

### 19.2 连线(Wires)= 数据管道,颜色/粗细 = 数据类型
| 线 | 含义 |
|----|------|
| 细橙 / 粗橙 | 单个小数(double) / 小数**数组** |
| 细蓝 / 粗蓝 | 单个整数 / 整数**数组**(如 `DO Pulses` U8 数组是粗线) |
| 绿(含虚线绿) | 布尔(真/假 T/F) |
| 粉 / 紫 粗线 | 硬件通道引用(`Motor and Trigger Lines`、`Scan AO Channels`) |
| 线上出现**红点/断口** | 坏线(类型不匹配) |
> 记法:**越粗 = 越"厚"的数据(数组/簇);越细 = 单个标量。**

### 19.3 长方形的框 = 结构(Structures)= 控制"顺序/重复/分支"
- **While Loop(while 循环)**:最外那个带灰边、右下角有**红色停止标志**、角上有 `i` 的大框。里面**反复执行**直到停止条件(Stop / 非 Continuous)。→ 扫描主循环。
- **For Loop(for 循环)**:左上角 `N`、左下角 `i` 的框。里面**执行 N 次**,`i` = 第几次(0,1,2…)。GEN SKIP PULSE 外面那几个叠框就是它,用来**一条条拼波形**。
- **Case Structure(条件结构 = if/else)**:顶上有 `◀True▼`/`◀False▼` 下拉的框。像开关——连进来的**布尔线**为 True 就跑 True 页。`DO Pulses`、`Save Data?` 外面的框都是"要不要做"的开关。
- **Sequence(顺序框)**:强制先后(本图主要靠数据流控顺序,用得少)。

### 19.4 带图片的方块 = subVI(子程序 = 别人写好的函数)
喂输入、拿输出即可。本图里:
- `ATS 9350 Simple Async` = 初始化 Alazar 采集卡
- `Init / Run / Stop DOAO DAQ` = 初始化/启动/停止 NI 卡的数字+模拟输出任务(播波形)
- `Send DO Pulse` = 把算好的波形数组真正送出去
- `GEN SKIP PULSE` / `GEN PULSE` = 生成触发 / 电机脉冲串
- `Create Binary File` = 建存盘文件;`Return Galvo` = 扫完振镜回位;`ATS Error Code` = 读采集卡错误码

### 19.5 小图标 = 基本函数(Primitives)
- `÷` 除、`×` 乘、`+` 加
- **`R ÷IQ`(写 R、IQ 的)= 商与余数 Quotient&Remainder**:整数除法,同时给出商和余数。⭐ **点数取整问题的关键**——非整除时余数怎么处理决定多/少几个点。
- `=` 判等;`≥` 大于等于
- **`?1:0` = Select 选择器**:按一个布尔在两个值里选一个(类似三元)。回程波形里 `xdir` 前用它选方向。
- **三角形带点 = NOT 非门**(取反);**小圈里 `∨` = OR 或**
- **像网格的图标 = Build Array(拼数组)/ Reshape / Index Array(取元素)**——把脉冲拼成整条波形、或取某段。

### 19.6 连线穿过框边的小方块 = 隧道(Tunnel)+ 移位寄存器
- **Tunnel(隧道)**:数据进出结构的口子。For 循环边上**实心橙色带方括号**的 = **自动索引 auto-indexing**:每转一圈自动往数组存/取一个元素 → 这就是"逐圈拼出一整条波形数组"的机制。
- **Shift Register(移位寄存器)**:循环边上**成对的上下三角**,把这一圈的值传给下一圈(累加、计数)。`x count in B-scan loop`、`Curr_X` 就靠它。
