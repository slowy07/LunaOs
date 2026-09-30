;===============================================================================

	%include	"software/shell/config.asm"

;===============================================================================
shell:
	; initialize the working environment of the shell
	%include	"software/shell/init.asm"

.restart:
	; fetch the output stream information
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_meta
	mov	bl,	KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_get | KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_out
	mov	rdi,	shell_stream_meta
	int	KERNEL_SERVICE
	jc	shell.restart	; no current information

	; fetch the command from the user
	%include	"software/shell/input.asm"

	; process
	%include	"software/shell/exec.asm"

	macro_debug	"software: shell"

	%include	"software/shell/data.asm"
	%include	"software/shell/event.asm"
	%include	"software/shell/header.asm"
	%include	"software/shell/prompt.asm"
