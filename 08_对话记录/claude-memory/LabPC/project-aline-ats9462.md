---
name: project-aline-ats9462
description: A-line MATLAB scripts live in C:\Users\2031\Desktop\Matlab (outside the project folder); facts about the 2026-10-01 saved data
metadata:
  node_type: memory
  type: project
  originSessionId: 39b3883d-0ddf-4134-ab62-dfce64583718
  modified: 2026-10-03T23:24:00.935Z
---

A-line scripts: `C:\Users\2031\Desktop\Matlab\ats9462_aline_once.m` (1024 pts, saveData=true) and `ats9462_aline_test_revised.m` (512 pts, saveData=false, comments at lines 32–34/54 etc. don't match code). Data: `C:\Users\2031\Desktop\Matlab\aline_data\` — 6 files from 2026-10-01 were made with aline_once.m: 1024 pts / 5.689 µs, 180 MS/s, level code 150, 1 MHz continuous square wave; ±0.4 V and ±2 V runs clipped, ±4 V not. Edge phase repeated within each setting (trigger locked).

Advisor's W1 (10/5–10/11) A-line check: generator CH1 = trigger, CH2 = signal, synced with a fixed delay; ATS-measured delay must match the set delay; cross-check with oscilloscope. Advisor also asks about trigger level meaning, filter (BW limit), DMA settings.

2026-10-03 lab results (A-line 1.1–1.3 all passed; details in docs/09 tables): TRIG IN measured ≈50 Ω (not 1 MΩ as a web datasheet snippet said) → generator CH1 Imped = Load; level code 150 threshold confirmed between 0.6–1.2 V; delay step 2 µs measured 1.9997 µs, jitter 1–2 ns, ATS ≈70 ns earlier than scope (fixed offset); ±4 V range zero offset ≈ −2.9 mV. Instruments: RIGOL DG852 Pro (changing Imped rescales display, not output) and DS1054Z (1 MΩ only). revised.m now 1024 pts, saveData=true, has cfg.note.

Full advisor meeting transcript and 4-week plan are in the Code-tab session "PAM导师会谈整理与四周计划" (readable with list_events).

MATLAB R2024b is installed (`C:\Program Files\MATLAB\R2024b\bin\matlab.exe -batch` works for read-only .mat inspection). SDK guide: `C:\AlazarTech\ATS-SDK\23.3.0\ATS-SDK-Guide.pdf` (no PDF renderer on this PC).

Related: [[user-pam-phd-student]]
