---
name: project-two-computers-sync
description: User works on two computers with the same Claude account; Code-tab sessions were copied to the second PC via a snapshot package on 2026-10-03
metadata:
  node_type: memory
  type: project
  originSessionId: 624142b1-3204-4664-b7e7-e787919d6088
  modified: 2026-10-03T22:33:35.277Z
---

User wants all PAM conversations visible on both computers (lab PC with NI Dev1 + ATS9462, and a second PC, same Claude account). Code-tab sessions are local-only: transcripts in `%USERPROFILE%\.claude\projects\<slug>\`, sidebar entries in `%APPDATA%\Claude\claude-code-sessions\<acct>\<org>\local_*.json`. On 2026-10-03 a snapshot `Desktop\PAM_sync_2026-10-03.zip` (project + Matlab + New folder + memory + all 7 sessions + restore.ps1 that rewrites paths if the user folder differs) was made; Control_py (22 GB) was left out. Remote Control was turned on for all 7 sessions the same evening. Remote Control is per-session: the app setting `connect_new_sessions_to_remote_control` was unset, so a session started later that night came up with Remote Control off (user asked why). Fixed 2026-10-03: setting turned On on the lab PC, so new sessions there auto-connect; the second PC has its own setting (待确认).

**Why:** later conversations do not sync automatically; whether the second PC's sidebar shows copied sessions was 待确认 at the time.

**How to apply:** if running on the second PC, paths may differ from `C:\Users\2031\...` and hardware (Dev1, ATS9462) is not present — don't run hardware scripts there. For live viewing from the other PC, Remote Control on a session is the alternative; re-package to carry newer sessions.

Related: [[user-pam-phd-student]], [[project-aline-ats9462]]
