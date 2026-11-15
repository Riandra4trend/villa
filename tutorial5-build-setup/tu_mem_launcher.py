#!/usr/bin/python3
"""Compiler launcher for measurements: run the wrapped compile command, then append one line
`<peak RSS in MB>\t<wall seconds>\t<exit code>\t<output file>` to the file named by TU_MEM_LOG.

Used as CMAKE_C_COMPILER_LAUNCHER / CMAKE_CXX_COMPILER_LAUNCHER. It does not change the command.
"""
import os
import resource
import subprocess
import sys
import time

start = time.monotonic()
code = subprocess.call(sys.argv[1:])
# Peak RSS of the largest waited-for descendant (cc1plus under the g++ driver), in kB on Linux.
peak_mb = resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss // 1024
output = next((sys.argv[i + 1] for i, arg in enumerate(sys.argv[:-1]) if arg == "-o"), "?")
with open(os.environ.get("TU_MEM_LOG", "/tmp/tu-mem.log"), "a") as log:
    log.write(f"{peak_mb}\t{time.monotonic() - start:.1f}\t{code}\t{output}\n")
sys.exit(code)
