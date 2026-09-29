;===============================================================================

;===============================================================================
kernel_gui_ipc_wm:
	; a message unrelated to the mouse?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.type],	KERNEL_IPC_TYPE_MOUSE
	jne	.end	; no

	; fetch the window identifier and the coordinates of the cursor pointer
	mov	rax,	qword [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_IPC_STRUCTURE_DATA_MOUSE.object_id]
	mov	r8w,	word [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_IPC_STRUCTURE_DATA_MOUSE.x]
	mov	r9w,	word [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_IPC_STRUCTURE_DATA_MOUSE.y]

	; right mouse button pressed?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_IPC_STRUCTURE_DATA_MOUSE.event],	KERNEL_IPC_MOUSE_EVENT_right_press
	je	.right_mouse_button	; yes

	; does the action concern the "menu" window?
	cmp	rax,	qword [rel kernel_gui_window_menu + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.id]
	jne	.left_mouse_button_no_menu	; no

	; is the window visible?
	test	word [rel kernel_gui_window_menu + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_visible
	jz	.end	; no, ignore the action

	; the window was hidden automatically, remove the flag
	and	word [rel kernel_gui_window_menu + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	~LIBRARY_BOSU_WINDOW_FLAG_visible

	; check which window element the action concerns
	mov	rsi,	kernel_gui_window_menu
	macro_library	LIBRARY_STRUCTURE_ENTRY.bosu_element
	jc	.end	; no action

	; does the element have an action handler procedure assigned?
	cmp	qword [rsi + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.event],	STATIC_EMPTY
	je	.end	; no, end of the action handling

	; run the procedure associated with the element
	push	.end	; return from the procedure
	push	qword [rsi + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.event]
	ret	; invoke it

.left_mouse_button_no_menu:
	; does the action concern the "taskbar" window?
	cmp	rax,	qword [rel kernel_gui_window_taskbar + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.id]
	jne	.end	; no

	; run the action related to the taskbar
	call	kernel_gui_taskbar_event

	; end of the message handling
	jmp	.end

.right_mouse_button:
	; does the action concern the "taskbar" window?
	cmp	rax,	qword [rel kernel_gui_window_taskbar + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.id]
	je	.end	; yes, no action yet

	; does the action concern the "background" window?
	cmp	rax,	qword [rel kernel_gui_window_workbench + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.id]
	jne	.end	; no

	; correct the position of the "menu" window
	mov	rbx,	qword [rel kernel_gui_window_menu + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.id]
	call	kernel_wm_object_by_id

	; does the cursor pointer position allow displaying the "menu" window?
	mov	ax,	r8w
	add	ax,	word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	cmp	ax,	word [rel kernel_gui_window_workbench + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	jl	.y	; yes on the X axis

	; display the "menu" window on the left side of the cursor pointer
	sub	r8w,	word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]

.y:
	; does the cursor pointer position allow displaying the "menu" window? (taking the "taskbar" window height into account)
	mov	ax,	r9w
	add	ax,	word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
	cmp	ax,	word [rel kernel_gui_window_taskbar + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
	jl	.visible	; yes on the Y axis

	; display the "menu" window above the "taskbar" window
	mov	r9w,	word [rel kernel_gui_window_taskbar + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
	sub	r9w,	word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
	dec	r9w	; keep 1 pixel of space between the "menu" and "taskbar" windows (a matter of taste)

.visible:
	; set the new position of the "menu" window
	mov	word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.x],	r8w
	mov	word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.y],	r9w

	; set the "visible" and "flush" flags for the "menu" window
	or	word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush

	; remember
	or	word [rel kernel_gui_window_menu + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush

.end:
	; return from the procedure
	ret

	macro_debug	"kernel_gui_ipc_wm"
