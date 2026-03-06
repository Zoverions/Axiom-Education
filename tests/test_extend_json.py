import json
import pytest
import os
from extend_json import load_json, save_json, create_mock_irt, process_course_data

def test_load_json(tmp_path):
    test_file = tmp_path / "test.json"
    data = {"key": "value", "unicode": "🌟"}
    with open(test_file, 'w', encoding='utf-8') as f:
        json.dump(data, f)

    loaded = load_json(str(test_file))
    assert loaded == data

def test_save_json(tmp_path):
    test_file = tmp_path / "test.json"
    data = {"key": "value", "unicode": "🌟"}

    save_json(data, str(test_file))

    assert test_file.exists()
    with open(test_file, 'r', encoding='utf-8') as f:
        loaded = json.load(f)
    assert loaded == data

def test_create_mock_irt_default_grade():
    course = {"name": "Science"}
    strand = "A_Stem"
    text = "simple text"

    result = create_mock_irt(course, strand, text)

    assert "irt_b" in result
    assert "irt_a" in result
    assert "irt_c" in result
    assert result["irt_c"] == 0.2
    assert "tags" in result
    assert isinstance(result["tags"], list)

def test_create_mock_irt_specific_grade():
    course = {"name": "Science Grade 11"}
    strand = "A_Stem"
    text = "simple text"

    result_g9 = create_mock_irt({"name": "Science Grade 9"}, strand, text)
    result_g11 = create_mock_irt(course, strand, text)

    assert result_g11["irt_b"] > result_g9["irt_b"]

def test_create_mock_irt_tags():
    course = {"name": "Science Grade 9"}
    strand = "A_Stem"
    text = "Write a paragraph to solve the equation and read the source material for EQAO."

    result = create_mock_irt(course, strand, text)
    tags = result["tags"]

    assert "writing" in tags
    assert "math" in tags
    assert "reading" in tags
    assert "eqao" in tags
    assert "stylus" in tags

def test_create_mock_irt_a_parameter():
    course = {"name": "Science Grade 9"}
    strand = "A_Stem"

    result1 = create_mock_irt(course, strand, "simple text")
    assert result1["irt_a"] == 1.2

    result2 = create_mock_irt(course, strand, "analyse this and evaluate that")
    assert result2["irt_a"] == 1.3

def test_create_mock_irt_bounds():
    course = {"name": "Science Grade 9"}
    strand = "A_Stem"
    text = ""

    result = create_mock_irt(course, strand, text)
    assert result["irt_b"] >= -3.0

    course_high = {"name": "Science Grade 12"}
    text_complex = "supercalifragilisticexpialidocious " * 100
    result_complex = create_mock_irt(course_high, strand, text_complex)
    assert result_complex["irt_b"] <= 3.0

def test_process_course_data():
    course_id = "SNC1W"
    name = "Science"
    url = "http://example.com"
    raw_strands = {
        "A_STEM_Skills": [
            "apply the scientific research process.",
            "evaluate impacts of technological innovations."
        ]
    }

    result = process_course_data(course_id, name, url, raw_strands)

    assert result["name"] == name
    assert result["official_url"] == url
    assert "A_STEM_Skills" in result["strands"]

    expectations = result["strands"]["A_STEM_Skills"]
    assert len(expectations) == 2

    assert expectations[0]["id"] == "SNC1W-A1"
    assert expectations[0]["expectation"] == "apply the scientific research process."
    assert "irt_a" in expectations[0]

    assert expectations[1]["id"] == "SNC1W-A2"
    assert expectations[1]["expectation"] == "evaluate impacts of technological innovations."

def test_process_course_data_empty_strands():
    result = process_course_data("ID", "Name", "URL", {})
    assert result["strands"] == {}

def test_process_course_data_empty_expectations():
    raw_strands = {
        "A_STEM": []
    }
    result = process_course_data("ID", "Name", "URL", raw_strands)
    assert "A_STEM" not in result["strands"]
