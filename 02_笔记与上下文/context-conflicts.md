# 参数账本与冲突清单

> **最近更新**：2026-10-11（#1 补第三个说法：Maria control_py 10/8 版写死 5 µm/pulse；裁决未改）。之前：2026-09-23 v2（v1 建于 2026-09-23 上午，只比 A/B 两份；v2 加入 ⟨G⟩ 9/23 三份 + ⟨N⟩ Drive 交接笔记 8/07 版，并重新裁决）。
> **来源缩写**：⟨C⟩ = Claude 8/30 `UV-PAM-context.md`；⟨G⟩ = ChatGPT 9/21 `PAM_project_context_for_new_chat.md` + 9/23 Handoff / Meeting Prep / New Chat Context；⟨N⟩ = Drive `PAM_LabVIEW_交接笔记.md` v0.9（8/07 版，38 KB）。
> **规则**：标「⚠ 待确认」的数值**不进计算、不进扫描设计**。有结论先写这里（结论 + 证据位置 + 日期），再同步到 `claude/UV-PAM-master.md`。

---

## A. 冲突清单（同一参数出现两个以上说法）

| # | 项目 | 说法一 | 说法二 | 为什么要紧 | 怎么核实 | **9/23 裁决** |
|---|---|---|---|---|---|---|
| 1 | **电机 X 轴 µm/pulse** | ⟨N⟩ §3 [文件确认]：1 pulse = 10 µm（200 step 设置，截图/README 图例）；⟨C⟩ 沿用 | ⟨G⟩ [实测]：手动 Move X 20,000 pulses ≈ 1 cm → **0.5 µm/pulse** | 差 20 倍。决定 H1 是否成立（16 kHz × 10 µm = 160 mm/s 超额定 8 倍 vs 16 kHz × 0.5 µm = 8 mm/s 在额定内）。0.5 µm/pulse ↔ SR2 约 2000（1 mm 导程）或 4000（2 mm 导程）step/rev | **Step 0**：拍三台 SR2 的 SW5–SW8 + 读台子型号标签（导程）；DG852 N-cycle burst 发正好 N 个脉冲量位移 | **⚠ 待确认。** 实测证据强于图例，工作中先按 0.5 µm/pulse 做条件计算，但每次写「[条件计算，X=0.5 µm/pulse]」。「dX=100 ≈ 1 cm」那半句**撤回**——那是 Xn≈200 的整行行程，(200−1)×100×0.5 µm = 9.95 mm，与 0.5 µm 相符，不是矛盾（⟨G⟩ Handoff §5.3）。**10/11 补第三个说法**：Maria 的 control_py（10/3、10/8 两版）写死 4 mm 导程 × 200 step/rev × 1/4 细分 = **5 µm/pulse** [文件确认，`06_控制程序/参考_Maria_control_py/2026-10-08/control_card/C_scan.py:24-26`、`:36`；她的"0.5 mm、每位置 0.01 mm = 2 脉冲"就是按这个算的]。没看到她的实测。和我们的实测差 10 倍：10/4 实测 0.5 µm/pulse、10/7 手轮量全行程约 27 圈 ≈ 54 mm → 导程 2 mm（`06_控制程序/CLAUDE.md`、工作日志 10/7）。若是同一台滑台、同一个 SR2 设置，她的 0.5 × 0.5 mm 扫描实际只有 50 × 50 µm [条件计算，X=0.5 µm/pulse]。是不是同一套硬件、她的 1/4 细分是不是读拨码得来的 → ⚠ 待问 Maria（`参考_Maria_control_py/2026-10-08/README.md` §7 第 1 问）。另：docs/11 记的实验室电脑上更早一版是"20 个微步 = 10 µm"（= 0.5 µm/pulse，和我们一致），到 10/3 版才变成 2 脉冲 = 10 µm。可能只是她改了代码里的假设，也可能有人改了 SR2 拨码；如果拨码被改过，我们 10/4 的 0.5 µm/pulse 也要重测（下次上硬件前先拍 SW5–SW8） |
| 2 | **DO Sample Rate** | ⟨C⟩⟨N⟩ §3：200 kHz | ⟨G⟩：500 kS/s（2 µs/样本）；早期示例 100 kS/s | 200k÷16k = 12.5，500k÷16k = 31.25，取整跳动幅度不同 | — | **✅ 解开（9/23，⟨N⟩ §6 [文件确认]）**：两个程序版本。**SlowUVscan_ENlaser = 200 kHz；SlowScan_ENdaq = 500 kHz**。用户 9 月在 "Enable DAQ" 文件夹跑 → ENdaq → 500 kS/s 正确。100 kS/s 是早期示例。**每次记录 DO rate 必须同时记程序版本。** |
| 3 | **激光重复频率 / 型号** | ⟨C⟩⟨N⟩：266 nm UV 激光头，可调 100 kHz–2 MHz；面板 Trig Rate 100 kHz、Galvo 区 Laser Freq 200 kHz；论文 50 kHz | ⟨G⟩ [文件确认，NPL 手册 Rev. J p.5]：台架上是 **NPL45C 450 nm**，无内触发，外触发上限 **50 kHz**，曾用函数发生器 20 kHz | 100/200 kHz 超 NPL45C 上限；450 nm 不是 UV | 查激光器铭牌 + 实际接线 + photodiode | **✅ 部分解开（用户 9/23 确认）**：**现在台架上接的是 NPL45C（450 nm）**，266 nm UV 是复现目标光源（在不在实验室、状态如何 ⚠ 待确认）。面板 100 kHz / 200 kHz 是 ENlaser 时代或旧值，**对 NPL45C 不适用**。Trig 100k vs Laser Freq 200k 面板不一致仍 ⚠ 待确认（⟨N⟩ §25.2 同族） |
| 4 | **bit6 / bit7 含义** | ⟨N⟩ §2：bit6 = DAQ Trigger、bit7 = Laser Trigger（I/O 页）；⟨N⟩ §22.1/§25.1 [实测]：ENdaq **C-Scan 帧** bit6 = GATE TRIG 连续高电平门，无 bit7 生成 | ⟨G⟩ [实测局部 buffer]：9 月 B-scan buffer 里 bit6/bit7 **同时以 5 样本间隔脉冲 20 次**（U8=192），再接 dX 个 STEP | 决定「每位置几个 laser pulse」怎么答；决定 ENdaq 下 bit7 是否接线 | 打开 ENdaq Main.vi **Start B-Scan 帧**，看波形生成区是 GATE TRIG 还是两个 GEN SKIP PULSE；示波器同测 P0.6 / photodiode / AND 输出 / Chan_B | **⚠ 待确认（新编号 #8 并入此条）**。可能解释：B-Scan 帧和 C-Scan 帧生成方式不同（⟨N⟩ §20.3 描述 B-Scan 帧用两个 GEN SKIP PULSE，§22.1 描述 C-Scan 帧用 GATE TRIG）。条件推断：那 20 个触发 = Subpixel Num = 20 |
| 5 | **A-line 长度** | ⟨C⟩⟨N⟩ §3：1024 点 | ⟨G⟩：64 点（@100 MS/s = 0.64 µs） | 0.64 µs 窗口很短 | — | **✅ 解开（⟨N⟩ §6）**：ENlaser = 1024（10.24 µs）；**ENdaq = 64（0.64 µs）**。同 #2，随程序版本记录。「0.64 ns」是笔误，应为 µs |
| 6 | **AlazarTech 型号** | ⟨C⟩：待确认；⟨N⟩ §12 待办写「ATS9350? ATS9462?」；框图里 SubVI 叫 "ATS 9350 Simple Async" | ⟨G⟩：工程有 ATS9350 文件夹也有 ATS9462-VI/6.3.0 路径；另一份 MATLAB 采集代码用 ATS9462 180 MS/s | 影响采样率上限、复现差距、ATS-SDK 迁移 | 看板卡丝印或 AlazarDSO 读型号 | ⚠ 待确认。倾向 ATS9350（SubVI 名 + 论文用 ATS9350），但 MATLAB 代码用 ATS9462 说明实验室可能两张都有 |
| 7 | **噪声目标** | Rui 口头：background 通常 **< 10 mV**（Vpp / RMS / 测量点未定义） | Rui 明确写出：**< 50 mV Vpp** | 验收标准不同，不能互相替代 | 问 Rui：测量点（放大器输出？）、增益、带宽、Vpp 还是 RMS | ⚠ 待确认。已列入 §20.1 问题 |
| 8 | **门 0.4 s vs 电机 1 s（面板自洽性）** | ⟨N⟩ §25.2 [实测 + 计算]：电机整行 Xn×dX = 2000×8 = 16000 步 @16 kHz ≈ 1 s = 500,000 样本（max2） | 采集门 (2000×20+1)×5 = 200,005 样本 ≈ 0.4 s（max1）→ 门只盖住行程 40% | 自洽要求 Trig = Motor÷dX×Subpx = 40 kHz ≠ 面板 100 kHz → 面板参数彼此不自洽，必有过时值或未见分频；若合成数组被截到门长（某次截图 bit1 size = sum size = 200005），电机后 60% 脉冲被切掉 | 一次干净运行，同屏截 bit6/bit1/sum size + max1/max2 + dX/Xn/Subpx/两个 Rate | ⚠ 待确认。与 #3 面板 Trig/Laser Freq 不一致同族 |
| 9 | **Motor Pulse Rate 16 kHz 是否在跑** | 面板 16 kHz [文件确认]；旧软件波形分析平均约 16 kHz（X 6000 STEP/375 ms） | Rui 上周提到 1 kHz（目标值还是当前值不明）；局部 STEP 间隔分析 5.43–16.13 kHz | 8 mm/s vs 0.5 mm/s 差 16 倍；非整除 31.25 样本 | 示波器接 STEP 线量周期；解码同次运行完整 U8 数上升沿间隔 | ⚠ 待确认。已列入 §20.1 |
| 10 | **dX 语义** | ⟨G⟩ [实测局部 buffer]：dX=2/4/8 → 2/4/8 个 X STEP（每次移动段的 STEP 数） | ⟨N⟩ §25.4：dX 语义待定（8 = 每像素步数？2000 = 总步数？）；面板「16 pulses=… 8 pulses=…」是换算图例 | 决定像素间距 = dX × µm/pulse 是否成立 | 同次运行完整 U8 + Xn 改变时 buffer 总长是否变 | ⚠ 待确认（被分析分支支持「每段 STEP 数」；其他分支未知） |
| 11 | **Xn 是位置数还是移动次数** | ⟨G⟩：Xn 位置 → Xn−1 个间隔 | ⟨N⟩ §4.1：forward 波形可能是一个扫描单元循环 Xn 次（→ Xn 次移动） | 301 vs 300；3 mm 边界 | 极小扫描（Xn=3）+ 大间距，数实际移动次数 | ⚠ 待确认 |
| 12 | **STEP 来源：DO 波形还是硬件计数器** | ⟨N⟩ §25.1 [实测]：三路 bit 在同一 DAQmx DO 任务里 | 工程引用 `SendCOPulses.vi`（Counter Output），⟨N⟩ §25.3 疑 100 kHz 触发可能走 ctr→PFI | 若走计数器，DO 网格非整除限制不适用 | Main.vi 框图 Ctrl+F 搜 "SendCO" 看是否真被调用；查输出通道名 | ⚠ 待确认。搜不到 → 遗留工具 VI，勿转向 |
| 13 | **换能器当前用哪只** | ⟨N⟩ §9 列四只：平面 30 MHz / 聚焦 37 MHz / 环形 31.7 MHz / 小型 30 MHz | ⟨G⟩ 只说「transducer 接 CH4」 | 影响频响、焦距、声程 | 看当前装的型号标签 | ⚠ 待确认 |

---

## B. 参数账本（所有带数值的说法，按来源分列；「✅」= 各来源一致或已裁决）

| 参数 | ⟨C⟩ 8/30 | ⟨G⟩ 9/21–9/23 | ⟨N⟩ 笔记 8/07 | 状态 |
|---|---|---|---|---|
| DO 管脚 bit0–7 | X/Y/Z STEP+DIR, bit6 DAQ, bit7 Laser | 同 | 同（I/O 页） | ✅ 逻辑映射一致；物理接线 ⚠ |
| DO Sample Rate | 200 kHz | 500 kS/s | ENlaser 200 k / ENdaq 500 k | ✅ 见 #2 |
| Motor Pulse Rate | 16 kHz | 16 kHz（旧分析平均） | 16 kHz | 面板一致；实际 ⚠ #9 |
| Trig Rate | 100 kHz | 100 kHz | 100 kHz（ENdaq 里只算门长） | 面板一致；对 NPL45C 不适用 |
| Laser Freq（Galvo 区） | 200 kHz | — | 200 kHz ⚠ 与 Trig 不一致 | ⚠ #3 |
| 实际光重复率 | — | 函数发生器 20 kHz；NPL45C ≤ 50 kHz | UV 头 100 kHz–2 MHz | ⚠ 随光源 |
| ADC 采样率 | 100 MS/s | 100 MS/s | 100 MS/s（ATS-VI 封顶） | ✅ |
| A-Line Points | 1024 | 64 | ENlaser 1024 / ENdaq 64 | ✅ 见 #5 |
| Trig Delay | — | 3.5 µs | 3.5 µs | ✅ 值；单位/定义 ⚠ |
| Trig Source / Level / Slope | — | — | ENlaser External / ENdaq Chan_B；144；Positive | ✅ [文件确认] |
| CH1 / CH2 Range | — | — | 200 mV / 4 V | ✅ |
| Pulses/Buffer | — | — | 2400 | ✅ |
| Subpixel Num | — | 「20 个触发」 | 20（每像素 A-line 数） | ✅ 值；「20 个触发 = Subpixel」⚠ 推断 |
| 参考时钟 | — | 10 MHz | 10 MHz | ✅ ≠ 任何输出率 |
| X µm/pulse | 10 µm（沿用笔记） | 0.5 µm [实测] | 10 µm（图例） | ⚠ #1（10/11：Maria 代码写 5 µm，见 #1） |
| Y / Z µm/pulse | — | 未标定 | — | ⚠ 未测 |
| Move X/Y/Z 面板值 | 8000 IN kx 0.25 / 200 RIGHT ky 0.9 / 320 UP kz 0.25 | kx=0.25、−0.5、1 试过 | — | 8/30 快照 |
| dX / dY / dZ 面板值 | 2000 / 1 / 4 | dX=2/4/8/20/100/200 试过 | dX=8, Xn=2000 | 随运行变 |
| DO 数组长度 | — | 500,000 样本 / 1 s（旧分析） | max1 200005 / max2 500000 | ✅ 旧运行一致 |
| CXP 整步/半步 | 10 / 5 µm（2 mm 导程）；5 / 2.5 µm（1 mm 导程） | — | — | ✅ [文件确认] |
| CXP 最大速度 | 20 mm/s（2 mm 导程）/ 10 mm/s（1 mm） | — | — | ✅ |
| SR2 输入 | ≥ 4.0 V, 10 mA, 下降沿, DIR 提前 ≥ 50 µs | — | — | ✅ [文件确认] |
| SR2 LED | 常亮 = 未使能；闪烁 = 正常 | — | — | ✅ [文件确认]；旧观察「绿的」无效 |
| 电机额定电流 | 1.3 A（28）/ 1.7 A（42）/相 | — | — | ✅ |
| 论文激发 | 266 nm, 50 kHz | — | — | ✅ |
| 论文分辨率 / 步长 | 1.3 µm / 1 µm | — | — | ✅ |
| 论文 digitizer | ATS9350, 500 MS/s | — | — | ✅ |
| NPL45C | — | 450 ± 10 nm, 无内触发, ≤ 50 kHz | — | ✅ [文件确认] |
| 噪声目标 | — | < 10 mV（?）/ < 50 mV Vpp | — | ⚠ #7 |
| CH4 背景 | — | 几十 mV（截图估计） | — | 非统一测量 |
| MATLAB ATS9462 代码 | — | Ch A, 180 MS/s, 2048 samples/record, 10×10 records | — | ✅ 独立配置 |
| 重建 −3300 | — | — | 峰峰值背景偏移 counts | ✅ [文件确认] |
| scan_pattern.mat | — | 177×2000, 1–2400, 2021-05-07 | — | ✅ 文件事实；含义 ⚠ |
| 会议 | 周一 9:00 一对一；周五 9:00 组会 BRB 332 | — | — | ✅ + 用户：中文 |
| 组织学 | — | 46 °C; xylene/ethanol; 1×3 in×1 mm; Jenifer 十月底退休; Week 9 | 联系人四位 | ✅ 回复内容；Week 9 日期 ⚠ |

---

## C. 各来源一致、可以放心引用的
- 8 路 DO 逻辑映射（bit0–5 = X/Y/Z STEP/DIR；bit6 DAQ 相关；bit7 Laser 相关）。
- 8 路 DO 是一个 U8 数组由 NI 卡硬件定时播出（⟨N⟩ §25.1 [实测]）——「软件循环发脉冲」作废。
- ADC 100 MS/s（legacy ATS-VI 上限）。
- Position X/Y/Z 是开环累加值，不能验证位移。
- 回程不发触发、不采数据。
- 6.25 只是 100/16 的名义比，不是每步实测脉冲数。
- 20k 全设 20 的每区间光脉冲数**没有**完整证据；不答 6.25 或 25。

## D. 已撤回的说法（详见 master §21）
- ⟨C⟩ H1「台子跑到 160 mm/s」——前提 10 µm/pulse 与实测冲突。
- ⟨C⟩ 「LED 绿的 = 正常」——常亮/闪烁含义相反。
- ⟨C⟩ 「脉冲串不是硬件定时」——作废。
- ⟨G⟩ 9/21「dX=100 ≈ 1 cm 与 0.5 µm/pulse 矛盾」——整行行程，不矛盾。
- 「64 点 = 0.64 ns」——µs。
- 「DO 200 vs 500 是矛盾」「1024 vs 64 是矛盾」——两个程序版本。

## E. 导师 9/23 谈话中提到的相关词
16 kHz、100 kHz、「分数脉冲」——与 #8/#9 非整除、面板不自洽方向一致，但转录不清，不能当确认。
