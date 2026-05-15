#!/usr/bin/env python3

from __future__ import annotations

import argparse
import shlex
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path

# ---- COLOR SETUP ----
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
    R = G = Y = B = C = X = ""

NAME = "Arabic-Lexicons"
DEFAULT_OUT = Path("build-release")

ALIASES = {
    "b": "bundle",
    "bundle": "bundle",
    "s": "split",
    "split": "split",
    "a": "all",
    "all": "all",
    "d": "fdroid",
    "fdroid": "fdroid",
    "f": "full",
    "full": "full",
}


class BuildError(Exception):
    pass


@dataclass(slots=True)
class Config:
    command: str
    out_dir: Path
    force: bool


class Builder:
    def __init__(self, config: Config):
        self.config = config

        self.version = self.get_version()

        self.git_commit = self.safe_git(
            "rev-parse",
            "--short",
            "HEAD",
            default="unknown",
        )

        self.git_message = self.safe_git(
            "log",
            "-1",
            "--pretty=%B",
            default="unknown",
        )

        self.base = Path("build/app/outputs")

        self.prefix = self.config.out_dir / NAME

        if self.version:
            self.prefix = Path(f"{self.prefix}_v{self.version}")

    # ---------------------------------------------------------
    # logging
    # ---------------------------------------------------------

    def info(self, msg: str):
        print(f"{B}INFO:{X} {msg}")

    def success(self, msg: str):
        print(f"{G}OK:{X} {msg}")

    def error(self, msg: str):
        print(f"{R}ERROR:{X} {msg}", file=sys.stderr)

    # ---------------------------------------------------------
    # helpers
    # ---------------------------------------------------------

    def safe_git(self, *args: str, default: str = "") -> str:
        try:
            res = subprocess.run(
                ["git", *args],
                check=True,
                capture_output=True,
                text=True,
            )

            out = res.stdout.strip()

            return out or default

        except Exception:
            return default

    def get_version(self) -> str:
        pubspec = Path("pubspec.yaml")

        if not pubspec.exists():
            print('No pubspec.yaml')
            sys.exit(2)

        for line in pubspec.read_text(encoding="utf-8").splitlines():
            if line.startswith("version:"):
                return line.split("version:", 1)[1].strip().split("+", 1)[0]

        print('Could not get version info from pubspec.yaml')
        sys.exit(3)

    def build_args(self) -> list[str]:
        return [
            f"--dart-define=APP_VERSION={self.version or ''}",
            f"--dart-define=BUILD_UNIX_TIME={int(time.time())}",
            f"--dart-define=GIT_COMMIT={self.git_commit}",
            f"--dart-define=GIT_COMMIT_MSG={self.git_message}",
        ]

    def run(self, cmd: list[str]):
        print(f"{C}RUN:{X} {shlex.join(cmd)}")

        try:
            subprocess.run(cmd, check=True)

        except FileNotFoundError:
            raise BuildError(f"Command not found: {cmd[0]}")

        except subprocess.CalledProcessError as e:
            raise BuildError(f"Command failed ({e.returncode}): {shlex.join(cmd)}")

    def copy(self, src: str | Path, dst: str | Path):
        src = Path(src)
        dst = Path(dst)

        if not src.exists():
            raise BuildError(f"Missing build output: {src}")

        dst.parent.mkdir(parents=True, exist_ok=True)

        print(f"{G}COPY:{X} {src} -> {dst}")

        shutil.copy2(src, dst)

    def notify(self, msg: str):
        icon = Path.cwd() / "assets/icons/icon.png"

        cmd = [
            "notify-send",
            "-t",
            "100",
            "-a",
            "Arabic Lexicons Build",
            "-c",
            "ar-lex-build",
        ]

        if icon.exists():
            cmd += ["-i", str(icon)]

        cmd += ["Build", msg]

        try:
            subprocess.run(
                cmd,
                check=False,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )

        except Exception:
            pass

    # ---------------------------------------------------------
    # dirs
    # ---------------------------------------------------------

    def prepare_dir(self, path: Path):
        if not path.exists():
            print(f"{G}MKDIR:{X} {path}")
            path.mkdir(parents=True, exist_ok=True)
            return

        if self.config.force:
            print(f"{R}DELETE:{X} {path}")
            shutil.rmtree(path)

        else:
            if not sys.stdin.isatty():
                raise BuildError(f"{path} exists. Use --yes to overwrite.")

            ans = input(f"{Y}Delete {path} [Y/n]{X} ").strip().lower()

            if ans in ("", "y", "yes"):
                print(f"{R}DELETE:{X} {path}")
                shutil.rmtree(path)

            else:
                self.info(f"Keeping {path}")
                return

        print(f"{G}MKDIR:{X} {path}")
        path.mkdir(parents=True, exist_ok=True)

    def fdroid_dir(self) -> Path:
        if self.config.out_dir == DEFAULT_OUT:
            return Path("build-fdroid")

        return self.config.out_dir / "fdroid"

    # ---------------------------------------------------------
    # builds
    # ---------------------------------------------------------

    def build_bundle(self):
        common = self.build_args()

        self.run(
            [
                "flutter",
                "build",
                "appbundle",
                "--release",
                *common,
            ]
        )

        self.copy(
            self.base / "bundle/release/app-release.aab",
            f"{self.prefix}.aab",
        )

    def build_split(self):
        common = self.build_args()

        self.run(
            [
                "flutter",
                "build",
                "apk",
                "--release",
                "--split-per-abi",
                "--target-platform=android-arm64",
                *common,
            ]
        )

        apk = self.base / "flutter-apk"

        self.copy(
            apk / "app-arm64-v8a-release.apk",
            f"{self.prefix}_arm64-v8a.apk",
        )

    def build_all(self):
        common = self.build_args()

        apk = self.base / "flutter-apk"

        self.run(
            [
                "flutter",
                "build",
                "apk",
                "--release",
                "--split-per-abi",
                *common,
            ]
        )

        self.copy(
            apk / "app-arm64-v8a-release.apk",
            f"{self.prefix}_arm64-v8a.apk",
        )

        self.copy(
            apk / "app-armeabi-v7a-release.apk",
            f"{self.prefix}_armeabi-v7a.apk",
        )

        self.copy(
            apk / "app-x86_64-release.apk",
            f"{self.prefix}_x86_64.apk",
        )

        self.run(
            [
                "flutter",
                "build",
                "apk",
                "--release",
                *common,
            ]
        )

        self.copy(
            apk / "app-release.apk",
            f"{self.prefix}_universal.apk",
        )

    def build_fdroid(self):
        out = self.fdroid_dir()

        apk = self.base / "flutter-apk"

        self.run(
            [
                "flutter",
                "build",
                "apk",
                "--release",
                "--split-per-abi",
                f"--dart-define=APP_VERSION={self.version or ''}",
                "--dart-define=APP_STORE=F-Droid"
            ]
        )

        self.copy(
            apk / "app-arm64-v8a-release.apk",
            out / "app-arm64-v8a-release.apk",
        )

        self.copy(
            apk / "app-armeabi-v7a-release.apk",
            out / "app-armeabi-v7a-release.apk",
        )

        self.copy(
            apk / "app-x86_64-release.apk",
            out / "app-x86_64-release.apk",
        )

    def build_full(self):
        self.build_all()
        self.build_bundle()
        # self.build_fdroid()

    # ---------------------------------------------------------
    # execute
    # ---------------------------------------------------------

    def execute(self):
        cmd = self.config.command

        self.prepare_dir(self.config.out_dir)

        if cmd == "bundle":
            self.build_bundle()

        elif cmd == "split":
            self.build_split()

        elif cmd == "all":
            self.build_all()

        elif cmd == "fdroid":
            self.build_fdroid()

        elif cmd == "full":
            self.build_full()

        else:
            raise BuildError(f"Unknown command: {cmd}")

        self.notify(f"Build complete: {cmd}")


# ---------------------------------------------------------
# args
# ---------------------------------------------------------


def parse_args() -> Config:
    parser = argparse.ArgumentParser(
        prog="rel.py",
        add_help=True,
    )

    parser.add_argument(
        "command",
        help="bundle | split | all | fdroid | full",
    )

    parser.add_argument(
        "-o",
        "--out",
        default=str(DEFAULT_OUT),
        help="output directory",
    )

    parser.add_argument(
        "-y",
        "--yes",
        action="store_true",
        help="overwrite output dirs without asking",
    )

    ns = parser.parse_args()

    cmd = ALIASES.get(ns.command.lower())

    if not cmd:
        raise BuildError(f"Unknown command: {ns.command}")

    return Config(
        command=cmd,
        out_dir=Path(ns.out),
        force=ns.yes,
    )


# ---------------------------------------------------------
# main
# ---------------------------------------------------------


def main() -> int:
    try:
        config = parse_args()

        builder = Builder(config)

        builder.execute()

        return 0

    except KeyboardInterrupt:
        print(f"{Y}\nInterrupted.{X}", file=sys.stderr)
        return 130

    except BuildError as e:
        print(f"{R}ERROR:{X} {e}", file=sys.stderr)
        return 1

    except Exception as e:
        print(
            f"{R}UNEXPECTED ERROR:{X} {type(e).__name__}: {e}",
            file=sys.stderr,
        )
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
