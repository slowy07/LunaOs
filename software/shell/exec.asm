;===============================================================================

;===============================================================================
; entry:
;	rbx - size of the first word in the string
;	rcx - size of the whole string in characters
;	rsi - pointer to the beginning of the string space
shell_exec:
	; check whether it is an internal command
	call	shell_prompt_internal
	jnc	shell.restart	; yes, the user command has been processed

	; save the size of the argument list in bytes
	sub	rcx,	rbx
	push	rcx

	; every launched program is entitled to a new line
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out_char
	mov	ecx,	STATIC_BYTE_SIZE_byte	; send a single character
	mov	dl,	STATIC_SCANCODE_NEW_LINE	; of the new line
	int	KERNEL_SERVICE

	; number of characters representing the program name
	mov	rcx,	rbx

	; was the program specified by an indirect/direct path?
	cmp	byte [rsi],	STATIC_SCANCODE_DOT
	je	.in_direct	; yes, the indirect one
	cmp	byte [rsi],	STATIC_SCANCODE_SLASH
	je	.in_direct	; yes, the direct one

	; look the program up in the executable directory
	add	rcx,	shell_exec_path_end - shell_exec_path
	mov	rsi,	shell_exec_path

.in_direct:
	; check whether a program of the given name exists
	mov	ax,	KERNEL_SERVICE_VFS_exist
	int	KERNEL_SERVICE
	jc	.error	; no program or wrong path

	; run the program, passing it all the arguments given along with it
	mov	ax,	KERNEL_SERVICE_PROCESS_run
	mov	bl,	KERNEL_SERVICE_PROCESS_RUN_FLAG_out_default
	pop	r8	; size of the argument list in bytes
	int	KERNEL_SERVICE
	jc	shell.restart	; failed to start the program

	; wait for the process to terminate

.wait_for_end:
	; free the remaining processor time
	mov	ax,	KERNEL_SERVICE_PROCESS_release
	int	KERNEL_SERVICE

	; has the process terminated?
	mov	ax,	KERNEL_SERVICE_PROCESS_check
	int	KERNEL_SERVICE
	jc	.end	; yes

	; fetch the message
	mov	ax,	KERNEL_SERVICE_PROCESS_ipc_receive
	mov	rdi,	shell_ipc_data
	int	KERNEL_SERVICE
	jc	.wait_for_end	; no message

	; any incoming exceptions, pass them to the process
	call	shell_event_transfer

	; continue
	jmp	.wait_for_end

.end:
	; reset the cursor state (visibility)
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	shell_string_cursor_reset_end - shell_string_cursor_reset
	mov	rsi,	shell_string_cursor_reset
	int	KERNEL_SERVICE

	; restore the header title
	call	shell_header

	; return to the main loop
	jmp	shell.restart

.error:
	; display the message
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	shell_command_unknown_end - shell_command_unknown
	mov	rsi,	shell_command_unknown
	int	KERNEL_SERVICE

	; free the local variable
	add	rsp,	STATIC_QWORD_SIZE_byte

	; return to the main loop
	jmp	shell.restart
