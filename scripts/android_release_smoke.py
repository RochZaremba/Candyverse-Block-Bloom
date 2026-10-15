#!/usr/bin/env python3
"""Exercise an already signed production APK on an explicitly selected QA emulator.

Uses accessibility nodes and real Android input, not an instrumented entrypoint.
Never clears app data. Run on a fresh disposable emulator, not a player's phone.
"""
import argparse
import atexit
import json
from pathlib import Path
import re
import subprocess
import time
import xml.etree.ElementTree as ET

APP = 'com.renvo.candyverse'


def read_page_size(adb):
    try:
        size = int(adb('shell', 'getconf', 'PAGE_SIZE'))
    except (subprocess.CalledProcessError, ValueError):
        # Android7's shell image predates getconf; inspect its own VMA mapping.
        mapping = adb('shell', 'cat', '/proc/self/smaps')
        match = re.search(r'^KernelPageSize:\s+(\d+)\s+kB', mapping, re.MULTILINE)
        if match is None:
            raise RuntimeError('Could not determine kernel page size.')
        size = int(match[1])*1024
    if size not in (4096, 16384):
        raise RuntimeError(f'Unexpected page size: {size}')
    return size


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('apk', type=Path)
    parser.add_argument('--device', default='emulator-5554')
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--expected-page-size', type=int, choices=(4096, 16384))
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)

    def adb(*command, binary=False):
        result = subprocess.run(['adb', '-s', args.device, *command],
                                check=True, capture_output=True, timeout=90)
        return result.stdout if binary else result.stdout.decode().strip()

    @atexit.register
    def diagnostics():
        try:
            result = subprocess.run(
                ['adb', '-s', args.device, 'logcat', '-d', '-t', '2000',
                 'AndroidRuntime:E', 'libc:F', 'flutter:E', 'ActivityManager:I', 'lmkd:I', '*:S'],
                capture_output=True, timeout=20,
            )
            (args.output/'errors.log').write_bytes(result.stdout+result.stderr)
            state = subprocess.run(['adb', '-s', args.device, 'shell', 'dumpsys', 'activity', 'activities'], capture_output=True, timeout=20)
            (args.output/'activity-state.txt').write_bytes(state.stdout+state.stderr)
            exits = subprocess.run(['adb', '-s', args.device, 'shell', 'dumpsys', 'activity', 'exit-info', APP], capture_output=True, timeout=20)
            (args.output/'process-exits.txt').write_bytes(exits.stdout+exits.stderr)
            memory = subprocess.run(['adb', '-s', args.device, 'shell', 'cat', '/proc/meminfo'], capture_output=True, timeout=20)
            (args.output/'device-memory.txt').write_bytes(memory.stdout+memory.stderr)
        except (OSError, subprocess.TimeoutExpired) as error:
            (args.output/'diagnostics-error.txt').write_text(str(error))

    def nodes():
        adb('shell', 'rm', '-f', '/sdcard/candyverse-release-ui.xml')
        dumped = adb('shell', 'uiautomator', 'dump', '/sdcard/candyverse-release-ui.xml')
        if 'dumped to' not in dumped.lower():
            raise ValueError('UIAutomator did not produce a fresh hierarchy.')
        xml = adb('shell', 'cat', '/sdcard/candyverse-release-ui.xml')
        (args.output/'latest-ui.xml').write_text(xml)
        return list(ET.fromstring(xml[xml.index('<?xml'):]).iter('node'))

    def locate(pattern, seconds=90):
        deadline = time.monotonic()+seconds
        last_error = None
        while time.monotonic() < deadline:
            try:
                current_nodes = nodes()
            except (subprocess.CalledProcessError, ValueError, ET.ParseError) as error:
                last_error = error
                time.sleep(1)
                continue
            matches = []
            for node in current_nodes:
                label = node.get('text', '')+'\n'+node.get('content-desc', '')
                bounds = [int(v) for v in re.findall(r'\d+', node.get('bounds', ''))]
                if (re.search(pattern, label, re.MULTILINE) and len(bounds) == 4
                        and bounds[2] > bounds[0] and bounds[3] > bounds[1]):
                    matches.append(bounds)
            if matches:
                return min(matches, key=lambda b: (b[2]-b[0])*(b[3]-b[1]))
            time.sleep(1)
        try:
            data = adb('exec-out', 'screencap', '-p', binary=True)
            (args.output/'failure-screen.png').write_bytes(data)
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
            pass
        raise RuntimeError(f'Accessibility node not found: {pattern}; last dump error: {last_error}')

    def tap(pattern, vertical=.5):
        left, top, right, bottom = locate(pattern)
        x, y = (left+right)//2, top+int((bottom-top)*vertical)
        with (args.output/'tap-trace.jsonl').open('a') as trace:
            trace.write(json.dumps({'pattern': pattern, 'bounds': [left,top,right,bottom], 'tap': [x,y]})+'\n')
        adb('shell', 'input', 'tap', str(x), str(y))
        time.sleep(1)

    def capture(name):
        # Nodes identify the screen; give the actual native buffer time to draw.
        time.sleep(2)
        data = adb('exec-out', 'screencap', '-p', binary=True)
        if not data.startswith(b'\x89PNG\r\n\x1a\n') or len(data) < 20000:
            raise RuntimeError('Native screenshot is missing or appears unrendered.')
        (args.output/f'{name}.png').write_bytes(data)
        (args.output/f'{name}-memory.txt').write_text(adb('shell', 'dumpsys', 'meminfo', APP))

    def launch():
        result = adb('shell', 'am', 'start', '-W', '-n', APP+'/.MainActivity')
        with (args.output/'launch-results.txt').open('a') as log:
            log.write(result+'\n')

    (args.output/'display.txt').write_text(adb('shell', 'wm', 'size')+'\n'+adb('shell', 'wm', 'density')+'\n')
    page_size = read_page_size(adb)
    total_memory = int(re.search(r'MemTotal:\s+(\d+)', adb('shell', 'cat', '/proc/meminfo'))[1])
    if args.expected_page_size is not None and page_size != args.expected_page_size:
        raise RuntimeError(f'Expected page size {args.expected_page_size}, got {page_size}')
    adb('install', '-r', str(args.apk.resolve()))
    launch()
    locate(r'^GRAJ$')
    capture('release-home-pl')
    tap(r'^Ustawienia$')
    try:
        locate(r'^Prywatność$', seconds=8)
    except RuntimeError:
        adb('shell', 'input', 'swipe', '540', '1550', '540', '650', '400')
    # Android7 merges the actionable tile and non-actionable footer semantics.
    # Tap the visible title region rather than the combined panel's midpoint.
    tap(r'^Prywatność$', vertical=.2)
    locate(r'rochzaremba@gmail\.com')
    capture('release-privacy-pl')
    adb('shell', 'input', 'keyevent', '4')
    time.sleep(1)
    adb('shell', 'input', 'keyevent', '4')
    tap(r'^GRAJ$')
    locate(r'Wiersz 1, kolumna 1, puste')
    tap(r'^Klocek 1,')
    tap(r'Wiersz 1, kolumna 1, puste')
    locate(r'Wiersz 1, kolumna 1, zajęte')
    locate(r'Klocek 1 zużyty')
    capture('release-game-pl')
    # Real background/resume, followed by real process death and disk restore.
    adb('shell', 'input', 'keyevent', 'KEYCODE_HOME')
    launch()
    locate(r'Wiersz 1, kolumna 1, zajęte')
    adb('shell', 'am', 'force-stop', APP)
    launch()
    locate(r'^WZNÓW$')
    capture('release-home-resume-pl')
    tap(r'^WZNÓW$')
    locate(r'Wiersz 1, kolumna 1, zajęte')
    locate(r'Klocek 1 zużyty')
    capture('release-game-restored-pl')
    if not adb('shell', 'pidof', APP):
        raise RuntimeError('Production process exited.')
    report = {'status': 'PASS', 'applicationId': APP,
              'api': adb('shell', 'getprop', 'ro.build.version.sdk'),
              'pageSize': page_size, 'deviceMemTotalKiB': total_memory,
              'entrypoint': 'production', 'nativeInput': True,
              'backgroundResume': True, 'forceStopRestore': True,
              'representativeHardware': False}
    (args.output/'report.json').write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps(report))


if __name__ == '__main__':
    main()
