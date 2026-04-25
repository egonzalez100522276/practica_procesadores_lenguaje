#!/bin/bash

# run_tests_frontend.sh - Compila y ejecuta tests para trad (C -> Lisp)

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
        
        ./trad < "$f" > "results/frontend/${base}.lisp" 2> "temp_err.log"
        
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
