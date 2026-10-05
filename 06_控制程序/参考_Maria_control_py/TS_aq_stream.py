# Triggered-streaming acquisition for the TS scan (syncronization/unScan_TS.py)
# that can run for any number of rows without ApiBufferOverflow.
#
#   ATS9462 --DMA--> DMA ring --copy--> RAM pool --writer thread--> disk
#   (posted buffers)          (main)   (queue)
#
# The acquisition loop never touches the disk: it waits for a DMA buffer, copies
# it into a free RAM slot (~1 ms for 8 MiB), hands the slot to the writer thread
# and re-posts the DMA buffer. The writer thread empties the pool to disk.
#
# Indefinite streaming works as long as, on AVERAGE,
#       disk write rate  >=  rate the board delivers
# (notes.txt: disk >= 939 MB/s worst window, board 360 MB/s live, 183 MB/s scan
# average -> 2.6x margin). Short disk stalls are absorbed by the RAM pool, the
# pool then drains during the next rows. The DMA ring is bigger than one row, so
# a whole row lands in posted buffers even if Python is briefly busy.
# The only remaining limit is free disk space (183 MB/s = ~660 GB per hour),
# which is checked before every row.
#
# Run via scriptControl_TS.py (reads SCAN_ROWS / SCAN_ROW_RECORD_SECONDS from the
# environment). SCAN_ROWS=0 streams rows until Ctrl+C.

from __future__ import division
import ctypes
import os
import queue
import shutil
import signal
import sys
import threading
import time
from pathlib import Path

import numpy as np

sys.path.append(r"C:\Users\Caolab\Desktop\daq\23.3.0\Samples_Python\Library\atsapi")

import atsapi as ats

# SETTINGS
DATA_ROOT = Path(r"C:\Users\Caolab\Desktop\control_py\PA_data")
SAVE_DATA = True

ROWS = int(os.environ.get("SCAN_ROWS", "50"))  # 0 = until Ctrl+C
ROW_RECORD_SECONDS = float(os.environ.get("SCAN_ROW_RECORD_SECONDS", "0.42"))

MiB = 1024 * 1024
BUFFER_BYTES = 8 * MiB  # one DMA buffer = one RAM pool slot
DMA_BUFFER_COUNT = 32  # 256 MiB posted = 0.7 s at 360 MB/s, more than one row
RAM_POOL_BYTES = 4 * 1024 * MiB  # backlog the disk may fall behind: ~11 s at 360 MB/s
SLOT_WAIT_SECONDS = 1.0  # longest the loop waits for a free slot before giving up
FSYNC_EVERY_BYTES = 256 * MiB  # keep the Windows write cache from piling up
DISK_RESERVE_BYTES = 20 * 1024 * MiB  # stop cleanly when free space gets this low

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

    # DAQ_LINE of the control card -> TRIG IN, one rising edge per row
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
    board.setTriggerDelay(0)
    board.setTriggerTimeOut(0)
    board.configureAuxIO(ats.AUX_OUT_TRIGGER, 0)


class DiskWriter(threading.Thread):
    """Owns the RAM pool. The acquisition loop takes a free slot, fills it and
    submits it; this thread writes it to disk and gives the slot back."""

    def __init__(self, poolBytes):
        super().__init__(daemon=True)
        self.nSlots = max(4, int(poolBytes // BUFFER_BYTES))
        self.pool = [np.empty(BUFFER_BYTES // 2, dtype=np.uint16) for _ in range(self.nSlots)]
        for slot in self.pool:
            slot.fill(0)  # commit the pages now, not as page faults during the scan
        self.free = queue.Queue()
        for i in range(self.nSlots):
            self.free.put(i)
        self.todo = queue.Queue()
        self.error = None
        self.bytesWritten = 0
        self.peakBacklog = 0

    def backlog(self):
        return self.nSlots - self.free.qsize()

    def openFile(self, path):
        self.todo.put(("open", path))

    def takeSlot(self):
        if self.error is not None:
            raise RuntimeError(f"disk writer failed: {self.error}")
        try:
            slot = self.free.get(timeout=SLOT_WAIT_SECONDS)
        except queue.Empty:
            raise RuntimeError(
                f"RAM pool full ({self.nSlots * BUFFER_BYTES / MiB:.0f} MiB): the disk "
                "did not keep up. Use a faster drive or a bigger RAM_POOL_BYTES."
            ) from None
        self.peakBacklog = max(self.peakBacklog, self.backlog())
        return slot

    def submit(self, slot, nValues):
        self.todo.put(("data", slot, nValues))

    def finish(self):
        self.todo.put(None)
        self.join()
        if self.error is not None:
            raise RuntimeError(f"disk writer failed: {self.error}")

    def run(self):
        f = None
        sinceSync = 0
        try:
            while True:
                item = self.todo.get()
                if item is None:
                    break
                if item[0] == "open":
                    if f is not None:
                        f.close()
                    f = open(item[1], "wb", buffering=0)
                    continue
                _, slot, nValues = item
                data = memoryview(self.pool[slot][:nValues]).cast("B")
                while data:  # raw writes may be partial
                    data = data[f.write(data):]
                self.bytesWritten += nValues * 2
                sinceSync += nValues * 2
                self.free.put(slot)
                if sinceSync >= FSYNC_EVERY_BYTES:
                    os.fsync(f.fileno())
                    sinceSync = 0
        except Exception as exc:
            self.error = exc
        finally:
            if f is not None:
                os.fsync(f.fileno())
                f.close()


def AcquireData(board):
    channels = ats.CHANNEL_A
    channelCount = sum(1 for c in ats.channels if c & channels == c)
    bytesPerPoint = 2 * channelCount  # ATS9462: 16-bit container per sample

    samplesPerBuffer = BUFFER_BYTES // bytesPerPoint
    samplesPerRow = int(samplesPerSec * ROW_RECORD_SECONDS + 0.5)
    # rounded UP to whole buffers: the overshoot runs into the flyback and is not saved
    buffersPerRow = -(-samplesPerRow // samplesPerBuffer)
    valuesPerBuffer = samplesPerBuffer * channelCount
    valuesPerRow = samplesPerRow * channelCount
    rowBytes = valuesPerRow * 2
    timeout_ms = max(5000, int(ROW_RECORD_SECONDS * 1000 + 5000))

    if buffersPerRow > DMA_BUFFER_COUNT:
        print(f"  NOTE: a row needs {buffersPerRow} DMA buffers but only "
              f"{DMA_BUFFER_COUNT} are posted, so the loop must keep up live")

    outputDir = DATA_ROOT / time.strftime("scan_%Y%m%d_%H%M%S")
    writer = None
    if SAVE_DATA:
        outputDir.mkdir(parents=True, exist_ok=True)
        print(f"Data directory: {outputDir}")
        writer = DiskWriter(RAM_POOL_BYTES)
        writer.start()

    print(f"Rows: {ROWS or 'until Ctrl+C'}, {ROW_RECORD_SECONDS * 1e3:.1f} ms / "
          f"{rowBytes / 1e6:.0f} MB per row, {buffersPerRow} buffers; "
          f"DMA ring {DMA_BUFFER_COUNT * BUFFER_BYTES / MiB:.0f} MiB, "
          f"RAM pool {RAM_POOL_BYTES / MiB:.0f} MiB", flush=True)

    # allocated ONCE and reused for every row: allocation would eat the re-arm window
    buffers = [ats.DMABuffer(board.handle, ctypes.c_uint16, BUFFER_BYTES)
               for _ in range(DMA_BUFFER_COUNT)]

    rowsDone = 0
    started = time.time()
    try:
        while (ROWS == 0 or rowsDone < ROWS) and not stopRequested:
            if writer is not None:
                pending = writer.backlog() * BUFFER_BYTES
                freeBytes = shutil.disk_usage(outputDir).free - pending
                if freeBytes < DISK_RESERVE_BYTES + rowBytes:
                    print(f"Stopping: only {freeBytes / 1e9:.1f} GB left on disk", flush=True)
                    break
                writer.openFile(outputDir / f"row_{rowsDone + 1:05d}.bin")

            board.beforeAsyncRead(
                channels, 0, samplesPerBuffer, 1, 0x7FFFFFFF,
                ats.ADMA_EXTERNAL_STARTCAPTURE | ats.ADMA_TRIGGERED_STREAMING,
            )
            try:
                for buffer in buffers:
                    board.postAsyncBuffer(buffer.addr, buffer.size_bytes)
                board.startCapture()
                print(f"{ARMED_MARKER} row {rowsDone + 1}/{ROWS or 'inf'}", flush=True)

                valuesSaved = 0
                for done in range(buffersPerRow):
                    buffer = buffers[done % DMA_BUFFER_COUNT]
                    try:
                        board.waitAsyncBufferComplete(buffer.addr, timeout_ms)
                    except Exception as exc:
                        raise RuntimeError(
                            f"row {rowsDone + 1} DMA buffer {done + 1}/{buffersPerRow}: {exc}. "
                            "ApiBufferOverflow = posted buffers ran out; ApiWaitTimeout = "
                            "no DAQ_LINE edge on TRIG IN."
                        ) from exc

                    nValues = min(valuesPerBuffer, valuesPerRow - valuesSaved)
                    if writer is not None and nValues > 0:
                        slot = writer.takeSlot()
                        np.copyto(writer.pool[slot][:nValues], buffer.buffer[:nValues])
                        writer.submit(slot, nValues)
                    valuesSaved += nValues

                    # re-post only if the row still needs more buffers than are posted
                    if done + DMA_BUFFER_COUNT < buffersPerRow:
                        board.postAsyncBuffer(buffer.addr, buffer.size_bytes)
            finally:
                board.abortAsyncRead()

            rowsDone += 1
            if writer is not None:
                print(f"Row {rowsDone} captured, RAM backlog "
                      f"{writer.backlog() * BUFFER_BYTES / MiB:.0f}/"
                      f"{writer.nSlots * BUFFER_BYTES / MiB:.0f} MiB", flush=True)
    finally:
        try:
            board.abortAsyncRead()
        except Exception:
            pass
        if writer is not None:
            print("Flushing RAM backlog to disk...", flush=True)
            writer.finish()
        del buffers

    elapsed = time.time() - started
    saved = writer.bytesWritten if writer is not None else rowsDone * rowBytes
    print(f"Capture finished: {rowsDone} rows, {saved / 1e9:.2f} GB in {elapsed:.1f} s "
          f"({saved / elapsed / 1e6 if elapsed else 0:.1f} MB/s average)")
    if writer is not None:
        print(f"Peak RAM backlog: {writer.peakBacklog * BUFFER_BYTES / MiB:.0f} MiB")


if __name__ == "__main__":
    signal.signal(signal.SIGINT, requestStop)
    board = ats.Board(systemId=1, boardId=1)
    ConfigureBoard(board)
    AcquireData(board)
