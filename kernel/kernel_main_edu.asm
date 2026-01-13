[BITS 16]           ; Atur mode 16-bit (Real Mode)
[ORG 0x0000]         ; Offset memori dihitung dari 0 (karena kita pakai Segment:Offset)

start:
    ; --- SETUP SEGMEN MEMORI ---
    ; Kita mengatur Data Segment (DS), Extra Segment (ES), dan Stack Segment (SS)
    ; ke alamat kernel kita (0x1000).
    mov ax, 0x1000
    mov ds, ax      ; DS = 0x1000
    mov es, ax      ; ES = 0x1000
    mov ss, ax      ; SS = 0x1000
    mov sp, 0xFFFE  ; Stack Pointer di ujung atas segmen (Hampir 64KB)

    ; --- PRINT PESAN SAMBUTAN ---
    mov si, welcome_msg
    call print_string
    call print_newline

    ; Cetak Prompt awal 'MYSHELL>'
    call print_prompt

    ; --- INISIALISASI BUFFER ---
    ; Menyiapkan area memori untuk menampung ketikan user
    mov di, command_buffer  ; DI menunjuk ke awal buffer
    xor cx, cx              ; CX = 0 (Counter jumlah karakter)
    
    ; Bersihkan baris tokenizer di bawah prompt agar rapi
    call update_tokenizer

shell_loop:
    ; --- MENUNGGU INPUT KEYBOARD ---
    mov ah, 0x00    ; Servis BIOS: Read Key Stroke
    int 0x16        ; Panggil Interrupt Keyboard
    ; Hasilnya: AL = Karakter ASCII yang ditekan

    ; Cek tombol ENTER (0x0D)
    cmp al, 0x0D
    je .handle_enter

    ; Cek tombol BACKSPACE (0x08)
    cmp al, 0x08
    je .handle_backspace

    ; --- MENANGANI INPUT KARAKTER BIASA ---
    stosb           ; Simpan huruf di AL ke memori [DI], lalu naikkan DI
    inc cx          ; Tambah hitungan karakter
    
    ; Echo (Tampilkan) huruf ke layar
    mov ah, 0x0E    ; Servis BIOS: Teletype Output
    int 0x10        ; Cetak huruf
    
    ; --- UPDATE VISUALISASI REAL-TIME ---
    ; Setiap kali ngetik, update baris bawah
    call update_tokenizer
    jmp shell_loop  ; Ulangi loop

.handle_enter:
    ; User menekan ENTER, proses perintah
    mov al, 0
    stosb           ; Tambahkan Null Terminator (0) di akhir buffer string
    
    ; 1. Bersihkan baris visualisasi agar tidak menimpa output perintah
    call clear_viz_line
    
    call print_newline
    
    ; 2. Eksekusi Perintah
    call process_command
    
    ; 3. RESET BUFFER (PENTING!)
    ; Hapus seluruh isi buffer agar tidak ada "hantu" teks lama
    mov di, command_buffer
    push cx
    mov cx, 128     ; Ukuran buffer 128 byte
    mov al, 0       ; Isi dengan 0 (Null)
    rep stosb       ; Lakukan berulang
    pop cx
    
    ; Reset penunjuk buffer
    mov di, command_buffer
    xor cx, cx
    
    call print_prompt
    call update_tokenizer 
    jmp shell_loop

.handle_backspace:
    ; Logika menghapus karakter (Backspace)
    cmp cx, 0       ; Jika buffer kosong, jangan hapus apa-apa
    je shell_loop
    dec di          ; Mundurkan pointer memori
    dec cx          ; Kurangi hitungan karakter
    
    ; Hapus visual di layar (Mundur - Spasi - Mundur)
    mov ah, 0x0E
    mov al, 0x08 ; Karakter Backspace
    int 0x10
    mov al, ' '  ; Karakter Spasi (menghapus huruf)
    int 0x10
    mov al, 0x08 ; Karakter Backspace (balik lagi)
    int 0x10
    
    mov byte [di], 0 ; Hapus karakter di dalam memori buffer
    
    call update_tokenizer ; Update visualisasi bawah
    jmp shell_loop

; --- FUNGSI TAMPILAN TOKENIZER (INOVASI I) ---
update_tokenizer:
    ; Simpan semua register (Context Saving)
    push ax
    push bx
    push cx
    push si
    push di
    push ds
    push es
    
    ; 1. Cek Posisi Kursor User (Supaya bisa balik lagi)
    mov ah, 0x03
    mov bh, 0       ; Page 0
    int 0x10        ; Mengembalikan DH=Baris, DL=Kolom
    push dx         ; Simpan ke Stack
    
    ; 2. Pindah ke Baris Berikutnya (Baris Bawah)
    inc dh          ; Row + 1
    
    mov ah, 0x02    ; Servis BIOS: Set Cursor Position
    mov bh, 0
    mov dl, 0       ; Kolom 0 (Awal Baris)
    int 0x10
    
    ; 3. Bersihkan Baris Bawah (Isi Spasi)
    mov cx, 79      ; Lebar layar console biasanya 80
    mov ah, 0x0E
    mov al, ' '
.clear_viz:
    int 0x10
    loop .clear_viz
    
    ; 4. Kembali ke Awal Baris Bawah
    mov ah, 0x02
    mov bh, 0
    ; (Kita pakai DH yang sudah di-inc tadi)
    mov dl, 0
    int 0x10
    
    ; 5. Tulis Label "CMD:"
    mov si, str_cmd_label
    call print_string
    
    ; 6. Tulis Isi Command (Sampai ketemu Spasi)
    mov si, command_buffer
.viz_loop:
    lodsb           ; Baca buffer ke AL
    cmp al, 0       ; Jika habis (Null), selesai
    je .viz_done
    cmp al, ' '     ; Jika Spasi, berarti pindah ke ARGumen
    je .viz_space
    mov ah, 0x0E
    int 0x10        ; Cetak karakter perintah
    jmp .viz_loop

.viz_space:
    ; Transisi ke Argumen
    push si
    mov si, str_arg_label
    call print_string   ; Cetak " ARG: "
    pop si
    
.viz_arg_loop:
    lodsb
    cmp al, 0
    je .viz_done
    mov ah, 0x0E
    int 0x10        ; Cetak sisa string sebagai argumen
    jmp .viz_arg_loop

.viz_done:
    ; 7. Kembalikan Kursor ke Posisi Asli (User mengetik)
    pop dx          ; Ambil posisi dari Stack
    mov ah, 0x02
    mov bh, 0
    int 0x10
    
    ; Restore semua register
    pop es
    pop ds
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret

; --- FUNGSI BERSIH LAYAR BAWAH ---
; Mirip update_tokenizer, tapi cuma menghapus (tanpa nulis CMD/ARG)
clear_viz_line:
    push ax
    push bx
    push cx
    push dx
    
    ; Ambil posisi
    mov ah, 0x03
    mov bh, 0
    int 0x10
    push dx
    
    ; Pindah bawah
    inc dh
    
    mov ah, 0x02
    mov bh, 0
    mov dl, 0
    int 0x10
    
    ; Hapus (Spasi 79x)
    mov cx, 79
    mov ah, 0x0E
    mov al, ' '
.cl_loop:
    int 0x10
    loop .cl_loop
    
    ; Pulihkan kursor
    pop dx
    mov ah, 0x02
    mov bh, 0
    int 0x10
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; --- LOGIKA PEMROSESAN PERINTAH (AUTO-GUESS) ---
process_command:
    mov al, [command_buffer]
    cmp al, 0        ; Jika buffer kosong, abaikan
    je .done
    
    ; PREFIX MATCHING (Optimasi Kecepatan)
    cmp al, 'h'
    je .is_help      ; Jika 'h...' -> Help
    cmp al, 'r'
    je .is_reboot    ; Jika 'r...' -> Reboot
    cmp al, 'p'
    je .is_pulse     ; Jika 'p...' -> Pulse (Monitor)
    cmp al, 'e'
    je .is_echo      ; Jika 'e...' -> Echo

    ; Jika tidak ada yang cocok
    mov si, unknown_msg
    call print_string
    call print_newline
.done:
    ret

; --- HANDLER PERINTAH ---

.is_help:
    mov si, help_msg
    call print_string
    call print_newline
    ret

.is_echo:
    mov si, command_buffer
    ; Skip kata pertama ("echo")
.echo_skip:
    lodsb
    cmp al, ' '
    je .echo_print
    cmp al, 0
    je .echo_nl
    jmp .echo_skip
.echo_print:
    call print_string   ; Cetak sisanya
.echo_nl:
    call print_newline
    ret

.is_reboot:
    mov si, reboot_msg
    call print_string
    call print_newline
    ; Magic Jump ke FFFF:0000 (Reset Vector BIOS)
    db 0xEA, 0x00, 0x00, 0xFF, 0xFF 
    ret

.is_pulse:
    mov si, pulse_header
    call print_string
    call print_newline
    mov si, pulse_cpu
    call print_string
    call print_newline
    mov si, pulse_mem
    call print_string
    call print_newline
    mov si, pulse_tick
    call print_string
    
    ; BACA BIOS DATA AREA (INOVASI II)
    push es
    xor ax, ax
    mov es, ax
    mov ax, [es:0x046C] ; Alamat Timer Ticks
    pop es
    
    call print_hex      ; Konversi Angka ke Hex String
    call print_newline
    ret

; --- FUNGSI UTILITAS ---

; Fungsi: Menghapus angka Hex
print_hex:
    push cx
    push ax
    push bx
    mov cx, 4       ; 16-bit = 4 digit Hex
.loop:
    rol ax, 4       ; Rotasi 4 bit (ambil nibble teratas)
    push ax
    and al, 0x0F    ; Ambil 4 bit terakhir
    cmp al, 9
    jle .digit
    add al, 7       ; Koreksi untuk A-F
.digit:
    add al, '0'     ; Koreksi untuk 0-9
    mov ah, 0x0E
    int 0x10        ; Cetak
    pop ax
    loop .loop
    pop bx
    pop ax
    pop cx
    ret

print_prompt:
    mov si, prompt_msg
    call print_string
    ret

print_newline:
    mov ah, 0x0E
    mov al, 0x0A    ; Line Feed
    int 0x10
    mov al, 0x0D    ; Carriage Return
    int 0x10
    ret

print_string:
    mov ah, 0x0E
.loop:
    lodsb           ; Ambil byte dari [SI]
    cmp al, 0       ; Cek Null Terminator
    je .done
    int 0x10        ; Cetak
    jmp .loop
.done:
    ret

; --- VARIABEL DATA STRING ---
str_cmd_label db 'CMD: ', 0
str_arg_label db ' ARG: ', 0
welcome_msg db 'Selamat Datang di Kernel MyShell OS (Mode Enhanced)', 0
prompt_msg db 'MYSHELL> ', 0
unknown_msg db 'Perintah tidak dikenal.', 0
help_msg db 'Perintah Tersedia: help, reboot, pulse, echo', 0
reboot_msg db 'Sistem akan dimuat ulang...', 0
pulse_header db '--- MONITOR STATISTIK HARDWARE ---', 0
pulse_cpu db 'CPU : Mode Real 16-bit (Aktif)', 0
pulse_mem db 'MEM : 640KB RAM Konvensional Terdeteksi', 0
pulse_tick db 'WAKTU NYALA (TICKS): 0x', 0

; --- RESERVASI MEMORI ---
command_buffer times 128 db 0

; Padding agar ukuran pas untuk Floppy (1.44MB - 512B Bootloader)
times 1474048 - ($ - $$) db 0
