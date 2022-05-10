; Draw horizontal line
; r0: X position
; r1: Y position
; r2: Length
draw_h_line:
    push r0
    push r1
    push r2
    push r3

    ; Calculate start address
    ldi r3, TERM_WIDTH
    mul r1, r3
    add r0, r1
    ldi r1, _term_temp_buffer
    add r0, r1

    ; Get color and set chracter to a horizontal line
    ldi r4, 45
    ld r3, [_term_color]
    add r3, r4

_draw_h_line_loop:
    st [r0], r3

    ; If not done, continue
    inc r0
    dec r2
    jmp@ne _draw_h_line_loop

    pop r3
    pop r2
    pop r1
    pop r0
    ret


; Draw vertical line
; r0: X position
; r1: Y position
; r2: Length
draw_v_line:
    push r0
    push r1
    push r2
    push r3
    push r4

    ; Calculate start address
    ldi r3, TERM_WIDTH
    mul r1, r3
    add r0, r1
    ldi r1, _term_temp_buffer
    add r0, r1

    ; Get color and set chracter to a vertical line
    ldi r4, 124
    ld r3, [_term_color]
    add r3, r4

    ldi r4, TERM_WIDTH

_draw_v_line_loop:
    st [r0], r3

    ; If not done, continue
    add r0, r4
    dec r2
    jmp@ne _draw_v_line_loop

    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    ret

