#include <stdio.h>

int main(int argc, char**argv){
	int i;
	#ifdef REVERSE
	for(i=argc-1; i>=0; i--){
	#else
	for(i=0; i<argc; i++){
	#endif
		printf("%s\n", argv[i]);
	}
	return 0;
}
