import json
import pytest
from parse_markdown import create_mock_irt, main

def test_main_function(tmp_path, capsys):
    temp_filepath = tmp_path / 'test_curriculum.json'

    # First run: should create file and add courses
    main(filepath=str(temp_filepath))

    # Verify file contents
    assert temp_filepath.exists()
    with open(temp_filepath, 'r', encoding='utf-8') as f:
        curriculum = json.load(f)

    assert "courses" in curriculum
    assert "CGC1W" in curriculum["courses"]
    assert "PPL1O" in curriculum["courses"]
    assert "strands" in curriculum["courses"]["CGC1W"]
    assert "A_Geographic_Inquiry" in curriculum["courses"]["CGC1W"]["strands"]
    assert len(curriculum["courses"]["CGC1W"]["strands"]["A_Geographic_Inquiry"]) > 0

    # Verify output
    captured = capsys.readouterr()
    assert "Adding course CGC1W..." in captured.out
    assert "Parsed new user data and appended to JSON successfully!" in captured.out

    # Second run: should not duplicate or print "Adding course..."
    main(filepath=str(temp_filepath))

    # Verify second output
    captured_second = capsys.readouterr()
    assert "Adding course CGC1W..." not in captured_second.out
    assert "Parsed new user data and appended to JSON successfully!" in captured_second.out

def test_create_mock_irt_grade_10():
    course_name = "Science, Grade 10, Academic"
    text = "Analyse the impact of human activities on the environment."
    result = create_mock_irt(course_name, text)

    # words = ['Analyse', 'the', 'impact', 'of', 'human', 'activities', 'on', 'the', 'environment.'] (9 words)
    # len: [7, 3, 6, 2, 5, 10, 2, 3, 12] (environment. has 12 chars)
    # total len = 50. avg = 50/9 = 5.5555...
    # syllables (estimated by VOWEL_RE = [aeiouAEIOU]):
    # Analyse: 3 (A, a, e)
    # the: 1 (e)
    # impact: 2 (i, a)
    # of: 1 (o)
    # human: 2 (u, a)
    # activities: 5 (a, i, i, i, e)
    # on: 1 (o)
    # the: 1 (e)
    # environment.: 4 (e, i, o, e)
    # Total syllables: 3+1+2+1+2+5+1+1+4 = 20

    assert result["irt_b"] == 0.78
    assert result["irt_a"] == 1.3
    assert result["tags"] == ["reading"]

def test_create_mock_irt_no_grade():
    course_name = "De-streamed Science"
    text = "Solve equations."
    result = create_mock_irt(course_name, text)
    assert result["irt_b"] == 0.83
    assert result["irt_a"] == 1.2
    assert "math" in result["tags"]

def test_create_mock_irt_tags():
    text = "Write a note about the EQAO provincial test and read the result to solve it."
    result = create_mock_irt("Course", text)
    assert "writing" in result["tags"]
    assert "stylus" in result["tags"]
    assert "reading" in result["tags"]
    assert "eqao" in result["tags"]
    assert "math" in result["tags"]

def test_create_mock_irt_syllables():
    result = create_mock_irt("Grade 10", "aeiou")
    assert result["irt_b"] == 1.25
