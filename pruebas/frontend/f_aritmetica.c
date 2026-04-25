// Test de Aritmética y Operadores para Frontend 
int global_x = 10;
int global_y = 20;

main() {
    int local_a;
    int local_b;
    
    local_a = (global_x + 5) * 2;
    local_b = global_y / (local_a - 10);
    
    printf("%d", local_a % 3);
    
    // Comparaciones y Lógica
    if (local_a == 30 && local_b != 0) {
        printf("%d", 1);
    }
    
    if (local_a < 100 || !(local_b >= 5)) {
        printf("%d", 2);
    }
    
    if (local_a <= 30 && local_b > -1) {
        printf("%s", "OK");
    }
}
//@ (main)
