; have two characters move from ends of the row at the
; center of the screen to the middle and back again
org 100h

mov ax, 0xb800
mov es, ax
jmp dancingChar

delay:
    mov cx, 64000
    badloop: loop badloop
    ret

dancingChar:
    mov di, 1920 ;center row
    mov dh, 0x07 ;black bg/white fg
    mov bp, 158  ;end offset - final column
    xor bx, bx   ;start offset - first column
    movementIn:
        mov dl, 0x07        ;dl = star
        mov [es:di+bp], dx  ;place 2 stars
        mov [es:di+bx], dx
        call delay
        mov dl, 0x20        ;dl = space
        mov [es:di+bp], dx  ;clear both stars
        mov [es:di+bx], dx
        sub bp, 2           ;adjust ptrs
        add bx, 2
        cmp bx, bp          ;exit if pts overlap
        jb movementIn
    movementOut:
        mov dl, 0x07
        mov [es:di+bp], dx
        mov [es:di+bx], dx
        call delay
        mov dl, 0x20
        mov [es:di+bp], dx
        mov [es:di+bx], dx
        add bp, 2
        sub bx, 2
        cmp bx, 0
        ja movementOut
    jmp dancingChar
