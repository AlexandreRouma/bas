.org 0x0000

start:
    ; Init the stack
    ldi rsp, 0x8000

    ; Initialize the terminal
    call term_init

game_loop:
    ; Clear screen
    call term_clear_screen
    call term_flush

    ; Print MOTD
    ldi r0, 2
    ldi r1, 1
    call term_set_cursor
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

    ; Select random word
    mov r0, r3
    call rand_seed
    call select_rand_word
    call strlen
    mov r5, r0
    mov r6, r1
    
question_loop:
    ldi r0, prompt_str
    call term_print
    call term_flush

    call term_get_cursor
    ldi r0, 2
    call term_set_cursor
    ldi r0, 0x2F00
    call term_set_color
    mov r0, r5
    call term_print
    call term_flush

    hlt


    jmp question_loop

    jmp game_loop

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
    

numbuf: .skip 5