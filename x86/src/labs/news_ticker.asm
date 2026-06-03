; Program that displays a news ticker on the bottom row
org 100h
jmp start

tickerString: db 'Mujtaba'
stringSize: dw 7

Delay:
    push cx
    mov cx, 65535
    a: loop a
    mov cx, 65535
    b: loop b
    mov cx, 65535
    c: loop c
    pop cx
    ret

newsTicker:
    push bp
    mov bp, sp
    pusha

    mov ax, 0xb800  ;point es to video
    mov es, ax

    ;Place the string on the bottom left of the screen
    cld
    mov ah, 0x07
    mov cx, [bp+6] ; cx = size
    mov si, [bp+4] ; si = string
    mov di, 3840   ; di = bottom left
    prntr0:
        lodsb      ;load string byte from si into al
        stosw      ;store string word in ax at es:di
        loop prntr0

    ;movement preparation
    mov ax, 0xb800
    mov ds, ax     ;point ds to video
    mov bx, 3840   ;bx = bottom left
    mov ah, 0x07
    std

    mover:
        mov si, bx
        mov cx, [bp+6]

        add si, cx
        add si, cx
        inc cx

        mov di, si
        add di, 2

        ;si = end of word
        ;di = end of word + 1
        rep movsw   ; 'mov string word cx times'

        ;clear the first index
        sub di, 2
        mov al, 0x20
        stosw

        ;next index
        call Delay
        add bx, 2
        cmp bx, 4000
        jne mover
	
    ; Clear the one character left
    mov di, 3998
    stosw

    popa
    pop bp
    ret 4

start:
    push word [stringSize]  ;push string size
    mov ax, tickerString
    push ax                 ;push word address

    call newsTicker

    mov ax, 4c00h
    int 21h
