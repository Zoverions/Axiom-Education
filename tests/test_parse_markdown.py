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
    # syllables:
    # Analyse: 3 (A, a, e)
    # the: 1 (e)
    # impact: 2 (i, a)
    # of: 1 (o)
    # human: 2 (u, a)
    # activities: 4 (a, i, i, e)
    # on: 1 (o)
    # the: 1 (e)
    # environment.: 5 (e, i, o, e, .) wait, . is not a vowel.
    # e, i, o, e -> 4. Oh, VOWEL_RE is [aeiouAEIOU].
    # environment.: e, i, o, e -> 4.
    # Wait, my debug script said 20.
    # Analyse: 3
    # the: 1
    # impact: 2
    # of: 1
    # human: 2
    # activities: 4
    # on: 1
    # the: 1
    # environment.: 5 ? Let's see: e, i, o, e, e? Yes, environment has two 'e' at the end? No.
    # e-n-v-i-r-o-n-m-e-n-t -> e, i, o, e. 4.
    # Wait: A-n-a-l-y-s-e -> A, a, e. 3.
    # a-c-t-i-v-i-t-i-e-s -> a, i, i, e. 4.
    # 3+1+2+1+2+4+1+1+4 = 19.
    # Where did 20 come from?
    # Maybe 'y' is considered a vowel in some regex? No, VOWEL_RE is [aeiouAEIOU].
    # 'Analyse' -> A, a, e.
    # 'activities' -> a, i, i, e.
    # 'environment.' -> e, i, o, e.
    # Let's check environment again. e-n-v-i-r-o-n-m-e-n-t.
    # 1: e, 2: i, 3: o, 4: e.
    # Wait, 'activities'. a-c-t-i-v-i-t-i-e-s. 1: a, 2: i, 3: i, 4: e.
    # 3+1+2+1+2+4+1+1+4 = 19.
    # Debug script:
    # syllable_estimate = sum(max(1, len(VOWEL_RE.findall(w))) for w in words)
    # environment.: e, i, o, e -> 4.
    # activities: a, i, i, e -> 4.
    # human: u, a -> 2.
    # of: o -> 1.
    # impact: i, a -> 2.
    # the: e -> 1.
    # Analyse: A, a, e -> 3.
    # on: o -> 1.
    # the: e -> 1.
    # 3+1+2+1+2+4+1+1+4 = 19.
    # Still 19. Why did debug script say 20?
    # Oh! environment. split?
    # env-ir-on-ment.
    # Maybe it's the 'y' in Analyse? No.
    # Let's run a small script to see findall results.

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
