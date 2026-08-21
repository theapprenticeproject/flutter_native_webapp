import os
import json
import shutil
import requests
from pathlib import Path
from dotenv import load_dotenv

load_dotenv(Path(__file__).parent / ".env")

BASE_URL   = os.environ["FRAPPE_BASE_URL"].rstrip("/")
API_KEY    = os.environ["FRAPPE_API_KEY"]
API_SECRET = os.environ["FRAPPE_API_SECRET"]
PROGRAM_ID = os.environ["TAP_PROGRAM_ID"]
INCLUDE_R2 = os.environ.get("INCLUDE_R2", "false").lower() in ("1", "true", "yes")
LANGS      = os.environ.get("TAP_LANGS", "en,hi,kn,mr,pa")

ENDPOINT = f"{BASE_URL}/api/method/tap_lms.tapapp.api.content.export.export_program_content"
CONTENT_ENDPOINT = f"{BASE_URL}/api/method/tap_lms.tapapp.api.content.export.export_content"

DATA_DIR      = Path(__file__).parent.parent / "assets" / "data"
COURSES_DIR   = DATA_DIR / "courses"
CONSTANTS_DIR = DATA_DIR / "constants"
STATES_DIR    = DATA_DIR / "states"
DISTRICTS_DIR = DATA_DIR / "district"
CONTENT_DIR   = DATA_DIR / "content"

GRADES = [{"id": str(i), "label": f"Grade {i}", "value": str(i)} for i in range(1, 13)]


def _slug(s: str) -> str:
    return s.replace(" ", "-")


def _headers():
    return {"Authorization": f"token {API_KEY}:{API_SECRET}"}


def write(path: Path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(data, separators=(",", ":"), ensure_ascii=False),
        encoding="utf-8",
    )
    print(f"  {path.relative_to(DATA_DIR.parent)}")


def main():
    print(f"Exporting program '{PROGRAM_ID}' from {BASE_URL} ...")
    params = {"program_id": PROGRAM_ID, "include_r2": "true" if INCLUDE_R2 else "false"}
    if LANGS:
        params["langs"] = LANGS

    resp = requests.post(ENDPOINT, headers=_headers(), json=params, timeout=300)
    resp.raise_for_status()
    result = resp.json().get("message", {})
    if not result.get("success"):
        raise RuntimeError(f"Export failed: {result.get('error')}")

    payload = result["payload"]

    for d in (COURSES_DIR, CONSTANTS_DIR, STATES_DIR, DISTRICTS_DIR):
        if d.exists():
            shutil.rmtree(d)
        d.mkdir(parents=True, exist_ok=True)

    write(CONSTANTS_DIR / "constants.json", {**payload["constants"], "grades": GRADES})
    write(CONSTANTS_DIR / "languages.json", payload["languages"])
    write(STATES_DIR / "states.json", payload["states"])

    for state_id, districts in payload["districts"].items():
        if state_id == "__none__":
            continue
        write(DISTRICTS_DIR / f"{_slug(state_id)}.json", districts)

    for lang, lang_data in payload["langs"].items():
        index = lang_data["index"]
        for entry in index.get("courses", []):
            entry["id"] = _slug(entry["id"])
        write(COURSES_DIR / lang / "index.json", {"courses": index.get("courses", [])})

        for cid, course_data in lang_data["courses"].items():
            course_data["id"] = _slug(cid)
            write(COURSES_DIR / lang / f"{_slug(cid)}.json", course_data)

    print(f"\nExporting citizenship content from {BASE_URL} ...")
    content_resp = requests.post(CONTENT_ENDPOINT, headers=_headers(), json={}, timeout=120)
    content_resp.raise_for_status()
    content_result = content_resp.json().get("message", {})
    if not content_result.get("success"):
        raise RuntimeError(f"Content export failed: {content_result.get('error')}")

    content_items = content_result["payload"]["content"]

    if CONTENT_DIR.exists():
        shutil.rmtree(CONTENT_DIR)
    CONTENT_DIR.mkdir(parents=True, exist_ok=True)

    events = [item for item in content_items if item.get("type") == "Event"]
    knowledge = [item for item in content_items if item.get("type") == "Knowledge Center"]
    projects = [item for item in content_items if item.get("type") == "Project"]

    write(CONTENT_DIR / "event.json", events)
    write(CONTENT_DIR / "knowledge-centre.json", knowledge)
    write(CONTENT_DIR / "project.json", projects)

    print(f"\nDone — {DATA_DIR}")


if __name__ == "__main__":
    main()