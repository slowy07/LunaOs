
; input:
;	rcx - size in bytes
; output:
;	rcx - size in pages, rounded up
library_page_from_size:
	; local variable
	push	rcx

	; drop the low bits of the size
	and	cx,	STATIC_PAGE_mask

	; check whether the size already matches
	cmp	rcx,	qword [rsp]
	je	.ready	; if so, done

	; advance the size by one page
	add	rcx,	STATIC_PAGE_SIZE_byte

.ready:
	; convert to pages
	shr	rcx,	STATIC_DIVIDE_BY_PAGE_shift

	; drop the local variable
	add	rsp,	STATIC_QWORD_SIZE_byte

	; return from the procedure
	ret

	macro_debug	"library_page_from_size"
