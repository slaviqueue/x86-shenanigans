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
%define bufsize 16
%define shift_places 3

; Initialized data
section .data
  command_encrypt: db "encrypt", 0
  command_decrypt: db "decrypt", 0
  command_line_arguments_error: db "Usage: %s {encrypt|decrypt}", 10, 0

; Uninitialized data
section .bss
  ; Had to rename this from "buffer" to "databuffer", because when debugging
  ; with gdb, it sees all "buffer"'s marked as static from libc files, and if we
  ; try to do a "print buffer" it picks up a random "buffer" symbol from the
  ; libc.
  ;
  ; Related issue:
  ; https://stackoverflow.com/questions/39220351/gdb-behaves-differently-for-symbols-in-the-bss-vs-symbols-in-data
  databuffer: resb bufsize

extern printf
extern strcmp

; Source code
section .text
  global main

  ; The entry point
  main:
    push rbp
    mov rbp, rsp

    ; Backup registers
    push r14

    ; Check the "command" argument and store the corresponding procedure in rax
    call parse_arguments
    cmp rax, 0 ; Check the result of parse_arguments
    je .exit_with_usage ; If it returned a null pointer - print the ussage
                        ; message and exit
    mov r14, rax ; Store the command handler in r14

    .read_and_process_input:
      call read_buffer

      cmp rax, 0 ; Check how many bytes we've read
      je .exit ; If we read 0 bytes - exit
      
      mov rdi, rax ; Move the amount of bytes read to rdi
      call r14 ; Encryp of decrypt

      ; Write the output to stdout
      mov rdi, rax
      call write_buffer

      ; Read next input chunk
      jmp .read_and_process_input

    .exit_with_usage:
      ; Print the usage with the name of the executable
      mov rsi, [rsi]
      call print_usage
      mov rax, 1

    .exit:
      pop r14
      pop rbp
      ret

  ; A procedure that figures out if we have encrypt of decrypt the input
  ; Input:
  ;  - rsi - a number of arguments
  ;  - rdi - a pointer to the array of arguments
  ; Output:
  ;   - rax - a pointer to procedure that should be run on the input buffer. If
  ;   rax contains 0, then the command argument was not valid, and we should
  ;   exit with usage
  ; Modifies: none         
  parse_arguments:
    ; Backup registers
    push rdi
    push rsi

    ; Check if the number of arguments is equal to 2, fail otherwise
    cmp rdi, 2
    jne .fail_to_parse

    ; Put the first command line argument after executable to rdi
    mov rdi, [rsi + 8]

    .check_command_encrypt:
      mov rsi, command_encrypt
      call strcmp
      cmp rax, 0
      jne .check_command_decrypt
      mov rax, encrypt
      jmp .return

    .check_command_decrypt:
      mov rsi, command_decrypt
      call strcmp
      cmp rax, 0
      jne .fail_to_parse
      mov rax, decrypt
      jmp .return

    .fail_to_parse:
      mov rax, 0

    .return:
      ; Restore registers
      pop rsi
      pop rdi
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
    push rdx

    ; Read a buffer from stdin
    mov rax, sys_read
    mov rdi, std_in
    mov rsi, databuffer
    mov rdx, bufsize
    syscall

    ; Restore registers and return
    pop rdx
    pop rsi
    pop rdi
    ret

  ; A procedure that encrypts the input buffer
  ;
  ; Input: rdi - the number of bytes in the buffer we have to encrypt
  ; Output: none
  ; Modifies: buffer
  encrypt:
    ; Backup registers
    push rcx
    push rax

    ; Set the counter register
    mov rcx, rdi

    ; Enrypt current byte, only if it's a letter. 
    .encrypt_byte:
      ; Here we need to put a byte from memory to the edi. We cannot, however
      ; refer directly to the lower 8 bits of the rdi, so we have to do it
      ; through the intermediate rax with al.
      xor rax, rax
      mov al, byte [databuffer + rcx - 1]
      mov rdi, rax
      call is_letter

      cmp rax, 0
      je .skip_byte
      add byte [databuffer + rcx - 1], shift_places

      .skip_byte:
        loop .encrypt_byte
    
    ; Restore registers
    pop rax
    pop rcx
    ret

  ; A procedure that decrypts the input buffer
  ;
  ; Input: rdi - the number of bytes in the buffer we have to decrypt
  ; Output: none
  ; Modifies: buffer
  decrypt:
    ; Backup registers
    push rcx
    push rax

    ; Set the counter register
    mov rcx, rdi

    ; Enrypt current byte, only if it's a letter. 
    .decrypt_byte:
      xor rax, rax
      mov al, byte [databuffer + rcx - 1]
      mov rdi, rax
      call is_letter

      cmp rax, 0
      je .skip_byte
      sub byte [databuffer + rcx - 1], shift_places

      .skip_byte:
        loop .decrypt_byte
    
    ; Restore registers
    pop rax
    pop rcx
    ret

  ; A procedure that checks if a given character is either a lower or an upper
  ; case letter. The condition is logically
  ; equivalent to the following C expression:
  ;
  ;   (rdi >= 'a' && rdi <= 'z') || (rdi >= 'A' && rdi <= 'Z')
  ; 
  ; Input: rdi - the character
  ; Output: rax - 1 if character *is* a letter, 0 otherwise
  ; Modifies: none
  is_letter:
    %macro return_status 1
      mov rax, %1
      ret
    %endmacro

    .check_if_lowercase_letter:
      cmp rdi, 'a'
      jb .check_if_uppercase_letter
      cmp rdi, 'z'
      ja .check_if_uppercase_letter
      return_status 1
    
    .check_if_uppercase_letter:
      cmp rdi, 'A'
      jb .return_false
      cmp rdi, 'Z'
      ja .return_false
      return_status 1
   
   .return_false:
      return_status 0

  ; A procedure that writes the buffer to stdout
  ;
  ; Input: rdi - the amount of characters to write
  ; Output: none
  ; Modifies: none
  write_buffer:
    ; Backup registers
    push rax
    push rdx
    push rsi

    ; Write buffer to stdout
    mov rax, sys_write
    mov rdx, rdi
    mov rdi, std_out
    mov rsi, databuffer
    syscall

    ; Restore registers
    pop rsi
    pop rdx
    pop rax
    ret

  ; Print the usage message
  ; Input:
  ;   - rdi - null-terminated string which contains the name of executable
  ; Output: none
  ; Modified: not relevant
  print_usage:
    ; Backup registers
    push rsi

    mov rsi, rdi
    mov rdi, command_line_arguments_error
    mov rax, 0
    call printf

    pop rsi
    ret
