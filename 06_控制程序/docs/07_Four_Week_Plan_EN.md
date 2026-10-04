# Four-Week Plan (Oct 5 – Nov 1)

As we discussed, this is my plan for the next four weeks, based on my own pace.

## Goals
- **Week 1:** Finish all A-line tests: trigger, time axis, delay, and amplitude for a single A-line, plus record counting and error handling when acquiring multiple A-lines.
- **Weeks 2–4:** Write my own first version of the B-scan and C-scan programs in MATLAB and validate them with a test signal.
  - Week 2: motor calibration and scan timing
  - Week 3: B-scan
  - Week 4: C-scan (small area)
- Imaging with a real photoacoustic signal (e.g., black tape) will come after these four weeks. If the optical setup is ready earlier, I can do a short test with a real signal before then.

## Time
- I plan to spend about 8 hours per week on the core tasks, plus up to 2 extra hours for unexpected problems. Week 1 has all of the A-line tests, so it will probably take about 10 hours.
- Exam weeks: to be added. If there is a conflict, I will tell you at the Monday meeting and reduce the scope for that week.

## Before starting (to confirm in Week 1)
- A motor power supply that stays at my setup, so I don't have to keep borrowing one back and forth with other students.
- Equipment: a two-channel function generator (with burst mode and an external trigger input), a two-channel oscilloscope, BNC cables, a BNC T-connector, and a ruler (a dial gauge or a microscope with a scale would be better).
- Before running MATLAB, I will close any other program that is using the NI card or the ATS9462. The laser will stay off during Weeks 1–4, and all tests will use test signals.

---

## Week 1 (Oct 5–11): All A-line tests

**Setup:**
- Function generator CH1 sends trigger pulses → ATS9462 TRIG IN
- Function generator CH2 outputs a "fake signal" (a short pulse, e.g., 100 ns wide) → ATS9462 CH A
- The two channels are synchronized, and CH2 has a fixed delay relative to CH1
- The oscilloscope monitors CH1 and CH2 at the same time as a reference

**Note:** For these tests I will change the record length to 1024 samples (a 5.69 µs window at 180 MS/s). The current code uses 512 samples (2.84 µs), which leaves too little room for testing different delays.

### 1.1 Trigger check
| Item | Details |
|---|---|
| Tests | ① With the trigger on, one run gives one record. ② With CH1 turned off, the program should report an error and exit after the timeout, instead of returning fake data. ③ After it exits, I can run it again without restarting MATLAB. |
| Parameters to confirm | Trigger source = external (TRIG IN); slope = rising edge; trigger level code 150 (about 0.87 V threshold with the ±5 V external trigger range); external trigger coupling = DC; auto-trigger timeout = 0 (no auto trigger); host wait timeout = 5000 ms |
| To look up | The input impedance of TRIG IN (in the ATS9462 manual), so that the voltage at TRIG IN is clearly above 0.87 V but stays within ±5 V |
| Pass criteria | ①, ②, and ③ are all true |

### 1.2 Time axis and delay
| Item | Details |
|---|---|
| Tests | Set two delays for CH2 relative to CH1 (e.g., 1 µs and 3 µs) and take 10 records for each. Find the pulse position in each record, convert it to time, and compare it with the delay measured on the oscilloscope. |
| Parameters to confirm | Sampling rate 180 MS/s (5.56 ns per sample); record length (a multiple of 32 and ≥ 256); pre-trigger samples = 0 (NPT mode); digitizer trigger delay = 0; time axis t = sample index / sampling rate |
| What I will record | Mean and standard deviation of the pulse position for each delay; the difference between the two delays (2 µs should be about 360 samples); the difference from the oscilloscope reading |
| Pass criteria | The pulse position moves with the delay by the expected amount, and the jitter over 10 repeats is small. I would like to decide the acceptable error with you based on the measured data, instead of assuming a number in advance. |

### 1.3 Amplitude and input range
| Item | Details |
|---|---|
| Tests | Output a known amplitude on CH2 (e.g., 200 mVpp) and compare the voltage calculated in MATLAB with the oscilloscope reading. Test once with the ±400 mV range and once with the ±4 V range. |
| Parameters to confirm | Input range; input impedance 50 Ω (the function generator load setting also needs to be 50 Ω, otherwise the displayed amplitude will be off by a factor of 2); DC coupling; bandwidth limit off; the formula for converting raw codes to volts |
| Pass criteria | The calculated amplitude matches the oscilloscope, and no samples hit the edge of the range (number of clipped samples = 0) |

### 1.4 Multiple A-lines (N records in one acquisition)
| Item | Details |
|---|---|
| Tests | ① Arm the ATS first, then let CH1 send exactly 100 triggers in burst mode (1 kHz). The program should return 100 records, with the pulse at the same position in each one. ② Send only 95 triggers: the program should report "90 complete records received, buffer 10 timed out" and then exit cleanly. ③ Send no triggers: it should time out and exit. ④ It can run again after exiting. |
| Parameters to confirm | Records per buffer (e.g., 10); number of buffers (e.g., 10); total records (100); bytes per buffer; number of DMA buffers posted in advance; timeout; NPT mode flag |
| Pass criteria | The number of records equals the number of triggers, no more and no less. When triggers are missing, the program reports how many are missing and cleans up properly. |

### What I will show for Week 1
- Plots and a data table for the delay test
- Amplitude comparison
- A table of trigger count vs. record count
- An A-line parameter table: what each parameter means, its current value, why it is set that way, and what happens if it changes

**If I have extra time:** use the photodiode as the trigger; increase the burst to 1000 triggers, or try 10 kHz.

---

## Week 2 (Oct 12–18): Motor calibration and scan timing

### 2.1 X-axis calibration
| Item | Details |
|---|---|
| Preparation | Take a photo of the DIP switches on the X-axis driver (SR2) and find the steps per revolution in the manual; confirm that STEP is connected to P0.0, DIR to P0.1, and STEP−/DIR− to ground; move the stage to the middle of its travel range |
| Tests | ① Send 20,000 pulses at 1 mm/s and measure the displacement with a ruler. At 0.5 µm/pulse it should move 10 mm, and at 0.25 µm/pulse it should move 5 mm, so this tells me the microstep setting. ② Use a counter loopback (P0.0 also wired to PFI3) to count the pulses that were actually sent. ③ Repeat 3 times in each direction. |
| Parameters to confirm | Steps per revolution (microstepping); distance per pulse (µm/pulse); which direction DIR = high means; step frequency and speed limit (≤ 20 mm/s); wait time after changing direction; whether the driver steps on the rising or falling edge of STEP (from the SR2 manual); minimum pulse width; safe travel range |
| Pass criteria | The count equals the commanded number of pulses, and the displacement matches the calculated value. I will also record the backlash between forward and backward moves. |

### 2.2 Y-axis calibration
- First confirm the Y-axis wiring (P0.2 STEP, P0.3 DIR) and the DIP switches on the Y driver, then repeat the steps in 2.1.
- I will not reuse the X-axis conversion factor for Y.

### 2.3 My scan timing (first version: move – stop – trigger)
| Item | Details |
|---|---|
| Design | All actions go into one timing table that runs on the hardware clock: trigger at position 1 → move Δx → wait to settle → trigger → … So N positions = 1 starting position + (N−1) moves. |
| Parameters to confirm | Timing clock (up to 250 kS/s with the MATLAB approach); step frequency; pulses per position (Δx ÷ distance per pulse); settling time; trigger pulse width; acquisition trigger line P0.6; laser trigger line P0.7 (kept at 0) |
| Tests | ① Generate the table offline, and have the program check that the number of triggers equals the number of positions and that the number of pulses between triggers matches Δx. Also compute the total time. ② Output it on the hardware, look at P0.0 and P0.6 on the oscilloscope, and count the triggers with a counter. |
| Pass criteria | Both the calculated values and the measurements match |

### What I will show for Week 2
- X and Y calibration tables
- Timing plot (zoomed in on the first few positions)
- Oscilloscope screenshots
- Trigger count results

---

## Week 3 (Oct 19–25): B-scan (X direction, test signal)

**Test signal:** P0.6 goes to both the ATS TRIG IN and the external trigger input of the function generator (through a BNC T-connector). Each time the function generator gets a trigger, CH2 outputs a pulse with a fixed delay into CH A. So every record should contain this pulse, which shows that every acquisition matches a real trigger.

| Item | Details |
|---|---|
| Workflow | Arm the ATS for N records → output the whole timing sequence → collect the data → record k corresponds to position k → save → display the B-scan (position on the horizontal axis, time on the vertical axis) |
| Parameters to confirm | Number of positions N (start with 10–20); Δx; moving speed; settling time; 1 record per position; record length; records per buffer; timeout |
| What will be saved | Raw data, conversion parameters, the commanded position of each record (labeled as commanded, not measured), time axis, all parameters, date, and a "test signal" label |
| Tests | ① Number of records = number of positions, and every record contains the test pulse ② Measure the final stage position: it should be start + (N−1)·Δx ③ Reload the saved file and reproduce the same plot ④ Stop in the middle: the program exits cleanly and reports how many positions were finished ⑤ Unplug the trigger cable: it times out with an error and cleans up ⑥ Repeat 3 times with the same settings, then once with a different N or Δx |
| Pass criteria | ①–⑥ all pass |

### What I will show for Week 3
- B-scan image
- Data file
- Test log
- A short user guide

---

## Week 4 (Oct 26 – Nov 1): C-scan (small area, test signal)

| Item | Details |
|---|---|
| Design | Each row is one B-scan from Week 3, timed by the hardware. Between rows, the program controls the motion: X returns to the start of the row → Y moves Δy → the next row starts. I will start with a unidirectional scan. |
| Parameters to confirm | Number of rows Ny; Δy; Y speed; X return speed; wait time between rows; data layout (time × X × Y) |
| Tests | ① Start with 10 × 10 positions; total records = Nx × Ny ② Measure the positions of the four corners ③ Make a maximum amplitude projection (MAP) image ④ Reload the saved data ⑤ Stopping in the middle and missing triggers are both handled cleanly, and the program reports which row it stopped at ⑥ Return to the starting position at the end |
| Note | With a test signal, the MAP image should look uniform, which is expected. The position mapping will be checked with the record counts and the position measurements. |
| Pass criteria | ①–⑥ all pass |

### What I will show for Week 4
- C-scan data and MAP image
- Test log
- User guide
- A list of questions for the next stage (real signal, continuous scanning, speed)

**If I have extra time:** when the optical path is ready, do one B-scan with a real signal on black tape.

---

## Risks and adjustments
- The C-scan depends on the Week 3 B-scan. If the B-scan is delayed, I will finish validating the B-scan first in Week 4 and test the C-scan in simulation without the motor.
- Week 1 has a lot of tests. If there is not enough time that week, I will move 1.4 (multiple A-lines) to the beginning of Week 2.

## Questions for you
1. **Timing for the first version:** Within each row, I plan to use hardware-timed "move – stop – trigger," and do a continuous-motion version later. Is this OK?
2. **First version of the C-scan:** Each row is timed by the hardware, and the program controls the moves between rows. Is this OK?
3. **Acceptance criteria:** For the A-line, how much delay error and how much jitter would be acceptable?
4. **Real signal:** Is it OK to validate the first versions of the B-scan and C-scan with a test signal? When should I switch to a real photoacoustic signal, and what sample should I use?
