;===============================================================================

;===============================================================================
kernel_wm_cursor:
	; preserve the original registers
	push	rsi

	;-----------------------------------------------------------------------
	; display the new content of the cursor matrix?
	;-----------------------------------------------------------------------
	test	word [rel kernel_wm_object_cursor + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_flush
	jz	.no	; no

	; register the cursor zone
	mov	rsi,	kernel_wm_object_cursor
	call	kernel_wm_fill_insert_by_object
	call	kernel_wm_fill

	; the cursor object has been displayed
	and	word [rel kernel_wm_object_cursor + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	~KERNEL_WM_OBJECT_FLAG_flush

.no:
	; restore the original registers
	pop	rsi

	; return from the procedure
	ret

	macro_debug	"kernel_wm_cursor"
