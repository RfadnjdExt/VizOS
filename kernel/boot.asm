[BITS 16]
[ORG 0x7C00]

start:
    ; Setup Stack
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    mov si, boot_msg
    call print_string

    ; Reset Disk System
    mov ah, 0
    mov dl, 0 ; Drive 0 (Floppy)
    int 0x13
    jc disk_error

    ; Load Kernel from Disk
    ; Read to ES:BX = 0x1000:0000
    mov ax, 0x1000
    mov es, ax
    xor bx, bx
    
    mov ah, 0x02    ; Read Sectors
    mov al, 10      ; Read 10 sectors (plenty of space)
    mov ch, 0       ; Cylinder 0
    mov cl, 2       ; Sector 2 (Sector 1 is bootloader)
    mov dh, 0       ; Head 0
    mov dl, 0       ; Drive 0
    int 0x13
    jc disk_error

    mov si, success_msg
    call print_string
    
    ; Jump to Kernel (0x1000:0000)
    jmp 0x1000:0000

disk_error:
    mov si, error_msg
    call print_string
    jmp $

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

boot_msg db 'MyShell Bootloader...', 0Ah, 0Dh, 0
success_msg db 'Kernel Loaded!', 0Ah, 0Dh, 0
error_msg db 'Disk Error!', 0

times 510-($-$$) db 0
dw 0xAA55
