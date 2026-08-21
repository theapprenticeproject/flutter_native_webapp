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

## Useful checks

```bash
flutter analyze
flutter test
npm run format:check
cd worker && npx wrangler deploy --dry-run
mkdocs build --strict
```

Do not commit generated `build/`, `.dart_tool/`, documentation `site/`, local Wrangler state, or secret files.
