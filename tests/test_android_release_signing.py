from pathlib import Path


GRADLE_FILE = Path("android/app/build.gradle.kts")
WORKFLOW_FILE = Path(".github/workflows/rebuild.yml")
RELEASE_WORKFLOW_FILE = Path(".github/workflows/android-release-candidate.yml")


def test_android_release_signing_fails_closed_without_complete_credentials():
    config = GRADLE_FILE.read_text(encoding="utf-8")

    assert "dummy.jks" not in config
    assert "releaseSigningRequiredKeys" in config
    assert "releaseSigningReady" in config
    assert "releaseTaskRequested" in config
    assert "GradleException(" in config
    assert "keyAlias" in config
    assert "keyPassword" in config
    assert "storeFile" in config
    assert "storePassword" in config


def test_debug_configuration_does_not_require_release_credentials():
    config = GRADLE_FILE.read_text(encoding="utf-8")

    assert "if (releaseTaskRequested && !releaseSigningReady)" in config
    assert "if (releaseSigningReady)" in config


def test_android_launch_verification_uses_bounded_process_start_evidence():
    workflow = WORKFLOW_FILE.read_text(encoding="utf-8")

    assert 'launch_deadline=$((SECONDS + 30))' in workflow
    assert 'if (( SECONDS >= launch_deadline ))' in workflow
    assert 'Application process did not start within 30 seconds' in workflow
    assert 'grep -F "Status: ok"' not in workflow


def test_android_release_candidate_is_manual_exact_head_and_fail_closed():
    workflow = RELEASE_WORKFLOW_FILE.read_text(encoding="utf-8")

    assert "workflow_dispatch:" in workflow
    assert "pull_request:" not in workflow
    assert "push:" not in workflow
    assert "schedule:" not in workflow
    assert "permissions:\n  contents: read" in workflow
    assert "ref: ${{ inputs.source_sha }}" in workflow
    assert "persist-credentials: false" in workflow
    assert 'test "$(git rev-parse FETCH_HEAD)" = "$SOURCE_SHA"' in workflow
    assert "development versions cannot be built as release candidates" in workflow
    assert "CHANGELOG.md has no exact release heading" in workflow
    assert "dummy.jks" not in workflow

    for secret in (
        "AXIOM_ANDROID_KEYSTORE_BASE64",
        "AXIOM_ANDROID_KEY_ALIAS",
        "AXIOM_ANDROID_KEY_PASSWORD",
        "AXIOM_ANDROID_STORE_PASSWORD",
    ):
        assert secret in workflow

    assert "base64 --decode" in workflow
    assert "trap cleanup EXIT" in workflow
    assert "flutter build apk --release --no-pub" in workflow
    assert '"$apksigner" verify --verbose "$apk"' in workflow
    assert "Confirm no signing material survived the build step" in workflow


def test_android_release_candidate_never_claims_install_or_upgrade_readiness():
    workflow = RELEASE_WORKFLOW_FILE.read_text(encoding="utf-8")

    assert '"install_verification": "not-run"' in workflow
    assert '"upgrade_verification": "not-run"' in workflow
    assert '"release_ready": False' in workflow
    assert "do not prove installation" in workflow
    assert "actions/upload-artifact@cf430e030ddbb5b0abf93d22962f4752f3646cd9" in workflow
