div16:
    push r2

    xor r2, r2

_div16_loop:
    cmp r0, r1
    jmp@lo _div16_done

    inc r2
    sub r0, r1

    jmp _div16_loop

_div16_done:
    mov r1, r2
    pop r2
    ret