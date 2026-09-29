;===============================================================================

;===============================================================================
console_window_close:
	; save the original registers
	push	rax
	push	rbx
	push	rdi

	; inform the child process that it has to terminate
	mov	byte [console_ipc_data + KERNEL_IPC_STRUCTURE.type],	KERNEL_IPC_TYPE_SYSTEM
	mov	byte [console_ipc_data + KERNEL_IPC_STRUCTURE.data],	KERNEL_IPC_DATA_SYSTEM_kill
	call	console_transfer

.wait:
	; fetch the answer
	mov	ax,	KERNEL_SERVICE_PROCESS_ipc_receive
	mov	rdi,	console_ipc_data
	int	KERNEL_SERVICE
	jc	.wait	; no message, keep waiting

	; message from the child process?
	mov	rbx,	qword [console_shell_pid]
	cmp	qword [rdi + KERNEL_IPC_STRUCTURE.pid_source],	rbx
	jne	.wait	; no, keep waiting

	; end of the process
	jmp	console.close

	; restore the original registers
	pop	rdi
	pop	rbx
	pop	rax

	; return from the procedure
	ret
