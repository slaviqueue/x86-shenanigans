; a program that outputs an uppercase version of a hardcoded string

section .data
  greeting: db `hey there, I'm going to make all chars upcase, observe:\n`, 0
  greeting_len: equ $ - greeting
  original_str: db `it's like a jungle sometimes, it makes me wonder how I keep from going under\n`, 0
  original_str_len: equ $ - original_str

global _start
section .text
  _start:
    ; print greeting
    mov rax, 1
    mov rdi, 1
    mov rsi, greeting
    mov rdx, greeting_len
    syscall

    ; print original string
    mov rax, 1
    mov rdi, 1
    mov rsi, original_str
    mov rdx, original_str_len
    syscall

    ; make a upcase string
    mov rax, original_str_len
    mov rbx, original_str

  upcase_next:
    ; check if current character is a-z
    cmp byte [rbx], 97
    jl skip_current_character
    cmp byte [rbx], 122
    jg skip_current_character

    ; make character upper case
    sub byte [rbx], 32

  skip_current_character:
    inc rbx
    dec rax
    jnz upcase_next

    ; print upcased string string
    mov rax, 1
    mov rdi, 1
    mov rsi, original_str
    mov rdx, original_str_len
    syscall

    ; gracefully exit
    mov rax, 60
    mov rdi, 0
    syscall
