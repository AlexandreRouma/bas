rand_entropy: .word 0x4269

; Seeds the entropy
; r0: data to seed the entropy with
rand_seed:
	push r1

	ld r1, [rand_entropy]
	xor r1, r0
	st [rand_entropy], r1

	pop r1
	ret

; Gets a random word
; return r0: the random word
rand:
	push r1
	push r2
	push rxt
	
	ld r0, [rand_entropy]
	ldi r1, 65521
	ldi r2, 69
	mul r0, r1
	add r0, r2

	st [rand_entropy], r0

	pop rxt
	pop r2
	pop r1
	ret

