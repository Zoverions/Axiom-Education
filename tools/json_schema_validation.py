"""Execute repository JSON Schemas as fail-closed runtime and CI gates."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker
from jsonschema.exceptions import SchemaError


class RepositoryJsonSchemaError(ValueError):
    """Raised when a schema is invalid or an instance does not conform."""


def _json_path(parts: list[object]) -> str:
    value = "$"
    for part in parts:
        if isinstance(part, int):
            value += f"[{part}]"
        else:
            value += f".{part}"
    return value


def validate_json_schema(
    instance: Any,
    schema_path: Path,
    *,
    label: str,
) -> None:
    try:
        schema = json.loads(schema_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise RepositoryJsonSchemaError(
            f"cannot load JSON Schema {schema_path}: {error}"
        ) from error
    if not isinstance(schema, dict):
        raise RepositoryJsonSchemaError(
            f"JSON Schema root must be an object: {schema_path}"
        )
    try:
        Draft202012Validator.check_schema(schema)
    except SchemaError as error:
        raise RepositoryJsonSchemaError(
            f"invalid JSON Schema {schema_path}: {error.message}"
        ) from error

    validator = Draft202012Validator(schema, format_checker=FormatChecker())
    errors = sorted(
        validator.iter_errors(instance),
        key=lambda error: [str(part) for part in error.absolute_path],
    )
    if errors:
        error = errors[0]
        path = _json_path(list(error.absolute_path))
        raise RepositoryJsonSchemaError(
            f"{label} fails {schema_path.name} at {path}: {error.message}"
        )
