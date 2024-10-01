; a program that takes a string as an input, and produces an uppercased version
; of that string

section .data
	stdin: equ 0
	stdout: equ 1

section .bss
	buf: resb 1

global _start

section .text
	_start:

	read_character:
		; read one character from stdin
		mov rax, 0
		mov rdi, stdin
		mov rsi, buf
		mov rdx, 1
		syscall

		; if out of bytes - exit
		cmp rax, 0
		je exit

		; check if we've read a lowercase letter
		cmp byte [buf], 'a'
		jl write_character
		cmp byte [buf], 'z'
		jg write_character

		; make it uppercase
		sub byte [buf], 32

	write_character:
		; write the character to stdout
		mov rax, 1
		mov rdi, stdout
		mov rsi, buf
		mov rdx, 1
		syscall

		jmp read_character

	exit:
		; exit
		mov rax, 60
		mov rdi, 0
		syscall
