import sys
from unittest.mock import MagicMock

# Mock pdfplumber and regex since they are not installed and we can't install them
sys.modules["pdfplumber"] = MagicMock()
sys.modules["regex"] = MagicMock()

import pytest
from compile_curriculum import extract_tags, estimate_irt

def test_extract_tags_empty():
    assert extract_tags("") == []
    assert extract_tags("abc def") == []

def test_extract_tags_writing():
    assert "writing" in extract_tags("write a paragraph")
    assert "writing" in extract_tags("written essay")
    assert "writing" in extract_tags("paragraph analysis")
    assert "writing" in extract_tags("essay writing")

def test_extract_tags_reading():
    assert "reading" in extract_tags("read the text")
    assert "reading" in extract_tags("source material")
    assert "reading" in extract_tags("analyse the document")

def test_extract_tags_math():
    assert "math" in extract_tags("solve the equation")
    assert "math" in extract_tags("calculate the value")
    assert "math" in extract_tags("graph the function")

def test_extract_tags_eqao():
    assert "eqao" in extract_tags("eqao preparation")
    assert "eqao" in extract_tags("provincial testing")
    assert "eqao" in extract_tags("standardized assessment")

def test_extract_tags_stylus():
    assert "stylus" in extract_tags("write a note")
    assert "stylus" in extract_tags("draw a diagram")
    assert "stylus" in extract_tags("label the parts")

def test_extract_tags_multiple():
    tags = extract_tags("write a paragraph and solve an equation")
    assert "writing" in tags
    assert "math" in tags
    assert "stylus" in tags # 'write' also triggers stylus

def test_extract_tags_case_insensitivity():
    assert "writing" in extract_tags("WRITE")
    assert "math" in extract_tags("SoLvE")

def test_extract_tags_substring_match():
    # Current implementation uses 'w in low', which is a substring match
    assert "writing" in extract_tags("typewriter") # contains 'write'
    assert "reading" in extract_tags("treadmill") # contains 'read'

def test_estimate_irt_empty_text():
    # Handle division by zero via max(len(words), 1)
    result = estimate_irt("", 9)
    assert result["irt_c"] == 0.2
    assert result["irt_a"] == 1.2

def test_estimate_irt_grade_scaling():
    # base_b = (grade - 9) * 0.5
    # For grade 9, base_b = 0.0
    # For grade 12, base_b = 1.5
    res9 = estimate_irt("a simple text", 9)
    res12 = estimate_irt("a simple text", 12)
    assert res12["irt_b"] > res9["irt_b"]

def test_estimate_irt_keywords_a_bump():
    # a = 1.2 + (0.1 if 'analyse' in text.lower() or 'evaluate' in text.lower() else 0.0)
    normal_res = estimate_irt("read the book", 10)
    analyse_res = estimate_irt("analyse the book", 10)
    evaluate_res = estimate_irt("evaluate the result", 10)

    assert normal_res["irt_a"] == 1.2
    assert analyse_res["irt_a"] == 1.3
    assert evaluate_res["irt_a"] == 1.3

    # Check case-insensitivity
    analyse_upper_res = estimate_irt("ANALYSE the data", 10)
    assert analyse_upper_res["irt_a"] == 1.3

def test_estimate_irt_bounds():
    # b should be clipped between -3.0 and 3.0

    # Low bound: Very simple text, grade 9 (base_b = 0), complexity will be low.
    # b = (0 + complexity - 1.0)
    # Actually complexity > 0, so it might not reach -3.0, but let's test a very small complexity.
    # "a" has length 1, 1 vowel -> avg_word_len=1, syllable_estimate=1 -> complexity = 0.15 + 0.2 = 0.35
    # b = 0 + 0.35 - 1.0 = -0.65.

    # We can force a lower bound by using a very low grade
    res_low = estimate_irt("a", -10)
    assert res_low["irt_b"] == -3.0

    # High bound: Very complex text, grade 12 (base_b = 1.5)
    # Long words with many vowels.
    complex_text = "supercalifragilisticexpialidocious " * 50
    res_high = estimate_irt(complex_text, 12)
    # "supercalifragilisticexpialidocious" length=34. Vowels=16.
    # complexity = 34*0.15 + 16*0.2 = 5.1 + 3.2 = 8.3
    # base_b = 1.5
    # b = 1.5 + 8.3 - 1.0 = 8.8. Clipped to 3.0.
    assert res_high["irt_b"] == 3.0
