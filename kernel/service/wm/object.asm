;===============================================================================

;===============================================================================+
; input:
;	rsi - pointer to the object
; output:
;	CF flag - if there is no space
;	rsi - pointer to the record in the object table
kernel_wm_object_insert:
	; preserve the original registers
	push	rax
	push	rcx
	push	rdi
	push	rsi

	; does the list have free entries?
	cmp	qword [rel kernel_wm_object_list_length],	KERNEL_WM_OBJECT_LIST_limit
	je	.error	; no space

	; find a free record in the table
	call	kernel_wm_object_table_entry
	jc	.error	 ; no space

	; preserve the pointer to the beginning of the record in the table
	push	rdi

	; load the object
	mov	rcx,	(KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.SIZE) >> STATIC_DIVIDE_BY_QWORD_shift
	rep	movsq

	; fetch the pointer to the beginning of the record in the table
	mov	rdi,	qword [rsp]

	; fetch the PID of the process (window owner)
	call	kernel_task_active_pid
	mov	qword [rdi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.pid],	rax

	;-----------------------------------------------------------------------

	; lock access to modifying the object list
	macro_lock	kernel_wm_object_semaphore,	0

	; number of entries of the object list
	mov	rcx,	qword [rel kernel_wm_object_list_length]

	; set the pointer to the beginning of the object list
	mov	rsi,	qword [rel kernel_wm_object_list_address]

.loop:
	; fetch the object pointer held in the object list entry
	lodsq

	; entry empty?
	test	rax,	rax
	jz	.found	; yes

	; N entries left to check
	dec	rcx

	; insert the registered object before the arbiter (if it exists)

	; is the object an arbiter?
	test	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_arbiter
	jz	.loop	; no, keep searching

	; no entries left to shift?
	test	rcx,	rcx
	jz	.moved	; yes

	; shift all following object list entries one position further
	shl	rcx,	KERNEL_WM_OBJECT_LIST_ENTRY_SIZE_shift

	; set the pointer to the last and the next entry
	add	rsi,	rcx

	; correct the position of the pointers
	mov	rdi,	rsi
	sub	rsi,	KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.SIZE

	; preserve the original processor flags
	pushf

	; convert the indirect pointer into a counter
	shr	rcx,	KERNEL_WM_OBJECT_LIST_ENTRY_SIZE_shift
	inc	rcx	; shift along with the arbiter

	; shift the entries
	std	; backwards
	rep	movsq

	; restore the original processor flags
	popf

	; correct the pointer after the operation
	add	rsi,	KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.SIZE

.moved:
	; correct the pointer relative to the arbiter
	add	rsi,	KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.SIZE

.found:
	; restore the pointer to the table record position
	pop	rax

	; store the pointer in the object list entry
	mov	qword [rsi - KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.SIZE],	rax

	; return the pointer of the registered object
	mov	qword [rsp],	rax

	; object registered on the list
	inc	qword [rel kernel_wm_object_list_length]

	; release access to modifying the object list
	mov	byte [rel kernel_wm_object_semaphore],	STATIC_FALSE

	; end of the procedure
	jmp	.end

.error:
	; flag, error
	stc

.end:
	; restore the original registers
	pop	rsi
	pop	rdi
	pop	rcx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"kernel_wm_object_insert"

;===============================================================================
; output:
;	CF flag - if there are no free records
;	rdi - pointer to the free table record
kernel_wm_object_table_entry:
	; preserve the original registers
	push	rcx
	push	rsi
	push	rdi

	; set the pointer to the beginning of the object table
	mov	rsi,	qword [rel kernel_wm_object_table_address]

.block:
	; number of objects per data block of the object table
	mov	rcx,	STATIC_STRUCTURE_BLOCK.link / (KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.SIZE)

.loop:
	; record free?
	cmp	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.address],	STATIC_EMPTY
	je	.found	; yes

	; end of the records in the object table data block?
	dec	rcx
	jz	.loop	; no

	; move the pointer to the next record
	add	rsi,	KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.SIZE

	; keep searching
	jmp	.loop

.next:
	; end of the available object table data blocks?
	and	si,	STATIC_PAGE_mask
	cmp	qword [rsi + STATIC_STRUCTURE_BLOCK.link],	STATIC_EMPTY
	je	.resize	; yes

.continue:
	; load the next object table data block
	mov	rsi,	qword [abs STATIC_STRUCTURE_BLOCK.link]

	; continue processing
	jmp	.block

.resize:
	; prepare a new data block for the object table
	call	kernel_memory_alloc_page
	jc	.error	; no space

	; attach the data block to the end of the object table
	mov	qword [rsi + STATIC_STRUCTURE_BLOCK.link],	rdi

	; load the new object table data block
	jmp	.continue

.found:
	; return the pointer to the free table record
	mov	qword [rsp],	rsi

	; end of the procedure
	jmp	.end

.error:
	; flag, error
	stc

.end:
	; restore the original registers
	pop	rdi
	pop	rsi
	pop	rcx

	; return from the procedure
	ret

	macro_debug	"kernel_wm_object_table_entry"

;===============================================================================
kernel_wm_object:
	; preserve the original registers
	push	rax
	push	rsi

	; set the pointer to the beginning of the object list
	mov	rsi,	qword [rel kernel_wm_object_list_address]

.loop:
	; fetch the object pointer from the list
	lodsq

	; end of the entries?
	test	rax,	rax
	jz	.end	; yes

	; redraw the content under the object?
	test	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_undraw
	jnz	.undraw	; yes

	; is the object visible?
	test	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_visible
	jz	.loop	; no

	; has the object updated its content?
	test	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_flush
	jz	.loop	; no

.undraw:
	; process the zone
	; rax - pointer to the object
	call	kernel_wm_zone_insert_by_object

	; clear the object update flag or the redraw-under-the-object flag
	and	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	~KERNEL_WM_OBJECT_FLAG_flush & ~KERNEL_WM_OBJECT_FLAG_undraw

	; force the cursor object to be updated
	or	word [rel kernel_wm_object_cursor + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_flush

	; continue
	jmp	.loop

.end:
	; restore the original registers
	pop	rsi
	pop	rax

	; return from the procedure
	ret

	macro_debug	"kernel_wm_object"

;===============================================================================
; input:
;	rcx - PID of the process
kernel_wm_object_drain:
	; preserve the original registers
	push	rsi

.next:
	; close all objects belonging to the process
	call	kernel_wm_object_by_pid
	jc	.end	; all closed

	; remove the object
	call	kernel_wm_object_delete

.end:
	; restore the original registers
	pop	rsi

	; return from the procedure
	ret

	macro_debug	"kernel_wm_object_drain"

;===============================================================================
; input:
;	rcx - PID of the process
; output:
;	CF flag, if not found
;	rsi - pointer to the object on the list
kernel_wm_object_by_pid:
	; preserve the original registers
	push	rax
	push	rsi

	; are there objects on the list?
	cmp	qword [rel kernel_wm_object_list_length],	STATIC_EMPTY
	je	.error	; no

	; search the object list
	mov	rsi,	qword [rel kernel_wm_object_list_address]

.loop:
	; fetch the pointer to the object table record
	lodsq

	; end of the entries on the object list?
	test	rax,	rax
	jz	.error	; yes

	; does the object carry the searched process PID?
	cmp	qword [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.pid],	rcx
	jne	.loop	; no

.found:
	; return the pointer to the object
	mov	qword [rsp],	rax

	; end of the procedure handling
	jmp	.end

.error:
	; flag, error
	stc

.end:
	; restore the original registers
	pop	rsi
	pop	rax

	; return from the procedure
	ret

	; information for Bochs
	macro_debug	"kernel_wm_object_by_pid"

;===============================================================================
; input:
;	rbx - window identifier
; output:
;	CF flag, if not found
;	rsi - pointer to the object on the list
kernel_wm_object_by_id:
	; preserve the original registers
	push	rax
	push	rsi

	; are there objects on the list?
	cmp	qword [rel kernel_wm_object_list_length],	STATIC_EMPTY
	je	.error	; no

	; fetch the pointer to the beginning of the object list
	mov	rsi,	qword [rel kernel_wm_object_list_address]

.loop:
	; fetch the object pointer from the list
	lodsq

	; does the object carry the searched identifier?
	cmp	qword [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.id],	rbx
	je	.found	; yes

	; end of the entries on the object list?
	cmp	qword [rsi],	STATIC_EMPTY
	jnz	.loop	; no

.error:
	; flag, error
	stc

	; end of the procedure handling
	jmp	.end

.found:
	; return the pointer to the object
	mov	qword [rsp],	rax

.end:
	; restore the original registers
	pop	rsi
	pop	rax

	; return from the procedure
	ret

	; information for Bochs
	macro_debug	"kernel_wm_object_by_id"


;===============================================================================
; output:
;	rcx - new identifier
kernel_wm_object_id_get:
	; lock access to the procedure
	macro_lock	kernel_wm_object_id_semaphore,	0

	; fetch the free identifier
	mov	rcx,	qword [rel kernel_wm_object_id]

	; prepare the next one
	inc	qword [rel kernel_wm_object_id]

	; release access to the procedure
	mov	byte [rel kernel_wm_object_id_semaphore],	STATIC_FALSE

	; return from the procedure
	ret

	macro_debug	"kernel_wm_object_id_get"

;===============================================================================
; input:
;	r8w - cursor position on the X axis
;	r9w - cursor position on the Y axis
; output:
;	CF flag - if no entry with the object pointer was found
;	rsi - pointer to the object table record located under the cursor coordinates
kernel_wm_object_find:
	; preserve the original registers
	push	rax
	push	rcx
	push	rsi

	; are there entries on the list?
	cmp	qword [rel kernel_wm_object_list_length],	STATIC_EMPTY
	je	.error	; no

	; set the pointer to the last entry of the object list
	mov	rsi,	qword [rel kernel_wm_object_list_length]
	shl	rsi,	KERNEL_WM_OBJECT_LIST_ENTRY_SIZE_shift
	; convert to a direct address
	add	rsi,	qword [rel kernel_wm_object_list_address]

.loop:
	; set the pointer to the entry to check
	sub	rsi,	KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.SIZE

	; end of the object list?
	cmp	rsi,	qword [rel kernel_wm_object_list_address]
	jb	.error	; yes

	; fetch the object pointer from the list entry
	mov	rax,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.object_address]

	; is the object visible?
	test	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_visible
	jz	.loop	; no

	;-----------------------------------------------------------------------
	; pointer within the object space relative to the left edge?
	cmp	r8w,	word [rax + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.x]
	jl	.loop	; no

	; pointer within the object space relative to the top edge?
	cmp	r9w,	word [rax + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.y]
	jl	.loop	; no

	; pointer within the object space relative to the right edge?
	mov	cx,	word [rax + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.x]
	add	cx,	word [rax + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.width]
	cmp	r8w,	cx
	jge	.loop	; no

	; pointer within the object space relative to the bottom edge?
	mov	cx,	word [rax + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.y]
	add	cx,	word [rax + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.height]
	cmp	r9w,	cx
	jge	.loop	; no
	;-----------------------------------------------------------------------

	; return the pointer to the object
	mov	qword [rsp],	rax

	; flag, success
	clc

	; end
	jmp	.end

.error:
	; flag, error
	stc

.end:
	; restore the original registers
	pop	rsi
	pop	rcx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"kernel_wm_object_find"

;===============================================================================
; input:
;	rsi - pointer to the record from the object table
kernel_wm_object_up:
	; preserve the original register
	push	rax
	push	rcx
	push	rdi
	push	rsi

	; lock access to modifying the object list
	macro_lock	kernel_wm_object_semaphore,	0

	; shifting an entry on the object list is not equivalent to modifying the record in the object table
	push	qword [rel kernel_wm_object_list_modify_time]

	; look for the entry describing the object table record
	mov	rcx,	qword [rel kernel_wm_object_list_length]
	mov	rdi,	qword [rel kernel_wm_object_list_address]

.search:
	; found?
	cmp	rsi,	qword [rdi + KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.object_address]
	je	.found	; yes

	; move the pointer to the next object list entry
	add	rdi,	KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.SIZE

	; end of the entries?
	dec	rcx
	jnz	.search	; no

	; flag, critical error
	stc

	; end of the procedure handling
	jmp	.end

.found:
	; preserve the pointer to the table record object
	push	rsi

	; move the remaining object list entries to the previous position
	mov	rsi,	rdi
	add	rsi,	KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.SIZE

.loop:
	; end of the entries on the object list?
	dec	rcx
	jz	.last	; yes

	; does the entry point to the arbiter object?
	mov	rax,	qword [rsi]
	test	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_arbiter
	jnz	.last	; yes

	; move the entry to the previous position
	movsq

	; end of the object list entries?
	dec	rcx
	jnz	.loop	; no

.last:
	; put the object pointer into the entry at the last position (or before the arbiter)
	pop	qword [rdi]

.end:
	; restore the original time of the last modification of the object list
	pop	qword [rel kernel_wm_object_list_modify_time]

	; release access to modifying the object list
	mov	byte [rel kernel_wm_object_semaphore],	STATIC_FALSE

	; restore the original register
	pop	rsi
	pop	rdi
	pop	rcx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"kernel_wm_object_up"

;===============================================================================
; input:
;	rsi - pointer to the object table record
kernel_wm_object_remove:
	; preserve the original registers
	push	rcx
	push	rsi
	push	rdi

	; lock access to modifying the object list
	macro_lock	kernel_wm_object_semaphore,	0

	; look for the pointer in the object list entry
	mov	rcx,	qword [rel kernel_wm_object_list_length]
	mov	rdi,	qword [rel kernel_wm_object_list_address]

.search:
	; entry found?
	cmp	rsi,	qword [rdi + KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.object_address]
	je	.found	; yes

	; move the pointer to the next entry of the object list
	add	rdi,	KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.SIZE

	; end of the entry list?
	dec	rcx
	jnz	.search	; no

	; flag, error
	stc

	; end of the procedure handling
	jmp	.end

.found:
	; set the source and destination pointers
	mov	rsi,	rdi
	add	rsi,	KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.SIZE

	; shift all remaining entries one position back
	rep	movsq

.end:
	; number of records on the list
	dec	qword [rel kernel_wm_object_list_length]

	; preserve the time of the last modification of the list
	mov	rcx,	qword [rel driver_rtc_microtime]
	mov	qword [rel kernel_wm_object_list_modify_time],	rcx

	; release access to modifying the object list
	mov	byte [rel kernel_wm_object_semaphore],	STATIC_FALSE

	; restore the original registers
	pop	rdi
	pop	rsi
	pop	rcx

	; return from the procedure
	ret

	macro_debug	"kernel_wm_object_remove"

;===============================================================================
; input:
;	r14 - delta of the X axis
;	r15 - delta of the Y axis
kernel_wm_object_move:
	; preserve the original registers
	push	rsi
	push	rdi
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15

	; set the pointer to the selected object
	mov	rsi,	qword [rel kernel_wm_object_selected_pointer]

	; fetch the pointer to the default object filling the zone
	mov	rdi,	qword [rel kernel_wm_object_table_address]

	; can the object be moved?
	test	word [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_fixed_xy
	jnz	.end	; no

	; fetch the object properties
	mov	r8w,	word [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.x]
	mov	r9w,	word [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.y]
	mov	r10w,	word [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.width]
	mov	r11w,	word [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.height]

	; set the local variables
	mov	r12w,	r8w
	mov	r13w,	r10w

	; no shift on the X axis?
	test	r14w,	r14w
	jz	.y	; yes

	; update the object position on the X axis
	add	word [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.x],	r14w

	; is the shift on the X axis positive?
	cmp	r14w,	STATIC_EMPTY
	jl	.to_left	; no

	; width of the zone
	mov	r10w,	r14w

	; register
	call	kernel_wm_zone_insert_by_register

	; correct the zone position on the X axis
	add	r8w,	r14w

.to_left:
	; is the shift on the X axis negative?
	cmp	r14w,	STATIC_EMPTY
	jnl	.x_done	; no

	; convert the shift to an absolute value
	neg	r14w

	; position and width of the zone
	add	r8w,	r10w
	sub	r8w,	r14w
	mov	r10w,	r14w

	; register
	call	kernel_wm_zone_insert_by_register

	; correct the zone position on the X axis
	mov	r8w,	r12w

.x_done:
	; correct the width of the zone
	mov	r10w,	r13w
	sub	r10w,	r14w

.y:
	; set the local variables
	mov	r12w,	r9w
	mov	r13w,	r11w

	; no shift on the X axis?
	test	r15w,	r15w
	jz	.ready	; yes

	; update the object position on the Y axis
	add	word [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.y],	r15w

	; is the shift on the Y axis positive?
	cmp	r15w,	STATIC_EMPTY
	jl	.to_up	; no

	; height of the zone
	mov	r11w,	r15w

	; register
	call	kernel_wm_zone_insert_by_register

	; correct the zone position on the Y axis
	add	r9w,	r15w

.to_up:
	; is the shift on the Y axis negative?
	cmp	r15w,	STATIC_EMPTY
	jnl	.y_done	; no

	; convert the shift to an absolute value
	neg	r15w

	; position and height of the zone
	add	r9w,	r11w
	sub	r9w,	r15w
	mov	r11w,	r15w

	; register
	call	kernel_wm_zone_insert_by_register

	; correct the zone position on the Y axis
	mov	r9w,	r12w

.y_done:
	; correct the height of the zone
	mov	r11w,	r13w
	sub	r11w,	r15w

.ready:
	; display the object content once again
	or	word [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_flush

.end:
	; restore the original registers
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	rdi
	pop	rsi

	; return from the procedure
	ret

	macro_debug	"kernel_wm_object_move"

;===============================================================================
kernel_wm_object_hide_fragile:
	; preserve the original registers
	push	rax
	push	rsi

	; set the pointer to the beginning of the object list
	mov	rsi,	qword [rel kernel_wm_object_list_address]

.loop:
	; fetch from the entry the pointer to the object table record
	lodsq

	; end of the entries?
	test	rax,	rax
	jz	.end	; yes

	; is the object VISIBLE?
	test	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_visible
	jz	.loop	; no

	; is the object FRAGILE?
	test	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_fragile
	jz	.loop	; no

	; clear the VISIBLE flag, set the UNDRAW flag
	and	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	~KERNEL_WM_OBJECT_FLAG_visible
	or	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_undraw

	; continue
	jmp	.loop

.end:
	; restore the original registers
	pop	rsi
	pop	rax

	; return from the subprocedure
	ret

	macro_debug	"kernel_wm_object_hide_fragile"

;===============================================================================
; output:
;	rcx - new identifier
kernel_wm_object_id_new:
	; lock access to the procedure
	macro_lock	kernel_wm_object_id_semaphore,	0

	; fetch the free identifier
	mov	rcx,	qword [rel kernel_wm_object_id]

	; prepare the next one
	inc	qword [rel kernel_wm_object_id]

	; release access to the procedure
	mov	byte [rel kernel_wm_object_id_semaphore],	STATIC_FALSE

	; return from the procedure
	ret

	macro_debug	"kernel_wm_object_id_new"

;===============================================================================
; input:
;	rsi - pointer to the object table record
kernel_wm_object_delete:
	; preserve the original registers
	push	rcx
	push	rdi

	; fetch the size of the object space and convert to pages
	mov	ecx,	dword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.size]
	call	library_page_from_size

	; release the object space
	mov	rdi,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.address]
	call	kernel_memory_release

	; redraw the space under the object
	mov	word [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	~KERNEL_WM_OBJECT_FLAG_visible | KERNEL_WM_OBJECT_FLAG_undraw

.wait:
	; has the space under the object been redrawn?
	test	word [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_undraw
	jnz	.wait	; no, wait

	; remove the object from the list
	call	kernel_wm_object_remove

	; restore the original registers
	pop	rdi
	pop	rcx

	; return from the procedure
	ret

	macro_debug	"kernel_wm_object_delete"
