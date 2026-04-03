import sqlite3
import pytest
from migrate_to_sqlite import setup_database, migrate_data
import json

def test_setup_database():
    # Use an in-memory database for testing
    conn, cursor = setup_database(':memory:')

    # Check if tables were created correctly
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
    tables = [row[0] for row in cursor.fetchall()]

    assert 'Course' in tables
    assert 'Strand' in tables
    assert 'Expectation' in tables
    assert 'Tag' in tables

    # Verify Course table schema
    cursor.execute("PRAGMA table_info(Course);")
    columns = {row[1]: row[2] for row in cursor.fetchall()}
    assert columns['id'] == 'TEXT'
    assert columns['name'] == 'TEXT'
    assert columns['official_url'] == 'TEXT'

    # Verify Strand table schema
    cursor.execute("PRAGMA table_info(Strand);")
    columns = {row[1]: row[2] for row in cursor.fetchall()}
    assert columns['id'] == 'TEXT'
    assert columns['course_id'] == 'TEXT'
    assert columns['name'] == 'TEXT'

    # Verify Expectation table schema
    cursor.execute("PRAGMA table_info(Expectation);")
    columns = {row[1]: row[2] for row in cursor.fetchall()}
    assert columns['id'] == 'TEXT'
    assert columns['course_id'] == 'TEXT'
    assert columns['strand_id'] == 'TEXT'
    assert columns['text'] == 'TEXT'
    assert columns['irt_b'] == 'REAL'
    assert columns['irt_a'] == 'REAL'
    assert columns['irt_c'] == 'REAL'

    # Verify Tag table schema
    cursor.execute("PRAGMA table_info(Tag);")
    columns = {row[1]: row[2] for row in cursor.fetchall()}
    assert columns['id'] == 'INTEGER'
    assert columns['expectation_id'] == 'TEXT'
    assert columns['tag'] == 'TEXT'

    conn.close()

def test_migrate_data(tmp_path):
    # Prepare dummy JSON data
    curriculum_data = {
        "courses": {
            "MATH101": {
                "name": "Intro to Math",
                "official_url": "http://math101.com",
                "strands": {
                    "Algebra": [
                        {
                            "id": "M101-A1",
                            "expectation": "Solve for x",
                            "irt_b": 1.0,
                            "irt_a": 1.5,
                            "irt_c": 0.2,
                            "tags": ["basic", "equations"]
                        }
                    ]
                }
            }
        }
    }

    json_path = tmp_path / "test_curriculum.json"
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(curriculum_data, f)

    db_path = tmp_path / "test_curriculum.sqlite"

    # Run migration
    migrate_data(str(db_path), str(json_path))

    # Verify migration results
    conn = sqlite3.connect(str(db_path))
    cursor = conn.cursor()

    cursor.execute("SELECT * FROM Course")
    courses = cursor.fetchall()
    assert len(courses) == 1
    assert courses[0] == ("MATH101", "Intro to Math", "http://math101.com")

    cursor.execute("SELECT * FROM Strand")
    strands = cursor.fetchall()
    assert len(strands) == 1
    assert strands[0] == ("MATH101_Algebra", "MATH101", "Algebra")

    cursor.execute("SELECT * FROM Expectation")
    expectations = cursor.fetchall()
    assert len(expectations) == 1
    assert expectations[0] == ("M101-A1", "MATH101", "MATH101_Algebra", "Solve for x", 1.0, 1.5, 0.2)

    cursor.execute("SELECT expectation_id, tag FROM Tag")
    tags = cursor.fetchall()
    assert len(tags) == 2
    assert ("M101-A1", "basic") in tags
    assert ("M101-A1", "equations") in tags

    conn.close()

def test_migrate_data_empty(tmp_path):
    json_path = tmp_path / "empty_curriculum.json"
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump({"courses": {}}, f)

    db_path = tmp_path / "empty_curriculum.sqlite"

    migrate_data(str(db_path), str(json_path))

    conn = sqlite3.connect(str(db_path))
    cursor = conn.cursor()

    for table in ['Course', 'Strand', 'Expectation', 'Tag']:
        cursor.execute(f"SELECT COUNT(*) FROM {table}")
        assert cursor.fetchone()[0] == 0

    conn.close()

def test_migrate_data_missing_optional_fields(tmp_path):
    # Test data missing official_url, tags, and IRT parameters
    curriculum_data = {
        "courses": {
            "SCI101": {
                "name": "Intro to Science",
                "strands": {
                    "Biology": [
                        {
                            "id": "S101-B1",
                            "expectation": "Cells exist"
                        }
                    ]
                }
            }
        }
    }

    json_path = tmp_path / "minimal_curriculum.json"
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(curriculum_data, f)

    db_path = tmp_path / "minimal_curriculum.sqlite"

    migrate_data(str(db_path), str(json_path))

    conn = sqlite3.connect(str(db_path))
    cursor = conn.cursor()

    cursor.execute("SELECT name, official_url FROM Course WHERE id='SCI101'")
    assert cursor.fetchone() == ("Intro to Science", "")

    cursor.execute("SELECT text, irt_b, irt_a, irt_c FROM Expectation WHERE id='S101-B1'")
    assert cursor.fetchone() == ("Cells exist", 0.0, 1.2, 0.2)

    cursor.execute("SELECT COUNT(*) FROM Tag")
    assert cursor.fetchone()[0] == 0

    conn.close()
