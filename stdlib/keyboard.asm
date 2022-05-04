.define KBD_BASE        0xDF00
.define KBD_BUF_POS     0xDFFF
.define KBD_BUF_MASK    0x7F
.define KBD_EXT_CODE    0xE0
.define KBD_REL_CODE    0xF0

; Get latest keyboard event from buffer
; return r0: Event, 0x0000 if no event occured
; return r1: 0 if pressed, 1 if released
kbd_get_event:
    push r2
    push r3
    
    ; Set event to 0 in case there is none
    xor r0, r0
    xor r1, r1

    ; Get buffer position
    ldi r2, KBD_BUF_POS
    ld r2, [r2]

    ; Get known buffer position
    ldi r3, _kbd_buf_pos
    ld r3, [r3]

    ; If they're the same, we're done
    cmp r2, r3
    jmp@eq _kbd_get_event_done

    ; Get value
    ldi r2, KBD_BUF_POS
    add r2, r3
    ld r0, [r2]

    ; Increment buffer position
    ldi r2, KBD_BUF_MASK
    inc r3
    and r3, r2
    st [_kbd_buf_pos], r3

    ; If keycode is extended, read the rest
    ldi r2, KBD_EXT_CODE
    cmp r0, r2
    jmp@ne _kbd_get_event_no_ext

    ; Save r0 into r2 and get the rest
    mov r2, r0
    call kbd_get_event
    
    ; Shift ext code to MSB
    shl r2, 8

    
_kbd_get_event_no_ext:
    ; If keycode is a release code, set r1 to 1 and read the rest
    ldi r3, KBD_REL_CODE
    cmp r0, r3
    jmp@ne _kbd_get_event_or

    ldi r1, 1
    call kbd_get_event

    ; Set r2 to 0 to not add an ext code
    xor r2, r2
    
_kbd_get_event_or:
    ; Or ext code just in case
    or r0, r2

_kbd_get_event_done:

    pop r3
    pop r2
    ret


_kbd_buf_pos:   .word 0
