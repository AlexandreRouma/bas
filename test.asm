.org 0x0000

jmp start
ret

start:
    ldi rsp, 0x8000

    ldi r0, 0
    ldi r1, 1

    cmp r0, r1
    jmp@gr cond_true

cond_false:
    ldi r0, 0xFA15
    hlt

cond_true:
    ldi r0,0x7E
    hlt