import sys
from unittest.mock import MagicMock

# Mock external dependencies
sys.modules['pdfplumber'] = MagicMock()
sys.modules['regex'] = MagicMock()

import timeit
from compile_curriculum import estimate_irt

text = "This is a sample text to test the IRT estimation function. It contains some words of varying lengths. It also has some longer words like mathematics and geography, as well as simple words."

def bench():
    for _ in range(10000):
        estimate_irt(text, 10)

if __name__ == '__main__':
    t = timeit.timeit(bench, number=1)
    print(f"Baseline Time: {t:.4f} seconds")
