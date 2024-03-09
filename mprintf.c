#include <stdio.h>
#include <inttypes.h>
#include <stdlib.h>
#include <string.h>

extern void mprintf(char* pattern, ...);

int main() {
    mprintf("args: %d %c %s %h\n", 234, 'c', "string", 0x64);
    return 0;
}
