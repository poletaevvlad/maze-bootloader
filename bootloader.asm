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

    call init_prng

    mov ax, 0x0013
    int 0x10

    push 0xFFFF
    push 0xFFFF
    push 0x0000
    push 0x0000

    _loop:
        pop ax
        pop bx

        cmp ax, 0xFFFF
        je _end  ; The stack is empty

        call set_cell

        sub sp, 16
        mov si, sp

        call get_neighbours

        cmp dx, 0
        jne .iteration
        add sp, 16
        jmp _loop

        .iteration:
        push ax

        call gen_random
        xor ah, ah
        div dl

        xor al, al
        xchg ah, al

        inc ax
        shl ax, 2
        sub si, ax

        pop ax
        mov cx, [ss:si]
        mov dx, [ss:si + 2]
        call connect

        add sp, 16

        push bx
        push ax
        push dx
        push cx

    jmp _loop

    _end:

    cli
    hlt


; gen_random() -> ax
gen_random:
    push dx

    mov ax, [ds:0]
    add ax, 0x2b7f
    mov dx, 0x9f89
    mul dx
    mov [ds:0], ax

    pop dx
    ret


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


;set_cell(ax, bx)
set_cell:
    call get_offset
    mov [es:di], byte 0x50
    ret


;connect(ax, bx, cd, dx)
connect:
    pusha
    xchg ax, cx
    xchg bx, dx
    call set_cell

    cmp ax, cx
    je .connect_same_row

    add ax, cx
    shr ax, 1

    jmp .connect_end

    .connect_same_row:
    add bx, dx
    shr bx, 1

    .connect_end:
    call set_cell
    popa
    ret


;add_neighbour(ax, bx, si)
add_neighbour:
    call get_offset
    mov cl, [es:di]
    cmp cl, 0x00
    jne .add_neighbour_end

    mov [ss:si], ax
    mov [ss:si + 2], bx
    add si, 4
    inc dx

    .add_neighbour_end:
    ret


;get_neighbours(ax, bx, si) -> dx
get_neighbours:
    push cx
    xor dx, dx

    cmp bx, 0
    je .skip_left_column

    sub bx, 2
    call add_neighbour
    add bx, 2
    .skip_left_column:

    cmp ax, 0
    je .skip_top_row

    sub ax, 2
    call add_neighbour
    add ax, 2
    .skip_top_row:

    cmp bx, (SCREEN_WIDTH - 2)
    jae .skip_right_column

    add bx, 2
    call add_neighbour
    sub bx, 2
    .skip_right_column:

    cmp ax, (SCREEN_HEIGHT - 2)
    jae .skip_bottom_row

    add ax, 2
    call add_neighbour
    sub ax, 2
    .skip_bottom_row:

    pop cx
    ret


init_prng:
    mov ax, 0x0002
    int 0x1a

    mov bx, cx
    xor bl, dh

    mov ax, 0x0004
    int 0x1a
    xor bx, dx

    mov [ds:0], bx
    ret


times 510 - ($ - $$) db 0
dw 0xAA55
