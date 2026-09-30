
; entry:
;	rcx - size of the string
;	rsi - pointer to the current beginning of the data in the buffer
shell_prompt_relocate:
	; save the original registers
	push rcx
	push rdi

	; beginning of the buffer space
	mov rdi, shell_cache

	; buffer contents at the beginning of its space?
	cmp rsi, shell_cache
	je .at_begin ; yes

	; move the buffer contents to the beginning of the space
	rep movsb

	; return the new pointer to the beginning of the string
	mov rsi, shell_cache

.at_begin:
	; restore the original registers
	pop rdi
	pop rcx

	; return from the procedure
	ret

; entry:
;	rbx - previous size of the "word"
;	r8 - current size of the string
;	rsi - pointer to the current position in the string
; exit:
;	CF flag, if the string is empty
;	registers updated
shell_prompt_clean:
	; move the pointer past the "ip" command and decrease the number of characters in the remaining string
	add rsi, rbx
	sub r8, rbx

	; remove the white characters from the beginning and the end of the rest of the string
	mov rcx, r8
	macro_library LIBRARY_STRUCTURE_ENTRY.string_trim

	; save the remaining size of the command
	mov r8, rcx

.error:
	; return from the procedure
	ret

; entry:
;	rbx - size of the command in characters
;	rsi - pointer to the command
shell_prompt_internal:
	; save the original registers
	push rax
	push rdi
	push rcx

	; probably the command: clear
	cmp rbx, shell_command_clear_end - shell_command_clear
	jne .no_clear ; no

	; check for the "clear" command
	mov ecx, ebx ; size of the compared string
	mov rdi, shell_command_clear
	macro_library LIBRARY_STRUCTURE_ENTRY.string_compare
	jc .no_clear ; the strings differ

	; send the character space clearing sequence
	mov ax, KERNEL_SERVICE_PROCESS_stream_out
	mov ecx, shell_string_sequence_clear_end - shell_string_sequence_clear
	mov rsi, shell_string_sequence_clear
	int KERNEL_SERVICE

	; the command has been executed
	jmp .end

.no_clear:
	; probably the command: exit
	cmp rbx, shell_command_exit_end - shell_command_exit
	jne .no_exit ; no

	; check for the "exit" command
	mov ecx, ebx ; size of the compared string
	mov rdi, shell_command_exit
	macro_library LIBRARY_STRUCTURE_ENTRY.string_compare
	jc .no_exit ; the strings differ

	; terminate the shell
	xor ax, ax
	int KERNEL_SERVICE

.no_exit:
	; probably the command: cd
	cmp rbx, shell_command_cd_end - shell_command_cd
	jne .no_cd ; no

	; check for the "cd" command
	mov ecx, ebx ; size of the compared string
	mov rdi, shell_command_cd
	macro_library LIBRARY_STRUCTURE_ENTRY.string_compare
	jc .no_cd ; the strings differ

	; set the registers to the access path
	mov rcx, qword [rsp]
	sub rcx, rbx
	add rsi, rbx

	; remove the "white characters" from the path, at the beginning and the end of the string
	macro_library LIBRARY_STRUCTURE_ENTRY.string_trim

	; change the working directory
	mov ax, KERNEL_SERVICE_PROCESS_dir_change
	int KERNEL_SERVICE

	; the command has been executed
	jmp .end

.no_cd:
	; unrecognized internal command
	stc

.end:
	; restore the original registers
	pop rcx
	pop rdi
	pop rax

	; return from the procedure
	ret
