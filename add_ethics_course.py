import json

def augment_ethics_course():
    filepath = 'assets/curriculum/ontario_curriculum_full.json'

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            curriculum = json.load(f)
    except FileNotFoundError:
        print(f"Error: {filepath} not found.")
        return

    # Custom Course: Ethics, Moral Foundations, and the Evolution of Thought
    course_code = "EMF1O"

    custom_course = {
        "name": "Ethics, Moral Foundations, and the Evolution of Thought (Custom OS)",
        "description": "An open-source, custom module tracing the evolution of human spirituality, moral reasoning, and philosophical thought from early ancestors to modern ethical dilemmas.",
        "official_url": "https://opensource.education/ethics-evolution",
        "strands": {
            "A_Early_Spirituality": [
                {
                    "id": f"{course_code}-A1",
                    "expectation": "Analyse early human attempts to understand existence and the natural world, including the significance of cave paintings, animism, and early spiritual artifacts.",
                    "irt_b": 0.0,
                    "irt_a": 1.2,
                    "irt_c": 0.2,
                    "tags": ["history", "spirituality", "anthropology", "reading"]
                },
                {
                    "id": f"{course_code}-A2",
                    "expectation": "Examine how early spiritual beliefs fostered community cohesion, moral codes, and survival strategies among hunter-gatherer societies.",
                    "irt_b": 0.2,
                    "irt_a": 1.1,
                    "irt_c": 0.2,
                    "tags": ["sociology", "ethics", "writing"]
                }
            ],
            "B_Evolution_of_Philosophy": [
                {
                    "id": f"{course_code}-B1",
                    "expectation": "Trace the transition from mythos (mythological storytelling) to logos (rational/logical discourse) in early civilizations.",
                    "irt_b": 0.5,
                    "irt_a": 1.3,
                    "irt_c": 0.2,
                    "tags": ["philosophy", "history", "reading"]
                },
                {
                    "id": f"{course_code}-B2",
                    "expectation": "Compare foundational moral frameworks from diverse global traditions (e.g., Indigenous knowledge systems, Eastern philosophies, Western classical antiquity).",
                    "irt_b": 0.8,
                    "irt_a": 1.4,
                    "irt_c": 0.2,
                    "tags": ["philosophy", "comparative", "writing"]
                }
            ],
            "C_Modern_Moral_Foundations": [
                {
                    "id": f"{course_code}-C1",
                    "expectation": "Evaluate contemporary ethical dilemmas (e.g., artificial intelligence, bioethics, environmental justice) using established moral frameworks like utilitarianism, deontology, and virtue ethics.",
                    "irt_b": 1.2,
                    "irt_a": 1.5,
                    "irt_c": 0.2,
                    "tags": ["ethics", "technology", "critical_thinking", "writing"]
                },
                {
                    "id": f"{course_code}-C2",
                    "expectation": "Reflect on personal moral development, emphasizing the freedom to choose and align with belief systems and methodologies that best suit individual mentalities and learning styles.",
                    "irt_b": -0.5,
                    "irt_a": 1.0,
                    "irt_c": 0.2,
                    "tags": ["sel", "reflection", "metacognition", "stylus"]
                }
            ]
        }
    }

    curriculum["courses"][course_code] = custom_course

    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(curriculum, f, indent=2, ensure_ascii=False)

    print(f"Successfully added {course_code} to {filepath}.")

if __name__ == "__main__":
    augment_ethics_course()
