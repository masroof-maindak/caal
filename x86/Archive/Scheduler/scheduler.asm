; Scheduler
; This code isn't complete/functional strictly speaking but is well-documented
; and contains extensive instructions and guidance towards completion/a deeper
; understanding of developing a userspace multi-tasking 'kernel'

org 0x100
jmp start

oldtt: dd 0
old21: dd 0

PCB: times 32*16 db 0     ; process control block - for 32 bytes/thread
stacks: times 512*16 db 0 ; 512 bytes per stack per program
currproc: dw 0            ; PCB number of currently active process
threadcount: dw 1         ; no. of active threads (i.e free flag != 1)

; Structure of one chunk in the PCB:
;  02 bytes - prev/next indexes
;  01 byte  - free flag (i.e current PCB is not dead)
;  01 byte  - priority
;  28 bytes - general purpose registers

LL_SAVE: EQU 0
FREE_FLAG: EQU 2
PR_SAVE: EQU 3
AX_SAVE: EQU 4
BX_SAVE: EQU 6
CX_SAVE: EQU 8
DX_SAVE: EQU 10
SI_SAVE: EQU 12
DI_SAVE: EQU 14
BP_SAVE: EQU 16
SP_SAVE: EQU 18
CS_SAVE: EQU 20
DS_SAVE: EQU 22
ES_SAVE: EQU 24
SS_SAVE: EQU 26
FLAG_SAVE: EQU 28
IP_SAVE: EQU 30

; @brief receives current process in ax
; @return (in ax) the next PCB's number
get_next:
    ; Priority handling?
    ; Maintain another global variable for the current tick count (init w/ 0)
    ; If the tick count is equal to the currproc's priority, then reset it and get
    ; the next free PCB; else, increment tick count (can be optimised further to
    ; prevent unnecessary restores)

    ; TODO: ignore processes that are suspended!
    mov bx, ax
    shl bx, 5
    mov ax, [PCB+LL_SAVE+bx]
    and ax, 0x00FF  ; to discard the 'prev' pointer ; CHECK: why did I do this?
    ret

; @brief loops through all PCBs and finds the first free one
; @return PCB's number (in ax), or 0xFF if no free entry
; NOTE: can't use PCB #0 (as it belongs to the mother process)
get_free_pcb:
    ; TODO
    ret

receive_ret:
    ; This function exists to serve as a fake 'return address'
    ; Reached via retf from user's subroutine (whether maliciously or accidentally)
    ; TODO: have this delete the thread that landed into it ?
    ret

; Receives PCB entry to insert into the dispatcher (linked list) via ax
insert_thread:
    push ax
    mov bx, ax               ; bx = new
    shl bx, 5                ; bx = new's PCB

    xor ax, ax               ; ax = 0
    call get_next            ; ax = 0:0's next
    mov [PCB+LL_SAVE+bx], ax ; new's prev|next = 0|0's next
    mov bx, ax;              ; bx = 0's next
    shl bx, 5;               ; bx = 0's next's PCB

    pop ax                        ; ax = new
    mov byte [PCB+LL_SAVE+bx], al ; 0's next's prev = new
    mov byte [PCB+LL_SAVE+1], al  ; 0's next = new
    ret

; @brief receives pcb # to init in ax.
; @detail it cleans up the registers, copies over the argument's address to the stack
; and sets a fake return address
init_pcb:
    
    push bp
    mov bp, sp
    push ax
    push si
    push bx

    ; At this point, we expect the following stack layout:
    ;
    ;   | BX                     | -6
    ;   | SI                     | -4
    ;   | AX                     | -2
    ; ->| BP (Original)          |  <-BP
    ;   | IP (int21 -> init_pcb) | +2
    ;   | IP    }                | +4
    ;   | CS    } int21          | +6
    ;   | FLAG  }                | +8
    ;   | offset    } entrypoint | +10
    ;   | segment   }            | +12
    ;   | offset    } void* arg  | +14
    ;   | segment   }            | +16
    ;   |________________________|


    ; bx to access PCBs
    mov bx, ax
    shl bx, 5

    ; si to access stacks
    mov si, ax
    shl si, 9
    add si, 510 ; move to bottom

    ; Init general purpose registers
    xor ax, ax
    mov byte [PCB+FREE_FLAG+bx], al
    mov byte [PCB+PR_SAVE+bx], al
    mov word [PCB+AX_SAVE+bx], ax
    mov word [PCB+BX_SAVE+bx], ax
    mov word [PCB+CX_SAVE+bx], ax
    mov word [PCB+DX_SAVE+bx], ax
    mov word [PCB+SI_SAVE+bx], ax
    mov word [PCB+DI_SAVE+bx], ax
    mov word [PCB+BP_SAVE+bx], ax
    mov word [PCB+DS_SAVE+bx], ax
    mov word [PCB+ES_SAVE+bx], ax
    mov word [PCB+FLAG_SAVE+bx], 0x0200 ; ensure interrupt flag is high
    mov word [PCB+SS_SAVE+bx], stacks   ; start of all contiguous stacks

    ; get thread's entrypoint from the stack
    mov ax, [bp+10]
    mov [PCB+IP_SAVE+bx], ax
    mov ax, [bp+12]
    mov [PCB+CS_SAVE+bx], ax

    ; 'push' a pointer to thread's intended argument (i.e a 'void* arg'
    ; that the thread's start routine can then parse as per its logic)
    ; to its newly allocated stack
    mov ax, [bp+16]
    mov word [stacks+si], ax
    sub si, 2
    mov ax, [bp+14]
    mov word [stacks+si], ax
    sub si, 2

    ; 'push' the segment and address of where the program should go
    ; if it calls for a 'ret far'
    ; The purpose is to NOT let an arbitrary ret in the function go to a random
    ; address as that could result in undefined behaviour
    mov [stacks+si], cs
    sub si, 2
    mov [stacks+si], receive_ret

    ; Init stack pointer
    mov [PCB+SP_SAVE+bx], si

    ; Thread's newly allocated stack:
    ;
    ;  | ret addr offset   | 504
    ;  | ret addr segment  | 506
    ;  | void* arg offset  | 508
    ;  | void* arg segment | 510
    ;  |___________________|

    pop bx
    pop si
    pop ax
    pop bp
    ret

int08isr:
    push bx
    mov bx, [currproc]
    shl bx, 5

    ; 1. SAVE STATE
    ; general purpose registers
    mov word [PCB+AX_SAVE+bx], ax
    pop ax
    mov word [PCB+BX_SAVE+bx], ax
    mov word [PCB+CX_SAVE+bx], cx
    mov word [PCB+DX_SAVE+bx], dx
    mov word [PCB+SI_SAVE+bx], si
    mov word [PCB+DI_SAVE+bx], di
    mov word [PCB+BP_SAVE+bx], bp
    mov word [PCB+DS_SAVE+bx], ds
    mov word [PCB+ES_SAVE+bx], es

    ; iret relevant registers
    pop ax
    mov word [PCB+IP_SAVE+bx], ax
    pop ax
    mov word [PCB+CS_SAVE+bx], ax
    pop ax
    mov word [PCB+FLAG_SAVE+bx], ax

    ; stack relevant registers
    mov word [PCB+SS_SAVE+bx], ss
    mov word [PCB+SP_SAVE+bx], sp

    ; 2. Get ID of the next process
    mov ax, [currproc]
    call get_next
    mov word [currproc], ax
    mov bx, ax

    ; 3. RESTORE STATE
    ; stack registers
    cli
    mov ax, [PCB+SS_SAVE+bx]
    mov ss, ax
    mov ax, [PCB+SP_SAVE+bx]
    mov sp, ax
    sti

    ; iret relevant registers
    mov ax, [PCB+FLAG_SAVE+bx]
    push ax
    mov ax, [PCB+CS_SAVE+bx]
    push ax
    mov ax, [PCB+IP_SAVE+bx]
    push ax

    ; General purpose registers
    mov cx, [PCB+CX_SAVE+bx]
    mov dx, [PCB+DX_SAVE+bx]
    mov si, [PCB+SI_SAVE+bx]
    mov di, [PCB+DI_SAVE+bx]
    mov bp, [PCB+BP_SAVE+bx]
    mov ds, [PCB+DS_SAVE+bx]
    mov es, [PCB+ES_SAVE+bx]

    ; EoI + restore ax & bx + leave
    mov al, 0x20
    out 0x20, al
    mov ax, [PCB+AX_SAVE+bx]
    mov bx, [PCB+BX_SAVE+bx]
    iret

int21isr:
    ; TODO: check if ah == 4c
    ; if so, then clean up all active threads before jumping to the oldINT21

    ; exit if not 4b
    cmp ah, 0x4b
    jne oldINT21

    ; exit if below 10
    cmp al, 0x10
    jb oldINT21

    createCheck:
        cmp al, 0x10
        jne deleteCheck
        ;check thread count and exit if >= 16
        call get_free_pcb  ; ax = available PCB
        call init_pcb      ; initialize it
        call insert_thread ;
        add word [thread_count], 1
        iret 8 ; Clean user args (entrypoint & void* segment-offset pair)

    deleteCheck: ; remove from dispatcher + set 'free' flag
        cmp al, 0x11
        jne suspendCheck
        ; if trying to delete '0' or >= 16, exit
        call delete_thread ; remove the thread from the thread 'chain' and set 'used' to false
        sub word [thread_count], 1
        jmp exitINT21

    suspendCheck: ; remove from dispatcher (w/o modifying the free flag)
        cmp al, 0x12
        jne resumeCheck
        ; if trying to suspend TID '0' or TID >= 16, exit
        call suspend_thread ; trivially set the suspend flag to true
        jmp exitINT21

    resumeCheck: ; Shrimply insert the thread back into the linked list (dispatcher)
        cmp al, 0x13
        jne oldINT21
        ; if trying to resume TID '0' or TID >= 16, exit
        call resume_thread

    exitINT21:
        ; TODO: ax should have 0xFF for failure, 0xEE (or PCB no. if insert) for success
        iret

    oldINT21:
        jmp [old21]

start:
    xor ax, ax
    mov es, ax

    ; store original ISRs
    mov eax, [es:8*4]
    mov dword [oldtt], eax
    mov eax, [es:21*4]
    mov dword [old21], eax

    ; Replace ISRs
    cli
    mov word [es:8*4+2], cs
    mov word [es:8*4], int08isr
    mov word [es:21*4+2], cs
    mov word [es:21*4], int21isr
    sti

    ; TSR
    mov dx, start
    add dx, 15
    mov cl, 4
    shr dx, cl
    mov ax, 3100h
    int 21h
