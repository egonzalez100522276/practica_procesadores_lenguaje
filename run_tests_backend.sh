#!/bin/bash

# run_tests_backend.sh - Pipeline completa: C -> Lisp (trad.y) -> Forth (back.y)

echo "--- Compilando Frontend (trad.y) ---"
bison trad.y
if [ $? -ne 0 ]; then
    echo "ERROR: Falló bison con trad.y"
    exit 1
fi
gcc -o trad trad.tab.c
if [ $? -ne 0 ]; then
    echo "ERROR: Falló gcc al compilar trad.tab.c"
    exit 1
fi

echo "--- Compilando Backend (back.y) ---"
bison back.y
if [ $? -ne 0 ]; then
    echo "ERROR: Falló bison con back.y"
    exit 1
fi
gcc -o back back.tab.c
if [ $? -ne 0 ]; then
    echo "ERROR: Falló gcc al compilar back.tab.c"
    exit 1
fi

mkdir -p results/backend
mkdir -p results/errors/backend

OK=0
FAIL=0

echo ""
echo "--- Ejecutando Batería de Tests Completa (C -> Lisp -> Forth) ---"
for f in pruebas/backend/*.c; do
    if [ -f "$f" ]; then
        base=$(basename "$f" .c)
        echo -n "[Test] $base: "
        
        # Paso 1: C -> Lisp
        ./trad < "$f" > "results/backend/${base}.lisp" 2> "temp_err_trad.log"
        if [ $? -ne 0 ] || [ -s "temp_err_trad.log" ]; then
            echo "FALLO en Frontend (trad)"
            mv "temp_err_trad.log" "results/errors/backend/${base}_trad.err"
            FAIL=$((FAIL + 1))
            continue
        fi
        
        # Paso 2: Lisp -> Forth
        ./back < "results/backend/${base}.lisp" > "results/backend/${base}.fs" 2> "temp_err_back.log"
        if [ $? -eq 0 ] && [ ! -s "temp_err_back.log" ]; then
            echo "OK (Pipeline completado)"
            rm -f "temp_err_trad.log" "temp_err_back.log"
            OK=$((OK + 1))
        else
            echo "FALLO en Backend (back)"
            mv "temp_err_back.log" "results/errors/backend/${base}_back.err"
            FAIL=$((FAIL + 1))
        fi
    fi
done

echo ""
echo "=============================="
echo " RESUMEN BACKEND (PIPELINE)"
echo "Success:  $OK"
echo "Failures: $FAIL"
echo "Total:    $((OK + FAIL))"
echo "=============================="
