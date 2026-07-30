#!/usr/bin/env python3
"""Reversibly reduce a GitHub repository to its canonical active branches.

The default mode is a dry run. In --apply mode, every non-default branch that
contains commits not reachable from the default branch is first preserved as a
lightweight archival tag. Branches with no unique commits are deleted directly.
Open pull-request head branches from the same repository are always preserved.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import asdict, dataclass
from datetime import date
from pathlib import Path
from typing import Any, Iterable

API_ROOT = "https://api.github.com"
MAX_BRANCHES = 500


class CleanupError(RuntimeError):
    """Raised when cleanup cannot be completed safely."""


class ApiError(CleanupError):
    def __init__(self, status: int, message: str, body: str = "") -> None:
        super().__init__(f"GitHub API {status}: {message}{': ' + body if body else ''}")
        self.status = status
        self.body = body


@dataclass(frozen=True)
class Branch:
    name: str
    sha: str
    protected: bool


@dataclass(frozen=True)
class Decision:
    name: str
    sha: str
    protected: bool
    action: str
    reason: str
    archive_tag: str | None = None


class GitHubApi:
    def __init__(self, repository: str, token: str | None) -> None:
        if repository.count("/") != 1:
            raise CleanupError("repository must be in owner/name form")
        self.repository = repository
        self.token = token

    def _request(
        self,
        method: str,
        url_or_path: str,
        *,
        payload: dict[str, Any] | None = None,
        expected: Iterable[int] = (200,),
    ) -> tuple[Any, dict[str, str]]:
        url = url_or_path if url_or_path.startswith("https://") else f"{API_ROOT}{url_or_path}"
        headers = {
            "Accept": "application/vnd.github+json",
            "User-Agent": "axiom-education-branch-hygiene",
            "X-GitHub-Api-Version": "2022-11-28",
        }
        if self.token:
            headers["Authorization"] = f"Bearer {self.token}"
        data = None
        if payload is not None:
            data = json.dumps(payload, separators=(",", ":")).encode("utf-8")
            headers["Content-Type"] = "application/json"

        request = urllib.request.Request(url, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                raw = response.read()
                status = response.status
                response_headers = {key.lower(): value for key, value in response.headers.items()}
        except urllib.error.HTTPError as error:
            raw = error.read()
            body = raw.decode("utf-8", errors="replace")
            raise ApiError(error.code, error.reason, body) from error
        except urllib.error.URLError as error:
            raise CleanupError(f"GitHub API connection failed: {error.reason}") from error

        if status not in set(expected):
            raise ApiError(status, "unexpected response", raw.decode("utf-8", errors="replace"))
        if not raw:
            return None, response_headers
        try:
            return json.loads(raw), response_headers
        except json.JSONDecodeError as error:
            raise CleanupError(f"GitHub API returned invalid JSON from {url}") from error

    def paginated(self, path: str) -> list[Any]:
        url = f"{API_ROOT}{path}"
        items: list[Any] = []
        while url:
            page, headers = self._request("GET", url)
            if not isinstance(page, list):
                raise CleanupError(f"expected array from {url}")
            items.extend(page)
            url = next_link(headers.get("link", ""))
        return items

    def repository_metadata(self) -> dict[str, Any]:
        data, _ = self._request("GET", f"/repos/{self.repository}")
        if not isinstance(data, dict):
            raise CleanupError("repository metadata is not an object")
        return data

    def branches(self) -> list[Branch]:
        rows = self.paginated(f"/repos/{self.repository}/branches?per_page=100")
        if len(rows) > MAX_BRANCHES:
            raise CleanupError(f"refusing to process more than {MAX_BRANCHES} branches")
        result: list[Branch] = []
        for row in rows:
            try:
                result.append(
                    Branch(
                        name=str(row["name"]),
                        sha=str(row["commit"]["sha"]),
                        protected=bool(row.get("protected", False)),
                    )
                )
            except (KeyError, TypeError) as error:
                raise CleanupError("branch response is missing required fields") from error
        return result

    def open_pull_request_heads(self) -> set[str]:
        rows = self.paginated(f"/repos/{self.repository}/pulls?state=open&per_page=100")
        heads: set[str] = set()
        for row in rows:
            head = row.get("head") if isinstance(row, dict) else None
            head_repo = head.get("repo") if isinstance(head, dict) else None
            if isinstance(head_repo, dict) and head_repo.get("full_name") == self.repository:
                ref = head.get("ref")
                if isinstance(ref, str) and ref:
                    heads.add(ref)
        return heads

    def ahead_by(self, default_branch: str, branch_sha: str) -> int:
        comparison = urllib.parse.quote(f"{default_branch}...{branch_sha}", safe=".")
        data, _ = self._request("GET", f"/repos/{self.repository}/compare/{comparison}")
        ahead = data.get("ahead_by") if isinstance(data, dict) else None
        if not isinstance(ahead, int) or ahead < 0:
            raise CleanupError(f"invalid comparison result for {branch_sha}")
        return ahead

    def ensure_tag(self, tag: str, sha: str) -> None:
        ref = f"refs/tags/{tag}"
        try:
            self._request(
                "POST",
                f"/repos/{self.repository}/git/refs",
                payload={"ref": ref, "sha": sha},
                expected=(201,),
            )
            return
        except ApiError as error:
            if error.status != 422:
                raise

        encoded = urllib.parse.quote(f"tags/{tag}", safe="/")
        existing, _ = self._request("GET", f"/repos/{self.repository}/git/ref/{encoded}")
        existing_sha = existing.get("object", {}).get("sha") if isinstance(existing, dict) else None
        if existing_sha != sha:
            raise CleanupError(f"archive tag {tag} already exists at a different commit")

    def delete_branch(self, branch: str) -> None:
        encoded = urllib.parse.quote(f"heads/{branch}", safe="/")
        self._request(
            "DELETE",
            f"/repos/{self.repository}/git/refs/{encoded}",
            expected=(204,),
        )


def next_link(link_header: str) -> str:
    for segment in link_header.split(","):
        parts = [part.strip() for part in segment.split(";")]
        if len(parts) >= 2 and parts[1] == 'rel="next"':
            return parts[0].strip("<>")
    return ""


def build_plan(
    branches: list[Branch],
    *,
    default_branch: str,
    active_pr_heads: set[str],
    ahead_by_branch: dict[str, int],
    archive_prefix: str,
) -> list[Decision]:
    names = [branch.name for branch in branches]
    if len(names) != len(set(names)):
        raise CleanupError("duplicate branch names returned by GitHub")
    if default_branch not in names:
        raise CleanupError(f"default branch {default_branch!r} is missing")
    unknown_heads = active_pr_heads.difference(names)
    if unknown_heads:
        raise CleanupError(f"open pull requests reference missing branches: {sorted(unknown_heads)}")

    plan: list[Decision] = []
    for branch in sorted(branches, key=lambda item: item.name):
        if branch.name == default_branch:
            plan.append(
                Decision(branch.name, branch.sha, branch.protected, "preserve", "canonical default branch")
            )
            continue
        if branch.name in active_pr_heads:
            plan.append(
                Decision(branch.name, branch.sha, branch.protected, "preserve", "open pull-request head")
            )
            continue
        ahead = ahead_by_branch.get(branch.name)
        if ahead is None:
            raise CleanupError(f"missing comparison for branch {branch.name}")
        if ahead == 0:
            plan.append(
                Decision(
                    branch.name,
                    branch.sha,
                    branch.protected,
                    "delete",
                    "no commits ahead of the canonical branch",
                )
            )
        else:
            plan.append(
                Decision(
                    branch.name,
                    branch.sha,
                    branch.protected,
                    "archive-delete",
                    f"{ahead} commit(s) not reachable from the canonical branch",
                    f"{archive_prefix}/{branch.name}",
                )
            )
    return plan


def render_report(
    *,
    repository: str,
    default_branch: str,
    initial_count: int,
    final_branches: list[str] | None,
    plan: list[Decision],
    applied: bool,
) -> dict[str, Any]:
    return {
        "schema": "axiom-education-branch-cleanup.v1",
        "repository": repository,
        "default_branch": default_branch,
        "mode": "apply" if applied else "dry-run",
        "initial_branch_count": initial_count,
        "final_branch_count": len(final_branches) if final_branches is not None else None,
        "final_branches": final_branches,
        "summary": {
            "preserved": sum(decision.action == "preserve" for decision in plan),
            "deleted_merged": sum(decision.action == "delete" for decision in plan),
            "archived_then_deleted": sum(decision.action == "archive-delete" for decision in plan),
        },
        "decisions": [asdict(decision) for decision in plan],
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repository", default=os.getenv("GITHUB_REPOSITORY"))
    parser.add_argument("--token", default=os.getenv("GITHUB_TOKEN"))
    parser.add_argument("--default-branch", default="main")
    parser.add_argument(
        "--archive-prefix",
        default=f"archive/branches/{date.today().isoformat()}",
    )
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--report", type=Path)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not args.repository:
        print("repository is required", file=sys.stderr)
        return 2
    if args.apply and not args.token:
        print("--apply requires a GitHub token", file=sys.stderr)
        return 2

    try:
        api = GitHubApi(args.repository, args.token)
        metadata = api.repository_metadata()
        actual_default = metadata.get("default_branch")
        if actual_default != args.default_branch:
            raise CleanupError(
                f"repository default branch is {actual_default!r}, expected {args.default_branch!r}"
            )

        branches = api.branches()
        active_heads = api.open_pull_request_heads()
        comparisons = {
            branch.name: api.ahead_by(args.default_branch, branch.sha)
            for branch in branches
            if branch.name != args.default_branch and branch.name not in active_heads
        }
        plan = build_plan(
            branches,
            default_branch=args.default_branch,
            active_pr_heads=active_heads,
            ahead_by_branch=comparisons,
            archive_prefix=args.archive_prefix.rstrip("/"),
        )

        final_names: list[str] | None = None
        if args.apply:
            for decision in plan:
                if decision.action == "preserve":
                    continue
                if decision.protected:
                    raise CleanupError(
                        f"branch {decision.name} is protected; remove its obsolete protection before cleanup"
                    )
                if decision.action == "archive-delete":
                    if not decision.archive_tag:
                        raise CleanupError(f"archive tag missing for {decision.name}")
                    api.ensure_tag(decision.archive_tag, decision.sha)
                api.delete_branch(decision.name)

            final_names = sorted(branch.name for branch in api.branches())
            expected = sorted({args.default_branch, *active_heads})
            if final_names != expected:
                raise CleanupError(
                    f"cleanup incomplete: remaining branches {final_names}, expected {expected}"
                )

        report = render_report(
            repository=args.repository,
            default_branch=args.default_branch,
            initial_count=len(branches),
            final_branches=final_names,
            plan=plan,
            applied=args.apply,
        )
        rendered = json.dumps(report, indent=2, sort_keys=True) + "\n"
        if args.report:
            args.report.parent.mkdir(parents=True, exist_ok=True)
            args.report.write_text(rendered, encoding="utf-8")
        print(rendered, end="")
        return 0
    except (CleanupError, OSError) as error:
        print(f"branch cleanup failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
