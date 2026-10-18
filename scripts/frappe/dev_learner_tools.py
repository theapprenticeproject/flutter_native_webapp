"""Helpers for inspecting and repairing test learners on a Frappe DEV site.

Run inside the bench console, from the bench directory:

    bench --site <site-name> console
    >>> exec(open("/path/to/dev_learner_tools.py").read())
    >>> show_phone("9123456780")

Reading is always safe. Every function that writes only prints what it WOULD
change until you pass apply=True. Check the site name printed at the top of every
output before you apply anything. Do not use this on production.

Field names come from what the dev site returned (Tapapp Auth -> Tapapp Auth
Profile rows -> tapapp_learner; Tapapp Learner -> enrollments). If the backend
schema changes, run show_schema() and adjust.
"""

import frappe


def _header(title):
    print(f"\n=== {title}  [site: {frappe.local.site}]")


def _profile_table_field():
    """Name of the Tapapp Auth field that holds the Tapapp Auth Profile rows."""
    for f in frappe.get_meta("Tapapp Auth").fields:
        if f.fieldtype == "Table" and f.options == "Tapapp Auth Profile":
            return f.fieldname
    raise RuntimeError("No Tapapp Auth Profile table found on Tapapp Auth")


def _find_auth(phone):
    """Find the Tapapp Auth record for a phone (keyed by phone), exact match first."""
    phone = str(phone).strip()
    if frappe.db.exists("Tapapp Auth", phone):
        return frappe.get_doc("Tapapp Auth", phone)
    names = frappe.get_all("Tapapp Auth", filters={"name": ["like", f"%{phone}%"]}, pluck="name")
    if len(names) == 1:
        return frappe.get_doc("Tapapp Auth", names[0])
    if not names:
        raise ValueError(f"No Tapapp Auth record found for {phone!r}")
    raise ValueError(f"More than one match for {phone!r}: {names}. Use the full name.")


def _enrollments(learner_doc):
    return [
        (e.course, e.status, e.videos_completed, e.quizzes_completed)
        for e in learner_doc.enrollments
    ]


def show_schema():
    """Print the fields and linked doctypes this script relies on."""
    _header("schema")
    print("Tapapp Auth profile table:", _profile_table_field())
    enr = frappe.get_meta("Tapapp Learner").get_field("enrollments").options
    course_field = frappe.get_meta(enr).get_field("course")
    print("Enrollment child doctype:", enr)
    print("course field:", course_field.fieldtype, "->", course_field.options)


def course_names():
    """Names in the doctype the enrollment 'course' field links to.

    Note: on the dev site these did NOT match the course ids stored in working
    enrollments (which are the app's bundled ids), so do not assume they are
    interchangeable. See documentation/todo.md.
    """
    _header("course doctype records")
    enr = frappe.get_meta("Tapapp Learner").get_field("enrollments").options
    doctype = frappe.get_meta(enr).get_field("course").options
    names = frappe.get_all(doctype, pluck="name")
    print(doctype, f"({len(names)} records)")
    for n in names:
        print("  ", n)
    return names


def show_phone(phone):
    """Read-only: list every profile on a phone, with each learner's enrollments."""
    _header(f"profiles for {phone}")
    auth = _find_auth(phone)
    for row in auth.get(_profile_table_field()):
        learner = frappe.get_doc("Tapapp Learner", row.tapapp_learner)
        print(
            f"- {row.tapapp_learner}  {row.student_name!r}  "
            f"onboarding_completed={row.onboarding_completed}"
        )
        print(f"    enrollments (course, status, videos, quizzes): {_enrollments(learner)}")


def set_course(learner, course, apply=False, ignore_links=False):
    """Point a learner's first enrollment at `course` (creates one if there is none).

    ignore_links=True skips Frappe's check that the course exists as a record of
    the linked doctype. The dev site's working data needed this for bundled ids.
    """
    _header(f"set_course {learner} -> {course!r}  (apply={apply})")
    doc = frappe.get_doc("Tapapp Learner", learner)
    print("before:", _enrollments(doc))
    if doc.enrollments:
        doc.enrollments[0].course = course
    else:
        doc.append("enrollments", {"course": course, "status": "active"})
    print("after: ", _enrollments(doc))
    if not apply:
        print("Dry run. Nothing saved. Call again with apply=True to save.")
        return
    doc.flags.ignore_links = ignore_links
    doc.save(ignore_permissions=True)
    frappe.db.commit()
    print("Saved. Now:", _enrollments(frappe.get_doc("Tapapp Learner", learner)))


def reset_for_onboarding(phone, learner, apply=False):
    """Make a profile run onboarding again: clear its enrollments and its
    onboarding_completed flag, so the app asks for a course choice."""
    _header(f"reset_for_onboarding {learner} on {phone}  (apply={apply})")
    auth = _find_auth(phone)
    rows = [r for r in auth.get(_profile_table_field()) if r.tapapp_learner == learner]
    if not rows:
        raise ValueError(f"{learner} is not a profile of {phone}")
    row = rows[0]
    doc = frappe.get_doc("Tapapp Learner", learner)
    print(f"onboarding_completed: {row.onboarding_completed} -> 0")
    print(f"enrollments: {_enrollments(doc)} -> []")
    if not apply:
        print("Dry run. Nothing saved. Call again with apply=True to save.")
        return
    row.onboarding_completed = 0
    auth.save(ignore_permissions=True)
    doc.set("enrollments", [])
    doc.save(ignore_permissions=True)
    frappe.db.commit()
    print("Saved. Log out and back in (or use a private window) in the app.")
    show_phone(phone)
