import importlib.util
import json
import unittest
from pathlib import Path

MODULE_PATH = Path(__file__).resolve().parents[1] / "tools" / "repository_branch_cleanup.py"
SPEC = importlib.util.spec_from_file_location("repository_branch_cleanup", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)

Branch = MODULE.Branch
CleanupError = MODULE.CleanupError
build_plan = MODULE.build_plan
next_link = MODULE.next_link
render_report = MODULE.render_report


class BranchCleanupPlanningTest(unittest.TestCase):
    def test_preserves_main_deletes_merged_and_archives_unique(self) -> None:
        branches = [
            Branch("main", "a" * 40, True),
            Branch("merged-work", "b" * 40, False),
            Branch("unmerged-work", "c" * 40, False),
        ]

        plan = build_plan(
            branches,
            default_branch="main",
            active_pr_heads=set(),
            ahead_by_branch={"merged-work": 0, "unmerged-work": 3},
            archive_prefix="archive/branches/2026-07-30",
        )

        by_name = {decision.name: decision for decision in plan}
        self.assertEqual(by_name["main"].action, "preserve")
        self.assertEqual(by_name["merged-work"].action, "delete")
        self.assertEqual(by_name["unmerged-work"].action, "archive-delete")
        self.assertEqual(
            by_name["unmerged-work"].archive_tag,
            "archive/branches/2026-07-30/unmerged-work",
        )

    def test_preserves_open_pull_request_head(self) -> None:
        branches = [
            Branch("main", "a" * 40, True),
            Branch("active-review", "b" * 40, False),
        ]
        plan = build_plan(
            branches,
            default_branch="main",
            active_pr_heads={"active-review"},
            ahead_by_branch={},
            archive_prefix="archive/branches/2026-07-30",
        )
        self.assertEqual(plan[0].action, "preserve")
        self.assertEqual(plan[1].action, "preserve")
        self.assertEqual(plan[1].reason, "open pull-request head")

    def test_rejects_missing_default_branch(self) -> None:
        with self.assertRaises(CleanupError):
            build_plan(
                [Branch("other", "a" * 40, False)],
                default_branch="main",
                active_pr_heads=set(),
                ahead_by_branch={"other": 0},
                archive_prefix="archive/branches/2026-07-30",
            )

    def test_rejects_missing_comparison(self) -> None:
        with self.assertRaises(CleanupError):
            build_plan(
                [Branch("main", "a" * 40, True), Branch("other", "b" * 40, False)],
                default_branch="main",
                active_pr_heads=set(),
                ahead_by_branch={},
                archive_prefix="archive/branches/2026-07-30",
            )

    def test_report_is_machine_readable(self) -> None:
        plan = build_plan(
            [Branch("main", "a" * 40, True), Branch("old", "b" * 40, False)],
            default_branch="main",
            active_pr_heads=set(),
            ahead_by_branch={"old": 0},
            archive_prefix="archive/branches/2026-07-30",
        )
        report = render_report(
            repository="Zoverions/Axiom-Education",
            default_branch="main",
            initial_count=2,
            final_branches=["main"],
            plan=plan,
            applied=True,
        )
        encoded = json.dumps(report)
        decoded = json.loads(encoded)
        self.assertEqual(decoded["final_branch_count"], 1)
        self.assertEqual(decoded["summary"]["deleted_merged"], 1)

    def test_parses_next_link(self) -> None:
        header = (
            '<https://api.github.com/example?page=2>; rel="next", '
            '<https://api.github.com/example?page=3>; rel="last"'
        )
        self.assertEqual(next_link(header), "https://api.github.com/example?page=2")
        self.assertEqual(next_link(""), "")


if __name__ == "__main__":
    unittest.main()
