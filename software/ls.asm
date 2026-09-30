
	%include "software/ls/config.asm"

ls:
	; initialize the working environment
	%include "software/ls/init.asm"

	; load the list of files from the given directory
	mov ax, KERNEL_SERVICE_VFS_dir
	int KERNEL_SERVICE
	jc .error ; wrong directory path or the file was not found

	; set the entry counter
	mov rbx, rcx

.loop:
	; default color scheme for the file
	mov ecx, ls_string_color_file_end - ls_string_color_file
	mov rsi, ls_string_color_file

	; a file of the directory type?
	test byte [rdi + KERNEL_VFS_STRUCTURE_KNOT.type], KERNEL_VFS_FILE_TYPE_directory
	jz .no_directory ; no

	; set the color scheme for the directory
	mov rsi, ls_string_color_directory

.no_directory:
	; change the color scheme
	mov ax, KERNEL_SERVICE_PROCESS_stream_out
	int KERNEL_SERVICE

	; set the pointer to the file name
	mov rsi, rdi
	add rsi, KERNEL_VFS_STRUCTURE_KNOT.name

	; is the file hidden?
	cmp byte [rsi], STATIC_SCANCODE_DOT
	je .hidden ; yes

	; display the file name
	mov cl, byte [rdi + KERNEL_VFS_STRUCTURE_KNOT.length]
	int KERNEL_SERVICE

	; display the separator
	mov cl, ls_string_separator_end - ls_string_separator
	mov rsi, ls_string_separator
	int KERNEL_SERVICE

.hidden:
	; have all the files been displayed?
	dec rbx
	jz .end ; yes

	; move the pointer to the next file
	add rdi, KERNEL_VFS_STRUCTURE_KNOT.SIZE

	; display the remaining files
	jmp .loop

.error:
	; display the message
	mov ax, KERNEL_SERVICE_PROCESS_stream_out
	mov ecx, ls_string_error_not_found_end - ls_string_error_not_found
	mov rsi, ls_string_error_not_found
	int KERNEL_SERVICE

.end:
	; terminate the program
	xor ax, ax
	int KERNEL_SERVICE

	macro_debug "software: ls"

	%include "software/ls/data.asm"
