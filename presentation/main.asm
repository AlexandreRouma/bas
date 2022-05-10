.org 0x0000

; Interrupt Vector
jmp start
ret

start:
    call term_init
    call term_clear_screen

    ldi r0, 2
    ldi r1, 1
    ldi r2, 3
    call draw_h_line

    ldi r0, 1
    ldi r1, 2
    ldi r2, 3
    call draw_v_line

    ldi r0, 2
    ldi r1, 5
    ldi r2, 3
    call draw_h_line

    ldi r0, 5
    ldi r1, 2
    ldi r2, 3
    call draw_v_line

    ldi r0, 2
    ldi r1, 3
    call term_set_cursor
    ldi r0, lol
    call term_print

    call term_flush

end:
    hlt

lol: .str "lol"