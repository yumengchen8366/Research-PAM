# UV-PAM 系统 · 对话上下文包

> ⚠️ **已过时（2026-09-23 标注）：这是较早版本的上下文包，已被 9/23 的交接文档取代，今后不再更新。**
> 开新对话请改用同目录下的 `PAM_Project_Handoff_2026-09-23.md`（完整记录）+ `PAM_New_Chat_Context_2026-09-23.txt`（开场白）；准备会议用 `PAM_Current_Setup_Meeting_Prep_2026-09-23.md`。
> 与新文档冲突的旧说法一律以新文档为准。数字化仪型号：工程里同时出现 ATS9350 和 ATS9462，**实际板卡型号尚未确认**（下文写的 ATS9462 只是从文件夹名推断，不作数）。

> 用法：开新对话时，把这一整份粘在第一条消息里，然后在最后「今天要问的」那一节写当天的问题。
> 每次和 Rui 开完会，回来更新「当前进度」和「待确认」两节，下次直接用。

---

## 一、我是谁 / 在做什么

Yumeng Chen，CWRU 生物医学工程博一（Fall 2026 入学），Rui Cao 组。
方向：photoacoustic imaging、biomedical optics、breast cancer imaging。

**当前任务**：教授要求先**复现实验室的 parallel UV-PAM 系统**，跑通之后开始扫描。

固定会议：周一 9:00 和 Rui 一对一；周五 9:00 Cao lab 组会（BRB 332）。

---

## 二、系统对标的两篇文献

| 论文 | 用途 |
|---|---|
| **Optical-resolution parallel ultraviolet photoacoustic microscopy for slide-free histology** · *Science Advances* · DOI `10.1126/sciadv.ado0518` | 我们系统的直接对标。galvo + diffractive grating 产生多光束、fast/slow axis 分工、双 transducer 接收 |
| **Multiscale photoacoustic microscopy and computed tomography** · Lihong V. Wang · *Nature Photonics* 2009 · DOI `10.1038/nphoton.2009.157` | 综述。用来定位 PAM 和 PACT 在整个领域里的位置 |

---

## 三、硬件清单（已确认型号）

| 部件 | 型号 | 作用 |
|---|---|---|
| DAQ 接线盒 | **NI BNC-2110** | Analog In/Out + Digital and Timing I/O。数字口 P0.0–P0.7 出 STEP/DIR；Trigger/Counter 口是 PFI 0/P1.0 和 PFI 12/P2.4；另有 USER 1 / USER 2 自定义 BNC |
| Galvo 驱动板 | **ScannerMAX（Pangolin）Mach-DSP** servo driver，S/N `PS502441` | 驱动 galvo mirror，负责 fast-axis 角度扫描 |
| 步进驱动器 ×3 | **MOONS' SR2**（SR series step motor drive） | 分别驱动 X / Y / Z 位移台。端子：`EN+/EN-`、`DIR+/DIR-`、`STEP+/STEP-`，电机相 `A+/A-/B+/B-`，电源 `V+/V-`。板上印有 Current Table、Microstep Table 和 LED Codes（绿=正常，红=故障） |
| 电源 | 开架式开关电源 | 给 SR2 供电 |
| 数字化仪 | AlazarTech **ATS9462**（从 LabVIEW 工程里的 `ATS9462-VI/` 驱动文件夹推断，9/23；待在板卡上核对） | 采集 PA 信号 |
| 激光器 | UV laser，**266 nm** | UV-PAM 的激发光源 |
| 光学元件 | beam splitter、photodiode、galvo mirror、多片 lens（含 **100 mm** 和 **250 mm**）、**diffractive grating**、两个 ultrasound transducer | 见下节光路 |

---

## 四、信号链（测电机时只涉及这一条）

```
LabVIEW
   ↓
NI DAQ
   ↓  Digital Output
BNC-2110 的 P0.x
   ↓  STEP / DIR
MOONS SR2 driver（X / Y / Z 各一台）
   ↓
X / Y / Z 步进电机
```

Galvo（走 ScannerMAX）、laser、Alazar 采集是另外的链路，**做电机测试时不参与**。

---

## 五、光路（按光的走向）

```
UV laser (266 nm)
  │
  ├─ beam splitter ──→ photodiode        ← 监测每发 pulse 的 timing 和能量，用于同步 / PA 信号归一化
  ↓
galvo mirror                              ← 角度扫描（fast axis）
  ↓
Lens ① ─── Lens ②                         ← relay / telescope，控制 beam diameter
  ↓
Lens ③
  ↓
diffractive grating                       ← 产生多个 diffraction order → 多个焦点（这是"parallel"的来源）
  ↓
Lens ④                                    ← 最终聚焦到组织
  ↓
tissue  ──→ PA wave ──→ transducer 1 / transducer 2
```

**为什么 lens 这么多**：每片负责不同任务，不是重复聚焦。
准直 → 扩束（改变 beam diameter）→ 送进 galvo → 把 galvo 的角度扫描 relay 成样品上的位移扫描 → 填满 objective aperture → 最终形成小 spot。
扩束的意义：spot size ∝ λf/D，进入聚焦镜的 beam 越大，最终 spot 越小，横向分辨率越高。若 100 mm + 250 mm 构成 Keplerian telescope，放大率 M = 250/100 = 2.5。

**待确认**：100 mm 和 250 mm 到底对应光路里哪两片——需要拿论文 schematic 对着实际光学台，一片一片认。

---

## 六、LabVIEW 前面板（我看到的控件）

| 控件 | 当前值 |
|---|---|
| Move X · 步数框 · 方向开关 | 8000 · IN · kx = 0.25 |
| Move Y · 步数框 · 方向开关 | 200 · RIGHT · ky = 0.9 |
| Move Z · 步数框 · 方向开关 | 320 · UP · kz = 0.25 |
| Position X / Y / Z | 显示当前位置 |
| Enable X? / Enable Y? / Enable Z? | 暂不使用 |
| dX / dY / dZ | 2000 / 1 / 4，暂不使用 |
| C-Scan、Volumetric Scan | 暂不使用 |

---

## 七、当前进度

- [x] 学会 align 光路（8/25）
- [ ] 按教授要求重新连线
- [ ] **X 电机单轴测试**：先把步数从 8000 改成 10–50 → 点一次 Move X → 观察（台子有没有动 / 是平滑还是只嗡嗡抖 / Position X 有没有变 / driver 灯是否正常）→ 正常就 50 → 100 → 200
- [ ] **X 方向测试**：切换 IN 开关，同样小步数，确认能反向走。能走但只走一个方向 → 查 DIR；完全不动 → 查 STEP / enable / driver / 接线
- [ ] Y 电机（Move Y ← RIGHT 开关），同样流程
- [ ] Z 电机（Move Z ← UP 开关），同样流程
- [ ] 和 Maira 一起校正 motor lines（9/2 下午）
- [ ] Galvo 测试（先不碰）
- [ ] 复现完整系统 → 开始扫描

---

## 八、安全约定

- 第一次点 Move 之前，手放在 Stop Program / 急停附近，**不要**放在运动平台或丝杆上
- 出现剧烈抖动、异常噪声、撞限位、driver 红灯 → **立即停，不要连点第二次**
- 一次只测一个轴，小步数起步，暂不碰 C-Scan / Volumetric Scan
- 确认 stage 不在行程最边缘，周围没有会被撞到的东西
- 不确定的线不要拔；**要拔之前先拍照记录原状**
- UV 激光：266 nm 不可见，护目镜按实验室规程

---

## 九、待确认 / 想问 Rui 的

- [ ] 100 mm 和 250 mm 的 lens 分别在光路的哪个位置
- [x] ~~AlazarTech 数字化仪的具体型号~~ → 应为 ATS9462（9/23 从驱动文件夹推断），会上跟 Rui 口头确认一下即可
- [ ] SR2 的 Current Table / Microstep Table 应该设成多少
- [ ] LabVIEW 里步数框是直接的 pulse 数，还是经过 kx/ky/kz 换算后的值
- [ ]

---

## 十、今天要问的

（每次开新对话时写在这里，写完再粘贴）

1.
2.
3.
