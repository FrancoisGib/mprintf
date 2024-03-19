mprintf:
	gcc -no-pie -g -static mprintf.c mprintf.s -o mprintf

mprintfbis:
	gcc -no-pie -g -static mprintf.c mprintfbis.s -o mprintf

ok:
	gcc -no-pie -g -static mprintf.c ok.s -o mprintf


test:
	as -a --gstabs -o test.o test.s
	ld -o test test.o

clean:
	rm -f mprintf