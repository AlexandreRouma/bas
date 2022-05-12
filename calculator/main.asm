.org 0x0000

; Interrupt Vector
jmp start
ret

start:
    ; Init the stack
    ldi rsp, 0x8000

    ; Initialize the terminal
    call term_init
    call term_clear_screen
    call term_flush
calculator:
    push r0
    push r1
    push r2
    push r3
    push r4
    push r5
    ; Print title
    ldi r0, title_str
    call term_println

    ; r3 contains the amount of numbers in the stack
    ; therefore also the line at which we currently are
    xor r3, r3

_calculator_input_loop:
    ldi r0, 0
    mov r1, r3
    inc r1
    call term_set_cursor

    ldi r0, prompt_str
    call term_print
    call term_flush

    ldi r0, 2
    mov r1, r3
    inc r1
    call term_set_cursor

    ldi r0, input_buffer
    ldi r1, size_buffer
    call kbd_read_line

    ; get first char
    ld r4, [r0]
    ld r5, [add_str]
    cmp r4, r5
    jmp@eq _calculator_add_nums

    ld r5, [sub_str]
    cmp r4, r5
    jmp@eq _calculator_sub_nums

    ld r5, [mul_str]
    cmp r4, r5
    jmp@eq _calculator_mul_nums

    ld r5, [div_str]
    cmp r4, r5
    jmp@eq _calculator_div_nums

    ld r5, [modulo_str]
    cmp r4, r5
    jmp@eq _calculator_modulo_nums

    ld r5, [drop_str]
    cmp r4, r5
    jmp@eq _calculator_drop_num

    ld r5, [exit_str]
    cmp r4, r5
    jmp@eq _calculator_end

    ; we have a number to parse

    ; do parsing
    xor r2, r2
_calculator_atoi_loop:
    ld r4, [r0]
    ; check for NULL
    xor r5, r5 
    cmp r4, r5
    jmp@eq _calculator_atoi_finished
    ; check if it is in '0' and '9'
    ldi r5, 0x30
    sub r4, r5
    jmp@lo _calculator_atoi_finished
    ldi r5, 9
    cmp r4, r5
    jmp@gr _calculator_atoi_finished
    ; add char to value
    ldi r5, 10
    mul r2, r5
    add r2, r4
    
    inc r0
    jmp _calculator_atoi_loop

_calculator_atoi_finished:

    ; add number to stack
    push r2
    inc r3

    jmp _calculator_input_loop

_calculator_add_nums:
    ldi r0, 2
    cmp r3, r0
    jmp@lo _calculator_reset_prompt

    pop r1
    pop r0
    add r0, r1
    dec r3
    push r0
    mov r4, r0

    jmp _calculator_print_result

_calculator_sub_nums:
    ldi r0, 2
    cmp r3, r0
    jmp@lo _calculator_reset_prompt

    pop r1
    pop r0
    sub r0, r1
    dec r3
    push r0
    mov r4, r0

    jmp _calculator_print_result

_calculator_mul_nums:
    ldi r0, 2
    cmp r3, r0
    jmp@lo _calculator_reset_prompt

    pop r1
    pop r0
    mul r0, r1
    dec r3
    push r0
    mov r4, r0

    jmp _calculator_print_result

_calculator_div_nums:
    ldi r0, 2
    cmp r3, r0
    jmp@lo _calculator_reset_prompt

    pop r1

    ; 0 divider check
    ldi r2, 0
    cmp r1, r2
    jmp@ne _calculator_div_nums_contd
    push r1
    jmp _calculator_reset_prompt

_calculator_div_nums_contd:
    pop r0

    call div16
    
    dec r3
    push r1 
    mov r4, r1

    jmp _calculator_print_result

_calculator_modulo_nums:
    ldi r0, 2
    cmp r3, r0
    jmp@lo _calculator_reset_prompt

    pop r1

    ; 0 divider check
    ldi r2, 0
    cmp r1, r2
    jmp@ne _calculator_modulo_nums_contd
    push r1
    jmp _calculator_reset_prompt

_calculator_modulo_nums_contd:
    pop r0

    call div16

    dec r3
    push r0
    mov r4, r0

    jmp _calculator_print_result

_calculator_print_result:
    ; rm op
    mov r0, r3
    inc r0
    inc r0
    call term_clear_line

    ldi r0, 0
    mov r1, r3
    ; do not increase here
    call term_set_cursor

    ldi r0, prompt_str
    call term_print

    ldi r0, 2
    mov r1, r3
    call term_set_cursor

    ; print number
    ldi r0, number_buffer
    mov r1, r4

    call itoa10
    call term_print

    call term_new_line
    jmp _calculator_input_loop

_calculator_drop_num:
    ldi r0, 1
    cmp r3, r0
    jmp@lo _calculator_reset_prompt

    pop r0

    mov r0, r3
    call term_clear_line
    inc r0
    call term_clear_line
    
    dec r3

    jmp _calculator_input_loop

_calculator_reset_prompt:
    mov r0, r3
    inc r0
    call term_clear_line

    jmp _calculator_input_loop

_calculator_end:
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    ret

input_buffer: .skip 11
size_buffer: .word 10

number_buffer: .skip 10