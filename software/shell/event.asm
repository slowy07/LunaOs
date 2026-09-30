
; entry:
;	rdi - pointer to the message
shell_event:
	; not handled

	; return from the procedure
	ret

; entry:
;	rcx - PID of the target process
shell_event_transfer:
	; save the original registers
	push rax
	push rcx
	push rsi

	; pass the message to the child process
	mov rax, KERNEL_SERVICE_PROCESS_ipc_send
	mov rbx, rcx
	xor ecx, ecx ; default message size
	mov rsi, shell_ipc_data
	int KERNEL_SERVICE

.end:
	; restore the original registers
	pop rsi
	pop rcx
	pop rax

	; return from the procedure
	ret
