Q1. Write the resultant value in `ax` **as it would appear in AFD** after
	each of the following code-blocks has been executed

		a.
			mov ax, 9
			mov bx, 9
			add ax, bx

		b.
			mov ax, 37
			mov bx, 38
			sub ax, bx

Q2. Write the number of bytes that the following program will consume in
	memory upon execution

                    org 100h
    31C0            xor ax, ax
    B91400          mov cx, 20
    051400          here: add ax, 20
    E2FB            loop here
    B8004C          mov ax, 4c00h
    CD21            int 21h

Q3. Complete the following task in x86 assembly

		Place the first 6 multiples of 10 in memory using a SINGLE label 
        (note that you are NOT allowed to use more than 6 bytes of memory);
        loop over these values and cumulatively add them into the accumulator.

		The value of accumulator at the end should be 0x00D2 (210 in decimal)

(BONUS)
Q4. Would the program from Q2 work on your laptop's processor on its host OS?
	a. True/False?
	b. Justify your answer.
