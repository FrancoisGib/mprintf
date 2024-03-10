#include <stdio.h>
#include <inttypes.h>
#include <stdlib.h>
#include <string.h>

extern void mprintf(char* pattern, ...);

int main() {
    mprintf("args: %d %c %s %h %b\n", 234, 'c', "string", 0xFFFFFFFF, 8, "ok", 15);
    return 0;
}
