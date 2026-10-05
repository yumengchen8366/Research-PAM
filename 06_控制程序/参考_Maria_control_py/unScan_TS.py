# undirectional scan, one laser trigger per position, one DAQ trigger per row
# (the DAQ is armed once at the first position of a row and streams until the
# row is over, then it is re-armed on the next row)

import sys
from pathlib import Path
import numpy as np
import nidaqmx
from nidaqmx.constants import AcquisitionType, LineGrouping, SampleTimingType


# LINES
X_STEP_LINE = "Dev1/port0/line0"
X_DIR_LINE  = "Dev1/port0/line1"

Y_STEP_LINE = "Dev1/port0/line2"
Y_DIR_LINE  = "Dev1/port0/line3"

DAQ_LINE   = "Dev1/port0/line6"
LASER_LINE = "Dev1/port0/line7"

# PARAMETERS
REVOLUTION_MM = 4
STAGE_STEP = 4 / 200 # 360 / 1.8
MOONS = 1/4
PULSE_RATE = 1000.0 # time frequancy of sending timed signals by control card
MM_PER_MOTOR_STEP = MOONS * STAGE_STEP # driver microstep

X_MM_MOVE = 0.5 # total scan distance
Y_MM_MOVE = 0.5
X_MM_PER_POSITION = 0.01 # distance between scan positions
Y_MM_PER_POSITION = 0.01
X_PULSES_PER_POSITION = round(X_MM_PER_POSITION / MM_PER_MOTOR_STEP)
Y_PULSES_PER_POSITION = round(Y_MM_PER_POSITION / MM_PER_MOTOR_STEP)
X_STEPS = round(X_MM_MOVE / X_MM_PER_POSITION) # actual steps number3.


Y_STEPS = round(Y_MM_MOVE / Y_MM_PER_POSITION)
X_POSITIONS = X_STEPS # number of acquisition positions, one per step: the last
                      # step of a row has no trigger, it is the time to change X direction
Y_POSITIONS = Y_STEPS
TOTAL_POSITIONS = X_POSITIONS * Y_POSITIONS

# DIRECTIONS 
X_FORWARD = True # acquisition direction
X_REVERSE = not X_FORWARD
Y_FORWARD = True # Y direction

# OFFSET from them motor sequance for 1 step
TRIGGER_BLOCK_SAMPLES = 1 # samples during which the motor is hold still (time for DAQ + LASER)
LASER_TRIGGER_OFFSET  = 0
DAQ_TRIGGER_OFFSET    = 0

# Settle time for driver to change X DIR: the level is held this many samples
# before AND after the change, so a direction change is never right next to a step
DIR_SETUP_SAMPLES = 1

# the trigger only STARTS the laser burst and the DAQ record, both keep running
# after their edge. The laser burst must finish before the stage moves again.
# The DAQ record must NOT: it spans the whole row on purpose.
DAQ_TRIGGER_WIDTH_SAMPLES = 1 # width of the single arming pulse at the row start

# after the last row, go back to starting position
RETURN_TO_ORIGIN = False

# LASER BURST PARAMETERS
LASER_FREQ = 50_000
LASER_DURATION = 3 / PULSE_RATE # of waveform samples
LASER_PULSE = round(LASER_FREQ * LASER_DURATION)
LASER_BURST_SAMPLES = round(LASER_DURATION * PULSE_RATE)

# samples the motor waits after the laser trigger sample before the next step
# motor sequence around a position: 1,0,[laser],0,1 -> 1,0,0,0,1
MOTOR_WAIT_AFTER_LASER_SAMPLES = 1 

SAMPLES_PER_ROW = X_STEPS * ( 2 * X_PULSES_PER_POSITION + 2) # important DAQ parameter for sampling rate

# how long the stage stays parked: laser trigger sample + MOTOR_WAIT_AFTER_LASER_SAMPLES.
# The laser burst is NOT waited for any more, the next step starts while it may
# still be running. TRIGGER_BLOCK_SAMPLES is only the floor. The DAQ record is
# NOT part of this constraint, it is a single streaming record across the whole row.
ACQUIRE_BLOCK_SAMPLES = max(
    TRIGGER_BLOCK_SAMPLES,
    LASER_TRIGGER_OFFSET + 1 + MOTOR_WAIT_AFTER_LASER_SAMPLES,
    DAQ_TRIGGER_OFFSET + DAQ_TRIGGER_WIDTH_SAMPLES,
)

# one acquisition row = X_POSITIONS parked blocks + one move after each of them
ROW_ACQUIRE_SAMPLES = (
    X_POSITIONS * ACQUIRE_BLOCK_SAMPLES
    + X_STEPS * X_PULSES_PER_POSITION * 2
)

# how long the digitizer keeps streaming after the single arming edge of a row.
# By default exactly the row: the record is opened at the first position and
# closed after the last one. Make it longer if the digitizer needs a tail.
DAQ_ROW_RECORD_SAMPLES = ROW_ACQUIRE_SAMPLES

# nothing may move in Y (and no new row may be armed) before that record ended,
# so park at the end of the row for whatever is still missing
DAQ_ROW_TAIL_SAMPLES = max(0,DAQ_TRIGGER_OFFSET + DAQ_ROW_RECORD_SAMPLES - ROW_ACQUIRE_SAMPLES)

# waveform dump for inspection in MATLAB
SAVE_WAVEFORMS_TO = Path(__file__).resolve().parent / "Sequence_UnscanTS.mat"

# WAVEFORMS
x_step = []
x_dir = []
y_step = []
y_dir = []
laser = []
daq = []


def addSample(xStep, xDir, yStep, laserTrig, daqTrig, yDir=Y_FORWARD):
    """Append one sample to every line at once so the arrays stay in lock-step."""
    x_step.append(xStep)
    x_dir.append(xDir)
    y_step.append(yStep)
    y_dir.append(yDir)
    laser.append(laserTrig)
    daq.append(daqTrig)


def addIdle(nSamples, xDir):
    """Hold everything low for nSamples while keeping the X direction level."""
    for _ in range(nSamples):
        addSample(False, xDir, False, False, False)


def addXDirChange(oldDir, newDir, extraOldSamples=0):
    """Idle gap around an X direction change. The low sample of the last step
    pulse already counts as one hold sample with the old level, so only
    DIR_SETUP_SAMPLES - 1 more are added, then DIR_SETUP_SAMPLES with the new one.
    With DIR_SETUP_SAMPLES = 1: step 1,0,0,1 / dir old,old,new,new.
    extraOldSamples adds that many more idle samples with the old level just
    before the change, e.g. 1 -> step 1,0,0,0,1 / dir old,old,old,new,new."""
    addIdle(DIR_SETUP_SAMPLES - 1 + extraOldSamples, oldDir)
    addIdle(DIR_SETUP_SAMPLES, newDir)


def addXStepBurst(nPulses, xDir):
    """nPulses step pulses on X (10 per pulse). No laser, no DAQ while moving."""
    for _ in range(nPulses):
        addSample(True, xDir, False, False, False)
        addSample(False, xDir, False, False, False)


def addYStepBurst(nPulses, xDir):
    """nPulses step pulses on Y (10 per pulse), X held at its current direction."""
    for _ in range(nPulses):
        addSample(False, xDir, True, False, False)
        addSample(False, xDir, False, False, False)


def addTriggerBlock(xDir, armDaq=False):
    """Stage is parked: trigger the laser and hold still for
    MOTOR_WAIT_AFTER_LASER_SAMPLES more samples. No step pulse inside this block.
    armDaq=True additionally puts out the single DAQ arming pulse, which is only
    done on the first position of a row."""
    for i in range(ACQUIRE_BLOCK_SAMPLES):
        addSample(
            False,
            xDir,
            False,
            i == LASER_TRIGGER_OFFSET,
            armDaq and DAQ_TRIGGER_OFFSET <= i < DAQ_TRIGGER_OFFSET + DAQ_TRIGGER_WIDTH_SAMPLES,
        )


def buildUnidirectionalScan():
    # every row: trigger + step at each position (last step has no trigger, it
    # is the time to change X direction), fly back to the row start, then step Y
    # so X rests while Y moves before the next row
    addIdle(DIR_SETUP_SAMPLES, X_FORWARD) # 1 sample acquisition rows +X
    for row in range(Y_POSITIONS):

        # the DAQ is armed here and only here: one streaming record per row
        addTriggerBlock(X_FORWARD, armDaq=True) # first position of the row
        addXStepBurst(X_PULSES_PER_POSITION, X_FORWARD)
        for _ in range(X_POSITIONS - 1):
            addTriggerBlock(X_FORWARD) # positions 2 .. X_POSITIONS}
            addXStepBurst(X_PULSES_PER_POSITION, X_FORWARD)
        # last step done without trigger: stage is at the +X end of this row

        # ---- let the row-long DAQ record finish before anything else happens ----
        addIdle(DAQ_ROW_TAIL_SAMPLES, X_FORWARD)

        # ---- fly back the whole X range to the row start, no laser, no DAQ ----
        # 1 extra +X sample before the change: 3 idle samples between +X and -X moves
        addXDirChange(X_FORWARD, X_REVERSE, extraOldSamples=1)
        addXStepBurst(X_STEPS * X_PULSES_PER_POSITION, X_REVERSE)

        # ---- hand the X direction back to forward for the next row ----
        addXDirChange(X_REVERSE, X_FORWARD)

        if row < Y_POSITIONS - 1:
            # ---- X is back at the row start: step Y while X rests ----
            addYStepBurst(Y_PULSES_PER_POSITION, X_FORWARD)

    if RETURN_TO_ORIGIN:
        # X is already at the origin column after every row, only Y has to go back
        for _ in range(DIR_SETUP_SAMPLES): # Y direction settle
            addSample(False, X_FORWARD, False, False, False, yDir=not Y_FORWARD)
        for _ in range((Y_POSITIONS - 1) * Y_PULSES_PER_POSITION):
            addSample(False, X_FORWARD, True, False, False, yDir=not Y_FORWARD)
            addSample(False, X_FORWARD, False, False, False, yDir=not Y_FORWARD)
        addIdle(DIR_SETUP_SAMPLES, X_FORWARD)

buildUnidirectionalScan()

# ARRAY
ARRAY_LENGTH = len(x_step)
for _name, _wave in (("x_dir", x_dir), ("y_step", y_step), ("y_dir", y_dir), ("laser", laser), ("daq", daq)):
    if len(_wave) != ARRAY_LENGTH:
        print(f"arrays are not the same length: {_name} has {len(_wave)}, x_step has {ARRAY_LENGTH}")
        sys.exit(1)

# ARRAY
ARRAY_LENGTH = len(x_step)
for _name, _wave in (("x_dir", x_dir), ("y_step", y_step), ("y_dir", y_dir), ("laser", laser), ("daq", daq)):
    if len(_wave) != ARRAY_LENGTH:
        print(f"arrays are not the same length: {_name} has {len(_wave)}, x_step has {ARRAY_LENGTH}")
        sys.exit(1)

daq_triggers   = sum(1 for i in range(ARRAY_LENGTH) if daq[i] and not (i and daq[i - 1]))
laser_triggers = sum(1 for i in range(ARRAY_LENGTH) if laser[i] and not (i and laser[i - 1]))

# channel order must match the order the DO channels are added below
waveform_data = [x_step, x_dir, y_step, y_dir, daq, laser]
channel_lines = [X_STEP_LINE, X_DIR_LINE, Y_STEP_LINE, Y_DIR_LINE, DAQ_LINE, LASER_LINE]

waveform_duration = ARRAY_LENGTH / PULSE_RATE


# HARDWARE OUTPUT

if __name__ == "__main__":

    print(f"laser triggers: {laser_triggers} (expected {TOTAL_POSITIONS}, one per position)")
    print(f"daq triggers:   {daq_triggers} (expected {Y_POSITIONS}, one per row)")
    print(f"row record:     {DAQ_ROW_RECORD_SAMPLES} samples "
          f"= {DAQ_ROW_RECORD_SAMPLES / PULSE_RATE * 1e3:.2f} ms, "
          f"{X_POSITIONS} laser shots inside it")

    with nidaqmx.Task() as task:

        task.do_channels.add_do_chan(X_STEP_LINE,line_grouping=LineGrouping.CHAN_PER_LINE)
        task.do_channels.add_do_chan(X_DIR_LINE,line_grouping=LineGrouping.CHAN_PER_LINE)
        task.do_channels.add_do_chan(Y_STEP_LINE,line_grouping=LineGrouping.CHAN_PER_LINE)
        task.do_channels.add_do_chan(Y_DIR_LINE,line_grouping=LineGrouping.CHAN_PER_LINE)
        task.do_channels.add_do_chan(DAQ_LINE,line_grouping=LineGrouping.CHAN_PER_LINE)
        task.do_channels.add_do_chan(LASER_LINE,line_grouping=LineGrouping.CHAN_PER_LINE)

        task.timing.cfg_samp_clk_timing(rate=PULSE_RATE,sample_mode=AcquisitionType.FINITE,samps_per_chan=ARRAY_LENGTH)

        number_written = task.write(waveform_data,auto_start=False)

        print("Starting unidirectional scan...")

        task.start()
        task.wait_until_done(timeout=waveform_duration + 10.0)
        task.stop()

        # leave every line low
        task.timing.samp_timing_type = SampleTimingType.ON_DEMAND
        task.write([False] * len(channel_lines), auto_start=True)
        task.stop()

    print("Unidirectional scan finished.")

