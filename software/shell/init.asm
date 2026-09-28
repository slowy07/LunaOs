;===============================================================================

	; zmień tytuł nagłówka
	call	shell_header

	; pobierz PID rodzica
	mov	ax,	KERNEL_SERVICE_PROCESS_pid_parent
	int	KERNEL_SERVICE

	; zachowaj PID rodzica
	mov	qword [shell_pid_parent],	rcx
