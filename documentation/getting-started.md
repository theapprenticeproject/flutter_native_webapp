# Getting Started

## Prerequisites

- Flutter with a Dart SDK compatible with `^3.11.5`
- Chrome for Flutter Web development
- Node.js and npm for Worker development
- Python 3 and pip to serve this documentation
- Cloudflare and Firebase CLIs only when deploying

## Install dependencies

From the repository root:

```bash
flutter pub get
npm ci
cd worker
npm ci
cd ..
```

## Run the Flutter app

```bash
flutter run -d chrome
```

The app currently uses the Worker URL declared in `AppConstants.workerBaseUrl`. Change that constant when testing against a different Worker environment.

## Run the Worker locally

```bash
cd worker
npm run dev
```

Provide local variables through Wrangler configuration or a local secrets file that is not committed. Required variables are documented under [Deployment](deployment.md#worker-configuration).

## Serve the documentation

```bash
python3 -m venv .venv-docs
source .venv-docs/bin/activate
pip install -r documentation/requirements.txt
mkdocs serve
```

Open `http://127.0.0.1:8000`.

## Set up the git hook (once for each clone)

The repository has a `pre-push` hook in `.githooks/`. It runs the quick checks (analyze, unit tests and the architecture check) before a push. Turn it on once:

```bash
git config core.hooksPath .githooks
```

It also runs when you push from VS Code. If a check fails, read the message in the terminal, or in the **Output** panel (choose **Git**).

> The hook does not exist yet. It is task E4 in the [v1 task breakdown](v1-task-breakdown.md). Until then, run the checks below by hand.

## Useful checks

```bash
flutter analyze
flutter test
npm run format:check
cd worker && npx wrangler deploy --dry-run
mkdocs build --strict
```

Do not commit generated `build/`, `.dart_tool/`, documentation `site/`, local Wrangler state, or secret files.
