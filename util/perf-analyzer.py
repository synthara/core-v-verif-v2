import os
import argparse

def get_cpu_time_from_log(log_path):
    print(f"Reading log file: {log_path}")
    try:
        with open(log_path, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
        # Search from the bottom for "CPU Time:"
        for line in reversed(lines):
            if "CPU Time:" in line:
                # Example: CPU Time:     35.010 seconds;
                parts = line.strip().split()
                for i, part in enumerate(parts):
                    if part == "CPU" and i+2 < len(parts) and parts[i+1] == "Time:":
                        # The next part should be the time value
                        try:
                            return float(parts[i+2])
                        except ValueError:
                            continue
                # Fallback: try to extract the float before "seconds;"
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

def compare_cpu_times(tests, programs, base_dir):
    # {program: {test: cpu_time}}
    cpu_times = {prog: {} for prog in programs}
    for prog in programs:
        for test in tests:
            log_path = os.path.join(base_dir, test + "_" + prog, "default", "vcs_results", "default", f"{prog}", "0", f"vcs-{prog}.log")
            cpu_time = get_cpu_time_from_log(log_path)
            cpu_times[prog][test] = cpu_time

    # Compare cpu times between tests for the same program
    for prog in programs:
        print(f"Program: {prog}")
        for test in tests:
            if cpu_times[prog][test] is None:
                print(f"\033[91m  Test: {test}, CPU Time: {cpu_times[prog][test]}\033[0m")
            else:
                print(f"  Test: {test}, CPU Time: {cpu_times[prog][test]}")
        
        # Find min/max/compare as needed
        times = [(test, cpu_times[prog][test]) for test in tests if cpu_times[prog][test] is not None]
        
        if times:
            min_test, min_time = min(times, key=lambda x: x[1])
            max_test, max_time = max(times, key=lambda x: x[1])
            perc_diff = (max_time - min_time) / min_time * 100
            print(f"    Fastest: {min_test} ({min_time} s), Slowest: {max_test} ({max_time} s) - Difference: {perc_diff:.2f}%")
        print()

# Example usage:
if __name__ == "__main__":
    tests = ["uvmt_cv32e20_firmware_test_c", "uvmt_cv32e20_model_test_c"]
    programs = ["hello-world", "fibonacci", "riscv_arithmetic_basic_test_0"]

    parser = argparse.ArgumentParser(description="Compare CPU times from log files.")
    parser.add_argument("--dir", type=str, required=True, help="Base directory containing log files")
    args = parser.parse_args()
    base_dir = args.dir

    compare_cpu_times(tests, programs, base_dir)