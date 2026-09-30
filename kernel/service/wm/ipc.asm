
; input:
;	cl - mouse related action type
;	rsi - pointer to the dependent object
kernel_wm_ipc_mouse:
	; preserve the original registers
	push	rax
	push	rbx
	push	rcx
	push	rsi

	; fetch the window ID and PID
	mov	rax,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.id]
	mov	rbx,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.pid]

	; convert the cursor position into an indirect one (relative to the window)
	sub	r8w,	word [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.x]
	sub	r9w,	word [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.y]

	; compose the message for the process
	mov	rsi,	kernel_wm_ipc_data

	; message type: keyboard
	mov	byte [rsi + KERNEL_IPC_STRUCTURE.type],	KERNEL_IPC_TYPE_MOUSE

	; send the information about the action type
	mov	byte [rsi + KERNEL_IPC_STRUCTURE.data + KERNEL_IPC_STRUCTURE_DATA_MOUSE.event],	cl

	; send the information about the ID of the participating window
	mov	qword [rsi + KERNEL_IPC_STRUCTURE.data + KERNEL_IPC_STRUCTURE_DATA_MOUSE.object_id],	rax

	; send the information about the cursor position
	mov	word [rsi + KERNEL_IPC_STRUCTURE.data + KERNEL_IPC_STRUCTURE_DATA_MOUSE.x],	r8w	; x
	mov	word [rsi + KERNEL_IPC_STRUCTURE.data + KERNEL_IPC_STRUCTURE_DATA_MOUSE.y],	r9w	; y

	; send the message
	xor	ecx,	ecx	; standard message size under the address in register RSI
	call	kernel_ipc_insert

	; restore the original registers
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"kernel_wm_ipc_mouse"

; input:
;	ax - key code
;	rsi - pointer to the dependent object
kernel_wm_ipc_keyboard:
	; preserve the original registers
	push	rbx
	push	rcx
	push	rdx
	push	rsi

	; fetch the PID of the window process
	mov	rbx,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.pid]

	; compose the message for the process
	mov	rsi,	kernel_wm_ipc_data

	; message type: keyboard
	mov	byte [rsi + KERNEL_IPC_STRUCTURE.type],	KERNEL_IPC_TYPE_KEYBOARD

	; send the information about the key code
	mov	word [rsi + KERNEL_IPC_STRUCTURE.data],	ax

	; send the message
	xor	ecx,	ecx	; standard message size under the address in register RSI
	call	kernel_ipc_insert

	; restore the original registers
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx

	; return from the procedure
	ret

	macro_debug	"kernel_wm_ipc_keyboard"
