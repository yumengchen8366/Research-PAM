# script for triggered streaming B line

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

# LASER PARAMETERS
LASER_FREQ = 50_000

# PARAMETERS
REVOLUTION_MM = 4
STAGE_STEP = 4 / 200 # 360 / 1.8 = 200
MOONS = 1/4
SAMPLE_RATE = 1000.0 # time frequancy of sending timed signals by control card
X_MM_MOVE = 0.5 # total scan distance
X_MM_PER_POSITION = 0.01 # distance between scan positions

X_POSITIONS = round(X_MM_MOVE / X_MM_PER_POSITION) 
TOTAL_POSITIONS = X_POSITIONS
MM_PER_MOTOR_STEP = MOONS * STAGE_STEP # driver microstep
X_PULSES_PER_POSITION = round(X_MM_PER_POSITION / MM_PER_MOTOR_STEP)
X_SAMPLES_PER_POSITION = round(X_MM_PER_POSITION / MM_PER_MOTOR_STEP)
X_STEPS = round(X_MM_MOVE / X_MM_PER_POSITION) # actual steps number.

# DIRECTIONS
X_FORWARD = True # acquisition direction
X_REVERSE = not X_FORWARD
Y_FORWARD = True # Y is not moved in a B line, its direction line is just held at this level

# OFFSETS 
TRIGGER_BLOCK_SAMPLES = 1 # samples during which the motor is hold still after laser trigger 
LASER_TRIGGER_OFFSET  = 0
DAQ_TRIGGER_OFFSET    = 0
DIR_SETUP_SAMPLES = 1 # samples before change of direction
DAQ_TRIGGER_WIDTH_SAMPLES = 1 # width of the single arming pulse at the row start
MOTOR_WAIT_AFTER_LASER_SAMPLES = 1 # samples the motor waits after the laser trigger sample before the next step
ACQUIRE_BLOCK_SAMPLES = max(TRIGGER_BLOCK_SAMPLES, LASER_TRIGGER_OFFSET + 1 + MOTOR_WAIT_AFTER_LASER_SAMPLES, DAQ_TRIGGER_OFFSET + DAQ_TRIGGER_WIDTH_SAMPLES)

DAQ_ACQUIRE_SAMPLES = X_STEPS * ( 2 * X_PULSES_PER_POSITION + 2) # important DAQ parameter for sampling rate
DAQ_ROW_TAIL_SAMPLES = DAQ_TRIGGER_OFFSET # possible additional samples for daq without movement if needed

# after the line, move X back to the starting position
RETURN_TO_ORIGIN = True

# WAVEFORMS
x_step = []
x_dir = []
y_step = []
y_dir = []
laser = []
daq = []

def addSample(xStep, xDir, yStep, laserTrig, daqTrig, yDir=Y_FORWARD):
    x_step.append(xStep)
    x_dir.append(xDir)
    y_step.append(yStep)
    y_dir.append(yDir)
    laser.append(laserTrig)
    daq.append(daqTrig)

def addIdle(nSamples, xDir):
    # hold everything low for nSamples while keeping the X direction level
    for _ in range(nSamples):
        addSample(False, xDir, False, False, False)

def addXDirChange(oldDir, newDir, extraOldSamples=0):
    # x direction change
    addIdle(DIR_SETUP_SAMPLES - 1 + extraOldSamples, oldDir)
    addIdle(DIR_SETUP_SAMPLES, newDir)

def addXStepBurst(nPulses, xDir):
    # nPulses step pulses on X
    for _ in range(nPulses):
        addSample(True, xDir, False, False, False)
        addSample(False, xDir, False, False, False)


def addTriggerBlock(xDir, armDaq=False):
    for i in range(ACQUIRE_BLOCK_SAMPLES):
        addSample(False, xDir,False,i == LASER_TRIGGER_OFFSET,armDaq and DAQ_TRIGGER_OFFSET <= i < DAQ_TRIGGER_OFFSET + DAQ_TRIGGER_WIDTH_SAMPLES)

def buildBLine():
    # one row of the C scan: Y stays where it is, only X moves
    addIdle(DIR_SETUP_SAMPLES, X_FORWARD)

    addTriggerBlock(X_FORWARD, armDaq=True) # first position of the line
    addXStepBurst(X_PULSES_PER_POSITION, X_FORWARD)
    for _ in range(X_POSITIONS - 1):
        addTriggerBlock(X_FORWARD)
        addXStepBurst(X_PULSES_PER_POSITION, X_FORWARD)

    # last step done without trigger
    addIdle(DAQ_ROW_TAIL_SAMPLES, X_FORWARD)

    if RETURN_TO_ORIGIN:
        addXDirChange(X_FORWARD, X_REVERSE, extraOldSamples=1) # go back the whole X range
        addXStepBurst(X_STEPS * X_PULSES_PER_POSITION, X_REVERSE)
        addXDirChange(X_REVERSE, X_FORWARD)

buildBLine()

# ARRAY
ARRAY_LENGTH = len(x_step)
for _name, _wave in (("x_dir", x_dir), ("y_step", y_step), ("y_dir", y_dir), ("laser", laser), ("daq", daq)):
    if len(_wave) != ARRAY_LENGTH:
        print(f"arrays are not the same length: {_name} has {len(_wave)}, x_step has {ARRAY_LENGTH}")
        sys.exit(1)

daq_triggers   = sum(1 for i in range(ARRAY_LENGTH) if daq[i] and not (i and daq[i - 1]))
laser_triggers = sum(1 for i in range(ARRAY_LENGTH) if laser[i] and not (i and laser[i - 1]))
waveform_data = [x_step, x_dir, y_step, y_dir, daq, laser]
channel_lines = [X_STEP_LINE, X_DIR_LINE, Y_STEP_LINE, Y_DIR_LINE, DAQ_LINE, LASER_LINE]
waveform_duration = ARRAY_LENGTH / SAMPLE_RATE

if __name__ == "__main__":

    print(f"line record:    {DAQ_ACQUIRE_SAMPLES} samples "
          f"= {DAQ_ACQUIRE_SAMPLES / SAMPLE_RATE * 1e3:.2f} ms, "
          f"{X_POSITIONS} laser shots inside it")
    
    # CONTROL CARD
    with nidaqmx.Task() as task:

        task.do_channels.add_do_chan(X_STEP_LINE,line_grouping=LineGrouping.CHAN_PER_LINE)
        task.do_channels.add_do_chan(X_DIR_LINE,line_grouping=LineGrouping.CHAN_PER_LINE)
        task.do_channels.add_do_chan(Y_STEP_LINE,line_grouping=LineGrouping.CHAN_PER_LINE)
        task.do_channels.add_do_chan(Y_DIR_LINE,line_grouping=LineGrouping.CHAN_PER_LINE)
        task.do_channels.add_do_chan(DAQ_LINE,line_grouping=LineGrouping.CHAN_PER_LINE)
        task.do_channels.add_do_chan(LASER_LINE,line_grouping=LineGrouping.CHAN_PER_LINE)

        task.timing.cfg_samp_clk_timing(rate=SAMPLE_RATE,sample_mode=AcquisitionType.FINITE,samps_per_chan=ARRAY_LENGTH)

        number_written = task.write(waveform_data,auto_start=False)

        print("Starting B line...")

        task.start()
        task.wait_until_done(timeout=waveform_duration + 10.0)
        task.stop()

        # leave every line low
        task.timing.samp_timing_type = SampleTimingType.ON_DEMAND
        task.write([False] * len(channel_lines), auto_start=True)
        task.stop()

    print("B line finished")

