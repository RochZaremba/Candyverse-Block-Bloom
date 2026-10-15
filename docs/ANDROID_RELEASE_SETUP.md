# Android release setup

Application ID and namespace: `com.renvo.candyverse` (owner approved).
Publisher/contact: Renvo, rochzaremba@gmail.com. This configuration does not
reserve the identifier or verify publisher status in Play Console. The temporary
`com.example.candyverse` development profile is a separate Android app and is not
automatically migrated; V1 has not been published under that temporary ID.

## Upload key outside the repository

The release build has **no debug-signing fallback**. Debug builds continue to use
Android's development key. Release tasks require `CANDYVERSE_KEY_PROPERTIES`.

Generate a new upload key once, only after reviewing this setup:

```sh
python3 scripts/create_upload_key.py --output-dir "$HOME/.candyverse-signing/v1"
export CANDYVERSE_KEY_PROPERTIES="$HOME/.candyverse-signing/v1/key.properties"
```

The generator refuses directories inside Git worktrees and existing output
directories. It creates a 4096-bit RSA PKCS12 key, random password, private directory
(mode700), and files (mode600). Passwords are passed to JDK `keytool` through the
child environment and are never printed or placed in command arguments. The
properties file contains `storeFile`, `storePassword`, `keyAlias`, `keyPassword`.
PKCS12 is the default store type; an existing JKS can explicitly set `storeType=JKS`.
Treat the properties file as a secret. Do not attach it to a PR, chat, CI log or store listing.

Back up both files and the password securely outside this machine before upload.
For a shared release pipeline, supply the same external files through the CI secret
store; do not generate a different upload key on every build. Google Play App
Signing uses a separate app-signing key; retain this upload key for future uploads.
See [Flutter's Android signing guide](https://docs.flutter.dev/deployment/android).

## Build and verify

After integrating T-009/T-010 and passing the repository tests:

```sh
flutter build appbundle --release --build-name=1.0.0 --build-number=1
flutter build apk --release --build-name=1.0.0 --build-number=1
python3 scripts/audit_android_artifact.py build/app/outputs/flutter-apk/app-release.apk
```

Without signing credentials, the release task must fail; an unsigned or debug-signed
artifact is not a publication deliverable. Android's debug APK is not a store asset.
Use `jarsigner -verify -verbose -certs` for the AAB and `apksigner verify --verbose
--print-certs` for the release APK; compare the public certificate digest with the
external upload key. Never display the private properties file to find its digest.

The artifact audit checks RELRO ranges as well as ELF LOAD alignment. A RELRO
range whose end is not a16KB boundary is accepted only when it covers its entire
corresponding LOAD segment, matching the
[Android linker implementation](https://android.googlesource.com/platform/bionic/+/refs/heads/main/linker/linker_phdr.cpp).
This avoids incorrectly rejecting Flutter/DataStore suffix RELRO ranges. The
runtime device check remains required; dependency version labels alone are not
compatibility evidence.

The artifact audit checks application ID, SDK24/36, no unexpected permissions,
backup exclusions and native 16KB ELF/ZIP alignment. A successful static audit does
not replace runtime testing on a 16KB device, or 20minute smoke/profiling on hardware.
For an AAB, additionally inspect `bundletool dump config --bundle=<file>` for
`PAGE_ALIGNMENT_16K` and test the generated APK set.
[Android's page-size guide](https://developer.android.com/guide/practices/page-sizes)
describes the distinction between alignment and runtime behavior.

## Original branding

`scripts/generate_brand_icon.py` produces the original Candyverse mark from code
and checked-in palette tokens. The full-square store icon is512×512,32-bit RGBA
PNG, opaque, tagged sRGB and below1MB, following the
[Google Play icon specification](https://developer.android.com/distribute/google-play/resources/icon-design-specifications).
Pillow is a development-only rasterization tool,
not an Android SDK. Outputs include a full 512px square store icon, legacy density
PNG launchers, adaptive foreground/background vectors and Android13 monochrome.
The icon does not use Flutter's placeholder, emoji, stock imagery or another brand.

```sh
python3 scripts/generate_brand_icon.py
```

[Source mark](../assets/brand/candyverse_mark.svg),
[512px store icon](../assets/brand/store_icon_512.png).
Original PL/EN feature graphics are in `assets/store/`; generate them with
`scripts/generate_store_graphics.py`. Actual screenshots remain a separate
release deliverable.

## Local save and backup

[ADR-0012](adr/0012-android-backup-exclusion.md) explicitly excludes app data from
standard Android cloud backup and device transfer, in both legacy and Android12+
formats. Canonical and quarantine saves are covered through the file/preferences
and root exclusions. No cloud save is supplied by the publisher. Manufacturer or
privileged tools can behave differently; do not promise that reset erases every
system copy. Validate final packaged resources and OEM behavior during QA.

Public privacy URL, store account, ownership/legal declarations and applicable
closed/internal testing are required before publishing. Follow the full
[Google Play release checklist](RELEASE_GOOGLE_PLAY.md); this setup does not submit
or publish the app.
