;===============================================================================

KERNEL_PAGE_FLAG_available		equ	1 << 0
KERNEL_PAGE_FLAG_write			equ	1 << 1
KERNEL_PAGE_FLAG_user			equ	1 << 2
KERNEL_PAGE_FLAG_write_through		equ	1 << 3
KERNEL_PAGE_FLAG_cache_disable		equ	1 << 4
KERNEL_PAGE_FLAG_length			equ	1 << 7
KERNEL_PAGE_FLAG_virtual		equ	1 << 9

KERNEL_PAGE_RECORDS_amount		equ	512

KERNEL_PAGE_PML4_SIZE_byte		equ	KERNEL_PAGE_RECORDS_amount * KERNEL_PAGE_PML3_SIZE_byte
KERNEL_PAGE_PML3_SIZE_byte		equ	KERNEL_PAGE_RECORDS_amount * KERNEL_PAGE_PML2_SIZE_byte
KERNEL_PAGE_PML2_SIZE_byte		equ	KERNEL_PAGE_RECORDS_amount * KERNEL_PAGE_PML1_SIZE_byte
KERNEL_PAGE_PML1_SIZE_byte		equ	KERNEL_PAGE_RECORDS_amount * STATIC_PAGE_SIZE_byte

KERNEL_PAGE_LIBRARY_PML4_records	equ	32
KERNEL_PAGE_SOFTWARE_PML4_records	equ	192

; bring the variable positions to a full address
align	STATIC_QWORD_SIZE_byte,		db	STATIC_NOTHING

kernel_page_pml4_address		dq	STATIC_EMPTY

kernel_page_total_count			dq	STATIC_EMPTY
kernel_page_free_count			dq	STATIC_EMPTY
kernel_page_reserved_count		dq	STATIC_EMPTY
kernel_page_paged_count			dq	STATIC_EMPTY
kernel_page_shared_count		dq	STATIC_EMPTY

;===============================================================================
; input:
;	rax - pointer to the beginning of the area
;	rcx - size of the area in pages
;	r11 - pointer to the PML4 table of the area
kernel_page_purge:
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

	; prepare the working environment
	call	kernel_page_convert

.pml1:
	; no page registered?
	cmp	qword [r8],	STATIC_EMPTY
	je	.pml1_omit	; yes, skip

	; fetch the physical address of the page
	mov	rdi,	qword [r8]

	; the page marked as virtual?
	test	di,	KERNEL_PAGE_FLAG_virtual
	jnz	.virtual	; yes, ignore

	; release the page
	and	di,	STATIC_PAGE_mask
	call	kernel_memory_release_page

.virtual:
	; release the entry in the PML1 table
	mov	qword [r8],	STATIC_EMPTY

.pml1_omit:
	; next entry of the PML1 table of tables
	add	r8,	STATIC_QWORD_SIZE_byte
	inc	r12

	; end of the PML1 table
	cmp	r12,	KERNEL_PAGE_RECORDS_amount
	jne	.pml1	; no

.pml2_entry:
	; release the area of the PML1 table
	mov	rdi,	qword [r9]
	and	di,	STATIC_PAGE_mask
	call	kernel_memory_release_page

	; the page table was released
	dec	qword [rel kernel_page_paged_count]

	; remove the record from the PML2 table
	mov	qword [r9],	STATIC_EMPTY

.pml2:
	; next entry in the PML2 table
	add	r9,	STATIC_QWORD_SIZE_byte
	inc	r13

	; end of the PML2 table?
	cmp	r13,	KERNEL_PAGE_RECORDS_amount
	je	.pml3_entry	; yes

.pml2_record:
	; fetch the address of the PML1 table
	mov	r8,	qword [r9]

	; no PML1 table
	test	r8,	r8
	jz	.pml2	; yes, next record

	; remove the flags
	xor	r8b,	r8b

	; clear the number of the processed entries
	xor	r12,	r12

	; continue
	jmp	.pml1

.pml3_entry:
	; release the area of the PML2 table
	mov	rdi,	qword [r10]
	and	di,	STATIC_PAGE_mask
	call	kernel_memory_release_page

	; the page table was released
	dec	qword [rel kernel_page_paged_count]

	; remove the record from the PML3 table
	mov	qword [r10],	STATIC_EMPTY

.pml3:
	; next entry in the PML3 table
	add	r10,	STATIC_QWORD_SIZE_byte
	inc	r14

	; end of the PML3 table?
	cmp	r14,	KERNEL_PAGE_RECORDS_amount
	je	.pml4_entry	; yes

.pml3_record:
	; fetch the address of the PML2 table
	mov	r9,	qword [r10]

	; no PML2 table?
	test	r9,	r9
	jz	.pml3	; yes, next record

	; remove the flags
	xor	r9b,	r9b

	; clear the number of the processed entries
	xor	r13,	r13

	; continue
	jmp	.pml2_record

.pml4_entry:
	; release the area of the PML3 table
	mov	rdi,	qword [r11]
	and	di,	STATIC_PAGE_mask
	call	kernel_memory_release_page

	; the page table was released
	dec	qword [rel kernel_page_paged_count]

	; remove the record from the PML4 table
	mov	qword [r11],	STATIC_EMPTY

.pml4:
	; the PML4 record was released
	dec	rcx
	jz	.end	; all the records of the PML4 table have been processed

	; next entry in the PML4 table
	add	r11,	STATIC_QWORD_SIZE_byte
	inc	r15

	; end of the PML4 table?
	cmp	r15,	KERNEL_PAGE_RECORDS_amount
	je	.pml5	; yes... and how?

	; fetch the address of the PML3 table
	mov	r10,	qword [r11]

	; no PML3 table?
	test	r10,	r10
	jz	.pml4	; yes, next record

	; remove the flags
	xor	r10b,	r10b

	; clear the number of the processed entries
	xor	r14,	r14

	; continue
	jmp	.pml3_record

.pml5:
	; flag, error
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

	macro_debug	"kernel_page_purge"

;===============================================================================
; input:
;	rax - pointer to the memory area to clear
;	rcx - number of the PML4 table records to review
;	r11 - pointer to the PML4 table
; output:
;	r8 - pointer to the record in the PML1 table
;	r9 - pointer to the record in the PML2 table
;	r10 - pointer to the record in the PML3 table
;	r11 - pointer to the record in the PML4 table
;	r12 - record number in the PML1 table
;	r13 - record number in the PML2 table
;	r14 - record number in the PML3 table
;	r15 - record number in the PML4 table
kernel_page_convert:
	; preserve the original registers
	push	rax
	push	rcx
	push	rdx

	; compute the entry number in the PML4 table from the given physical/logical address
	mov	rcx,	KERNEL_PAGE_PML3_SIZE_byte
	xor	rdx,	rdx	; clear the upper part
	div	rcx

	; save
	mov	r15,	rax

	; move the pointer in the PML4 table to the given entry
	shl	rax,	STATIC_MULTIPLE_BY_8_shift	; convert to Bytes
	add	r11,	rax

	; fetch the PML3 table pointer from the PML4 table entry
	mov	rax,	qword [r11]
	xor	al,	al	; remove the entry flags

	; save the PML3 table pointer
	mov	r10,	rax

	; compute the entry number in the PML3 table from the remaining physical/logical address
	mov	rax,	rdx	; restore the remainder of the division
	mov	rcx,	KERNEL_PAGE_PML2_SIZE_byte
	xor	rdx,	rdx	; clear the upper part
	div	rcx

	; save
	mov	r14,	rax

	; move the pointer in the PML3 table to the entry
	shl	rax,	STATIC_MULTIPLE_BY_8_shift	; convert to Bytes
	add	r10,	rax

	; fetch the address of the PML2 table from the PML3 table entry
	mov	rax,	qword [r10]
	xor	al,	al	; remove the entry flags

	; save the PML2 table pointer
	mov	r9,	rax

	; compute the entry number in the PML2 table from the remaining physical/logical address
	mov	rax,	rdx	; restore the remainder of the division
	mov	rcx,	KERNEL_PAGE_PML1_SIZE_byte
	xor	rdx,	rdx	; clear the upper part
	div	rcx

	; save
	mov	r13,	rax

	; move the pointer in the PML2 table to the entry
	shl	rax,	STATIC_MULTIPLE_BY_8_shift	; convert to Bytes
	add	r9,	rax

	; fetch the address of the PML1 table from the PML2 table entry
	mov	rax,	qword [r9]
	xor	al,	al	; remove the entry flags

	; save the PML2 table pointer
	mov	r8,	rax

	; compute the entry number in the PML1 table from the remaining physical/logical address
	mov	rax,	rdx	; restore the remainder of the division
	mov	rcx,	STATIC_PAGE_SIZE_byte
	xor	rdx,	rdx	; clear the upper part
	div	rcx

	; save
	mov	r12,	rax

	; move the pointer in the PML1 table to the entry
	shl	rax,	STATIC_MULTIPLE_BY_8_shift	; convert to Bytes
	add	r8,	rax

	; restore the original registers
	pop	rdx
	pop	rcx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"kernel_page_convert"

;===============================================================================
; input:
;	rdi - pointer to the page
; output:
;	ZF flag - if empty
kernel_page_empty:
	; preserve the original registers
	push	rax
	push	rcx

	; clear the accumulator
	xor	eax,	eax

	; number of the records to check
	mov	ecx,	KERNEL_PAGE_RECORDS_amount - 0x01

.loop:
	; fetch the content of the record
	or	rax,	qword [rdi + rcx * STATIC_QWORD_SIZE_byte]

	; end of the counting?
	dec	cx
	jns	.loop	; no

	; the page empty?
	test	rax,	rax

	; restore the original registers
	pop	rcx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"kernel_page_empty"

;===============================================================================
; input:
;	rdi - address of the page to clear
kernel_page_drain:
	; preserve the original registers
	push	rcx

	; size of the page in Bytes
	mov	rcx,	STATIC_PAGE_SIZE_byte
	call	.proceed

	; restore the original registers
	pop	rcx

	; return from the procedure
	ret

	macro_debug	"kernel_page_drain"

; notes:
;	rcx - destroyed
.proceed:
	; preserve the original registers
	push	rax
	push	rdi

	; clear the area
	xor	rax,	rax
	shr	rcx,	STATIC_DIVIDE_BY_8_shift	; 8 Bytes at a time
	and	di,	STATIC_PAGE_mask	; move the area address down to the alignment boundary (failsafe)
	rep	stosq

	; restore the original registers
	pop	rdi
	pop	rax

	; return from the subprocedure
	ret

	macro_debug	"kernel_page_drain.proceed"

;===============================================================================
; input:
;	rcx - number of consecutive pages to clear
;	rdi - pointer to the first page
kernel_page_drain_few:
	; preserve the original registers
	push	rcx

	; compute the size of the area to clear
	shl	rcx,	STATIC_PAGE_SIZE_shift
	call	kernel_page_drain.proceed

	; restore the original registers
	pop	rcx

	; return from the procedure
	ret

	macro_debug	"kernel_page_drain_few"

;===============================================================================
; input:
;	rax - address of the physical area to describe in the page tables
;	bx - flags of the page table records
;	rcx - size of the area in pages to describe
;	r11 - physical address of the PML4 table in which to make the entry
; output:
;	CF flag - set, if an error occurred
;	r8 - address of the entry describing the first page of the area
; notes:
;	reserve the appropriate number of pages, rbp
kernel_page_map_physical:
	; preserve the original registers
	push	rcx
	push	rdx
	push	rdi
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15
	push	rax

	; prepare the base path to the mapped area
	call	kernel_page_prepare
	jc	.error	; error, no free memory or the page table overflowed

	; attach to the beginning of the described area, the properties
	or	ax,	bx

.row:
	; check whether the records in the PML1 table have run out
	cmp	r12,	KERNEL_PAGE_RECORDS_amount
	jb	.exist	; no

	; create a new PML1 page table
	call	kernel_page_pml1

.exist:
	; store the mapped address into the PML1[r12] row
	stosq

	; move the address to the next page of the mapped area
	add	rax,	STATIC_PAGE_SIZE_byte

	; set the number of the next row in the PML1 table
	inc	r12

	; next table row?
	dec	rcx
	jnz	.row	; yes

	; flag, success
	clc

	; end
	jmp	.end

.error:
	; flag, error
	stc

.end:
	; restore the original registers
	pop	rax
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	rdi
	pop	rdx
	pop	rcx

	; return from the procedure
	ret

	macro_debug	"kernel_page_map_physical"

;===============================================================================
; input:
;	rax - address of the logical area to describe in the page tables
;	bx - flags of the page table records
;	rcx - size of the area in pages to describe
;	r11 - physical address of the PML4 table in which to make the entry
; output:
;	CF flag - if set, error
;	r8 - address of the record describing the first page of the area
; notes:
;	reserve the appropriate number of pages, rbp
kernel_page_map_logical:
	; preserve the original registers
	push	rcx
	push	rdx
	push	rdi
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15
	push	rax

	; prepare the base path from the tables to the mapped address
	call	kernel_page_prepare
	jc	.error

.record:
	; check whether the records in the PML1 table have run out
	cmp	r12,	KERNEL_PAGE_RECORDS_amount
	jb	.exists	; records exist

	; create a new PML1 page table
	call	kernel_page_pml1
	jc	.error

.exists:
	; record occupied?
	cmp	qword [rdi],	STATIC_EMPTY
	je	.no

	; move the pointer to the next record
	add	rdi,	STATIC_QWORD_SIZE_byte
	jmp	.continue

.no:
	; save the address of the PML1 table record
	push	rdi

	; allocate a free page
	call	kernel_memory_alloc_page
	jc	.error

	; clear
	call	kernel_page_drain

	; set the properties of the record
	add	di,	bx

	; restore the address of the PML1 table record
	pop	rax

	; store the address of the mapped area into the PML1[r12] table record
	xchg	rdi,	rax
	stosq

.continue:
	; set the number of the next record in the PML1 table
	inc	r12

	; continue
	dec	rcx
	jnz	.record

	; end of the procedure
	jmp	.end

.error:
	; return the error code
	mov	qword [rsp],	rax

	; flag, error
	stc

.end:
	; restore the original registers
	pop	rax
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	rdi
	pop	rdx
	pop	rcx

	; return from the procedure
	ret

	macro_debug	"kernel_page_map_logical"

;===============================================================================
; input:
;	rcx - size of the area in pages to describe
;	rsi - pointer to the kernel address space
;	rdi - pointer to the process address space
;	r11 - physical address of the PML4 table in which to make the attachment
; output:
;	CF flag - if set, error
kernel_page_map_virtual:
	; preserve the original registers
	push	rax
	push	rcx
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

	; correct the address of the logical area
	mov	rax,	STATIC_EMPTY	; KERNEL_MEMORY_HIGH_mask
	sub	rdi,	rax
	mov	rax,	rdi

	; fetch the pointer to the properties of the process
	call	kernel_task_active

	; is the calling process a service?
	test	word [rdi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_service
	jnz	.end	; ignore the call

	; default page tables of the process
	mov	bx,	KERNEL_PAGE_FLAG_user | KERNEL_PAGE_FLAG_write | KERNEL_PAGE_FLAG_available

	; mark the physical pages as virtual, because they are only a "copy" shared with the process
	or	si,	bx
	or	si,	KERNEL_PAGE_FLAG_virtual

	; prepare the base path from the tables to the mapped address
	mov	r11,	qword [rdi + KERNEL_TASK_STRUCTURE.cr3]
	call	kernel_page_prepare
	jc	.error

.record:
	; check whether the records in the PML1 table have run out
	cmp	r12,	KERNEL_PAGE_RECORDS_amount
	jb	.exists	; records exist

	; create a new PML1 page table
	call	kernel_page_pml1
	jc	.error

.exists:
	; record free?
	cmp	qword [r8],	STATIC_EMPTY
	jne	.error	; the area is already occupied!

	; attach a page of the kernel address space to the process
	mov	qword [r8],	rsi

	; next page of the kernel address space
	add	rsi,	STATIC_PAGE_SIZE_byte
	add	r8,	STATIC_QWORD_SIZE_byte	; next entry in the table

	; set the number of the next record in the PML1 table
	inc	r12

	; continue
	dec	rcx
	jnz	.record

	; end of the procedure
	jmp	.end

.error:
	; flag, error
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
	pop	rsi
	pop	rcx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"kernel_page_map_virtual"

;===============================================================================
; input:
;	rax - address of the physical area to describe in the page tables
;	bx - flags of the page table records
;	r11 - physical address of the PML4 table in which to do the paging
; output:
;	CF flag, if there are not enough pages
;	rdi - pointer to the record in the PML1 table, the beginning of the described physical area
;
;	r8 - pointer to the next record in the PML1 table
;	r9 - pointer to the next record in the PML2 table
;	r10 - pointer to the next record in the PML3 table
;	r11 - pointer to the next record in the PML4 table
;	r12 - number of the next record in the PML1 table
;	r13 - number of the next record in the PML2 table
;	r14 - number of the next record in the PML3 table
;	r15 - number of the next record in the PML4 table
kernel_page_prepare:
	; preserve the original registers
	push	rcx
	push	rdx
	push	rax

	; compute the record number in the PML4 table from the given physical/logical address
	mov	rcx,	KERNEL_PAGE_PML3_SIZE_byte
	xor	rdx,	rdx	; clear the upper part
	div	rcx

	; remember the number of the PML4 table record
	mov	r15,	rax

	; move the pointer in the PML4 table to the record
	shl	rax,	STATIC_MULTIPLE_BY_8_shift	; convert to Bytes
	add	r11,	rax

	; the PML4 record holds the address of the PML3 table?
	cmp	qword [r11],	STATIC_EMPTY
	je	.no_pml3

	; fetch the address of the PML3 table from the PML4 table record
	mov	rax,	qword [r11]
	xor	al,	al	; remove the properties of the record

	; store the address of the PML3 table
	mov	r10,	rax

	; continue
	jmp	.pml3

.no_pml3:
	; fetch a reserved page to create a new table
	call	kernel_memory_alloc_page
	jc	.error

	; clear
	call	kernel_page_drain

	; store the address of the PML3 table
	mov	r10,	rdi

	; store the address of the PML3 table into the PML4 table record
	mov	qword [r11],	rdi
	or	word [r11],	bx	; set the properties of the PML4 table record

	; page used for the page tables
	inc	qword [rel kernel_page_paged_count]

.pml3:
	; set the number and the pointer of the PML4 table record to the next one
	inc	r15
	add	r11,	STATIC_QWORD_SIZE_byte

	; compute the record number in the PML4 table from the given physical/logical address
	mov	rax,	rdx	; restore the remainder of the division
	mov	rcx,	KERNEL_PAGE_PML2_SIZE_byte
	xor	rdx,	rdx	; clear the upper part
	div	rcx

	; remember the record number
	mov	r14,	rax

	; move the pointer in the PML3 table to the record
	shl	rax,	STATIC_MULTIPLE_BY_8_shift	; convert to Bytes
	add	r10,	rax

	; the PML3 record holds the address of the PML2 table?
	cmp	qword [r10],	STATIC_EMPTY
	je	.no_pml2

	; fetch the address of the PML2 table from the PML3 table record
	mov	rax,	qword [r10]
	xor	al,	al	; remove the properties of the record

	; store the address of the PML2 table
	mov	r9,	rax

	; continue
	jmp	.pml2

.no_pml2:
	; fetch a reserved page to create a new table
	call	kernel_memory_alloc_page
	jc	.error

	; clear
	call	kernel_page_drain

	; store the address of the PML2 table
	mov	r9,	rdi

	; store the address of the PML2 table into the PML3 table record
	mov	qword [r10],	rdi
	or	word [r10],	bx	; set the properties of the PML3 table record

	; page used for the page tables
	inc	qword [rel kernel_page_paged_count]

.pml2:
	; set the number and the pointer of the PML3 table record to the next one
	inc	r14
	add	r10,	STATIC_QWORD_SIZE_byte

	; compute the record number in the PML2 table from the given physical/logical address
	mov	rax,	rdx	; restore the remainder of the division
	mov	rcx,	KERNEL_PAGE_PML1_SIZE_byte
	xor	rdx,	rdx	; clear the upper part
	div	rcx

	; remember the record number
	mov	r13,	rax

	; move the pointer in the PML2 table to the record
	shl	rax,	STATIC_MULTIPLE_BY_8_shift	; convert to Bytes
	add	r9,	rax

	; the PML2 record holds the address of the PML1 table?
	cmp	qword [r9],	STATIC_EMPTY
	je	.no_pml1

	; fetch the address of the PML1 table from the PML2 table record
	mov	rax,	qword [r9]
	xor	al,	al	; remove the properties of the record

	; store the address of the PML1 table
	mov	r8,	rax

	; continue
	jmp	.pml1

.no_pml1:
	; fetch a reserved page to create a new table
	call	kernel_memory_alloc_page
	jc	.error

	; clear
	call	kernel_page_drain

	; store the address of the PML1 table
	mov	r8,	rdi

	; store the address of the PML1 table into the PML2 table record
	mov	qword [r9],	rdi
	or	word [r9],	bx	; set the properties of the PML2 table record

	; page used for the page tables
	inc	qword [rel kernel_page_paged_count]

.pml1:
	; set the number and the pointer of the PML3 table record to the next one
	inc	r13
	add	r9,	STATIC_QWORD_SIZE_byte

	; compute the record number in the PML1 table from the given physical/logical address
	mov	rax,	rdx	; restore the remainder of the division
	mov	rcx,	STATIC_PAGE_SIZE_byte
	xor	rdx,	rdx	; clear the upper part
	div	rcx

	; remember the record number
	mov	r12,	rax

	; move the pointer in the PML2 table to the record
	shl	rax,	STATIC_MULTIPLE_BY_8_shift	; convert to Bytes
	add	r8,	rax

	; return the pointer to the PML1 table record
	mov	rdi,	r8

	; end of the procedure
	jmp	.end

.error:
	; return the error code
	mov	qword [rsp],	rax

.end:
	; restore the original registers
	pop	rax
	pop	rdx
	pop	rcx

	; return from the procedure
	ret

	macro_debug	"kernel_page_prepare"

;===============================================================================
; optionally:
;	rbp - number of the reserved pages (if the procedure is to use them)
; input:
;	r8 - pointer to the current row in the PML1 table
;	r9 - pointer to the current row in the PML2 table
;	r10 - pointer to the current row in the PML3 table
;	r11 - pointer to the current row in the PML4 table
;	r12 - number of the current row in the PML1 table
;	r13 - number of the current row in the PML2 table
;	r14 - number of the current row in the PML3 table
;	r15 - number of the current row in the PML4 table
; output:
;	CF flag, if an error
;	rax - error code, if the CF flag is raised
;	rdi - pointer to the row in the PML1 table, the beginning of the described physical area
;
;	r8 - pointer to the next row in the PML1 table
;	r9 - pointer to the next row in the PML2 table
;	r10 - pointer to the next row in the PML3 table
;	r11 - pointer to the next row in the PML4 table
;	r12 - number of the next row in the PML1 table
;	r13 - number of the next row in the PML2 table
;	r14 - number of the next row in the PML3 table
;	r15 - number of the next row in the PML4 table
; notes:
;	the procedure decreases the number of the pages reserved in the binary memory map!
kernel_page_pml1:
	; check whether the PML2 table is full
	cmp	r13,	KERNEL_PAGE_RECORDS_amount
	je	.pml3	; if so, create a new PML2 table

	; check whether the next PML2 table record in the queue holds the address of the PML1 table
	cmp	qword [r9],	STATIC_EMPTY
	je	.pml2_create	; no

	; fetch the address of the PML1 table from the PML2 table record
	mov	rdi,	qword [r9]

	; end
	jmp	.pml2_continue

.pml2_create:
	; prepare the space for the PML1 table
	call	kernel_memory_alloc_page
	jc	.error

	; clear
	call	kernel_page_drain

	; set the properties of the record in the PML2 table
	or	di,	bx

	; attach the PML1 tables to the PML2[r13] table record
	mov	qword [r9],	rdi

	; page used for the page tables
	inc	qword [rel kernel_page_paged_count]

.pml2_continue:
	; remove the properties of the PML2 table record
	and	di,	STATIC_PAGE_mask

	; return the address of the first record in the PML1 table
	mov	r8,	rdi

	; reset the number of the record being processed in the PML1 table
	xor	r12,	r12

	; set the address of the next record in the PML2 table
	add	r9,	STATIC_QWORD_SIZE_byte
	inc	r13	; set the number of the next record in the PML2 table

	; return from the procedure
	ret

.pml3:
	; check whether the PML3 table is full
	cmp	r14,	KERNEL_PAGE_RECORDS_amount
	je	.pml4	; if so, create a new PML3 table

	; check whether the next PML3 table record in the queue holds the address of the PML2 table
	cmp	qword [r10],	STATIC_EMPTY
	je	.pml3_create	; no

	; fetch the address of the PML2 table from the PML3 table record
	mov	rdi,	qword [r10]

	; end
	jmp	.pml3_continue

.pml3_create:
	; prepare the space for the PML2 table
	call	kernel_memory_alloc_page
	jc	.error

	; clear
	call	kernel_page_drain

	; set the properties of the record in the PML3 table
	or	di,	bx

	; attach the PML2 tables to the PML3[r14] table record
	mov	qword [r10],	rdi

	; page used for the page tables
	inc	qword [rel kernel_page_paged_count]

.pml3_continue:
	; remove the properties of the PML3 table record
	and	di,	STATIC_PAGE_mask

	; return the address of the first record in the PML2 table
	mov	r9,	rdi

	; reset the number of the record being processed in the PML2 table
	xor	r13,	r13

	; set the address of the next record in the PML3 table
	add	r10,	STATIC_QWORD_SIZE_byte
	inc	r14	; set the number of the next record in the PML3 table

	; return to the main procedure
	jmp	kernel_page_pml1

.pml4:
	; check whether the PML4 table is full
	cmp	r15,	KERNEL_PAGE_RECORDS_amount
	je	.error	; if so, create a new PML5 table... and how?!

	; check whether the next PML4 table record in the queue holds the address of the PML3 table
	cmp	qword [r11],	STATIC_EMPTY
	je	.pml4_create	; no

	; fetch the address of the PML3 table from the PML4 table record
	mov	rdi,	qword [r11]

	; end
	jmp	.pml4_continue

.pml4_create:
	; prepare the space for the PML3 table
	call	kernel_memory_alloc_page
	jc	.error

	; clear
	call	kernel_page_drain

	; set the properties of the record in the PML4 table
	or	di,	bx

	; attach the PML3 tables to the PML4[r15] table record
	mov	qword [r11],	rdi

	; page used for the page tables
	inc	qword [rel kernel_page_paged_count]

.pml4_continue:
	; remove the properties of the PML4 table record
	and	di,	STATIC_PAGE_mask

	; return the address of the first record in the PML3 table
	mov	r10,	rdi

	; reset the number of the record being processed in the PML3 table
	xor	r14,	r14

	; set the address of the next record in the PML4 table
	add	r11,	STATIC_QWORD_SIZE_byte
	inc	r15	; set the number of the next record in the PML4 table

	; return to the subprocedure
	jmp	.pml3

.error:
	; flag, error
	stc

	; return from the procedure
	ret

	macro_debug	"kernel_page_pml1"

;===============================================================================
; input:
;	rsi - source address of the PML4 table
;	rdi - destination address of the PML4 table
; notes:
;	the procedure merges two PML4 tables (taking the "subtables" into account)
;	preserving the original records of the destination table!
kernel_page_merge:
	; preserve the original registers
	push	rbx

	; current level of the PML table
	mov	rbx,	4

.inner:
	; preserve the original registers
	push	rax
	push	rbx
	push	rcx
	push	rsi
	push	rdi

	; is the table a copy of the original?
	cmp	rdi,	rsi
	je	.copy	; yes, do not do the hard labour

	; decrease the level of the processed table
	dec	rbx

	; number of the records per table
	mov	rcx,	KERNEL_PAGE_RECORDS_amount

.loop:
	; check whether the source record exists
	cmp	qword [rsi],	STATIC_EMPTY
	je	.next	; none

	; check whether the destination record is occupied
	cmp	qword [rdi],	STATIC_EMPTY
	jne	.level	; occupied

	; fetch the entry from the source table
	mov	rax,	qword [rsi]

	; load the entry into the destination table
	mov	qword [rdi],	rax

.level:
	; no tables of another level
	test	bl,	bl
	jz	.next	; yes

	; preserve the original registers
	push	rsi
	push	rdi

	; load the address of the source and the destination table
	mov	rsi,	qword [rsi]
	mov	rdi,	qword [rdi]

	; is the table a copy of the original?
	test	rsi,	rdi
	jz	.the_same	; yes

	; remove the properties of the records
	and	si,	STATIC_PAGE_mask
	and	di,	STATIC_PAGE_mask

	; merge the content of the tables
	call	.inner

.the_same:
	; restore the original registers
	pop	rdi
	pop	rsi

.next:
	; next record of the table
	add	rsi,	STATIC_QWORD_SIZE_byte
	add	rdi,	STATIC_QWORD_SIZE_byte

	; continue
	dec	rcx
	jnz	.loop

.copy:
	; restore the original registers
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; have we processed level 4?
	cmp	rbx,	4
	jne	.return	; no

	; restore the original registers
	pop	rbx

.return:
	; return from the procedure
	ret

	macro_debug	"kernel_page_merge"

;===============================================================================
; input:
;	rcx - number of pages to reserve
; output:
;	CF flag - if there are not enough
;	rax - error code, if the CF flag is raised
kernel_page_secure:
	; preserve the original registers
	push	rax

	; block the modifications of the variables by other processes
	call	kernel_memory_lock

	; are there any available pages?
	mov	rax,	qword [rel kernel_page_free_count]
	sub	rax,	qword [rel kernel_page_reserved_count]
	jz	.error	; no

	; is there enough left?
	cmp	rax,	rcx
	jb	.error	; no

	; reserve
	sub	qword [rel kernel_page_free_count],	rcx
	add	qword [rel kernel_page_reserved_count],	rcx

	; flag, success
	clc

	; end
	jmp	.end

.error:
	; return the error code
	mov	qword [rsp],	KERNEL_ERROR_memory_low

	; flag, error
	stc

.end:
	; unblock
	mov	byte [rel kernel_memory_lock_semaphore],	STATIC_FALSE

	; restore the original registers
	pop	rax

	; return from the procedure
	ret

	macro_debug	"kernel_page_secure"
