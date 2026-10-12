import importlib.util
import os
import subprocess
import sys
from pathlib import Path


ARMED_MARKER = "Acquisition started."

# ---- scan geometry, taken from the control-card script -----------------------
program_directory = Path(__file__).resolve().parent.parent
digitizer_script = program_directory / "control_py" / "digitizer" / "NPT_Aline.py"
control_card_script = program_directory / "control_py" / "control_card" / "A_scan.py"

for _path in (digitizer_script, control_card_script):
    if not _path.is_file():
        raise FileNotFoundError(f"script not found: {_path}")


def loadScanGeometry(path):
    """Import A_scan.py for its constants only. Its hardware section is
    behind a __main__ guard, so importing it does not touch the control card."""
    spec = importlib.util.spec_from_file_location("A_scan_geometry", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def countRisingEdges(wave):
    return sum(1 for i in range(len(wave)) if wave[i] and not (i and wave[i - 1]))


scan = loadScanGeometry(control_card_script)

ROWS = 1                                                  # a single A line
SHOTS_PER_ROW = countRisingEdges(scan.laser)              # one record per laser trigger
TOTAL_SECONDS = scan.ARRAY_LENGTH / scan.SAMPLE_RATE

print(f"rows / acquisitions:  {ROWS}")
print(f"shots per row:        {SHOTS_PER_ROW}")
print(f"waveform:             {TOTAL_SECONDS * 1e3:.1f} ms")


# ---- start the digitizer and wait until it is armed --------------------------
digitizer_environment = dict(os.environ)
digitizer_environment.update({
    "SCAN_ROWS": str(ROWS),
    "SCAN_SHOTS_PER_ROW": str(SHOTS_PER_ROW),
    "SCAN_TOTAL_SECONDS": repr(TOTAL_SECONDS),
})

# ``-u`` makes its status messages available immediately, so the control card
# does not start before the digitizer is armed.
digitizer_process = subprocess.Popen(
    [sys.executable, "-u", str(digitizer_script)],
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True,
    bufsize=1,
    env=digitizer_environment,
)
assert digitizer_process.stdout is not None

rows_armed = 0
for line in digitizer_process.stdout:
    print(line, end="", flush=True)

    if ARMED_MARKER in line:
        rows_armed += 1
        break

if rows_armed == 0:
    return_code = digitizer_process.wait()
    raise RuntimeError(
        "Digitizer exited before acquisition became ready "
        f"(exit code {return_code})."
    )

# Only now, with the board armed, may the trigger be sent.
control_process = subprocess.Popen([sys.executable, str(control_card_script)])

# Continue forwarding digitizer output.
for line in digitizer_process.stdout:
    print(line, end="", flush=True)

    if ARMED_MARKER in line:
        rows_armed += 1

# Wait until both scripts finish and report failures accurately.
digitizer_return_code = digitizer_process.wait()
control_return_code = control_process.wait()

if digitizer_return_code != 0 or control_return_code != 0:
    raise RuntimeError(
        "Acquisition failed: "
        f"digitizer exit code={digitizer_return_code}, "
        f"control-card exit code={control_return_code}."
    )

if rows_armed != ROWS:
    print(f"WARNING: digitizer armed {rows_armed} times for {ROWS} A line")

print(f"Acquisition finished: A line, {SHOTS_PER_ROW} shot(s)")
