#include <inttypes.h>
#include <string.h>
#include <stdio.h> 
#include <stdlib.h> 

extern void mprintf(char* pattern, ...);

int main() {
    mprintf("args: %d, %s", 0, "dqsd");
    return 0;
}