# Repository rename record: OntarioEdAI to Axiom-Education

**Status:** completed  
**Completed:** 2026-07-30

## Canonical state

- Repository: `Zoverions/Axiom-Education`
- Product: **Axiom Education**
- Default branch: `main`
- Historical URL: `Zoverions/OntarioEdAI`, retained only through GitHub's automatic redirect
- Ontario content: jurisdictional curriculum pack, not platform identity

## Completed GitHub administration

The repository was renamed from `OntarioEdAI` to `Axiom-Education`, and `main` was set as the default branch.

The completed administrative state must remain:

1. repository name `Axiom-Education`;
2. default branch `main`;
3. branch protection and required checks targeting `main`;
4. no replacement repository created at the deprecated slug;
5. the former URL retained only as GitHub's redirect.

Local remotes should use the canonical URL explicitly:

```bash
git remote set-url origin https://github.com/Zoverions/Axiom-Education.git
git remote -v
```

## Post-rename verification

```bash
python tools/check_capabilities.py
python -m unittest discover -s tests -p 'test_curriculum_pack.py' -v
flutter pub get --enforce-lockfile
flutter analyze
flutter test
```

Verified repository conditions:

- the canonical repository resolves as `Zoverions/Axiom-Education`;
- GitHub reports `main` as the default branch;
- the protected `Axiom Education CI` workflow targets `main` and pull requests;
- README and canonical documentation identify the new repository and product;
- AXIOM-MESH contains no current code-search result for the deprecated repository slug;
- historical issues, pull requests, commits, and redirects remain part of the same repository identity.

External package registries, deployment manifests, local clones, mirrors, and automation must use the canonical remote rather than relying on redirects.

## Compatibility policy

The Dart package identifier `ontarioedai` is not changed in this repository-administration tranche. Renaming it changes every `package:` import and generated platform project. It is recorded as a temporary compatibility shim and will be migrated in one isolated, full-suite-gated change before `0.6.0`.

No runtime compatibility is provided for the deprecated LAN mesh, synthetic model outputs, unencrypted learner storage, or legacy architecture claims.
