#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdlib.h>
#include <unistd.h>

#define PIPE "./squareFIFO"

int main(int argc, char* argv[]) {

 if(argc !=2){
   printf("Not a suitable number of program parameters\n");
   return(1);
 } 



    mkfifo(PIPE, 0644);
    
    FILE* pipe = fopen(PIPE, "w");
    
    fprintf(pipe, "%d", atoi(argv[1]));
    fclose(pipe);
    unlink(PIPE);

    return 0;
}
