# Repository migration: OntarioEdAI to Axiom-Education

## Target state

- Repository: `Zoverions/Axiom-Education`
- Product: **Axiom Education**
- Default branch: `main`
- Historical URL: `Zoverions/OntarioEdAI` retained only through GitHub's automatic redirect
- Ontario content: jurisdictional curriculum pack, not platform identity

## GitHub administrative change

From the repository settings:

1. Open **Settings → General → Repository name**.
2. Rename `OntarioEdAI` to `Axiom-Education`.
3. Set **Settings → Branches → Default branch** to `main`.
4. Confirm branch-protection rules and required checks target `main`.
5. Do not create a replacement repository at the old slug; preserve GitHub's redirect.

GitHub redirects ordinary web, clone, fetch, and push traffic from the former repository URL after a rename, but local remotes should still be updated explicitly:

```bash
git remote set-url origin https://github.com/Zoverions/Axiom-Education.git
git remote -v
```

## Required post-rename verification

```bash
python tools/check_capabilities.py
python -m unittest discover -s tests -p 'test_curriculum_pack.py' -v
flutter pub get --enforce-lockfile
flutter analyze
flutter test
```

Also verify:

- the protected `Axiom Education Rebuild` workflow runs on `main`;
- README and documentation links resolve under the new slug;
- AXIOM-MESH contains no pinned reference to the deprecated repository slug;
- open issues and pull requests remain present after the rename;
- package registries, deployment manifests, local clones, and external automation use the new remote.

## Compatibility policy

The Dart package identifier `ontarioedai` is not changed in this repository-administration tranche. Renaming it changes every `package:` import and generated platform project. It is recorded as a temporary compatibility shim and will be migrated in one isolated, full-suite-gated change before `0.6.0`.

No runtime compatibility is provided for the deprecated LAN mesh, synthetic model outputs, unencrypted learner storage, or legacy architecture claims.
