#!/usr/bin/env python3
"""Fail closed on unexpected manifest data and native alignment in an APK."""
import argparse
import os
from pathlib import Path
import re
import struct
import subprocess
import zipfile

APP_ID = 'com.renvo.candyverse'
DOMAINS = {'root', 'file', 'database', 'sharedpref', 'external',
           'device_root', 'device_file', 'device_database', 'device_sharedpref'}


def command(*args):
    return subprocess.run(args, check=True, text=True, capture_output=True).stdout


def elf_segments(data):
    if len(data) < 64 or data[:4] != b'\x7fELF' or data[4] != 2 or data[5] not in (1, 2):
        raise ValueError('Expected a 64-bit ELF library.')
    endian = '<' if data[5] == 1 else '>'
    offset = struct.unpack_from(endian+'Q', data, 32)[0]
    size, count = struct.unpack_from(endian+'HH', data, 54)
    if size != 56 or offset+count*size > len(data):
        raise ValueError('Invalid ELF program header table.')
    for index in range(count):
        kind, flags, file_offset, address, physical, file_size, memory_size, alignment = struct.unpack_from(
            endian+'IIQQQQQQ', data, offset+index*size)
        yield kind, alignment, file_offset, address, memory_size


def validate_elf(data, name='library'):
    segments = list(elf_segments(data))
    if not any(kind == 1 for kind, *_ in segments):
        raise ValueError('ELF has no loadable segments.')
    for kind, alignment, offset, address, memory_size in segments:
        if kind == 1 and (alignment < 16384 or offset % alignment != address % alignment):
            raise ValueError(f'16KB PT_LOAD alignment failed: {name}')
        if kind == 0x6474e552 and (address+memory_size) % 16384:
            # Bionic can safely protect the full LOAD when RELRO
            # starts at the same address and covers its memory size.
            # A bare end-modulo check incorrectly rejects Flutter.
            suffix = any(load_kind == 1 and load_address == address
                         and load_size <= memory_size
                         for load_kind, _, _, load_address, load_size in segments)
            if not suffix:
                raise ValueError(f'16KB partial RELRO alignment failed: {name}')

def packaged_xml(resources, name):
    # Release resource shrinking renames ZIP paths; resolve through resources.arsc.
    entry = re.search(
        r'resource (0x[0-9a-f]+) (?:'+re.escape(APP_ID)+r':)?xml/'+re.escape(name)
        +r'\b\n\s+\(\) \(file\) (res/[^\s]+\.xml) type=XML', resources)
    if entry is None or '..' in entry[2].split('/'):
        raise ValueError(f'Missing default XML resource: {name}')
    return entry[1], entry[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('apk', type=Path)
    parser.add_argument('--debug', action='store_true', help='Explicit development artifact audit, not publication approval.')
    parser.add_argument('--preview', action='store_true', help='Audit the separate preview application ID; requires --debug.')
    parser.add_argument('--sdk', type=Path, default=Path(os.environ.get('ANDROID_SDK_ROOT', Path.home()/'Android/Sdk')))
    args = parser.parse_args()
    if args.preview and not args.debug:
        parser.error('--preview requires --debug; preview is not a signed release.')
    expected_id = APP_ID + ('.preview' if args.preview else '')
    tools = sorted((args.sdk/'build-tools').iterdir(), key=lambda p: [int(v) for v in re.findall(r'\d+', p.name)])[-1]
    aapt = str(tools/'aapt2')
    apk = str(args.apk.resolve())
    badging = command(aapt, 'dump', 'badging', apk)
    manifest = command(aapt, 'dump', 'xmltree', apk, '--file', 'AndroidManifest.xml')
    if f"package: name='{expected_id}'" not in badging:
        raise ValueError('Unexpected application ID.')
    if "minSdkVersion:'24'" not in badging or "targetSdkVersion:'36'" not in badging:
        raise ValueError('Expected minSdk24 and targetSdk36.')
    permissions = set(re.findall(r"uses-permission: name='([^']+)'", badging))
    expected = {expected_id+'.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION'}
    if args.debug:
        expected.add('android.permission.INTERNET')
    if permissions-expected:
        raise ValueError(f'Unexpected permissions: {sorted(permissions-expected)}')
    if not args.debug and re.search(r':(?:debuggable|testOnly)\([^\n]+\)=true', manifest):
        raise ValueError('Release artifact is debuggable or test-only.')
    if not re.search(r':allowBackup\([^\n]+\)=false', manifest):
        raise ValueError('Backup is not disabled.')
    resources = command(aapt, 'dump', 'resources', apk)
    for name, attribute in [('backup_rules', 'fullBackupContent'), ('data_extraction_rules', 'dataExtractionRules')]:
        resource_id, resource_path = packaged_xml(resources, name)
        if not re.search(r':'+attribute+r'\([^\n]+\)=@'+resource_id, manifest):
            raise ValueError(f'Manifest must reference the packaged {name}.')
        tree = command(aapt, 'dump', 'xmltree', apk, '--file', resource_path)
        sections = [tree] if name == 'backup_rules' else re.split(r'E: (?:cloud-backup|device-transfer) ', tree)[1:]
        if len(sections) != (1 if name == 'backup_rules' else 2):
            raise ValueError('Missing cloud or device-transfer backup exclusions.')
        for section in sections:
            excluded = set(re.findall(r'A: domain="([^"]+)"', section))
            if (excluded != DOMAINS or section.count('A: path="."') != len(DOMAINS)
                    or section.count('E: exclude') != len(DOMAINS) or 'E: include' in section):
                raise ValueError('Incomplete packaged backup-domain exclusions.')
    aligned = []
    with zipfile.ZipFile(args.apk) as archive:
        for name in archive.namelist():
            if re.match(r'lib/(arm64-v8a|x86_64)/.+\.so$', name):
                validate_elf(archive.read(name), name)
                aligned.append(name)
    if not aligned:
        raise ValueError('No 64-bit Flutter libraries found.')
    command(str(tools/'zipalign'), '-c', '-P', '16', '4', apk)
    signature = command(str(tools/'apksigner'), 'verify', '--verbose', '--print-certs', apk)
    if not args.debug and 'Android Debug' in signature:
        raise ValueError('Release artifact is signed with a development certificate.')
    print(f'PASS: {expected_id}, SDK24/36, permissions={sorted(permissions)}, backup exclusions.')
    print(f'PASS: {len(aligned)} 64-bit ELF libraries and APK ZIP alignment at16KB; APK signature valid.')
    if args.debug:
        print('Development APK only; runtime QA and a signed final release are still required.')
    else:
        print('Static artifact checks only; this does not approve store publication or runtime QA.')


if __name__ == '__main__':
    main()
