## Q1:

```nasm
mov si, 241     ; SI = 241
mov ax, 2       ; AX = 2
div si          ; DX:AX/SI, quotient in ax, remainder in dx
test dx, dx     ; AND the remainder w/ itself
                ; equivalent to `cmp dx, 0`
jne after_if    ; skip the conditional
mov [flag], 1   ; flag = 1
after_if:
```

## Q2:

```nasm
    swapBack:
        mov dx, word [arr+si]       ; dx = new word
        cmp dx, word [arr+si-2]     ; cmp {this}, {this-1}
        jnb swapsOver               ; if {this} is not smaller, no swaps needed

        mov cx, word [arr+si-2]     ; cx = {this-1}
        mov word [arr+si], cx       ; {this} = cx
        mov word [arr+si-2], dx     ; {this-1} = {this}

        sub si, 2                   ; si -= 2
        jmp swapBack
    swapsOver:
```

NOTE: usage of the `xchg` instruction to solve this question is also allowed; in fact, it is encouraged.

## Q3:

Yes, because it could get replaced with the bitwise operation `x & 1`, which is a single-clock `AND`; much cheaper than using a `DIV`
