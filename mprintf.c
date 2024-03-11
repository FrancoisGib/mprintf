#include <inttypes.h>
#include <string.h>
#include <stdio.h> 
#include <stdlib.h> 

extern void mprintf(char* pattern, ...);

int main() {
    mprintf("args: %c %s %h %b %s %d %c %s\n", 128, 'c', "string", 0xFFFFFFFF, 8, "qsd", 15, 'c', "string2");
    return 0;
}