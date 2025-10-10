"""
Requirements:
- Python 3.6+
- g++ compiler
- umsgpack (install via pip)

Directory Structure:
.
├── runner.py          # this script
├── solution.cpp      # C++ source file
└── testcases/        # Testcases directory
    └── solution.tc   # Testcases file in .tc format (umsgpack)

OR (using -tin and -tout for .txt testcases)
.
├── input.txt         # Input testcases in .txt format
├── output.txt        # Output testcases in .txt format
├── runner.py         # this script
└── solution.cpp      # C++ source file


What is .tc format?
- Binary file with the format that is used by Competitest.nvim when saving testcases to single file.
"""


import argparse
import subprocess
import sys
import time
from pathlib import Path

# pip install umsgpack
import umsgpack

SOURCE, EXECUTABLE, TIME_LIMIT, TC_FILE = " ", " ", 1.0, None
TXT_INPUT_FILE, TXT_OUTPUT_FILE = None, None
VERBOSE = False


def parse_args():
    global SOURCE, EXECUTABLE, TIME_LIMIT, TC_FILE, VERBOSE
    parser = argparse.ArgumentParser(
        description="Run C++ solutions against testcases"
    )

    parser.add_argument(
        "source", type=str, help="Path to the C++ source file (e.g., solution.cpp)"
    )

    parser.add_argument(
        "-t",
        "--time-limit",
        type=float,
        default=1.0,
        help="Execution timeout per testcase in seconds (default: 1.0)",
    )

    parser.add_argument(
        "-o",
        "--output-bin",
        type=str,
        default="./temp/main",
        help="Path to store compiled executable (default: ./temp/main)",
    )

    parser.add_argument(
        "--tc",
        type=str,
        default=None,
        help="Override testcases file (.tc). If not set, auto-derived from source file name.",
    )

    parser.add_argument(
        "-tin",
        "--txt-input",
        type=str,
        default=None,
        help="(Optional) Input file for .txt testcases (overrides .tc)",
    )

    parser.add_argument(
        "-tout",
        "--txt-output",
        type=str,
        default=None,
        help="(Optional) Output file for .txt testcases (overrides .tc)",
    )

    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Enable verbose output during execution",
    )

    args = parser.parse_args()

    # validate source
    source_path = Path(args.source)
    if not source_path.exists():
        parser.error(f"Source file '{args.source}' does not exist.")

    # resolve testcase file
    if args.tc:
        tc_file = Path(args.tc)
    else:
        testcases_dir = source_path.parent / "testcases"
        tc_file = Path.home() / testcases_dir / source_path.with_suffix(".tc").name

    SOURCE = str(source_path)
    EXECUTABLE = args.output_bin
    TIME_LIMIT = args.time_limit
    TC_FILE = tc_file
    VERBOSE = args.verbose
    global TXT_INPUT_FILE, TXT_OUTPUT_FILE
    TXT_INPUT_FILE = args.txt_input
    TXT_OUTPUT_FILE = args.txt_output
    if TXT_INPUT_FILE or TXT_OUTPUT_FILE:
        if not (TXT_INPUT_FILE and TXT_OUTPUT_FILE):
            parser.error(
                "Both --txt-input and --txt-output must be provided for .txt testcases."
            )
        TC_FILE = None  # Ignore .tc if .txt files are provided


def compile_code():
    print(f"--> [CODE] Compiling {SOURCE}...")
    result = subprocess.run(
        [
            "g++",
            "-std=c++17",
            "-O2",
            "-Wall",
            "-Wextra",
            "-Wshadow",
            "-Wconversion",
            SOURCE,
            "-o",
            EXECUTABLE,
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        print("[FAILED] Compilation Error")
        print(result.stderr.decode())
        sys.exit(1)
    print("--> [✔] Compilation successful!")


def load_testcases():
    # .tc -> open with binary mode
    # .txt -> open with text mode
    if TC_FILE:
        if not TC_FILE.exists():
            print(f"[ERROR] Testcases file {TC_FILE} not found")
            sys.exit(1)

        with open(TC_FILE, "rb") as f:
            tcs = umsgpack.unpack(f)
        decoded = {}
        for k, v in tcs.items():
            if b"input" in v or "input" in v:
                # Normalize key types (sometimes bytes keys)
                key = k.decode() if isinstance(k, bytes) else k
                inp = v.get("input") or v.get(b"input")
                out = v.get("output") or v.get(b"output")
                decoded[key] = {
                    "input": inp.decode() if isinstance(inp, bytes) else inp,
                    "output": out.decode() if isinstance(out, bytes) else out,
                }

        return decoded
    else:
        if not TXT_INPUT_FILE or not TXT_OUTPUT_FILE:
            print(
                "[ERROR] For .txt testcases, both --txt-input and --txt-output must be provided."
            )
            sys.exit(1)

        input_path = Path(TXT_INPUT_FILE)
        output_path = Path(TXT_OUTPUT_FILE)

        if not input_path.exists():
            print(f"[ERROR] Input file '{TXT_INPUT_FILE}' does not exist.")
            sys.exit(1)
        if not output_path.exists():
            print(f"[ERROR] Output file '{TXT_OUTPUT_FILE}' does not exist.")
            sys.exit(1)

        with open(input_path, "r") as fin, open(output_path, "r") as fout:
            inputs = fin.read().strip().split("\n\n")
            outputs = fout.read().strip().split("\n\n")

        if len(inputs) != len(outputs):
            print(
                "[ERROR] Number of input and output testcases do not match in .txt files."
            )
            sys.exit(1)

        tcs = {}
        for i, (inp, out) in enumerate(zip(inputs, outputs), start=1):
            tcs[str(i)] = {"input": inp.strip(), "output": out.strip()}

        return tcs


RED = "\033[31m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RESET = "\033[0m"
BLUE = "\033[94m"
CYAN = "\033[96m"
MAGENTA = "\033[95m"
WHITE = "\033[97m"


def run_test(tcnum, tc):
    if VERBOSE:
        print(f"\n[TESTCASE {tcnum}]")
        print("INPUT:")
        print(tc["input"])
        print("EXPECTED OUTPUT:")
        print(tc["output"])

    start = time.time()
    proc = None
    output = ""
    cause = ""

    try:
        proc = subprocess.run(
            [EXECUTABLE],
            input=tc["input"].encode(),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=TIME_LIMIT,
        )
        output = proc.stdout.decode().strip()
    except subprocess.TimeoutExpired:
        cause = "TLE"
        print(f"{YELLOW}[TIMEOUT] Execution exceeded {TIME_LIMIT}s{RESET}")
    except Exception as e:
        cause = "ERR"
        print(f"{RED}[ERROR] Unexpected failure: {e}{RESET}")

    end = time.time()
    expected = tc["output"].strip()

    # Runtime Error Handling
    if proc and proc.returncode != 0 and not cause:
        cause = "RE"
        print(f"{RED}[RUNTIME ERROR] Return code {proc.returncode}{RESET}")
        print(proc.stderr.decode())

    verdict = "AC" if output == expected else "WA"
    color = GREEN if verdict == "AC" else RED

    if VERBOSE:
        print("OUTPUT" + (" [INCORRECT]" if verdict == "WA" else "") + ":")
        print(output)
        print()

    return {
        "verdict": verdict,
        "time": end - start,
        "cause": cause,
        "output": output,
        "expected": expected,
    }


def main():
    compile_code()
    testcases = load_testcases()
    if not testcases:
        print("[WARN] No full testcases found!")
        return

    passed = 0
    total = len(testcases)
    print(f"--> [CHECKER] Running {total} testcases...\n")
    for tcnum, tc in sorted(testcases.items()):
        result = run_test(tcnum, tc)
        if result:
            verdict_color = GREEN if result["verdict"] == "AC" else RED

            print(
                f"{BLUE}TEST #{tcnum}{RESET}  "
                f"{YELLOW}|{RESET}  "
                f"{verdict_color}VERDICT: {result['verdict']}{RESET}  "
                f"{YELLOW}|{RESET}  "
                f"{CYAN}TIME: {result['time']:.3f}s{RESET}"
            )

            if result["verdict"] == "WA":
                print(
                    f"{YELLOW}Expected:{RESET}\n{result['expected']}\n\n{RED}Got:{RESET}\n{result['output']}\n"
                )

            if result["verdict"] == "AC":
                passed += 1
                # print(f"{GREEN}{passed}/{total} testcases passed! {RESET}")

    print("\n--> [SUMMARY]")
    if passed == total:
        print(f"{GREEN}[PASSED] All {total} testcases passed! {RESET}")
    elif passed > 0:
        print(f"{RED}[FAILED] {total - passed}/{total} testcases failed.{RESET}")
    else:
        print(f"{RED}[FAILED] All {total} testcases failed.{RESET}")

    print()


if __name__ == "__main__":
    parse_args()
    main()
