.org 0x0000

; Interrupt Vector
jmp start
ret

start:
    ; Init stack
    ldi rsp, 0x8000

    call term_init

    ldi r0, 0xF000
    call term_set_color

    call term_clear_screen

    
    ldi r0, 0x1000
    call term_set_color
    ldi r0, 1
    ldi r1, 1
    ldi r2, 5
    ldi r3, 5
    call draw_filled_rect

    ldi r0, 0x3000
    call term_set_color
    ldi r0, 7
    ldi r1, 1
    ldi r2, 5
    ldi r3, 5
    call draw_filled_rect

    ldi r0, 0x2000
    call term_set_color
    ldi r0, 13
    ldi r1, 1
    ldi r2, 5
    ldi r3, 5
    call draw_filled_rect

    ldi r0, 0x6000
    call term_set_color
    ldi r0, 19
    ldi r1, 1
    ldi r2, 5
    ldi r3, 5
    call draw_filled_rect

    ldi r0, 0x4000
    call term_set_color
    ldi r0, 25
    ldi r1, 1
    ldi r2, 5
    ldi r3, 5
    call draw_filled_rect

    ldi r0, 0x5000
    call term_set_color
    ldi r0, 31
    ldi r1, 1
    ldi r2, 5
    ldi r3, 5
    call draw_filled_rect


    ldi r0, 0xF000
    call term_set_color
    ldi r0, 1
    ldi r1, 7
    ldi r2, 35
    ldi r3, 5
    call draw_filled_rect

    ; ldi r0, 0x4F00
    ; call term_set_color
    ; ldi r0, 3
    ; ldi r1, 3
    ; call term_set_cursor
    ; ldi r0, msg
    ; call term_print

    call term_flush

end:
    hlt

msg: .str "nice"