"""Read-only dump of LabVIEW .vi resource files: block list, link info, and strings
from (decompressed) front-panel / block-diagram heaps. Does not modify inputs.

Usage (PowerShell, using the Python bundled in Control_py):
  & "C:\\Users\\2031\\Desktop\\Control_py\\.uv-python\\cpython-3.13.15-windows-x86_64-none\\python.exe" `
    docs\\tools\\vi_dump.py <folder containing .vi files> <output .txt>

Sections in the output: LIvi/LIbd = linked subVIs, VCTP = control/indicator names,
FPHb = front-panel text, BDHb = block-diagram text (labels, constants, comments),
DFDS = default data strings. Wiring and numeric defaults are NOT recoverable here."""
import os
import re
import struct
import sys
import zlib

PRINTABLE = re.compile(rb"[\x20-\x7e]{3,}")


def parse_rsrc(b):
    if b[:6] != b"RSRC\r\n":
        raise ValueError("not RSRC")
    _ver, _typ, _cre, info_off, _info_size, data_off, _data_size = struct.unpack(">H4s4sIIII", b[6:32])
    p = info_off + 32
    _d1, _d2, _d3, bi_off, _bi_size = struct.unpack(">IIIII", b[p:p + 20])
    base = info_off + bi_off
    n = struct.unpack(">I", b[base:base + 4])[0] + 1
    out = []
    for i in range(n):
        name, cnt, off = struct.unpack(">4sII", b[base + 4 + 12 * i: base + 16 + 12 * i])
        s = base + off
        for j in range(cnt + 1):
            _idx, _noff, _i3, doff, _i5 = struct.unpack(">iIIII", b[s + 20 * j: s + 20 * j + 20])
            dpos = data_off + doff
            size = struct.unpack(">I", b[dpos:dpos + 4])[0]
            out.append((name.decode("latin1"), b[dpos + 4: dpos + 4 + size]))
    return out


def maybe_decompress(data):
    if len(data) > 6 and data[4] == 0x78:
        try:
            return zlib.decompress(data[4:]), True
        except zlib.error:
            pass
    return data, False


def strings(data):
    seen, res = set(), []
    for m in PRINTABLE.finditer(data):
        s = m.group().decode("latin1").strip()
        if len(s) >= 3 and s not in seen and not re.fullmatch(r"[\W\d_]+", s):
            seen.add(s)
            res.append(s)
    return res


def dump(path, out):
    b = open(path, "rb").read()
    secs = parse_rsrc(b)
    out.write(f"\n######## {os.path.basename(path)}  ({len(b)} bytes)\n")
    out.write("blocks: " + " ".join(sorted({n for n, _ in secs})) + "\n")
    for name, data in secs:
        if name not in ("LIvi", "LIfp", "LIbd", "FPHb", "BDHb", "STRG", "DFDS", "VCTP", "CPC2", "LVSR"):
            continue
        dec, z = maybe_decompress(data)
        ss = strings(dec)
        if not ss:
            continue
        out.write(f"--- {name}{' (zlib)' if z else ''}: {len(ss)} strings\n")
        for s in ss:
            out.write("    " + s[:200] + "\n")


if __name__ == "__main__":
    folder, outpath = sys.argv[1], sys.argv[2]
    paths = [os.path.join(folder, f) for f in sorted(os.listdir(folder)) if f.lower().endswith(".vi")]
    with open(outpath, "w", encoding="utf-8") as out:
        for p in paths:
            try:
                dump(p, out)
            except Exception as e:  # keep going on unusual files
                out.write(f"\n######## {os.path.basename(p)}  PARSE ERROR: {e}\n")
