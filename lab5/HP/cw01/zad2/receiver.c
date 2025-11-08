#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

#define PIPE "./squareFIFO"

int main() {
        sleep(1);
        int val = 0;
	FILE* pipe; 
	if ( !(pipe = fopen(PIPE, "r"))){
        return 1;
	}else{
	 fscanf(pipe, "%d",&val);
	 fclose(pipe);
	 printf("%d square is: %d\n", val, val*val);
         	
	}
 return 0;
}
