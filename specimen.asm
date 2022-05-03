.org 0x0000

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

    ; Display message depending on r1
    cmp r1, r2
    jmp@eq kbd_pressed

    mov r2, r0

    ldi r0, msg_released
    call term_print
    
    ldi r0, strbuf
    call itoa16
    call term_print
    
    ldi r0, msg_space
    call term_print
    
    ldi r0, strbuf
    mov r1, r2
    call itoa16
    call term_println
    call term_flush

    jmp kbd_loop

kbd_pressed:
    mov r2, r0

    ldi r0, msg_pressed
    call term_print
    
    ldi r0, strbuf
    call itoa16
    call term_print
    
    ldi r0, msg_space
    call term_print
    
    ldi r0, strbuf
    mov r1, r2
    call itoa16
    call term_println
    call term_flush

    jmp kbd_loop

end:
    hlt

msg_any_key:    .str "Press any key"
msg_pressed:    .str "PRESSED:  "
msg_released:   .str "RELEASED: "
msg_space:      .str " "
strbuf: .skip 5