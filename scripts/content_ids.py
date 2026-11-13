#!/usr/bin/env python3
"""Add, check and replace the ids in the bundled course content.

The API needs ids that the exported course files do not have:
  uid  on every unit          (the API calls it unit_id)
  qid  on every quiz question (the API calls it question_id), also on the
                              practice-quiz questions of a video
  aid  on every assignment    (the API calls it assignment_id)
  vid  on every video         (the API calls it video_id)
  zid  on the unit quiz       (the API calls it quiz_id)

Until the real ids are known, this script writes clearly marked DUMMY ids. The
ids depend only on the course and the position, so they are the same in every
language. The files are edited as text, so the formatting does not change.

Usage (from the repo root):
  python3 scripts/content_ids.py                  add missing dummy ids
  python3 scripts/content_ids.py --check          check every file (CI, tests)
  python3 scripts/content_ids.py --check --no-dummy
                                                  also fail while a DUMMY id is left
                                                  (run this before a deployment)
  python3 scripts/content_ids.py --dump-map ids.json
                                                  write the ids of the English files
  python3 scripts/content_ids.py --apply-map ids.json
                                                  replace ids in every language from the
                                                  map (fill in the real ids, then apply)
"""
import argparse
import json
import re
import sys
from pathlib import Path

COURSES = Path(__file__).resolve().parent.parent / "assets" / "data" / "courses"
LANGS = ["en", "hi", "kn", "mr", "pa"]

KEY_OPEN = re.compile(r'^(\s*)"(\w+)":\s*([\[{])\s*$')
ANON_OPEN = re.compile(r'^(\s*)([\[{])\s*$')
CLOSE = re.compile(r'^\s*[\]}],?\s*$')


def course_code(course_id: str) -> str:
    return course_id.rsplit("-", 1)[-1]


def dummy_id(kind: str, code: str, u: int, v: int = 0, q: int = 0, a: int = 0) -> str:
    if kind == "uid":
        return f"LU-DUMMY-{code}-U{u:02d}"
    if kind == "aid":
        return f"AS-DUMMY-{code}-U{u:02d}-A{a:02d}"
    if kind == "qid_quiz":
        return f"QN-DUMMY-{code}-U{u:02d}-Q{q:02d}"
    if kind == "qid_pq":
        return f"QN-DUMMY-{code}-U{u:02d}-V{v:02d}-Q{q:02d}"
    if kind == "vid":
        return f"VC-DUMMY-{code}-U{u:02d}-V{v:02d}"
    if kind == "zid":
        return f"QZ-DUMMY-{code}-U{u:02d}"
    raise ValueError(kind)


def add_ids_to_course(course: dict) -> int:
    """Add the missing ids to one course that is already loaded as a dict.

    This gives the same ids as the text version below. The export script uses it,
    because it writes compact JSON. Ids that are already there are kept, so ids
    that come from the backend are never replaced. Returns how many ids it added.
    """
    code = course_code(course["id"])
    added = 0

    def put(obj: dict, field: str, value: str):
        nonlocal added
        if not obj.get(field):
            obj[field] = value
            added += 1

    for ui, unit in enumerate(course.get("units", []), 1):
        put(unit, "uid", dummy_id("uid", code, ui))
        for ai, assign in enumerate(unit.get("assigns", []) or [], 1):
            put(assign, "aid", dummy_id("aid", code, ui, a=ai))
        quiz = unit.get("quiz")
        if isinstance(quiz, dict):
            put(quiz, "zid", dummy_id("zid", code, ui))
        for qi, ques in enumerate((quiz or {}).get("qs", []) or [], 1):
            put(ques, "qid", dummy_id("qid_quiz", code, ui, q=qi))
        for vi, vid in enumerate(unit.get("vids", []) or [], 1):
            put(vid, "vid", dummy_id("vid", code, ui, v=vi))
            for qi, ques in enumerate((vid.get("pq") or {}).get("qs", []) or [], 1):
                put(ques, "qid", dummy_id("qid_pq", code, ui, v=vi, q=qi))
    return added


def objects(lines):
    """Yield (line_index, indent, kind, u, v, q, a) for every object that needs an id."""
    stack = []  # (key, bracket)
    u = v = q = a = 0
    for i, line in enumerate(lines):
        m = KEY_OPEN.match(line)
        if m:
            stack.append((m.group(2), m.group(3)))
            if m.group(2) in ("pq", "quiz"):
                q = 0
            if m.group(2) == "quiz" and m.group(3) == "{":
                yield i, m.group(1), "zid", u, v, q, a
            continue
        m = ANON_OPEN.match(line)
        if m:
            indent, bracket = m.group(1), m.group(2)
            parent = stack[-1][0] if stack else None
            grand = stack[-2][0] if len(stack) > 1 else None
            if bracket == "{" and parent == "units":
                u += 1
                v = a = 0
                yield i, indent, "uid", u, v, q, a
            elif bracket == "{" and parent == "vids":
                v += 1
                q = 0
                yield i, indent, "vid", u, v, q, a
            elif bracket == "{" and parent == "qs":
                q += 1
                kind = "qid_pq" if grand == "pq" else "qid_quiz"
                yield i, indent, kind, u, v, q, a
            elif bracket == "{" and parent == "assigns":
                a += 1
                yield i, indent, "aid", u, v, q, a
            stack.append((None, bracket))
            continue
        if CLOSE.match(line) and stack:
            stack.pop()


FIELD = {"uid": "uid", "aid": "aid", "qid_quiz": "qid", "qid_pq": "qid", "vid": "vid", "zid": "zid"}


def process(path: Path, id_map, write: bool):
    text = path.read_text(encoding="utf-8")
    lines = text.split("\n")
    data = json.loads(text)
    code = course_code(data["id"])
    cmap = (id_map or {}).get(data["id"], {})
    inserts = []  # (line_index, new_line) / replacements applied in place
    changed = 0
    for i, indent, kind, u, v, q, a in objects(lines):
        field = FIELD[kind]
        value = dummy_id(kind, code, u, v, q, a)
        if cmap:
            unit = cmap["units"][u - 1]
            if kind == "uid":
                value = unit["uid"]
            elif kind == "aid":
                value = unit["assigns"][a - 1]
            elif kind == "qid_quiz":
                value = unit["quiz"][q - 1]
            elif kind == "vid":
                value = unit.get("vids", [value] * v)[v - 1]
            elif kind == "zid":
                value = (unit.get("zid") or [value])[0]
            else:
                value = unit["pq"][v - 1][q - 1]
        nxt = lines[i + 1] if i + 1 < len(lines) else ""
        existing = re.match(rf'^(\s*)"{field}":\s*"([^"]*)",\s*$', nxt)
        if existing:
            if cmap and existing.group(2) != value:
                lines[i + 1] = f'{existing.group(1)}"{field}": {json.dumps(value, ensure_ascii=False)},'
                changed += 1
        else:
            inserts.append((i + 1, f'{indent}  "{field}": {json.dumps(value, ensure_ascii=False)},'))
    for pos, new in reversed(inserts):
        lines.insert(pos, new)
    changed += len(inserts)
    if changed and write:
        path.write_text("\n".join(lines), encoding="utf-8")
    return changed


def course_files(lang):
    return sorted(p for p in (COURSES / lang).glob("*.json") if p.name != "index.json")


def collect(path: Path):
    """Return the ids of one file as plain lists, in document order."""
    d = json.loads(path.read_text(encoding="utf-8"))
    units = []
    for u in d["units"]:
        units.append(
            {
                "uid": u.get("uid"),
                "assigns": [x.get("aid") for x in u.get("assigns", [])],
                "quiz": [q.get("qid") for q in (u.get("quiz") or {}).get("qs", [])],
                "vids": [vid.get("vid") for vid in u.get("vids", [])],
                "zid": [u["quiz"].get("zid")] if isinstance(u.get("quiz"), dict) else [],
                "pq": [[q.get("qid") for q in (vid.get("pq") or {}).get("qs", [])] for vid in u.get("vids", [])],
            }
        )
    return d["id"], units


def flat(units):
    out = []
    for u in units:
        out.append(u["uid"])
        out += u["assigns"] + u["quiz"] + u["vids"] + u["zid"]
        for p in u["pq"]:
            out += p
    return out


def check(no_dummy: bool) -> int:
    problems = []
    for p in course_files("en"):
        cid, base = collect(p)
        ids = flat(base)
        if any(not x for x in ids):
            problems.append(f"{p.name}: missing id (run the script without --check)")
        if len(ids) != len(set(ids)):
            problems.append(f"{p.name}: duplicate id inside the course")
        if no_dummy and any("DUMMY" in (x or "") for x in ids):
            problems.append(f"{p.name}: still has DUMMY ids")
        for lang in LANGS[1:]:
            q = COURSES / lang / p.name
            if not q.exists():
                problems.append(f"{lang}/{p.name}: file is missing")
                continue
            _, other = collect(q)
            if other != base:
                problems.append(f"{lang}/{p.name}: ids differ from the English file")
    all_ids = []
    for p in course_files("en"):
        all_ids += flat(collect(p)[1])
    if len(all_ids) != len(set(all_ids)):
        problems.append("an id is used in more than one course")
    for x in problems:
        print("PROBLEM:", x)
    print("OK" if not problems else f"{len(problems)} problem(s)")
    return 1 if problems else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--no-dummy", action="store_true")
    ap.add_argument("--dump-map")
    ap.add_argument("--apply-map")
    args = ap.parse_args()

    if args.check:
        sys.exit(check(args.no_dummy))
    if args.dump_map:
        out = {}
        for p in course_files("en"):
            cid, units = collect(p)
            out[cid] = {"units": units}
        Path(args.dump_map).write_text(json.dumps(out, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"wrote {args.dump_map}")
        return
    id_map = json.loads(Path(args.apply_map).read_text(encoding="utf-8")) if args.apply_map else None
    total = 0
    for lang in LANGS:
        for p in course_files(lang):
            total += process(p, id_map, write=True)
    print(f"{total} id line(s) added or changed")


if __name__ == "__main__":
    main()
