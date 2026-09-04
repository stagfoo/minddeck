#!/usr/bin/env bash
# Builds a debug APK locally and publishes it as a GitHub release asset, for
# when CI budget is tight. Uses the same debug.keystore committed to the repo
# that CI builds use, so this can still install as an update over a previously
# CI-built (or previously locally-built) copy.
#
# The tag is exactly the app's version, with no "v" and no commit suffix, so it
# matches the versionName inside the APK. Obtainium compares the version string
# a release advertises against the version Android reports for the installed
# app, and can only do that when the two are the same shape — a "v1.0.0-3d1885e"
# tag against a "1.0.0" versionName is not.
set -euo pipefail

cd "$(dirname "$0")/.."

app_name=$(basename "$(pwd)")

current=$(grep '^version:' pubspec.yaml | head -1 | awk '{print $2}')
current_version=${current%%+*}
current_build=${current##*+}

# Every release gets its own version. Shipping the same version twice leaves
# Obtainium with nothing to compare, and leaves Android with no reason to treat
# the APK as an update.
major=$(echo "$current_version" | cut -d. -f1)
minor=$(echo "$current_version" | cut -d. -f2)
patch=$(echo "$current_version" | cut -d. -f3)
next_version="$major.$minor.$((patch + 1))"
next_build=$((current_build + 1))
tag="$next_version"

# Release, not debug. A debug build runs Dart in the JIT with no AOT snapshot,
# so it starts several times slower — and for a home launcher, cold start *is*
# the experience: every swipe up pays it. It is also ~18MB against ~80MB.
# Signed with the same committed debug.keystore, so it still installs as an
# update over anything built before.
#
# arm64-only, not the universal multi-ABI APK: arm64-v8a covers every real
# Android phone from the last ~8 years, and this is a personal sideload.
apk_path="build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"

echo "==> $app_name $current_version -> $next_version"

if gh release view "$tag" >/dev/null 2>&1; then
  echo "!! Release $tag already exists; bump past it or delete it first." >&2
  exit 1
fi

sed -i "s/^version: .*/version: $next_version+$next_build/" pubspec.yaml

flutter pub get
flutter analyze
flutter test
flutter build apk --release --target-platform android-arm64 --split-per-abi

git add pubspec.yaml
git commit -m "Release $next_version"

# gh release create --target takes a commit the remote already has; without
# this the whole build runs and then fails with "target_commitish is invalid".
git push origin HEAD

gh release create "$tag" "$apk_path" \
  --title "$app_name $next_version" \
  --notes "$(git log -1 --pretty=%s)" \
  --target "$(git rev-parse HEAD)"

gh release view "$tag" --json url --jq .url
