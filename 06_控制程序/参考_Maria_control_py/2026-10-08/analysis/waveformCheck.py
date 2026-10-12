# undirectional scan, one laser trigger per position, one DAQ trigger per row
# (the DAQ is armed once at the first position of a row and streams until the
# row is over, then it is re-armed on the next row)

import sys
from pathlib import Path
import numpy as np
from scipy.io import savemat
# LINES
X_STEP_LINE = "Dev1/port0/line0"
X_DIR_LINE  = "Dev1/port0/line1"

Y_STEP_LINE = "Dev1/port0/line2"
Y_DIR_LINE  = "Dev1/port0/line3"

DAQ_LINE   = "Dev1/port0/line6"
LASER_LINE = "Dev1/port0/line7"

# .mat file for MATLAB (set to None to skip saving)
SAVE_WAVEFORMS_TO = Path(__file__).with_name("waveforms.mat")
# LINES
DAQ_LINE   = "Dev1/port0/line6"
LASER_LINE = "Dev1/port0/line7"

# PARAMETERS
SAMPLE_RATE = 1000.0 # time frequancy of sending timed signals by control card
TRIGGER_WIDTH_SAMPLES = 1 # width of the trigger pulse

# WAVEFORMS
daq   = [False] + [True] * TRIGGER_WIDTH_SAMPLES + [False]
laser = [False] + [True] * TRIGGER_WIDTH_SAMPLES + [False]

waveform_data = [daq, laser]
channel_lines = [DAQ_LINE, LASER_LINE]
ARRAY_LENGTH = len(daq)
waveform_duration = ARRAY_LENGTH / SAMPLE_RATE


# SAVE WAVEFORMS FOR MATLAB
if SAVE_WAVEFORMS_TO is not None:
    waveform_array = np.asarray(waveform_data, dtype=np.uint8) # 6 channels x ARRAY_LENGTH samples
    savemat(
        SAVE_WAVEFORMS_TO,
        {
            #"x_step": np.asarray(x_step, dtype=np.uint8),
            #"x_dir": np.asarray(x_dir, dtype=np.uint8),
            #"y_step": np.asarray(y_step, dtype=np.uint8),
            #"y_dir": np.asarray(y_dir, dtype=np.uint8),
            "daq": np.asarray(daq, dtype=np.uint8),
            "laser": np.asarray(laser, dtype=np.uint8),
            "waveform_data": waveform_array,
            "pulse_rate_Hz": SAMPLE_RATE,
            "array_length": ARRAY_LENGTH,
            #"x_positions": X_POSITIONS,
            #"y_positions": Y_POSITIONS,
            #"total_positions": TOTAL_POSITIONS,
        },)
    print(f"Waveforms saved to: {SAVE_WAVEFORMS_TO}")
    print(f"Waveform shape: {waveform_array.shape}")