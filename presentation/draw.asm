; Draw horizontal line
; r0: X position
; r1: Y position
; r2: Length
; r3: Character
draw_h_line:
    push r0
    push r1
    push r2
    push r3
    push r4

    ; Calculate start address
    ldi r4, TERM_WIDTH
    mul r1, r4
    add r0, r1
    ldi r1, _term_temp_buffer
    add r0, r1

    ; Get color and set chracter to a horizontal line
    ld r4, [_term_color]
    or r3, r4

_draw_h_line_loop:
    st [r0], r3

    ; If not done, continue
    inc r0
    dec r2
    jmp@ne _draw_h_line_loop

    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    ret


; Draw vertical line
; r0: X position
; r1: Y position
; r2: Length
; r3: Character
draw_v_line:
    push r0
    push r1
    push r2
    push r3
    push r4

    ; Calculate start address
    ldi r4, TERM_WIDTH
    mul r1, r4
    add r0, r1
    ldi r1, _term_temp_buffer
    add r0, r1

    ; Get color and set chracter to a horizontal line
    ld r4, [_term_color]
    or r3, r4

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

; Draw char
; r0: X position
; r1: Y position
; r2: Character
draw_char:
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
    ld r3, [_term_color]
    or r2, r3

    ; Write character
    st [r0], r2

    pop r3
    pop r2
    pop r1
    pop r0
    ret


; Draw rectangle
; r0: X position
; r1: Y position
; r2: Width
; r3: Height
draw_rect:
    push r0
    push r1
    push r2
    push r3
    push r4
    push r5

    ; Draw corners
    mov r4, r2

    ldi r2, 5
    call draw_char

    add r0, r4
    dec r0
    ldi r2, 6
    call draw_char

    add r1, r3
    dec r1
    ldi r2, 8
    call draw_char

    inc r0
    sub r0, r4
    ldi r2, 7
    call draw_char

    ; Draw sides
    mov r5, r3

    inc r0
    inc r1
    sub r1, r5
    mov r2, r4
    dec r2
    dec r2
    ldi r3, 11
    call draw_h_line

    dec r0
    inc r1
    mov r2, r5
    dec r2
    dec r2
    ldi r3, 9
    call draw_v_line

    inc r0
    add r1, r5
    dec r1
    dec r1
    mov r2, r4
    dec r2
    dec r2
    ldi r3, 12
    call draw_h_line

    add r0, r4
    dec r0
    dec r0
    inc r1
    inc r1
    sub r1, r5
    mov r2, r5
    dec r2
    dec r2
    ldi r3, 10
    call draw_v_line

    pop r5
    pop r4 
    pop r3
    pop r2
    pop r1
    pop r0
    ret



; Draw filled rectangle
; r0: X position
; r1: Y position
; r2: Width
; r3: Height
draw_filled_rect:
    push r0
    push r1
    push r2
    push r3
    push r4
    
    ; Draw normal rectangle
    call draw_rect

    ; Calculate new variables for filling
    inc r0
    inc r1
    dec r2
    dec r2
    dec r3
    dec r3

    ; Fill loop
_draw_filled_rect_loop:
    mov r4, r3
    xor r3, r3
    call draw_h_line
    mov r3, r4

    inc r1
    dec r3
    jmp@ne _draw_filled_rect_loop


    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    ret