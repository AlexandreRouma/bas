.org 0x0000

start:
    ; Init the stack
    ldi rsp, 0x8000

    ; Initialize the terminal
    call term_init
    call term_clear_screen
    call term_flush

    ; Print MOTD
    ldi r0, motd_str
    call term_println
    call term_new_line

    ldi r0, begin_str
    call term_println
    call term_new_line
    call term_flush

    ; Wait for any key to be pressed
    xor r2, r2
    xor r3, r3
rand_loop_thing:
    call kbd_get_event
    
    ; Increment random seed
    inc r3

    ; If no event occured, continue waiting
    cmp r0, r2
    jmp@eq rand_loop_thing

    ; Keep track of modifiers
    call kdb_update_modif_state

    ; If this was a key release, continue waiting
    cmp r1, r2
    jmp@eq rand_loop_thing

game_loop:
    ; Select random word
    mov r0, r3
    call rand_seed
    call select_rand_word
    mov r5, r0

    ; DEBUG ONLY: print word
    ;call term_println
    ;call term_flush
    
question_loop:
    ; Save cursor y pos to r7
    call term_get_cursor
    mov r7, r1

    ; Show prompt
    ldi r0, prompt_str
    call term_print
    call term_flush

    ; Move cursor back to beginning
    ldi r0, 2
    mov r1, r7
    call term_set_cursor

    ; Read input
    ldi r0, input_buffer
    ldi r1, 5
    call kbd_read_line

    ; Move cursor back to beginning again
    mov r2, r0
    ldi r0, 2
    mov r1, r7
    call term_set_cursor
    mov r0, r2

    ; Compare strings and give feed back
    mov r1, r5
    call compare_words
    call term_new_line

    ; If score is 5, win
    ldi r1, 5
    cmp r2, r1
    jmp@eq question_win

    ; If false, continue prompting
    jmp question_loop

question_win:
    call term_new_line
    ldi r0, win_str
    call term_println
    call term_flush

    ; Wait for a keypress
    call kbd_wait_key

    ; Clear the screen
    call term_clear_screen

    ; Print MOTD
    ldi r0, motd_str
    call term_println
    call term_new_line
    call term_flush


    jmp game_loop


; Compare and reprint
; r0: Typed string
; r1: Wanted string
; return r2: Score
compare_words:
    push r0
    push r1
    push r3
    push r4
    push r5
    push r6
    push r7

    ; Save target string in r7
    mov r7, r1

    ; Save current term color
    mov r2, r0
    call term_get_color
    mov r6, r0
    mov r0, r2

    xor r2, r2

_compare_words_loop:
    ld r3, [r0]
    ld r4, [r1]

    ; If null, goto end
    xor r5, r5
    cmp r3, r5
    jmp@eq _compare_words_end

    ; Increment cursors
    inc r0
    inc r1

    ; Default color is white on black
    ldi r5, 0x0F00

    ; If equal, increase score and set color to green on black
    cmp r3, r4
    jmp@ne _compare_words_no_score

    inc r2
    ldi r5, 0x0200

    push r0
    push r1
    push r2
    jmp _compare_words_print

_compare_words_no_score:
    ; Save r0 and print char in the right color
    push r0
    push r1
    push r2

    ; Check if the current character is contained within the current word
    mov r0, r7
    mov r1, r3
    call str_contains

    ; If not, jump to print stage
    xor r0, r0
    cmp r2, r0
    jmp@eq _compare_words_print

    ; Set color to yellow
    ldi r5, 0x0300

_compare_words_print:    
    mov r0, r5
    call term_set_color
    ldi r0, _compare_words_cbuf
    st [r0], r3
    call term_print

    ; Restore r0 for the next iteration
    pop r2
    pop r1
    pop r0

    jmp _compare_words_loop
    

_compare_words_end:
    ; Restore color
    mov r0, r6
    call term_set_color

    pop r7
    pop r6
    pop r5
    pop r4
    pop r3
    pop r1
    pop r0
    ret

_compare_words_cbuf: .str " "

; Select random word from the list
; return r0: pointer to string
select_rand_word:
    push r1
    push r2
    push r3
    push r4

    xor r2, r2

    ; Get random number
    call rand
    ldi r1, WORD_LIST_MASK
    and r0, r1

    ; Get n'th string according to r0
    ldi r1, word_list
_select_rand_word_loop:
    cmp r0, r2
    jmp@eq _select_rand_word_end
    dec r0

    mov r3, r0
    mov r0, r1
    call strlen
    add r1, r0
    inc r1
    mov r0, r3

    jmp _select_rand_word_loop

_select_rand_word_end:
    mov r0, r1

    pop r4
    pop r3
    pop r2
    pop r1
    ret

end:
    

input_buffer: .skip 6
numbuf: .skip 5