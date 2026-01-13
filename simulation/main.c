#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <conio.h>
#include "tokenizer.h"

#define MAX_BUFFER 256

void print_prompt() {
    printf("MyShell> ");
}

void process_command(char* input) {
    if (strlen(input) == 0) return;
    
    ParsedCommand cmd;
    transparent_tokenize(input, &cmd);
    
    if (cmd.valid) {
        printf("[EXEC]: Command='%s', Args='%s'\n", cmd.command, cmd.arguments);

        if (strcmp(cmd.command, "exit") == 0) {
            printf("Exiting MyShell OS Simulation...\n");
            exit(0);
        } else if (strcmp(cmd.command, "pulse") == 0) {
            printf("\n--- HARDWARE PULSE MONITOR ---\n");
            printf("CPU Interrupts: [||||      ] 42%%\n");
            printf("Memory Buffer : [||||||||||] 100%% OK\n");
            printf("Keyboard IRQ  : ACTIVE (Port 0x60)\n");
            printf("------------------------------\n");
        } else if (strcmp(cmd.command, "echo") == 0) {
            printf("%s\n", cmd.arguments);
        } else {
            printf("Unknown command: %s\n", cmd.command);
        }
    }
}

int main() {
    char buffer[MAX_BUFFER];
    int pos = 0;
    
    printf("=== MyShell OS Userspace Simulation ===\n");
    printf("Type 'exit' to quit. Try 'pulse' or 'echo hello'.\n\n");

    print_prompt();

    while (1) {
        if (_kbhit()) {
            char ch = _getch();
            
            // Handle Enter
            if (ch == '\r') {
                printf("\n"); // Newline after enter
                buffer[pos] = '\0';
                process_command(buffer);
                pos = 0;
                print_prompt();
            } 
            // Handle Backspace
            else if (ch == '\b') {
                if (pos > 0) {
                    pos--;
                    printf("\b \b");
                    fflush(stdout);
                }
            }
            // Handle Tab (Auto-Guess)
            else if (ch == '\t') {
                buffer[pos] = '\0';
                const char* guess = auto_guess(buffer);
                if (guess) {
                    // Complete the command
                    printf("%s", guess + pos); // Print remaining chars
                    strcpy(buffer, guess);
                    pos = strlen(guess);
                    fflush(stdout);
                }
            }
            // Handle Normal Character
            else if (pos < MAX_BUFFER - 1) {
                buffer[pos++] = ch;
                printf("%c", ch);
                fflush(stdout);
            }
        }
    }
    return 0;
}
