---
name: feedback-teach-dont-do
description: "Teach step by step; user writes/edits the code themselves, Claude explains and reviews; one module per chat window"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 39b3883d-0ddf-4134-ab62-dfce64583718
  modified: 2026-10-03T19:34:30.808Z
---

Explain first, then let the user write or edit the code; Claude explains and checks. Don't edit their MATLAB files unless asked. They use a separate chat window per module.

**Why:** User must be able to read every parameter/line and modify the code alone later; advisor questions them on each parameter (trigger level, delay, filter, DMA).
**How to apply:** Point out problems with file:line and let them fix; give test procedures and checklists rather than finished code. Reading files/data is fine.

Related: [[user-pam-phd-student]]
