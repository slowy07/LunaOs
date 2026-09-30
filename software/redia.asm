
	%include	"software/redia/config.asm"

redia:
	; terminate the program
	xor	ax,	ax
	int	KERNEL_SERVICE

	macro_debug	"software: redia"
