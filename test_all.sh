#!/bin/bash
mkdir -p results
bison trad3.y
gcc -o trad3 trad3.tab.c
for f in tests-2026/00/*.c; do
    base=$(basename "$f" .c)
    echo "Testing $base..."
    ./trad3 < "$f" > "results/$base.out"
    echo "--- Result for $base ---"
    cat "results/$base.out"
    echo "------------------------"
done
