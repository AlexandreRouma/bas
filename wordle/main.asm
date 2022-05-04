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

    ; 

    jmp game_loop

; Select random word from the list
; return r0: pointer to string
; return r1: length of string
select_rand_word:
    push r0
    push r1

    ; Get random number
    call rand
    ldi r1, WORD_LIST_MASK
    and r0, r1

    ; Get n'th string according to r0
    ldi r1, word_list
_select_rand_word_loop:



    pop r1
    pop r0
    ret

end:
    