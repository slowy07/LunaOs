
kernel_gui_ipc:
	; preserve the original registers
	push rax
	push rsi
	push rdi
	push r8
	push r9

	; fetch a message
	mov rdi, kernel_gui_ipc_data
	call kernel_ipc_receive
	jc .end ; no message

	; a message from the window manager?
	mov rax, qword [rel kernel_wm_pid]
	cmp qword [rdi + KERNEL_IPC_STRUCTURE.pid_source], rax
	jne .no_desu ; no, ignore

	; handle the message
	call kernel_gui_ipc_wm

.no_desu:

.end:
	; restore the original registers
	pop r9
	pop r8
	pop rdi
	pop rsi
	pop rax

	; return from the procedure
	ret

	macro_debug "kernel_gui_ipc"

	%include "kernel/service/gui/ipc/wm.asm"
