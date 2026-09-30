
kernel_gui_event_console:
	; preserve the original registers
	push rbx
	push rcx
	push rsi

	; run the "Console" program
	mov ax, KERNEL_SERVICE_PROCESS_run
	mov ebx, KERNEL_SERVICE_PROCESS_RUN_FLAG_out_default
	mov ecx, kernel_gui_event_console_file_end - kernel_gui_event_console_file
	mov rsi, kernel_gui_event_console_file
	xor r8, r8 ; no arguments to pass
	int KERNEL_SERVICE

	; restore the original registers
	pop rsi
	pop rcx
	pop rbx

	; return from the action handler procedure
	ret

	macro_debug "kernel_gui_event_console"

kernel_gui_event_calculator:
	; preserve the original registers
	push rbx
	push rcx
	push rsi

	; run the "Console" program
	mov ax, KERNEL_SERVICE_PROCESS_run
	mov ebx, KERNEL_SERVICE_PROCESS_RUN_FLAG_out_default
	mov ecx, kernel_gui_event_calculator_file_end - kernel_gui_event_calculator_file
	mov rsi, kernel_gui_event_calculator_file
	xor r8, r8 ; no arguments to pass
	int KERNEL_SERVICE

	; restore the original registers
	pop rsi
	pop rcx
	pop rbx

	; return from the action handler procedure
	ret

kernel_gui_event_tetris:
	; preserve the original registers
	push rbx
	push rcx
	push rsi

	; run the "Tetris" program
	mov ax, KERNEL_SERVICE_PROCESS_run
	mov ebx, KERNEL_SERVICE_PROCESS_RUN_FLAG_out_default
	mov ecx, kernel_gui_event_tetris_file_end - kernel_gui_event_tetris_file
	mov rsi, kernel_gui_event_tetris_file
	xor r8, r8 ; no arguments to pass
	int KERNEL_SERVICE

	; restore the original registers
	pop rsi
	pop rcx
	pop rbx

	; return from the action handler procedure
	ret

	macro_debug "kernel_gui_event_console"
