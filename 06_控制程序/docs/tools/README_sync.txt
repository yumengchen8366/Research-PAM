PAM 同步包（在实验室电脑上用 docs\tools\make_sync_package.ps1 打包）
================================================

包里有什么
  project\PAM_controlProgram\   整个项目文件夹（CLAUDE.md、docs、LabviewPAM、Alazartech_sampleCode）
  extra\Matlab\                 A-line 脚本、test2.m、bscan_test.m 和 aline_data（10/1、10/3 的全部测试数据）
  extra\New folder\             手册（CXP 滑台、SR2 驱动器、激光测试报告）
  extra\System_test_09_25\      LabVIEW 导出的 ForwardDO 时序数据和 bscantest.m
  extra\Control_py\             同学的 Python 代码（只有代码，不含 22 GB 的数据和 Python 环境）
  extra\ATS-SDK-23.3.0\         ATS-SDK-Guide.pdf，以及 Samples_MATLAB\Include（AlazarDefs.m 等，读代码时查常量用）
  claude\projects\              Claude Code 的记忆（memory\）和这个项目的全部对话记录
  claude\uploads\               对话里发过的照片（示波器、接线照片）
  claude\desktop-sessions\      Claude 桌面版侧边栏的会话列表
  manifest.tsv、package_info.txt   每个文件的校验值和打包时间（还原脚本要用，不要删）
  restore.ps1                   还原/更新脚本

  文件名带 lite 的是精简包（几 MB，可以直接从聊天里发过来）：不含 LabviewPAM、对话记录、照片和侧边栏会话列表，
  只有 memory。以后再还原完整包，缺的部分会补上（完整包要比精简包新，旧的会被拒绝）。

在另一台电脑上怎么还原或更新（第一次还原和以后每次更新，步骤都一样）
  1. 装好 Claude 桌面版，登录同一个账号，打开一次 Code 标签页。
  2. 完全退出 Claude（任务栏右下角托盘图标 -> 退出）。也关掉 Excel、PowerPoint、PDF 阅读器。
  3. 把 zip 解压到路径短的地方，例如 C:\PAM 或 下载 文件夹。
  4. 在解压出来的 PAM_sync 文件夹里，地址栏输入 powershell 回车，然后运行：
       powershell -ExecutionPolicy Bypass -File .\restore.ps1
     想先看看会改哪些文件、但不真的改，在最后加 -DryRun。
  5. 重新打开 Claude -> Code 标签页，侧边栏里应该能看到全部 PAM 会话。

脚本对每个文件怎么处理（这台电脑会记住上次收到的每个文件，所以中间跳过几个包也没关系）
  - 这台电脑上没有                       -> 复制过去。
  - 和实验室版本一样                     -> 不动。
  - 上次还原以后你没改过                 -> 换成实验室的新版本。
  - 你改过，实验室没改过                 -> 保留你的版本。
  - 你改过，实验室也改过（冲突）：
      你的文件（docs、Matlab 等）        -> 保留你的版本；实验室版本放到 桌面\PAM_sync_conflicts_<时间>\，你自己合并。
      Claude 的数据（对话记录、记忆）    -> 用实验室版本；你的版本放到 桌面\PAM_sync_backup_<时间>\。
  - 这台电脑上已经有、但没有记录（第一次用这个脚本） -> 用实验室版本；原来的放到备份文件夹。
  - 不会删除任何文件。每次运行都会在桌面写一个 PAM_sync_restore_log_<时间>.txt。
  - 比上次还原的包更旧的包，脚本会拒绝（防止把新文件改回旧版本）。
  - 某个文件被别的程序占用时，只有它会失败，其他文件照常处理；关掉那个程序再运行一次就行。

说明
  - 同步是单向的：实验室 -> 这台电脑。在这台电脑上改的东西不会自动回到实验室，要自己带回去。
    两边都会改的文件（尤其是 docs\工作日志.md、memory）最容易冲突，冲突时按上面的规则处理。
  - 如果这台电脑的用户名不是 2031（或者桌面在 OneDrive 里），脚本会把对话记录、记忆、
    CLAUDE.md 和 docs 里的旧路径改成新路径；ATS SDK 的路径会指向 桌面\ATS-SDK-23.3.0。
    Matlab 里的 .m 文件不改。
  - NI 卡和 ATS9462 只在实验室电脑上。硬件脚本（revised.m、test2.m、bscan_test.m）只能在实验室运行；
    这台电脑上只做分析（读 aline_data 里的 .mat）、写代码、看文档。分析需要装 MATLAB。
  - 侧边栏能不能显示拷过去的会话还没验证过（这不是官方的迁移功能）。如果没显示，
    对话记录仍然在 %USERPROFILE%\.claude\projects\ 下面。
  - 旧格式的包（没有 manifest.tsv，例如 10/3 下午 16:25 和晚上 19:34 那两个）不要再用。
