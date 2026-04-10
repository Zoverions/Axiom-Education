import timeit
import re
from extend_json import create_mock_irt

course = {"name": "Science, Grade 9 (De-streamed)"}
strand = "A_STEM_Skills"
text = "apply the scientific research process to investigate scientific questions and problems."

def bench():
    for _ in range(10000):
        create_mock_irt(course, strand, text)

if __name__ == '__main__':
    # Warm up
    bench()
    t = timeit.timeit(bench, number=10)
    print(f"Total time for 100,000 calls: {t:.4f} seconds")
    print(f"Average time per call: {t/100000:.8f} seconds")
