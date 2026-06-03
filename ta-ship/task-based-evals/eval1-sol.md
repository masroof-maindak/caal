## Q1. (30%)

a. 0x0012
b. 0xFFFF

## Q2. (30%)

### Perfect

15

### 75% credit

14

## Q3.(40%)

```x86
org 100h

xor ax, ax
xor bx, bx
mov cx, 6

sum:
	add al, [nums + bx]
	add bx, 1
	loop sum

mov ax, 4c00h
int 21h

nums: db 10, 20, 30, 40, 50, 60
```

## Q4. (30%)

### Perfect
a. False
b. DOS syscalls will not be present

### 60% Credit
a. True
b. Processor understands the same assembly language
