; Program to toggle a stopwatch by pressing left shift
; Peak
org 100h

jmp start

; Timekeeping
ticks: dd 0
seconds: dw 0
minutes: dw 0
hours: dw 0

; Flags
timerFlag: dw 0
terminateFlag: dw 0

; Store original ISRs
oldkb: dd 0
oldtt: dd 0

printnum:
    push bp
    mov bp, sp
    pusha

    mov ax, 0xb800
    mov es, ax             ; point es to video base

    mov ax, [bp+4]         ; load number in ax
    mov bx, 10             ; use base 10 for division
    mov cx, 0              ; initialize count of digits

    nextdigit:
        mov dx, 0              ; zero upper half of dividend
        div bx                 ; divide by 10
        add dl, 0x30           ; digit -> ascii
        push dx                ; save ascii value on stack
        inc cx                 ; increment count of values

        cmp ax, 0              ; is the quotient zero
        jnz nextdigit          ; if not, divide it again

		push 0
		inc cx
        mov di, 140            ; point di to 70th column + offset
        add di, [bp+6]
    nextpos:
        pop dx                 ; remove a digit from the stack
        mov dh, 0x07           ; blk BG/wht FG
        mov [es:di], dx        ; print char on screen
        add di, 2              ; move to next screen location
        loop nextpos

        popa
        pop bp
        ret 4

; Keyboard ISR - called every time a key is pressed
KB_ISR:
    push ax
    in al, 0x60

	is_lctrL:
    cmp al, 29
    jne is_esc
    xor word [timerFlag], 1
	jmp exit_kb_isr

    is_esc:
    cmp al, 0x01
	jne goto_original_kb_isr
    mov word [terminateFlag], 1
	jmp exit_kb_isr
	
    goto_original_kb_isr:
	pop ax
	jmp far [cs:oldkb]

	exit_kb_isr:
    mov al, 0x20
    out 0x20, al
    pop ax
    iret

; tick timer ISR - called 18.2 times every second
TT_ISR:
    push ax
    cmp word [timerFlag], 1
    jne exit_timer_isr

    ; time b/w 2 ticks = 0.0549254s = 54.92ms
    ; 1 second = 1000ms = 100,000 xs where 1 xs is a ms * 100
	; We do this to convert 54.92 to 5492, allowing for greater precision

    ; so now, all we need to do is check if 'ticks' has surpassed
    ; 100,000, and if it has, reset it while incrementing seconds

	; Increment ticks & seconds
	add dword [ticks], 5492
	cmp dword [ticks], 100000
	jnae no_more_increments
	inc word [seconds]
	sub dword [ticks], 100000
	; I could (should)  do this with `div`
	; Not that it matters really

	; Inc minute if 60 seconds
	cmp word [seconds], 60
	jne no_more_increments
	inc word [minutes]
	mov word [seconds], 0

	; Inc hour if 60 minutes
	cmp word [minutes], 60
	jne no_more_increments
	inc word [hours]
	mov word [minutes], 0

	; TODO: clear the '9' left behind from the 59th s or m
	; prior to incrementing them or modify the printnum
	; subroutine to print a zero before single-digit numbers

    no_more_increments:
        push word 0xE
        push word [seconds]
        call printnum

        push word 0x8
        push word [minutes]
        call printnum

        push word 0x0
        push word [hours]
        call printnum

    exit_timer_isr:
        mov al, 0x20
        out 0x20, al
        pop ax
        iret

start:
    ; es = 0 (IVT)
    xor ax, ax
    mov es, ax

    ; Store original ISRs
    mov eax, [es:8*4]
    mov dword [oldtt], eax
    mov eax, [es:9*4]
    mov dword [oldkb], eax

    ; Hook keyboard and timer w/ our ISRs
    cli
    mov word [es:8*4+2], cs
    mov word [es:9*4+2], cs
    mov word [es:8*4], TT_ISR
    mov word [es:9*4], KB_ISR
    sti

	; Busy wait till user says they're done
    termination_check:
        cmp word [terminateFlag], 1
        jne termination_check

	; Recover original ISRs
	cli
	mov eax, [cs:oldkb]
	mov dword [es:9*4], eax
	mov eax, [cs:oldtt]
	mov dword [es:8*4], eax
	sti

	; Terminate gracefully
	mov ax, 4c00h
	int 21h
