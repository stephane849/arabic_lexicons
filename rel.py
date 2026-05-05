#!/usr/bin/env python3

import shutil
import subprocess
import sys
import time
from pathlib import Path

# ---- COLOR SETUP (cross-platform) ----
try:
    from colorama import Fore, Style, init

    init()
    R = Fore.RED
    G = Fore.GREEN
    Y = Fore.YELLOW
    B = Fore.BLUE
    C = Fore.CYAN
    X = Style.RESET_ALL
except ImportError:
    # fallback (no colors)
    R = G = Y = B = C = X = ""

BD = Path("build-release")
NAME = "Arabic-Lexicons"


def parse_args():
    cmd = None
    out_dir = BD

    args = sys.argv[1:]
    i = 0

    while i < len(args):
        a = args[i]

        if a in ("-o", "--out"):
            i += 1
            if i >= len(args):
                print(f"{R}ERROR:{X} Missing value for --out")
                sys.exit(1)
            out_dir = Path(args[i])

        elif cmd is None:
            cmd = a.lower()

        else:
            print(f"{R}ERROR:{X} Unknown arg: {a}")
            sys.exit(1)

        i += 1

    if not cmd:
        print_usage()
        sys.exit(1)

    return cmd, out_dir


def print_usage():
    print(
        f"""{Y}Usage:{X} rel.py <COMMAND> [-o DIR]

COMMANDS:
    bundle, b   build just the bundle
    split, s    build only arm64
    all, a      build all 3 apk
    full, f     build all + universal + bundle

OPTIONS:
    -o, --out   output directory (default: {BD})
"""
    )


def run(cmd):
    print(f"{C}RUN:{X}", " ".join(cmd))
    subprocess.run(cmd, check=True)


def copy(src, dst):
    print(f"{G}COPY:{X} {src} -> {dst}")
    shutil.copy(src, dst)


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


def reset_build_dir(out_dir):
    if out_dir.exists():
        ans = input(f"{Y}Delete {out_dir} [Y/n]{X} ").strip().lower()
        if ans in ("", "y"):
            print(f"{R}DELETE:{X} {out_dir}")
            shutil.rmtree(out_dir)
        else:
            print(f"{B}KEEP:{X} {out_dir}")
            return

    print(f"{G}MKDIR:{X} {out_dir}")
    out_dir.mkdir(parents=True, exist_ok=True)


def build_args(ver, gc, gcm):
    return [
        f"--dart-define=APP_VERSION={ver}",
        f"--dart-define=BUILD_UNIX_TIME={int(time.time())}",
        f"--dart-define=GIT_COMMIT={gc}",
        f"--dart-define=GIT_COMMIT_MSG={gcm}",
    ]


def main():
    cmd, out_dir = parse_args()

    ver = get_version()
    gc = get_git_commit()
    gcm = get_git_message()

    prefix = out_dir / NAME
    if ver:
        prefix = Path(f"{prefix}_v{ver}")

    reset_build_dir(out_dir)
    common = build_args(ver, gc, gcm)

    base = "build/app/outputs/"

    # ---- BUNDLE ----
    if cmd in ("bundle", "b"):
        run(["flutter", "build", "appbundle", "--release", *common])
        copy(base + "bundle/release/app-release.aab", f"{prefix}.aab")
        return

    # ---- SPLIT ----
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
        copy(
            base + "flutter-apk/app-arm64-v8a-release.apk",
            f"{prefix}_arm64-v8a.apk",
        )
        return

    # ---- ALL ----
    if cmd in ("all", "a"):
        run(["flutter", "build", "apk", "--release", "--split-per-abi", *common])

        apk_base = base + "flutter-apk/"
        copy(apk_base + "app-arm64-v8a-release.apk", f"{prefix}_arm64-v8a.apk")
        copy(apk_base + "app-armeabi-v7a-release.apk", f"{prefix}_armeabi-v7a.apk")
        copy(apk_base + "app-x86_64-release.apk", f"{prefix}_x86_64.apk")
        return

    # ---- FULL ----
    if cmd in ("full", "f"):
        run(["flutter", "build", "apk", "--release", "--split-per-abi", *common])

        apk_base = base + "flutter-apk/"
        copy(apk_base + "app-arm64-v8a-release.apk", f"{prefix}_arm64-v8a.apk")
        copy(apk_base + "app-armeabi-v7a-release.apk", f"{prefix}_armeabi-v7a.apk")
        copy(apk_base + "app-x86_64-release.apk", f"{prefix}_x86_64.apk")

        run(["flutter", "build", "apk", "--release", *common])
        copy(apk_base + "app-release.apk", f"{prefix}_universal.apk")

        run(["flutter", "build", "appbundle", "--release", *common])
        copy(base + "bundle/release/app-release.aab", f"{prefix}.aab")
        return

    print(f"{R}ERROR:{X} Unknown command: {cmd}")
    sys.exit(1)


if __name__ == "__main__":
    main()
