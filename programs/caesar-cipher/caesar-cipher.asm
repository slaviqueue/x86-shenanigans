; This is a program that encrypts the data it receives from the stdin with the
; caeser cipher. It only encrypts letters. The number of places each letter is
; being shifter by is specified by the "shift_places" macro.

; Syscalls
%define sys_read 0
%define sys_write 1
%define sys_exit 60

; File descriptors
%define std_in 0
%define std_out 1

; Program-specific constants
%define exit_success 0
%define bufsize 16
%define shift_places 3

; Uninitialized data
section .bss
  buffer: resb bufsize

; Source code
section .text
  global _start

  ; The entry point
  _start:
    .read_and_process_input:
    call read_buffer

    ; Exit if out of input
    cmp rax, 0
    je .exit

    ; Encrypt and write the output to stdout
    call encrypt

    ; Write the output to stdout
    mov rbx, rax
    call write_buffer

    ; Read next input chunk
    jmp .read_and_process_input

    .exit:
    call exit

  ; A procedure to read the input buffer
  ; 
  ; Input: none
  ; Output: rax - number of characters read
  ; Modifies: buffer
  read_buffer:
    ; Backup registers
    push rdi
    push rsi

    ; Read a buffer from stdin
    mov rax, sys_read
    mov rdi, std_in
    mov rsi, buffer
    mov rdx, bufsize
    syscall

    ; Restore registers and return
    pop rsi
    pop rdi
    ret

  ; A procedure that encrypts the input buffer
  ;
  ; Input: rax - the number of bytes in the buffer we have to encrypt
  ; Output: none
  ; Modifies: buffer
  encrypt:
    ; backup registers
    push rcx
    push r8

    mov rcx, rax

    ; Enrypt current byte, only if it's a letter. The condition is logically
    ; equivalent to the following C expression:
    ; (r8b >= 'a' && r8b <= 'z') || (r8b >= 'A' && r8b <= 'Z')
    .encrypt_byte:
      mov r8b, byte [buffer + rcx - 1]

      .check_if_lowercase_letter:
        cmp r8b, 'a'
        jl .check_if_uppercase_letter
        cmp r8b, 'z'
        ja .check_if_uppercase_letter
        jmp .encrypt

      .check_if_uppercase_letter:
        cmp r8b, 'A'
        jl .skip_byte
        cmp r8b, 'Z'
        ja .skip_byte

      .encrypt:
        add byte [buffer + rcx - 1], shift_places
      .skip_byte:
        loop .encrypt_byte
    
    ; Restore_registers
    pop r8
    pop rcx
    ret

  ; A procedure that writes the buffer to stdout
  ;
  ; Input: rbx - the amount of characters to write
  ; Output: none
  ; Modifies: none
  write_buffer:
    ; Dump registers
    push rax

    ; Write buffer to stdout
    mov rax, sys_write
    mov rdi, std_out
    mov rsi, buffer
    mov rdx, rbx
    syscall

    ; Restore registers
    pop rax
    ret

  ; Exit the program
  ;
  ; Input: none
  ; Output: none
  ; Modifies: who cares
  exit:
    mov rax, sys_exit
    mov rdi, exit_success
    syscall
