	;   switches the stack to a new location
	org 100h

	jmp start

stackBottom:
	dw 0xFFFC; curr stack's bottom (where first value gets pushed)

switchStack:
	push bp
	mov  bp, sp

	pushf
	push si
	push bx

	mov bx, sp; bx = top
	sub bx, 2; so the final element is included
	mov si, [stackBottom]; si = bottom

	mov sp, [bp+4]; sp = newSP
	mov word [stackBottom], sp
	sub word [stackBottom], 2
	mov ss, [bp+6]; ss = newSS

copyStackFrame:
	push word [si]; add element from old stack
	sub  si, 2; move up on the old stack
	cmp  si, bx; if top == bottom, exit
	jne  copyStackFrame; else, grab another element

	pop bx
	pop si
	popf
	pop bp
	ret 4

start:
	push 0x2341
	push word 0x0500; new stack segment
	push word 0x1000; new stack offset
	call switchStack
	pop  cx

	mov ax, 0x4c00
	int 21h
