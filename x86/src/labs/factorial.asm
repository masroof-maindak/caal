; factorial of the integer in 'arg'
org 100h

mov ax, [arg]
cmp ax, 1               ;if arg==0 or arg==1
jbe end                 ;exit. default ans = 1.

mov [op1], ax           ;op1 = arg
dec ax
mov [op2], ax           ;op2 = arg-1

start:
    mov cx, ax          ;cx = op2
    mov ax, [op1]       ;ax = op1
    mult: add [tmp], ax ;tmp = op1*op2
    loop mult

    mov ax, [tmp]       ;ans = tmp
    mov [ans], ax
    mov bx, tmp         ;clr tmp (next run)
    mov [bx], cx

    mov [op1], ax       ;op1 = ans
    mov ax, [op2]       ;op2--
    dec ax
    mov [op2], ax

    cmp ax, 0           ;if op2==0, exit
    jne start

end:
    mov ax, 4c00h
    int 21h

arg: dw 4
op1: dw 0
op2: dw 0
tmp: dw 0
ans: dw 1
