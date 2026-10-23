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
store; do not generate a different upload key on every build. The current key also signs the standalone APK. Preserve its certificate if those
installations should update through Google Play: during Play App Signing setup,
provide this existing signing key through Google's PEPK flow instead of accepting
a newly generated app-signing key. A new Google-generated certificate would
require uninstalling the standalone app, which can lose offline progress.
After enrollment, a separate upload key can be registered without changing the
app-signing identity. Do not regenerate this directory for each release.
See ADR-0014; enrollment and legal terms require the publisher's verified account.
See [Flutter's Android signing guide](https://docs.flutter.dev/deployment/android).

## Build and verify

For the readability candidate, after the repository tests and T-022 QA pass,
use version1.3.1+7. This candidate has not been built or published yet. Keep all previously published artifacts unchanged:

```sh
flutter build appbundle --release --build-name=1.3.1 --build-number=7
flutter build apk --release --build-name=1.3.1 --build-number=7
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

## Candy Kingdom branding

The banner/logo comes from the owner-supplied reference, copied unchanged into
`assets/kingdom/brand-sheet.png`. The full-bleed kitten icon and rendered game
artwork were generated using that reference. Sources, processing notes and
rights-confirmation requirements are recorded in
[artwork provenance](../assets/kingdom/README.md),
[full image prompts](../assets/kingdom/PROMPTS.md) and the
[asset catalog](../assets/ASSET_LICENSES.md).

`scripts/generate_brand_icon.py` packages/resamples the checked-in
`assets/kingdom/icon.png`; it does not draw the kitten from code or invoke AI.
The full-square store icon is512×512,32-bit RGBA PNG, opaque, tagged sRGB and
below1MB, following the
[Google Play icon specification](https://developer.android.com/distribute/google-play/resources/icon-design-specifications).
Pillow is a development-only packaging tool, not an Android SDK. Outputs include
the store icon,1080px preview, legacy density PNG launchers, adaptive raster
foreground/solid background and Android13 monochrome vector silhouette.

```sh
python3 scripts/generate_brand_icon.py
```

[Rendered source icon](../assets/kingdom/icon.png),
[512px store icon](../assets/brand/store_icon_512.png).
The retained [code-authored mark](../assets/brand/candyverse_mark.svg) and the
PL/EN feature graphics generated by `scripts/generate_store_graphics.py` belong
to the older1.0.0-rc.1 presentation. They are historical materials; replace
store submissions with reviewed Candy Kingdom materials and actual screenshots
of the new signed candidate. Do not overwrite the published rc.1 bundle.

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

## Rebuild the signed universal APK

After validating the AAB, the local-only helper reads Java Properties and supplies
passwords through private temporary files, never shell arguments or output.
Both credential files must remain outside every Git worktree; an existing output
is refused. JDK21 and bundletool1.18.3 were used for the1.1.0 candidate.

```sh
java scripts/BuildCandyverseApks.java /path/to/bundletool.jar \
  "$HOME/.candyverse-signing/v1/key.properties" \
  /path/to/candyverse-1.3.0-6.aab /path/to/new-candyverse.apks
```

Extract `universal.apk` from that public APK-set ZIP, then run
`audit_android_artifact.py` and `apksigner verify --print-certs` on it.
This packaging step is independent of Play Console submission.
