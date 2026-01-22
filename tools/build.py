#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent


def run(cmd, *, env=None):
    subprocess.check_call(cmd, cwd=ROOT, env=env)


def env_truthy(name):
    value = os.getenv(name, "")
    return value.lower() in {"1", "true", "yes", "on"}


def ensure_submodules(skip):
    if skip:
        return

    run(["git", "submodule", "update", "--init", "--recursive"])

    required = [
        "OpenSceneGraph",
        "simbody",
        "opensim3-scone",
    ]
    missing = [name for name in required if not (ROOT / name).exists()]
    if missing:
        names = ", ".join(missing)
        raise RuntimeError(
            f"Missing dependency submodules: {names}. "
            "Add them as git submodules and retry."
        )


def main():
    parser = argparse.ArgumentParser(
        description="Build SCONE and dependencies from source."
    )
    parser.add_argument("--no-install-deps", action="store_true")
    parser.add_argument("--skip-submodules", action="store_true")
    parser.add_argument("--skip-osg", action="store_true")
    parser.add_argument("--skip-simbody", action="store_true")
    parser.add_argument("--skip-opensim3", action="store_true")
    parser.add_argument("--skip-scone", action="store_true")
    parser.add_argument("--skip-install-tree", action="store_true")
    parser.add_argument("--skip-package", action="store_true")
    args = parser.parse_args()

    on_macos = sys.platform == "darwin"
    on_linux = sys.platform.startswith("linux")

    ensure_submodules(args.skip_submodules)

    if on_macos:
        if not args.no_install_deps:
            run(["./tools/mac_1_get-dependencies"])
    elif on_linux:
        if not args.no_install_deps:
            run(["./tools/linux_1_get-dependencies"])
    else:
        raise RuntimeError(f"Unsupported platform: {sys.platform}")

    if not args.skip_osg and not env_truthy("CACHE_OSG_HIT"):
        run(["./tools/unix_2a_build-osg"])

    if not args.skip_simbody and not env_truthy("CACHE_SIMBODY_HIT"):
        run(["./tools/unix_2b_build-simbody-fix"])

    if not args.skip_opensim3 and not env_truthy("CACHE_OPENSIM3_HIT"):
        run(["./tools/unix_2c_build-opensim3-fix"])

    if not args.skip_scone:
        run(["./tools/unix_2d_build-scone"])

    if on_linux:
        if not args.skip_install_tree:
            run(["./tools/linux_3_create-install-dirtree"])
        if not args.skip_package:
            run(["./tools/linux_4_package"])
    else:
        if not args.skip_install_tree:
            run(["./tools/mac_3_create-install-dirtree"])


if __name__ == "__main__":
    main()
