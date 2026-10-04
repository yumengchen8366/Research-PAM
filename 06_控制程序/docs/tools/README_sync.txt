PAM 同步包（在实验室电脑上用 docs\tools\make_sync_package.ps1 打包）
================================================

包里有什么
  project\PAM_controlProgram\   整个项目文件夹（CLAUDE.md、docs、LabviewPAM、Alazartech_sampleCode）
  extra\Matlab\                 A-line 脚本、test2.m、bscan_test.m 和 aline_data（含 10/1、10/3 的全部测试数据）
  extra\New folder\             手册（CXP 滑台、SR2 驱动器、激光测试报告）
  extra\System_test_09_25\      LabVIEW 导出的 ForwardDO 时序数据和 bscantest.m
  extra\ATS-SDK-23.3.0\         ATS-SDK-Guide.pdf，以及 Samples_MATLAB\Include（AlazarDefs.m 等，读代码时查常量用）
  claude\projects\              Claude Code 的记忆（memory\）和这个项目的全部对话记录（*.jsonl）
  claude\desktop-sessions\      Claude 桌面版侧边栏的会话列表
  changed_since_previous.txt    和上一个同步包相比，实验室电脑上新增或改过的文件
  restore.ps1                   还原/更新脚本

没有打包：Control_py（22 GB，同学的代码）、SDK7.30、SDK_NPT7.25（很大的 .dat 数据）。

在另一台电脑上怎么还原或更新（第一次还原和以后每次更新都一样）
  1. 装好 Claude 桌面版，登录同一个账号，打开一次 Code 标签页。
  2. 完全退出 Claude（任务栏右下角托盘图标 -> 退出）。
  3. 把这个 zip 解压到任意位置（例如 下载 文件夹）。
  4. 在解压出来的 PAM_sync 文件夹里，地址栏输入 powershell 回车，然后运行：
       powershell -ExecutionPolicy Bypass -File .\restore.ps1
  5. 重新打开 Claude -> Code 标签页，侧边栏里应该能看到全部 PAM 会话。

脚本对每个文件的处理
  - 这台电脑上没有：复制过去。
  - 内容一样：不动。
  - 内容不一样，而且实验室电脑上改过：先把这台电脑上的版本备份到 桌面\PAM_sync_backup_<时间>\，再换成新版。
  - 内容不一样，但实验室电脑上没改过（你在这台电脑上改的）：保留你的版本。
  - 不会删除任何文件。每次运行都会在桌面写一个 PAM_sync_restore_log_<时间>.txt。

说明
  - 如果这台电脑的用户名不是 2031（或者桌面在 OneDrive 里），脚本会自动把对话记录、记忆、
    CLAUDE.md 和 docs\*.md 里的旧路径改成新路径。Matlab 里的 .m 文件不改。
  - 这是打包那一刻的快照。之后两台电脑上的新对话不会自动互相同步，要再打一次包。
  - 同一个会话如果在两台电脑上都继续聊过，两边的记录就分叉了：脚本会用实验室电脑的版本，
    这台电脑上的那份会在备份文件夹里。
  - NI 卡和 ATS9462 只在实验室电脑上。硬件脚本（revised.m、test2.m、bscan_test.m）只能在实验室电脑上运行；
    在这台电脑上只做分析（读 aline_data 里的 .mat）、写代码、看文档。
  - 侧边栏能不能显示拷过去的会话是"待确认"（这不是官方的迁移功能）。如果没显示，
    对话记录仍然在 %USERPROFILE%\.claude\projects\ 下面。
