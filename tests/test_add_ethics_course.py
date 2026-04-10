import json
from add_ethics_course import augment_ethics_course

def test_augment_ethics_course_success(tmp_path):
    # Setup: Create a temporary JSON file with some initial data
    test_file = tmp_path / "ontario_curriculum_full.json"
    initial_data = {"courses": {}}
    with open(test_file, 'w', encoding='utf-8') as f:
        json.dump(initial_data, f)

    # Action: Run the augmentation
    augment_ethics_course(str(test_file))

    # Verification: Check if the course was added correctly
    with open(test_file, 'r', encoding='utf-8') as f:
        updated_data = json.load(f)

    assert "EMF1O" in updated_data["courses"]
    course = updated_data["courses"]["EMF1O"]
    assert course["name"] == "Ethics, Moral Foundations, and the Evolution of Thought (Custom OS)"
    assert "A_Early_Spirituality" in course["strands"]
    assert "B_Evolution_of_Philosophy" in course["strands"]
    assert "C_Modern_Moral_Foundations" in course["strands"]

    # Check a specific expectation
    early_spirituality = course["strands"]["A_Early_Spirituality"]
    assert len(early_spirituality) == 2
    assert early_spirituality[0]["id"] == "EMF1O-A1"
    assert "cave paintings" in early_spirituality[0]["expectation"]

def test_augment_ethics_course_file_not_found(capsys):
    # Action: Try to run on a non-existent file
    augment_ethics_course("non_existent_file.json")

    # Verification: Check if it prints an error message
    captured = capsys.readouterr()
    assert "Error: non_existent_file.json not found." in captured.out
