#!/usr/bin/env bash
# Builds a debug APK locally and publishes it as a GitHub release asset,
# for when CI budget is tight. Uses the same debug.keystore committed to
# the repo that CI builds use, so this can still install as an update over
# a previously CI-built (or previously locally-built) copy.
set -euo pipefail

cd "$(dirname "$0")/.."

app_name=$(basename "$(pwd)")
version=$(grep '^version:' pubspec.yaml | head -1 | awk '{print $2}' | cut -d'+' -f1)
sha=$(git rev-parse --short HEAD)
tag="v${version}-${sha}"
# arm64-only, not the universal multi-ABI APK: a debug build bundles a
# full Flutter debug engine per ABI, which makes a universal APK ~160MB
# against ~55MB for one. arm64-v8a covers every real Android phone from
# the last ~8 years, and this is a personal sideload, not a public release.
apk_path="build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk"

echo "==> $app_name $tag"

flutter pub get
flutter analyze
flutter test
flutter build apk --debug --target-platform android-arm64 --split-per-abi

if gh release view "$tag" >/dev/null 2>&1; then
  echo "==> Release $tag already exists, uploading APK (clobber)"
  gh release upload "$tag" "$apk_path" --clobber
else
  echo "==> Creating release $tag"
  gh release create "$tag" "$apk_path" \
    --title "$app_name $tag" \
    --notes "Local debug build of $sha." \
    --target "$(git rev-parse HEAD)"
fi

gh release view "$tag" --json url --jq .url
