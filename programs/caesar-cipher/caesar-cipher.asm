; This is a program that encrypts the data it receives from the stdin with the
; caeser cipher. It only encrypts letters. The number of places each letter is
; being shifter by is specified by the "shift_places" macro.
; 
; Note: since this program uses functions from libc, we have to link it with
; gcc, not with ld:
; LD_FLAGS=-no-pie LINK_WITH=gcc ./build.sh programs/caesar-cipher

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

; command-line argument offsets
%define arg_executable 1
%define arg_command 2

; Initialized data
section .data
  command_encrypt: db "encrypt", 0
  command_decrypt: db "decrypt", 0
  command_line_arguments_error: db "Usage: %s {encrypt|decrypt}", 10, 0

; Uninitialized data
section .bss
  buffer: resb bufsize

extern printf
extern strcmp

; Source code
section .text
  global main

  ; The entry point
  main:
    push rbp
    mov rbp, rsp

    ; backup inputs
    mov r12, rdi ; backup the arguments count in r12
    mov r13, rsi ; backup the arguments pointer in r13

    ; validate 
    cmp r12, 2
    jne .exit_with_usage

    ; check the "command" argument and store the corresponding procedure in r14
    .check_command_encrypt:
      mov rdi, [r13 + 8]
      mov rsi, command_encrypt
      call strcmp
      cmp rax, 0
      jne .check_command_decrypt
      mov r14, encrypt
      jmp .read_and_process_input

    .check_command_decrypt:
      mov rdi, [r13 + 8]
      mov rsi, command_decrypt
      call strcmp
      cmp rax, 0
      jne .exit_with_usage
      mov r14, decrypt

    .read_and_process_input:
    call read_buffer

    ; Exit if out of input
    cmp rax, 0
    je .exit

    ; Encrypt or decrypt and write the output to stdout
    call r14

    ; Write the output to stdout
    mov rbx, rax
    call write_buffer

    ; Read next input chunk
    jmp .read_and_process_input

    .exit_with_usage:
      mov rsi, [r13]
      call print_usage
      mov rax, 1

    .exit:
      mov rax, 0

      pop rbp
      ret

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

  decrypt:
    push rcx
    push r8

    mov rcx, rax

    .decrypt_byte:
      mov r8b, [buffer + rcx - 1]

      .check_if_lowercase_letter:
        cmp r8b, 'a'
        jb .check_if_uppercase_letter
        cmp r8b, 'z'
        ja .check_if_uppercase_letter
        jmp .decrypt
      
      .check_if_uppercase_letter:
        cmp r8b, 'A'
        jb .skip_byte
        cmp r8b, 'Z'
        ja .skip_byte
        
      .decrypt:
        sub byte [buffer + rcx - 1], shift_places
      .skip_byte:
        loop .decrypt_byte
    
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

  ; Print the usage message
  ; Input:
  ;   - rsi - null-terminated string which contains the name of executable
  ; Output: none
  ; Modified: not relevant
  print_usage:
    mov rdi, command_line_arguments_error
    mov rax, 0
    call printf
    ret
