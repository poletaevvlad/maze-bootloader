%define SCREEN_WIDTH 320
%define SCREEN_HEIGHT 200

bits 16

    ; Initialization

    mov ax, 0x07C0
    mov ds, ax

    mov ax, 0x07E0
    mov ss, ax

    mov ax, 0xA000
    mov es, ax

    mov sp, 0x2000

    mov ax, 0013h
    int 10h

    push 0xFFFF
    push 0xFFFF
    push 0x0002
    push 0x0002

    _loop:
        pop ax
        pop bx

        cmp ax, 0xFFFF
        je _end  ; The stack is empty

        call set_cell

        mov cx, 4
        mov dx, 2
        call connect

    _end:

    cli
    hlt


; get_offset(ax, bx) -> di
get_offset:
    push dx
    push ax

    mov dx, SCREEN_WIDTH
    mul dx
    add ax, bx
    mov di, ax

    pop ax
    pop dx
    ret


;set_cell
set_cell:
    call get_offset
    mov [es:di], byte 0x50
    ret


;connect(ax, bx, cd, dx)
connect:
    xchg ax, cx
    xchg bx, dx
    call set_cell

    cmp ax, cx
    je .connect_same_row

    add ax, cx
    shr ax, 1

    jmp .end

    .connect_same_row:
    add bx, dx
    shr bx, 1

    .end:
    call set_cell
    ret



times 510 - ($ - $$) db 0
dw 0xAA55
