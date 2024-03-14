#include <inttypes.h>
#include <string.h>
#include <stdio.h> 
#include <stdlib.h> 

extern void mprintf(char* pattern, ...);

int main() {
    mprintf("args:%d%c%s%b%s%d%d", 128, 'c', "string", 8, "qsd", 45, 32);
    return 0;
}

