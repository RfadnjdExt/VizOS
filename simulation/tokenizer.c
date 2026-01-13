#include <stdio.h>
#include <string.h>
#include "tokenizer.h"

// Daftar perintah yang tersedia untuk Auto-Guess
const char* KNOWN_COMMANDS[] = {
    "pulse",
    "boot",
    "arch",
    "echo",
    "exit",
    NULL
};

void transparent_tokenize(const char* input, ParsedCommand* out_cmd) {
    printf("\n[TOKENIZER]: Processing buffer '%s'...\n", input);
    
    // Reset output
    out_cmd->command[0] = '\0';
    out_cmd->arguments[0] = '\0';
    out_cmd->valid = 0;

    char temp[256];
    strncpy(temp, input, 255);
    
    // Visualisasi splitting
    char* token = strtok(temp, " ");
    if (token) {
        printf("[TOKENIZER]: Found Command Token -> '%s'\n", token);
        strncpy(out_cmd->command, token, 63);
        
        token = strtok(NULL, ""); // Ambil sisa string
        if (token) {
            printf("[TOKENIZER]: Found Argument Token -> '%s'\n", token);
            strncpy(out_cmd->arguments, token, 127);
        } else {
            printf("[TOKENIZER]: No Arguments detected.\n");
        }
        out_cmd->valid = 1;
    } else {
        printf("[TOKENIZER]: Empty buffer. No tokens.\n");
    }
}

const char* auto_guess(const char* partial_input) {
    if (strlen(partial_input) == 0) return NULL;
    
    for (int i = 0; KNOWN_COMMANDS[i] != NULL; i++) {
        if (strncmp(partial_input, KNOWN_COMMANDS[i], strlen(partial_input)) == 0) {
            return KNOWN_COMMANDS[i];
        }
    }
    return NULL;
}
