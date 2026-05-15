import json
import itertools
import chromadb

def load_curriculum():
    filepath = 'assets/curriculum/ontario_curriculum_full.json'
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"Error: {filepath} not found.")
        return None

def extract_expectations(curriculum_data):
    courses = curriculum_data.get('courses', {})
    for course_code, course_info in courses.items():
        course_name = course_info.get('name', 'Unknown Course')
        course_prefix = f"Course: {course_name} ({course_code}). "
        strands = course_info.get('strands', {})

        for strand_name, expectations in strands.items():
            strand_prefix = f"{course_prefix}Strand: {strand_name}. Expectation: "
            for exp in expectations:
                text = exp.get('expectation', '')
                exp_id = exp.get('id', f"{course_code}-{hash(text)}")

                # The document to be embedded and searched
                document = strand_prefix + text

                metadata = {
                    "course_code": course_code,
                    "course_name": course_name,
                    "strand": strand_name,
                    "expectation_raw": text,
                    "tags": ",".join(exp.get('tags', []))
                }

                yield document, metadata, exp_id

def ingest_to_chroma(curriculum_data):
    print("Initializing ChromaDB...")
    # Initialize a local persistent Chroma client
    client = chromadb.PersistentClient(path="assets/curriculum/chroma_db")

    # Use a lightweight local embedding model
    sentence_transformer_ef = chromadb.utils.embedding_functions.SentenceTransformerEmbeddingFunction(model_name="all-MiniLM-L6-v2")

    # Create or get the collection
    collection_name = "ontario_curriculum"
    collection = client.get_or_create_collection(
        name=collection_name,
        embedding_function=sentence_transformer_ef
    )

    print("Processing and ingesting curriculum data into ChromaDB...")

    # Batch ingest to avoid memory issues with huge datasets
    batch_size = 500
    total_ingested = 0

    iterator = extract_expectations(curriculum_data)
    while True:
        batch = list(itertools.islice(iterator, batch_size))
        if not batch:
            break

        batch_docs, batch_metas, batch_ids = zip(*batch)

        # Convert tuples to lists as required by ChromaDB
        docs_list = list(batch_docs)
        metas_list = list(batch_metas)
        ids_list = list(batch_ids)

        start_idx = total_ingested
        end_idx = total_ingested + len(docs_list)
        print(f"  Adding batch {start_idx} to {end_idx}...")

        collection.upsert(
            documents=docs_list,
            metadatas=metas_list,
            ids=ids_list
        )
        total_ingested += len(docs_list)

    if total_ingested == 0:
        print("No expectations found to ingest.")
        return

    print("Ingestion complete!")

    # Test a simple query to verify
    print("\nRunning a test query for 'algebraic equations'...")
    results = collection.query(
        query_texts=["algebraic equations"],
        n_results=3
    )

    for idx, result in enumerate(results['documents'][0]):
        print(f"{idx+1}. {result}")

if __name__ == "__main__":
    data = load_curriculum()
    if data:
        ingest_to_chroma(data)
