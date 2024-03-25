mprintf:
	gcc -no-pie -g -static mprintf.c mprintf.s -o mprintf

mprintf2:
	gcc -no-pie -g -static mprintf.c mprintf2.s -o mprintf

mprintf3:
	gcc -no-pie -g -static mprintf.c mprintf3.s -o mprintf


test:
	as -a --gstabs -o test.o test.s
	ld -o test test.o

clean:
	rm -f mprintf