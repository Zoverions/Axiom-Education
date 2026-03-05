import json
import os
import chromadb
from chromadb.utils import embedding_functions

def load_curriculum():
    filepath = 'assets/curriculum/ontario_curriculum_full.json'
    if not os.path.exists(filepath):
        print(f"Error: {filepath} not found.")
        return None
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)

def ingest_to_chroma(curriculum_data):
    print("Initializing ChromaDB...")
    # Initialize a local persistent Chroma client
    client = chromadb.PersistentClient(path="assets/curriculum/chroma_db")

    # Use a lightweight local embedding model
    sentence_transformer_ef = embedding_functions.SentenceTransformerEmbeddingFunction(model_name="all-MiniLM-L6-v2")

    # Create or get the collection
    collection_name = "ontario_curriculum"
    collection = client.get_or_create_collection(
        name=collection_name,
        embedding_function=sentence_transformer_ef
    )

    documents = []
    metadatas = []
    ids = []

    print("Processing curriculum data...")
    courses = curriculum_data.get('courses', {})
    for course_code, course_info in courses.items():
        course_name = course_info.get('name', 'Unknown Course')
        strands = course_info.get('strands', {})

        for strand_name, expectations in strands.items():
            for exp in expectations:
                exp_id = exp.get('id', f"{course_code}-{hash(exp.get('expectation', ''))}")
                text = exp.get('expectation', '')

                # The document to be embedded and searched
                document = f"Course: {course_name} ({course_code}). Strand: {strand_name}. Expectation: {text}"

                documents.append(document)
                metadatas.append({
                    "course_code": course_code,
                    "course_name": course_name,
                    "strand": strand_name,
                    "expectation_raw": text,
                    "tags": ",".join(exp.get('tags', []))
                })
                ids.append(exp_id)

    if not documents:
        print("No expectations found to ingest.")
        return

    print(f"Ingesting {len(documents)} expectations into ChromaDB...")

    # Batch ingest to avoid memory issues with huge datasets
    batch_size = 500
    for i in range(0, len(documents), batch_size):
        end_idx = min(i + batch_size, len(documents))
        print(f"  Adding batch {i} to {end_idx}...")
        collection.upsert(
            documents=documents[i:end_idx],
            metadatas=metadatas[i:end_idx],
            ids=ids[i:end_idx]
        )

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
