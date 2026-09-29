;===============================================================================

	;-----------------------------------------------------------------------
	%include	"software/taris/config.asm"
	;-----------------------------------------------------------------------

;===============================================================================
taris:
	; create the window
	mov	rsi,	taris_window
	macro_library	LIBRARY_STRUCTURE_ENTRY.bosu
	jc	taris.close	; not enough memory space

	; randomly pick a block and its pattern
	call	taris_random_block

	; starting position of the block
	mov	r8,	TARIS_BRICK_START_POSITION_x
	mov	r9,	TARIS_BRICK_START_POSITION_y

.loop:
	; check whether the new block collides with the currently existing ones
	call	taris_collision

	; check the incoming events
	mov	rsi,	taris_window
	macro_library	LIBRARY_STRUCTURE_ENTRY.bosu_event

	; etc.
	jmp	$

.close:
	; terminate the program
	xor	ax,	ax
	int	KERNEL_SERVICE

	macro_debug	"software: taris"

	;-----------------------------------------------------------------------
	%include	"software/taris/data.asm"
	%include	"software/taris/random.asm"
	%include	"software/taris/collision.asm"
	;-----------------------------------------------------------------------
