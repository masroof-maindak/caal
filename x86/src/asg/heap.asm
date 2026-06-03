; heap allocator - 80 bytes, 400 bits
; alloc - make that many consecutive bits 1
; free - makes that many bits, at that starting index, 0
org 100h

;REAL DECLARATIONS
jmp start
bitfield: times 50 db 0 ; 400 bits for actual data
db 0xFF, 0xFF           ; used to stop the insertion sort in swapBack

freeChunks: dw 0, 400   ; 15 words/240 bits for info
times 14 dw 0           ; 1st word is starting idx, 2nd is length
db 0xFF, 0xFF           ; signifying the end, for self-reference.

;TESTING FREE:
; jmp start
; bitfield: times 4 db 0xFF
; times 50 db 0
; db 0xFF, 0xFF
; freeChunks: dw 32, 368
; times 14 dw 0
; db 0xFF, 0xFF

alloc:
    push bp
    mov bp, sp
    push bx
    push dx
    push si
    push cx

    push 0xEE      ; exit code in case allocation fails
    mov ax, [bp+4] ; ax = number of bits to allocate

    ;now we must find a chunk of reasonable size from freeChunks
	xor bx, bx
    checkIfFits:
        cmp word [freeChunks+bx+2], ax ;cmp the 2nd byte of the chunk's word with ax
        ;if available space is more or equal to my need, I can exit here
        jae soIFit
        ;if not, I might be 'out of bounds' now, i.e there's no free space left
        ;and I should exit the program. but how to check if I'm out of bounds?
        ;well if the current chunk I encountered nudged me past the boundary of 400,
        ;then I must be out of bounds and no longer have any free space to write to
        mov dx, word[freeChunks+bx]     ;mov starting idx to dx
        add dx, word[freeChunks+bx+2]   ;add length to idx
        cmp dx, 400
        jae onesDone            ;if dx >= 400, leave
        add bx, 4               ;if not, check the next info chunk
        jmp checkIfFits

    soIFit:
        ;if I reach here, it means that I've found a chunk that can hold
        ;the number of bits I want to tweak
        ;so lets modify this chunk's entry in my freeChunks array

        ;first, let's 'waste' the exit code we pushed earlier in case alloc failed
        add sp, 2

        push word [freeChunks+bx] ;store what bit this good chunk starts at

        ;we need to subtract the chunk length, since it's going to be reduced
        sub word [freeChunks+bx+2], ax

        ;[[now intuitively, if, after the subtraction, the byte denoting length
        ;hits 0, we should remove it, but that would require shifting every value
        ;that comes after this chunk back two words so I shan't be doing that.]]

        ;we must also 'forward' the bit index by the number of bits we will fill
        add word [freeChunks+bx], ax

        pop bx ;bx = offset from the start of 'bitfield', from where we must place 1

        ;with the freeChunks modified, I can now feel free to shift my focus
        ;to the actual bitfield and turning 0s to 1s

        ;Currently,
		;	ax houses the number of bits I want to turn 1
        ;	bx holds the offset from from where I need to start turning bits 1

        ;since my granularity is that of a byte,
        ;I must first load the BYTE which contains BIT # bx
        ;how can I get this byte though? Keep counting up,
        ;starting from 0, while the startIdx > 8

    push bx ;since we are required to return the first bit's index in ax

	xor si, si
    getStartByteNumber:
        cmp bx, 8
        ;if the starting index is less than 8, that means we're at the right byte
        jb correctStartByteAcquired
        ;if not, we must increment byte number, and remove that many bits from bx
        inc si
        sub bx, 8
        jmp getStartByteNumber

    correctStartByteAcquired:
        xchg bx, si ; unnecessary, I just mistakenly wrote all the code after this
		; assuming they weren't exchanged and didn't want to refactor it all

    ;Now:
    ;   1. bx = in bitfield, pick up a byte AFTER this many bytes
    ;   2. si = in the byte above, offset after which we will pick a bit
    ;   3. ax = make this many bits, starting from bit #si in byte #bx, 1

	; NOTE: There're better ways to do this but in my infinite wisdom, I
	; to decided generate a mask register using shifts and rotates, but
	; fuck it, I'm not changing anything now.
    turningToOne:
        ;if no more bits left to turn to 1, leave function
        cmp ax, 0
        jna onesDone

        xor dl, dl ;reset 'mask' from previous iteration

        ;if ax < 8, then we need to turn some bits on the LEFT side of the byte 1
        ;this also means that it HAS to be the final byte

        ; if it is the final byte, put the number of bits we need to shift into cx
        ; if it turns out to not be the final byte, we mov into cx again anyway
        mov cx, ax
        cmp ax, 8
        jb generateDLmaskFinalByte

        ;if ax >= 8, then we need to convert either the right most couple bits
        ;(first byte) or all 8 bits (middle/first/last byte)

        ; cx = (number of bits in this byte to turn 1) = 8 - si
        ; where si = starting index of bit in this byte
        mov cx, 8
        sub cx, si

        sub ax, cx ;since we will be 'enabling' cx many bits, and ax is the no. of bits left

        generateDLmaskNonFinal:
            stc
            rcl dl, 1
            loop generateDLmaskNonFinal

        ;xor the byte from memory (bitfield+bx) with the mask (dl)
        xor [bitfield+bx], dl

        ;after the mask has been generated, then for the FOLLOWING byte
        ;we must start from the very BEGINNING, i.e bit #0, therefore
        inc bx
		xor si, si
        jmp turningToOne

        generateDLmaskFinalByte:
            stc
            rcr dl, 1
            loop generateDLmaskFinalByte

        ;xor the byte from memory (bitfield+bx) with the mask (dl)
        xor [bitfield+bx], dl

    onesDone:
        pop ax
        pop cx
        pop si
        pop dx
        pop bx
        pop bp
        ret 2

free:
    push bp
    mov bp, sp
    push bx
    push dx
    push si
    push cx

    mov ax, [bp+4] ; number of bits to free
    mov bx, [bp+6] ; index of first bit

    ;if the region we are being asked to free overlaps with a free chunk, we exit
    mov si, 0
    mov cx, 0 ; prevFreeChunksEndingIndex
    checkForOverlap:
        ;CASE 1: the ending index of the region I want to free is
        ;greater than or equal to the start index of this free chunk
        ;i.e region to free overlaps with the start of a free chunk
        add bx, ax                      ;bx = endIdx (of region to free)
        mov dx, word[freeChunks+si]     ;dx = startIdx (of free chunk)
        cmp bx, dx
        jae prematureExit

        ;CASE 2: the starting index of a region I want to free is
        ;less than the end index of the free chunk BEHIND me (brain grew 2x)
        ;i.e region to free overlaps with the end of a free chunk
        sub bx, ax                      ;bx = startIdx (of region to free)
        cmp bx, cx
        jb prematureExit

        ;if we're here, no prematureExit was taken and we should make dx
        ;this freeChunks' ending index + update cx for the next iteration
        add dx, word[freeChunks+si+2]
        mov cx, dx

        ;if dx hit 400 post addition, there can be no more
        ;freeChunks left, since we sort them as we go along
        cmp dx, 400
        add si, 4      ;need to do this regardless whether we loop around or jae
        jae noOverlap

        ;repeat w/ next chunk
        jmp checkForOverlap

    noOverlap:
    ;if we reach here, it means the chunk we're going to free is a valid one
    ;so let's make an addition to the freeChunks memory location

        ;dx has crossed 400 (since that is the only way to get here)
        ;si is pointing to the byte after the last freeChunk

        ;so let's plop down our newly created free chunk here
        ;and safely and head over to swapBack
        mov word [freeChunks+si], bx    ;start index
        mov word [freeChunks+si+2], ax  ;length of chunk
        jmp swapBack

        ;___________________________________________________________________________
        prematureExit: jmp zeroesDone ;to overcome shortjump range issues from above
        ;___________________________________________________________________________

        ;then, just keep swapping it back based on the starting index
        ;(insertion sort). This is also why we put 0xFFFF before freeChunks
        swapBack:
            mov dx, word [freeChunks+si]
            cmp dx, word [freeChunks+si-4] ;cmp {inserted idx}, {idx behind}
            jnb freeChunkAdded             ;if new idx is not smaller, don't swap

            swap:
                ;swap starting indexes
                mov cx, word [freeChunks+si-4]
                mov word [freeChunks+si], cx
                mov word [freeChunks+si-4], dx

                ;swap lengths
                mov dx, word [freeChunks+si+2]
                mov cx, word [freeChunks+si-4+2]
                mov word [freeChunks+si+2], cx
                mov word [freeChunks+si-4+2], dx

                ;if a swap did happen, more might happen so check again
                sub si, 4
                jmp swapBack

    freeChunkAdded:

    mov si, 0
    getStartByteNumber_2:
        cmp bx, 8
        ;if the starting index is less than 8, that means we're at the right byte
        jb correctStartByteAcquired_2
        ;if not, we must increment byte number, and remove that many bits from bx
        inc si
        sub bx, 8
        jmp getStartByteNumber_2

    correctStartByteAcquired_2:
        xchg bx, si

        ;Therefore:
        ;   1. bx = in bitfield, offset after which we will pick up a byte
        ;   2. si = in the byte above, offset after which we will pick a bit
        ;   3. ax = make this many bits, starting from bit # si, 0

    turningToZero:
        ;if no more bits left to turn to 0, then (prepare to) leave function
        cmp ax, 0
        jna zeroesDone

        ;reset dl (mask) from previous iterations
		xor dx, dx

        ;if ax < 8, then we need to turn some bits on the LEFT side of the byte 1
        ;this also means that it HAS to be the final byte
        ;if it is the final byte, put the number of bits we need to shift into cx
        ;if it turns out to not be the final byte, we mov into cx again anyway
        mov cx, ax
        cmp ax, 8
        jb generateDLmaskFinalByte_2

        ;if ax >= 8, then we need to convert either the right most couple bits
        ;(first byte) or all 8 bits (middle/first/last)
        ;cx = number of bits in this byte to turn 1 = 8 - si
        mov cx, 8
        sub cx, si

        sub ax, cx ;since we will be converting this many bits to 1
		xor dx, dx

        ;MASK
        ; 1 - turn this bit to 0
        ; 0 - do not do anything to this bit

        ;to do what free does, we must perform [mem & not(mask)]
        ;       mem: 1100
        ;      mask: 1100
        ;     !mask: 0011
        ; mem&!mask: 0000

        generateDLmaskNonFinal_2:
            stc
            rcl dl, 1
            loop generateDLmaskNonFinal_2

        ;and the byte from memory (bitfield+bx) with the not mask (dl)
        not dl
        and [bitfield+bx], dl

        ;after the mask has been generated, then for the FOLLOWING byte
        ;we must start from the very BEGINNING, i.e bit #0, therefore
        inc bx
		xor si, si
        jmp turningToZero

        generateDLmaskFinalByte_2:
            stc
            rcr dl, 1
            loop generateDLmaskFinalByte_2

        ;AND the byte from memory (bitfield+bx) with the not mask (dl)
        not dl
        and [bitfield+bx], dl

    zeroesDone:
        pop cx
        pop si
        pop dx
        pop bx
        pop bp
        ret 4

start:
    ; Alloc
    push 7
    call alloc
    push 9
    call alloc

    ; Free
    push 0  ; bit index
    push 4  ; length
    call free

exit:
    mov ax, 4c00h
    int 21h
