---
name: project-two-computers-sync
description: "PAM project syncs across PCs AND Claude accounts via private GitHub repo yumengchen8366/PAM_research: sync_pam.cmd (+ _sidebar), junction layout; zip packages are fallback only"
metadata:
  node_type: memory
  type: project
  originSessionId: ec41eebc-31a0-448d-b552-0778ae4432dd
  modified: 2026-10-04T17:11:32.796Z
---

Since 2026-10-04 the user works on PAM from several PCs and from a second, personal Claude account (not the researchcaolab one). Everything goes through the private GitHub repo `https://github.com/yumengchen8366/PAM_research.git` (commit identity yumengchen8366 / yumengchen8366@users.noreply.github.com).

Layout on the lab PC (CAOLAB1): repo root = `Desktop\PAM_controlProgram`; `Matlab`, `New folder`, `System_test_09_25` live inside it with Desktop junctions; `~\.claude\projects\<slug>\memory` is a junction to `claude\memory` (so memory edits are committed directly). Transcripts/uploads/sidebar entries are copied by `docs\tools\pam_sync.ps1` to `claude\transcripts|uploads|desktop-sessions`, stored with canonical lab paths and rewritten per PC. `sync_pam.cmd` = export, commit, fetch+merge, import, push; `sync_pam_sidebar.cmd` adds -ImportSidebar (app must be quit) to put sessions in the sidebar of whichever account is signed in. `docs/工作日志.md` and MEMORY.md use merge=union. Git is per-user at `%LOCALAPPDATA%\Programs\Git` (not on PATH in old shells). The project folder is owned by Windows user "CAO LAB", so git needed safe.directory.

**Why:** the user wants one shared state wherever they work; Claude conversations themselves are account-bound, so knowledge must live in docs + memory files.

**How to apply:** remind the user to run sync_pam.cmd at the start and end of each window. Claude's own shell is non-interactive, so a push needing GitHub login must be run by the user. Pushing from Claude works only after credentials are cached. Unverified: whether the desktop sidebar shows imported sessions; whether new sessions in a git repo default to worktrees (would change memory path). Old zip scripts (make_sync_package.ps1/restore.ps1) remain as fallback for Control_py / ATS SDK which are not in GitHub. Hardware scripts only on the lab PC.

Mac (added 2026-10-04, untested): `docs/tools/pam_sync_mac.py` via `sync_pam.command` (`--setup` once; memory = symlink). It never round-trips whole files: it stores per-file hash+length of both sides and appends only new lines (path-rewritten) to the repo copy, because Windows→Mac path rewriting is not exactly reversible. Code-tab sessions are local, not tied to the claude.ai account.

Related: [[user-pam-phd-student]], [[project-aline-ats9462]]
