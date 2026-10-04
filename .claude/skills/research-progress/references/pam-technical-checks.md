# 最终稿技术补充的核对与适用边界

本说明随 2026-09-28 新定稿更新，用于引用、计算和实验建议。它不是教授的会谈要求。归档附件保持原文；其中第八节的简化或不一致之处按下面的核对结果解释。每次实施前仍以本机代码、硬件版本及对应文档为准。

## 代码数值与本机配置

- `0.4` 只有在确认变量代表以 V 表示的单边输入范围时，才能解释为 ±0.4 V。硬件具有 ±400 mV 档位，并不能证明某段未提供代码中的 `0.4` 就是这个档位。`150` 同样先核对是否为 `AlazarSetTriggerOperation` 的 Level 参数。
- 最终稿记录了当时的采集卡带宽讨论，不代表任何程序都只能控制采集卡。解释软件控制范围应看实际设备接口与函数调用。

## Trigger level 换算

ATS-SDK Programmer’s Guide v26.2.0 给出的设置关系是 `code = 128 + 127 × Vtrig / Vrange`。[1] 因此对普通非端点编码，按这个关系估算应使用 `Vtrig ≈ (code − 128) / 127 × Vrange`；最终稿第八节公式中的分母 128 不是此文档给出的换算。

若 code=150，且确认为该触发参数，三个假设量程 ±0.4 V、±1 V、±5 V 分别对应约 +69.3 mV、+0.173 V、+0.866 V。这些是标称换算示例，仍受量化、取整、触发准确度影响，不能写成本机实测值。先确定触发源及其量程；外部触发量程由独立配置决定。[1][2] 不把触发编码的换算用于 ADC 波形样本。

## NPT、Triggered Streaming 与 buffer

- NPT 通常按每个触发形成一条 record，一个 buffer 可包含多条 record；不能仅凭模式名称断言所有版本都绝对没有预触发。ATS9462 v1.5M 规格表明确列出固件版本 23 及以上时 NPT 最多 2048 个预触发点，需核对本机固件与设置。[3]
- Triggered Streaming 在触发后采集一条可跨越多个 DMA buffer 的连续 record。[1] 不把最终稿的“一次触发 → 一条 record → 多条 record 组成 buffer”当作所有模式通用的关系。

## 采样率与时间轴

- 80 MS/s 不在 ATS9462 v1.5M 所列内部时钟档位中。最终稿第七节把 80 与 160、180 并列为待选值时，应理解为会谈例子；实际可选值须按时钟源、硬件选件及 SDK 核对。[3]
- 不把“最高频率的 4–10 倍”设成统一达标要求。先确定输入有效频带、抗混叠条件、所需时间精度、记录长度和数据处理方法，再讨论采样率取舍。
- `1/fs` 是时间采样间隔；由声速换算的 `c/fs` 是单程声程采样间隔，不等于实际轴向分辨率。将时间轴映射为样品深度还需明确时间零点、传播路径和声速。

## 光声公式、波长与单位

- `p0 = Γ μa F` 应交代适用的热与应力约束、热转换假设及一致单位。若 μa 用 m⁻¹、F 用 J/m²，乘积是 J/m³，即 Pa；若使用 cm⁻¹ 与 J/cm²，数值所得 J/cm³ 需乘 10⁶ 才是 Pa。Γ 应解释为热弹性参数，不能简单当作 0 到 1 的能量转换比例。
- UV 对核酸、532 nm 对血红蛋白的例子说明主要吸收对比；不据此断言该波长只激发一种物质，也不把 266 nm 自动认作本机当前波长。

## 扩束、有效 NA 与本机图像

- 区分入射束径、透镜通光口径和物镜标称 NA。理想近轴几何中，聚焦角与实际利用到的束径和焦距相关；在束径、焦距相同且没有截光时，仅增大透镜通光口径不会自动增大有效 NA。
- 扩束缩小焦斑依赖入瞳利用、光束质量和像差等条件，不保证越扩越好。Edmund Optics 明确讨论了衍射与球差之间的取舍。[4] 给出分辨率系数前，说明采用的光斑或分辨率定义。
- A-line、B-scan 的通常定义不能代替本机实现。应查数据维度、扫描轴和投影/峰值处理，再判断程序显示的是深度截面还是处理后的平面图。

## 核对来源

[1] [ATS-SDK Programmer’s Guide](https://docs.alazartech.com/ats-sdk-user-guide/latest/programmers-guide.html)：Trigger level、AutoDMA acquisition modes；核对于 2026-09-28，当时 latest 文档显示 v26.2.0。

[2] [AlazarSetTriggerOperation](https://docs.alazartech.com/ats-sdk-user-guide/latest/reference/AlazarSetTriggerOperation.html)：8 位触发编码、触发源与外部触发量程。

[3] [ATS9462 datasheet v1.5M](https://www.alazartech.com/en/download/product/9058/306/ats9462-datasheet-and-specifications/1-5m/)：第 3、9 页的采集模式、NPT 预触发及内部采样率。

[4] [Edmund Optics: Laser Beam Expanders](https://www.edmundoptics.com/knowledge-center/application-notes/lasers/beam-expanders/)：Application 3, Minimizing Focused Spot Size。
