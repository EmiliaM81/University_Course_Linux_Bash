#include<stdint.h>
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


char* filetype(struct stat* info);
int dateComparator(time_t a, time_t b, char operation);
void go(char* file,char o, time_t time);
time_t createDate(int year, int month, int day, int hour, int min, int sec);

int main(int argc, char* argv[]){
    char* file = argv[1];
    char o= argv[2][0];
    time_t data = createDate(atoi(argv[5]),atoi(argv[4]),atoi(argv[3]),atoi(argv[6]), atoi(argv[7]), atoi(argv[8]));
    printf("%s \n",ctime(&data));

    go(file, o,data);

    // go("/home/jacek", '<',data);
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

void go(char* file,char o, time_t tim){

    DIR* dirs = opendir(file);
    struct dirent* dir = readdir(dirs);
    struct stat* info = malloc(sizeof(struct stat));    
    char* inDir = malloc(sizeof(char)*1000);      
    char* absolute_path = malloc(sizeof(char)*1024);
    
    
    char* filetyp = malloc(sizeof(char)*1024);
    while(dir!=NULL){
        if (strcmp(".",dir->d_name)!=0 && strcmp("..",dir->d_name)!=0) {
            strcpy(inDir, file);
            strcat(inDir,"/");
            strcat(inDir,dir->d_name);
            realpath(inDir,absolute_path);
            
            if (stat(inDir, info)==0){
                if(dateComparator(info->st_mtime,tim,o)==1){
                    filetyp = filetype(info);
                    printf("Nazwa pliku ------> %s \n", dir->d_name);
                    printf("Ścieżka do pliku ------> %s \n", dir->d_name);
                    printf("Ścieżka bezwzględna do pliku ------> %s \n", absolute_path);
                    printf("Rodzaj pliku -----> %s \n",filetyp);
                    printf("Rozmiar pliku ------> %iB \n", info->st_size);
                    printf("Last status change:       %s", ctime(&info->st_ctime));
                    printf("Last file access:         %s", ctime(&info->st_atime));
                    printf("Last file modification:   %s", ctime(&info->st_mtime));
                    printf("\n \n \n");
                }
                if(strcmp(filetype(info), "Katalog")==0){
                        go(absolute_path,o,tim);
                    }
            }
        }
        dir = readdir(dirs);
    }
    closedir(dirs);

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