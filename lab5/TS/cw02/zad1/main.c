#include<stdint.h>
#include<fcntl.h>
#include<unistd.h> 
#include<sys/types.h>
#include<sys/stat.h>
#include<stdlib.h>
#include<stdio.h>
#include<time.h>
#include<string.h>

void libsort(char * filename,int records, int size);
void generate(char* filename, int records, int size);
void systemsort(char * filename,int records, int size);
void libcopy(char* filename,char* filecopy, int records, int size);
void syscopy(char* filename,char* filecopy, int records, int size);
int main(int argc, char* argv[]){
    time_t tt;
    // int zarodek = time(&tt);
    srand(time(&tt));
    // int size = 3;
    // int record = 100;
    // generate("dane.txt", record, size);
    // libcopy("dane.txt","copy.txt", record, size);

    if(argc > 4){
        if(strcmp(argv[1],"generate")==0){
            generate(argv[2],atoi(argv[3]),atoi(argv[4]));
        }else  if(strcmp(argv[1],"sort")==0){
            if(strcmp(argv[5],"sys")==0){
                systemsort(argv[2],atoi(argv[3]),atoi(argv[4]));
            }else
            {
                libsort(argv[2],atoi(argv[3]),atoi(argv[4]));
            }
        }else if (strcmp(argv[1],"copy")==0) {
            if(strcmp(argv[6],"sys")==0){
                syscopy(argv[2],argv[3],atoi(argv[4]),atoi(argv[5]));
            }else{
                libcopy(argv[2],argv[3],atoi(argv[4]),atoi(argv[5]));
            }
        }        
    }
}


void generate(char* filename, int records, int size){
    int file = open(filename,O_CREAT|O_WRONLY|O_TRUNC,S_IRUSR|S_IWUSR,S_IXGRP);
    char* record = malloc(size);
    for(int i = 0; i<records;i++){
        for(int i=0;i<size;i++){
            record[i] = (char)(rand()%43+48);
        }
        write(file,record,size);
    }
    close(file);
}

void systemsort(char * filename,int records, int size){
        int file = open(filename,O_RDWR);
        lseek(file,0,SEEK_SET);
        int min = 0; 
        unsigned char minvalue = 0;
        unsigned char temp;
        unsigned char * minblock =  malloc(size);
        unsigned char * iblock = malloc(size);
        for(int i = 0; i < records; i++){
            min = i;
            lseek(file,i*size,SEEK_SET);
            read(file, &minvalue,1); 
            // printf("%c \n",(char)minvalue);
            for(int a = i+1;a<records;a++){
                lseek(file,a*size,SEEK_SET);   
                read(file, &temp,1); 
                if(minvalue > temp){
                    minvalue = temp;
                    min = a;
                }            
            }
            lseek(file,i*size,SEEK_SET);
            read(file,iblock,size);

            lseek(file,min*size,SEEK_SET);
            read(file,minblock,size);

            lseek(file,i*size,SEEK_SET);
            write(file,minblock,size);

            lseek(file,min*size,SEEK_SET);
            write(file,iblock,size);
        }
        close(file);
}

void libsort(char * filename,int records, int size){
        FILE* file = fopen(filename,"r+");
        int min;
        unsigned char minvalue = 0;
        unsigned char temp;
        unsigned char * minblock =  malloc(size);
        unsigned char * iblock = malloc(size);
        for(int i = 0; i < records-1; i++){
            min = i;
            fseek(file,i*size,0);
            fread(&minvalue, 1,1,file); 
            for(int a = i+1;a<records;a++){
                fseek(file,a*size,0);   
                fread(&temp, 1, 1, file); 
                if(minvalue > temp){
                    minvalue = temp;
                    min = a;
                }
            }
            
            fseek(file,i*size,0);
            fread(iblock,size, 1, file);

            fseek(file,min*size,0);
            fread(minblock, size, 1, file);

            fseek(file,i*size,0);
            fwrite(minblock,size, 1, file);

            fseek(file,min*size,0);
            fwrite(iblock,size, 1, file);
        }
        fclose(file);
}

void syscopy(char* filename,char* filecopy, int records, int size){
    int file = open(filename,O_RDONLY);
    int copy = open(filecopy,O_CREAT|O_WRONLY|O_TRUNC,S_IRUSR|S_IWUSR,S_IXGRP);
    char* record = malloc(size);

    for(int i = 0; i<records;i++){
        lseek(file,i*size,SEEK_SET);
        read(file, record,size);
        write(copy,record,size);
    }
    close(file);
    close(copy);
}

void libcopy(char* filename,char* filecopy, int records, int size){
    FILE* file = fopen(filename,"r");
    FILE* copy = fopen(filecopy,"w");

    char* record = malloc(size);

    for(int i = 0; i<records;i++){
        fseek(file,i*size,0);
        fread(record,size, 1, file);
        fwrite(record,size, 1, copy);
    }
    fclose(file);
    fclose(copy);
}


