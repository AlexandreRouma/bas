.define KBD_BASE        0xDF00
.define KBD_BUF_POS     0xDFFF
.define KBD_BUF_MASK    0x7F
.define KBD_EXT_CODE    0xE0
.define KBD_REL_CODE    0xF0

; Get latest keyboard event from buffer
; return r0: Event, 0x0000 if no event occured
; return r1: 0 if pressed, 1 if released
; IMPORTANT: If called, you MUST call kdb_update_modif_state if you wish to keep track of the modifiers
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
    ldi r2, KBD_BASE
    add r2, r3
    ld r0, [r2]

    ; Increment buffer position
    ldi r2, KBD_BUF_MASK
    inc r3
    and r3, r2
    st [_kbd_buf_pos], r3

    ; If the keycode is extended, read the rest
    ldi r2, KBD_EXT_CODE
    cmp r0, r2
    jmp@ne _kbd_get_event_no_ext

    ; Since it's extended, put EXT in MSB 
    mov r2, r0
    shl r2, 8

    ; Wait for the rest and put in LSB
    call kbd_wait_event
    or r0, r2

_kbd_get_event_no_ext:
    ; Check if code is a release code
    ldi r2, 0x00FF
    mov r3, r0
    and r3, r2
    ldi r2, KBD_REL_CODE
    cmp r3, r2
    jmp@ne _kbd_get_event_done

    ; Since it was released, read rest and keep ext code
    ldi r2, 0xFF00
    and r2, r0
    call kbd_wait_event
    or r0, r2

    ldi r1, 1

_kbd_get_event_done:
    pop r3
    pop r2
    ret


; Wait for an event
; return r0: Event, 0x0000 if no event occured
; return r1: 0 if pressed, 1 if released
kbd_wait_event:
    push r2

    xor r2, r2

_kbd_wait_event_loop:
    call kbd_get_event
    cmp r0, r2
    jmp@eq _kbd_wait_event_loop

    ; Update the modifiers
    call kdb_update_modif_state

    pop r2
    ret


kdb_update_modif_state:
    push r0
    push r1
    push r2
    push r3

    ldi r2, 1
    xor r1, r2

    ; Detect shift
    ldi r2, KEYCODE_L_SHIFT
    cmp r0, r2
    jmp@eq _kdb_update_modif_state_shift
    ldi r2, KEYCODE_R_SHIFT
    cmp r0, r2
    jmp@eq _kdb_update_modif_state_shift

    ; Detect ctrl
    ldi r2, KEYCODE_L_CTRL
    cmp r0, r2
    jmp@eq _kdb_update_modif_state_ctrl
    ldi r2, KEYCODE_R_CTRL
    cmp r0, r2
    jmp@eq _kdb_update_modif_state_ctrl

    ; Detect alt
    ldi r2, KEYCODE_L_ALT
    cmp r0, r2
    jmp@eq _kdb_update_modif_state_alt

    ; Detect altgr
    ldi r2, KEYCODE_R_ALT
    cmp r0, r2
    jmp@eq _kdb_update_modif_state_altgr

    jmp _kdb_update_modif_state_end

_kdb_update_modif_state_shift:
    st [KBD_SHIFT_STATE], r1
    jmp _kdb_update_modif_state_end

_kdb_update_modif_state_ctrl:
    st [KBD_CTRL_STATE], r1
    jmp _kdb_update_modif_state_end

_kdb_update_modif_state_alt:
    st [KBD_ALT_STATE], r1
    jmp _kdb_update_modif_state_end

_kdb_update_modif_state_altgr:
    st [KBD_ALTGR_STATE], r1
    jmp _kdb_update_modif_state_end

_kdb_update_modif_state_end:
    pop r3
    pop r2
    pop r1
    pop r0
    ret


; Wait until a key is pressed
; return r0: Keycode
kbd_wait_key:
    push r1
    push r2

    xor r2, r2

    ; Wait until a key pressed event occurs
_kbd_wait_key_loop:
    call kbd_wait_event
    cmp r1, r2
    jmp@ne _kbd_wait_key_loop

    pop r2
    pop r1
    ret


; Wait until a key is pressed and translate into associated character
kbd_wait_char:
    push r1
    push r2

    ; Wait for a key press
    call kbd_wait_key

    ; Decode keycode into character according to modifiers
    ldi r1, 1
    ld r2, [KBD_SHIFT_STATE]
    cmp r2, r1
    jmp@eq _kbd_wait_char_shift

    ldi r1, 1
    ld r2, [KBD_ALTGR_STATE]
    cmp r2, r1
    jmp@eq _kbd_wait_char_altgr

    ldi r1, keymap_fr_be
    jmp _kbd_wait_char_next

_kbd_wait_char_shift:
    ldi r1, keymap_fr_be_shift
    jmp _kbd_wait_char_next

_kbd_wait_char_altgr:
    ldi r1, keymap_fr_be_altgr
    jmp _kbd_wait_char_next

_kbd_wait_char_next:
    ldi r2, 0xFF
    and r0, r2
    add r0, r1
    ld r0, [r0]

    pop r2
    pop r1
    ret


; Read characters from keyboard until buffer is full or return is pressed
; r0: String buffer
; r1: Max number of characters to read
kbd_read_line:
    push r0
    push r1
    push r2
    push r3

    ; Move the string pointer to r3
    mov r3, r0

_kbd_read_line_loop:
    call kbd_wait_char

    ; If return was pressed, end
    ldi r2, 0x0A
    cmp r0, r2
    jmp@eq _kbd_read_line_end

    ; If null, continue waiting
    xor r2, r2
    cmp r0, r2
    jmp@eq _kbd_read_line_loop

    ; Write character to string
    st [r3], r0

    ; Write character to screen
    st [_kbd_read_line_buf], r0
    ldi r0, _kbd_read_line_buf
    call term_print
    call term_flush

    ; Increment counter and continue if there is still enough space
    xor r2, r2
    inc r3
    dec r1
    cmp r1, r2
    jmp@ne _kbd_read_line_loop

_kbd_read_line_end:
    xor r2, r2
    st [r3], r2

    pop r3
    pop r2
    pop r1
    pop r0
    ret

_kbd_read_line_buf: .str " "

_kbd_buf_pos:       .word 0
KBD_SHIFT_STATE:    .word 0
KBD_ALT_STATE:      .word 0
KBD_ALTGR_STATE:    .word 0
KBD_CTRL_STATE:     .word 0