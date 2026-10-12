from __future__ import division
import ctypes
import os
import signal
import sys
import time
from pathlib import Path

sys.path.append(r"C:\Users\Caolab\Desktop\daq\23.3.0\Samples_Python\Library\atsapi")

import atsapi as ats

# SETTINGS
DATA_ROOT = Path(r"C:\Users\Caolab\Desktop\control_py\data")
SAVE_DATA = True

ROWS = int(os.environ.get("SCAN_ROWS", "1"))  # 0 = until Ctrl+C
SHOTS_PER_ROW = int(os.environ.get("SCAN_SHOTS_PER_ROW", "1"))  # A-lines (triggers) per row

SAMPLES_PER_RECORD = 12800  # one A-line; NPT needs this to be a multiple of the board's record alignment
TRIGGER_DELAY_SAMPLES = 0 # shift the 128-sample window later to skip the acoustic time of flight
ROW_TIMEOUT_MS = 5000  # longest wait for a row's triggers before reporting a missing trigger

DMA_BUFFER_COUNT = 2  # one row per buffer; the second covers the next row being posted early

ARMED_MARKER = "Acquisition started."  # scriptControl_TS.py counts this per row

samplesPerSec = None
stopRequested = False


def requestStop(signum, frame):
    global stopRequested
    stopRequested = True
    print("Stop requested: finishing the current row", flush=True)


# Configures a board for acquisition
def ConfigureBoard(board):

    global samplesPerSec
    samplesPerSec = 180000000.0
    board.setCaptureClock(ats.INTERNAL_CLOCK,
                          ats.SAMPLE_RATE_180MSPS,
                          ats.CLOCK_EDGE_RISING,
                          0)

    board.inputControlEx(ats.CHANNEL_A,
                         ats.AC_COUPLING,
                         ats.INPUT_RANGE_PM_200_MV,
                         ats.IMPEDANCE_50_OHM)
    board.setBWLimit(ats.CHANNEL_A, 0)

    # laser / pulse sync -> TRIG IN, one rising edge per A-line
    board.setTriggerOperation(ats.TRIG_ENGINE_OP_J,
                              ats.TRIG_ENGINE_J,
                              ats.TRIG_EXTERNAL,
                              ats.TRIGGER_SLOPE_POSITIVE,
                              150,
                              ats.TRIG_ENGINE_K,
                              ats.TRIG_DISABLE,
                              ats.TRIGGER_SLOPE_POSITIVE,
                              128)
    board.setExternalTrigger(ats.DC_COUPLING, ats.ETR_5V)
    board.setTriggerDelay(TRIGGER_DELAY_SAMPLES)
    board.setTriggerTimeOut(0)  # never auto-trigger: a missing pulse must show up as a timeout
    board.configureAuxIO(ats.AUX_OUT_TRIGGER, 0)


def AcquireData(board):
    channels = ats.CHANNEL_A
    channelCount = sum(1 for c in ats.channels if c & channels == c)
    bytesPerSample = 2  # ATS9462: 16-bit container per sample

    valuesPerRow = SHOTS_PER_ROW * SAMPLES_PER_RECORD * channelCount
    bytesPerBuffer = valuesPerRow * bytesPerSample
    recordSeconds = SAMPLES_PER_RECORD / samplesPerSec

    print(f"A-line mode: {SAMPLES_PER_RECORD} samples/record "
          f"({recordSeconds * 1e6:.2f} us, trigger delay {TRIGGER_DELAY_SAMPLES} samples), "
          f"{SHOTS_PER_ROW} records/row, rows {ROWS or 'until Ctrl+C'}, "
          f"{bytesPerBuffer / 1e3:.1f} kB per row", flush=True)

    # allocated ONCE and reused for every row: allocation would eat the re-arm window
    buffers = [ats.DMABuffer(board.handle, ctypes.c_uint16, bytesPerBuffer)
               for _ in range(DMA_BUFFER_COUNT)]

    rows = []  # each entry: (SHOTS_PER_ROW, SAMPLES_PER_RECORD) uint16
    started = time.time()
    try:
        while (ROWS == 0 or len(rows) < ROWS) and not stopRequested:
            # NPT: pre-trigger must be 0; the acquisition ends by itself after
            # SHOTS_PER_ROW records, which is exactly one buffer
            board.beforeAsyncRead(
                channels, 0, SAMPLES_PER_RECORD, SHOTS_PER_ROW, SHOTS_PER_ROW,
                ats.ADMA_EXTERNAL_STARTCAPTURE | ats.ADMA_NPT,
            )
            try:
                buffer = buffers[len(rows) % DMA_BUFFER_COUNT]
                board.postAsyncBuffer(buffer.addr, buffer.size_bytes)
                board.startCapture()
                print(f"{ARMED_MARKER} row {len(rows) + 1}/{ROWS or 'inf'}", flush=True)

                try:
                    board.waitAsyncBufferComplete(buffer.addr, ROW_TIMEOUT_MS)
                except Exception as exc:
                    raise RuntimeError(
                        f"row {len(rows) + 1}: {exc}. ApiWaitTimeout = fewer than "
                        f"{SHOTS_PER_ROW} trigger edges reached TRIG IN for this row."
                    ) from exc

                rows.append(buffer.buffer[:valuesPerRow]
                            .reshape(SHOTS_PER_ROW, SAMPLES_PER_RECORD * channelCount)
                            .copy())
            finally:
                board.abortAsyncRead()

            print(f"Row {len(rows)} captured: {SHOTS_PER_ROW} A-lines", flush=True)
    finally:
        try:
            board.abortAsyncRead()
        except Exception:
            pass
        del buffers
        # save whatever was captured, also after an error or Ctrl+C:
        # one raw uint16 file per row, records back to back, no header
        if SAVE_DATA and rows:
            outputDir = DATA_ROOT / time.strftime("aline_%Y%m%d_%H%M%S")
            outputDir.mkdir(parents=True, exist_ok=True)
            for i, row in enumerate(rows):
                row.tofile(outputDir / f"row_{i + 1:03d}.bin")
            print(f"Saved {len(rows)} row file(s) of {SHOTS_PER_ROW} x {SAMPLES_PER_RECORD} "
                  f"uint16 to {outputDir}", flush=True)

    elapsed = time.time() - started
    print(f"Capture finished: {len(rows)} rows, {len(rows) * SHOTS_PER_ROW} A-lines "
          f"in {elapsed:.1f} s")


if __name__ == "__main__":
    signal.signal(signal.SIGINT, requestStop)
    board = ats.Board(systemId=1, boardId=1)
    ConfigureBoard(board)
    AcquireData(board)
