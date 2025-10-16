import os
import subprocess
from datetime import datetime
import getpass

tests = ["uvmt_cv32e20_firmware_test_c", "uvmt_cv32e20_model_test_c"]
programs = ["hello-world", "fibonacci", "riscv_arithmetic_basic_test_0"]

# Get current date time and username
datetime_str = datetime.now().strftime("%Y%m%d_%H%M%S")
username = getpass.getuser()

# Create the output directory
base_dir = f"/scratch/{username}/riscv/{datetime_str}"
os.makedirs(base_dir, exist_ok=True)
print(f"Created directory: {base_dir}")

for prog in programs:
    for test in tests:
        out_dir = f"{test}_{prog}"
        print(f"Running test: {test} with program: {prog}")
        cmd = [
            "python3", "run-vcs.py",
            "-test", test,
            "-march", "rv32imc_zicsr",
            "-program", prog,
            "-out_dir", f"{base_dir}/{out_dir}"
        ]
        result = subprocess.run(cmd)
        status = result.returncode
        print(f"Test {test} with program {prog} finished with exit code {status}.")
        if status != 0:
            print(f"Error running test {test} with program {prog}. Exiting script.")
            exit(1)
