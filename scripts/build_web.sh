#!/usr/bin/env bash
# Builds the web app with build details baked in. They are shown when someone
# long-presses the logos on the login screen, so a deployment can be traced to a
# commit and a Flutter version. Use this for every build that gets deployed.
#
# usage: [WORKER_URL=https://<worker-host>] scripts/build_web.sh [extra flutter build web arguments]
#
# WORKER_URL picks the Worker the app talks to, for example the dev Worker.
# Without it the build uses the production Worker. It must be an https origin
# with no path. Plain http is allowed only for localhost (a local `wrangler dev`).
# DRY_RUN=1 checks the settings and prints the command without building.
#
# The build always uses --no-web-resources-cdn, so the app loads CanvasKit (the
# drawing engine) from our own server and not from Google's. On a slow or
# filtered network inside WhatsApp, a download from Google can fail or be late.
# The files are in the build either way, so this adds nothing to the deploy.
set -euo pipefail
cd "$(dirname "$0")/.."

worker_define=()
if [ -n "${WORKER_URL:-}" ]; then
  worker_url="${WORKER_URL%/}"
  if ! [[ "$worker_url" =~ ^(https://[A-Za-z0-9.-]+(:[0-9]+)?|http://(localhost|127\.0\.0\.1)(:[0-9]+)?)$ ]]; then
    echo "WORKER_URL must be an https:// origin with no path, for example https://name.workers.dev" >&2
    echo "(http:// is allowed only for localhost). Got: $WORKER_URL" >&2
    exit 2
  fi
  worker_define=(--dart-define=WORKER_URL="$worker_url")
fi

if [ "${DRY_RUN:-}" = "1" ]; then
  echo "DRY RUN: flutter build web --release --no-web-resources-cdn ${worker_define[*]:-} $*"
  exit 0
fi

info=$(flutter --version --machine)
flutter_version=$(printf '%s\n' "$info" | sed -n 's/.*"frameworkVersion": "\([^"]*\)".*/\1/p')
engine=$(printf '%s\n' "$info" | sed -n 's/.*"engineRevision": "\([0-9a-f]\{8\}\).*/\1/p')
commit=$(git rev-parse --short HEAD)
if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  commit="${commit}-dirty"
fi
built=$(date -u +%Y-%m-%dT%H:%MZ)

flutter build web --release --no-web-resources-cdn \
  --dart-define=BUILD_TIME="$built" \
  --dart-define=GIT_SHA="$commit" \
  --dart-define=BUILD_FLUTTER_VERSION="$flutter_version" \
  --dart-define=BUILD_ENGINE_REVISION="$engine" \
  ${worker_define[@]+"${worker_define[@]}"} \
  "$@"

echo "Built $built, commit $commit, Flutter $flutter_version (engine $engine)"
echo "Worker: ${worker_url:-default (production)}"
