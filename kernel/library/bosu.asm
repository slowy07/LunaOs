
	; constants, variables, structures, objects
	%include	"kernel/library/bosu/header.asm"
	%include	"kernel/library/bosu/data.asm"

; input:
;	rsi - pointer to the window properties
; output:
;	CF flag - if there is no keyboard related exception
;	dx - key code
library_bosu_event:
	; preserve the original registers
	push	rax
	push	rsi
	push	rdi
	push	r8
	push	r9

	; prepare the space for the incoming IPC message
	sub	rsp,	KERNEL_IPC_STRUCTURE.SIZE

	; fetch the message (if it exists)
	mov	ax,	KERNEL_SERVICE_PROCESS_ipc_receive
	mov	rdi,	rsp
	int	KERNEL_SERVICE
	jc	.error	; no message

	; message of type: pointing device (keyboard)?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.type],	KERNEL_IPC_TYPE_KEYBOARD
	je	.keyboard	; yes

	; message of type: pointing device (mouse)?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.type],	KERNEL_IPC_TYPE_MOUSE
	je	.mouse	; yes

.error:
	; free the temporary area
	add	rsp,	KERNEL_IPC_STRUCTURE.SIZE

	; no exception handler
	stc

	; end of the procedure handler
	jmp	.end

.mouse:
	; left mouse button press?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_IPC_STRUCTURE_DATA_MOUSE.event],	KERNEL_IPC_MOUSE_EVENT_left_press
	jne	.error	; no, ignore the message

	; fetch the cursor coordinates
	movzx	r8d,	word [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_IPC_STRUCTURE_DATA_MOUSE.x]	; x
	movzx	r9d,	word [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_IPC_STRUCTURE_DATA_MOUSE.y]	; y

	; fetch the pointer to the element taking part in the event
	macro_library	LIBRARY_STRUCTURE_ENTRY.bosu_element
	jc	.error	; no dependent element found

	; does the element have an assigned action handler procedure?
	cmp	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.event],	STATIC_EMPTY
	je	.error	; no, end of action handling

	; run the procedure tied to the element
	mov	rax,	.error	; the procedure handled correctly, no data is returned
	push	rax	; return address from the procedure
	push	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON_CLOSE.event]	; procedure to run
	ret	; run

.keyboard:
	; fetch the key code
	mov	dx,	word [rdi + KERNEL_IPC_STRUCTURE.data]

	; free the temporary area
	add	rsp,	KERNEL_IPC_STRUCTURE.SIZE

.end:
	; restore the original registers
	pop	r9
	pop	r8
	pop	rdi
	pop	rsi
	pop	rax

	; return from the procedure
	ret

; input:
;	rsi - pointer to the window structure
; output:
;	CF flag - if the window could not be initialised
;	rcx - window identifier
library_bosu:
	; preserve the original registers
	push	rax
	push	rbx
	push	rdi
	push	rsi
	push	rcx

	; fix the element positions relative to the window border?
	test	word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_border
	jz	.no_border	; no

	; fix the window size by the border thickness

	; width
	add	word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width],	LIBRARY_BOSU_WINDOW_BORDER_THICKNESS_pixel << STATIC_MULTIPLE_BY_2_shift
	jc	.end	; window size error

	; height
	add	word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height],	LIBRARY_BOSU_WINDOW_BORDER_THICKNESS_pixel << STATIC_MULTIPLE_BY_2_shift
	jc	.end	; window size error

	; fix up all the window elements
	call	library_bosu_border_correction

.no_border:
	; fetch the window width and height
	movzx	r8d,	word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	movzx	r9d,	word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]

	; compute the window scanline in bytes
	mov	r10,	r8
	shl	r10,	KERNEL_VIDEO_DEPTH_shift
	mov	dword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.scanline_byte],	r10d	; store

	; compute the window data area size in bytes
	mov	eax,	r10d
	mul	r9d
	mov	dword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.size],	eax	; store

	; register the window in the window manager?
	test	word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_unregistered
	jnz	.unregistered	; no

	; create a window
	mov	al,	KERNEL_WM_WINDOW_create
	int	KERNEL_WM_IRQ
	jc	.end	; out of memory

	; return the pointer/identifier of the registered window
	mov	qword [rsp],	rcx

.unregistered:
	; fill the window area with the default background color
	mov	eax,	LIBRARY_BOSU_WINDOW_BACKGROUND_color
	mov	ecx,	dword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.size]
	shr	rcx,	KERNEL_VIDEO_DEPTH_shift
	mov	rdi,	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.address]
	rep	stosd

	; draw the window border?
	test	word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_border
	jz	.no_draw_border	; no

	; preserve the original registers
	push	r8
	push	r9

	; palette
	mov	rax,	LIBRARY_BOSU_WINDOW_BORDER_color

	; top edge
	mov	rcx,	r8
	mov	rdi,	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.address]
	rep	stosd

	; offset between the edges and the height
	sub	r8,	(LIBRARY_BOSU_WINDOW_BORDER_THICKNESS_pixel << STATIC_MULTIPLE_BY_2_shift)
	shl	r8,	KERNEL_VIDEO_DEPTH_shift
	sub	r9,	LIBRARY_BOSU_WINDOW_BORDER_THICKNESS_pixel << STATIC_MULTIPLE_BY_2_shift

.draw_border:
	; left edge
	stosd

	; change the edge color
	rol	rax,	STATIC_REPLACE_EAX_WITH_HIGH_shift

	; move the pointer to the right edge
	add	rdi,	r8

	; right edge
	stosd

	; change the edge color
	rol	rax,	STATIC_REPLACE_EAX_WITH_HIGH_shift

	; end of the left and right edge drawing?
	dec	r9
	jnz	.draw_border	; no

	; change the edge color
	rol	rax,	STATIC_REPLACE_EAX_WITH_HIGH_shift

	; bottom edge
	movzx	ecx,	word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	rep	stosd

	; restore the original registers
	pop	r9
	pop	r8

.no_draw_border:
	; display the window header
	call	library_bosu_header_update

	; process every element the window is made of
	call	library_bosu_elements

.end:
	; restore the original registers
	pop	rcx
	pop	rsi
	pop	rdi
	pop	rbx
	pop	rax

	; return from the library
	ret

	macro_debug	"library_bosu"

; input:
;	cl - number of characters making up the new prefix
;	rsi - pointer to the character string
;	rdi - pointer to the window structure
library_bosu_header_set:
	; preserve the original registers
	push	rax
	push	rcx
	push	rsi
	push	r8
	push	r9
	push	r10
	push	rdi

	; number of corners over the limit?
	cmp	cl,	LIBRARY_BOSU_WINDOW_NAME_length
	jbe	.ok	; no

	; clamp the count to LIBRARY_BOSU_WINDOW_NAME_length characters
	mov	cl,	LIBRARY_BOSU_WINDOW_NAME_length

.ok:
	; remember the old counter and the new counter
	push	qword [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.length]
	push	rcx

	; store the number of characters making up the new window name
	mov	byte [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.length],	cl

	; copy the new character string
	add	rdi,	LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.name
	rep	movsb

	; restore the new and the old counter
	pop	rcx
	pop	rax

	; clear the remaining area?
	sub	cl,	al
	jns	.ready	; no

	; convert to an absolute value
	not	cl
	inc	cl

	; clear it with STATIC_SCANCODE_SPACE characters
	mov	al,	STATIC_SCANCODE_SPACE
	rep	stosb

.ready:
	; fetch the window width, height and scanline in bytes
	mov	rsi,	qword [rsp]
	movzx	r8d,	word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	movzx	r9d,	word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
	mov	r10d,	dword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.scanline_byte]

	; redraw the header
	call	library_bosu_header_update

	; update the object name in the window manager
	mov	ax,	KERNEL_WM_WINDOW_update
	int	KERNEL_WM_IRQ

	; restore the original registers
	pop	rdi
	pop	r10
	pop	r9
	pop	r8
	pop	rsi
	pop	rcx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"library_bosu_header_set"

; input:
;	rsi - pointer to the element list
library_bosu_clean:
	; preserve the original registers
	push	rsi

.loop:
	; restore the original registers
	pop	rsi

	; return from the procedure
	ret

	macro_debug	"library_bosu_clean"

; input:
;	rsi - pointer to the window specification
library_bosu_border_correction:
	; preserve the original registers
	push	rax
	push	rsi

	; move the pointer to the start of the window element list
	add	rsi,	LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.SIZE

.loop:
	; end of the elements to fix up?
	mov	al,	byte [rsi + LIBRARY_BOSU_STRUCTURE_TYPE.set]
	cmp	al,	LIBRARY_BOSU_ELEMENT_TYPE_none
	je	.ready	; yes

	; element of type "button close"?
	cmp	al,	LIBRARY_BOSU_ELEMENT_TYPE_button_close
	je	.next	; yes, skip

	; element of type "button minimize"?
	cmp	al,	LIBRARY_BOSU_ELEMENT_TYPE_button_minimize
	je	.next	; yes, skip

	; element of type "button maximize"?
	cmp	al,	LIBRARY_BOSU_ELEMENT_TYPE_button_maximize
	je	.next	; yes, skip

	; element of type "chain"?
	cmp	al,	LIBRARY_BOSU_ELEMENT_TYPE_chain
	je	.chain	; yes

	; fix the element position by the border size
	add	word [rsi + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x],	LIBRARY_BOSU_WINDOW_BORDER_THICKNESS_pixel
	add	word [rsi + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y],	LIBRARY_BOSU_WINDOW_BORDER_THICKNESS_pixel

.next:
	; move the pointer to the next element
	movzx	eax,	word [rsi + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.size]
	add	rsi,	rax

	; continue
	jmp	.loop

.chain:
	; is the "chain" empty?
	cmp	word [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.size],	STATIC_EMPTY
	je	.next	; yes, skip

	; store the pointer to the current element
	push	rsi

	; fetch the address of the "chain"
	mov	rsi,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.address]
	call	library_bosu_border_correction	; fix up all the chain elements

	; restore the pointer to the current element
	pop	rsi

	; move the pointer to the next element
	movzx	eax,	word [rsi + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.size]
	add	rsi,	rax

	; continue
	jmp	.loop

.ready:
	; restore the original registers
	pop	rsi
	pop	rax

	; return from the procedure
	ret

	macro_debug	"library_bosu_border_correction"

; input:
;	rsi - pointer to the window properties
library_bosu_close:
	; preserve the original registers
	push	rax

	; close the window
	mov	ax,	KERNEL_WM_WINDOW_close
	int	KERNEL_WM_IRQ

	; restore the original registers
	pop	rax

	; return from the procedure
	ret

	macro_debug	"library_bosu_close"

; input:
;	rsi - pointer to the window properties
;	r8 - window width in pixels
;	r10 - window scanline in bytes
library_bosu_element_button_close:
	; preserve the original registers
	push	rax
	push	rcx
	push	rsi
	push	rdi

	; store the pointer to the window structure
	mov	rsi,	rdi

	; set the pointer to the element position
	xor	rdi,	rdi

	; position on the X axis
	mov	rax,	r8
	sub	rax,	LIBRARY_BOSU_ELEMENT_BUTTON_CLOSE_width

	; does the window have borders?
	test	word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_border
	jz	.no_border	; no

	; fix the position on the X axis
	sub	rax,	LIBRARY_BOSU_WINDOW_BORDER_THICKNESS_pixel

	; fix the position on the Y axis
	add	rdi,	r10

.no_border:
	; target position of the element's first stroke in the window data area
	add	rax,	0x05	; 5 pixels right on the X axis
	shl	rax,	KERNEL_VIDEO_DEPTH_shift
	add	rdi,	rax
	mov	rax,	r10				; and 5 pixels down on the Y axis
	shl	rax,	STATIC_MULTIPLE_BY_4_shift	; |
	add	rax,	r10				; |
	add	rdi,	rax				; /
	add	rdi,	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.address]

	; color and size of the first stroke
	mov	rax,	LIBRARY_BOSU_ELEMENT_BUTTON_FOREGROUND_color
	mov	ecx,	0x08

.left:
	; draw
	stosd

	; move the pointer to the next position
	add	rdi,	r10

	; end of the first stroke?
	dec	rcx
	jnz	.left	; no

	; position of the right stroke on the X axis
	sub	rdi,	0x08 << KERNEL_VIDEO_DEPTH_shift

	; size of the second stroke
	mov	ecx,	0x08

.right:
	; move the pointer to the next position
	sub	rdi,	r10

	; draw
	stosd

	; end of the second stroke?
	dec	rcx
	jnz	.right	; no

	; restore the original registers
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"library_bosu_element_button_close"

; input:
;	rsi - pointer to the window properties
library_bosu_element_button_minimize:
	xchg	bx,bx

	; return from the procedure
	ret

	macro_debug	"library_bosu_element_button_minimize"

; input:
;	rsi - pointer to the window properties
library_bosu_element_button_maximize:
	xchg	bx,bx

	; return from the procedure
	ret

	macro_debug	"library_bosu_element_button_maximize"

; input:
;	rsi - pointer to the window structure
; output:
;	r8 - minimum window width based on the elements it holds
;	r9 - minimum window height based on the elements it holds
library_bosu_elements_specification:
	; preserve the original registers
	push	rax
	push	rbx
	push	rsi

	; position of the farthest element on the X axis
	xor	r8,	r8

	; position of the farthest element on the Y axis
	xor	r9,	r9

	; move the pointer to the element list
	add	rsi,	LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.SIZE

.loop:
	; end of the elements?
	cmp	byte [rsi + LIBRARY_BOSU_STRUCTURE_TYPE.set],	LIBRARY_BOSU_ELEMENT_TYPE_none
	je	.end	; yes

	; element of type "chain"?
	cmp	byte [rsi + LIBRARY_BOSU_STRUCTURE_TYPE.set],	LIBRARY_BOSU_ELEMENT_TYPE_chain
	je	.next	; yes, skip

	; element position on the X axis
	movzx	eax,	word [rsi + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x]
	movzx	ebx,	word [rsi + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	add	eax,	ebx

	; further than the previous one?
	cmp	rax,	r8
	jbe	.y	; no

	; store the information
	mov	r8,	rax

.y:
	; element position on the Y axis
	movzx	eax,	word [rsi + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
	movzx	ebx,	word [rsi + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
	add	eax,	ebx

	; further than the previous one?
	cmp	rax,	r9
	jbe	.next	; no

	; store the information
	mov	r9,	rax

.next:
	; move the pointer to the next element in the list
	movzx	eax,	word [rsi + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.size]
	add	rsi,	rax

	; continue
	jmp	.loop

.end:
	; restore the original registers
	pop	rsi
	pop	rbx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"library_bosu_elements_specification"

; input:
;	rsi - pointer to the window elements
library_bosu_elements:
	; preserve the original registers
	push	rax
	push	rbx
	push	rcx
	push	rsi

	; list of jumps to the procedures
	mov	rbx,	library_bosu_element_entry

	; store the pointer to the window structure
	mov	rdi,	rsi

	; move the pointer to the start of the window element list
	add	rsi,	LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.SIZE

.loop:
	; end of the elements?
	movzx	eax,	byte [rsi + LIBRARY_BOSU_STRUCTURE_TYPE.set]
	cmp	al,	LIBRARY_BOSU_ELEMENT_TYPE_none
	je	.ready	; yes

	; element of type "draw"?
	cmp	al,	LIBRARY_BOSU_ELEMENT_TYPE_draw
	je	.leave	; yes, not handled

	; element of type "chain"?
	cmp	al,	LIBRARY_BOSU_ELEMENT_TYPE_chain
	jne	.other	; no

	; is the "chain" empty?
	cmp	word [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.size],	STATIC_EMPTY
	je	.empty	; yes, skip

	; store the pointer to the current element
	push	rsi

	; fetch the address of the "chain"
	mov	rsi,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.address]
	call	library_bosu_elements	; process all the chain elements

	; restore the pointer to the current element
	pop	rsi

.empty:
	; move the pointer to the next element
	add	rsi,	LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.SIZE

	; continue
	jmp	.loop

.other:
	; go to the element handler procedure
	call	qword [rbx + rax * STATIC_QWORD_SIZE_byte]

.leave:
	; move the pointer to the next element
	movzx	eax,	word [rsi + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.size]
	add	rsi,	rax

	; continue
	jmp	.loop

.ready:
	; restore the original register
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"library_bosu_elements"

; input:
;	rsi - pointer to the element properties
;	rdi - pointer to the window structure
library_bosu_element_taskbar:
	; preserve the original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13

	; fetch the window width, height and scanline
	movzx	r8d,	word [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	movzx	r9d,	word [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
	mov	r10d,	dword [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.scanline_byte]

	; compute the element width, height and scanline
	movzx	r11d,	word [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	movzx	r12d,	word [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
	mov	r13,	r11
	shl	r13,	KERNEL_VIDEO_DEPTH_shift

	; store the pointer to the window properties
	mov	rbx,	rdi

	; compute the absolute position of the element in the window data area
	movzx	eax,	word [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
	mul	r13	; * scanline
	movzx	edi,	word [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x]
	shl	rdi,	KERNEL_VIDEO_DEPTH_shift
	add	rdi,	rax
	add	rdi,	qword [rbx + LIBRARY_BOSU_STRUCTURE_WINDOW.address]

	; clear the element area
	mov	eax,	dword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.background]
	call	library_bosu_element_drain

	; store the pointer to the start of the element area
	push	rdi

	; compute the absolute position of the line in the element area
	mov	rax,	r12
	dec	rax	; last pixel row in the element area
	mul	r10	; * scanline

	; line width
	mov	rcx,	r11

	; direct pointer to the line being drawn
	add	rdi,	rax

	; draw the bottom edge of the element
	mov	eax,	0x0000FF00
	rep	stosd

.under_line:

	; restore the pointer to the start of the element area
	pop	rdi

	; string size to print in the label
	movzx	rcx,	byte [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.length]

	; centre the text vertically
	mov	rax,	r12
	sub	rax,	LIBRARY_FONT_HEIGHT_pixel
	shr	rax,	STATIC_DIVIDE_BY_2_shift
	mul	r10
	add	rdi,	rax

	; display the string with the default font color
	mov	ebx,	LIBRARY_BOSU_ELEMENT_TASKBAR_FOREGROUND_color
	movzx	ecx,	byte [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.length]
	add	rsi,	LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.string
	add	rdi,	LIBRARY_BOSU_ELEMENT_TASKBAR_PADDING_LEFT_pixel << KERNEL_VIDEO_DEPTH_shift
	call	library_bosu_string

	; restore the original registers
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"library_bosu_element_taskbar"

; input:
;	rsi - pointer to the "chain" element
;	rdi - pointer to the window structure
library_bosu_element_chain:
	; preserve the original registers
	push	rax
	push	rbx
	push	rsi
	push	r8
	push	r9
	push	r10

	; fetch the window width, height and scanline
	movzx	r8d,	word [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	movzx	r9d,	word [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
	mov	r10d,	dword [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.scanline_byte]

	; list of jumps to the procedures
	mov	rbx,	library_bosu_element_entry

	; process all the chain elements
	mov	rsi,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.address]

.loop:
	; end of the elements?
	movzx	eax,	byte [rsi + LIBRARY_BOSU_STRUCTURE_TYPE.set]
	cmp	al,	LIBRARY_BOSU_ELEMENT_TYPE_none
	je	.ready	; yes

	; element of type "draw"?
	cmp	al,	LIBRARY_BOSU_ELEMENT_TYPE_draw
	je	.leave	; yes, not handled

	; go to the element handler procedure
	call	qword [rbx + rax * STATIC_QWORD_SIZE_byte]

.leave:
	; move the pointer to the next element
	movzx	eax,	word [rsi + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.size]
	add	rsi,	rax

	; continue
	jmp	.loop

.ready:
	; restore the original registers
	pop	r10
	pop	r9
	pop	r8
	pop	rsi
	pop	rbx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"library_bosu_element_chain"

; input:
;	rsi - pointer to the window structure
;	r8 - window width in pixels
;	r9 - window height in pixels
;	r10 - window scanline in bytes
library_bosu_header_update:
	; preserve the original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	r11
	push	r12
	push	r13
	push	r15
	push	rdi
	push	rsi

	; default width of the header element
	mov	r11,	r8

	; does the window have borders?
	test	word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_border
	jz	.no_border	; no

	; fix up the element width
	sub	r11,	LIBRARY_BOSU_WINDOW_BORDER_THICKNESS_pixel << STATIC_MULTIPLE_BY_2_shift

.no_border:
	; close control button?
	test	word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_BUTTON_close
	jz	.no_close	; no

	; fix up the element width
	sub	r11,	LIBRARY_BOSU_ELEMENT_BUTTON_CLOSE_width

.no_close:
	; set the header height and scanline
	mov	r12,	LIBRARY_BOSU_HEADER_HEIGHT_pixel
	mov	r13,	r11
	shl	r13,	KERNEL_VIDEO_DEPTH_shift

	; fetch the pointer to the window data area
	mov	rdi,	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.address]

	; compute the absolute address of the element in the window area

	; position on the Y axis
	mov	rax,	LIBRARY_BOSU_WINDOW_BORDER_THICKNESS_pixel
	mul	r10	; * scanline
	add	rdi,	rax

	; position on the X axis
	mov	rax,	LIBRARY_BOSU_WINDOW_BORDER_THICKNESS_pixel
	shl	rax,	KERNEL_VIDEO_DEPTH_shift
	add	rdi,	rax

	; clear the element area with the given color
	mov	eax,	LIBRARY_BOSU_HEADER_BACKGROUND_color
	call	library_bosu_element_drain

	; centre the text vertically
	mov	rax,	r12
	sub	rax,	LIBRARY_FONT_HEIGHT_pixel
	shr	rax,	STATIC_DIVIDE_BY_2_shift
	mul	r10
	add	rdi,	rax

	; display the header label
	mov	ebx,	LIBRARY_BOSU_HEADER_FOREGROUND_color
	movzx	rcx,	byte [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.length]
	add	rsi,	LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.name
	add	rdi,	LIBRARY_BOSU_HEADER_PADDING_LEFT_pixel << KERNEL_VIDEO_DEPTH_shift
	call	library_bosu_string

	; restore the original registers
	pop	rsi
	pop	rdi
	pop	r15
	pop	r13
	pop	r12
	pop	r11
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"library_bosu_header_update"

; input:
;	ebx - font color
;	rcx - string size in characters
;	rsi - pointer to the string
;	rdi - pointer to the element area
;	r8 - window area width in pixels
;	r9 - window area height in pixels
;	r10 - window scanline in bytes
;	r11 - element area width in pixels
;	r12 - element area height in pixels
;	r13 - element scanline in bytes
library_bosu_string:
	; preserve the original registers
	push	rax
	push	rdi
	push	r9
	push	r13

	; empty string?
	test	rcx,	rcx
	jz	.end	; yes

	; clear the accumulator
	xor	rax,	rax

.loop:
	; fetch the character from the string
	lodsb

	; display the character
	call	library_bosu_char

	; move the pointer to the next position in the element area
	add	rdi,	LIBRARY_FONT_WIDTH_pixel << KERNEL_VIDEO_DEPTH_shift

	; end of string?
	dec	rcx
	jz	.end	; no, display the next one

	; end of the element area?
	sub	r11,	LIBRARY_FONT_WIDTH_pixel
	jns	.loop	; no, one more character still fits

.end:
	; restore the original registers
	pop	r13
	pop	r9
	pop	rdi
	pop	rax

	; return from the procedure
	ret

	macro_debug	"library_bosu_string"

; input:
;	rax - ASCII code of the character to display
;	rbx - font color
;	rdi - pointer to the start of the element area
;	r8 - window area width in pixels
;	r9 - window area height in pixels
;	r10 - window scanline in bytes
;	r11 - element area width in pixels
;	r12 - element area height in pixels
;	r13 - element scanline in bytes
library_bosu_char:
	; preserve the original registers
	push	rax
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r12
	push	r11

	; set the pointer to the font matrix
	mov	rsi,	library_font_matrix

	; fix the ASCII code by the offset in the font matrix
	sub	al,	LIBRARY_FONT_MATRIX_offset
	js	.end	; the counter wrapped, a non printable character - skip it

	; set the pointer to the glyph matrix
	mul	qword [library_font_height_pixel]
	add	rsi,	rax

	; set the color of the next string pixels
	mov	eax,	ebx

	; matrix height in pixels
	mov	rdx,	qword [library_font_height_pixel]

.next:
	; restore the remaining object width
	mov	r11,	qword [rsp]

	; matrix width
	mov	rcx,	qword [library_font_width_pixel]
	dec	rcx	; we count from zero

.loop:
	; change the pixel color?
	bt	word [rsi],	cx
	jnc	.omit	; no

	; change the color
	stosd

	; draw the shadow behind the pixel
	mov	dword [rdi],	STATIC_EMPTY

	; continue
	jmp	.continue

.omit:
	; move the pointer to the next pixel
	add	rdi,	KERNEL_VIDEO_DEPTH_byte

.continue:
	; end of the element area?
	dec	r11
	jnz	.continue_pixels	; no

	; yes, fix up the remaining pixels in the glyph row
	shl	rcx,	KERNEL_VIDEO_DEPTH_shift
	add	rdi,	rcx

	; next glyph matrix row
	jmp	.end_of_line

.continue_pixels:
	; next pixel from the matrix row?
	dec	rcx
	jns	.loop	; yes

.end_of_line:
	; move the pointer to the next matrix row in the element area
	sub	rdi,	LIBRARY_FONT_WIDTH_pixel << KERNEL_VIDEO_DEPTH_shift
	add	rdi,	r10

	; move the pointer to the next matrix row
	inc	rsi

	; have we processed all the rows of the element area?
	dec	r12
	jz	.end	; yes

.line_invisible:
	; has the whole glyph matrix been processed?
	dec	rdx
	jnz	.next	; no

.end:
	; restore the original registers
	pop	r11
	pop	r12
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"library_bosu_char"

; input:
;	rsi - pointer to the element
;	rdi - pointer to the window structure
library_bosu_element_button:
	; preserve the original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13

	; fetch the window width, height and scanline
	movzx	r8d,	word [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	movzx	r9d,	word [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
	mov	r10d,	dword [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.scanline_byte]

	; compute the element width, height and scanline
	movzx	r11d,	word [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	movzx	r12d,	word [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
	mov	r13,	r11
	shl	r13,	KERNEL_VIDEO_DEPTH_shift

	; store the pointer to the window properties
	mov	rbx,	rdi

	; compute the absolute position of the element in the window data area
	movzx	eax,	word [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
	mul	r10	; * scanline
	movzx	edi,	word [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x]
	shl	rdi,	KERNEL_VIDEO_DEPTH_shift
	add	rdi,	rax
	add	rdi,	qword [rbx + LIBRARY_BOSU_STRUCTURE_WINDOW.address]

	; clear the element area with the default color
	mov	eax,	LIBRARY_BOSU_ELEMENT_BUTTON_BACKGROUND_color
	call	library_bosu_element_drain

	; string size to print in the label
	movzx	rcx,	byte [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.length]

	; centre the text vertically
	mov	rax,	r12
	sub	rax,	LIBRARY_FONT_HEIGHT_pixel
	shr	rax,	STATIC_DIVIDE_BY_2_shift
	mul	r10
	add	rdi,	rax

	; text width greater than the element width?
	movzx	eax,	byte [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.length]
	mul	qword [library_font_width_pixel]
	cmp	rax,	r11
	ja	.aligned	; no centring

	; centre the text horizontally

	; subtract half the string width in pixels
	shr	rax,	STATIC_DIVIDE_BY_2_shift

	; from half the element width in pixels
	mov	rdx,	r11
	shr	rdx,	STATIC_DIVIDE_BY_2_shift
	sub	rdx,	rax

	; fix the string position pointer in the element area on the X axis
	shl	rdx,	KERNEL_VIDEO_DEPTH_shift
	add	rdi,	rdx

.aligned:
	; display the string with the default font color
	mov	ebx,	LIBRARY_BOSU_ELEMENT_BUTTON_FOREGROUND_color
	movzx	ecx,	byte [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.length]
	add	rsi,	LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.string
	call	library_bosu_string

	; restore the original registers
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"library_bosu_element_button"

; input:
;	eax - interface background color
;	rdi - pointer to the element area in pixels
;	r10 - window scanline in bytes
;	r11 - element width in pixels
;	r12 - element height in pixels
;	r13 - element scanline in bytes
library_bosu_element_drain:
	; preserve the original registers
	push	rcx
	push	rdx
	push	rdi
	push	r12

.loop:
	; change the pixel color across the whole element area width
	mov	rcx,	r11
	rep	stosd

	; move the pointer to the next pixel line in the element area
	sub	rdi,	r13	; element scanline
	add	rdi,	r10	; window scanline

	; end of the element area?
	dec	r12
	jnz	.loop	; no, continue

	; restore the original registers
	pop	r12
	pop	rdi
	pop	rdx
	pop	rcx

	; return from the procedure
	ret

	macro_debug	"library_bosu_element_drain"

; input:
;	rsi - pointer to the element
;	rdi - pointer to the window structure
library_bosu_element_label:
	; preserve the original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13

	; fetch the window width, height and scanline
	movzx	r8d,	word [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	movzx	r9d,	word [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
	mov	r10d,	dword [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.scanline_byte]

	; compute the element width, height and scanline
	movzx	r11d,	word [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	movzx	r12d,	word [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
	mov	r13,	r11
	shl	r13,	KERNEL_VIDEO_DEPTH_shift

	; store the pointer to the window properties
	mov	rbx,	rdi

	; compute the absolute position of the element in the window data area
	movzx	eax,	word [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
	mul	r10	; * scanline
	movzx	edi,	word [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x]
	shl	rdi,	KERNEL_VIDEO_DEPTH_shift
	add	rdi,	rax
	add	rdi,	qword [rbx + LIBRARY_BOSU_STRUCTURE_WINDOW.address]

	; clear the element area with the default background color
	mov	eax,	LIBRARY_BOSU_ELEMENT_LABEL_BACKGROUND_color
	call	library_bosu_element_drain

	; string size to print in the label
	movzx	rcx,	byte [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.length]

	; centre the text vertically
	mov	rax,	r12
	sub	rax,	LIBRARY_FONT_HEIGHT_pixel
	shr	rax,	STATIC_DIVIDE_BY_2_shift
	mul	r10
	add	rdi,	rax

	; centre the string?
	test	byte [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.flags],	LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_center
	jz	.no_center	; no

	; string width greater than the element width?
	movzx	eax,	byte [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.length]
	mul	qword [library_font_width_pixel]
	cmp	rax,	r11
	ja	.aligned	; centring not possible

	; subtract half the string width in pixels
	shr	rax,	STATIC_DIVIDE_BY_2_shift

	; from half the element width in pixels
	mov	rdx,	r11
	shr	rdx,	STATIC_DIVIDE_BY_2_shift
	sub	rdx,	rax

	; fix the string position pointer in the element area on the X axis
	shl	rdx,	KERNEL_VIDEO_DEPTH_shift
	add	rdi,	rdx

.no_center:
	; move the string over to the right edge of the element?
	test	byte [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.flags],	LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_right
	jz	.aligned	; no

	; string width greater than the element width?
	movzx	eax,	byte [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.length]
	mul	qword [library_font_width_pixel]
	cmp	rax,	r11
	ja	.aligned	; centring not possible

	; from half the element width in pixels
	mov	rdx,	r11
	sub	rdx,	rax

	; fix the string position pointer in the element area on the X axis
	shl	rdx,	KERNEL_VIDEO_DEPTH_shift
	add	rdi,	rdx

.aligned:
	; display the string with the default font color
	mov	ebx,	LIBRARY_BOSU_ELEMENT_LABEL_FOREGROUND_color
	movzx	ecx,	byte [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.length]
	add	rsi,	LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.string
	call	library_bosu_string

	; restore the original registers
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"library_bosu_element_label"

; input:
;	rsi - pointer to the window structure
;	r8 - cursor position on the X axis
;	r9 - cursor position on the Y axis
; output:
;	CF flag - if no element was found at the given position
;	rsi - pointer to the window element
library_bosu_element:
	; preserve the original registers
	push	rdi
	push	rsi

	; store the pointer to the window structure
	mov	rdi,	rsi

	; move the pointer to the window elements
	add	rsi,	LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.SIZE

	; search the elements
	call	library_bosu_element_subroutine
	jc	.end	; not found

	; return the pointer to the element
	mov	qword [rsp],	rsi

.end:
	; restore the original registers
	pop	rsi
	pop	rdi

	; return from the procedure
	ret

	macro_debug	"library_bosu_element"

library_bosu_element_subroutine:
	; preserve the original registers
	push	rax
	push	rbx
	push	rcx
	push	r8
	push	r9
	push	rsi

.loop:
	; walk the window elements in order

	; end of the element list?
	cmp	byte [rsi + LIBRARY_BOSU_STRUCTURE_TYPE.set],	LIBRARY_BOSU_ELEMENT_TYPE_none
	je	.error	; yes

	; fetch the element size
	movzx	ecx,	word [rsi + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.size]

	; element of type "chain"?
	cmp	byte [rsi + LIBRARY_BOSU_STRUCTURE_TYPE.set],	LIBRARY_BOSU_ELEMENT_TYPE_chain
	jne	.no_chain	; no

	; store the pointer to the chain element
	push	rsi

	; check the elements inside the chain
	mov	rsi,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.address]
	call	library_bosu_element_subroutine
	jnc	.found	; element found in the chain

	; restore the pointer to the chain element
	pop	rsi

	; no element in the chain, continue
	jmp	.next_from_chain

.found:
	; return the pointer to the element
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	rsi

	; restore the pointer to the chain element
	pop	rsi

	; end of the procedure handler
	jmp	.end

.no_chain:
	; store the element size
	push	rcx

	; element of type: button close?
	cmp	byte [rsi + LIBRARY_BOSU_STRUCTURE_TYPE.set],	LIBRARY_BOSU_ELEMENT_TYPE_button_close
	jne	.no_button_close	; no

	; element position on the X axis
	movzx	eax,	word [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	sub	rax,	LIBRARY_BOSU_ELEMENT_BUTTON_CLOSE_width

	; element position on the Y axis
	xor	ecx,	ecx

	; does the window contain borders?
	test	word [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_border
	jz	.no_button_close_border	; no

	; fix the position on the X,Y axes
	add	rax,	LIBRARY_BOSU_WINDOW_BORDER_THICKNESS_pixel
	add	rcx,	LIBRARY_BOSU_WINDOW_BORDER_THICKNESS_pixel

.no_button_close_border:
	; compare the pointer position with the left edge of the element
	cmp	r8,	rax
	jl	.next	; outside the element area

	; compare the pointer position with the right edge of the element
	add	rax,	LIBRARY_BOSU_ELEMENT_BUTTON_CLOSE_width
	cmp	r8,	rax
	jge	.next	; outside the element area

	; compare the pointer position with the top edge of the element
	cmp	r9,	rcx
	jl	.next	; outside the element area

	; compare the pointer position with the bottom edge of the element
	add	rcx,	LIBRARY_BOSU_ELEMENT_BUTTON_CLOSE_width
	cmp	r9,	rcx
	jge	.next	; outside the element area

	; recognised element: button close
	jmp	.element_recognized

.no_button_close:
	; compare the pointer position with the left edge of the element
	movzx	eax,	word [rsi + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x]
	cmp	r8,	rax
	jl	.next	; outside the element area

	; compare the pointer position with the right edge of the element
	movzx	ebx,	word [rsi + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	add	rax,	rbx
	cmp	r8,	rax
	jge	.next	; outside the element area

	; compare the pointer position with the top edge of the element
	movzx	rax,	word [rsi + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
	cmp	r9,	rax
	jl	.next	; outside the element area

	; compare the pointer position with the bottom edge of the element
	movzx	ebx,	word [rsi + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
	add	rax,	rbx
	cmp	r9,	rax
	jge	.next	; outside the element area

.element_recognized:
	; drop the element size from the stack
	add	rsp,	STATIC_QWORD_SIZE_byte

	; flag, success
	clc

	; return the pointer to the element
	mov	qword [rsp],	rsi

	; end of procedure
	jmp	.end

.next:
	; restore the element size
	pop	rcx

.next_from_chain:
	; move the pointer to the next element in the list
	add	rsi,	rcx

	; continue
	jmp	.loop

.error:
	; flag, error
	stc

.end:
	; restore the original registers
	pop	rsi
	pop	r9
	pop	r8
	pop	rcx
	pop	rbx
	pop	rax

	; return from the subprocedure
	ret

	macro_debug	"library_bosu_element_subroutine"
