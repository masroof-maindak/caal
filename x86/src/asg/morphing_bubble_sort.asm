; 4 bubble sorts in one
org 100h

start:
    mov bl, [sortIdx]  ; exit if option out of bounds
    cmp bl, 3
    ja end

    mov al, [sorts+bx] ; write selected sorttype to jmpOp
    mov [jmpOp], al

outer:
	xor bx, bx		   ; reset bx and swap bool
    mov [swapBool], bx

inner:
    mov al, [arr+bx]
    cmp al, [arr+bx+1] ; cmp i and i+1
    call jmpOp         ; conditional jump based on sortIdx

swap:
    mov ah, [arr+bx+1] ; swap i and i+1
    mov [arr+bx+1], al
    mov [arr+bx], ah
    mov ax, 1
    mov [swapBool], ax ; indicate swap has been made

inorder:               ; values are now in order
    add bx, 1          ; inc pointer of array
    cmp bl, [size]
    jne inner          ; loop again if not at end

    mov ax, [swapBool]
    cmp ax, 1
    je outer           ; loop outer if swap happened

end:
    mov ax, 4c00h
    int 21h

jmpOp:   dw 0xE700
; E7 is the number of bytes we need to move (in this
; case, it's -0x23/(24?). The '00' is where the correct jump
; we want gets written (i.e one of 76/73/7E/7D). This propels
; us back to the first instruction after the 'inorder' label
; i.e no swap was required and we go directly back there.

; BUT
; if the entries in the array at that index are OUT of order,
; then after the call, the jump will fail, thus, we shall need
; to swap, for which we shall need to go back to the swap label
jmp swap

;my dumbass did not know about ret at this point in time

sorts:    db 0x76, 0x73, 0x7E, 0x7D ; j[be,ae,le,ge]
sortIdx:  db 0
arr:      db 4, 14, 125, 22, 81, 23, 12, 8, 10, 1
size:     db 9       ; size of arr minus 1
swapBool: db 0
