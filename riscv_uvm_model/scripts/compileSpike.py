#!/usr/bin/env python3
"""Run Spike-related steps from `make comp CV_CORE=cv32e20 SIMULATOR=vcs`."""

from __future__ import annotations

import shlex
import subprocess
from pathlib import Path


DEFAULT_JOBS = 8
DEFAULT_DRY_RUN = False


def run(cmd: str, cwd: Path | None = None, dry_run: bool = False) -> None:
    print(f"+ {cmd}")
    if dry_run:
        return
    subprocess.run(cmd, shell=True, check=True, cwd=None if cwd is None else str(cwd))


def main(argv: list[str] | None = None) -> int:
    # argv kept only for backward compatibility with existing callers.
    _ = argv

    jobs = DEFAULT_JOBS
    dry_run = DEFAULT_DRY_RUN

    repo_root = Path(__file__).resolve().parents[2]
    cv_core = "cv32e20"

    # `make comp` prereqs around Spike
    vcs_dir = repo_root / cv_core / "sim" / "uvmt" / "vcs_results" / "default" / "vcs.d"
    svlib_pkg = repo_root / cv_core / "vendor_lib" / "verilab" / "svlib"
    svlib_repo = "https://bitbucket.org/verilab/svlib/src/master/svlib"
    svlib_hash = "c25509a7e54a880fe8f58f3daa2f891d6ecf6428"

    # Spike locations from mk/Common.mk
    spike_path = repo_root / "vendor" / "riscv" / "riscv-isa-sim"
    build_dir = spike_path / "build"
    install_dir = repo_root / "tools" / "spike"

    run(f"mkdir -p {vcs_dir}", dry_run=dry_run)
    if not svlib_pkg.exists():
        run(
            "git clone "
            f"{shlex.quote(svlib_repo)} --recurse {shlex.quote(str(svlib_pkg))}; "
            f"cd {shlex.quote(str(svlib_pkg))}; "
            f"git checkout {shlex.quote(svlib_hash)}",
            dry_run=dry_run,
        )

    if not spike_path.exists():
        print("ERROR: Spike source tree is missing:")
        print(f"  {spike_path}")
        print("Initialize it first, for example:")
        print("  git submodule update --init --recursive vendor/riscv/riscv-isa-sim")
        return 2

    # Same sequence as mk/Common.mk:697-702 (`spike_lib`)
    run(f"mkdir -p {build_dir}", dry_run=dry_run)
    run(
        f"[ ! -f {build_dir}/config.log ] && cd {build_dir} && ../configure --prefix={install_dir} || true",
        dry_run=dry_run,
    )
    run(f"make -C {build_dir}/ -j {jobs} yaml-cpp-static", dry_run=dry_run)
    run(f"make -C {build_dir}/ -j {jobs} yaml-cpp", dry_run=dry_run)
    run(f"make -C {build_dir}/ -j {jobs} install", dry_run=dry_run)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
