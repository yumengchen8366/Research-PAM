# Maria 的 control_py（参考用，不改）

Maria（组里同学）写的 Python 版扫描 + 采集程序。按**代码最后修改日期**分文件夹存快照，只作参考：不改 Maria 的代码，也不在本仓库里运行（路径写死为实验室电脑 `C:\Users\Caolab\...`；没有检查模式，一运行就会动 X/Y 电机、发 P0.7 激光触发）。

## 版本
| 文件夹 | 代码最后修改 | 来源 / 下载 | 主要内容 | 说明 |
|---|---|---|---|---|
| `2026-10-03/` | 10/3 | Drive `control_py`，10/5 下载 | 一套 C-scan：`unScan_TS.py`（DO）+ `TS_aq.py` / `TS_aq_stream.py`（ATS triggered streaming）+ `scriptControl_TS.py`（总控） | `2026-10-03/README.md` |
| `2026-10-08/` | 10/8 21:39 | Drive `control_py`，10/11 下载（`control_py-20261011T185333Z-1-001.zip`） | 拆成 A-line（NPT）/ B-line / C-scan 三套，加 `analysis/` 小工具；附数据检查结果 | `2026-10-08/README.md` |

另外：`docs/11_Control_py与hardware_timing.md` 讲的是实验室电脑上另一份更早的版本（`C:\Users\2031\Desktop\Control_py`，DO 5 kS/s、每行 0.42 s），没有存进这里。

## 每个版本存什么
- 存：`.py`、`.m`、`pyproject.toml`、`uv.lock`、`.python-version`、截图（有的话），保持 Maria 原来的子文件夹结构。
- 不存：`.venv/`（Windows 虚拟环境）、`__pycache__/`、`.vscode/`、`data/`（原始数据；10/8 版光分卷 1 就有 2.6 GB）。数据只在该版本的 README 里记文件夹名、大小和检查结果。
- 和代码一起下载到的无关文件不存（例如 10/11 同时下载的 Qualcomm NCM865 WiFi 驱动包）。

## 有新版本时怎么更新
1. 从 Drive 下载 `control_py`，解压到一个临时的空文件夹（不要解压进仓库）。
2. 看代码文件里最晚的修改日期，在这里新建同名文件夹 `YYYY-MM-DD/`，按上面"存什么"复制。
3. 和上一版对比：`diff -r 2026-10-08 <新文件夹>`；文件改了名的要手动配对着比。
4. 在新文件夹写 `README.md`：来源、文件结构、默认参数、相对上一版改了什么、问题、要问 Maria 的；然后在上面的版本表加一行。
5. 工作日志记一条，commit：`<日期> 参考代码: Maria control_py <代码日期> 版`，再双击 `sync_pam.command` 推到 GitHub。

在 Claude Code 里说"Maria 又发了新版 control_py，按 `06_控制程序/参考_Maria_control_py/README.md` 更新"，并给出 zip 的路径即可。
