
; input:
;	rdi - address
; output:
;	rdi - address rounded up to a whole page
library_page_align_up:
	; create a local variable
	push rdi

	; drop the low bits of the address
	and di, STATIC_PAGE_mask

	; check whether the address equals the local variable
	cmp rdi, qword [rsp]
	je .end ; if so, done

	; advance the address by one frame
	add rdi, STATIC_PAGE_SIZE_byte

.end:
	; drop the local variable
	add rsp, STATIC_QWORD_SIZE_byte

	; return from the procedure
	ret

	macro_debug "library_page_align_up"
