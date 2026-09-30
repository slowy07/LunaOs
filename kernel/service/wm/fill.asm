
; input:
;	rax - pointer to the filling object
;	r8w - position on the X axis
;	r9w - position on the Y axis
;	r10w - width of the zone
;	r11w - height of the zone
kernel_wm_fill_insert_by_register:
	; preserve the original registers
	push rcx
	push rdi

	; max number of slots on the list
	mov ecx, KERNEL_WM_FILL_LIST_limit

	; set the pointer to the list
	mov rdi, qword [rel kernel_wm_fill_list_address]

.loop:
	; a free slot?
	cmp qword [rdi + KERNEL_WM_STRUCTURE_FILL.object], STATIC_EMPTY
	jne .next ; no

	; put a new zone on the list
	mov word [rdi + KERNEL_WM_STRUCTURE_FILL.field + KERNEL_WM_STRUCTURE_FIELD.x], r8w
	mov word [rdi + KERNEL_WM_STRUCTURE_FILL.field + KERNEL_WM_STRUCTURE_FIELD.y], r9w
	mov word [rdi + KERNEL_WM_STRUCTURE_FILL.field + KERNEL_WM_STRUCTURE_FIELD.width], r10w
	mov word [rdi + KERNEL_WM_STRUCTURE_FILL.field + KERNEL_WM_STRUCTURE_FIELD.height], r11w

	; and its dependent object
	mov qword [rdi + KERNEL_WM_STRUCTURE_FILL.object], rax

	; done
	jmp .end

.next:
	; move the pointer to the next entry
	add rdi, KERNEL_WM_STRUCTURE_FILL.SIZE

	; end of the entries
	dec rcx
	jnz .loop ; no

	; error
	xchg bx,bx
	jmp $

.end:
	; restore the original registers
	pop rdi
	pop rcx

	; return from the procedure
	ret

	macro_debug "kernel_wm_fill_insert_by_register"

; input:
;	rsi - pointer to the object
kernel_wm_fill_insert_by_object:
	; preserve the original registers
	push rax
	push rcx
	push rdi
	push rsi

	; max number of slots on the list
	mov ecx, KERNEL_WM_FILL_LIST_limit

	; set the pointer to the list
	mov rdi, qword [rel kernel_wm_fill_list_address]

.loop:
	; a free slot?
	cmp qword [rdi + KERNEL_WM_STRUCTURE_FILL.object], STATIC_EMPTY
	jne .next ; no

	; insert the fill properties
	movsw ; position on the X axis
	movsw ; position on the Y axis
	movsw ; width
	movsw ; height

	; and the information about the dependent object
	mov rax, qword [rsp]
	mov qword [rdi], rax

	; done
	jmp .end

.next:
	; move the pointer to the next entry
	add rdi, KERNEL_WM_STRUCTURE_FILL.SIZE

	; end of the entries
	dec rcx
	jnz .loop ; no

	; error
	xchg bx,bx
	jmp $

.end:
	; restore the original registers
	pop rsi
	pop rdi
	pop rcx
	pop rax

	; return from the procedure
	ret

	macro_debug "kernel_wm_fill_insert_by_object"

kernel_wm_fill:
	; preserve the original registers
	push rax
	push rcx
	push rdx
	push rsi
	push rdi
	push r8
	push r9
	push r10
	push r11
	push r12
	push r13
	push r14
	push r15

	; max number of slots on the list
	mov ecx, KERNEL_WM_FILL_LIST_limit

	; set the pointer to the fill list
	mov rsi, qword [rel kernel_wm_fill_list_address]

.loop:
	; an empty position?
	cmp qword [rsi + KERNEL_WM_STRUCTURE_FILL.object], STATIC_EMPTY
	je .next ; yes

	; save the pointer and the size of the list
	push rcx
	push rsi

	; fetch the fill properties
	movzx r8d, word [rsi + KERNEL_WM_STRUCTURE_FILL.field + KERNEL_WM_STRUCTURE_FIELD.x]
	movzx r9d, word [rsi + KERNEL_WM_STRUCTURE_FILL.field + KERNEL_WM_STRUCTURE_FIELD.y]
	movzx r10d, word [rsi + KERNEL_WM_STRUCTURE_FILL.field + KERNEL_WM_STRUCTURE_FIELD.width]
	movzx r11d, word [rsi + KERNEL_WM_STRUCTURE_FILL.field + KERNEL_WM_STRUCTURE_FIELD.height]

	; is the described zone on the negative X axis?
	bt r8w, STATIC_QWORD_BIT_sign
	jnc .x_positive ; no

	; cut out the invisible fragment
	not r8w
	inc r8w
	sub r10w, r8w

	; move to the beginning of the X axis
	xor r8w, r8w

.x_positive:
	; is the described zone on the negative Y axis?
	bt r9w, STATIC_QWORD_BIT_sign
	jnc .y_positive ; no

	; cut out the invisible fragment
	not r9w
	inc r9w
	sub r11w, r9w

	; move to the beginning of the Y axis
	xor r9w, r9w

.y_positive:
	; does the described zone exceed the X axis?
	mov ax, r8w
	add ax, r10w
	cmp ax, word [rel kernel_video_width_pixel]
	jb .x_inside ; no

	; limit the zone to the screen space
	sub ax, word [rel kernel_video_width_pixel]
	sub r10w, ax

.x_inside:
	; does the described zone exceed the Y axis?
	mov ax, r9w
	add ax, r11w
	cmp ax, word [rel kernel_video_height_pixel]
	jb .y_inside ; no

	; limit the zone to the screen space
	sub ax, word [rel kernel_video_height_pixel]
	sub r11w, ax

.y_inside:
	; compute the variables for the space copying operation

	; fetch the pointer to the filling object
	mov rsi, qword [rsi + KERNEL_WM_STRUCTURE_FILL.object]

	; scanlines
	; r12 - fill scanline in Bytes
	movzx r12d, r10w
	shl r12d, KERNEL_VIDEO_DEPTH_shift
	; r13 - object scanline in Bytes
	movzx r13d, word [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.width]
	shl r13d, KERNEL_VIDEO_DEPTH_shift
	; r14 - buffer scanline in Bytes
	movzx r14d, word [rel kernel_wm_object_framebuffer + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.width]
	shl r14d, KERNEL_VIDEO_DEPTH_shift

	; compute the pointer of the fill start in the buffer space

	; position relative to the X axis
	movzx edi, r8w
	shl edi, KERNEL_VIDEO_DEPTH_shift

	; position relative to the Y axis
	mov eax, r14d
	mul r9d

	; direct pointer to the fill space in the buffer
	add rdi, rax
	add rdi, qword [rel kernel_wm_object_framebuffer + KERNEL_WM_STRUCTURE_OBJECT.address]

	; correction of the fill position relative to the object
	; -----------------------------------------------------------------------
	sub r8w, word [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.x]
	js .overflow ; the filling object outside the fragment area
	sub r9w, word [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.y]
	js .overflow ; the filling object outside the fragment area

	; compute the pointer of the fill start in the object space

	; position on the Y axis in Bytes (relative)
	movzx eax, r9w
	mul r13d

	; position on the X axis in Bytes (relative)
	shl r8d, KERNEL_VIDEO_DEPTH_shift

	; convert to an absolute pointer
	mov rsi, qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.address]
	add rsi, rax
	add rsi, r8

	; Filling

.row:
	; next row of N pixels
	mov cx, r10w

.print:
	; a completely transparent pixel?
	cmp byte [rsi + 0x03], STATIC_MAX_unsigned
	je .transparent_max ; yes

	; fill the pixel row with the filler
	movsd

	; continue
	jmp .continue

.overflow:
	; process the fragment once again as a zone
	mov rax, qword [rsp]
	call kernel_wm_zone_insert_by_object
	call kernel_wm_zone

	; skip the fragment
	jmp .leave

.transparent_max:
	; skip the pixel
	add rsi, STATIC_DWORD_SIZE_byte
	add rdi, STATIC_DWORD_SIZE_byte

.continue:
	; next pixel?
	dec cx
	jnz .print ; yes

	; move the pointers to the next line
	; buffer
	sub rdi, r12
	add rdi, r14
	; filler
	sub rsi, r12
	add rsi, r13

	; remaining fill rows?
	dec r11w
	jnz .row ; yes

	; the buffer content has been modified
	or word [rel kernel_wm_object_framebuffer + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags], KERNEL_WM_OBJECT_FLAG_flush

.leave:
	; restore the pointer and the size of the list
	pop rsi
	pop rcx

	; free the fill on the list
	mov qword [rsi + KERNEL_WM_STRUCTURE_FILL.object], STATIC_EMPTY

.next:
	; move the pointer to the next fill
	add rsi, KERNEL_WM_STRUCTURE_FILL.SIZE

	; the next entry on the list?
	dec cx
	jnz .loop ; yes

.end:
	; restore the original registers
	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop rdi
	pop rsi
	pop rdx
	pop rcx
	pop rax

	; return from the procedure
	ret

	macro_debug "kernel_wm_fill"
