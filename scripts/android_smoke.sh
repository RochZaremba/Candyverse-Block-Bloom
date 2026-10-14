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
adb -s "$qa_device" get-state
adb -s "$qa_device" shell getprop ro.build.version.sdk > "$qa_output/android-api.txt"
adb -s "$qa_device" shell getprop ro.product.model > "$qa_output/device-model.txt"
adb -s "$qa_device" shell getconf PAGE_SIZE > "$qa_output/page-size.txt"
flutter --version > "$qa_output/flutter-version.txt"
# Do not clear global logcat: retain other workers' diagnostic history.
flutter drive --"$qa_mode" -d "$qa_device" \
  --driver integration_test/smoke_driver.dart \
  --target integration_test/android_smoke_test.dart \
  --dart-define="CANDYVERSE_SMOKE_MINUTES=$qa_minutes" \
  2>&1 | tee "$qa_output/flutter-drive.log"
adb -s "$qa_device" logcat -d -t 2000 AndroidRuntime:E flutter:E '*:S' > "$qa_output/errors.log"
python3 - "$qa_output/report.json" <<'PY'
import json,sys
with open(sys.argv[1]) as f:
    report=json.load(f)
print(json.dumps(report,ensure_ascii=False,indent=2))
PY
