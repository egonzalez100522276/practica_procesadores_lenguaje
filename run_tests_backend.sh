#!/bin/bash

# run_tests_backend.sh - Compila y ejecuta tests para back3 (Lisp -> Forth)

echo "--- Compilando Backend (back3.y) ---"
bison back3.y
if [ $? -ne 0 ]; then
    echo "ERROR: Falló bison con back3.y"
    exit 1
fi

gcc -o back3 back3.tab.c
if [ $? -ne 0 ]; then
    echo "ERROR: Falló gcc al compilar back3.tab.c"
    exit 1
fi

mkdir -p results/backend
mkdir -p results/errors/backend

OK=0
FAIL=0

echo ""
echo "--- Ejecutando Batería de Tests de Backend ---"
for f in pruebas/backend/*.lisp; do
    if [ -f "$f" ]; then
        base=$(basename "$f" .lisp)
        echo -n "[Test] $base: "
        
        ./back3 < "$f" > "results/backend/${base}.fs" 2> "temp_err.log"
        
        if [ $? -eq 0 ] && [ ! -s "temp_err.log" ]; then
            echo "OK (Forth generado)"
            rm -f "temp_err.log"
            OK=$((OK + 1))
        else
            echo "FALLO"
            mv "temp_err.log" "results/errors/backend/${base}.err"
            FAIL=$((FAIL + 1))
        fi
    fi
done

echo ""
echo "=============================="
echo " RESUMEN BACKEND"
echo "Success:  $OK"
echo "Failures: $FAIL"
echo "Total:    $((OK + FAIL))"
echo "=============================="
