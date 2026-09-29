;===============================================================================

;===============================================================================
kernel_gui_clock:
	; preserve the original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	; fetch the current RTC clock time
	call	driver_rtc_get_date_and_time
	mov	rax,	qword [rel driver_rtc_date_and_time]

	; did the time change?
	cmp	qword [rel kernel_gui_clock_last_state],	rax
	je	.end	; no, end of the procedure handling

	; save the new time stamp
	mov	qword [rel kernel_gui_clock_last_state],	rax

	; at each time change (second) hide/show the colon
	mov	bl,	byte [rel kernel_gui_clock_colon]
	xchg	bl,	byte [rel kernel_gui_window_taskbar.element_label_clock_char_colon]
	mov	byte [rel kernel_gui_clock_colon],	bl

	;-----------------------------------------------------------------------
	; Minute
	;-----------------------------------------------------------------------
	shr	rax,	STATIC_MOVE_HIGH_TO_AL_shift	; move the number of minutes to register AX
	and	eax,	0xFF	; remove the hour, day, month... information
	mov	ebx,	STATIC_NUMBER_SYSTEM_decimal
	mov	ecx,	0x02	; display two digits (prefix)
	mov	dl,	STATIC_SCANCODE_DIGIT_0	; the prefix is the digit "0"
	mov	rdi,	kernel_gui_window_taskbar.element_label_clock_string_minute
	macro_library	LIBRARY_STRUCTURE_ENTRY.integer_to_string

	; fetch the current time stamp
	mov	rax,	qword [rel kernel_gui_clock_last_state]

	;-----------------------------------------------------------------------
	; Hour
	;-----------------------------------------------------------------------
	shr	rax,	STATIC_MOVE_HIGH_TO_AX_shift	; move the number of hours to register AL
	and	rax,	0xFF	; remove the day, month, year... information
	mov	dl,	STATIC_SCANCODE_SPACE	; the prefix is "space"
	mov	rdi,	kernel_gui_window_taskbar.element_label_clock_string_hour
	macro_library	LIBRARY_STRUCTURE_ENTRY.integer_to_string

	; update the "clock label" element in the taskbar window space
	mov	rdi,	kernel_gui_window_taskbar
	mov	rsi,	kernel_gui_window_taskbar.element_label_clock
	macro_library	LIBRARY_STRUCTURE_ENTRY.bosu_element_label

	; set the window flag: new content
	mov	al,	KERNEL_WM_WINDOW_update
	mov	rsi,	kernel_gui_window_taskbar
	int	KERNEL_WM_IRQ

.end:
	; restore the original registers
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"kernel_gui_clock"
