
	; change the header title
	call	shell_header

	; fetch the parent PID
	mov	ax,	KERNEL_SERVICE_PROCESS_pid_parent
	int	KERNEL_SERVICE

	; save the parent PID
	mov	qword [shell_pid_parent],	rcx
