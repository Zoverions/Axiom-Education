import pytest

from tools.verify import (
    VerificationSetupError,
    parse_openssl_major,
    validate_flutter_payload,
    verification_commands,
)


def test_verification_command_covers_pinned_install_and_complete_checks():
    commands = verification_commands("flutter", "dart")
    rendered = [" ".join(command) for _, command in commands]

    assert any("requirements-dev.txt" in command for command in rendered)
    assert "flutter pub get --enforce-lockfile" in rendered
    assert any("tools/check_capabilities.py" in command for command in rendered)
    assert any("tools/mth1w_official_inventory.py verify" in command for command in rendered)
    assert any("tools/check_curriculum_readiness.py" in command for command in rendered)
    assert any("pytest -q" in command for command in rendered)
    assert any("format --output=none --set-exit-if-changed" in command for command in rendered)
    assert "flutter analyze --no-fatal-infos" in rendered
    assert any("flutter test --no-pub" in command for command in rendered)


def test_toolchain_version_parsers_accept_the_supported_versions():
    validate_flutter_payload(
        {"frameworkVersion": "3.41.1", "dartSdkVersion": "3.11.0"}
    )
    assert parse_openssl_major("OpenSSL 3.5.7 9 Jun 2026") == 3


def test_toolchain_version_parsers_reject_unsupported_versions():
    with pytest.raises(VerificationSetupError):
        validate_flutter_payload(
            {"frameworkVersion": "3.42.0", "dartSdkVersion": "3.12.0"}
        )
    with pytest.raises(VerificationSetupError):
        parse_openssl_major("LibreSSL 4.2.0")
