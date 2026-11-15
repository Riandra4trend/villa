"""Summarize the per-compile memory log written by tu_mem_launcher.py during a serial `uv sync` build.

uv built the three C++ packages one after the other (UV_CONCURRENT_BUILDS=1), so the log is three
consecutive CMake builds. Each one starts with CMake's C compiler ABI probe, which marks the boundary.
Memory is the compiler's peak resident set size in MiB.
"""
import sys

rows = []
with open(sys.argv[1]) as log:
    for line in log:
        peak, seconds, code, obj = line.rstrip("\n").split("\t")
        rows.append((int(peak), float(seconds), int(code), obj))

starts = [index for index, row in enumerate(rows) if row[3].endswith("CMakeCCompilerABI.c.o")]
starts.append(len(rows))

peaks_all = sorted((row[0] for row in rows), reverse=True)
print(f"{len(rows)} compile commands, {sum(row[1] for row in rows) / 3600:.2f} h of compile time in total")
print(f"peak above 2000 MiB: {sum(peak > 2000 for peak in peaks_all)}, "
      f"above 1500 MiB: {sum(peak > 1500 for peak in peaks_all)}")
for number, (begin, end) in enumerate(zip(starts, starts[1:]), 1):
    part = sorted(rows[begin:end], reverse=True)
    peaks = [row[0] for row in part]
    print(f"\nbuild {number}: {end - begin} compile commands, {sum(row[1] for row in rows[begin:end]) / 60:.0f} min")
    print(f"  largest peaks (MiB): {peaks[:6]}")
    print(f"  if the 2 largest overlap: {sum(peaks[:2])} MiB; the 3 largest: {sum(peaks[:3])} MiB")
    for peak, seconds, _, obj in part[:3]:
        print(f"  {peak:5d} MiB {seconds:7.1f} s  {obj}")
