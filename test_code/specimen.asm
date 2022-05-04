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

    ; Update modifiers
    call kdb_update_modif_state

    ; If release, keep waiting
    cmp r1, r2
    jmp@ne kbd_loop

    
    ; Display character
    ldi r1, 1
    ldi r2, _kbd_shift_state
    ld r2, [r2]
    cmp r2, r1
    jmp@eq kbd_chose_shift

    ldi r1, 1
    ldi r2, _kbd_altgr_state
    ld r2, [r2]
    cmp r2, r1
    jmp@eq kbd_chose_altgr

    ldi r1, keymap_fr_be
    jmp kbd_disp

kbd_chose_shift:
    ldi r1, keymap_fr_be_shift
    jmp kbd_disp

kbd_chose_altgr:
    ldi r1, keymap_fr_be_altgr
    jmp kbd_disp

kbd_disp:
    ldi r2, 0xFF
    and r0, r2
    add r0, r1
    ld r1, [r0]
    ldi r0, charbuf
    st [charbuf], r1
    call term_print
    call term_flush

    jmp kbd_loop


.define KEYCODE_L_SHIFT 0x12
.define KEYCODE_L_CTRL  0x14
.define KEYCODE_L_ALT   0x11

.define KEYCODE_R_SHIFT 0x59
.define KEYCODE_R_CTRL  0xE014
.define KEYCODE_R_ALT   0xE011

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
    st [_kbd_shift_state], r1
    jmp _kdb_update_modif_state_end

_kdb_update_modif_state_ctrl:
    st [_kbd_ctrl_state], r1
    jmp _kdb_update_modif_state_end

_kdb_update_modif_state_alt:
    st [_kbd_alt_state], r1
    jmp _kdb_update_modif_state_end

_kdb_update_modif_state_altgr:
    st [_kbd_altgr_state], r1
    jmp _kdb_update_modif_state_end

_kdb_update_modif_state_end:
    pop r3
    pop r2
    pop r1
    pop r0
    ret


end:
    hlt

charbuf:      .str  " "


_kbd_shift_state:   .word 0
_kbd_alt_state:     .word 0
_kbd_altgr_state:   .word 0
_kbd_ctrl_state:    .word 0

teststr: .str "BRUH"