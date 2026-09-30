
ls_init:
	; disable the virtual cursor (it is not needed, the program does not interact, we save processor time)
	mov ax, KERNEL_SERVICE_PROCESS_stream_out
	mov ecx, ls_string_init_end - ls_string_init
	mov rsi, ls_string_init
	int KERNEL_SERVICE

	; fetch the size of the argument list passed to the process
	pop rcx

	; were the arguments passed to the process?
	test rcx, rcx
	jz .no_arguments ; no

	; point the pointer at the argument list
	mov rsi, rsp

	; remove all the white characters from the beginning and the end of the list
	macro_library LIBRARY_STRUCTURE_ENTRY.string_trim
	jnc .trimmed ; processed

.no_arguments:
	; display the list of files in the working directory of the process
	mov ecx, ls_path_local_end - ls_path_local
	mov rsi, ls_path_local

.trimmed:
