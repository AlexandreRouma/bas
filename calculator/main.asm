.org 0x0000

start:
    ; Init the stack
    ldi rsp, 0x8000

    ; Initialize the terminal
    call term_init
    call term_clear_screen
    call term_flush

    ; Print title
    ldi r0, motd_str
    call term_println

    ; r3 contains the amount of numbers in the stack
    ; therefore also the line at which we currently are
    xor r3, r3

input_loop:
    ldi r0, prompt_str
    call term_print
    call term_flush

    ldi r0, 2
    ldi r1, r3
    inc r1
    call term_set_cursor

    ldi r0, input_buffer
    ldi r1, size_buffer
    call kbd_read_line

    ; get first char
    ld r4, [r0]
    ldi r5, [add_str]
    cmp r4, r5
    jmp@eq add_nums

    ldi r5, [sub_str]
    cmp r4, r5
    jmp@eq sub_nums

    ldi r5, [mul_str]
    cmp r4, r5
    jmp@eq mul_nums

    ; we have a number to parse

    ; do parsing

    ; add number to stack
    push r0
    inc r3

add_nums:
    ldi r0, 2
    cmp r3, r0
    jmp@lo reset_prompt

    pop r1
    pop r0
    add r0, r1
    dec r3
    push r0

sub_nums:
    ldi r0, 2
    cmp r3, r0
    jmp@lo reset_prompt


mul_nums:
    ldi r0, 2
    cmp r3, r0
    jmp@lo reset_prompt


print_result:
    ldi r0, 0
    ldi r1, r3
    inc r3
    call term_set_cursor

    ldi r0, prompt_str
    call term_print

    ldi r0, 2
    ldi r1, r3
    inc r3
    call term_set_cursor

    ; print number

    call term_new_line
    jmp input_loop

reset_prompt:
    ldi r0, 0
    ldi r1, r3
    inc r1
    call term_set_cursor

    jmp input_loop

end:
    hlt

input_buffer: .skip 11
size_buffer: 10