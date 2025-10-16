import os
import subprocess
from datetime import datetime
import getpass
import argparse

TEST_LIST = ["uvmt_cv32e20_firmware_test_c", "uvmt_cv32e20_model_test_c"]
PROGRAM_LIST = ["hello-world", "fibonacci", "riscv_arithmetic_basic_test_0"]

def compile_programs(out_dir: str, programs: list = PROGRAM_LIST):
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

def run_sims(run_vcs_dir: str, tests: list = TEST_LIST, programs: list = PROGRAM_LIST, out_dir: str = ""):
    for prog in programs:
        for test in tests:
            print(f"Running test: {test} with program: {prog}")
            cmd = [
                "python3", "{run_vcs_dir}/run_vcs.py",
                "--out_dir", out_dir,
            ]
            result = subprocess.run(cmd)
            status = result.returncode
            print(f"\033[92mTest {test} with program {prog} finished with exit code {status}.\033[0m")
            if status != 0:
                print(f"\033[91mError running test {test} with program {prog}. Exiting script.\033[0m")
                exit(1)

# def compile(run_vcs_dir: str, out_dir: str):
#     cmd = sv_compile_cmd
#     result = subprocess.run(cmd)
#     status = result.returncode
#     print(f"Compilation finished with exit code {status}.")
#     if status != 0:
#         print("\033[91mError during compilation. Exiting script.\033[0m")
#         exit(1)

if __name__ == "__main__":

    ap = argparse.ArgumentParser(description="Compile, run simulations, and extract results.")
    ap.add_argument("--out_dir", type=str, required=True, help="Base directory for output")
    ap.add_argument("-core", type=str, default="cv32e20", help="Core name, default is cv32e20")
    args = ap.parse_args()

    script_dir = os.path.dirname(os.path.abspath(__file__))

    run_vcs_dir = os.path.join(script_dir, "..")

    print(f"Script directory: {script_dir}")

    # compile(run_vcs_dir=run_vcs_dir, out_dir=args.out_dir)
    compile_programs(out_dir=args.out_dir, programs=PROGRAM_LIST)
    # run_sims(run_vcs_dir=run_vcs_dir, out_dir=args.out_dir, tests=TEST_LIST, programs=PROGRAM_LIST)

    # extract_results()