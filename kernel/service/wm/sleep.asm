;===============================================================================

;===============================================================================
kernel_wm_sleep:
	; no objects on the list?
	cmp	qword [kernel_wm_object_list_length],	STATIC_EMPTY
	je	.end	; yes

	; continue waiting
	jmp	kernel_wm_sleep

.end:
	; return from the procedure
	ret

	; information for Bochs
	macro_debug	"kernel_wm_sleep"
