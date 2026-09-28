;===============================================================================

	;-----------------------------------------------------------------------
	%include	"kernel/library/terminal/header.asm"
	;-----------------------------------------------------------------------

;===============================================================================
; input:
;	r8 - pointer to the terminal structure
library_terminal:
	; preserve the original registers
	push	rax
	push	rdx

	; compute the scanline from the characters
	mov	rax,	LIBRARY_FONT_HEIGHT_pixel
	mul	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.scanline_byte]
	mov	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.scanline_char],	rax

	; compute the terminal width in characters
	mov	rax,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.width]
	xor	edx,	edx
	div	qword [library_font_width_pixel]
	mov	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.width_char],	rax

	; compute the terminal height in characters
	mov	rax,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.height]
	xor	edx,	edx
	div	qword [library_font_height_pixel]
	mov	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.height_char],	rax

	; the virtual cursor is off by default
	mov	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.lock],	STATIC_FALSE

	; initialise the terminal area
	call	library_terminal_clear

	; switch the virtual cursor on
	call	library_terminal_cursor_enable

	; restore the original registers
	pop	rdx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"library_terminal"

;===============================================================================
; input:
;	r8 - pointer to the terminal structure
library_terminal_clear:
	; preserve the original registers
	push	rax
	push	rcx
	push	rdx
	push	rdi

	; switch the virtual cursor off
	call	library_terminal_cursor_disable

	; clear the area with the default background color
	mov	eax,	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.background_color]
	mov	rdx,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.height]
	mov	rdi,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.address]

.loop:
	; store the address of the start of the chunk
	push	rdi

	; clear the first chunk
	mov	rcx,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.width]
	rep	stosd

	; restore the address of the start of the chunk
	pop	rdi

	; move the pointer to the next chunk
	add	rdi,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.scanline_byte]

	; end of the area?
	dec	rdx
	jnz	.loop	; no

	; set the virtual cursor to the start of the terminal area
	mov	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.cursor],	STATIC_EMPTY

	; position the hardware cursor
	call	library_terminal_cursor_set

	; switch the virtual cursor on
	call	library_terminal_cursor_enable

	; restore the original registers
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"library_terminal_clear"

;===============================================================================
; input:
;	r8 - pointer to the terminal structure
library_terminal_cursor_disable:
	; take the cursor lock
	inc	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.lock]

	; lock already taken?
	cmp	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.lock],	STATIC_FALSE
	jne	.ready	; the lock was taken before, the level was raised

	; toggle the cursor visibility
	call	library_terminal_cursor_switch

.ready:
	; restore the original registers
	ret

	macro_debug	"library_terminal_cursor_disable"

;===============================================================================
; input:
;	r8 - pointer to the terminal structure
library_terminal_cursor_enable:
	; lock already taken?
	cmp	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.lock],	STATIC_EMPTY
	je	.ready	; no, ignore

	; release the cursor lock
	dec	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.lock]

	; lock taken further up?
	cmp	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.lock],	STATIC_EMPTY
	jne	.ready	; yes, ignore

	; toggle the cursor visibility
	call	library_terminal_cursor_switch

.ready:
	; restore the original registers
	ret

	macro_debug	"library_terminal_cursor_enable"

;===============================================================================
; input:
;	r8 - pointer to the terminal structure
library_terminal_cursor_switch:
	; preserve the original registers
	push	rax
	push	rcx
	push	rdi

	; screen scanline
	mov	rax,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.scanline_byte]

	; cursor height
	mov	rcx,	LIBRARY_FONT_HEIGHT_pixel

	; cursor position
	mov	rdi,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.pointer]

.loop:
	; invert the pixel color
	not	word [rdi]
	not	byte [rdi + STATIC_WORD_SIZE_byte]

	; move the pointer to the next pixel
	add	rdi,	rax

	; next pixel?
	dec	rcx
	jnz	.loop

.end:
	; restore the original registers
	pop	rdi
	pop	rcx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"library_terminal_cursor_switch"

;===============================================================================
; input:
;	r8 - pointer to the terminal structure
library_terminal_cursor_set:
	; preserve the original registers
	push	rax
	push	rcx
	push	rdx

	; switch the cursor off
	call	library_terminal_cursor_disable

	; compute the cursor position in characters
	mov	eax,	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.cursor + LIBRARY_TERMINAL_STURCTURE_CURSOR.y]
	mul	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.scanline_char]
	push	rax	; remember
	mov	eax,	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.cursor + LIBRARY_TERMINAL_STURCTURE_CURSOR.x]
	mul	qword [library_font_width_byte]
	add	qword [rsp],	rax
	pop	rax	; return the result

	; store the new pointer position in the graphics card memory area
	add	rax,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.address]
	mov	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.pointer],	rax

	; switch the cursor on
	call	library_terminal_cursor_enable

	; restore the original registers
	pop	rdx
	pop	rcx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"library_terminal_cursor_set"

;===============================================================================
; input:
;	rax - character ASCII code
;	rdi - character position in the screen memory area
;	r8 - pointer to the terminal structure
library_terminal_matrix:
	; preserve the original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r9

	; compute the offset from the start of the font matrix for the character
	mov	ebx,	dword [library_font_height_pixel]
	mul	rbx

	; set the pointer to the glyph matrix
	mov	rsi,	library_font_matrix
	add	rsi,	rax

	; fetch the font color
	mov	r9d,	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.foreground_color]

.next:
	; glyph matrix width counted from zero
	mov	ecx,	LIBRARY_FONT_WIDTH_pixel - 0x01

.loop:
	; switch a glyph matrix pixel on screen?
	bt	word [rsi],	cx
	jnc	.continue	; no

	; display the pixel with the given glyph color
	mov	dword [rdi],	r9d

.continue:
	; next glyph matrix pixel
	add	rdi,	STATIC_DWORD_SIZE_byte

	; display the rest?
	dec	cl
	jns	.loop	; yes

	; move the pointer to the next matrix line on screen
	sub	rdi,	LIBRARY_FONT_WIDTH_pixel << KERNEL_VIDEO_DEPTH_shift	; go back by the width of the displayed character in bytes
	add	rdi,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.scanline_byte]	; advance by the size of the screen scanline

	; move the pointer to the next glyph matrix line
	inc	rsi

	; has the whole glyph matrix been processed?
	dec	bl
	jnz	.next	; no, continue with the next glyph row

	; restore the original registers
	pop	r9
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"library_terminal_matrix"

;===============================================================================
; input:
;	rdi - pointer to the character position
;	r8 - pointer to the terminal structure
library_terminal_empty_char:
	; preserve the original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rdi

	; glyph matrix height in pixels
	mov	ebx,	LIBRARY_FONT_HEIGHT_pixel

	; background color
	mov	eax,	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.background_color]

.next:
	; glyph matrix width counted from zero
	mov	cx,	LIBRARY_FONT_WIDTH_pixel - 0x01

.loop:
	; display the pixel with the given background color
	stosd

.continue:
	; next pixel from the glyph matrix line
	dec	cl
	jns	.loop

	; move the pointer to the next matrix line on screen
	sub	rdi,	LIBRARY_FONT_WIDTH_pixel << KERNEL_VIDEO_DEPTH_shift	; go back by the character width in bytes
	add	rdi,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.scanline_byte]	; advance by the size of the screen scanline

	; has the whole glyph matrix been processed?
	dec	bl
	jnz	.next	; no, next glyph row

	; restore the original registers
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"library_terminal_empty_char"

;===============================================================================
; input:
;	rax - character ASCII code
;	rcx - number of copies of the character to display
;	r8 - pointer to the terminal structure
library_terminal_char:
	; preserve the original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rdi

	; switch the cursor off
	call	library_terminal_cursor_disable

	; cursor position on the X,Y axes
	mov	ebx,	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.cursor + LIBRARY_TERMINAL_STURCTURE_CURSOR.x]
	mov	edx,	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.cursor + LIBRARY_TERMINAL_STURCTURE_CURSOR.y]

	; set the pointer to the last position in the text mode memory area
	mov	rdi,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.pointer]

.loop:
	; character "carriage return"?
	cmp	ax,	STATIC_SCANCODE_RETURN
	je	.return	; yes

	; character "new line"?
	cmp	ax,	STATIC_SCANCODE_NEW_LINE
	je	.new_line	; yes

	; character "backspace"?
	cmp	ax,	STATIC_SCANCODE_BACKSPACE
	je	.backspace	; yes

	; unsupported special character?
	cmp	ax,	STATIC_SCANCODE_SPACE
	jb	.omit	; yes
	cmp	ax,	STATIC_SCANCODE_TILDE
	ja	.omit	; yes

	; clear the glyph area with the default background color
	call	library_terminal_empty_char

	; display the glyph matrix on screen
	sub	ax,	STATIC_SCANCODE_SPACE	; the font matrix starts at the STATIC_SCANCODE_SPACE character
	call	library_terminal_matrix

	; advance the cursor one position right on the X axis
	inc	ebx

	; move the pointer to the next position in the graphics card memory area
	add	rdi,	qword [library_font_width_byte]

	; cursor position outside the text mode memory area?
	cmp	ebx,	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.width_char]
	jb	.continue	; no

	; preserve the original registers
	push	rax
	push	rdx

	; move the cursor pointer to the start of the new line
	mov	rax,	qword [library_font_width_byte]
	mul	rbx
	sub	rdi,	rax
	add	rdi,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.scanline_char]

	; restore the original registers
	pop	rdx
	pop	rax

	; move the cursor to the next row
	xor	ebx,	ebx
	inc	edx

.row:
	; cursor position outside the text mode memory area?
	cmp	edx,	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.height_char]
	jb	.continue	; no

	; fix the cursor position on the Y axis
	dec	edx

	; fix up the pointer
	sub	rdi,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.scanline_char]

	; scroll the text mode memory area content up by one text line
	call	library_terminal_scroll

.continue:
	; have all the copies been displayed?
	dec	rcx
	jnz	.loop	; no

	; store the current cursor position in the text mode memory area
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.cursor + LIBRARY_TERMINAL_STURCTURE_CURSOR.x],	ebx
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.cursor + LIBRARY_TERMINAL_STURCTURE_CURSOR.y],	edx

	; store the current pointer position in the text mode memory area
	mov	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.pointer],	rdi

.omit:
	; switch the cursor on
	call	library_terminal_cursor_enable

	; restore the original registers
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"library_terminal_char"

;-------------------------------------------------------------------------------
.return:
	; move the pointer and the virtual cursor to the start of the current line
	mov	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.cursor + LIBRARY_TERMINAL_STURCTURE_CURSOR.x],	STATIC_EMPTY
	call	library_terminal_cursor_set

	; fix the virtual cursor position on the X axis
	xor	ebx,	ebx

	; fetch the new virtual cursor position pointer in the terminal memory area
	mov	rdi,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.pointer]

	; return to the main loop
	jmp	.continue

	macro_debug	"library_terminal_char.return"

;-------------------------------------------------------------------------------
.new_line:
	; preserve the original registers
	push	rax	; character ASCII code
	push	rdx	; cursor position on the Y axis

	; move the pointer back to the start of the line
	mov	eax,	ebx
	mul	qword [library_font_width_pixel]
	shl	rax,	KERNEL_VIDEO_DEPTH_shift
	sub	rdi,	rax

	; move the virtual cursor back to the start of the line
	xor	ebx,	ebx

	; move the cursor and the pointer to the next line
	add	rdi,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.scanline_char]

	; restore the cursor position on the Y axis
	pop	rdx
	inc	rdx	; move the cursor to the next line

	; restore the character ASCII code
	pop	rax

	; continue
	jmp	.row

	macro_debug	"library_terminal_char.new_line"

;-------------------------------------------------------------------------------
.backspace:
	; is the cursor at the start of the line?
	test	ebx,	ebx
	jz	.begin	; yes

	; move the cursor position back on the X axis
	dec	ebx

	; continue
	jmp	.clear

.begin:
	; is the cursor on the first line?
	test	edx,	edx
	jz	.continue	; yes

	; set the cursor position to the end of the current line
	mov	ebx,	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.width_char]
	dec	ebx

	; move the cursor back by one line
	dec	edx

	; preserve the original register
	push	rax
	push	rdx

	; move the cursor pointer to the start of the previous line
	sub	rdi,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.scanline_char]
	mov	rax,	qword [library_font_width_byte]
	mul	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.width_char]
	add	rdi,	rax

	; restore the original register
	pop	rdx
	pop	rax

.clear:
	; move the pointer back by one character
	sub	rdi,	LIBRARY_FONT_WIDTH_pixel << KERNEL_VIDEO_DEPTH_shift

	; clear the glyph area with the default background color
	call	library_terminal_empty_char

	; continue
	jmp	.continue

	macro_debug	"library_terminal_char.backspace"

;===============================================================================
; input:
;	r8 - pointer to the terminal structure
library_terminal_scroll:
	; preserve the original registers
	push	rbx
	push	rcx

	; start at line number 1 (we count from zero)
	mov	ecx,	1

	; all rows
	mov	rbx,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.height_char]
	dec	rbx	; the first row does not take part

	; scroll up
	call	library_terminal_scroll_up

	; clear the last character line on screen
	call	library_terminal_empty_line

	; restore the original registers
	pop	rcx
	pop	rbx

	; return from the procedure
	ret

	macro_debug	"library_terminal_scroll"

;===============================================================================
; input:
;	rbx - number of lines to shift
;	rcx - starting line
;	r8 - pointer to the terminal structure
library_terminal_scroll_down:
	; preserve the original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r9

	; switch the virtual cursor off
	call	library_terminal_cursor_disable

	; start scrolling from the RCX line
	mov	rdi,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.address]
	mov	rax,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.scanline_char]
	add	rcx,	rbx
	mul	rcx
	add	rdi,	rax

	; towards the previous line
	mov	rsi,	rdi
	sub	rsi,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.scanline_char]

	; line size of the terminal area in bytes
	mov	rax,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.width]
	shl	rax,	KERNEL_VIDEO_DEPTH_shift

	; display area scanline
	mov	r9,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.scanline_byte]

.row:
	; store the pointers to the rows being processed
	push	rsi
	push	rdi

	; line height in pixels
	mov	edx,	LIBRARY_FONT_HEIGHT_pixel

.line:
	; move the first row of the current line
	mov	rcx,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.width]
	rep	movsd

	; move the pointers to the next line
	sub	rdi,	rax
	add	rdi,	r9
	sub	rsi,	rax
	add	rsi,	r9

	; have all the lines of the first row been shifted?
	dec	edx
	jnz	.line	; no

	; restore the pointers to the processed rows
	pop	rdi
	pop	rsi

	; move the pointers to the next row
	sub	rsi,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.scanline_char]
	sub	rdi,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.scanline_char]

	; have all the rows been shifted?
	dec	rbx
	jnz	.row	; no

	; switch the virtual cursor on
	call	library_terminal_cursor_enable

	; restore the original registers
	pop	r9
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"library_terminal_scroll_up"

;===============================================================================
; input:
;	rbx - number of lines to shift
;	rcx - starting line
;	r8 - pointer to the terminal structure
library_terminal_scroll_up:
	; preserve the original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r9

	; switch the virtual cursor off
	call	library_terminal_cursor_disable

	; start scrolling from the RCX line
	mov	rsi,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.address]
	mov	rax,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.scanline_char]
	mul	rcx
	add	rsi,	rax

	; towards the next line
	mov	rdi,	rsi
	sub	rdi,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.scanline_char]

	; line size of the terminal area in bytes
	mov	rax,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.width]
	shl	rax,	KERNEL_VIDEO_DEPTH_shift

	; display area scanline
	mov	r9,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.scanline_byte]

.row:
	; line height in pixels
	mov	edx,	LIBRARY_FONT_HEIGHT_pixel

.line:
	; move the first row of the current line
	mov	rcx,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.width]
	rep	movsd

	; move the pointers to the next line
	sub	rdi,	rax
	add	rdi,	r9
	sub	rsi,	rax
	add	rsi,	r9

	; have all the lines of the first row been shifted?
	dec	edx
	jnz	.line	; no

	; have all the rows been shifted?
	dec	rbx
	jnz	.row	; no

	; switch the virtual cursor on
	call	library_terminal_cursor_enable

	; restore the original registers
	pop	r9
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"library_terminal_scroll_up"

;===============================================================================
; input:
;	rbx - line number on screen
;	r8 - pointer to the terminal structure
library_terminal_empty_line:
	; preserve the original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rdi

	; switch the virtual cursor off
	call	library_terminal_cursor_disable

	; compute the relative position of the line in the terminal area
	mov	rax,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.scanline_char]
	mul	rbx

	; terminal area scanline
	mov	rbx,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.width]
	shl	rbx,	KERNEL_VIDEO_DEPTH_shift

	; row height in pixels
	mov	edx,	LIBRARY_FONT_HEIGHT_pixel

	; set the pointer
	mov	rdi,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.address]
	add	rdi,	rax

.line:
	; clear the line with the default background color
	mov	eax,	dword [r8 + LIBRARY_TERMINAL_STRUCTURE.background_color]
	mov	rcx,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.width]
	rep	stosd

	; move the pointer to the next row line
	sub	rdi,	rbx
	add	rdi,	qword [r8 + LIBRARY_TERMINAL_STRUCTURE.scanline_byte]

	; have all the lines of the row been cleared?
	dec	edx
	jnz	.line	; no

	; switch the virtual cursor on
	call	library_terminal_cursor_enable

	; restore the original registers
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"library_terminal_empty_line"

;===============================================================================
; input:
;	rcx - number of characters in the string
;	rsi - pointer to the string
;	r8 - pointer to the terminal structure
library_terminal_string:
	; preserve the original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi

	; switch the virtual cursor off
	call	library_terminal_cursor_disable

	; display any number of characters from the string?
	test	rcx,	rcx
	jz	.end	; no

	; clear the variable
	xor	eax,	eax

.loop:
	; fetch the ASCII code from the string
	lodsb

	; forced end of string?
	test	al,	al
	jz	.end	; yes

	; store the remaining string size
	push	rcx

	; display 1 copy of the ASCII code
	mov	ecx,	1
	call	library_terminal_char

	; restore the remaining string size
	pop	rcx

.continue:
	; display the remaining part of the string
	dec	rcx
	jnz	.loop

.end:
	; switch the virtual cursor on
	call	library_terminal_cursor_enable

	; restore the original registers
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"library_terminal_string"

;===============================================================================
; input:
;	rax - value to display
;	rbx - number base
;	rcx - size of the padding in front of the number
;	rdx - padding ASCII code
;	r8 - pointer to the terminal structure
library_terminal_number:
	; preserve the original registers
	push	rax
	push	rdx
	push	rbp
	push	r9

	; switch the virtual cursor off
	call	library_terminal_cursor_disable

	; clear the redundant data in the RBX register
	and	ebx,	STATIC_BYTE_mask

	; number base within the valid range?
	cmp	bl,	2
	jb	.error	; no
	cmp	bl,	36
	ja	.error	; no

	; store the prefix value
	mov	r9,	rdx
	sub	r9,	0x30

	; clear the high part / remainder
	xor	rdx,	rdx

	; create a stack of local variables
	mov	rbp,	rsp

.loop:
	; compute the remainder
	div	rbx

	; store the remainder in the local variables
	push	rdx
	dec	rcx	; shrink the prefix size

	; clear the remainder
	xor	rdx,	rdx

	; keep converting?
	test	rax,	rax
	jnz	.loop	; yes

	; fill the prefix?
	cmp	rcx,	STATIC_EMPTY
	jle	.print	; no

.prefix:
	; fill the value with the prefix
	push	r9

	; keep filling?
	dec	rcx
	jnz	.prefix	; yes

.print:
	; display every digit
	mov	ecx,	0x01	; once

	; any digits left to display?
	cmp	rsp,	rbp
	je	.end	; no

	; fetch the digit
	pop	rax

	; convert the digit into an ASCII code
	add	rax,	0x30

	; number base above 10?
	cmp	al,	0x3A
	jb	.no	; no

	; fix the ASCII code to the number base
	add	al,	0x07

.no:
	; display the digit
	call	library_terminal_char

	; continue
	jmp	.print

.error:
	; flag, error
	stc

.end:
	; switch the virtual cursor on
	call	library_terminal_cursor_enable

	; restore the original registers
	pop	r9
	pop	rbp
	pop	rdx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"library_terminal_number"
