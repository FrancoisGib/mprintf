#include <stdio.h>
#include <inttypes.h>
#include <stdlib.h>
#include <string.h>

#define MAX_STR_SIZE 32

extern void mprintf(char* motif, ...);

int main() {
    mprintf("args: %d %c %s %h\n", 234, 'c', "string", 0x64);
    return 0;
}
