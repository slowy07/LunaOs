
; input:
;	rax - empty or continuation of the previous checksum
;	rcx - space size in words (2 Bytes each)
;	rdi - pointer to the converted space
; output:
;	ax - checksum (Little-Endian)
service_network_checksum:
	; preserve the original registers
	push rbx
	push rcx
	push rdi

	; set the preliminary result
	xor ebx, ebx
	xchg rbx, rax

.calculate:
	; fetch 2 Bytes from the converted space
	mov ax, word [rdi]
	rol ax, STATIC_REPLACE_AL_WITH_HIGH_shift ; Big-Endian

	; sum it into the accumulator
	add rbx, rax

	; move the pointer to the next fragment
	add rdi, STATIC_WORD_SIZE_byte

	; process the remaining space
	loop .calculate

	; correct the checksum for the overflow
	mov ax, bx
	shr ebx, STATIC_MOVE_HIGH_TO_AX_shift
	add rax, rbx

	; return the result in reverse notation
	not ax

	; restore the original registers
	pop rdi
	pop rcx
	pop rbx

	; return from the procedure
	ret

	macro_debug "service_network_checksum"

; input:
;	rax - empty or continuation of the previous checksum
;	ecx - space size in words (2 Bytes each)
;	rdi - pointer to the converted space
; output:
;	ax - checksum (Little-Endian)
service_network_checksum_part:
	; preserve the original registers
	push rbx
	push rcx
	push rdi

	xor ebx, ebx

.calculate:
	; fetch 2 Bytes from the converted space
	mov bx, word [rdi]
	rol bx, STATIC_REPLACE_AL_WITH_HIGH_shift ; Big-Endian

	; sum it into the accumulator
	add rax, rbx

	; move the pointer to the next fragment
	add rdi, STATIC_WORD_SIZE_byte

	; process the remaining space
	loop .calculate

	; restore the original registers
	pop rdi
	pop rcx
	pop rbx

	; return from the procedure
	ret

	macro_debug "service_network_checksum_part"
