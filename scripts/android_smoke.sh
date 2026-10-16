#!/usr/bin/env bash
set -euo pipefail
# Run only on an explicitly selected disposable QA emulator/device. The Dart
# harness scopes preferences under candyverse.qa.smoke.*, never production keys.
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"
qa_device=${CANDYVERSE_QA_DEVICE:-emulator-5554}
qa_minutes=${CANDYVERSE_SMOKE_MINUTES:-0}
qa_output=${CANDYVERSE_QA_OUTPUT:-"$repo_root/build/qa-smoke"}
qa_mode=${CANDYVERSE_QA_MODE:-profile}
qa_runner=${CANDYVERSE_QA_RUNNER:-instrumentation}
qa_software=${CANDYVERSE_SOFTWARE_RENDERING:-0}
if [[ "$qa_software" != 0 && "$qa_software" != 1 ]]; then
  printf 'CANDYVERSE_SOFTWARE_RENDERING must be 0 or 1.\n' >&2
  exit 2
fi
qa_renderer_args=()
qa_software_define=false
if [[ "$qa_software" == 1 ]]; then
  qa_renderer_args=(--enable-software-rendering --no-enable-impeller)
  qa_software_define=true
fi
if [[ ! "$qa_minutes" =~ ^[0-9]+$ ]] || ((qa_minutes > 60)); then
  printf 'CANDYVERSE_SMOKE_MINUTES must be an integer from 0 to 60.\n' >&2
  exit 2
fi
if [[ "$qa_mode" != profile && "$qa_mode" != debug ]]; then
  printf 'CANDYVERSE_QA_MODE must be profile or debug.\n' >&2
  exit 2
fi
mkdir -p "$qa_output"
export CANDYVERSE_QA_OUTPUT="$qa_output"
# Release the single-use build JVM before the active emulator scenario.
export GRADLE_OPTS="${GRADLE_OPTS:-} -Dorg.gradle.daemon=false"
adb -s "$qa_device" get-state
# Flutter drive does not pass the Gradle QA applicationId property. Keep this
# diagnostic path on disposable emulators; physical devices use instrumentation.
if [[ "$qa_runner" == drive && "$(adb -s "$qa_device" shell getprop ro.kernel.qemu | tr -d '\r')" != 1 ]]; then
  printf 'Flutter drive requires a disposable emulator; use instrumentation on a physical QA device.\n' >&2
  exit 2
fi
# adb may connect before Android's package service is ready, especially without KVM.
qa_boot_deadline=$((SECONDS + 600))
until [[ "$(adb -s "$qa_device" shell getprop sys.boot_completed | tr -d '\r')" == 1 ]]; do
  if ((SECONDS >= qa_boot_deadline)); then
    printf 'Android boot did not complete within 600 seconds.\n' >&2
    exit 1
  fi
  sleep 2
done
adb -s "$qa_device" shell getprop ro.build.version.sdk > "$qa_output/android-api.txt"
adb -s "$qa_device" shell getprop ro.product.model > "$qa_output/device-model.txt"
adb -s "$qa_device" shell getconf PAGE_SIZE > "$qa_output/page-size.txt"
flutter --version > "$qa_output/flutter-version.txt"
# Do not clear global logcat: retain other workers' diagnostic history.
adb -s "$qa_device" logcat -v threadtime AndroidRuntime:E libc:F DEBUG:F ActivityTaskManager:I ActivityManager:I flutter:I FlutterTestRunner:V '*:S' > "$qa_output/android-lifecycle.log" 2>&1 &
qa_logcat_pid=$!
qa_capture_pid=
qa_native_capture=false
cleanup_qa_observers() {
  kill "$qa_logcat_pid" 2>/dev/null || true
  if [[ -n "$qa_capture_pid" ]]; then
    kill "$qa_capture_pid" 2>/dev/null || true
    wait "$qa_capture_pid" 2>/dev/null || true
  fi
}
trap cleanup_qa_observers EXIT
# Keep real PNG evidence on disposable emulators; never observe a player's phone.
if [[ "$(adb -s "$qa_device" shell getprop ro.kernel.qemu | tr -d '\r')" == 1 ]]; then
  python3 scripts/capture_android_milestones.py --device "$qa_device" \
    --output "$qa_output/screenshots" > "$qa_output/screenshot-observer.log" 2>&1 &
  qa_capture_pid=$!
  qa_native_capture=true
fi
if [[ "$qa_runner" == drive ]]; then
flutter drive --"$qa_mode" "${qa_renderer_args[@]}" -d "$qa_device" \
  --driver integration_test/smoke_driver.dart \
  --target integration_test/android_smoke_test.dart \
  --dart-define="CANDYVERSE_SMOKE_MINUTES=$qa_minutes" \
  --dart-define="CANDYVERSE_SOFTWARE_RENDERING=$qa_software_define" \
  2>&1 | tee "$qa_output/flutter-drive.log"
elif [[ "$qa_runner" == instrumentation ]]; then
  if [[ "$qa_mode" != profile ]]; then
    printf 'Native instrumentation requires profile mode.\n' >&2
    exit 2
  fi
  qa_connected=$(adb devices | awk 'NR>1 && $2=="device" {print $1}')
  if [[ "$qa_connected" != "$qa_device" ]]; then
    printf 'Connect only the explicitly selected QA device for instrumentation.\n' >&2
    exit 2
  fi
  qa_abi=$(adb -s "$qa_device" shell getprop ro.product.cpu.abi | tr -d '\r')
  case "$qa_abi" in
    x86_64) qa_platform=android-x64 ;;
    arm64-v8a) qa_platform=android-arm64 ;;
    armeabi-v7a) qa_platform=android-arm ;;
    *) printf 'Unsupported QA ABI: %s\n' "$qa_abi" >&2; exit 2 ;;
  esac
  qa_run_token=$(python3 -c 'import uuid; print(uuid.uuid4().hex)')
  flutter build apk --profile --target-platform "$qa_platform" --target integration_test/android_smoke_test.dart \
    --dart-define="CANDYVERSE_SMOKE_MINUTES=$qa_minutes" \
    --dart-define="CANDYVERSE_QA_RUN_TOKEN=$qa_run_token" \
    --dart-define="CANDYVERSE_NATIVE_SCREENSHOTS=$qa_native_capture" \
    --dart-define="CANDYVERSE_SOFTWARE_RENDERING=$qa_software_define" \
    > "$qa_output/profile-build.log" 2>&1
  qa_defines=$(python3 - "$qa_minutes" "$qa_run_token" "$qa_software_define" "$qa_native_capture" <<'PY_DEFINES'
import base64,sys
print(','.join(base64.b64encode(value.encode()).decode() for value in ('CANDYVERSE_SMOKE_MINUTES='+sys.argv[1], 'CANDYVERSE_QA_RUN_TOKEN='+sys.argv[2], 'CANDYVERSE_SOFTWARE_RENDERING='+sys.argv[3], 'CANDYVERSE_NATIVE_SCREENSHOTS='+sys.argv[4])))
PY_DEFINES
  )
  qa_native_started=$SECONDS
  (
    cd android
    ANDROID_SERIAL="$qa_device" ./gradlew :app:connectedProfileAndroidTest \
      -PcandyverseInstrumentation=true \
      -Ptarget-platform="$qa_platform" \
      -Ptarget="$repo_root/integration_test/android_smoke_test.dart" \
      -Pdart-defines="$qa_defines" \
      -Pandroid.testInstrumentationRunnerArguments.timeout_msec=1800000 \
      -Pandroid.testInstrumentationRunnerArguments.candyverseSoftwareRendering="$qa_software_define" \
      --console=plain
  ) 2>&1 | tee "$qa_output/instrumentation.log"
  qa_native_elapsed=$((SECONDS - qa_native_started))
  adb -s "$qa_device" logcat -d -v threadtime flutter:I '*:S' > "$qa_output/final-flutter.log"
  python3 - "$qa_output" "$qa_minutes" "$qa_native_elapsed" "$qa_run_token" <<'PY_METRICS'
import json,sys
from pathlib import Path
out=Path(sys.argv[1])
records=[]
for line in (out/'final-flutter.log').read_text(errors='replace').splitlines():
    marker='CANDYVERSE_QA_REPORT:'
    if marker in line:
        record=json.loads(line.split(marker,1)[1].strip())
        if record.get('runToken') == sys.argv[4]: records.append(record)
if not records:
    raise SystemExit('Native instrumentation completed without QA metrics.')
report=records[-1]
if report.get('storageKind') != 'native-data-store':
    raise SystemExit('Host memory validation cannot count as native persistence QA.')
minutes=int(sys.argv[2])
host_elapsed=int(sys.argv[3])
if report['requestedActiveMinutes'] != minutes or report['activeDwellSeconds'] < 60*minutes or host_elapsed < 60*minutes:
    raise SystemExit('The requested real-time active dwell was not completed.')
if minutes and (not report['dwellMoves'] or not report['dwellReactions'] or not report['dwellCycles']):
    raise SystemExit('Active dwell did not exercise gameplay and island interactions.')
if not report['frameCount']:
    raise SystemExit('No profile FrameTiming samples were captured.')
report['runner']='native-android-instrumentation'
report['hostInstrumentationElapsedSeconds']=host_elapsed
if report.get('candyNavigationVerified') is not True or report.get('candyNoticesVerified') is not True:
    raise SystemExit('Native candy navigation/notice assertions did not complete.')
if report.get('captureMethod') == 'native-adb-milestone-observer':
    expected=('candy-settings-return','candy-island-map','candy-notice-info','candy-notice-success')
    for name in expected:
        screenshot=out/'screenshots'/f'{name}.png'
        if not screenshot.exists() or not screenshot.read_bytes().startswith(b'\x89PNG\r\n\x1a\n'):
            raise SystemExit('Missing native candy screenshot: '+name)
    report['nativeMilestoneScreenshots']=len(list((out/'screenshots').glob('*.png')))
(out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
PY_METRICS
  if [[ -d "$repo_root/build/app/outputs/androidTest-results" ]]; then
    cp -R "$repo_root/build/app/outputs/androidTest-results" "$qa_output/junit"
  fi
else
  printf 'CANDYVERSE_QA_RUNNER must be instrumentation or drive.\n' >&2
  exit 2
fi
adb -s "$qa_device" logcat -d -t 2000 AndroidRuntime:E flutter:E '*:S' > "$qa_output/errors.log"
python3 - "$qa_output/report.json" <<'PY'
import json,sys
with open(sys.argv[1]) as f:
    report=json.load(f)
print(json.dumps(report,ensure_ascii=False,indent=2))
PY
