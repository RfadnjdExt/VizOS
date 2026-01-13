#ifndef TOKENIZER_H
#define TOKENIZER_H

typedef struct {
    char command[64];
    char arguments[128];
    int valid;
} ParsedCommand;

// Fungsi untuk memvisualisasikan proses tokenisasi
void transparent_tokenize(const char* input, ParsedCommand* out_cmd);

// Fungsi prediksi perintah (Auto-Guess)
const char* auto_guess(const char* partial_input);

#endif
