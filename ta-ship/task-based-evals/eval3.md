#### 1. This task-based evaluation corresponds to labs #7, 8 and 9.
#### 2. You have 45 minutes to attempt these questions.
#### 3. Any manner of plagiarism will lead to an instant, unquestionable and non-negotiable zero across all three labs.
#### 4. Provide *screenshots* of your `.asm` files in a report titled as per the format `BSCS22012-Eval3.pdf`.
#### 5. Failure to comply with the prior instruction will result in negative grading.

---

###### Q1 \[10\]: Write a subroutine `count_vowels` that counts all occurrences of vowel characters in a null-terminated string

- Provide a screenshot of the input string and register/memory containing the count.
- The user should pass the address of the string as a parameter to the subroutine

---

###### Q2 \[10\]: Write a subroutine `fill_screen` that fill's the screen with a certain attribute and character

- Take the argument for the attribute byte and character from the user.
- Provide a screenshot of the output.

```nasm
org 100h
jmp start

fill_screen:
	;

start:
	push 0x212A ; green BG // red FG // asterisk (probably)?
	call fill_screen
	mov ax, 4c00h
	int 21h
```

---

###### Q3 \[10\]: Hook the keyboard interrupt to toggle a stopwatch when a certain scancode is pressed

- Your subroutine is to refer to the original ISR should a scancode you are not anticipating arrives.
- Clean up by unhooking the interrupt when the user presses escape.
- You are _not_ required to provide code for the timer tick ISR.
- Only the keyboard ISR and relevant set-up code is required.
- Recall that the keyboard and timer ISR's IVT entries are at the 9th and 8th indexes respectively 

```nasm
KB_ISR:
	push ax
	in al, 0x60
	
	;
	
	exit_kb_isr:
	mov al, 0x20
	out 0x20, al
	pop ax
	iret
```

---

###### Q4 \[3\]: (BONUS) List your favourite dinosaur(s).

