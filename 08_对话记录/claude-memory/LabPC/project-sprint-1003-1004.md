---
name: project-sprint-1003-1004
description: "10/3 evening + 10/4 lab-day sprint (A-line tests, motor calibration, analysis code); checklist and fallback deliverables in docs/09"
metadata:
  node_type: memory
  type: project
  originSessionId: 595d5304-88bb-4eaa-a874-33f8cdfa76d3
  modified: 2026-10-05T02:36:08.257Z
---

User planned a two-day push before Week 1 (10/5) officially starts. Split (updated 10/3): 10/3 ~2 h in the lab doing all A-line tests (all instruments available in the lab; none at home), 10/4 motor work; analysis code and parameter table can be done at home since they need no hardware. The A-line work itself happens in the session "A-line 代码参数确认". Goal: finish A-line tests 07 §1.1–1.3 (1.4 if time), X-motor calibration (DIP switches, one-rev test for 0.5 vs 0.25 µm/pulse, direction, pulse count), and their own edge-finder analysis code. Checklist, record tables, reference edge times from the 10/1 data, and the priority order of fallback deliverables are in `docs/09_两天冲刺清单_1003-1004.md`.

**Why:** user wants something deliverable to the advisor even if not everything finishes, and wants everything written down so they can look it up from the other PC.

**How to apply:** in a new window, check docs/09 checkboxes/tables and the last 工作日志 entry to see what got done; CAOLAB1 has both ATS9462 and PCIe-6323 installed, so no-trigger timeout tests and motor-unpowered pulse counting need no instruments.

Status 10/4 evening: A-line done; X-motor calibration done (results in docs/01, 05, 09 part 2). Left open: pulse-count check via PFI3, caliper 3x, reading SR2 SW1–8. User wants to move straight to B-scan next (new window).

Related: [[project-aline-ats9462]], [[feedback-teach-dont-do]], [[project-two-computers-sync]]
