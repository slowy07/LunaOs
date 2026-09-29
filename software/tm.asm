;===============================================================================

	;-----------------------------------------------------------------------
	%include	"software/tm/config.asm"
	;-----------------------------------------------------------------------

;===============================================================================
tm:
	; initialize the working environment of the task manager
	%include	"software/tm/init.asm"

.check:
	; fetch the output stream information
	call	tm_stream_info

.loop:
	; set the cursor to the "uptime" position
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_uptime_position_and_color_end - tm_string_uptime_position_and_color
	mov	rsi,	tm_string_uptime_position_and_color
	int	KERNEL_SERVICE

	; fetch the current system clocks
	mov	ax,	KERNEL_SERVICE_SYSTEM_time
	int	KERNEL_SERVICE

	; display the system uptime
	call	tm_uptime

	; display the RAM usage
	call	tm_ram

	; display the number and the list of the active processes
	call	tm_task

	; next state update in 1 second
	add	rax,	1024
	mov	qword [tm_microtime],	rax

.event:
	; fetch the system microtime
	mov	ax,	KERNEL_SERVICE_SYSTEM_time
	int	KERNEL_SERVICE

	; has 1 second elapsed?
	cmp	rax,	qword [tm_microtime]
	jnb	.check	; yes

	;-----------------------------------------------------------------------
	; fetch the message
	mov	ax,	KERNEL_SERVICE_PROCESS_ipc_receive
	mov	rdi,	tm_ipc_data
	int	KERNEL_SERVICE
	jc	.no_event	; no message

	; message of the keyboard type?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.type],	KERNEL_IPC_TYPE_KEYBOARD
	jne	.no_event	; no, ignore

	; was the "q" key pressed?
	cmp	word [rdi + KERNEL_IPC_STRUCTURE.data],	"q"
	je	.end	; yes, terminate the process

	; was the "d" key pressed?
	cmp	word [rdi + KERNEL_IPC_STRUCTURE.data],	"d"
	jne	.no_event	; yes, terminate the process

	; enable the debug mode (Bochs)
	xchg	bx,bx
	jmp	.loop

.no_event:
	; free the remaining processor time
	mov	ax,	KERNEL_SERVICE_PROCESS_sleep
	xor	ecx,	ecx	; no waiting in time
	int	KERNEL_SERVICE

	; return to the main loop
	jmp	.event

.end:
	; move the virtual cursor to the end of the text screen space
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_end_of_work_end - tm_string_end_of_work
	mov	rsi,	tm_string_end_of_work
	int	KERNEL_SERVICE

	; terminate the process
	xor	ax,	ax
	int	KERNEL_SERVICE

	macro_debug	"software: tm"

	;-----------------------------------------------------------------------
	%include	"software/tm/data.asm"
	%include	"software/tm/static.asm"
	%include	"software/tm/stream.asm"
	%include	"software/tm/ram.asm"
	%include	"software/tm/uptime.asm"
	%include	"software/tm/task.asm"
	%include	"software/tm/percent.asm"
	;-----------------------------------------------------------------------
