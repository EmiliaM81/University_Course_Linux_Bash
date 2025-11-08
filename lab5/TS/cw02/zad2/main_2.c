#include<stdint.h>
#define _XOPEN_SOURCE 500 
#include<fcntl.h>
#include<unistd.h> 
#include<sys/types.h>
#include<sys/stat.h>
#include<stdlib.h>
#include<stdio.h>
#include<time.h>
#include<string.h>
#include<dirent.h>
#include<sys/sysmacros.h>
#include <ftw.h>
time_t data;
char op;
char* filetype(struct stat* info);
int dateComparator(time_t a, time_t b, char operation);
int fn(char *fpath, struct stat *sb,int typeflag, struct FTW *ftwbuf){
    if(dateComparator(sb->st_mtime,data,op)==1){
        char* inDir = malloc(sizeof(char)*1000);      
        char* absolute_path = malloc(sizeof(char)*1024);
        realpath(fpath,absolute_path);
        // strcat(inDir,"/");
        // strcat(inDir,fpath);
        // realpath(inDir,absolute_path);
        printf("Ścieżka do pliku ------> %s \n", fpath);
        printf("Ścieżka bezwzgledna do pliku ------> %s \n", absolute_path);
        printf("Rodzaj pliku -----> %s \n",filetype(sb));
        printf("Rozmiar pliku ------> %iB \n", sb->st_size);
        printf("Last status change:       %s", ctime(&sb->st_ctime));
        printf("Last file access:         %s", ctime(&sb->st_atime));
        printf("Last file modification:   %s", ctime(&sb->st_mtime));
        printf("\n \n \n");
    }
    return 0;
}


void go(char* file);
time_t createDate(int year, int month, int day, int hour, int min, int sec);

int main(int argc, char* argv[]){
    // data = createDate(2019,3,1,1,1,1);
    // op = '<';
    // go("/home/jacek");

    char* file = argv[1];
    op = argv[2][0];
    data = createDate(atoi(argv[5]),atoi(argv[4]),atoi(argv[3]),atoi(argv[6]), atoi(argv[7]), atoi(argv[8]));
    // printf("%s \n",ctime(&data));
    go(file);
}


char* filetype(struct stat* info){
    if(S_ISDIR(info->st_mode)==1){
        return "Katalog";
    }
    if(S_ISREG(info->st_mode)==1){
        return "Plik zwykły";
    }
    if(S_ISLNK(info->st_mode)==1){
        return "Link symboliczny";
    }
    if(S_ISBLK(info->st_mode)==1){
        return "Blok specjalny";
    }
    if(S_ISCHR(info->st_mode)==1){
        return "Urządzenie znakowe";
    }
    if((info->st_dev)== __S_IFSOCK){
        return "FIFO";
    }
    return "unknown";
}

int dateComparator(time_t a, time_t b, char operation){

    if(operation == '<'){
        return a < b;
    }
    if(operation == '>'){
        return a > b;
    }
    if(operation == '='){
        return a == b;
    }
    
}

void go(char* file){

    // struct stat* info = malloc(sizeof(struct stat));
    // struct FTW* ftw = malloc(sizeof(struct ftw));    
    
    int ntf = nftw(file,&fn,100);
}



time_t createDate(int year, int month, int day, int hour, int min, int sec){
    struct tm t; // = malloc(sizeof(struct tm));

    t.tm_mon = month-1;
    t.tm_year = year-1900;
    t.tm_mday = day;
    t.tm_hour = hour+1;
    t.tm_sec = sec;
    t.tm_min = min;
    return mktime(&t);

}