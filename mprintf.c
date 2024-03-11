#include <stdio.h>
#include <inttypes.h>
#include <stdlib.h>
#include <string.h>

extern void mprintf(char* pattern, ...);

int main() {
    mprintf("args: %d %c %s %h %b %s %d %c %s\n", 234, 'c', "string", 0xFFFFFFFF, 8, "qsd", 15, 'o', "sqdsq");
    return 0;
}