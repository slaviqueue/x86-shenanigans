section .bss
  sys_read: equ 0
  sys_write: equ 1

  stdin: equ 0
  stdout: equ 1

  buf_size: equ 1024
  buf: resb buf_size

section .text
  global _start

  _start:
  read_buffer:
    ; read bytes from stdin to buffer
    mov rax, sys_read
    mov rdi, stdin
    mov rsi, buf
    mov rdx, buf_size
    syscall

    ; if read 0 bytes - exit
    cmp rax, 0
    je exit

    ; make a pointer to a character in buf
    mov rbx, buf
    ; make a counter of bytes left to process
    mov rcx, rax

  process_char:
    ; if processed whole buffer - write to stdout
    cmp rcx, 0
    je write_buffer

    ; check if char is a lowercase letter
    cmp byte [rbx], 'a'
    jb next_char
    cmp byte [rbx], 'z'
    ja next_char

    ; make the letter uppercase
    sub byte [rbx], 32

  next_char:
    ; decrease the counter of characters left to process
    dec rcx 
    ; increase the address of the next character in buffer
    inc rbx
    jmp process_char

  write_buffer:
    ; write processed buffer to stdout
    mov rax, sys_write
    mov rdi, stdout
    mov rsi, buf
    mov rdx, buf_size
    syscall

    jmp read_buffer

  exit:
    mov rax, 60
    mov rdi, 0
    syscall
