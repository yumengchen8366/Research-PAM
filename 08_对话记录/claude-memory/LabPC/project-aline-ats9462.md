---
name: project-aline-ats9462
description: A-line (ATS9462) module is DONE as of 2026-10-04 — summary in docs/10; code in PAM_controlProgram\Matlab; key measured facts and open items
metadata:
  node_type: memory
  type: project
  originSessionId: feb01eef-b2c2-40e2-a447-45d5e4384744
  modified: 2026-10-05T01:16:48.887Z
---

A-line module (plan docs/07 week 1, 1.1–1.4) finished 2026-10-04, ahead of the 10/5–10/11 schedule. Full summary: `docs/10_A-line测试总结.md`; raw per-file settings in docs/09 parts 3–4. Code in `PAM_controlProgram\Matlab\` (Desktop\Matlab is a junction): `ats9462_aline_test_revised.m` (single record, TRIG IN, 180 MS/s, 1024 pts, cfg.note), `aline_edge_time.m`, `analyze_delay_1003.m`, `ats9462_multi_aline.m` (NPT 10×10, 4-buffer ring, keeps full buffers on timeout; `(N)` = offline sim). Analysis code / param table / multi script were written by Claude at the user's request.

Measured facts: TRIG IN ≈50 Ω; threshold 0.8–0.9 V (ETR_5V, code 150 ≈ 0.87 V); delay step 2 µs → 1.9997 µs, jitter 1–2 ns, ATS ≈70 ns earlier than scope; trigger delay 180 samples shifts window 1.0018 µs; BW limit slows edge 17→24 ns, noise unchanged; multi-record 1000/1000 at 100 kHz; real laser NPL45C (ext trigger only, 0.2–2 V, ≤50 kHz) + photodiode PDA10A2 → TRIG IN works (blocked light → timeout). LabVIEW Main defaults: trigger source **Chan_B** (photodiode, level 144 ≈ 0.5 V), CH1 ±200 mV, 100 MS/s, Trig Delay 3.5 µs.

Open: CH B trigger mode untested; real transducer signal on CH A not yet; P0.6→50 Ω TRIG IN drive level and P0.7→laser (5 V vs ≤2 V spec) unverified; original P0.6/P0.7 wiring currently disconnected (ask Maria); "terminal 7" probably P0.7 (confirm with advisor). Next module: motor calibration, then timing, then B-scan (week 3).

Advisor meeting transcript + 4-week plan: Code-tab session "PAM导师会谈整理与四周计划". MATLAB R2024b `-batch` works for read-only .mat checks on the lab PC.

Related: [[user-pam-phd-student]], [[project-two-computers-sync]]
