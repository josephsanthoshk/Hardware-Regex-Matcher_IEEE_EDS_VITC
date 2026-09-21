import subprocess
import sys

RTL = "tt_um_regex_matcher.v"
TB  = "tb.v"
OUT = "sim.out"

print("Compiling...")

compile_cmd = [
    "iverilog",
    "-g2012",
    "-o", OUT,
    RTL,
    TB
]

result = subprocess.run(
    compile_cmd,
    capture_output=True,
    text=True
)

if result.returncode != 0:
    print("Compilation FAILED")
    print(result.stdout)
    print(result.stderr)
    sys.exit(1)

print("Compilation successful.")
print()
print("Running simulation...")
print("----------------------------------------------")

result = subprocess.run(
    ["vvp", OUT],
    capture_output=True,
    text=True
)

print(result.stdout)

if result.stderr:
    print("Simulation stderr:")
    print(result.stderr)

if result.returncode != 0:
    print("Simulation FAILED")
    sys.exit(1)

print("----------------------------------------------")
print("Simulation completed successfully.")
