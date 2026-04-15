#!/bin/bash

# Compilar el frontend
echo "Compilando trad3.y..."
bison trad3.y
gcc -o trad3 trad3.tab.c

# Crear carpeta de resultados si no existe
mkdir -p results

# Contadores
OK=0
FAIL=0

# Recorrer todos los subdirectorios dentro de tests-2026
for dir in tests-2026/*; do
    if [ -d "$dir" ]; then
        echo "========================================"
        echo " Procesando tests en: $dir"
        echo "========================================"
        
        for f in "$dir"/*.c; do
            if [ -f "$f" ]; then
                base=$(basename "$f" .c)
                dirname=$(basename "$dir")
                echo "[Test] $dirname/$base..."
                
                ./trad3 < "$f" > "results/${dirname}_${base}.out" 2> "results/${dirname}_${base}.err"
                
                if [ -s "results/${dirname}_${base}.err" ]; then
                    echo "--- Error/Syntax en $base ---"
                    cat "results/${dirname}_${base}.err"
                    FAIL=$((FAIL + 1))
                else
                    echo "--- Output para $base ---"
                    cat "results/${dirname}_${base}.out"
                    OK=$((OK + 1))
                fi
                echo "----------------------------------------"
            fi
        done
    fi
done

echo ""
echo "========================================"
echo " RESUMEN FINAL"
echo "========================================"
echo " OKs:      $OK"
echo " FALLOS:   $FAIL"
echo " TOTAL:    $((OK + FAIL))"
echo "========================================"
