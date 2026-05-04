#!/usr/bin/env python3

import shutil
import subprocess
import sys
import time
from pathlib import Path

BD = Path("build-release")
NAME = "Arabic-Lexicons"

USAGES = """Usage: rel.py <COMMAND>
COMMANDS:
    bundle, b   build just the bundle
    split, s    build only arm64
    all, a      build all 4 apk
    full, f     build all 4 apk, and bundle"""


def run(cmd):
    print("running:", " ".join(cmd))
    subprocess.run(cmd, check=True)


def get_version():
    for line in Path("pubspec.yaml").read_text().splitlines():
        if line.startswith("version:"):
            return line.split("version:")[1].strip().split("+")[0]
    return ""


def get_git_commit():
    return (
        subprocess.check_output(["git", "rev-parse", "--short", "HEAD"])
        .decode()
        .strip()
    )


def get_git_message():
    msg = subprocess.check_output(["git", "log", "-1", "--pretty=%B"]).decode()
    return " ".join(msg.strip().split())


def reset_build_dir():
    if BD.exists():
        ans = input(f"Delete {BD} [Y/n] ").strip().lower()
        if ans in ("", "y"):
            shutil.rmtree(BD)
            print(f"removing: {BD}")
        else:
            print(f"Keeping: {BD}")
            return

    BD.mkdir()


def build_args(ver, gc, gcm):
    return [
        f"--dart-define=APP_VERSION={ver}",
        f"--dart-define=BUILD_UNIX_TIME={int(time.time())}",
        f"--dart-define=GIT_COMMIT={gc}",
        f"--dart-define=GIT_COMMIT_MSG={gcm}",
    ]


def main():
    if len(sys.argv) < 2:
        print(USAGES)
        sys.exit(1)

    cmd = sys.argv[1].lower()

    ver = get_version()
    gc = get_git_commit()
    gcm = get_git_message()

    prefix = BD / NAME
    if ver:
        prefix = Path(f"{prefix}_v{ver}")

    reset_build_dir()
    common = build_args(ver, gc, gcm)

    base = "build/app/outputs/"

    # ---- BUNDLE ----
    if cmd in ("bundle", "b"):
        run(["flutter", "build", "appbundle", "--release", *common])
        shutil.copy(
            base + "bundle/release/app-release.aab",
            f"{prefix}.aab",
        )
        return

    # ---- SPLIT (arm64 only) ----
    if cmd in ("split", "s"):
        run(
            [
                "flutter",
                "build",
                "apk",
                "--release",
                "--split-per-abi",
                "--target-platform=android-arm64",
                "--no-tree-shake-icons",
                *common,
            ]
        )
        shutil.copy(
            base + "flutter-apk/app-arm64-v8a-release.apk",
            f"{prefix}_arm64-v8a.apk",
        )
        return

    # ---- ALL (split all ABIs) ----
    if cmd in ("all", "a"):
        run(["flutter", "build", "apk", "--release", "--split-per-abi", *common])

        apk_base = base + "flutter-apk/"
        shutil.copy(apk_base + "app-arm64-v8a-release.apk", f"{prefix}_arm64-v8a.apk")
        shutil.copy(
            apk_base + "app-armeabi-v7a-release.apk", f"{prefix}_armeabi-v7a.apk"
        )
        shutil.copy(apk_base + "app-x86_64-release.apk", f"{prefix}_x86_64.apk")
        return

    # ---- FULL (everything) ----
    if cmd in ("full", "f"):
        # split builds
        run(["flutter", "build", "apk", "--release", "--split-per-abi", *common])

        apk_base = base + "flutter-apk/"
        shutil.copy(apk_base + "app-arm64-v8a-release.apk", f"{prefix}_arm64-v8a.apk")
        shutil.copy(
            apk_base + "app-armeabi-v7a-release.apk", f"{prefix}_armeabi-v7a.apk"
        )
        shutil.copy(apk_base + "app-x86_64-release.apk", f"{prefix}_x86_64.apk")

        # universal
        run(["flutter", "build", "apk", "--release", *common])
        shutil.copy(apk_base + "app-release.apk", f"{prefix}_universal.apk")

        # bundle
        run(["flutter", "build", "appbundle", "--release", *common])
        shutil.copy(
            base + "bundle/release/app-release.aab",
            f"{prefix}.aab",
        )
        return

    print(f"Unknown command: {cmd}")
    sys.exit(1)


if __name__ == "__main__":
    main()
