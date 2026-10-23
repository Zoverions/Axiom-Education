from pathlib import Path


GRADLE_FILE = Path("android/app/build.gradle.kts")


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
