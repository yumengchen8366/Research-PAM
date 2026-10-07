# 用 GitHub 在多台电脑、多个 Claude 账号之间同步 PAM 项目

（2026-10-04 起取代 zip 包同步。zip 方式 `make_sync_package.ps1` / `restore.ps1` 保留备用。）

## 原理

- 一个**私有** GitHub 仓库，仓库的根目录就是 `Desktop\PAM_controlProgram`。
- `Matlab`、`New folder`、`System_test_09_25` 放在项目文件夹里面。桌面上的同名"文件夹"其实是 **junction**（目录联接，对程序透明），所以 `C:\Users\2031\Desktop\Matlab\...` 这样的旧路径照样能用。
- Claude 的记忆：`%USERPROFILE%\.claude\projects\<项目>\memory` 是指向 `claude\memory` 的 junction，Git 直接就能看到。
- 对话记录、聊天里发过的照片、桌面版侧边栏的会话列表，由 `pam_sync.ps1` 在本机和 `claude\transcripts`、`claude\uploads`、`claude\desktop-sessions` 之间来回复制。
- 仓库里的 Claude 数据统一用实验室电脑的路径（`C:\Users\2031\...`）存。复制到别的电脑时，会自动改成那台电脑的路径。
- 对话、记忆这些都是本地文件，**和登录哪个 Claude 账号无关**。只有桌面版侧边栏是按账号分开存的，所以要用 `sync_pam_sidebar.cmd` 导入一次。

## 每天怎么用（任何电脑、任何账号都一样）

| 什么时候 | 做什么 |
|---|---|
| **开工前** | 双击项目文件夹里的 `sync_pam.cmd` |
| **收工后** | 先让 Claude 按 CLAUDE.md 写好工作日志，再双击 `sync_pam.cmd` |
| 想在侧边栏看到另一台电脑新开的会话 | 完全退出 Claude（托盘图标 → 退出），双击 `sync_pam_sidebar.cmd`，再打开 Claude |

`sync_pam.cmd` 做五步：本机对话 → 仓库；提交（commit）；从 GitHub 拉取并合并（fetch + merge）；仓库 → 本机对话；推送（push）。

## 冲突时会怎样

- `docs/工作日志.md` 和 `claude/memory/MEMORY.md`：两边都加了行时，**两边的行都保留**（union 合并），不会报冲突。
- 对话记录：只有一边变了，就用变了的那一边；一边是另一边的续写，就用更长的那份；同一个会话在两台电脑上**都**继续了，就留本机这份，另一份放进 `claude\conflicts\`。**两份都不会丢。**
- 其他文件（docs、Matlab 代码、CLAUDE.md）在两边改了同一处：脚本会**停下来，不推送**，列出冲突的文件。可以对 Claude 说"帮我解决 git 合并冲突"，解决完再双击一次。不想合并了就运行 `git merge --abort`。
- **避免冲突的习惯：换电脑前先在旧电脑上收工同步，到新电脑上先开工同步。**

## 第一次在另一台电脑上（或者另一个账号）

1. 安装 Git：`winget install --id Git.Git -e`（或者从 git-scm.com 下载）。
2. 如果桌面上已经有 `PAM_controlProgram`（以前从 zip 还原的），先把它改名为 `PAM_controlProgram_old`。
3. 克隆（第一次会弹出浏览器让你登录 GitHub，**你自己登录**）：
   ```
   git clone https://github.com/<你的用户名>/<仓库名>.git "%USERPROFILE%\Desktop\PAM_controlProgram"
   ```
4. 运行一次安装脚本（会把桌面上的 Matlab 等换成 junction；原来的真实文件夹改名为 `*_before_git_<时间>`，不删除）：
   ```
   powershell -ExecutionPolicy Bypass -File "%USERPROFILE%\Desktop\PAM_controlProgram\docs\tools\setup_git_sync.ps1" -GitName "<名字>" -GitEmail "<邮箱>"
   ```
5. 用**你想用的那个账号**登录 Claude 桌面版，打开一次 Code 标签页，然后完全退出。
6. 双击 `sync_pam_sidebar.cmd`。再打开 Claude，Code 标签页里选 `PAM_controlProgram` 文件夹。

## 注意

- 仓库必须是 **Private**。里面有全部对话和实验数据。
- 硬件脚本（revised.m、test2.m、bscan_test.m）只在实验室电脑上运行。
- 单个文件超过 90 MB 不会上传（GitHub 的上限是 100 MB）。新出现的大数据文件（比如将来的 C-scan .mat）会被自动写进 `.git\info\exclude`，只留在本机，脚本会提示；这种文件用 OneDrive 或 U 盘传。测试数据要存在 `Matlab\` 下面（比如 `aline_data`、`bscan_data`），否则不会同步。
- 不放进仓库的东西：同学的 Control_py、AlazarTech SDK（版权不属于我们）。要用还是走 zip 包。
- 侧边栏是按账号存的（`claude-code-sessions\<账号>\<组织>\`）。脚本会写进 app **最近使用**的那个账号文件夹，不对的话可以加 `-SidebarFolder <文件夹>` 手动指定。**这不是官方的迁移功能，能不能正常显示待验证。** 就算侧边栏没显示，对话记录也已经在 `%USERPROFILE%\.claude\projects\` 里了。
- 现在项目文件夹是 Git 仓库了。在桌面版开新会话时，如果出现"在 worktree 里工作"之类的选项，选**直接在这个文件夹里工作**；否则记忆和对话会记到另一个文件夹下（待验证）。
- 两台电脑同时开着 Claude 写同一个会话，迟早会冲突。一个会话只在一台电脑上继续写。

## Mac（2026-10-04 新增，**尚未在 Mac 上实测**）

脚本：`docs/tools/pam_sync_mac.py`（Python 3，只用标准库），双击入口 `sync_pam.command` / `sync_pam_sidebar.command`，作用和 Windows 的 `.cmd` 一样。

**第一次（在终端里做）：**
1. 安装 Git 和 Python 3：`xcode-select --install`（会弹窗，点安装）。
2. 登录 GitHub（**你自己登录**）：推荐 `brew install gh`，然后 `gh auth login`。GitHub 不接受账号密码，需要用 gh 或者 Personal Access Token。
3. 克隆：`gh repo clone yumengchen8366/PAM_research ~/Desktop/PAM_controlProgram`
   - 如果开了"iCloud 云盘同步桌面与文稿"，就别放在桌面，改成 `~/PAM_controlProgram`。iCloud 和 git 一起用会把 `.git` 弄坏。脚本按自己所在的位置找仓库，放哪里都能用。
4. `python3 ~/Desktop/PAM_controlProgram/docs/tools/pam_sync_mac.py --setup --git-name "<名字>" --git-email "<邮箱>"`
   作用：设置 git，把 `~/.claude/projects/<项目>/memory` 做成指向 `claude/memory` 的符号链接，并给 `.command` 文件加上执行权限。
5. 双击 `sync_pam.command`。对话记录会进到 `~/.claude/projects/-Users-<你>-Desktop-PAM-controlProgram/`。
6. 想在桌面版侧边栏看到这些会话：先用 Claude 桌面版打开一次 Code 标签页，Cmd+Q 完全退出，再双击 `sync_pam_sidebar.command`。侧边栏数据在 `~/Library/Application Support/Claude/claude-code-sessions/`（Mac 上的位置和格式**待验证**）。也可以在终端里进入项目文件夹，运行 `claude --resume` 来接着某个会话聊。

**和 Windows 版不一样的地方：**
- 路径改写不能严格还原。`C:\Users\2031\...` 改成 `/Users/<你>/...` 以后，再改回来不一定一字不差（比如转义了两次的路径）。所以 Mac 版**从不整份改回**：它记住上次同步时两边的长度和哈希值，对话变长时只把**新加的几行**改写后追加到仓库那份的末尾。Windows 那边看到的就是"原文件 + 续写"。
- 对话历史里 Windows 路径的后半段仍然是反斜杠（比如 `/Users/<你>/Desktop/PAM_controlProgram\docs\x.md`），只是历史文字，不影响接着聊。Mac 上新写的内容同步回仓库后，会变成 `C:\Users\2031\Desktop\PAM_controlProgram/docs/x.md`，Windows 也认这种写法。
- 同步记录存在 `~/Library/Application Support/PAM_sync/`。
- 硬件脚本当然只能在实验室电脑上运行。Mac 上只用来读文档、改代码、做离线数据处理。
