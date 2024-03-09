mprintf:
	gcc -no-pie -g mprintf.c mprintf.s -o mprintf

clean:
	rm -f mprintf