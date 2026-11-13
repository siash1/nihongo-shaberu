#!/bin/bash
# Builds tests/AppFlow from the app's sources and runs its steps against a running backend:
#
#   BASE_URL=http://127.0.0.1:3210 tests/AppFlow/run.sh
#
# Device A and device B are two copies of the same executable, so each has its own UserDefaults
# domain. Steps run one after another, except the poll check, which runs on device A while device B
# makes a change. Signs up two random users (both deleted again at the end). Exit status 0 when all pass.
set -u
cd "$(dirname "$0")/../.."

export BASE_URL="${BASE_URL:-http://127.0.0.1:3210}"
work="$(mktemp -d "${TMPDIR:-/tmp}/appflow.XXXXXX")"
export APPFLOW_DIR="$work"
export APPFLOW_USER="Flow_$(uuidgen | tr -d - | head -c 8 | tr 'A-Z' 'a-z')"
export APPFLOW_USER2="Flow2_$(uuidgen | tr -d - | head -c 8 | tr 'A-Z' 'a-z')"
export APPFLOW_PASSWORD="kana-$(uuidgen)"

app=KanaFlashcard
echo "Building into $work"
swiftc -default-isolation MainActor \
    -enable-upcoming-feature InferIsolatedConformances \
    -enable-upcoming-feature NonisolatedNonsendingByDefault \
    $app/Models/ProgressSnapshot.swift $app/Models/WordCard.swift $app/Models/JLPTLevel.swift \
    $app/Models/Kanji.swift $app/Models/KanjiData.swift $app/Models/KanjiData+Units*.swift \
    $app/Models/KanjiQuiz.swift $app/Services/RomajiConverter.swift \
    $app/Services/LocalProgress.swift $app/Services/KanjiProgressStore.swift $app/Services/WordStorageService.swift \
    $app/Services/Backend/BackendConfig.swift $app/Services/Backend/ConvexClient.swift \
    $app/Services/Backend/AuthService.swift $app/Services/Backend/SyncService.swift \
    $app/ViewModels/KanjiViewModel.swift \
    tests/AppFlow/Stubs.swift tests/AppFlow/main.swift \
    -o "$work/deviceA" || exit 1
cp "$work/deviceA" "$work/deviceB"

failed=0
run() {
    "$work/device$1" "$2" || failed=$((failed + 1))
}

echo "Backend $BASE_URL, user $APPFLOW_USER"
run A a1
run B b1
run A a2
run A a3
# Device A stays active (polling) while device B learns a kanji.
"$work/deviceA" apoll > "$work/apoll.log" 2>&1 &
poll=$!
sleep 3
run B b2
wait $poll || failed=$((failed + 1))
cat "$work/apoll.log"
run B b3
run A a4
run B b4
# Switching accounts on one device, and progress made while signed out joining an account.
run B b5
run A a5
run B b6

defaults delete deviceA > /dev/null 2>&1
defaults delete deviceB > /dev/null 2>&1
rm -rf "$work"
if [ "$failed" -eq 0 ]; then echo "AppFlow: all steps passed"; else echo "AppFlow: $failed step(s) failed"; fi
exit "$failed"
