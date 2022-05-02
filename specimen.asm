.org 0x0000

start:
    ; Init the stack
    ldi rsp, 0x8000

    ; Initialize the terminal
    .call term_init
    .call term_clear_screen
    .call term_flush

    ldi r0, 1
    ldi r1, 1
    .call term_set_cursor

    ldi r0, bell_top
    .call term_print

    ldi r0, 1
    ldi r1, 2
    .call term_set_cursor

    ldi r0, bell_bottom
    .call term_print

    ldi r0, message
    .call term_print

    .call term_flush

end:
    hlt

bell_top:
    .word 2
    .word 1
    .word 0
bell_bottom:
    .word 4
    .word 3
    .word 0

message: .str " We do a little emulation?"
