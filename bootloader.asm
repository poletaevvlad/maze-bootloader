%define SCREEN_WIDTH 320
%define SCREEN_HEIGHT 200
%define KBD_INTERRUPT 0x09

bits 16

    jmp 0x7C0:start

    start:
    mov ax, 0x07C0
    mov ds, ax

    mov ax, 0x07E0
    mov ss, ax

    mov ax, 0xA000
    mov es, ax

    mov sp, 0x2000

    cli
    mov ax, 0x0000
    mov fs, ax
    mov [fs:(KBD_INTERRUPT * 4)], word kbd_interrupt
    mov [fs:(KBD_INTERRUPT * 4 + 2)], cs

    call init_prng

    mov ax, 0x0013
    int 0x10
    call init_color_palette

    call create_maze
    sti

    .inf_loop:
        mov dx, 0x03DA
        in al, dx
        and al, 0x08
        jz .inf_loop

        mov al, [ds:color_offset]
        dec al
        mov [ds:color_offset], al
        call init_color_palette
        xor bx, bx

        .wait_for_non_vblank:
        mov dx, 0x03DA
        in al, dx
        and al, 0x08
        jz .wait_for_non_vblank

        mov ah, 0x86
        mov cx, 0x01
        mov dx, 0x00
        int 0x15
    jmp .inf_loop


create_maze:
    push 0xFFFF
    push 0xFFFF
    push 0x0000
    push 0x0000

    xor ax, ax
    xor bx, bx
    call set_cell

    .create_loop:
        pop ax
        pop bx

        cmp ax, 0xFFFF
        je .create_end  ; The stack is empty

        sub sp, 16
        mov si, sp

        call get_neighbours

        cmp dx, 0
        jne .iteration
        add sp, 16
        jmp .create_loop

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

    jmp .create_loop

    .create_end:
    ret

; gen_random() -> ax
gen_random:
    push dx

    mov ax, [ds:rng_state]
    add ax, 0x2b7f
    mov dx, 0x9f89
    mul dx
    mov [ds:rng_state], ax

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
    push ax

    call get_offset
    mov al, [ds:color]

    inc al
    cmp al, 0x40
    jb .skip_set_0
    mov al, 1
    .skip_set_0:

    mov [es:di], al
    mov [ds:color], al

    pop ax
    ret


;connect(ax, bx, cd, dx)
connect:
    pusha

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

    mov ax, cx
    mov bx, dx
    call set_cell
    popa
    ret


;add_neighbour(ax, bx, si)
add_neighbour:
    call get_offset
    push cx

    mov cl, [es:di]
    cmp cl, 0x00
    jne .add_neighbour_end

    mov [ss:si], ax
    mov [ss:si + 2], bx
    add si, 4
    inc dx

    .add_neighbour_end:
    pop cx
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

    mov [ds:rng_state], bx
    ret


clear_screen:
    xor si, si
    mov al, 0
    .clear_loop:
        mov [es:si], al
        inc si
    cmp si, (SCREEN_WIDTH * SCREEN_HEIGHT)
    jb .clear_loop
    ret


kbd_interrupt:
    cli
    pusha

    in al, 0x60
    cmp al, 0x39
    jne .finish

    call clear_screen
    call create_maze

    .finish:

    mov al, 0x20
    out 0x20, al

    popa
    sti
    iret


init_color_palette:
    xor ax, ax
    mov dx, 0x03C8
    out dx, al
    inc dx

    xor al, al
    out dx, al
    out dx, al
    out dx, al

    xor bx, bx
    mov cl, [color_offset]
    .palette_loop:
        xor al, al
        out dx, al

        mov al, bl
        add al, cl
        and al, 0x3f
        out dx, al

        xor al, al
        out dx, al

        inc bx
        cmp bx, 0x40
    jne .palette_loop
    ret


color_offset db 0x00
color db 0x00
rng_state dw 0x0000

times 510 - ($ - $$) db 0
dw 0xAA55
