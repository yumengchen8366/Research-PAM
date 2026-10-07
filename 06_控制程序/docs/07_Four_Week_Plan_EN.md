# Four-Week Plan (Oct 5 – Nov 1, revised Oct 4)

As we discussed, this is my plan for the next four weeks, based on my own pace.

**Revision (Oct 4):** I finished all of the A-line tests that were planned for Week 1 between Oct 1 and Oct 4, and most of the X-axis motor calibration. So I moved the remaining modules one week earlier, and Week 4 is now a buffer week and a chance to test with a real signal.

## Goals
- **Done (Oct 1–4):** All A-line tests (trigger, time axis, delay, and amplitude for a single A-line, plus record counting and error handling when acquiring multiple A-lines), and the main part of the X-axis motor calibration.
- **Weeks 1–3:** Write my own first version of the B-scan and C-scan programs in MATLAB and validate them with a test signal.
  - Week 1: motor calibration (finish X, do Y) and scan timing
  - Week 2: B-scan
  - Week 3: C-scan (small area)
- **Week 4:** Buffer. If the optical setup is ready, do a B-scan / C-scan with a real photoacoustic signal (e.g., black tape). If not, do stability tests and finish the documentation.

## Time
- I plan to spend about 8 hours per week on the core tasks, plus up to 2 extra hours for unexpected problems.
- Exam weeks: to be added. If there is a conflict, I will tell you at the Monday meeting and reduce the scope for that week.

## Before starting (to confirm in Week 1)
- A motor power supply that stays at my setup, so I don't have to keep borrowing one back and forth with other students.
- Equipment: a two-channel function generator (with burst mode and an external trigger input), a two-channel oscilloscope, BNC cables, a BNC T-connector, a ruler (a dial gauge or a microscope with a scale would be better), and a screwdriver (to read the driver DIP switches and wire the counter loopback).
- Before running MATLAB, I will close any other program that is using the NI card or the ATS9462. The laser will stay off during Weeks 1–3, and all tests will use test signals.

---

## Done: All A-line tests (Oct 1–4)

Highlights (full results in my A-line test summary):

| Test | Result |
|---|---|
| 1.1 Trigger | With a trigger, one run gives one record. Without a trigger, it times out after about 5 s with an error, returns no fake data, and can run again. TRIG IN measures about 50 Ω. The measured threshold for trigger level code 150 is 0.8–0.9 V, which matches the calculated 0.87 V for the ±5 V range. |
| 1.2 Time axis and delay | About 10 records each at 1 µs and 3 µs: the difference is 1.9997 µs (359.94 samples; expected 360), with a repeatability of 0.8 / 1.8 ns. It agrees with the oscilloscope's measured difference to within about 10 ns. Setting the digitizer's own trigger delay to 180 samples shifts the window by exactly 1 µs. |
| 1.3 Amplitude and range | 200 mV signal: 206.4 mV measured on the ±4 V range, 203.2 mV on the ±0.4 V range, no clipping. Turning on the bandwidth limit slows the edge but does not reduce the noise, so I keep it off. |
| 1.4 Multiple A-lines | 100 triggers → 100 records. 95 triggers → 90 records, with a report that buffer 10 timed out, and the received records are still saved. No triggers → clean timeout. 1000 triggers at 10 kHz and at 100 kHz → 1000 / 1000. |
| Extra | Triggering the ATS from the real laser through the photodiode works: it triggers with light and times out when the light is blocked. |

**X-axis calibration (originally 2.1) is also mostly done (Oct 4):** the SR2 driver is set to 4000 steps per revolution, which gives 0.5 µm/pulse (20,000 pulses = 10 mm). The direction is confirmed. Starting without acceleration works up to about 4 mm/s; at 5 mm/s the motor stalls.

---

## Week 1 (Oct 5–11): Motor calibration and scan timing

### 1.1 Finish the X axis
| Item | Details |
|---|---|
| Tests | ① Use a counter loopback (P0.0 also wired to PFI3) to count the pulses that were actually sent. ② Measure a 10 mm move with a ruler (or dial gauge), 3 times in each direction. ③ Read the driver DIP switches and compare them with the measured 4000 steps/rev. |
| Already confirmed | 0.5 µm/pulse; direction; speed limit without acceleration about 4 mm/s |
| Still to confirm | Backlash between forward and backward moves; wait time after changing direction; minimum pulse width; safe travel range (the limit switches are not connected, so I will add software limits) |
| Pass criteria | The count equals the commanded number of pulses, and the displacement matches the calculated value |

### 1.2 Y-axis calibration
- First confirm the Y-axis wiring (P0.2 STEP, P0.3 DIR) and the DIP switches on the Y driver, then repeat the X-axis steps (steps per revolution, µm/pulse, direction, speed limit, pulse count).
- I will not reuse the X-axis conversion factor for Y.

### 1.3 Acquisition trigger line P0.6
| Item | Details |
|---|---|
| Problem | P0.6 is not connected to the ATS right now. TRIG IN is 50 Ω, so I need to measure whether the NI digital output gives a high enough level into a 50 Ω load. |
| Test | Look at the high level of P0.6 on the oscilloscope while it drives TRIG IN. It should be clearly above 0.87 V. |
| Backup plan | If the level is too low: connect P0.6 to the external trigger input of the function generator (high impedance), and let the function generator send the trigger to TRIG IN. This is the same setup I will use for the Week 2 test signal anyway. |
| Pass criteria | Each pulse on P0.6 gives one trigger on the ATS |

### 1.4 My scan timing (first version: move – stop – trigger)
| Item | Details |
|---|---|
| Design | All actions go into one timing table that runs on the hardware clock: trigger at position 1 → move Δx → wait to settle → trigger → … So N positions = 1 starting position + (N−1) moves. |
| Parameters to confirm | Timing clock (up to 250 kS/s with the MATLAB approach); step frequency (speed ≤ 4 mm/s); pulses per position (Δx ÷ 0.5 µm); settling time; trigger pulse width; acquisition trigger line P0.6; laser trigger line P0.7 (kept at 0) |
| Tests | ① Generate the table offline, and have the program check that the number of triggers equals the number of positions and that the number of pulses between triggers matches Δx. Also compute the total time. ② Output it on the hardware, look at P0.0 and P0.6 on the oscilloscope, and count the triggers with a counter. |
| Pass criteria | Both the calculated values and the measurements match |

### What I will show for Week 1
- X and Y calibration tables
- Timing plot (zoomed in on the first few positions)
- Oscilloscope screenshots
- Trigger count results

---

## Week 2 (Oct 12–18): B-scan (X direction, test signal)

**Test signal:** P0.6 goes to both the ATS TRIG IN and the external trigger input of the function generator (through a BNC T-connector; if 1.3 shows the level is too low, I will use P0.6 → function generator → TRIG IN instead). Each time the function generator gets a trigger, CH2 outputs a pulse with a fixed delay into CH A. So every record should contain this pulse, which shows that every acquisition matches a real trigger.

| Item | Details |
|---|---|
| Workflow | Arm the ATS for N records → output the whole timing sequence → collect the data → record k corresponds to position k → save → display the B-scan (position on the horizontal axis, time on the vertical axis) |
| Parameters to confirm | Number of positions N (start with 10–20); Δx; moving speed; settling time; 1 record per position; record length; records per buffer; timeout |
| What will be saved | Raw data, conversion parameters, the commanded position of each record (labeled as commanded, not measured), time axis, all parameters, date, and a "test signal" label |
| Tests | ① Number of records = number of positions, and every record contains the test pulse ② Measure the final stage position: it should be start + (N−1)·Δx ③ Reload the saved file and reproduce the same plot ④ Stop in the middle: the program exits cleanly and reports how many positions were finished ⑤ Unplug the trigger cable: it times out with an error and cleans up ⑥ Repeat 3 times with the same settings, then once with a different N or Δx |
| Pass criteria | ①–⑥ all pass |

### What I will show for Week 2
- B-scan image
- Data file
- Test log
- A short user guide

---

## Week 3 (Oct 19–25): C-scan (small area, test signal)

| Item | Details |
|---|---|
| Design | Each row is one B-scan from Week 2, timed by the hardware. Between rows, the program controls the motion: X returns to the start of the row → Y moves Δy → the next row starts. I will start with a unidirectional scan. |
| Parameters to confirm | Number of rows Ny; Δy; Y speed; X return speed; wait time between rows; data layout (time × X × Y) |
| Tests | ① Start with 10 × 10 positions; total records = Nx × Ny ② Measure the positions of the four corners ③ Make a maximum amplitude projection (MAP) image ④ Reload the saved data ⑤ Stopping in the middle and missing triggers are both handled cleanly, and the program reports which row it stopped at ⑥ Return to the starting position at the end |
| Note | With a test signal, the MAP image should look uniform, which is expected. The position mapping will be checked with the record counts and the position measurements. |
| Pass criteria | ①–⑥ all pass |

### What I will show for Week 3
- C-scan data and MAP image
- Test log
- User guide

---

## Week 4 (Oct 26 – Nov 1): Buffer and real signal

- If an earlier module is delayed, I will finish it this week, so the C-scan is still done no later than in the original plan (Nov 1).
- **If the optical setup is ready:** do a B-scan with a real photoacoustic signal on black tape, then one small C-scan. Triggering the ATS from the laser through the photodiode already worked on Oct 4.
- **If it is not ready:** stability tests (repeat scans with the same settings, a larger area, higher speed within the limit) and finish the user guide.

### What I will show for Week 4
- Real-signal B-scan / C-scan images (if done), or the stability test log
- A list of questions for the next stage (real signal, continuous scanning, speed)

---

## Risks and adjustments
- The C-scan depends on the Week 2 B-scan. If the B-scan is delayed, the C-scan moves to Week 4, which is still the same finish date as the original plan.
- The Y-axis wiring and DIP switches have not been checked yet, and the P0.6 level has not been measured. These two may take a large part of Week 1. If Week 1 runs out of time, I will move the hardware check of the timing to the beginning of Week 2.

## Questions for you
1. **Timing for the first version:** Within each row, I plan to use hardware-timed "move – stop – trigger," and do a continuous-motion version later. Is this OK?
2. **First version of the C-scan:** Each row is timed by the hardware, and the program controls the moves between rows. Is this OK?
3. **A-line acceptance:** The delay difference is off by about 0.3 ns (1.9997 µs vs. 2 µs), the repeatability is 1–2 ns, and it agrees with the oscilloscope to within about 10 ns. Is this acceptable?
4. **Real signal:** Is it OK to validate the first versions of the B-scan and C-scan with a test signal? If the optical setup is ready in Week 4, what sample should I use?
