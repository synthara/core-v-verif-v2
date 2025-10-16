import os
import subprocess
from datetime import datetime
import getpass
import argparse
import yaml

"""
perf_analyzer.py

This script automates the compilation of RTL and software programs, runs simulations, and manages output directories for performance analysis in a RISC-V UVM verification environment.

Functions:
    compile_programs(out_dir: str, programs: list = PROGRAM_LIST)
        Compiles a list of software programs using the run-vcs.py script.
        Args:
            out_dir (str): Output directory for compiled programs.
            programs (list): List of program names to compile.

    sv_compile(run_vcs_dir: str, out_dir: str)
        Compiles ONCE the RTL design using the run-vcs.py script.
        Args:
            run_vcs_dir (str): Directory containing the run-vcs.py script.
            out_dir (str): Output directory for compilation results.

    sv_sim(run_vcs_dir: str, tests: list = TEST_LIST, programs: list = PROGRAM_LIST, out_dir: str = "")
        Runs RTL simulations for each combination of test and program using the run-vcs.py script.
        Args:
            run_vcs_dir (str): Directory containing the run-vcs.py script.
            tests (list): List of test names to run.
            programs (list): List of program names to use in simulations.
            out_dir (str): Output directory for simulation results.

Usage:
    Run this script from the command line with the required --out_dir argument to specify the output directory.
    Example:
        python perf_analyzer.py --out_dir /path/to/output

Notes:
    - Exits the script if any compilation or simulation step fails.
    - Assumes the presence of run-vcs.py in the parent directory of the script.
"""

failed_tests = []
passed_tests = []

def compile_programs(out_dir: str, programs: list = None):
    for program in programs:
        cmd = [
                "python3", f"{run_vcs_dir}/run-vcs.py",
                "-out_dir", out_dir,
                "-program", program,
                "--sw-compile-only"
            ]
        print(f"Compiling program: {program}")
        result = subprocess.run(cmd)
        status = result.returncode
        print(f"\033[92mCompilation of program {program} finished with exit code {status}.\033[0m")
        if status != 0:
            print(f"\033[91mError compiling program {program}. Exiting script.\033[0m")
            exit(1)

def sv_compile(run_vcs_dir: str, out_dir: str):
    cmd = [
        "python3", f"{run_vcs_dir}/run-vcs.py",
        "-out_dir", out_dir,
        "--rtl-compile-only"
    ]
    result = subprocess.run(cmd)
    status = result.returncode
    print(f"Compilation finished with exit code {status}.")
    if status != 0:
        print("\033[91mError during compilation. Exiting script.\033[0m")
        exit(1)

def sv_sim(run_vcs_dir: str, tests: list = None, programs: list = None, out_dir: str = ""):
    for prog in programs:
        for test in tests:
            test_idx = 0
            print(f"Running test: {test} with program: {prog}")
            cmd = [
                "python3", f"{run_vcs_dir}/run-vcs.py",
                "-out_dir", out_dir,
                "--rtl-sim-only",
                "-test", test,
                "-program", prog,
                "-test_idx", str(test_idx),
                "-uvm_verbosity", "UVM_NONE",
                "-asf", "+rand_stall_obi_disable"
            ]
            result = subprocess.run(cmd)
            status = result.returncode
            print(f"\033[92mTest {test} with program {prog} finished with exit code {status}.\033[0m")
            if status != 0:
                print(f"\033[91mError running test {test} with program {prog}. Exiting script.\033[0m")
                failed_tests.append(f"Test {test} with program {prog} FAILED!")
            else:
                passed_tests.append(f"Test {test} with program {prog} PASSED!")

if __name__ == "__main__":

    ap = argparse.ArgumentParser(description="Compile, run simulations, and extract results.")
    ap.add_argument("--out_dir", type=str, required=True, help="Base directory for output")
    args = ap.parse_args()

    script_dir = os.path.dirname(os.path.abspath(__file__))

    run_vcs_dir = os.path.join(script_dir, "..", "..")

    print(f"Script directory: {script_dir}")

    config_path = os.path.join(script_dir, "perf_analyzer_config.yml")
    with open(config_path, "r") as f:
        config = yaml.safe_load(f)
    TEST_LIST = config.get("test_list", [])
    PROGRAM_LIST = config.get("program_list", [])

    sv_compile(run_vcs_dir=run_vcs_dir, out_dir=args.out_dir)
    compile_programs(out_dir=args.out_dir, programs=PROGRAM_LIST)
    sv_sim(run_vcs_dir=run_vcs_dir, out_dir=args.out_dir, tests=TEST_LIST, programs=PROGRAM_LIST)

    print("\nSummary of Test Results:")
    for test in passed_tests:
        print(f"\033[92m{test}\033[0m")
    for test in failed_tests:
        print(f"\033[91m{test}\033[0m")

    # extract_results()