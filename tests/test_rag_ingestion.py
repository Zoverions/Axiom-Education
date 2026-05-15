import sys
from unittest.mock import MagicMock

# Mock chromadb and its dependencies since they are not installed
sys.modules["chromadb"] = MagicMock()
sys.modules["chromadb.utils"] = MagicMock()

import json
from unittest.mock import patch, mock_open
import pytest
from rag_ingestion import extract_expectations, load_curriculum

def test_load_curriculum_success():
    mock_data = {"courses": {"TEST": {"name": "Test Course"}}}
    mock_json = json.dumps(mock_data)

    with patch("builtins.open", mock_open(read_data=mock_json)):
        data = load_curriculum()
        assert data == mock_data

def test_load_curriculum_file_not_found(capsys):
    with patch("builtins.open", side_effect=FileNotFoundError):
        data = load_curriculum()
        assert data is None

        captured = capsys.readouterr()
        assert "Error: assets/curriculum/ontario_curriculum_full.json not found." in captured.out

def test_extract_expectations_basic():
    curriculum_data = {
        "courses": {
            "MTH1W": {
                "name": "Mathematics Grade 9",
                "strands": {
                    "Algebra": [
                        {
                            "id": "MTH1W-A1",
                            "expectation": "solve linear equations",
                            "tags": ["math", "algebra"]
                        }
                    ]
                }
            }
        }
    }

    expectations = list(extract_expectations(curriculum_data))
    assert len(expectations) == 1

    doc, meta, exp_id = expectations[0]
    assert exp_id == "MTH1W-A1"
    assert "Mathematics Grade 9" in doc
    assert "MTH1W" in doc
    assert "Algebra" in doc
    assert "solve linear equations" in doc

    assert meta["course_code"] == "MTH1W"
    assert meta["course_name"] == "Mathematics Grade 9"
    assert meta["strand"] == "Algebra"
    assert meta["expectation_raw"] == "solve linear equations"
    assert meta["tags"] == "math,algebra"

def test_extract_expectations_missing_id():
    curriculum_data = {
        "courses": {
            "ENG1D": {
                "name": "English Grade 9",
                "strands": {
                    "Reading": [
                        {
                            "expectation": "read short stories",
                            "tags": ["literacy"]
                        }
                    ]
                }
            }
        }
    }

    expectations = list(extract_expectations(curriculum_data))
    assert len(expectations) == 1

    doc, meta, exp_id = expectations[0]
    # Check that ID is generated using the course code and a hash
    assert exp_id.startswith("ENG1D-")
    assert meta["expectation_raw"] == "read short stories"

def test_extract_expectations_missing_tags():
    curriculum_data = {
        "courses": {
            "SNC1W": {
                "name": "Science Grade 9",
                "strands": {
                    "Biology": [
                        {
                            "id": "SNC1W-B1",
                            "expectation": "explain cellular processes"
                        }
                    ]
                }
            }
        }
    }

    expectations = list(extract_expectations(curriculum_data))
    assert len(expectations) == 1

    doc, meta, exp_id = expectations[0]
    assert meta["tags"] == ""

def test_extract_expectations_missing_course_name():
    curriculum_data = {
        "courses": {
            "UNKNOWN": {
                "strands": {
                    "Misc": [
                        {
                            "id": "U-1",
                            "expectation": "some expectation"
                        }
                    ]
                }
            }
        }
    }

    expectations = list(extract_expectations(curriculum_data))
    assert len(expectations) == 1

    doc, meta, exp_id = expectations[0]
    assert "Unknown Course" in doc
    assert meta["course_name"] == "Unknown Course"

def test_extract_expectations_empty_data():
    assert list(extract_expectations({})) == []
    assert list(extract_expectations({"courses": {}})) == []

def test_extract_expectations_multiple_courses_and_strands():
    curriculum_data = {
        "courses": {
            "C1": {
                "name": "Course 1",
                "strands": {
                    "S1": [{"expectation": "E1"}],
                    "S2": [{"expectation": "E2"}]
                }
            },
            "C2": {
                "name": "Course 2",
                "strands": {
                    "S3": [{"expectation": "E3"}]
                }
            }
        }
    }

    expectations = list(extract_expectations(curriculum_data))
    assert len(expectations) == 3

    doc_texts = [e[0] for e in expectations]
    assert any("E1" in t for t in doc_texts)
    assert any("E2" in t for t in doc_texts)
    assert any("E3" in t for t in doc_texts)
