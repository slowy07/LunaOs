
console_transfer:
	; set the pointer to the message
	mov rsi, console_ipc_data

	; message type: keyboard
	mov byte [rsi + KERNEL_IPC_STRUCTURE.type], KERNEL_IPC_TYPE_KEYBOARD

	; key code
	mov word [rsi + KERNEL_IPC_STRUCTURE.data], dx

	; send the message to the shell
	mov rax, KERNEL_SERVICE_PROCESS_ipc_send
	mov rbx, qword [console_shell_pid]
	xor ecx, ecx ; default message size
	int KERNEL_SERVICE

	; return from the procedure
	ret
