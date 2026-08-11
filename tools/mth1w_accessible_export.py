#!/usr/bin/env python3
"""Build deterministic, printable, nonvisual MTH1W lesson exports.

The export is a delivery alternative for the current authored draft. It does not establish
WCAG/AODA conformance, pedagogical validity, educator approval, or course completion.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import sys
import tempfile
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = ROOT / "build" / "mth1w-accessible-offline"
EXPECTED_LESSONS = 43

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.mth1w_review_evidence import canonical_digest, load_authored_units  # noqa: E402


class AccessibleExportError(RuntimeError):
    """Raised when a lesson cannot produce a bounded accessible/offline export."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AccessibleExportError(message)


def text(value: object, message: str) -> str:
    require(isinstance(value, str) and value.strip(), message)
    return value.strip()


def strings(value: object, message: str, minimum: int = 1) -> list[str]:
    require(isinstance(value, list) and len(value) >= minimum, message)
    require(all(isinstance(item, str) and item.strip() for item in value), message)
    return [str(item).strip() for item in value]


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def write_lines(lines: list[str]) -> bytes:
    return ("\n".join(lines).rstrip() + "\n").encode("utf-8")


def response_instruction(response: dict[str, Any]) -> str:
    response_type = response.get("type")
    if response_type == "selected":
        options = strings(response.get("options"), "selected response options missing", 2)
        return "Choose one: " + " | ".join(options)
    if response_type == "short_text":
        return "Write a short response."
    if response_type == "constructed":
        criteria = strings(response.get("criteria"), "constructed response criteria missing", 2)
        return "Construct a response addressing: " + "; ".join(criteria)
    raise AccessibleExportError(f"unsupported response type: {response_type!r}")


def answer_text(response: dict[str, Any]) -> list[str]:
    response_type = response.get("type")
    if response_type == "selected":
        return ["Answer: " + text(response.get("correct_answer"), "selected answer missing")]
    if response_type == "short_text":
        accepted = strings(response.get("accepted_answers"), "accepted answers missing")
        return ["Accepted answers: " + " | ".join(accepted)]
    if response_type == "constructed":
        return [
            "Review required: yes",
            "Sample response: " + text(response.get("sample_response"), "sample response missing"),
        ]
    raise AccessibleExportError(f"unsupported response type: {response_type!r}")


def render_item(item: dict[str, Any], *, include_answers: bool) -> list[str]:
    item_id = text(item.get("id"), "item id missing")
    prompt = text(item.get("prompt"), f"{item_id}: prompt missing")
    response = item.get("response")
    require(isinstance(response, dict), f"{item_id}: response missing")
    lines = [f"### {item_id}", "", prompt, "", response_instruction(response)]
    if include_answers:
        lines += [""] + answer_text(response)
        rationale = item.get("rationale")
        if isinstance(rationale, str) and rationale.strip():
            lines += ["", "Rationale: " + rationale.strip()]
    return lines + [""]


def validate_accessibility(lesson: dict[str, Any]) -> dict[str, Any]:
    lesson_id = text(lesson.get("id"), "lesson id missing")
    accessibility = lesson.get("accessibility")
    require(isinstance(accessibility, dict), f"{lesson_id}: accessibility contract missing")
    require(
        accessibility.get("printable_equivalent") is True,
        f"{lesson_id}: printable equivalent must be explicitly available",
    )
    text(accessibility.get("nonvisual_route"), f"{lesson_id}: nonvisual route missing")
    strings(
        accessibility.get("response_options"),
        f"{lesson_id}: alternate response options missing",
        2,
    )

    representations = lesson.get("representations")
    require(
        isinstance(representations, list) and len(representations) >= 2,
        f"{lesson_id}: representations missing",
    )
    for representation in representations:
        require(isinstance(representation, dict), f"{lesson_id}: representation invalid")
        representation_id = text(
            representation.get("id"), f"{lesson_id}: representation id missing"
        )
        text(
            representation.get("text_alternative"),
            f"{lesson_id}/{representation_id}: text alternative missing",
        )
    return accessibility


def render_lesson(
    unit: dict[str, Any], lesson: dict[str, Any], *, include_answers: bool
) -> bytes:
    lesson_id = text(lesson.get("id"), "lesson id missing")
    accessibility = validate_accessibility(lesson)
    unit_title = text(unit.get("title"), f"{lesson_id}: unit title missing")
    title = text(lesson.get("title"), f"{lesson_id}: title missing")
    expectations = strings(
        lesson.get("official_expectation_ids"),
        f"{lesson_id}: expectation ids missing",
    )

    lines = [
        f"# {title}",
        "",
        f"Course: MTH1W",
        f"Unit: {unit_title}",
        f"Lesson ID: {lesson_id}",
        f"Official expectation references: {', '.join(expectations)}",
        f"Estimated time: {lesson.get('estimated_minutes')} minutes",
        "",
        "> Draft learning material. Human educator, cultural/context, licensing, accessibility, and course-completion gates remain separate.",
        "",
        "## Learning goals",
        "",
    ]
    lines += [f"- {item}" for item in strings(lesson.get("learning_goals"), f"{lesson_id}: learning goals missing", 3)]
    lines += ["", "## Success criteria", ""]
    lines += [f"- {item}" for item in strings(lesson.get("success_criteria"), f"{lesson_id}: success criteria missing", 3)]

    lines += ["", "## Vocabulary", ""]
    vocabulary = lesson.get("vocabulary")
    require(isinstance(vocabulary, list) and vocabulary, f"{lesson_id}: vocabulary missing")
    for entry in vocabulary:
        require(isinstance(entry, dict), f"{lesson_id}: vocabulary entry invalid")
        lines.append(
            f"- **{text(entry.get('term'), f'{lesson_id}: vocabulary term missing')}** — "
            + text(entry.get("meaning"), f"{lesson_id}: vocabulary meaning missing")
        )

    lines += ["", "## Why this matters", "", text(lesson.get("why_it_matters"), f"{lesson_id}: why-it-matters missing")]
    lines += ["", "## Direct instruction", ""]
    instruction = lesson.get("direct_instruction")
    require(isinstance(instruction, list) and instruction, f"{lesson_id}: instruction missing")
    for block in instruction:
        require(isinstance(block, dict), f"{lesson_id}: instruction block invalid")
        lines += [
            f"### {text(block.get('heading'), f'{lesson_id}: instruction heading missing')}",
            "",
            text(block.get("body"), f"{lesson_id}: instruction body missing"),
            "",
        ]

    lines += ["## Method routes", ""]
    methods = lesson.get("method_routes")
    require(isinstance(methods, list) and len(methods) >= 2, f"{lesson_id}: method routes missing")
    for method in methods:
        require(isinstance(method, dict), f"{lesson_id}: method invalid")
        method_title = text(method.get("title"), f"{lesson_id}: method title missing")
        lines += [f"### {method_title}", ""]
        lines += [f"{index}. {step}" for index, step in enumerate(strings(method.get("steps"), f"{lesson_id}: method steps missing", 4), start=1)]
        lines += [
            "",
            "When useful: " + text(method.get("when_useful"), f"{lesson_id}: method use missing"),
            "Check: " + text(method.get("check"), f"{lesson_id}: method check missing"),
            "",
        ]

    lines += ["## Representations and nonvisual equivalents", ""]
    for representation in lesson["representations"]:
        label = text(representation.get("label"), f"{lesson_id}: representation label missing")
        description = text(representation.get("description"), f"{lesson_id}: representation description missing")
        alternative = text(representation.get("text_alternative"), f"{lesson_id}: representation alternative missing")
        lines += [f"### {label}", "", "Visual/structural description: " + description, "", "Nonvisual equivalent: " + alternative, ""]

    lines += ["## Worked examples", ""]
    examples = lesson.get("worked_examples")
    require(isinstance(examples, list) and len(examples) >= 2, f"{lesson_id}: worked examples missing")
    for example in examples:
        require(isinstance(example, dict), f"{lesson_id}: worked example invalid")
        example_id = text(example.get("id"), f"{lesson_id}: example id missing")
        lines += [f"### {example_id}", "", text(example.get("prompt"), f"{example_id}: prompt missing"), ""]
        steps = example.get("steps")
        require(isinstance(steps, list) and steps, f"{example_id}: steps missing")
        for index, step in enumerate(steps, start=1):
            require(isinstance(step, dict), f"{example_id}: step invalid")
            lines.append(
                f"{index}. **{text(step.get('label'), f'{example_id}: step label missing')}** — "
                + text(step.get("explanation"), f"{example_id}: step explanation missing")
            )
        if include_answers:
            lines += [
                "",
                "Answer: " + text(example.get("answer"), f"{example_id}: answer missing"),
                "Verification: " + text(example.get("verification"), f"{example_id}: verification missing"),
            ]
        lines.append("")

    lines += ["## Common misconceptions", ""]
    misconceptions = lesson.get("misconceptions")
    require(isinstance(misconceptions, list) and misconceptions, f"{lesson_id}: misconceptions missing")
    for misconception in misconceptions:
        require(isinstance(misconception, dict), f"{lesson_id}: misconception invalid")
        lines.append("- Claim: " + text(misconception.get("claim"), f"{lesson_id}: misconception claim missing"))
        if include_answers:
            lines.append("  Correction: " + text(misconception.get("correction"), f"{lesson_id}: misconception correction missing"))
    lines.append("")

    practice_sets = lesson.get("practice_sets")
    require(isinstance(practice_sets, dict), f"{lesson_id}: practice sets missing")
    for phase in ("guided", "independent", "retrieval"):
        lines += [f"## {phase.title()} practice", ""]
        items = practice_sets.get(phase)
        require(isinstance(items, list) and items, f"{lesson_id}: {phase} practice missing")
        for item in items:
            require(isinstance(item, dict), f"{lesson_id}: {phase} item invalid")
            lines += render_item(item, include_answers=include_answers)

    lines += ["## Reflection", "", text(lesson.get("reflection_prompt"), f"{lesson_id}: reflection prompt missing"), ""]
    lines += ["## Accessibility and alternate response routes", ""]
    lines += ["Nonvisual route: " + text(accessibility.get("nonvisual_route"), f"{lesson_id}: nonvisual route missing"), ""]
    lines.append("Available response routes:")
    lines += [f"- {option}" for option in strings(accessibility.get("response_options"), f"{lesson_id}: response options missing", 2)]
    lines += [
        "",
        "This UTF-8 Markdown export is designed to remain usable offline, printable as text, searchable, zoomable, and convertible by standard assistive/document tools without requiring the Flutter UI.",
    ]
    return write_lines(lines)


def build_package(output_dir: Path) -> dict[str, Any]:
    if output_dir.exists():
        shutil.rmtree(output_dir)
    lesson_dir = output_dir / "lessons"
    lesson_dir.mkdir(parents=True, exist_ok=True)

    records: list[dict[str, Any]] = []
    seen: set[str] = set()
    for _source_path, unit in load_authored_units():
        lessons = unit.get("lessons")
        require(isinstance(lessons, list), f"{unit.get('unit_id')}: lessons missing")
        for lesson in lessons:
            require(isinstance(lesson, dict), "lesson must be an object")
            lesson_id = text(lesson.get("id"), "lesson id missing")
            require(lesson_id not in seen, f"duplicate lesson id: {lesson_id}")
            seen.add(lesson_id)
            student = render_lesson(unit, lesson, include_answers=False)
            key = render_lesson(unit, lesson, include_answers=True)
            student_name = f"{lesson_id}.student.md"
            key_name = f"{lesson_id}.answer-key.md"
            (lesson_dir / student_name).write_bytes(student)
            (lesson_dir / key_name).write_bytes(key)
            records.append(
                {
                    "lesson_id": lesson_id,
                    "unit_id": unit["unit_id"],
                    "source_lesson_sha256": canonical_digest(lesson),
                    "student_path": f"lessons/{student_name}",
                    "student_sha256": sha256_bytes(student),
                    "answer_key_path": f"lessons/{key_name}",
                    "answer_key_sha256": sha256_bytes(key),
                    "format": "text/markdown; charset=utf-8",
                    "printable_equivalent": True,
                    "nonvisual_route_included": True,
                }
            )

    require(len(records) == EXPECTED_LESSONS, f"expected {EXPECTED_LESSONS} lesson exports, found {len(records)}")
    manifest = {
        "schema": "axiom-education-accessible-offline-export.v1",
        "course_code": "MTH1W",
        "status": "machine-verified-draft-alternative",
        "lesson_count": len(records),
        "formats": ["text/markdown; charset=utf-8"],
        "student_answers_separated": True,
        "human_accessibility_review_status": "required",
        "claim_boundary": (
            "These deterministic text exports provide printable/offline/nonvisual delivery alternatives for current draft lessons. "
            "They do not establish WCAG, AODA, pedagogical, or course-completion conformance."
        ),
        "records": records,
    }
    manifest_bytes = write_lines([json.dumps(manifest, ensure_ascii=False, sort_keys=True, separators=(",", ":"))])
    (output_dir / "manifest.json").write_bytes(manifest_bytes)
    return manifest


def verify_package(output_dir: Path) -> dict[str, Any]:
    manifest = build_package(output_dir)
    require(manifest["lesson_count"] == EXPECTED_LESSONS, "accessible export coverage incomplete")
    records = manifest["records"]
    require(isinstance(records, list), "export records missing")
    for record in records:
        require(isinstance(record, dict), "export record invalid")
        for path_field, digest_field in (
            ("student_path", "student_sha256"),
            ("answer_key_path", "answer_key_sha256"),
        ):
            artifact = output_dir / str(record[path_field])
            require(artifact.is_file(), f"export artifact missing: {artifact}")
            require(sha256_bytes(artifact.read_bytes()) == record[digest_field], f"export digest mismatch: {artifact}")
    return manifest


def verify_determinism() -> dict[str, Any]:
    with tempfile.TemporaryDirectory(prefix="axiom-accessible-a-") as first_dir, tempfile.TemporaryDirectory(prefix="axiom-accessible-b-") as second_dir:
        first = Path(first_dir)
        second = Path(second_dir)
        first_manifest = verify_package(first)
        second_manifest = verify_package(second)
        require(first_manifest == second_manifest, "accessible export manifest is not deterministic")
        first_files = sorted(path.relative_to(first) for path in first.rglob("*") if path.is_file())
        second_files = sorted(path.relative_to(second) for path in second.rglob("*") if path.is_file())
        require(first_files == second_files, "accessible export file set is not deterministic")
        for relative in first_files:
            require((first / relative).read_bytes() == (second / relative).read_bytes(), f"accessible export bytes differ: {relative}")
        return first_manifest


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    build = commands.add_parser("build", help="build the accessible/offline package")
    build.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    commands.add_parser("verify", help="build twice and prove deterministic accessible coverage")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        if args.command == "build":
            manifest = verify_package(args.output)
            print(f"accessible offline package built: {manifest['lesson_count']} lessons -> {args.output}")
        else:
            manifest = verify_determinism()
            print(
                "accessible offline export verified: "
                f"{manifest['lesson_count']} lessons; deterministic student + answer-key text routes"
            )
    except (OSError, KeyError, AccessibleExportError, ValueError) as error:
        print(f"MTH1W accessible export failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
