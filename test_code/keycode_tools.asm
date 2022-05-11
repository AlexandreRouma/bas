start:
    ; Init the stack
    ldi rsp, 0x8000

    ; Initialize the terminal
    call term_init
    call term_clear_screen
    call term_flush

kbd_loop:
    ; Check for an event
    call kbd_get_event

    ; If we got no event, keep waiting
    xor r2, r2
    cmp r0, r2
    jmp@eq kbd_loop

    ; If release, keep waiting
    cmp r1, r2
    jmp@ne kbd_loop

    ldi r1, 0xFF
    and r0, r1

    ldi r1, keymap_fr_be
    add r0, r1
    ld r0, [r0]

    st [charbuf], r0
    ldi r0, charbuf

    ; mov r1, r0
    ; ldi r0, strbuf
    ; call itoa16
    call term_print
    call term_flush

    jmp kbd_loop


end:
    hlt

charbuf:      .str " "
strbuf: .skip 5