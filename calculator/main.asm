.org 0x0000

start:
    ; Init the stack
    ldi rsp, 0x8000

    ; Initialize the terminal
    call term_init
    call term_clear_screen
    call term_flush

    ; Print title
    ldi r0, title_str
    call term_println

    ; r3 contains the amount of numbers in the stack
    ; therefore also the line at which we currently are
    xor r3, r3

input_loop:
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
    jmp@eq add_nums

    ld r5, [sub_str]
    cmp r4, r5
    jmp@eq sub_nums

    ld r5, [mul_str]
    cmp r4, r5
    jmp@eq mul_nums

    ; we have a number to parse

    ; do parsing

    ; add number to stack
    push r0
    inc r3

    jmp input_loop

add_nums:
    ldi r0, 2
    cmp r3, r0
    jmp@lo reset_prompt

    pop r1
    pop r0
    add r0, r1
    dec r3
    push r0

    jmp print_result

sub_nums:
    ldi r0, 2
    cmp r3, r0
    jmp@lo reset_prompt


mul_nums:
    ldi r0, 2
    cmp r3, r0
    jmp@lo reset_prompt


print_result:
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
    ldi r0, result_str
    call term_print

    call term_new_line
    jmp input_loop

reset_prompt:
    mov r0, r3
    inc r0
    call term_clear_line

    jmp input_loop

end:
    hlt

input_buffer: .skip 11
size_buffer: .word 10