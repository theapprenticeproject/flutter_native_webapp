#!/usr/bin/env bash
# Builds the web app with build details baked in. They are shown when someone
# long-presses the logos on the login screen, so a deployment can be traced to a
# commit and a Flutter version. Use this for every build that gets deployed.
#
# usage: scripts/build_web.sh [extra flutter build web arguments]
set -euo pipefail
cd "$(dirname "$0")/.."

info=$(flutter --version --machine)
flutter_version=$(printf '%s\n' "$info" | sed -n 's/.*"frameworkVersion": "\([^"]*\)".*/\1/p')
engine=$(printf '%s\n' "$info" | sed -n 's/.*"engineRevision": "\([0-9a-f]\{8\}\).*/\1/p')
commit=$(git rev-parse --short HEAD)
if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  commit="${commit}-dirty"
fi
built=$(date -u +%Y-%m-%dT%H:%MZ)

flutter build web --release \
  --dart-define=BUILD_TIME="$built" \
  --dart-define=GIT_SHA="$commit" \
  --dart-define=BUILD_FLUTTER_VERSION="$flutter_version" \
  --dart-define=BUILD_ENGINE_REVISION="$engine" \
  "$@"

echo "Built $built, commit $commit, Flutter $flutter_version (engine $engine)"
