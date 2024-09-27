; a simple hello world program

section .data
  hello_world_str: db "Hello, world!", 10, 0
  hello_world_length: equ $-hello_world_str

section .bss

section .text
  global _start

  _start:
    ; print hello_world_str to stdout using the "write" syscall
    mov rax, 1 ; set syscall to "write"
    mov rdi, 1 ; set file descriptor to stdout
    mov rsi, hello_world_str ; set pointer to buffer
    mov rdx, hello_world_length ; set length

    syscall

    ; exit with status 0
    mov rax, 60 ; set "exit" syscall
    mov rdi, 0 ; set exit code
    syscall
