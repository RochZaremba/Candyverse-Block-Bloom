#!/usr/bin/env python3
"""Create private, external signing material; never print a password."""
import argparse
import os
from pathlib import Path
import secrets
import shutil
import subprocess
import sys


def outside_repository(path):
    destination = Path(path).expanduser().resolve()
    if any(character in str(destination) for character in '\n\r\t'):
        raise ValueError('Output path must not contain control characters.')
    ancestor = destination
    while not ancestor.exists():
        ancestor = ancestor.parent
    if ancestor.is_file():
        ancestor = ancestor.parent
    probe = subprocess.run(
        ['git', '-C', str(ancestor), 'rev-parse', '--is-inside-work-tree'],
        capture_output=True, text=True, check=False,
    )
    if probe.returncode == 0 and probe.stdout.strip() == 'true':
        raise ValueError('Signing material must be outside every Git worktree.')
    return destination


def properties_escape(value):
    return value.replace('\\', '\\\\').replace(':', '\\:').replace(' ', '\\ ')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output-dir', required=True, help='Private directory outside all Git repositories.')
    args = parser.parse_args()
    try:
        destination = outside_repository(args.output_dir)
        if destination.exists():
            raise ValueError('Output directory already exists; refusing to overwrite signing material.')
        executable = shutil.which('keytool')
        if executable is None:
            raise ValueError('JDK keytool is not available.')
    except ValueError as error:
        parser.error(str(error))
    os.umask(0o077)
    destination.mkdir(mode=0o700, parents=True)
    keystore = destination / 'candyverse-upload.p12'
    properties = destination / 'key.properties'
    password = secrets.token_urlsafe(40)
    environment = os.environ.copy()
    environment['CANDYVERSE_GENERATED_STORE_PASSWORD'] = password
    try:
        subprocess.run([
            executable, '-genkeypair', '-v', '-keystore', str(keystore),
            '-storetype', 'PKCS12', '-keyalg', 'RSA', '-keysize', '4096',
            '-validity', '10000', '-alias', 'upload',
            '-dname', 'CN=Candyverse upload key',
            '-storepass:env', 'CANDYVERSE_GENERATED_STORE_PASSWORD',
            '-keypass:env', 'CANDYVERSE_GENERATED_STORE_PASSWORD',
        ], env=environment, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        os.chmod(keystore, 0o600)
        descriptor = os.open(properties, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(descriptor, 'w') as stream:
            stream.write(f'storeFile={properties_escape(str(keystore))}\n')
            stream.write(f'storePassword={password}\nkeyAlias=upload\nkeyPassword={password}\n')
    except (OSError, subprocess.CalledProcessError):
        for generated in (keystore, properties):
            if generated.exists():
                generated.unlink()
        destination.rmdir()
        sys.exit('Key generation failed; no signing material retained.')
    print(f'Created private upload key and properties in {destination}.')
    print('Back up this directory securely before building or uploading a release.')
    print(f'Set CANDYVERSE_KEY_PROPERTIES to {properties}.')


if __name__ == '__main__':
    main()
