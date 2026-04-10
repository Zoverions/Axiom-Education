import timeit
from parse_markdown import create_mock_irt

course_name = "Science, Grade 10, Academic"
text = "This is a sample expectation text that might contain several words to test the syllable estimation and IRT difficulty heuristic calculation. It should be long enough to make the regex compilation overhead noticeable when run many times."

def bench():
    for _ in range(10000):
        create_mock_irt(course_name, text)

if __name__ == '__main__':
    # Warm up
    bench()
    t = timeit.timeit(bench, number=5)
    print(f"Benchmark Time (5 runs of 10k iterations): {t:.4f} seconds")
