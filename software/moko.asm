;===============================================================================

	%include	"software/moko/config.asm"

;===============================================================================
moko:
	; initialize the working environment of the text editor
	%include	"software/moko/init.asm"

.loop:
	; fetch the "character from the keyboard buffer" message
	mov	ax,	KERNEL_SERVICE_PROCESS_ipc_receive
	mov	rdi,	moko_ipc_data
	int	KERNEL_SERVICE
	jc	.loop	; no message

	; update the document status bar
	call	moko_status

	; message of the keyboard type?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.type],	KERNEL_IPC_TYPE_KEYBOARD
	jne	.loop	; ignore

	; fetch the key code
	mov	ax,	word [rdi + KERNEL_IPC_STRUCTURE.data]

	; was the keyboard shortcut invoked?
	call	moko_shortcut
	jnc	.loop	; yes

	; function key?
	call	moko_key
	jnc	.loop	; yes

	; printable character?
	cmp	ax,	STATIC_SCANCODE_SPACE
	jb	.loop	; no
	cmp	ax,	STATIC_SCANCODE_TILDE
	ja	.loop	; yes

	; insert a character into the document
	xor	bl,	bl	; update all the global variables
	call	moko_document_insert

	; display the current line contents on the screen again
	call	moko_line

	; return to the main loop
	jmp	.loop

.end:
	; move the cursor to the end of the character space
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	moko_string_close_end - moko_string_close
	mov	rsi,	moko_string_close
	int	KERNEL_SERVICE

	; terminate the program
	xor	ax,	ax
	int	KERNEL_SERVICE

	macro_debug	"software: moko"

	%include	"software/moko/data.asm"
	%include	"software/moko/document.asm"
	%include	"software/moko/interface.asm"
	%include	"software/moko/key.asm"
	%include	"software/moko/line.asm"
	%include	"software/moko/shortcut.asm"
	%include	"software/moko/ipc.asm"
	%include	"software/moko/status.asm"
