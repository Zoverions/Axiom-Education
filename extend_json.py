import json
import re
import os

GRADE_RE = re.compile(r'Grade\s+(\d+)')
VOWEL_RE = re.compile(r'[aeiouAEIOU]')

def load_json(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_json(data, filepath):
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

def create_mock_irt(course, strand, text):
    grade_match = GRADE_RE.search(course.get('name', ''))
    grade = int(grade_match.group(1)) if grade_match else 9

    words = text.split()
    avg_word_len = sum(len(w) for w in words) / max(len(words), 1)
    syllable_estimate = sum(max(1, len(VOWEL_RE.findall(w))) for w in words)
    complexity = (avg_word_len * 0.15 + syllable_estimate / max(len(words), 1) * 0.2)
    base_b = (grade - 9) * 0.5
    b = max(-3.0, min(3.0, base_b + complexity - 1.0))
    a = 1.2 + (0.1 if 'analyse' in text.lower() or 'evaluate' in text.lower() else 0.0)

    tags = []
    low = text.lower()
    if any(w in low for w in ['write', 'written', 'paragraph', 'essay']): tags.append('writing')
    if any(w in low for w in ['read', 'text', 'source', 'analyse']): tags.append('reading')
    if any(w in low for w in ['solve', 'calculate', 'equation', 'graph']): tags.append('math')
    if any(w in low for w in ['eqao', 'provincial', 'standardized']): tags.append('eqao')
    if any(w in low for w in ['write', 'note', 'diagram', 'label']): tags.append('stylus')

    return {
        "irt_b": round(b, 2),
        "irt_a": round(a, 2),
        "irt_c": 0.2,
        "tags": tags
    }

def process_course_data(course_id, name, url, raw_strands):
    course_data = {
        "name": name,
        "official_url": url,
        "strands": {}
    }

    for strand_name, expectations in raw_strands.items():
        strand_code = strand_name.split('_')[0]
        parsed_expectations = []

        for idx, text in enumerate(expectations, 1):
            exp_id = f"{course_id}-{strand_code}{idx}"
            irt_data = create_mock_irt(course_data, strand_name, text)

            parsed_expectations.append({
                "id": exp_id,
                "expectation": text,
                "irt_b": irt_data["irt_b"],
                "irt_a": irt_data["irt_a"],
                "irt_c": irt_data["irt_c"],
                "tags": irt_data["tags"]
            })

        if parsed_expectations:
            course_data["strands"][strand_name] = parsed_expectations

    return course_data

def extend_curriculum():
    filepath = 'assets/curriculum/ontario_curriculum_full.json'

    if os.path.exists(filepath):
        curriculum = load_json(filepath)
    else:
        curriculum = {
            "version": "4.3.0",
            "updated": "2026-03-05",
            "legal_note": "© King's Printer for Ontario – Supplementary use only. Official: dcp.edu.gov.on.ca",
            "courses": {}
        }

    # Add SNC1W
    if "SNC1W" not in curriculum["courses"]:
        curriculum["courses"]["SNC1W"] = process_course_data(
            "SNC1W",
            "Science, Grade 9 (De-streamed)",
            "https://www.dcp.edu.gov.on.ca/en/curriculum/science/grade9",
            {
                "A_STEM_Skills": [
                    "apply the scientific research process to investigate scientific questions and problems.",
                    "apply the scientific experimentation process to investigate scientific questions and problems.",
                    "apply the engineering design process to design, build, and test solutions to real-world problems.",
                    "apply coding skills to investigate and model scientific concepts, relationships, and processes.",
                    "demonstrate an understanding of safe practices, including WHMIS, when conducting investigations.",
                    "analyse applications of science and technology in various contexts and careers.",
                    "evaluate impacts of technological innovations (including AI) on society and the environment.",
                    "analyse contributions to science from diverse communities, including First Nations, Métis, and Inuit knowledge systems."
                ],
                "B_Biology": [
                    "assess the impacts of climate change on ecosystem sustainability and evaluate initiatives to address them.",
                    "analyse the impacts of climate change on Canadian communities, including First Nations, Métis, and Inuit.",
                    "describe sustainable practices used by Indigenous communities.",
                    "explain the interactions among the biosphere, hydrosphere, lithosphere, and atmosphere.",
                    "describe the cycling of matter and the flow of energy through ecosystems.",
                    "explain the processes of photosynthesis and cellular respiration.",
                    "explain concepts of biodiversity, ecological succession, and bioindicators.",
                    "analyse the effects of human activities on ecosystems.",
                    "explain indicators of climate change and the role of human activities.",
                    "describe sustainable practices in agriculture and resource management."
                ],
                "C_Chemistry": [
                    "assess social, environmental, and economic impacts of processes associated with the life cycle of consumer products.",
                    "analyse impacts of using emerging chemical technologies in various fields.",
                    "investigate properties, changes, and interactions of matter important for dynamic equilibrium.",
                    "research the role of experimental evidence in the development of atomic models.",
                    "identify the location, relative mass, and charge of subatomic particles using the Bohr-Rutherford model.",
                    "explain the relationship between the position of an element in the periodic table and atomic structure.",
                    "investigate physical and chemical properties of elements to relate to the periodic table.",
                    "investigate and describe physical and chemical properties of elements and compounds.",
                    "describe the relationship between the structure of simple compounds and their chemical formulas."
                ],
                "D_Physics": [
                    "assess social, environmental, and economic benefits and challenges resulting from electrical energy production.",
                    "evaluate how electrical energy production impacts communities and describe sustainable practices.",
                    "develop a plan of action to address a local or global electrical energy issue.",
                    "analyse impacts of emerging technologies related to electrical energy.",
                    "conduct investigations to explain the behaviour of electric charges.",
                    "determine the conductivity of various materials.",
                    "identify components of a direct current (DC) circuit and explain their functions.",
                    "investigate relationships between current, potential difference, and resistance.",
                    "apply a mathematical model to calculate electric current, potential difference, and resistance.",
                    "construct series and parallel circuits to compare current, potential difference, and resistance.",
                    "explain the difference between electricity and electrical energy.",
                    "determine the efficiency of various electrical devices."
                ],
                "E_Earth_Space": [
                    "evaluate social, environmental, and economic impacts of space observation and exploration.",
                    "evaluate how space technologies contribute to understanding climate change and phenomena.",
                    "assess ways technological innovations from space exploration are applied on Earth.",
                    "describe the importance of the Sun and its characteristics.",
                    "explain how the Sun's energy causes natural phenomena on Earth.",
                    "summarize observational evidence used to support theories about the origin of the universe.",
                    "describe major components of the solar system and the universe.",
                    "quantify distances in the solar system using relative distances and appropriate units.",
                    "conduct investigations to explain causes of astronomical phenomena observed from Earth."
                ]
            }
        )

    # Add ENL1W
    if "ENL1W" not in curriculum["courses"]:
        curriculum["courses"]["ENL1W"] = process_course_data(
            "ENL1W",
            "English, Grade 9 (De-streamed)",
            "https://www.dcp.edu.gov.on.ca/en/curriculum/english/grade9",
            {
                "A_Literacy_Connections": [
                    "identify and describe transferable skills that support literacy development.",
                    "explain how transferable skills are applied in various contexts.",
                    "reflect on their own development of transferable skills.",
                    "analyse the impact of digital media on literacy and society.",
                    "create and interpret digital texts using appropriate tools.",
                    "evaluate the credibility and bias of digital sources.",
                    "analyse how literacy skills support participation in diverse communities.",
                    "make connections between literacy and contributions from First Nations, Métis, and Inuit.",
                    "explore career pathways requiring strong literacy skills."
                ],
                "B_Foundations": [
                    "use appropriate tone, volume, and pace in oral communication.",
                    "demonstrate active listening and provide constructive feedback.",
                    "identify and use roots, prefixes, and suffixes.",
                    "analyse sentence structures and their effects on meaning.",
                    "apply knowledge of morphology and syntax.",
                    "apply spelling, grammar, and punctuation conventions.",
                    "use the conventions continuum to edit and revise work.",
                    "expand vocabulary through reading and word study."
                ],
                "C_Comprehension": [
                    "read and comprehend various complex texts using foundational knowledge.",
                    "analyze and compare the characteristics of various text forms and genres.",
                    "compare text patterns and features associated with different text forms.",
                    "evaluate how images and visual design contribute to meaning.",
                    "identify various elements of style and analyze how they create meaning.",
                    "analyze the narrator's point of view in texts.",
                    "read and view text forms by First Nations, Métis, and Inuit creators.",
                    "identify prior knowledge to make connections and understand texts.",
                    "identify purposes for engaging with texts and select appropriate texts.",
                    "make predictions, pose questions, and revise understanding.",
                    "select suitable strategies to monitor understanding of complex texts.",
                    "connect, compare, and contrast ideas in texts to lived experiences.",
                    "summarize and synthesize important ideas and draw conclusions.",
                    "explain how strategies helped comprehend texts and set goals.",
                    "analyze literary devices and explain how they create meaning.",
                    "make local and global inferences using explicit and implicit evidence.",
                    "analyze complex texts by assessing credibility and significance.",
                    "analyze cultural elements represented in texts.",
                    "analyze explicit and implicit perspectives and evaluate bias.",
                    "explain how topics like diversity are addressed in texts.",
                    "compare how socio-political conditions influence texts by Indigenous creators.",
                    "assess the effectiveness of critical thinking skills used."
                ],
                "D_Composition": [
                    "identify topic, purpose, and audience; choose a text form and medium.",
                    "generate and develop ideas and details about complex topics.",
                    "gather and synthesize information; evaluate quality and cite sources.",
                    "classify and sequence ideas and organize relevant content.",
                    "evaluate strategies used to develop ideas and suggest future steps."
                ]
            }
        )

    # Add CHV2O
    if "CHV2O" not in curriculum["courses"]:
        curriculum["courses"]["CHV2O"] = process_course_data(
            "CHV2O",
            "Civics and Citizenship, Grade 10 (Open, 0.5 credit)",
            "https://www.dcp.edu.gov.on.ca/en/curriculum/canadian-world-studies/grade10",
            {
                "A_Political_Inquiry": [
                    "formulate different types of questions to guide investigations into issues of civic importance.",
                    "select and organize relevant data and information on civic issues from a variety of sources.",
                    "assess the credibility of sources relevant to their investigations.",
                    "interpret and analyse data and information relevant to their investigations.",
                    "use the concepts of political thinking when interpreting and analysing evidence.",
                    "communicate their ideas, arguments, and conclusions using appropriate formats.",
                    "describe ways in which political inquiry can help develop transferable skills.",
                    "identify some careers in which a background in civics and citizenship might be an asset."
                ],
                "B_Civic_Issues": [
                    "analyse the significance of various civic issues of local, national, and global significance.",
                    "assess the role of citizens, governments, and other stakeholders in addressing issues.",
                    "analyse the impact of various civic issues on different groups in Canada.",
                    "explain the importance of democratic values and principles in a democratic society.",
                    "describe ways in which democratic values and principles are reflected in Canadian society.",
                    "analyse challenges to democratic values and principles in Canada and elsewhere."
                ],
                "C_Rights_Responsibilities": [
                    "describe the rights and responsibilities of citizens in a democratic society.",
                    "analyse the relationship between rights and responsibilities.",
                    "assess the impact of various rights and responsibilities on individuals and society.",
                    "explain the purpose and key provisions of the Canadian Charter of Rights and Freedoms.",
                    "analyse the role of the Charter in protecting citizens’ rights.",
                    "describe ways in which the Charter has been used to address issues of civic importance."
                ],
                "D_Civic_Action": [
                    "explain the importance of civic action in addressing issues of civic importance.",
                    "describe various forms of civic action.",
                    "assess the effectiveness of various forms of civic action.",
                    "plan and take action to address an issue of civic importance.",
                    "reflect on the process of planning and taking civic action."
                ]
            }
        )

    # Add BEM1O
    if "BEM1O" not in curriculum["courses"]:
        curriculum["courses"]["BEM1O"] = process_course_data(
            "BEM1O",
            "Building the Entrepreneurial Mindset, Grade 9 (Open)",
            "https://www.dcp.edu.gov.on.ca/en/curriculum/business-studies/grade9",
            {
                "A_Business_Leadership": [
                    "compare various business leadership styles and explain their appropriateness.",
                    "use a project management process to manage the main aspects of a business project.",
                    "evaluate tasks and projects on a regular basis in terms of goals and outcomes.",
                    "identify existing and emerging digital technologies to support business tasks.",
                    "analyze benefits, costs, and risks associated with various digital technologies.",
                    "select and use the most appropriate digital technologies to complete business tasks.",
                    "describe ways problem solving and critical thinking can address challenges.",
                    "analyze how business skills and knowledge can support learning in other areas.",
                    "describe how learning in this course can be applied in a variety of careers.",
                    "create and maintain a portfolio that illustrates business competencies.",
                    "describe ways entrepreneurial ventures have addressed social and ethical issues.",
                    "describe the contributions of successful entrepreneurs from diverse communities.",
                    "analyze challenges faced by entrepreneurs and identify supports."
                ],
                "B_Entrepreneurial_Mindset": [
                    "identify and describe what constitutes an entrepreneurial mindset.",
                    "describe how experiences of entrepreneurs led them to innovate.",
                    "assess their own entrepreneurial potential and develop a growth plan.",
                    "describe different business ownership structures.",
                    "generate new ideas for a new product or service that meets a market need.",
                    "develop criteria to evaluate ideas they could pursue as a venture.",
                    "select and describe an idea that addresses a market need.",
                    "create a prototype to illustrate a product's intended purpose and benefits.",
                    "analyze the social, economic, and ethical impacts of their venture idea.",
                    "produce a simple budget to assess the financial outlook for their venture.",
                    "use a problem solving process to refine their idea and prototype.",
                    "identify and compare various supports and funding opportunities for entrepreneurs.",
                    "demonstrate an understanding of the elements of a pitch presentation.",
                    "present their final pitch, gather feedback, and identify next steps."
                ],
                "C_Business_Communications": [
                    "identify topic, purpose, and audience for business texts and choose a form.",
                    "research, synthesize, and organize information to support business texts.",
                    "draft business texts using clear language, terminology, and text forms.",
                    "select appropriate fonts, colours, and visual elements to enhance design.",
                    "revise draft business texts to improve clarity, accuracy, and effectiveness.",
                    "publish final business texts using appropriate digital tools.",
                    "present final business texts using digital and oral presentation tools."
                ]
            }
        )

    save_json(curriculum, filepath)
    print(f"Curriculum extended and saved to {filepath}.")

if __name__ == "__main__":
    extend_curriculum()
