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

    extract_results(tests, programs, base_dir)
        Extracts and compares CPU times from simulation log files.
        Args:
            tests (list): List of test names.
            programs (list): List of program names.
            base_dir (str): Base output directory containing log files.
        def get_cpu_time_from_log(log_path):
        Extracts CPU time from a given log file.
        Args:
            log_path (str): Path to the log file.
        Returns:
            float or None: Extracted CPU time in seconds, or None if not found.

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

def extract_results(tests, programs, base_dir):
    """
    Extracts and compares CPU times from simulation log files.

    Args:
        tests (list): List of test names.
        programs (list): List of program names.
        base_dir (str): Base output directory containing log files.
    """
    def get_cpu_time_from_log(log_path):
        try:
            with open(log_path, 'r', encoding='utf-8', errors='ignore') as f:
                lines = f.readlines()
            for line in reversed(lines):
                if "CPU Time:" in line:
                    parts = line.strip().split()
                    for i, part in enumerate(parts):
                        if part == "CPU" and i+2 < len(parts) and parts[i+1] == "Time:":
                            try:
                                return float(parts[i+2])
                            except ValueError:
                                continue
                    try:
                        idx = line.index("CPU Time:")
                        after = line[idx+len("CPU Time:"):].strip()
                        time_str = after.split()[0]
                        return float(time_str)
                    except Exception:
                        continue
            return None
        except FileNotFoundError:
            return None

    cpu_times = {prog: {} for prog in programs}
    for prog in programs:
        for test in tests:
            log_path = os.path.join(base_dir, "default", "vcs_results", "default", f"{prog}", "0", f"vcs-{test}_{prog}.log")
            print(f"Processing log file: {log_path}")
            cpu_time = get_cpu_time_from_log(log_path)
            cpu_times[prog][test] = cpu_time

    for prog in programs:
        print(f"Program: {prog}")
        for test in tests:
            if cpu_times[prog][test] is None:
                print(f"\033[91m  Test: {test}, CPU Time: {cpu_times[prog][test]}\033[0m")
            else:
                print(f"  Test: {test}, CPU Time: {cpu_times[prog][test]}")
        times = [(test, cpu_times[prog][test]) for test in tests if cpu_times[prog][test] is not None]
        if times:
            min_test, min_time = min(times, key=lambda x: x[1])
            max_test, max_time = max(times, key=lambda x: x[1])
            perc_diff = (max_time - min_time) / min_time * 100
            print(f"    Fastest: {min_test} ({min_time} s), Slowest: {max_test} ({max_time} s) - Difference: {perc_diff:.2f}%")
        print()

if __name__ == "__main__":

    ap = argparse.ArgumentParser(description="Compile, run simulations, and extract results.")
    ap.add_argument("--out_dir", type=str, required=False, default=None, help="Base directory for output")
    args = ap.parse_args()

    script_dir = os.path.dirname(os.path.abspath(__file__))

    run_vcs_dir = os.path.join(script_dir, "..", "..")

    print(f"Script directory: {script_dir}")

    config_path = os.path.join(script_dir, "perf_analyzer_config.yml")
    with open(config_path, "r") as f:
        config = yaml.safe_load(f)
    TEST_LIST = config.get("test_list", [])
    PROGRAM_LIST = config.get("program_list", [])

    if not args.out_dir:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        username = getpass.getuser()
        args.out_dir = os.path.join("/", "scratch", username, "riscv_uvm_model", "perf_analyzer", timestamp)

        print(f"\033[93mNo output directory specified. Using default: {args.out_dir}\033[0m")
        
        if not os.path.exists(args.out_dir):
            try:
                os.makedirs(args.out_dir, exist_ok=True)
            except Exception as e:
                print(f"\033[91mFailed to create directory {args.out_dir}: {e}\033[0m")
                exit(1)
            print(f"Directory {args.out_dir} does not exist. Creating...")

    # 1. Compile RTL once
    sv_compile(run_vcs_dir=run_vcs_dir, out_dir=args.out_dir)
    # 2. Compile all the requested software programs
    compile_programs(out_dir=args.out_dir, programs=PROGRAM_LIST)
    # 3. Run simulations for all tests and programs
    sv_sim(run_vcs_dir=run_vcs_dir, out_dir=args.out_dir, tests=TEST_LIST, programs=PROGRAM_LIST)

    print("\nSummary of Test Results:")
    for test in passed_tests:
        print(f"\033[92m{test}\033[0m")
    for test in failed_tests:
        print(f"\033[91m{test}\033[0m")

    # 4. Extract and compare the timing statistics from the logs
    extract_results(tests=TEST_LIST, programs=PROGRAM_LIST, base_dir=args.out_dir)