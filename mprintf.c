#include <inttypes.h>
#include <stdio.h> 
#include <stdlib.h> 

extern void mprintf(char* pattern, ...);

int main() {
    int list[] = {52, 45, 5362, 11};
    mprintf("args: %td, %s, %c, %h, %d\n", 4, list, "string", 'c', 0xFF, 55);
    return 0;
}