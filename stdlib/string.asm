; Get length of a null terminate string
; r0: String pointer
; returns: r1: string length
strlen:
    push r0
    push r2
    push r3
    
    ; Zero out the length and keep a zero in r3
    xor r1, r1
    xor r3, r3

    ; Loop until char is null
_strlen_loop:
    ; Load character
    ld r2, [r0]

    ; Stop if null
    cmp r2, r3
    jmp@eq _strlen_end

    ; Increment counters and restart loop
    inc r0
    inc r1
    jmp _strlen_loop

_strlen_end:
    pop r3
    pop r2
    pop r0
    ret


; Turn usigned number into a hex string
; r0: 5 word buffer
; r1: Number
itoa16:
    push r0
    push r2
    push r3

    ; Load alphabet in r2
    ldi r2, _itoa_alphabet

    ; Nibble 3
    mov r3, r1
    shr r3, 12
    add r3, r2
    ld r3, [r3]
    st [r0], r3
    inc r0

    ; Nibble 2
    mov r3, r1
    shl r3, 4
    shr r3, 12
    add r3, r2
    ld r3, [r3]
    st [r0], r3
    inc r0

    ; Nibble 1
    mov r3, r1
    shl r3, 8
    shr r3, 12
    add r3, r2
    ld r3, [r3]
    st [r0], r3
    inc r0

    ; Nibble 0
    mov r3, r1
    shl r3, 12
    shr r3, 12
    add r3, r2
    ld r3, [r3]
    st [r0], r3
    inc r0

    ; Null termination
    xor r3, r3
    st [r0], r3

    pop r3
    pop r2
    pop r0
    ret

_itoa_alphabet: .str "0123456789ABCDEF"

; Copy section of memory from one place to another
; r0: Destination
; r1: Source
; r2: Size
memcpy:
    push r0
    push r1
    push r2
    push r3

_memcpy_loop:
    ; Copy data
    ld r3, [r1]
    st [r0], r3

    ; Increment cursors
    inc r0
    inc r1

    ; Decrement counter and continue if not done
    dec r2
    jmp@ne _memcpy_loop

    pop r3
    pop r2
    pop r1
    pop r0
    ret


; Check if a string contains a character
; r0: String pointer
; r1: Character
; return r2: 1 if the string contains the character, 0 otherwise
str_contains:
    push r0
    push r3
    push r4

    xor r2, r2
    xor r4, r4

_str_contains_loop:
    ld r3, [r0]
    inc r0

    ; End if null
    cmp r3, r4
    jmp@eq _str_contains_end

    ; End if string contains character and set r2 to 1
    cmp r3, r1
    jmp@ne _str_contains_loop

    inc r2

_str_contains_end:
    pop r4
    pop r3
    pop r0
    ret