; r0 string buffer
; r1 number
itoa10:
    push r0
    push r1
    push r2
    push r3
    push r4
    push r5
    push r6

    ; r5,r6 constains the string buffer
    mov r5, r0
    mov r6, r0
    ; r0 contains the number
    mov r0, r1
    ; r2 0 constant
    xor r2, r2
    ; r3 10 constant
    ldi r3, 10
    ; r4 0x30 constant
    ldi r4, 0x30
    ; sanity check for 0
    cmp r0, r2
    jmp@ne _itoa10_loop
    st [r5], r4
    inc r5
    st [r5], r2
    jmp _itoa_10_reverse_loop_end

_itoa10_loop:
    ; check if number is finished
    cmp r0, r2
    jmp@eq _itoa10_loop_end

    ; set divisor and divide
    mov r1, r3
    call div16

    ; add '0' to rest
    add r0, r4
    st [r5], r0
    ; add quotient back to r0
    mov r0, r1
    inc r5

    jmp _itoa10_loop

_itoa10_loop_end:
    ; set \0
    st [r5], r2
    dec r5

_itoa_10_reverse_loop:
    cmp r5, r6
    jmp@le _itoa_10_reverse_loop_end

    ld r3, [r5]
    ld r4, [r6]
    st [r5], r4
    st [r6], r3

    dec r5
    inc r6

    jmp _itoa_10_reverse_loop

_itoa_10_reverse_loop_end:
    pop r6
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    ret

title_str:      .str "  RPN Calculator 2.0"
prompt_str:     .str ">           "
add_str:        .str "+"
sub_str:        .str "-"
mul_str:        .str "*"
div_str:        .str "/"
modulo_str:     .str "%"
drop_str:       .str "d"
result_str:     .str "result"