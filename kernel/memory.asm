
KERNEL_MEMORY_MAP_SIZE_page		equ	0x01	; default size 4088 Bytes (~128 MiB of the describable address space)

kernel_memory_map_address		dq	STATIC_EMPTY
kernel_memory_map_address_end		dq	STATIC_EMPTY

kernel_memory_high_mask			dq	STATIC_EMPTY	; KERNEL_MEMORY_HIGH_mask
kernel_memory_real_address		dq	STATIC_EMPTY	; KERNEL_MEMORY_HIGH_REAL_address

kernel_memory_lock_semaphore		db	STATIC_FALSE

; input:
;	rcx - number of pages to mark as allocated
;	rsi - pointer to the binary memory map
kernel_memory_secure:
	; preserve the original registers
	push	rax
	push	rcx
	push	rsi

	; start blocking the pages from the beginning of the binary memory map
	mov	rax,	STATIC_MAX_unsigned

.loop:
	; block access to the first page of the "set"
	inc	rax
	btr	qword [rsi],	rax

	; block the remaining pages?
	dec	rcx
	jnz	.loop	; yes

	; restore the original registers
	pop	rsi
	pop	rcx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"kernel_memory_secure"

; input:
;	rbp - number of pages reserved for use
; output:
;	CF flag, if none is available
;	rax - error code, if the CF flag is raised
;	rdi - pointer to the allocated area
;	rbp - number of the remaining reserved pages
kernel_memory_alloc_page:
	; preserve the original registers
	push	rcx

	; allocate an area of one page in size
	mov	ecx,	0x01
	call	kernel_memory_alloc

	; restore the original registers
	pop	rcx

	; return from the procedure
	ret

	macro_debug	"kernel_memory_alloc_page"

; input:
;	rcx - size of the area in pages
;	rbp - number of pages reserved for use
; output:
;	CF flag, if none is available
;	rax - error code, if the CF flag is raised
;	rdi - pointer to the allocated area
;	rbp - number of the remaining reserved pages
kernel_memory_alloc:
	; preserve the original registers
	push	rbx
	push	rdx
	push	rsi
	push	rax
	push	rcx

	; reset the bit number of the first page of the searched area
	mov	rax,	STATIC_MAX_unsigned

	; fetch the number of the pages described in the binary memory map
	mov	rcx,	qword [rel kernel_page_total_count]

	; search the binary memory map from the beginning
	mov	rsi,	qword [rel kernel_memory_map_address]

.reload:
	;	number of the pages belonging to the considered area
	xor	edx,	edx

.search:
	; check the next page
	inc	rax

	;	end of the binary memory map?
	cmp	rax,	rcx
	je	.error	;	yes

	;	a free page found?
	bt	qword [rsi],	rax
	jnc	.search	;	no

	;	save the bit number of the first page belonging to the searched area
	mov	rbx,	rax

.check:
	; check the next page
	inc	rax

	; count the current page into the searched area
	inc	rdx

	;	the full size of the area has been found
	cmp	rdx,	qword [rsp]
	je	.found	;	yes

	;	end of the binary memory map?
	cmp	rax,	rcx
	je	.error	;	yes

	;	next page belonging to the searched area?
	bt	qword [rsi],	rax
	jc	.check	;	yes

	;	the considered area is incomplete, find the next one
	jmp	.reload

.error:
	;	return the error code
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	KERNEL_ERROR_memory_low

	;	flag, error
	stc

	;	end of the procedure
	jmp	.end

.found:
	;	set the page number of the first page of the area to block
	mov	rax,	rbx

.lock:
	;	release the following pages belonging to the found area
	btr	qword [rsi],	rax

	;	use a reserved page?
	test	rbp,	rbp
	jz	.next	;	no

	;	the number of the reserved pages decreased
	dec	rbp
	dec	dword [rel kernel_page_reserved_count]

	; a reserved page was used
	jmp	.reserved

.next:
	; the number of the available pages decreased
	dec	qword [rel kernel_page_free_count]

.reserved:
	;	next page
	inc	rax

	;	end of the area processing?
	dec	rdx
	jnz	.lock	;	no, continue

	;	convert the page number of the first page of the area into a RELATIVE address
	mov	rdi,	rbx
	shl	rdi,	STATIC_MULTIPLE_BY_PAGE_shift

	;	correct it by the start address of the area described by the binary memory map
	add	rdi,	KERNEL_BASE_address

.end:
	;	release the access to the binary memory map
	mov	byte [rel kernel_memory_lock_semaphore],	STATIC_FALSE

	; restore the original registers
	pop	rcx
	pop	rax
	pop	rsi
	pop	rdx
	pop	rbx

	; return from the procedure
	ret

	macro_debug	"kernel_memory_alloc"

kernel_memory_lock:
	;	block the access to the binary memory map
	macro_lock	kernel_memory_lock_semaphore, 0

	; return from the procedure
	ret

	macro_debug	"kernel_memory_lock"

; input:
;	rdi - address of the page to release
kernel_memory_release_page:
	; preserve the original registers and flags
	push	rax
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	;	fetch the address of the beginning of the binary memory map
	mov	rsi,	qword [rel kernel_memory_map_address]

	;	convert the page address into a bit number
	mov	rax,	rdi
	sub	rax,	KERNEL_BASE_address
	shr	rax,	STATIC_PAGE_SIZE_shift

	;	compute the offset relative to the beginning of the binary memory map
	mov	rcx,	64
	xor	rdx,	rdx	;	clear the upper part
	div	rcx

	; shift the pointer to the "packet"
	shl	rax,	STATIC_MULTIPLE_BY_8_shift
	add	rsi,	rax

	; set the bit of the page being released
	bts	qword [rsi],	rdx

	;	we increase the number of the available pages by one
	inc	qword [rel kernel_page_free_count]

	;	task queue active?
	cmp	qword [rel kernel_task_active_list],	STATIC_EMPTY
	je	.end	;	no

	;	task queues of the logical processors filled up?
	call	kernel_task_active
	jz	.end	;	no, the kernel initialisation is still running

.end:
	; restore the original registers and flags
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"kernel_memory_release_page"

; input:
;	rcx - number of consecutive pages to release
;	rdi - pointer to the first page
kernel_memory_release:
	; preserve the original registers and flags
	push	rcx
	push	rdi

.loop:
	; release the first page
	call	kernel_memory_release_page

	; move the pointer to the next page
	add	rdi,	STATIC_PAGE_SIZE_byte

	;	any pages left to release?
	dec	rcx
	jnz	.loop	;	yes

	; restore the original registers and flags
	pop	rdi
	pop	rcx

	; return from the procedure
	ret

	macro_debug	"kernel_memory_release"

; input:
;	rax - pointer to the beginning of the area
;	rcx - size of the area in pages
;	r11 - pointer to the PML4 table of the area
; output:
;	CF flag, if the page tables end unexpectedly
kernel_memory_release_task:
	; preserve the original registers
	push	rcx
	push	rdi
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15

	;	prepare the working environment
	call	kernel_page_convert

.pml1:
	;	end of the processing?
	test	rcx,	rcx
	jz	.end	;	yes

	;	no page registered?
	cmp	qword [r8],	STATIC_EMPTY
	je	.pml1_omit	;	yes, skip

	;	fetch the physical address of the page
	mov	rdi,	qword [r8]

	;	the page marked as virtual?
	test	di,	KERNEL_PAGE_FLAG_virtual
	jnz	.virtual	;	yes, ignore

	; release the page
	and	di,	STATIC_PAGE_mask
	call	kernel_memory_release_page

.virtual:
	; release the entry in the PML1 table
	mov	qword [r8],	STATIC_EMPTY

	;	if the draining of the area has finished
	dec	rcx
	jz	.pml2_entry	; release the empty page tables

.pml1_omit:
	;	next entry of the PML1 table of tables
	add	r8,	STATIC_QWORD_SIZE_byte
	inc	r12

	;	end of the PML1 table
	cmp	r12,	KERNEL_PAGE_RECORDS_amount
	jne	.pml1	;	no

.pml2_entry:
	;	is the current PML1 table empty?
	mov	rdi,	qword [r9]
	and	di,	STATIC_PAGE_mask
	call	kernel_page_empty
	jnz	.pml2	;	no

	; release the area of the table
	call	kernel_memory_release_page

	; the page table was released
	dec	qword [rel kernel_page_paged_count]

	;	remove the record from the PML2 table
	mov	qword [r9],	STATIC_EMPTY

.pml2:
	;	next entry in the PML2 table
	add	r9,	STATIC_QWORD_SIZE_byte
	inc	r13

	;	end of the PML2 table?
	cmp	r13,	KERNEL_PAGE_RECORDS_amount
	je	.pml3_entry	;	yes

.pml2_record:
	;	fetch the address of the PML1 table
	mov	r8,	qword [r9]

	;	no PML1 table
	test	r8,	r8
	jz	.pml2	;	yes, next record

	;	remove the flags
	xor	r8b,	r8b

	;	clear the number of the processed entries
	xor	r12,	r12

	;	continue
	jmp	.pml1

.pml3_entry:
	;	is the current PML2 table empty?
	mov	rdi,	qword [r10]
	and	di,	STATIC_PAGE_mask
	call	kernel_page_empty
	jnz	.pml3	;	no

	; release the area of the table
	call	kernel_memory_release_page

	; the page table was released
	dec	qword [rel kernel_page_paged_count]

	;	remove the record from the PML3 table
	mov	qword [r10],	STATIC_EMPTY

.pml3:
	;	next entry in the PML3 table
	add	r10,	STATIC_QWORD_SIZE_byte
	inc	r14

	;	end of the PML3 table?
	cmp	r14,	KERNEL_PAGE_RECORDS_amount
	je	.pml4_entry	;	yes

.pml3_record:
	;	fetch the address of the PML2 table
	mov	r9,	qword [r10]

	;	no PML2 table?
	test	r9,	r9
	jz	.pml3	;	yes, next record

	;	remove the flags
	xor	r9b,	r9b

	;	clear the number of the processed entries
	xor	r13,	r13

	;	continue
	jmp	.pml2_record

.pml4_entry:
	;	is the current PML3 table empty?
	mov	rdi,	qword [r11]
	and	di,	STATIC_PAGE_mask
	call	kernel_page_empty
	jnz	.pml4	;	no

	; release the area of the table
	call	kernel_memory_release_page

	; the page table was released
	dec	qword [rel kernel_page_paged_count]

	;	remove the record from the PML4 table
	mov	qword [r11],	STATIC_EMPTY

.pml4:
	;	next entry in the PML4 table
	add	r11,	STATIC_QWORD_SIZE_byte
	inc	r15

	;	end of the PML4 table?
	cmp	r15,	KERNEL_PAGE_RECORDS_amount
	je	.pml5	;	yes... and how?

	;	fetch the address of the PML3 table
	mov	r10,	qword [r11]

	;	no PML3 table?
	test	r10,	r10
	jz	.pml4	;	yes, next record

	;	remove the flags
	xor	r10b,	r10b

	;	clear the number of the processed entries
	xor	r14,	r14

	;	continue
	jmp	.pml3_record

.pml5:
	;	flag, error
	stc

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
	pop	rcx

	; return from the procedure
	ret

	macro_debug	"kernel_memory_release_task"

; input:
;	rcx % 256 = 0 - size of the area to copy in Bytes
;	rsi - source location
;	rdi - destination location
kernel_memory_copy:
	; preserve the original registers
	push	rcx
	push	rsi
	push	rdi

	;	we copy the area in packets of 256 Bytes
	shr	rcx,	STATIC_DIVIDE_BY_256_shift

.loop:
	; copy
	macro_copy

	; move the pointers to the next packet of data
	add	rsi,	256
	add	rdi,	256

	;	end of the area?
	dec	rcx
	jnz	.loop	;	no

	; restore the original registers
	pop	rdi
	pop	rsi
	pop	rcx

	; return from the procedure
	ret

	macro_debug	"kernel_memory_copy"

; input:
;	rcx - expected size of the area in pages
; output:
;	CF flag - if there is no space
;	rdi - pointer to the allocated area
kernel_memory_alloc_task:
	; preserve the original registers
	push	rax
	push	rbx
	push	r8
	push	r11

	;	reserve the given size of the area
	call	kernel_memory_alloc_task_secure
	jc	.error	;	not enough memory

	;	map the area
	mov	rax,	rdi
	mov	bx,	KERNEL_PAGE_FLAG_write | KERNEL_PAGE_FLAG_user | KERNEL_PAGE_FLAG_available
	mov	r11,	cr3
	call	kernel_page_map_logical
	jnc	.ready	;	allocated

	;	no free RAM space, unregister the area of the process
	call	kernel_memory_release_task_secured

.error:
	;	flag, error
	stc

.ready:
	; restore the original registers
	pop	r11
	pop	r8
	pop	rbx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"kernel_memory_alloc_task"

; input:
;	rcx - size of the area in pages
; output:
;	CF flag, if none is available
;	rax - error code, if the CF flag is raised
;	rdi - pointer to the allocated area
kernel_memory_alloc_task_secure:
	; preserve the original registers
	push	rbx
	push	rdx
	push	rsi
	push	rdi
	push	rax
	push	rcx

	;	bit number of the first page of the free area
	mov	rax,	STATIC_MAX_unsigned

	;	fetch the pointer to the properties of the process
	call	kernel_task_active

	;	the calling process is a service?
	test	word [rdi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_service
	jnz	.end	;	ignore the call

	;	fetch the pointer and the number of pages in the binary memory map of the process
	mov	rcx,	qword [rdi + KERNEL_TASK_STRUCTURE.map_size]
	mov	rsi,	qword [rdi + KERNEL_TASK_STRUCTURE.map]

.reload:
	;	number of the pages belonging to the considered area
	xor	edx,	edx

.search:
	; check the next page
	inc	rax

	;	end of the binary memory map?
	cmp	rax,	rcx
	je	.error	;	yes

	;	a free page found?
	bt	qword [rsi],	rax
	jnc	.search	;	no

	;	save the bit number of the first page belonging to the searched area
	mov	rbx,	rax

.check:
	; check the next page
	inc	rax

	; count the current page into the searched area
	inc	rdx

	;	the full size of the area has been found
	cmp	rdx,	qword [rsp]
	je	.found	;	yes

	;	end of the binary memory map?
	cmp	rax,	rcx
	je	.error	;	yes

	;	next page belonging to the searched area?
	bt	qword [rsi],	rax
	jc	.check	;	yes

	;	the considered area is incomplete, find the next one
	jmp	.reload

.error:
	;	return the error code
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	KERNEL_ERROR_memory_low

	;	flag, error
	stc

	;	end of the procedure
	jmp	.end

.found:
	;	set the page number of the first page of the area to block
	mov	rax,	rbx

.lock:
	;	release the following pages belonging to the found area
	btr	qword [rsi],	rax

	;	next page
	inc	rax

	;	end of the area processing?
	dec	rdx
	jnz	.lock	;	no, continue

	;	convert the page number of the first page of the area into a RELATIVE address
	shl	rbx,	STATIC_MULTIPLE_BY_PAGE_shift

	;	correct it by the start address of the area described by the binary memory map of the process
	mov	rax,	SOFTWARE_BASE_address
	add	rbx,	rax

	;	return the address to the process
	mov	qword [rsp + STATIC_QWORD_SIZE_byte * 0x02],	rbx

.end:
	; restore the original registers
	pop	rcx
	pop	rax
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rbx

	; return from the procedure
	ret

	macro_debug	"kernel_memory_alloc_task_secure"

; input:
;	rcx - size of the area in pages
;	rdi - address of the area to release
kernel_memory_release_task_secured:
	; preserve the original registers and flags
	push	rax
	push	rdx
	push	rsi
	push	rdi
	push	rcx

	;	fetch the pointer to the properties of the process
	call	kernel_task_active

	;	fetch the pointer to the binary memory map of the process
	mov	rsi,	qword [rdi + KERNEL_TASK_STRUCTURE.map]

	;	convert the page address into a bit number
	mov	rax,	-SOFTWARE_BASE_address
	add	rax,	qword [rsp + STATIC_QWORD_SIZE_byte]
	shr	rax,	STATIC_PAGE_SIZE_shift

	;	compute the offset relative to the beginning of the binary memory map
	mov	rcx,	64
	xor	rdx,	rdx	;	clear the upper part
	div	rcx

	; move the pointer to the "packet"
	shl	rax,	STATIC_MULTIPLE_BY_8_shift
	add	rsi,	rax

	;	release all the pages belonging to the area
	mov	rcx,	qword [rsp]

.loop:
	; set the bit of the page being released
	bts	qword [rsi],	rdx

	;	next page of the area
	inc	rdx

	;	end of the area?
	dec	rcx
	jnz	.loop	;	no

	; restore the original registers and flags
	pop	rcx
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"kernel_memory_release_task_secured"
