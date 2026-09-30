
kernel_gc:
	; search for a finished process
	call	kernel_gc_search

	; close all windows created by the process
	mov	rcx,	qword [rsi + KERNEL_TASK_STRUCTURE.pid]
	call	kernel_wm_object_drain

	; fetch the process input stream identifier
	mov	rdi,	qword [rsi + KERNEL_TASK_STRUCTURE.in]

	; number of processes using the stream
	dec	qword [rdi + KERNEL_STREAM_STRUCTURE_ENTRY.lock]

	; does only one process use the stream?
	cmp	qword [rdi + KERNEL_STREAM_STRUCTURE_ENTRY.lock],	STATIC_EMPTY
	jne	.stream_not_unique	; no

	; release the stream
	call	kernel_stream_release

.stream_not_unique:
	; fetch the process output stream identifier
	mov	rdi,	qword [rsi + KERNEL_TASK_STRUCTURE.out]

	; number of processes using the stream
	dec	qword [rdi + KERNEL_STREAM_STRUCTURE_ENTRY.lock]

	; does only one process use the stream?
	cmp	qword [rdi + KERNEL_STREAM_STRUCTURE_ENTRY.lock],	STATIC_EMPTY
	jne	.stream_out_unique	; no

	; release the stream
	call	kernel_stream_release

.stream_out_unique:
	; remember the address of the process PML4 table
	mov	r11,	qword [rsi + KERNEL_TASK_STRUCTURE.cr3]

	; set the pointer to the base of the process context stack space
	mov	rax,	SOFTWARE_BASE_address
	movzx	ecx,	word [rsi + KERNEL_TASK_STRUCTURE.stack]	; size of the thread context stack
	shl	rcx,	STATIC_PAGE_SIZE_shift	; convert to Bytes
	sub	rax,	rcx	; correct the pointer position

	; release the thread context stack space
	shr	rcx,	STATIC_PAGE_SIZE_shift
	call	kernel_memory_release_task

	; release the process code/data space
	mov	rax,	SOFTWARE_BASE_address
	mov	rcx,	KERNEL_PAGE_SOFTWARE_PML4_records
	call	kernel_page_purge

	; release the thread PML4 table space
	mov	rdi,	r11
	call	kernel_memory_release_page	; release the PML4 table space

	; page recovered from the paging tables
	dec	qword [rel kernel_page_paged_count]

.child:
	; find the child process or the thread of the parent
	call	kernel_task_child
	jc	.end	; no child processes/threads

	; force the process to close
	and	word [rdi + KERNEL_TASK_STRUCTURE.flags],	~KERNEL_TASK_FLAG_active
	or	word [rdi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_closed

	; find the remaining processes
	jmp	.child

.end:
	; release the entry in the task queue
	mov	word [rsi + KERNEL_TASK_STRUCTURE.flags],	STATIC_EMPTY

	; number of tasks in the queue
	dec	qword [rel kernel_task_count]

	; number of free records in the task queue
	inc	qword [rel kernel_task_free]

	; search for a new process to release
	jmp	kernel_gc

	macro_debug	"kernel_gc"

; output:
;	rsi - pointer to the found record
kernel_gc_search:
	; preserve the original registers
	push	rcx

	; search the queue from the beginning for a closed entry
	mov	rsi,	qword [rel kernel_task_address]

.restart:
	; number of entries in one data block of the task queue
	mov	rcx,	STATIC_STRUCTURE_BLOCK.link / KERNEL_TASK_STRUCTURE.SIZE

.next:
	; check the closed process flag
	test	word [rsi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_closed
	jnz	.found

	; move the pointer to the next record
	add	rsi,	KERNEL_TASK_STRUCTURE.SIZE

	; keep searching?
	dec	rcx
	jnz	.next	; yes

	; release the remaining processor time
	call	kernel_sleep

	; fetch the address of the next task queue block
	and	si,	STATIC_PAGE_mask
	mov	rsi,	qword [rsi + STATIC_STRUCTURE_BLOCK.link]

	; search the serpentine again
	jmp	.restart

.found:
	; restore the original registers
	pop	rcx

	; return from the procedure
	ret

	macro_debug	"kernel_gc_search"

kernel_gc_end:
