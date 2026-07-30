# Repository branch hygiene

**Canonical branch:** `main`  
**Repository:** `Zoverions/Axiom-Education`

Axiom Education uses one durable development branch: `main`.

Short-lived branches exist only for an active pull request. After merge or closure, their commits remain in Git history or an archival tag and the branch ref is removed.

## Cleanup guarantees

The protected branch-hygiene workflow uses `tools/repository_branch_cleanup.py` and applies these rules:

1. Verify that GitHub reports `main` as the default branch.
2. Enumerate every repository branch and every open pull request.
3. Preserve `main` and any same-repository branch that is the head of an open human review.
4. During an explicitly approved dependency-queue consolidation, close only pull requests authored by `dependabot[bot]`, targeting `main`, and using a same-repository `dependabot/` head branch.
5. Comment on each closed automated pull request with its disposition and preserve its exact head commit as an archival tag before deleting the branch.
6. Delete a branch directly when it has no commits ahead of `main`.
7. When a branch has commits not reachable from `main`, create a lightweight tag at its exact head before deleting the branch.
8. Fail if an obsolete protected branch cannot be removed.
9. Re-enumerate branches and fail unless only `main` and active human-review branches remain.
10. Upload a machine-readable cleanup report and publish durable repository evidence.

## Archival tags

Unique branch heads removed in the July 30, 2026 cleanup are retained under:

```text
archive/branches/2026-07-30/<former-branch-name>
```

An archival tag preserves the exact commit graph without leaving an apparently active development branch. It does not make the tagged implementation current, supported, secure, or production-ready.

## Dependency updates

Automated dependency pull requests are inputs to review, not permanent development branches. When a bot queue becomes stale, conflicting, or fragmented, it may be closed and replaced by one controlled dependency-upgrade tranche. Human-authored pull requests are never closed by the automated dependency-queue rule.

## Ongoing policy

- New work branches from `main`.
- Every work branch must have an active pull request or be deleted.
- Merged branches are deleted promptly.
- Abandoned branches with unique commits are tagged before deletion only when the commits retain traceability value.
- Releases use signed release tags rather than permanent release branches unless a maintained release line is explicitly established.
- Archived tags are immutable evidence; corrections use a new tag and a documented disposition rather than moving an existing archive tag.
