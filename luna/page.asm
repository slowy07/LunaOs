;===============================================================================

;===============================================================================
; 16-bit main boot program code =================================
;===============================================================================
[bits 16]

;===============================================================================
; in:
;	di - address in logical address space
; out:
;	di - address aligned up to a full page
zero_page_align_up:
	; create a local variable
	push	edi

	; clear the low part of the address
	and	edi,	0xF000

	; check whether the address equals the local variable
	cmp	edi,	dword [esp]
	je	.end	; if so, we are done

	; advance the address by one frame
	add	edi,	0x1000
.end:
	; drop the local variable
	add	esp,	0x04

	; return from the routine
	ret
