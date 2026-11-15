# Tutorial 5 setup on a fresh Ubuntu 24.04 (WSL2): logs

Logs and scripts behind the pull request "Tutorial 5: add the native build prerequisites step and a
low-memory build tip". Everything ran on villa commit `2d3fb38d33a18b257230c0bd23986436c3d4722e`
in a new `Ubuntu-24.04` WSL2 distribution created only for this (`wsl --install Ubuntu-24.04 --name villa-clean`).

Machine: Windows 11 laptop, AMD Ryzen 9 4900H (16 logical CPUs), 15.4 GiB RAM, NVIDIA RTX 2060 (6 GB),
WSL 2.7.14 with its default limits: the Linux VM has 7.5 GiB of RAM and 2 GiB of swap
(see `environment.txt`).

## Runs

Each run is the tutorial's `uv sync --extra models` in `villa/vesuvius`, started by `run_sync.sh`, which also
samples available memory, swap in use and the number of running `cc1plus` processes every 5 seconds.

| Run | System packages | Settings | Result | Logs |
| --- | --- | --- | --- | --- |
| A | none (fresh Ubuntu 24.04) | tutorial as written | exit code 1: no C compiler | `logs/A_fresh_ubuntu.log` |
| C | `install_build_deps.sh minimal-build` | tutorial as written | out of memory within a minute of the first compiler starting: 36 compilers, 43 MiB available, swap full, OOM killer; command terminated after 204 s | `logs/C_default_parallelism.*` |
| D | same | `UV_CONCURRENT_BUILDS=1 CMAKE_BUILD_PARALLEL_LEVEL=3` | out of memory after 20 minutes (0 MiB available, swap full); no package finished during the following hour; command terminated after 82 minutes | `logs/D_one_package_three_jobs.*` |
| E | same | `UV_CONCURRENT_BUILDS=1 CMAKE_BUILD_PARALLEL_LEVEL=1` | exit code 0 after 15,002 s (4 h 10 min); lowest available memory 1,882 MiB; at most 18 MiB of swap | `logs/E_one_compiler_at_a_time.*`, `logs/E_tu_mem.tsv` |

`logs/install_build_deps.log` is the package installation between runs A and C (523 → 937 installed packages).
`logs/F_verify_env.log` is the environment of run E afterwards: the documented prerequisite line run from
`villa/vesuvius`, the tutorial's GPU check (`2.12.1+cu130 | cuda: True`), and the released 9 µm ink model
(`scrollprize/ink_9um`, `hybrid_3d2d-seed42/step-075000.pth`) on the published surface volume of the
PHerc. 0800 segment `20251028213516-auto_grown_20251028213516907` (8.64 µm, 31 × 2160 × 2240): 684 patches in 109 s.

## Memory per compile command (run E)

Run E wrapped every compile command in `tu_mem_launcher.py`, which records the peak resident memory of the
compiler. `python3 tu_summary.py logs/E_tu_mem.tsv` prints the summary. Of 643 compile commands:

- the largest peak is 4,763 MiB (`core/.../lasagna/LasagnaNormalSampler.cpp`), the next 3,399 MiB
  (`vc_reader`'s `bindings.cpp`, which also takes 21.6 minutes to compile);
- 18 commands peak above 2,000 MiB and 67 above 1,500 MiB;
- inside the `volume-cartographer` build the largest peaks are 4,763, 2,592, 2,491, 2,340, 2,298 and 2,292 MiB,
  so two jobs can need 7.2 GiB at the same moment and three jobs 9.6 GiB;
- inside the `vc_reader` build, which uv starts first, the three largest peaks add up to 6.7 GiB.

## Notes

- Third-party wheels (PyTorch and the rest) came from a warm uv cache, because the connection here is slow.
  Run A read it through a mount shared from another distribution (hence `/mnt/wsl/uvcache` in its log); for the
  later runs it was copied into the distribution. The three local C++ packages were built from source in every run.
- The laptop was suspended while run A was waiting, so the elapsed time on the last line of its log is meaningless.
  Its sampler has 31 samples, about two and a half minutes of running time.
- After run C, WSL stopped the distribution about a minute into the next command
  (`logs/D_aborted_before_wsl_restart.*`). Run D is the repeat after `wsl --shutdown`.
- The kernel log of run D was not saved: the command was terminated before the script reached that step, and
  WSL was restarted afterwards.
- Each run was done once.
- The two checksums at the end of `logs/F_verify_env.log` compare the prediction with one computed earlier in
  another environment on the same laptop. The files are not identical: 15,535 of 4,838,400 pixels differ, each
  by 1/255 (correlation 0.999999).
