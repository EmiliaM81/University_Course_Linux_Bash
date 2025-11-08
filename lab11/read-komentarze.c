#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define RECORD_SIZE  1024
#define TEXT_SIZE (RECORD_SIZE - sizeof(int)) // Rozmiar tekstu po odjęciu pola id

/**
Struktura Record
przechowuje dane rekordu
**/

typedef struct {
    int id;
    char text[TEXT_SIZE];
} Record;

void read_record(const char *filename, int record_number) {
    FILE *file = fopen(filename, "rb");
    if (!file) {
        perror("Error opening file");
        exit(1);
    }

    /* Przesunięcie wskaźnika pliku na początek żądanego rekordu */
    if (fseek(file, record_number * sizeof(Record), SEEK_SET) != 0) {
        perror("Error seeking in file");
        fclose(file);
        exit(1);
    }

    Record record;
    size_t read_size = fread(&record, sizeof(Record), 1, file);
    if (read_size != 1) {
        if (feof(file)) {
            fprintf(stderr, "Error: Record number %d does not exist in the file.\n", record_number);
        } else {
            perror("Error reading from file");
        }
        fclose(file);
        exit(1);
    }

    /** Wyświetlenie zawartości rekordu
    */
    printf("Record ID: %d\n", record.id);
    printf("Text: %s\n", record.text);

    fclose(file);
}
/**
Program główny
*/
int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <file_name> <record_number>\n", argv[0]);
        return 1;
     }

    const char *filename = argv[1];
    int record_number = atoi(argv[2]);
    if (record_number < 0) {
      fprintf(stderr, "Error: Record number must be a non-negative integer.\n");
      return 1;
    }

    read_record(filename, record_number); // czytamy rekord
    return 0;
}
