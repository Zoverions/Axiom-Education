#!/usr/bin/env python3
"""
OntarioEdAI Curriculum Compiler — v4.3
Extracts expectations from Ministry of Ontario PDF files using pdfplumber.
Run once: python compile_curriculum.py --pdf_dir ./pdfs --out ./assets/curriculum/ontario_curriculum_full.json

Requirements: pip install pdfplumber regex
"""
import json, re, argparse
from pathlib import Path
from datetime import date
import pdfplumber

# ── Course metadata (Ministry course codes → subject/grade/URL) ──────────────
COURSE_META = {
    "MTH1W": {"subject": "mathematics", "grade": 9, "url_path": "mathematics/grade9"},
    "MFM2P": {"subject": "mathematics", "grade": 10, "url_path": "mathematics/grade10"},
    "MCR3U": {"subject": "mathematics", "grade": 11, "url_path": "mathematics/grade11"},
    "MHF4U": {"subject": "mathematics", "grade": 12, "url_path": "mathematics/grade12"},
    "ENL1W": {"subject": "english", "grade": 9, "url_path": "english/grade9"},
    "ENG2D": {"subject": "english", "grade": 10, "url_path": "english/grade10"},
    "ENG3U": {"subject": "english", "grade": 11, "url_path": "english/grade11"},
    "ENG4U": {"subject": "english", "grade": 12, "url_path": "english/grade12"},
    "SNC1W": {"subject": "science", "grade": 9, "url_path": "science/grade9"},
    "SNC2D": {"subject": "science", "grade": 10, "url_path": "science/grade10"},
    "CGC1W": {"subject": "geography", "grade": 9, "url_path": "canadian-world-studies/grade9"},
    "CHC2D": {"subject": "history", "grade": 10, "url_path": "canadian-world-studies/grade10"},
    "CHV2O": {"subject": "civics", "grade": 10, "url_path": "canadian-world-studies/grade10"},
    "BEM1O": {"subject": "business", "grade": 9, "url_path": "business-studies/grade9"},
    "GLC2O": {"subject": "careers", "grade": 10, "url_path": "guidance-and-career-education"},
    "GLS1O": {"subject": "learning_strategies", "grade": 9, "url_path": "guidance-and-career-education"},
    "ICS3U": {"subject": "computer_science", "grade": 11, "url_path": "computer-studies/grade11"},
    "ICS4U": {"subject": "computer_science", "grade": 12, "url_path": "computer-studies/grade12"},
}

# ── IRT difficulty heuristics (calibrated from pilot data) ───────────────────
VOWEL_PATTERN = re.compile(r'[aeiouAEIOU]')

def estimate_irt(text: str, grade: int) -> dict:
    """Heuristic IRT calibration from text complexity + grade level."""
    words = text.split()
    avg_word_len = sum(len(w) for w in words) / max(len(words), 1)
    syllable_estimate = sum(max(1, len(VOWEL_PATTERN.findall(w))) for w in words)
    complexity = (avg_word_len * 0.15 + syllable_estimate / max(len(words), 1) * 0.2)
    base_b = (grade - 9) * 0.5  # Grade 9 → 0, Grade 12 → 1.5
    b = (base_b + complexity - 1.0).clip(-3.0, 3.0) if hasattr(base_b, 'clip') else max(-3.0, min(3.0, base_b + complexity - 1.0))
    a = 1.2 + (0.1 if 'analyse' in text.lower() or 'evaluate' in text.lower() else 0.0)
    return {"irt_b": round(b, 2), "irt_a": round(a, 2), "irt_c": 0.2}

def extract_tags(text: str) -> list:
    tags = []
    low = text.lower()
    if 'write' in low or 'written' in low or 'paragraph' in low or 'essay' in low:
        tags.append('writing')
    if 'read' in low or 'text' in low or 'source' in low or 'analyse' in low:
        tags.append('reading')
    if 'solve' in low or 'calculate' in low or 'equation' in low or 'graph' in low:
        tags.append('math')
    if 'eqao' in low or 'provincial' in low or 'standardized' in low:
        tags.append('eqao')
    if 'write' in low or 'note' in low or 'diagram' in low or 'label' in low:
        tags.append('stylus')
    return tags

# ── Strand pattern: "A. Strand Title" or "Strand A:" ─────────────────────────
STRAND_PATTERN = re.compile(
    r'^(?:Strand\s)?([A-F])[.:]\s+(.+)$', re.MULTILINE)

# ── Expectation pattern: "A1." or "A1.1" with leading text ───────────────────
EXPECTATION_PATTERN = re.compile(
    r'\b([A-F]\d+(?:\.\d+)?)\s*[–\-:\.]\s*(.{20,300}?)(?=\n[A-F]\d+|$)',
    re.DOTALL)

def extract_course(pdf_path: Path, course_code: str) -> dict:
    meta = COURSE_META.get(course_code, {})
    grade = meta.get("grade", 9)
    url_path = meta.get("url_path", "")
    strands: dict = {}
    current_strand = "General"
    exp_counter: dict = {}

    with pdfplumber.open(str(pdf_path)) as pdf:
        full_text = "\n".join(
            page.extract_text() or "" for page in pdf.pages
        )

    # Find strand headers
    for m in STRAND_PATTERN.finditer(full_text):
        strand_key = f"{m.group(1)}_{m.group(2).strip().replace(' ', '_')}"
        strands[strand_key] = []

    # Fallback if no strands found
    if not strands:
        strands["A_General"] = []

    # Extract expectations
    for m in EXPECTATION_PATTERN.finditer(full_text):
        code = m.group(1)
        letter = code[0]
        text = " ".join(m.group(2).split())  # normalise whitespace

        # Find matching strand
        strand_key = next(
            (k for k in strands if k.startswith(f"{letter}_")),
            list(strands.keys())[0]
        )

        # Build unique ID
        exp_counter[strand_key] = exp_counter.get(strand_key, 0) + 1
        item_id = f"{course_code}-{code}"

        irt = estimate_irt(text, grade)
        tags = extract_tags(text)

        strands[strand_key].append({
            "id": item_id,
            "expectation": text[:300],  # cap at 300 chars — supplementary use
            **irt,
            "tags": tags,
        })

    return {
        "name": pdf_path.stem.replace("_", " ").title(),
        "official_url": f"https://www.dcp.edu.gov.on.ca/en/curriculum/{url_path}",
        "source_pdf": pdf_path.name,
        "grade": grade,
        "strands": {k: v for k, v in strands.items() if v},  # drop empty strands
    }

def main():
    parser = argparse.ArgumentParser(description="Compile Ontario Curriculum JSON")
    parser.add_argument("--pdf_dir", default=".", help="Folder containing Ministry PDFs")
    parser.add_argument("--out", default="assets/curriculum/ontario_curriculum_full.json")
    args = parser.parse_args()

    pdf_dir = Path(args.pdf_dir)
    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    curriculum = {
        "version": "4.3.0",
        "compiled": str(date.today()),
        "legal_note": "© King's Printer for Ontario – Supplementary use only. Official: dcp.edu.gov.on.ca",
        "courses": {}
    }

    pdf_files = list(pdf_dir.glob("*.pdf"))
    if not pdf_files:
        print("⚠️  No PDFs found. Place Ministry PDFs in the folder and retry.")
        return

    for pdf_file in sorted(pdf_files):
        # Infer course code from filename (e.g. MTH1W_Grade9_Math.pdf → MTH1W)
        code = pdf_file.stem.split("_")[0].upper()
        if code not in COURSE_META:
            print(f"⚠️  Skipping {pdf_file.name} — course code '{code}' not in COURSE_META")
            continue
        print(f"Processing {pdf_file.name}...")
        try:
            curriculum["courses"][code] = extract_course(pdf_file, code)
            count = sum(len(s) for s in curriculum["courses"][code]["strands"].values())
            print(f"  ✅ {code}: {count} expectations extracted")
        except Exception as e:
            print(f"  ❌ {code}: {e}")

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(curriculum, f, indent=2, ensure_ascii=False)

    total = sum(
        sum(len(s) for s in c["strands"].values())
        for c in curriculum["courses"].values()
    )
    print(f"\n✅ Done. {len(curriculum['courses'])} courses, {total} expectations → {out_path}")

if __name__ == "__main__":
    main()
