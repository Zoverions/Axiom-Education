import pytest
from parse_markdown import create_mock_irt

def test_create_mock_irt_grade_10():
    course_name = "Science, Grade 10, Academic"
    text = "Analyse the impact of human activities on the environment."
    result = create_mock_irt(course_name, text)

    # Calculation breakdown:
    # words = ['Analyse', 'the', 'impact', 'of', 'human', 'activities', 'on', 'the', 'environment.'] (9 words)
    # lengths: [7, 3, 6, 2, 5, 10, 2, 3, 12] -> total = 50. avg_word_len = 50/9 = 5.555...
    # syllables (vowels):
    # - Analyse: 3 (A, a, e)
    # - the: 1 (e)
    # - impact: 2 (i, a)
    # - of: 1 (o)
    # - human: 2 (u, a)
    # - activities: 5 (a, i, i, i, e)
    # - on: 1 (o)
    # - the: 1 (e)
    # - environment.: 4 (e, i, o, e)
    # Total syllable_estimate = 3+1+2+1+2+5+1+1+4 = 20.
    # complexity = (5.555... * 0.15 + 20 / 9 * 0.2) = (0.8333... + 0.4444...) = 1.2777...
    # base_b = (10 - 9) * 0.5 = 0.5
    # b = 0.5 + 1.2777... - 1.0 = 0.7777... -> rounded to 0.78

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
