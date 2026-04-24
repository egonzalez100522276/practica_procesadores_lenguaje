#!/bin/bash

# run_tests_frontend.sh - Compila y ejecuta tests para trad3 (C -> Lisp)

echo "--- Compilando Frontend (trad3.y) ---"
bison trad3.y
if [ $? -ne 0 ]; then
    echo "ERROR: Falló bison con trad3.y"
    exit 1
fi

gcc -o trad3 trad3.tab.c
if [ $? -ne 0 ]; then
    echo "ERROR: Falló gcc al compilar trad3.tab.c"
    exit 1
fi

mkdir -p results/frontend
mkdir -p results/errors/frontend

OK=0
FAIL=0

echo ""
echo "--- Ejecutando Batería de Tests de Frontend ---"
for f in pruebas/frontend/*.c; do
    if [ -f "$f" ]; then
        base=$(basename "$f" .c)
        echo -n "[Test] $base: "
        
        ./trad3 < "$f" > "results/frontend/${base}.lisp" 2> "temp_err.log"
        
        if [ $? -eq 0 ] && [ ! -s "temp_err.log" ]; then
            echo "OK (Lisp generado)"
            rm -f "temp_err.log"
            OK=$((OK + 1))
        else
            echo "FALLO"
            mv "temp_err.log" "results/errors/frontend/${base}.err"
            FAIL=$((FAIL + 1))
        fi
    fi
done

echo ""
echo "=============================="
echo " RESUMEN FRONTEND"
echo "Success:  $OK"
echo "Failures: $FAIL"
echo "Total:    $((OK + FAIL))"
echo "=============================="
