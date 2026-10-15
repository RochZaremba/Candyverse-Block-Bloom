#!/usr/bin/env python3
"""Exercise an already signed production APK on an explicitly selected QA emulator.

Uses accessibility nodes and real Android input, not an instrumented entrypoint.
Never clears app data. Run on a fresh disposable emulator, not a player's phone.
"""
import argparse
import json
from pathlib import Path
import re
import subprocess
import time
import xml.etree.ElementTree as ET

APP = 'com.renvo.candyverse'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('apk', type=Path)
    parser.add_argument('--device', default='emulator-5554')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)

    def adb(*command, binary=False):
        result = subprocess.run(['adb', '-s', args.device, *command],
                                check=True, capture_output=True, timeout=90)
        return result.stdout if binary else result.stdout.decode().strip()

    def nodes():
        adb('shell', 'uiautomator', 'dump', '/sdcard/candyverse-release-ui.xml')
        xml = adb('shell', 'cat', '/sdcard/candyverse-release-ui.xml')
        return list(ET.fromstring(xml[xml.index('<?xml'):]).iter('node'))

    def locate(pattern, seconds=90):
        deadline = time.monotonic()+seconds
        while time.monotonic() < deadline:
            matches = []
            for node in nodes():
                label = node.get('text', '')+'\n'+node.get('content-desc', '')
                bounds = [int(v) for v in re.findall(r'\d+', node.get('bounds', ''))]
                if (re.search(pattern, label, re.MULTILINE) and len(bounds) == 4
                        and bounds[2] > bounds[0] and bounds[3] > bounds[1]):
                    matches.append(bounds)
            if matches:
                return min(matches, key=lambda b: (b[2]-b[0])*(b[3]-b[1]))
            time.sleep(1)
        raise RuntimeError(f'Accessibility node not found: {pattern}')

    def tap(pattern):
        left, top, right, bottom = locate(pattern)
        adb('shell', 'input', 'tap', str((left+right)//2), str((top+bottom)//2))
        time.sleep(1)

    def capture(name):
        # Nodes identify the screen; give the actual native buffer time to draw.
        time.sleep(2)
        data = adb('exec-out', 'screencap', '-p', binary=True)
        if not data.startswith(b'\x89PNG\r\n\x1a\n') or len(data) < 20000:
            raise RuntimeError('Native screenshot is missing or appears unrendered.')
        (args.output/f'{name}.png').write_bytes(data)

    def launch():
        adb('shell', 'am', 'start', '-W', '-n', APP+'/.MainActivity')

    adb('install', '-r', str(args.apk.resolve()))
    launch()
    locate(r'^GRAJ$')
    capture('release-home-pl')
    tap(r'^Ustawienia$')
    try:
        locate(r'^Prywatność$', seconds=8)
    except RuntimeError:
        adb('shell', 'input', 'swipe', '540', '1550', '540', '650', '400')
    tap(r'^Prywatność$')
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
              'pageSize': adb('shell', 'getconf', 'PAGE_SIZE'),
              'entrypoint': 'production', 'nativeInput': True,
              'backgroundResume': True, 'forceStopRestore': True,
              'representativeHardware': False}
    (args.output/'report.json').write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps(report))


if __name__ == '__main__':
    main()
