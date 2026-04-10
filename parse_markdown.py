import json
import re

GRADE_RE = re.compile(r'Grade\s+(\d+)')
VOWEL_RE = re.compile(r'[aeiouAEIOU]')
EXPECTATION_RE = re.compile(r'^([A-Z]\d\.\d+)\s*(.*)')

def create_mock_irt(course_name, text):
    grade_match = GRADE_RE.search(course_name)
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

def main(filepath='assets/curriculum/ontario_curriculum_full.json'):
    # Because there are so many courses, I'll extract from a hardcoded list of the user's schemas.
    # Since I don't have direct access to the entire prompt string directly in python,
    # I'll create a mapping based on the provided schemas from the instructions.

    new_courses_data = {
      "CGC1W": {
        "name": "Exploring Canadian Geography, Grade 9, De-streamed",
        "description": "This course explores relationships between people and natural/built environments in Canada using geographic inquiry, spatial skills, and concepts of geographic thinking.",
        "strands": {
          "A_Geographic_Inquiry": [
            "A1.1 formulate different types of questions to guide investigations into issues in Canadian geography",
            "A1.2 select and organize relevant data and information on geographic issues from a variety of primary and secondary sources",
            "A1.3 apply critical-thinking skills to assess the credibility and biases of relevant sources from a wide variety of media forms",
            "A1.4 use geospatial technologies to construct and analyze datasets, including digital maps, graphs, charts and images",
            "A1.5 use the concepts of geographic thinking when interpreting and analyzing evidence, data, and information",
            "A1.6 communicate their ideas, arguments, and conclusions using geographic and other terminology",
            "A2.1 describe some ways in which geographic investigation can help them develop skills",
            "A2.2 apply communication skills, showing consideration for diverse perspectives and experiences",
            "A2.3 apply the concepts of geographic thinking when analyzing current events involving geographic issues within Canada",
            "A2.4 identify some careers in which a geography background and related skills might be an asset"
          ],
          "B_Physical_Geography": [
            "B1.1 identify the characteristics of Canada’s landscapes and landforms",
            "B1.2 analyze how geological, hydrological, and climatic processes formed Canada’s landscape",
            "B1.3 analyze and describe patterns and trends in the frequency of physical processes",
            "B1.4 analyze patterns and trends related to various global physical systems",
            "B1.5 explain how various features of Canada’s unique physical geography can contribute to Canadian identity",
            "B2.1 analyze interrelationships between physical characteristics in specific regions of Canada and various human activities",
            "B2.2 explain how human activities can alter physical processes and affect natural events",
            "B2.3 analyze the risks that various physical processes present to communities in Canada",
            "B2.4 analyze environmental, economic, social, and/or political consequences for Canada of changes in Earth’s physical processes",
            "B2.5 analyze how various communities value Canada’s natural environment"
          ],
          "C_Managing_Canada_Resources": [
            "C1.1 describe the characteristics of various renewable, non-renewable, and flow resources that are found in Canada",
            "C1.2 explain how the spatial distribution of key natural resources is related to the physical geography of the country",
            "C1.3 analyze interrelationships between the location/accessibility and the mode of extraction/harvesting",
            "C1.4 identify knowledge-based industries, and other industries based on human capital",
            "C1.5 analyze the interrelationship between the main factors that determine the location of sites",
            "C1.6 assess the importance of different industries in the Canadian economy",
            "C1.7 identify some careers in Canadian industries, including the marine sector",
            "C1.8 explain forms of land tenure and ownership in Canada",
            "C2.1 analyze various innovative models of and approaches to sustainable development",
            "C2.2 analyze issues related to the sustainable development of various resources and industries",
            "C2.3 describe strategies that industries and governments have implemented to increase sustainability",
            "C2.4 analyze the influence of governments, industries, advocacy groups, local community organizations",
            "C2.5 analyze issues related to sustainability, with a focus on the resources extracted"
          ],
          "D_Changing_Populations": [
             "D1.1 analyze the major demographic characteristics of, and trends within, the population in Canada",
             "D1.2 analyze interrelationships between factors that contribute to quality of life",
             "D1.3 analyze trends in the migration of people within Canada and in immigration to Canada",
             "D1.4 describe patterns of population settlement in Canada",
             "D1.5 compare settlement and population characteristics of selected communities in Canada",
             "D2.1 analyze current economic, social, cultural, political, and environmental effects that changes in Canada’s population are having",
             "D2.2 evaluate various strategies used by governments and organizations to address the needs of Canada’s changing population",
             "D2.3 describe ways in which population growth and demographic shifts within communities in Canada can create opportunities",
             "D2.4 identify global population issues that are of concern to people living in Canada"
          ],
          "E_Liveable_Communities": [
             "E1.1 analyze the characteristics of different land uses in various communities in Canada",
             "E1.2 analyze the impact of the natural environment and physical processes on land use",
             "E1.3 analyze some ways in which economic, social, cultural, and political forces affect various communities",
             "E1.4 assess the impacts of urban sprawl, compact urban growth, and other types of urban growth",
             "E2.1 analyze issues related to the sustainability of Canada’s food system",
             "E2.2 analyze existing and proposed transportation systems, locally, provincially, nationally",
             "E2.3 analyze the effects of government policies and corporate and individual decisions on energy consumption",
             "E2.4 analyze issues related to the social, environmental, and economic sustainability of communities",
             "E2.5 analyze innovative methods and practices being applied in the planning of communities"
          ]
        }
      },
      "GLC2O": {
        "name": "Career Studies, Grade 10, Open",
        "description": "This course teaches students how to develop and achieve personal goals for future learning, work, and community involvement...",
        "strands": {
          "A_Skills_Strategies": [
            "A1.1 demonstrate an understanding of the importance of resilience and perseverance",
            "A1.2 identify a range of strategies to help manage stress as they navigate a healthy school/life/work balance",
            "A1.3 identify people, resources, and services in the school and the community that can provide support",
            "A2.1 apply various decision-making strategies as they set personal, social, educational, and career/life goals",
            "A2.2 reflect on and document the process of developing and revising goals"
          ],
          "B_Exploring_Work": [
             "B1.1 identify some recent and evolving technological, economic, and social trends that have influenced the world of work",
             "B1.2 explain how transferable skills are developed through school, extracurricular, and/or community experiences",
             "B1.3 reflect on how the transferable skills they have developed so far have aided them in their learning",
             "B2.1 investigate their own interests, values, skills, strengths, and areas that require further development",
             "B2.2 identify factors and conditions other than an individual’s strengths, interests, and needs that inform choices",
             "B2.3 explain how digital media use and a social media presence can influence their education",
             "B2.4 analyse the role of networking, including traditional and online social networking",
             "B3.1 use a research process to identify and compare a few postsecondary options",
             "B3.2 identify the pathways towards their preferred destinations"
          ],
          "C_Planning_Financial": [
             "C1.1 select and organize information related to the postsecondary options that best suit their specific interests",
             "C1.2 develop a plan that identifies steps and strategies for working towards their initial postsecondary goal(s)",
             "C1.3 use effective and appropriate forms, media, and styles to communicate their skills",
             "C1.4 create a variety of materials, such as a résumé, cover letter, portfolio, or presentation",
             "C2.1 describe fundamentals of financial responsibility",
             "C2.2 compare different forms of borrowing and identify some of the risks and benefits",
             "C2.3 identify key considerations related to preparing a personal budget"
          ]
        }
      },
      "BEP2O": {
        "name": "Launching and Leading a Business, Grade 10, Open",
        "description": "This course introduces students to the world of business and the concepts, strategies, and skills needed to launch and lead a business...",
        "strands": {
            "A_Business_Leadership": [
                "A1.1 compare various business leadership styles and explain why it might be appropriate to use a particular style",
                "A1.2 use a project management process to manage the main aspects of a business project",
                "A1.3 evaluate tasks and projects on a regular basis in terms of goals, key performance indicators, and outcomes",
                "A2.1 identify a variety of existing and emerging digital technologies, tools, and applications",
                "A2.2 analyse and compare the benefits, limitations, costs, and risks associated with various digital technologies",
                "A2.3 select and use the most appropriate digital technologies, tools, and applications to complete a variety of business-related tasks",
                "A3.1 describe ways in which problem solving and creative and critical thinking can be applied to address challenges",
                "A3.2 analyse and explain how business skills and knowledge, including financial literacy, can support learning",
                "A3.3 describe how their learning in this course can be applied in a variety of careers",
                "A3.4 create and maintain a portfolio that illustrates their business competencies",
                "A4.1 describe ways in which different entrepreneurial ventures have addressed social, economic, environmental issues",
                "A4.2 describe the contributions and impacts of successful entrepreneurs from diverse local communities",
                "A4.3 analyse challenges faced by entrepreneurs from various communities"
            ],
            "B_Economic_Foundations": [
                "B1.1 explain how market forces affect the supply, demand, and price of goods and services",
                "B1.2 describe how the needs and wants of consumers and the scarcity and choice of goods impact consumer behaviour",
                "B1.3 describe how various groups in Canada have been affected by current and past market forces",
                "B2.1 analyse how different competitive market structures affect business activities in Canada",
                "B2.2 describe how trade relationships Canada has with other countries have an impact on Canadian markets",
                "B2.3 explain how different levels of government in Canada may intervene to correct market failures",
                "B3.1 describe the different types of businesses in Canada and their role in economies",
                "B3.2 compare the actions taken and innovations made by various Canadian businesses to become socially responsible",
                "B3.3 analyse the ways in which various Canadian businesses are working with Indigenous entrepreneurs"
            ],
            "C_Entrepreneurship_Mindset": [
                "C1.1 describe what constitutes an entrepreneurial mindset, and how their own lived experiences can help",
                "C1.2 use a design process to identify how to meet a market need or opportunity",
                "C1.3 use a problem solving process to assess and refine their entrepreneurial idea and prototype",
                "C1.4 use a pitch process to effectively communicate their entrepreneurial idea to various audiences",
                "C2.1 identify key performance indicators for their venture to measure its progress",
                "C2.2 consider the target market and competition for their venture, and create a brand",
                "C2.3 identify the logistics, resources, and requirements needed for their entrepreneurial venture",
                "C2.4 calculate their venture’s start-up budget and conduct a break-even analysis",
                "C3.1 identify and compare various supports, including funding opportunities, available for entrepreneurs",
                "C3.2 launch an entrepreneurial venture and lead it towards achieving their identified goals",
                "C3.3 analyse ethical sales strategies and respectful, accessible customer service approaches"
            ],
            "D_Business_Functions": [
                "D1.1 describe the processes involved in the production of a product or the delivery of a service",
                "D1.2 examine and evaluate how various businesses have enhanced the efficiency, health and safety practices",
                "D1.3 outline a process for producing their product or delivering their service in an efficient way",
                "D2.1 analyse how various businesses have successfully used different marketing strategies",
                "D2.2 create a mission statement based on the unique selling proposition and brand values",
                "D2.3 explain how their venture is best suited for their target customer and distinguishes itself",
                "D2.4 describe the four Ps of marketing, including how they complement each other",
                "D3.1 explain the role and importance of both financial and management accounting for a business",
                "D3.2 demonstrate an understanding of tracking cash inflows and outflows for a small business",
                "D3.3 analyse basic financial statements for a small business to determine its financial position",
                "D3.4 demonstrate an understanding of the role and importance of non-financial reporting"
            ]
        }
      },
      "TAS2O": {
        "name": "Technology and the Skilled Trades, Grade 10, Open",
        "description": "This hands-on course enables students to apply the engineering design process...",
        "strands": {
            "A_Design_Processes": [
                "A1.1 apply an understanding of fundamental technological concepts, and evaluate their significance",
                "A1.2 apply an understanding of fundamental technological concepts, design considerations, and science",
                "A1.3 investigate design considerations, including accessibility requirements",
                "A1.4 communicate design ideas for various purposes and audiences",
                "A1.5 establish and justify evaluation criteria for products and/or services being developed",
                "A1.6 investigate and describe project management skills and approaches",
                "A1.7 collect and synthesize information from a variety of sources",
                "A2.1 use project management skills to develop a process to create a product",
                "A2.2 identify factors that could impact the development of their projects",
                "A2.3 select materials and other resources based on their properties or characteristics",
                "A2.4 select, use, and maintain tools and equipment appropriately",
                "A2.5 use a variety of industry-related documents to guide the creation of products",
                "A2.6 create products and/or deliver services, documenting their development process",
                "A2.7 select appropriate units of measure and tools to make accurate measurements",
                "A3.1 identify challenges they encounter in the process of developing their projects",
                "A3.2 identify various industry-relevant performance standards and quality control methods",
                "A3.3 analyze the performance of products and/or service delivery using quality control methods",
                "A3.4 refine the design of products and/or services based on an analysis of data",
                "A3.5 communicate project-related challenges, performance analyses, and refinements",
                "A4.1 describe relevant health and safety regulations for a variety of settings",
                "A4.2 identify hazards in their environment, and apply strategies to minimize risks",
                "A4.3 use tools and equipment safely, including using personal protective equipment",
                "A4.4 follow practices that support physical and mental health and well-being",
                "A4.5 follow proper procedures for the safe handling, storage, and disposal of materials",
                "A4.6 demonstrate a safety mindset by making safety a priority at all times"
            ],
            "B_Technological_Development": [
                "B1.1 assess interrelationships between user needs and the development of various technological solutions",
                "B1.2 analyze how the development and application of technologies are impacted by legal, ethical considerations",
                "B1.3 investigate and describe contributions to technological innovations made by Canadians",
                "B1.4 describe ways in which diverse communities have drawn on various knowledge systems",
                "B2.1 assess short-term and long-term impacts of various technological innovations on individuals and society",
                "B2.2 assess local and global impacts of various technological innovations on the environment",
                "B2.3 evaluate how positive and negative impacts of various technologies can influence technological evolution",
                "B3.1 explore a variety of roles, responsibilities, and opportunities related to current and emerging careers",
                "B3.2 research and identify programs related to pathways and careers in technological fields",
                "B3.3 compare a variety of pathways leading to careers in technological fields and the skilled trades",
                "B3.4 evaluate the transferable skills they are developing, identifying areas of strength and growth"
            ]
        }
      },
      "ICD2O": {
        "name": "Digital Technology and Innovations in the Changing World, Grade 10, Open",
        "description": "This course helps students develop cutting-edge digital technology and computer programming skills...",
        "strands": {
            "A_Computational_Thinking": [
                "A1.1 apply computational thinking concepts and practices when planning and designing computational artifacts",
                "A1.2 use a variety of tools and processes to plan, design, and share algorithms",
                "A1.3 develop computational artifacts for a variety of contexts and purposes that support diverse users",
                "A2.1 investigate current social, cultural, economic, environmental, and ethical issues related to digital technology",
                "A2.2 analyze personal and societal safety and cybersecurity issues related to digital technology",
                "A2.3 investigate contributions to innovations in digital technology and computing by people from diverse communities",
                "A2.4 investigate how to identify and address bias involving digital technology",
                "A2.5 analyze accessibility issues involving digital technology",
                "A3.1 investigate how digital technology and programming skills can be used within a variety of disciplines",
                "A3.2 investigate ways in which various industries are changing as a result of digital technology",
                "A3.3 investigate various career options related to digital technology and programming"
            ],
            "B_Hardware_Software": [
                "B1.1 describe the functions and features of various core components of hardware",
                "B1.2 describe the functions and features of various connected devices",
                "B1.3 describe the functions of various types of software",
                "B2.1 use file management techniques to organize, edit, and share files",
                "B2.2 identify and use effective research practices and supports when learning new hardware",
                "B2.3 assess the hardware and software requirements for various users, contexts, and purposes",
                "B3.1 apply safe and effective data practices when using digital technology",
                "B3.2 apply safe and effective security practices, including practices to protect their privacy",
                "B4.1 investigate current and emerging innovations in digital technology, including automation",
                "B4.2 analyze the impact of various technological innovations on everyday life"
            ],
            "C_Programming": [
                "C1.1 use appropriate terminology to describe programming concepts and algorithms",
                "C1.2 describe simple algorithms that are encountered in everyday situations",
                "C1.3 identify various types of data and explain how they are used within programs",
                "C1.4 determine the appropriate expressions and instructions to use in a programming statement",
                "C1.5 identify and explain situations in which conditional and repeating structures are required",
                "C2.1 use variables, constants, expressions, and assignment statements to store and manipulate numbers",
                "C2.2 write programs that use and generate data involving various sources and formats",
                "C2.3 write programs that include single and nested conditional statements",
                "C2.4 write programs that include sequential, selection, and repeating events",
                "C2.5 write programs that include the use of Boolean operators, comparison operators",
                "C2.6 interpret program errors and implement strategies to resolve them",
                "C2.7 write clear internal documentation and use coding standards to improve code readability",
                "C3.1 analyze existing code to understand the components and outcomes of the code",
                "C3.2 modify an existing program to enable it to complete a different task",
                "C3.3 write subprograms, and use existing subprograms, to complete program components",
                "C3.4 write programs that make use of external or add-on modules or libraries",
                "C3.5 explain the components of a computational artifact they have created"
            ]
        }
      },
      "ENG3U": {
          "name": "English, Grade 11, University Preparation",
          "description": "This course emphasizes the development of literacy, critical thinking, and communication skills.",
          "strands": {
              "A_Oral_Communication": [
                  "A1.1 identify the purpose of a variety of listening tasks and set goals for specific tasks",
                  "A1.2 select and use appropriate listening strategies to understand meaning",
                  "A1.3 identify and analyse the elements of effective oral communication",
                  "A2.1 identify the purpose and audience for a variety of speaking tasks and adapt",
                  "A2.2 use appropriate speaking techniques to communicate ideas effectively",
                  "A2.3 use appropriate organizational patterns and stylistic devices to suit purpose and audience",
                  "A3.1 explain which strategies they found most helpful before, during, and after listening and speaking",
                  "A3.2 identify their strengths and areas for improvement as listeners and speakers"
              ],
              "B_Reading_Literature": [
                  "B1.1 read a variety of complex texts with understanding",
                  "B1.2 identify and explain the effect of literary devices and techniques",
                  "B1.3 analyse the influence of cultural, historical, and social contexts on texts",
                  "B2.1 explain how form, structure, and style contribute to meaning",
                  "B2.2 analyse the use of rhetorical devices and persuasive techniques",
                  "B2.3 compare texts from different periods and cultures"
              ],
              "C_Writing": [
                  "C1.1 identify the purpose and audience for a variety of writing tasks",
                  "C1.2 use research and critical thinking to gather and organize ideas",
                  "C1.3 produce written work that demonstrates effective organization and coherence",
                  "C2.1 use appropriate literary and rhetorical devices",
                  "C2.2 adapt style and voice for purpose and audience",
                  "C3.1 apply spelling, grammar, and punctuation conventions",
                  "C3.2 use the conventions continuum (SCHhw) to edit and revise"
              ],
              "D_Media_Studies": [
                  "D1.1 interpret a variety of media texts",
                  "D1.2 identify and explain the purpose and audience for media texts",
                  "D2.1 analyse how media forms, conventions, and techniques influence meaning",
                  "D2.2 analyse bias, perspective, and stereotyping in media",
                  "D3.1 create media texts using appropriate forms and techniques",
                  "D3.2 use digital tools to enhance media production"
              ]
          }
      },
      "ENG4U": {
          "name": "English, Grade 12, University Preparation",
          "description": "This course emphasizes the consolidation of literacy, critical thinking, and communication skills.",
          "strands": {
              "A_Oral_Communication": [
                  "A1.1 identify the purpose of a variety of complex listening tasks and set goals",
                  "A1.2 use advanced listening strategies to analyse and evaluate meaning",
                  "A1.3 analyse the elements of effective academic and professional oral communication",
                  "A2.1 adapt speaking techniques for university-level and professional audiences",
                  "A2.2 use sophisticated organizational patterns and stylistic devices in presentations",
                  "A2.3 deliver oral presentations with confidence and coherence",
                  "A3.1 evaluate the effectiveness of listening and speaking strategies used",
                  "A3.2 set personal goals for continued improvement in academic oral communication"
              ],
              "B_Reading_Literature": [
                  "B1.1 read and interpret complex literary and informational texts with insight",
                  "B1.2 analyse how cultural, historical, and social contexts shape meaning in texts",
                  "B1.3 evaluate the influence of literary theories on interpretation",
                  "B2.1 analyse sophisticated literary devices, rhetorical strategies, and stylistic elements",
                  "B2.2 compare and contrast texts across periods, cultures, and genres",
                  "B2.3 explain how form and structure create meaning in challenging texts"
              ],
              "C_Writing": [
                  "C1.1 use scholarly research methods to gather and synthesize information",
                  "C1.2 produce coherent, well-organized academic essays and research papers",
                  "C2.1 write with an academic voice and sophisticated stylistic devices",
                  "C2.2 adapt style for university-level and professional audiences",
                  "C3.1 apply advanced grammar, punctuation, and citation conventions",
                  "C3.2 use the conventions continuum to edit and revise at a university-ready level"
              ],
              "D_Media_Studies": [
                  "D1.1 interpret and evaluate complex media texts with critical insight",
                  "D2.1 analyse media forms, conventions, and techniques in depth",
                  "D2.2 evaluate bias, ideology, and representation in media",
                  "D3.1 create advanced media texts using digital tools and professional techniques",
                  "D3.2 produce media that demonstrates academic rigour and ethical considerations"
              ]
          }
      },
      "BOH4M": {
          "name": "Business Leadership: Management Fundamentals, Grade 12",
          "description": "This course focuses on the development of leadership skills used in managing a successful business...",
          "strands": {
              "A_Foundations": [
                  "A1.1 explain the role of management in the operation of a business",
                  "A1.2 describe the functions of management",
                  "A1.3 analyse how the functions of management are interrelated",
                  "A2.1 explain the importance of ethical behaviour in business",
                  "A2.2 evaluate the impact of corporate social responsibility on a business",
                  "A3.1 describe the impact of business decisions on stakeholders",
                  "A3.2 analyse the economic impact of business activity on society"
              ],
              "B_Leading": [
                  "B1.1 explain the importance of effective leadership in achieving business goals",
                  "B1.2 compare various leadership styles and their effectiveness",
                  "B1.3 demonstrate the ability to apply leadership skills in group settings",
                  "B2.1 use effective communication skills in business contexts",
                  "B2.2 analyse the role of communication in motivating employees",
                  "B2.3 resolve conflict using appropriate strategies"
              ],
              "C_Management_Challenges": [
                  "C1.1 identify and analyse major challenges facing managers",
                  "C1.2 evaluate strategies for managing change effectively",
                  "C1.3 describe the impact of technology on management practices",
                  "C2.1 analyse the effects of workplace stress and conflict on productivity",
                  "C2.2 develop strategies for motivating employees and managing diversity",
                  "C2.3 assess the role of human resources management"
              ]
          }
      },
      "PPL1O": {
          "name": "Health and Physical Education, Grade 9, Open",
          "description": "This course equips students with the knowledge and skills they need to make healthy choices...",
          "strands": {
              "A_Active_Living": [
                  "A1.1 participate regularly in a wide variety of physical activities",
                  "A1.2 demonstrate an understanding of the factors that contribute to personal enjoyment of physical activity",
                  "A1.3 demonstrate an understanding of the factors that contribute to personal fitness levels",
                  "A2.1 explain the benefits of regular participation in physical activity",
                  "A2.2 describe the factors that contribute to the development of physical fitness",
                  "A3.1 demonstrate safe practices when participating in physical activities",
                  "A3.2 demonstrate an understanding of the importance of proper warm-up and cool-down"
              ],
              "B_Movement_Competence": [
                  "B1.1 demonstrate the ability to perform a variety of movement skills",
                  "B1.2 demonstrate an understanding of the principles of movement",
                  "B1.3 demonstrate the ability to use movement concepts to improve performance",
                  "B2.1 apply movement strategies in a variety of physical activities",
                  "B2.2 demonstrate an understanding of the factors that influence the choice of movement strategies"
              ],
              "C_Healthy_Living": [
                  "C1.1 identify factors that contribute to healthy development",
                  "C1.2 demonstrate an understanding of the impact of healthy choices on health",
                  "C2.1 make healthy choices related to nutrition, substance use, and sexual health",
                  "C2.2 demonstrate an understanding of the importance of mental health",
                  "C3.1 explain the connections between healthy living and overall well-being",
                  "C3.2 analyse how healthy living contributes to personal growth"
              ]
          }
      },
      "PPL2O": {
          "name": "Health and Physical Education, Grade 10, Open",
          "description": "This course enables students to further develop the knowledge and skills they need...",
          "strands": {
              "A_Active_Living": [
                  "A1.1 participate regularly in a wide variety of physical activities that develop health-related fitness",
                  "A1.2 demonstrate an understanding of how personal interests and preferences influence choices",
                  "A1.3 develop and implement a personal fitness plan",
                  "A2.1 explain the long-term benefits of regular physical activity for physical and mental health",
                  "A2.2 analyse factors that affect personal fitness levels and how to improve them",
                  "A3.1 demonstrate safe practices and proper etiquette in a variety of physical activities",
                  "A3.2 apply warm-up and cool-down routines effectively"
              ],
              "B_Movement_Competence": [
                  "B1.1 refine and combine movement skills in a variety of physical activities",
                  "B1.2 demonstrate an understanding of movement principles and how to apply them",
                  "B1.3 use movement concepts and strategies to enhance participation and performance",
                  "B2.1 apply tactical and strategic thinking in a variety of physical activities",
                  "B2.2 adapt movement strategies to different activity contexts"
              ],
              "C_Healthy_Living": [
                  "C1.1 analyse how healthy choices in nutrition, activity, and stress management affect health",
                  "C1.2 explain the impact of substance use and sexual health decisions on well-being",
                  "C2.1 apply decision-making skills to real-life health scenarios",
                  "C2.2 develop strategies for managing mental health and building resilience",
                  "C3.1 analyse the connections between healthy living and community well-being",
                  "C3.2 evaluate how personal choices influence lifelong health"
              ]
          }
      }
    }

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            curriculum = json.load(f)
    except Exception:
        curriculum = {"courses": {}}

    for code, data in new_courses_data.items():
        if code not in curriculum["courses"]:
            print(f"Adding course {code}...")
            course_entry = {
                "name": data["name"],
                "description": data["description"],
                "official_url": f"https://www.dcp.edu.gov.on.ca/en/curriculum/{code}",
                "strands": {}
            }

            for strand_name, texts in data["strands"].items():
                strand_code = strand_name.split('_')[0]
                expectations = []
                for text in texts:
                    # extract 'B1.1 ' prefix if exists, or generate a unique id
                    match = EXPECTATION_RE.match(text)
                    if match:
                        exp_id = f"{code}-{match.group(1)}"
                        exp_text = match.group(2)
                    else:
                        exp_id = f"{code}-{strand_code}-{hash(text) % 10000}"
                        exp_text = text

                    irt = create_mock_irt(data["name"], exp_text)
                    expectations.append({
                        "id": exp_id,
                        "expectation": exp_text,
                        "irt_b": irt["irt_b"],
                        "irt_a": irt["irt_a"],
                        "irt_c": irt["irt_c"],
                        "tags": irt["tags"]
                    })
                course_entry["strands"][strand_name] = expectations

            curriculum["courses"][code] = course_entry

    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(curriculum, f, indent=2, ensure_ascii=False)

    print("Parsed new user data and appended to JSON successfully!")

if __name__ == "__main__":
    main()
