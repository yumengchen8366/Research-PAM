# test line
import nidaqmx
from nidaqmx.constants import AcquisitionType, LineGrouping
data = [True] * 10
data = [False] * 10
SAMPLE_RATE = 2 #Hz
waveform_duration = len(data) / SAMPLE_RATE # seconds
with nidaqmx.Task() as task:

    task.do_channels.add_do_chan("Dev1/port0/line6",line_grouping=LineGrouping.CHAN_PER_LINE)

    task.timing.cfg_samp_clk_timing(rate=SAMPLE_RATE,sample_mode=AcquisitionType.FINITE,samps_per_chan=len(data))

    number_written = task.write(data,auto_start=False)

    print("Starting...")

    task.start()
    task.wait_until_done(timeout=waveform_duration + 2.0)
    task.stop()

print("finished.")

