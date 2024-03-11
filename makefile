mprintf:
	gcc -no-pie -g -static mprintf.c mprintf.s -o mprintf

clean:
	rm -f mprintf