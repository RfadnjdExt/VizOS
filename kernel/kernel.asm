[BITS 16]
[ORG 0x7C00]

start:
    xor ax, ax
    mov ds, ax
    mov es, ax

    mov si, welcome_msg
    call print_string

    call print_newline
    call print_prompt

    ; Initialize buffer index
    mov di, command_buffer
    xor cx, cx          ; CX will act as counter

shell_loop:
    mov ah, 0x00
    int 0x16

    cmp al, 0x0D        ; Enter key
    je .handle_enter

    cmp al, 0x08        ; Backspace
    je .handle_backspace

    ; Store char
    stosb
    inc cx
    
    mov ah, 0x0E
    int 0x10
    jmp shell_loop

.handle_backspace:
    cmp cx, 0
    je shell_loop
    dec di
    dec cx
    mov ah, 0x0E
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    jmp shell_loop

.handle_enter:
    mov al, 0
    stosb               ; Null terminate
    
    call print_newline
    call visualize_parsing  ; <--- NEW Viz Feature
    call process_command
    
    ; Reset buffer
    mov di, command_buffer
    xor cx, cx
    
    call print_prompt
    jmp shell_loop

visualize_parsing:
    mov si, str_cmd_label
    call print_string
    
    mov si, command_buffer
.cmd_loop:
    lodsb
    cmp al, 0
    je .no_arg
    cmp al, ' '
    je .found_space
    mov ah, 0x0E
    int 0x10
    jmp .cmd_loop

.found_space:
    mov si, str_arg_label
    call print_string
.print_arg:
    lodsb
    cmp al, 0
    je .done_viz
    mov ah, 0x0E
    int 0x10
    jmp .print_arg

.no_arg:
    ; No argument, just newline
.done_viz:
    call print_newline
    ret

process_command:
    ; Check if empty
    mov al, [command_buffer]
    cmp al, 0
    je .done

    ; Smart/Lazy Matching (Prefix)
    cmp al, 'h' ; matches 'help', 'hel', 'h'
    je .is_help
    
    cmp al, 'r' ; matches 'reboot', 'r'
    je .is_reboot
    
    cmp al, 'p' ; matches 'pulse', 'pul', 'p'
    je .is_pulse

    mov si, unknown_msg
    call print_string
    call print_newline
.done:
    ret

.is_help:
    mov si, help_msg
    call print_string
    call print_newline
    ret

.is_reboot:
    mov si, reboot_msg
    call print_string
    call print_newline
    ; Reboot logic (Warm boot)
    db 0xEA             ; JMP FAR
    dw 0x0000           ; Offset
    dw 0xFFFF           ; Segment (BIOS Reset Vector)
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
    
    ; Show dynamic timer tick (heartbeat)
    mov si, pulse_tick
    call print_string
    
    ; Read BIOS Timer Count (0x0040:0x006C) - assuming DS=0, address 0x046C
    mov ax, [0x046C] 
    call print_hex
    
    call print_newline
    ret

; Print AX as 4 Hex digits
print_hex:
    push cx
    push ax
    push bx
    mov cx, 4       ; 4 nibbles
.loop:
    rol ax, 4       ; Rotate left 4 bits
    push ax
    and al, 0x0F    ; Mask lower nibble
    cmp al, 9
    jle .digit
    add al, 7       ; Adjust for A-F
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
    
str_cmd_label db 'CMD:', 0
str_arg_label db ' ARG:', 0

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

welcome_msg db 'MyShell OS', 0
prompt_msg db 'MyS> ', 0
unknown_msg db 'Error', 0
cmd_help_str db 'help', 0
cmd_reboot_str db 'reboot', 0
cmd_pulse_str db 'pulse', 0
help_msg db 'CMD: help, reboot, pulse', 0
reboot_msg db 'Reset...', 0
pulse_header db 'MONITOR:', 0
pulse_cpu db 'CPU: 16-bit', 0
pulse_mem db 'MEM: 640KB', 0
pulse_tick db 'TICK: 0x', 0

; Define buffer at 0x7E00 (just after boot sector)
command_buffer equ 0x7E00

times 510-($-$$) db 0
dw 0xAA55

