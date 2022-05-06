.org 0x0000
jmp start
jmp _int_handler

start:
    ; Init terminal
    call term_init
    call term_clear_screen
    call term_flush

    ; Enable interrupts
    ldi r0, 8
    or rfl, r0

inf_loop:
    jmp inf_loop
    

end:
    hlt

frame_count: .word 0

on_vsync:
    ; Do tetris stuff

    ; Load and increment counter
    ld r1, [frame_count]
    inc r1
    st [frame_count], r1

    ; Goto end if not at 60
    ldi r0, 60
    cmp r1, r0
    jmp@ne _on_vsync_end

    ; Roll around counter
    xor r1, r1
    st [frame_count], r1

_on_vsync_once_every_500ms:


_on_vsync_end:
    ret

_int_handler:
    ; Save all registers
    push rfl
    push r0
    push r1
    push r2
    push r3
    push r4
    push r5
    push r6
    push r7
    push r8
    push r9
    push r10
    push r11
    push r12
    push rxt

    ; Disable interrupts
    ldi r0, 0xF7
    and rfl, r0

    ; Run real handler
    call on_vsync

    ; Restore registers
    pop rxt
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop r7
    pop r6
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    pop rfl
    ret

test_msg: .str "Timer!"