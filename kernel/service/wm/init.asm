;===============================================================================

	; fetch own PID
	call	kernel_task_active_pid
	mov	qword [rel kernel_wm_pid],	rax

	; invert the alpha channel of the cursor object
	mov	ecx,	kernel_wm_object_cursor.end - kernel_wm_object_cursor.data
	mov	rsi,	kernel_wm_object_cursor.data
	macro_library	LIBRARY_STRUCTURE_ENTRY.color_alpha_invert

	; fetch the size of the graphics card memory space in pixels and Bytes
	mov	bx,	word [rel kernel_video_width_pixel]
	mov	cx,	word [rel kernel_video_height_pixel]
	mov	edx,	dword [rel kernel_video_size_byte]

	; update the buffer properties
	mov	word [rel kernel_wm_object_framebuffer + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.width],	bx
	mov	word [rel kernel_wm_object_framebuffer + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.height],	cx
	mov	dword [rel kernel_wm_object_framebuffer + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.size],	edx

	; for higher performance in visualisation we give up double buffering,
	; the graphics card memory space is the buffer for us directly
	mov	rdi,	qword [rel kernel_video_base_address]

	; preserve the pointer to the beginning of the buffer space
	mov	qword [rel kernel_wm_object_framebuffer + KERNEL_WM_STRUCTURE_OBJECT.address],	rdi

	; prepare space for the object list
	call	kernel_memory_alloc_page
	call	kernel_page_drain	; clear
	mov	qword [rel kernel_wm_object_list_address],	rdi

	; prepare space for the object table
	call	kernel_memory_alloc_page
	call	kernel_page_drain	; clear
	mov	qword [rel kernel_wm_object_table_address],	rdi

	; prepare space for the fill list
	call	kernel_memory_alloc_page
	call	kernel_page_drain	; clear
	mov	qword [rel kernel_wm_fill_list_address],	rdi

	; prepare space for the zone list
	call	kernel_memory_alloc_page
	call	kernel_page_drain	; clear
	mov	qword [rel kernel_wm_zone_list_address],	rdi

	; attach the "window management system" handler procedure
	mov	rax,	KERNEL_WM_IRQ
	mov	bx,	KERNEL_IDT_TYPE_isr
	mov	rdi,	kernel_wm_irq
	call	kernel_idt_mount

	; window manager initialised
	mov	byte [rel kernel_wm_semaphore],	STATIC_TRUE

.wait:
	; objects registered on the list?
	cmp	qword [rel kernel_wm_object_list_length],	STATIC_EMPTY
	je	.wait	; no, wait
