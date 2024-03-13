mprintf:
	gcc -no-pie -g -static mprintf.c mprintf.s -o mprintf

mprintfbis:
	gcc -no-pie -g -static mprintf.c mprintfbis.s -o mprintf

clean:
	rm -f mprintf