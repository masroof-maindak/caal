; Print a rectangle with dimensions passed as arguments
org 100h

jmp start

printRect:
    push bp
    mov bp, sp
    pusha

    mov ax, 0xb800
    mov es, ax

    ;dimensions
    mov ax, [bp+4]
    mov cx, [bp+6]

    mov dx, 0x0730  ;dx = ascii 0
    mov di, 3998    ;di = bottom right pixel

    outer:
        xor bx, bx      ;bx = 0
        inner:
            mov [es:di], dx
            inc bx
            sub di, 2   ;decrement 'pixel'
            cmp bx, ax
            jne inner
        sub di, 160     ;decrement row
        add di, bx
        add di, bx      ;go to final column of rectangle
        loop outer

    popa
    pop bp
    ret

start:
    push 10
    push 5
    call printRect

    mov ax, 4c00h
    int 21h
