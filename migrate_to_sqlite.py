import sqlite3
import json

def setup_database():
    conn = sqlite3.connect('assets/curriculum/ontario_curriculum.sqlite')
    cursor = conn.cursor()

    # Create tables
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS Course (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        official_url TEXT
    )
    ''')

    cursor.execute('''
    CREATE TABLE IF NOT EXISTS Strand (
        id TEXT PRIMARY KEY,
        course_id TEXT NOT NULL,
        name TEXT NOT NULL,
        FOREIGN KEY (course_id) REFERENCES Course (id)
    )
    ''')

    cursor.execute('''
    CREATE TABLE IF NOT EXISTS Expectation (
        id TEXT PRIMARY KEY,
        course_id TEXT NOT NULL,
        strand_id TEXT NOT NULL,
        text TEXT NOT NULL,
        irt_b REAL,
        irt_a REAL,
        irt_c REAL,
        FOREIGN KEY (course_id) REFERENCES Course (id),
        FOREIGN KEY (strand_id) REFERENCES Strand (id)
    )
    ''')

    cursor.execute('''
    CREATE TABLE IF NOT EXISTS Tag (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        expectation_id TEXT NOT NULL,
        tag TEXT NOT NULL,
        FOREIGN KEY (expectation_id) REFERENCES Expectation (id)
    )
    ''')

    conn.commit()
    return conn, cursor

def migrate_data():
    conn, cursor = setup_database()

    with open('assets/curriculum/ontario_curriculum_full.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    for course_code, course_info in data.get('courses', {}).items():
        # Insert Course
        cursor.execute(
            'INSERT OR REPLACE INTO Course (id, name, official_url) VALUES (?, ?, ?)',
            (course_code, course_info.get('name', ''), course_info.get('official_url', ''))
        )

        for strand_name, expectations in course_info.get('strands', {}).items():
            strand_id = f"{course_code}_{strand_name}"
            # Insert Strand
            cursor.execute(
                'INSERT OR REPLACE INTO Strand (id, course_id, name) VALUES (?, ?, ?)',
                (strand_id, course_code, strand_name)
            )

            for exp in expectations:
                exp_id = exp.get('id', '')
                # Insert Expectation
                cursor.execute(
                    '''INSERT OR REPLACE INTO Expectation
                       (id, course_id, strand_id, text, irt_b, irt_a, irt_c)
                       VALUES (?, ?, ?, ?, ?, ?, ?)''',
                    (exp_id, course_code, strand_id, exp.get('expectation', ''),
                     exp.get('irt_b', 0.0), exp.get('irt_a', 1.2), exp.get('irt_c', 0.2))
                )

                # Insert Tags
                for tag in exp.get('tags', []):
                    cursor.execute(
                        'INSERT INTO Tag (expectation_id, tag) VALUES (?, ?)',
                        (exp_id, tag)
                    )

    conn.commit()
    conn.close()
    print("Database migration complete. Data saved to 'assets/curriculum/ontario_curriculum.sqlite'.")

if __name__ == "__main__":
    migrate_data()
