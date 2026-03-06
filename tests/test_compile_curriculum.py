import sys
from unittest.mock import MagicMock

# Mock pdfplumber and regex since they are not installed and we can't install them
sys.modules["pdfplumber"] = MagicMock()
sys.modules["regex"] = MagicMock()

import pytest
from compile_curriculum import extract_tags

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
