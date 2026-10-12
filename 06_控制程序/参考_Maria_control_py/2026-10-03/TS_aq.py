from __future__ import division
import ctypes
import numpy as np
import os
import signal
import sys
import time
from pathlib import Path

sys.path.append(r"C:\Users\Caolab\Desktop\daq\23.3.0\Samples_Python\Library\atsapi")

import atsapi as ats

# SETTINGS (scriptControl_TS.py passes the scan geometry in the environment)
ROWS = int(os.environ.get("SCAN_ROWS", "50"))
ROW_RECORD_SECONDS = float(os.environ.get("SCAN_ROW_RECORD_SECONDS", "0.3"))
SAVE_DATA = True
OUTPUT_DIR = Path(__file__).resolve().parent / "PA_data" / time.strftime("scan_%Y%m%d_%H%M%S")

TARGET_BUFFER_BYTES = 8 * 1024 * 1024  # one DMA buffer
BUFFER_ALIGNMENT_SAMPLES = 128  # keep the buffer length a multiple of this
BUFFER_COUNT = 32  # 256 MiB posted, more than one 108 MB row

samplesPerSec = None

# Configures a board for acquisition
def ConfigureBoard(board):

    global samplesPerSec
    samplesPerSec = 180000000.0
    board.setCaptureClock(ats.INTERNAL_CLOCK,
                          ats.SAMPLE_RATE_180MSPS,
                          ats.CLOCK_EDGE_RISING,
                          0)
    

    # channel A input parameters as required
    board.inputControlEx(ats.CHANNEL_A,
                         ats.AC_COUPLING,
                         ats.INPUT_RANGE_PM_200_MV,
                         ats.IMPEDANCE_50_OHM)
    
    # channel A bandwidth limit as required
    board.setBWLimit(ats.CHANNEL_A, 0)

    # TODO: Select trigger inputs and levels as required. In this example program, the 
    # board is setup to trigger on CHA positive slope, at +17% trigger level. The input 
    # signal amplitude must be at least 30% of the full scale for the board to trigger. 
    # If no signal is supplied, the board will not trigger and acquisition will timeout.

    board.setTriggerOperation(ats.TRIG_ENGINE_OP_J,
                              ats.TRIG_ENGINE_J,
                              ats.TRIG_EXTERNAL,
                              ats.TRIGGER_SLOPE_POSITIVE,
                              150,
                              ats.TRIG_ENGINE_K,
                              ats.TRIG_DISABLE,
                              ats.TRIGGER_SLOPE_POSITIVE,
                              128)

    board.setExternalTrigger(ats.DC_COUPLING,
                             ats.ETR_5V)
    
    triggerDelay_samples = 0
    board.setTriggerDelay(triggerDelay_samples)

    board.setTriggerTimeOut(0)

    # Diagnostic: AUX I/O outputs a pulse each time the trigger engine
    # actually fires, independent of DMA/buffer completion. Scope this
    # pin to confirm whether/when the board is recognizing triggers
    # coming in on TRIG IN.
    board.configureAuxIO(ats.AUX_OUT_TRIGGER, 0)

## things for buffer count
X_STEPS = 50
X_PULSES_PER_POSITION = 20
SAMPLES_PER_ROW = X_STEPS * ( 2 * X_PULSES_PER_POSITION + 2)
CONTROL_CARD_FREQUENCY = 1000 #Hz
SAMPLING_RATE = 180000000 # samples/sec
SAMPLES_TOTAL = SAMPLING_RATE / CONTROL_CARD_FREQUENCY * SAMPLES_PER_ROW 
BIT_PER_SAMPLE = 16 
BIT_TOTAL = SAMPLES_TOTAL * 16
TIME_ROW = SAMPLES_TOTAL * SAMPLING_RATE

def AcquireData(board):
    # Select which channels to capture (A, B, or both)
    channels = ats.CHANNEL_A
    channelCount = 0
    for c in ats.channels:
        channelCount += (c & channels == c)

    # ---- what the board actually gives us ------------------------------------
    memorySize_samples, bitsPerSample = board.getChannelInfo()
    bytesPerSample = (bitsPerSample.value + 7) // 8
    bytesPerPoint = bytesPerSample * channelCount

    # ---- how much of one row we have to catch --------------------------------
    samplesPerRow = int(samplesPerSec * ROW_RECORD_SECONDS + 0.5)

    # ---- one DMA buffer ------------------------------------------------------
    samplesPerBuffer = TARGET_BUFFER_BYTES // bytesPerPoint
    samplesPerBuffer -= samplesPerBuffer % BUFFER_ALIGNMENT_SAMPLES
    bytesPerBuffer = samplesPerBuffer * bytesPerPoint

    # In triggered streaming the record does not stop itself: it ends when we
    # stop taking buffers. So the row length is quantised to whole buffers and
    # we always round UP - the overshoot just runs into the flyback and gets
    # trimmed later. Rounding down would cut the last positions of the row off.
    buffersPerAcquisition = -(-samplesPerRow // samplesPerBuffer)
    samplesPerAcquisition = buffersPerAcquisition * samplesPerBuffer
    overshoot_samples = samplesPerAcquisition - samplesPerRow

    bytesPerAcquisition = samplesPerAcquisition * bytesPerPoint
    bytesWholeScan = samplesPerRow * bytesPerPoint * ROWS
    dmaWorkingSet_bytes = BUFFER_COUNT * bytesPerBuffer


    # The board only has to sustain the full streaming rate over the bus if its
    # on-board memory cannot hold the row. If the row fits, the burst is
    # absorbed on the board and drained during the flyback.
    if samplesPerAcquisition > memorySize_samples.value:
        print(f"  NOTE: a row ({samplesPerAcquisition:,} samples) does not fit in "
              f"on-board memory ({memorySize_samples.value:,}), so the bus must "
              f"sustain {samplesPerSec * bytesPerPoint / 1e6:.0f} MB/s live or "
              f"you will get ApiBufferOverflow")

    # Allocate memory for DMA buffers using an Alazar API, which internally uses virtual alloc. It
    # is essential for DMA buffers to be page aligned.
    sample_type = ctypes.c_uint8
    if bytesPerSample > 1:
        sample_type = ctypes.c_uint16

    # allocated ONCE and reused for every row - never reallocate between rows,
    # allocation is slow and would eat into the re-arm window
    buffers = []
    for i in range(BUFFER_COUNT):
        buffers.append(ats.DMABuffer(board.handle, sample_type, bytesPerBuffer))

    # DAQ_LINE emits one external trigger per row. End this triggered stream
    # after the row's known sample count, then arm again during the X flyback.
    if SAVE_DATA:
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        print(f"Data directory: {OUTPUT_DIR}", flush=True)

    bytesTransferred = 0
    started = time.time()
    for row_index in range(ROWS):
        row_file = None
        if SAVE_DATA:
            row_file = open(OUTPUT_DIR / f"row_{row_index + 1:03d}.bin", "wb")

        row_started = time.time()
        buffersCompleted = 0
        samplesWritten = 0
        try:
            board.beforeAsyncRead(
                channels, 0, samplesPerBuffer, 1, 0x7FFFFFFF,
                ats.ADMA_EXTERNAL_STARTCAPTURE | ats.ADMA_TRIGGERED_STREAMING,
            )
            for buffer in buffers:
                board.postAsyncBuffer(buffer.addr, buffer.size_bytes)

            # scriptControl_TS waits for this before starting the motor for row 1.
            # Repeated markers show that each following row is armed during flyback.
            board.startCapture()
            print(f"Acquisition started. row {row_index + 1}/{ROWS}", flush=True)

            while buffersCompleted < buffersPerAcquisition:
                buffer = buffers[buffersCompleted % len(buffers)]
                timeout_ms = max(5000, int(ROW_RECORD_SECONDS * 1000 + 5000))
                try:
                    board.waitAsyncBufferComplete(buffer.addr, timeout_ms)
                except Exception as exc:
                    raise RuntimeError(
                        f"Failed waiting for row {row_index + 1} DMA buffer "
                        f"{buffersCompleted + 1}/{buffersPerAcquisition}: {exc}. Check "
                        "that DAQ_LINE reaches ATS TRIG IN, the trigger edge is "
                        "positive, and the board is armed before the row pulse."
                    ) from exc

                buffersCompleted += 1
                valid_samples = min(samplesPerBuffer, samplesPerRow - samplesWritten)
                if row_file is not None and valid_samples:
                    buffer.buffer[:valid_samples].tofile(row_file)
                samplesWritten += valid_samples
                bytesTransferred += valid_samples * bytesPerPoint

                # The final buffer contains up to a few ms of flyback. Do not
                # save that tail or return the buffer to the DMA queue.
                if buffersCompleted < buffersPerAcquisition:
                    board.postAsyncBuffer(buffer.addr, buffer.size_bytes)
        finally:
            board.abortAsyncRead()
            if row_file is not None:
                row_file.close()

        elapsed = time.time() - row_started
        print(f"Row {row_index + 1}/{ROWS} captured: {samplesWritten:,} samples "
              f"in {elapsed:.3f} s; rearming", flush=True)

    transferTime_sec = time.time() - started
    rate = bytesTransferred / transferTime_sec if transferTime_sec > 0 else 0
    print(f"Capture completed in {transferTime_sec:.3f} s; transferred "
          f"{bytesTransferred:,} bytes ({rate / 1e6:.1f} MB/s average)")


if __name__ == "__main__":

    # TODO: Select a board.
    # This sample program is designed for single board use. If there are more
    # than one board installed, user should use Multi_system sample programs.
    board = ats.Board(systemId = 1, boardId = 1)

    # Configure the board's sample rate, input, and trigger settings
    ConfigureBoard(board)

    # Make an acquisition, optionally saving sample data to a file
    AcquireData(board)
