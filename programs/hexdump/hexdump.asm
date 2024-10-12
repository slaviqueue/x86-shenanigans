; file descriptors
%define stdin 0
%define stdout 1

; syscalls
%define sys_read 0
%define sys_write 1
%define sys_exit 60

; register alias
%define current_byte_index_r r9
%define bytes_read_r r8
%define output_buffer_position_r r12

; constants
%define input_buffer_length 16
%define output_characters_per_byte 3

section .data
  digits: db "0123456789ABCDEF"
  output_line: db " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00", 10
  output_line_length: equ $ - output_line

section .bss
  input_buffer: resb input_buffer_length

section .text
  global _start

  _start:
  read_input:
    ; read to input buffer
    mov rax, sys_read
    mov rdi, stdin
    mov rsi, input_buffer
    mov rdx, input_buffer_length
    syscall

    ; remember how many bytes we have read
    mov bytes_read_r, rax

    ; if we've run out of input, exit
    cmp rax, 0
    je exit
  
  process_buffer:
    ; the index of current byte
    mov current_byte_index_r, 0

  process_byte:
    ; set the output buffer position
    lea output_buffer_position_r, [output_line + current_byte_index_r * output_characters_per_byte]

    ; process high nibble
    mov rbx, 0
    mov bl, byte [input_buffer + current_byte_index_r]
    shr bl, 4
    mov bl, [digits + rbx]
    mov [output_buffer_position_r + 1], bl

    ; process low nibble
    mov rbx, 0
    mov bl, byte [input_buffer + current_byte_index_r]
    and bl, 0fh
    mov bl, [digits + rbx]
    mov [output_buffer_position_r + 2], bl

    inc current_byte_index_r

    ; process next byte if haven't processed all bytes yet
    cmp current_byte_index_r, bytes_read_r
    jne process_byte

    ; check if we filled full output buffer
    ; otherwise zero residue bytes in the output line
    cmp current_byte_index_r, input_buffer_length
    je write_output

    dec current_byte_index_r

  zero_residue_byte:
    ; zero single byte
    mov byte [output_line + current_byte_index_r * 3], " "
    mov byte [output_line + current_byte_index_r * 3 + 1], "0"
    mov byte [output_line + current_byte_index_r * 3 + 2], "0"

    ; check if there are mote bytes to zero
    inc current_byte_index_r
    cmp current_byte_index_r, input_buffer_length
    jne zero_residue_byte

  write_output:
    mov rax, sys_write
    mov rdi, stdout
    mov rsi, output_line
    mov rdx, output_line_length
    syscall
    jmp read_input
  
  exit:
    mov rax, sys_exit
    mov rdi, 0
    syscall
