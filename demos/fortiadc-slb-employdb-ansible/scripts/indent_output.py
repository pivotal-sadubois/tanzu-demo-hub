import sys
from rich.console import Console

console = Console()

for line in sys.stdin:
    console.print("     " + line, end="")
