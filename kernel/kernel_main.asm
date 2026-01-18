[BITS 16]
[ORG 0x0000]

; Define Buffer Address (Fixed to avoid label shift issues)
command_buffer equ 0x2000

start:
    ; Setup Segments
    mov ax, 0x1000
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFFFE

    mov si, welcome_msg
    call print_string
    call print_newline

    call print_prompt

    ; Initialize buffer
    mov di, command_buffer
    xor cx, cx
    
    ; Clear the tokenizer line initially (just to be sure)
    call update_tokenizer

shell_loop:
    mov ah, 0x00
    int 0x16

    cmp al, 0x0D        ; Enter
    je .handle_enter

    cmp al, 0x08        ; Backspace
    je .handle_backspace

    ; Standard Char Input
    stosb               ; Store in buffer
    inc cx
    
    ; Echo to screen
    mov ah, 0x0E
    int 0x10
    
    ; Update Tokenizer on next line
    call update_tokenizer
    jmp shell_loop

.handle_enter:
    mov al, 0
    stosb               ; Null terminate
    
    ; Before processing, we MUST clear the tokenizer line 
    ; so the command output doesn't overwrite it messily.
    call clear_viz_line
    
    call print_newline
    call process_command
    
    ; Reset buffer (Clear entire 128 bytes to prevent ghosting)
    mov di, command_buffer
    push cx
    mov cx, 128
    mov al, 0
    rep stosb           ; Fill [di] with 0, cx times
    pop cx
    
    ; Reset indices
    mov di, command_buffer
    xor cx, cx
    
    call print_prompt
    ; Clear tokenizer line for new prompt (optional, but good practice)
    call update_tokenizer 
    jmp shell_loop

.handle_backspace:
    cmp cx, 0
    je shell_loop
    dec di
    dec cx
    
    ; Destructive Backspace on Screen
    mov ah, 0x0E
    mov al, 0x08 ; BS
    int 0x10
    mov al, ' '  ; Space
    int 0x10
    mov al, 0x08 ; BS
    int 0x10
    
    mov byte [di], 0 ; Clear buffer char
    
    call update_tokenizer
    jmp shell_loop

; --- Dual-Line Tokenizer Routine ---
update_tokenizer:
    push ax
    push bx
    push cx
    push si
    push di
    push ds
    push es
    
    ; 1. Get Current Cursor Position
    mov ah, 0x03
    mov bh, 0       ; Page 0
    int 0x10        ; Returns DH=Row, DL=Col
    push dx         ; Save original cursor (DH, DL)
    
    ; 2. Move to Next Row
    inc dh
    
    ; Check if we are at bottom? (Assume 25 rows, 0-24). 
    ; If dh > 24, we might cause scroll if we write. 
    ; For now, let's just write.
    
    mov ah, 0x02
    mov bh, 0
    mov dl, 0       ; Col 0
    int 0x10
    
    ; 3. Clear the line
    mov cx, 79
    mov ah, 0x0E
    mov al, ' '
.clear_viz:
    int 0x10
    loop .clear_viz
    
    ; 4. Return to start of viz line
    mov ah, 0x02
    mov bh, 0
    ; Retrieve cursor row from stack (but it's buried under DX!)
    ; We have DX on stack.
    ; Actually, let's just use DH which we incremented.
    mov dl, 0
    int 0x10
    
    ; 5. Draw Tokenizer
    mov si, str_cmd_label
    call print_string
    
    mov si, command_buffer
.viz_loop:
    lodsb
    cmp al, 0
    je .viz_done
    cmp al, ' '
    je .viz_space
    mov ah, 0x0E
    int 0x10
    jmp .viz_loop

.viz_space:
    push si
    mov si, str_arg_label
    call print_string
    pop si
    
.viz_arg_loop:
    lodsb
    cmp al, 0
    je .viz_done
    mov ah, 0x0E
    int 0x10
    jmp .viz_arg_loop

.viz_done:
    ; 6. Restore Original Cursor
    pop dx          ; Pop original position
    mov ah, 0x02
    mov bh, 0
    int 0x10
    
    pop es
    pop ds
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret

; Routine to just clear the visualization line without drawing
clear_viz_line:
    push ax
    push bx
    push cx
    push dx
    
    ; 1. Get Current Cursor Position
    mov ah, 0x03
    mov bh, 0
    int 0x10
    push dx
    
    ; 2. Move to Next Row
    inc dh
    
    mov ah, 0x02
    mov bh, 0
    mov dl, 0
    int 0x10
    
    ; 3. Clear the line
    mov cx, 79
    mov ah, 0x0E
    mov al, ' '
.cl_loop:
    int 0x10
    loop .cl_loop
    
    ; 4. Restore Original Cursor
    pop dx
    mov ah, 0x02
    mov bh, 0
    int 0x10
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

process_command:
    ; (Same logic as before)
    mov al, [command_buffer]
    cmp al, 0
    je .done
    
    cmp al, 'h'
    jne .check_r
    jmp handler_help
.check_r:
    cmp al, 'r'
    jne .check_p
    jmp handler_reboot
.check_p:
    cmp al, 'p'
    jne .check_c
    jmp handler_pulse
.check_c:
    cmp al, 'c'
    jne .check_t
    jmp handler_cls
.check_t:
    cmp al, 't'
    jne .check_d
    jmp handler_time
.check_d:
    cmp al, 'd'
    jne .check_e
    jmp handler_date
.check_e:
    cmp al, 'e'
    jne .check_k
    jmp handler_echo
.check_k:
    cmp al, 'k'
    jne .unknown
    jmp handler_color

.unknown:
    mov si, unknown_msg
    call print_string
    call print_newline
.done:
    ret

handler_cls:
    ; Scroll/Clear Window (AH=06h)
    mov ah, 0x06
    mov al, 0       ; 0 = Clear entire window
    mov bh, [current_attrib] ; Attribute from variable
    mov cx, 0       ; Top-Left (0,0)
    mov dx, 0x184F  ; Bottom-Right (24,79)
    int 0x10
    
    ; Reset Cursor to (0,0)
    mov ah, 0x02
    mov bh, 0
    mov dx, 0
    int 0x10
    ret

handler_color:
    ; Format: k XX (where XX is hex color)
    ; Example: k 1F (Blue background, White text)
    mov si, command_buffer
    inc si          ; Skip 'k'
    inc si          ; Skip space (assuming 'k ' format)
    
    ; Parse First Hex Digit (High Nibble)
    lodsb
    call char_to_hex
    mov bl, al
    shl bl, 4
    
    ; Parse Second Hex Digit (Low Nibble)
    lodsb
    call char_to_hex
    or bl, al
    
    ; Store new attribute
    mov [current_attrib], bl
    
    ; Apply immediately by clearing screen
    call handler_cls
    ret

char_to_hex:
    ; Input: AL (ASCII) -> Output: AL (Value 0-15)
    cmp al, '0'
    jl .done_hex
    cmp al, '9'
    jle .is_digit
    cmp al, 'A'
    jl .done_hex
    cmp al, 'F'
    jle .is_upper
    cmp al, 'a'
    jl .done_hex
    cmp al, 'f'
    jle .is_lower
    jmp .done_hex

.is_digit:
    sub al, '0'
    ret
.is_upper:
    sub al, 'A'
    add al, 10
    ret
.is_lower:
    sub al, 'a'
    add al, 10
    ret
.done_hex:
    mov al, 0
    ret

handler_time:
    mov ah, 0x02    ; Get Real-Time Clock Time
    int 0x1A        ; Returns CH=Hour, CL=Minute, DH=Second
    
    mov al, ch      ; Hour
    call print_bcd
    
    mov al, ':'
    mov ah, 0x0E
    int 0x10
    
    mov al, cl      ; Minute
    call print_bcd
    
    mov al, ':'
    mov ah, 0x0E
    int 0x10
    
    mov al, dh      ; Second
    call print_bcd
    
    call print_newline
    ret

handler_date:
    mov ah, 0x04    ; Get Real-Time Clock Date
    int 0x1A        ; Returns CX=Year, DH=Month, DL=Day
    
    mov al, ch      ; Year (Century, e.g. 20)
    call print_bcd
    mov al, cl      ; Year (Year, e.g. 23)
    call print_bcd
    
    mov al, '-'
    mov ah, 0x0E
    int 0x10
    
    mov al, dh      ; Month
    call print_bcd
    
    mov al, '-'
    mov ah, 0x0E
    int 0x10
    
    mov al, dl      ; Day
    call print_bcd
    
    call print_newline
    ret

; Helper to print BCD value in AL
print_bcd:
    push ax
    push bx
    
    mov bl, al      ; Save original BCD
    
    ; Upper Nibble (Tens)
    and al, 0xF0
    shr al, 4
    add al, '0'
    mov ah, 0x0E
    int 0x10
    
    ; Lower Nibble (Ones)
    mov al, bl
    and al, 0x0F
    add al, '0'
    mov ah, 0x0E
    int 0x10
    
    pop bx
    pop ax
    ret

handler_help:
    mov si, help_msg
    call print_string
    call print_newline
    ret

handler_echo:
    mov si, command_buffer
.echo_skip:
    lodsb
    cmp al, ' '
    je .echo_print
    cmp al, 0
    je .echo_nl
    jmp .echo_skip
.echo_print:
    call print_string
.echo_nl:
    call print_newline
    ret

handler_reboot:
    mov si, reboot_msg
    call print_string
    call print_newline
    db 0xEA, 0x00, 0x00, 0xFF, 0xFF ; Jump FFFF:0000
    ret

handler_pulse:
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
    push es
    xor ax, ax
    mov es, ax
    mov ax, [es:0x046C] 
    pop es
    call print_hex
    call print_newline
    ret

print_hex:
    push cx
    push ax
    push bx
    mov cx, 4
.loop:
    rol ax, 4
    push ax
    and al, 0x0F
    cmp al, 9
    jle .digit
    add al, 7
.digit:
    add al, '0'
    mov ah, 0x0E
    int 0x10
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
    mov al, 0x0A
    int 0x10
    mov al, 0x0D
    int 0x10
    ret

print_string:
    mov ah, 0x0E
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    ret

str_cmd_label db 'CMD: ', 0
str_arg_label db ' ARG: ', 0
welcome_msg db 'Selamat Datang di Kernel VizOS (Mode Enhanced)', 0
prompt_msg db 'VIZOS> ', 0
unknown_msg db 'Perintah tidak dikenal.', 0
help_msg db 'Perintah Tersedia: help, reboot, pulse, echo', 0
reboot_msg db 'Sistem akan dimuat ulang...', 0
pulse_header db '--- MONITOR STATISTIK HARDWARE ---', 0
pulse_cpu db 'CPU : Mode Real 16-bit (Aktif)', 0
pulse_mem db 'MEM : 640KB RAM Konvensional Terdeteksi', 0
pulse_tick db 'WAKTU NYALA (TICKS): 0x', 0
current_attrib db 0x07 ; Default White on Black


; Buffer moved to fixed address


times 1474048 - ($ - $$) db 0
