; Configuration
.define VGA_VRAM_BASE       0xE000
.define VGA_CRAM_BASE       0xF800
.define TERM_WIDTH          80
.define TERM_HEIGHT         60
.define TERM_HEIGHT_M_1     59      ; 60 - 1
.define VRAM_LEN            4800    ; 80 * 60
.define VRAM_LEN_NO_FIRST   4720    ; 80 * (60 - 1)
.define CRAM_LEN            512
; TODO: Update CRAM len to 1024 when addition CRAM is installed

; Initialize terminal
term_init:
    push r0
    
    ; Init color
    ldi r0, 0x0F00
    st [_term_color], r0

    ; Load default font
    .call term_load_default_font

    ; Clear the screen and init cursor to (0, 0)
    .call term_clear_screen

    pop r0
    ret


; Load default font into CRAM
term_load_default_font:
    push r0
    push r1
    push r2

    ldi r0, VGA_CRAM_BASE
    ldi r1, _term_default_font
    ldi r2, CRAM_LEN
    .call memcpy

    pop r2
    pop r1
    pop r0
    ret


; Clear screen with the current color and set cursor to 0
term_clear_screen:
    push r0
    push r1
    push r2

    ; Load frame buffer address, size and clear color
    ldi r0, _term_temp_buffer
    ldi r1, VRAM_LEN        ; 80 * 60
    ldi r2, _term_color
    ld r2, [r2]

    ; Clear screen with color
_term_clear_screen_loop:
    st [r0], r2

    ; Increment counter
    inc r0

    ; Continue if not done
    dec r1
    jmp@ne _term_clear_screen_loop

    ; Set cursor pos to (0, 0)
    xor r0, r0
    xor r1, r1
    .call term_set_cursor

    pop r2
    pop r1
    pop r0
    ret

; Copy terminal buffer to frame buffer
term_flush:
    push r0
    push r1
    push r2

    ldi r0, VGA_VRAM_BASE
    ldi r1, _term_temp_buffer
    ldi r2, VRAM_LEN
    .call memcpy

    pop r2
    pop r1
    pop r0
    ret


; Set cursor position
; r0: Pos X
; r1; Pos Y
term_set_cursor:
    st [_term_cursor_x], r0
    st [_term_cursor_y], r1
    ret

; Get cursor position
; return r0: Pos X
; return r1; Pos Y
term_get_cursor:
    ldi r0, _term_cursor_x
    ldi r1, _term_cursor_y
    ld r0, [r0]
    ld r1, [r1]
    ret


; Set color
; r0: Color
term_set_color:
    st [_term_color], r0
    ret


; Get color
; return r0: Color
term_get_color:
    ldi r0, _term_color
    ld r0, [r0]
    ret


; Scroll screen
term_scroll_up:
    push r0
    push r1
    push r2
    push r3

    ; Put line 0 addres in r0 and line 1 in r1
    ldi r0, _term_temp_buffer
    ldi r1, TERM_WIDTH
    add r1, r0

    ; Copy 80 * (60 - 1) chacaters from line 1 to line 0
    ldi r2, VRAM_LEN_NO_FIRST
_term_scroll_up_loop:
    ; Copy data
    ld r3, [r1]
    st [r0], r3

    ; Increment cursors
    inc r0
    inc r1

    ; Decrement counter and continue if not done
    dec r2
    jmp@ne _term_scroll_up_loop

    ; Set r1 to the beginning of the last line
    ldi r0, TERM_WIDTH
    sub r1, r0

    ; Clear last line
    mov r2, r0
    ldi r0, _term_color
    ld r0, [r0]
_term_scroll_up_clear_loop:
    st [r1], r0

    ; Increment counter
    inc r1

    ; Decrement counter and continue if not done
    dec r2
    jmp@ne _term_scroll_up_clear_loop


    pop r3
    pop r2
    pop r1
    pop r0
    ret


; Go to a new line
term_new_line:
    push r0
    push r1

    ; Set X cursor position to 0
    xor r0, r0
    st [_term_cursor_x], r0

    ; Get current Y positions
    ldi r0, _term_cursor_y
    ld r0, [r0]

    ; If not on the last line, increment Y pos
    ldi r1, TERM_HEIGHT_M_1
    cmp r0, r1
    jmp@ge _term_new_line_no_inc
    inc r0
    st [_term_cursor_y], r0
    jmp _term_new_line_no_scroll
_term_new_line_no_inc:
    .call term_scroll_up
_term_new_line_no_scroll:

    pop r1
    pop r0
    ret


; Print null terminated string
; r0: string pointer
term_print:
    push r0
    push r1
    push r2
    push r3
    push r4
    push r5
    push r6

    ; Set r3 to the terminal color, r4 to the terminal width
    ldi r3, _term_color
    ldi r4, TERM_WIDTH
    ld r3, [r3]

_term_print_loop:
    ; Load character from string
    ld r1, [r0]

    ; Increment string cursor
    inc r0

    ; If null, end loop
    xor r2, r2
    cmp r1, r2
    jmp@eq _term_print_loop_end

    ; If it's a new line, go to next line and print next character
    ldi r2, 0x10    ; TODO: Check that this is indeed '\n'
    cmp r1, r2
    jmp@ne _term_print_loop_not_lf
    .call term_new_line
_term_print_loop_not_lf:

    ; Load X and Y position
    ldi r5, _term_cursor_x
    ldi r6, _term_cursor_y
    ld r5, [r5]
    ld r6, [r6]

    ; Multiply y pos by term width
    ; TODO: switch out r3 and r2 everywhere to avoid needing to do this
    mov r2, r3
    mul r6, r4
    mov r3, r2

    ; Calculate position in framebuffer
    ldi r2, _term_temp_buffer
    add r2, r5
    add r2, r6

    ; Add color to the character and print it
    or r1, r3
    st [r2], r1

    ; Increment X cursor and check that it's within bound. If yes, continue loop
    inc r5
    st [_term_cursor_x], r5
    cmp r5, r4
    jmp@lo _term_print_loop

    ; Since it was at the end, go to new line and continue
    .call term_new_line
    jmp _term_print_loop

_term_print_loop_end:
    pop r6
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    ret

; Print null terminated string
; r0: string pointer
term_println:
    .call term_print
    .call term_new_line
    ret


_term_cursor_x:     .word 0
_term_cursor_y:     .word 0
_term_color:        .word 0x0F00
_term_temp_buffer:  .skip 4800
_term_default_font: .incbin "font.bin"