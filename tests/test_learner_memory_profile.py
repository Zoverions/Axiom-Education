from __future__ import annotations

import hashlib
from pathlib import Path

import pytest

from tools.learner_memory_profile import (
    EXPECTED_EVENT_MEMORY_KINDS,
    EXPECTED_SHA256,
    LearnerMemoryProfileError,
    PROFILE_PATH,
    load_profile,
)


def test_learner_memory_profile_is_exactly_digest_pinned() -> None:
    raw = PROFILE_PATH.read_bytes()
    assert len(raw) == 971
    assert hashlib.sha256(raw).hexdigest() == EXPECTED_SHA256
    profile = load_profile()
    assert profile["event_type_to_memory_kind"] == EXPECTED_EVENT_MEMORY_KINDS


def test_learner_memory_profile_rejects_even_semantically_valid_byte_drift(tmp_path: Path) -> None:
    profile = PROFILE_PATH.read_bytes()
    changed = tmp_path / "learner-memory.json"
    changed.write_bytes(profile + b"\n")
    with pytest.raises(LearnerMemoryProfileError, match="digest drift"):
        load_profile(changed)
