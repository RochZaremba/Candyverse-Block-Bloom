#!/usr/bin/env python3
"""Capture stable QA milestones from the native surface without changing Flutter's renderer."""
import argparse
from pathlib import Path
import re
import signal
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--device', required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    adb = ['adb', '-s', args.device]
    # Never capture a player's physical phone from this automated observer.
    is_emulator = subprocess.check_output(
        [*adb, 'shell', 'getprop', 'ro.kernel.qemu'], timeout=20,
    ).decode().strip() == '1'
    if not is_emulator:
        raise SystemExit('Milestone observer requires a disposable QA emulator.')

    def stop(*_):
        raise SystemExit(0)

    signal.signal(signal.SIGTERM, stop)
    process = subprocess.Popen(
        [*adb, 'logcat', '-v', 'raw', 'flutter:I', '*:S'],
        stdout=subprocess.PIPE, text=True,
    )
    try:
        for line in process.stdout:
            match = re.search(r'QA milestone: ([a-z0-9-]+)\s*$', line)
            if match is None:
                continue
            name = match[1]
            result = subprocess.run(
                [*adb, 'exec-out', 'screencap', '-p'],
                capture_output=True, timeout=20,
            )
            if (result.returncode or not result.stdout.startswith(b'\x89PNG\r\n\x1a\n')
                    or len(result.stdout) < 20000):
                raise RuntimeError(f'Native screenshot failed at {name}')
            (args.output / f'{name}.png').write_bytes(result.stdout)
            print(f'Captured native milestone: {name}', flush=True)
    finally:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()


if __name__ == '__main__':
    main()
