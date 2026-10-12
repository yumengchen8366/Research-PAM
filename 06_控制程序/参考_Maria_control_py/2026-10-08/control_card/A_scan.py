# script for single-position A line, one trigger to DAQ and laser at the same time, no stage movement

import nidaqmx
from nidaqmx.constants import AcquisitionType, LineGrouping, SampleTimingType

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

if __name__ == "__main__":

    # CONTROL CARD
    with nidaqmx.Task() as task:

        task.do_channels.add_do_chan(DAQ_LINE,line_grouping=LineGrouping.CHAN_PER_LINE)
        task.do_channels.add_do_chan(LASER_LINE,line_grouping=LineGrouping.CHAN_PER_LINE)

        task.timing.cfg_samp_clk_timing(rate=SAMPLE_RATE,sample_mode=AcquisitionType.FINITE,samps_per_chan=ARRAY_LENGTH)

        number_written = task.write(waveform_data,auto_start=False)

        print("Sending single trigger to DAQ and laser...")

        task.start()
        task.wait_until_done(timeout=waveform_duration + 10.0)
        task.stop()

        # leave every line low
        task.timing.samp_timing_type = SampleTimingType.ON_DEMAND
        task.write([False] * len(channel_lines), auto_start=True)
        task.stop()

    print("A line finished.")
