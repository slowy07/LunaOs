;===============================================================================

	;-----------------------------------------------------------------------
	%include	"software/cat/config.asm"
	;-----------------------------------------------------------------------

;===============================================================================
cat:
	; disable the virtual cursor (it is not needed, the program does not interact, we save processor time)
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	cat_string_init_end - cat_string_init
	mov	rsi,	cat_string_init
	int	KERNEL_SERVICE

	; fetch the size of the argument list passed to the process
	pop	rcx

	; were the arguments passed to the process?
	test	rcx,	rcx
	jz	.not_found	; no

	; point the pointer at the argument list
	mov	rsi,	rsp

	; remove all the white characters from the beginning and the end of the list
	macro_library	LIBRARY_STRUCTURE_ENTRY.string_trim
	jc	.not_found	; wrong path to the file or it does not exist

	; load the file data at the end of the program
	mov	ax,	KERNEL_SERVICE_VFS_read
	int	KERNEL_SERVICE
	jc	.not_found	; the given file was not found

	;-----------------------------------------------------------------------

	; remember the size of the loaded file
	mov	rbx,	rcx

	; display the bytes from the file in sequence
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out_char
	mov	ecx,	STATIC_BYTE_SIZE_byte	; one character at a time

	; set the pointer to the file data
	mov	rsi,	rdi

.loop:
	; fetch the ASCII code
	mov	dl,	byte [rsi]

	; printable character?
	cmp	dl,	STATIC_SCANCODE_TILDE
	ja	.no	; no
	cmp	dl,	STATIC_SCANCODE_SPACE
	jae	.yes	; yes

	; newline character?
	cmp	dl,	STATIC_SCANCODE_NEW_LINE
	je	.yes	; yes, display

	; caret character?
	cmp	dl,	STATIC_SCANCODE_RETURN
	je	.yes	; yes, display

.no:
	; convert into a dot character
	mov	dl,	STATIC_SCANCODE_DOT

.yes:
	; display
	int	KERNEL_SERVICE

	; set the pointer to the next byte from the file
	inc	rsi

	; display the remaining part?
	dec	rbx
	jnz	.loop	; yes

	; end of the program
	jmp	.end

	;-----------------------------------------------------------------------

.not_found:
	; display the error message
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	rcx,	cat_string_not_found_end - cat_string_not_found
	mov	rsi,	cat_string_not_found
	int	KERNEL_SERVICE

.end:
	; leave the program
	xor	ax,	ax
	int	KERNEL_SERVICE

	macro_debug	"software: cat"

	;-----------------------------------------------------------------------
	%include	"software/cat/data.asm"
	;-----------------------------------------------------------------------

cat_end:
