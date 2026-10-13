---
name: project-bscan-1007
description: "B-scan (07 week 2, test signal) first worked 10/7 — trigger chain, results, what is left; details in docs/13"
metadata:
  node_type: memory
  type: project
  originSessionId: 70a4e53f-3e22-4e38-9207-5f7d1f6e294c
  modified: 2026-10-07T04:59:57.476Z
---

First real B-scan with a test signal ran 2026-10-07 (~01:00) with `Matlab/bscan_test.m`: 400/400 A-lines while the X stage moved at 4 mm/s, every record has the test pulse, edge std 1.84 ns. Full record in `docs/13_B-scan记录.md`; advisor figure `docs/figures/bscan_test_20261007.png`.

Test-time trigger chain: P0.6 → BNC-2110 USER 1 → DG852 Pro rear AUX IN/OUT of both channels (Burst NCycle 1, Ext Leading) → G1 → ATS TRIG IN, G2 (+2 µs, 200 ns, 1 V) → CH A. P0.6 can drive 50 Ω TRIG IN directly (2.84 V) but at ~57 mA, so the generator is kept in between.

**Why:** 07 week 2 commitment to the advisor; the 10/4 conclusion "red-ferrule wire ≈ P0.7" was void (scope probe 1X/10X mismatch).
**How to apply:** next B-scan session starts from docs/13 section 4–5 (tests ②③④⑥, STEP/P0.6 alignment, PFI3 count, design questions (a) continuous vs move-stop-trigger and (b) pre-posting all DMA buffers). Related: [[project-aline-ats9462]], [[project-sprint-1003-1004]], [[feedback-teach-dont-do]].
