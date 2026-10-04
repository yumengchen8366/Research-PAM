# 08 我的 LabVIEW 清单（自己用，不写进给导师的计划）

用每周的机动时间做，每周 1–2 小时；忙的周可以跳过。目的是让我能说清"我写的和 LabVIEW 写的有什么不同、为什么"。

| 编号 | 做什么 | 怎么做 | 目的 | 和哪周一起 | 结果写到哪 |
|---|---|---|---|---|---|
| L1 | 截图存档 | 按 `screenshots/README.md` 的清单截 LabVIEW 框图和前面板，存进 `screenshots\`，再让 Claude 读图转写 | .vi 是压缩文件，新窗口里的 Claude 看不到框图；截图转成文字后，每个窗口都能读到 LabVIEW 是怎么算的 | 第 1 周 | 02 "截图转写" |
| L2 | 记下前面板的实际参数值 | 打开 Main.vi，截下平时用的参数（采样率、A-line 点数、触发电平、Motor Pulse Rate、Trig Rate、delta_x 等） | 拿到"组里一直在用的数值"，作为我选参数时的参考 | 第 1 周 | 02、05 |
| L3 | 读懂采集部分 | 写完自己的 A-line 和多条采集代码后，打开 Digitizer_initialization 和 GetDAQAsyncData，看它们怎么设置采样率、量程、触发、每个 buffer 几条记录、怎么取数据 | 检查自己的设置有没有遗漏，并能回答"LabVIEW 为什么这样设" | 第 1 周 | 03 对照表的"2 单条 A-line""3 多条 A-line"两行 |
| L4 | 读懂时序部分 | 打开 Start B-Scan 分支、GeneratePulses、GenerateSkipPulses、InitDODAQ，看电机脉冲和触发是怎么生成的 | 理解 LabVIEW 的连续运动加固定频率触发思路 | 第 2 周 | 02、03 "4 时序矩阵" |
| L5 | 和 ForwardDO 对照 | `System_test_09_25\ForwardDO_*.xlsx` 是 9/25 从 LabVIEW 导出的实际输出：8 条线在每个时刻是高还是低。我的时序表也是同样的格式（每行一个时刻、每列一条线）。把两者画在一起比较：电机脉冲多快、触发多频繁、触发和电机步之间的关系（LabVIEW 是固定 100 kHz，和步进不对齐；我的是每个位置一次） | 用实际数据看懂两种设计的差别；以后被问"为什么不用 LabVIEW 那种"能回答 | 第 2 周 | 03 "为什么不同" |
| L6 | 读懂电机移动 | 打开 Move X/Y/Z 分支、GenerateDiffPulses、current_pos | 对照自己的移动函数和回原点写法 | 第 2 周 | 03 "5 数字输出和电机" |
| L7 | 读懂 C-scan 和保存 | 打开 Start C-Scan 分支、SaveBinaryData；看 Y 循环怎么写、文件头（0/1/2/3）怎么存 | 对照自己的 C-scan 流程和数据格式 | 第 4 周 | 03 "6、7" |
