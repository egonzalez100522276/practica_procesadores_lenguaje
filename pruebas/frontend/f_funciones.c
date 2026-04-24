// Test de Funciones y Variables Locales para Frontend 
int global_v = 100;

sumar(int a, int b) {
    int temporal;
    temporal = a + b;
    return temporal;
}

cuadrado(int n) {
    return n * n;
}

main() {
    int x = 5;
    int y = 10;
    
    
    resultado = sumar(x, y);
    printf("%d", resultado);
    printf("%d", cuadrado(resultado));
    printf("%d", global_v);
}
