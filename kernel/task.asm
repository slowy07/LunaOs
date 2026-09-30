
KERNEL_TASK_EFLAGS_if equ 000000000000001000000000b
KERNEL_TASK_EFLAGS_zf equ 000000000000000001000000b
KERNEL_TASK_EFLAGS_cf equ 000000000000000000000001b
KERNEL_TASK_EFLAGS_df equ 000000000000010000000000b
KERNEL_TASK_EFLAGS_default equ KERNEL_TASK_EFLAGS_if

KERNEL_TASK_STACK_address equ SOFTWARE_STACK_pointer - (KERNEL_TASK_STACK_SIZE_page << STATIC_MULTIPLE_BY_PAGE_shift)
KERNEL_TASK_STACK_SIZE_page equ 1

; KERNEL_TASK_STRUCTURE.SIZE % STATIC_DWORD_SIZE_byte = 0
struc KERNEL_TASK_STRUCTURE
	.cr3 resb 8 ; address of the PML4 table of the process
	.rsp resb 8 ; last known pointer to the top of the context stack of the process
	.cpu resb 8 ; identifier of the logical processor currently handling the process
	.pid resb 8 ; identifier of the process
	.parent resb 8 ; identifier of the parent process
	.time resb 8 ; start time of the process relative to the kernel lifetime
	.apic resb 4 ; unused processor time
	.memory resb 8 ; size of the taken logical area in pages (without the page tables)
	.knot resb 8 ; pointer to the spool of the working directory of the process
	.map resb 8 ; pointer to the area of the binary memory map of the process
	.map_size resb 8 ; size of the area of the binary memory map of the process in bits
	.flags resb 2 ; state flags of the process
	.in resb 8 ; stdin
	.out resb 8 ; stdout
	.stack resb 2 ; size of the context stack area in pages
	.length resb 1 ; number of characters in the process name
	.name resb 255 ; name of the process
	.SIZE:
endstruc

struc KERNEL_TASK_STRUCTURE_IRETQ
	.rip resb 8
	.cs resb 8
	.eflags resb 8
	.rsp resb 8
	.ds resb 8
endstruc

kernel_task_address dq STATIC_EMPTY
kernel_task_size_page dq KERNEL_TASK_STACK_SIZE_page
kernel_task_count dq STATIC_EMPTY
kernel_task_free dq ((KERNEL_TASK_STACK_SIZE_page << STATIC_MULTIPLE_BY_PAGE_shift) - (KERNEL_TASK_STACK_SIZE_page << STATIC_MULTIPLE_BY_QWORD_shift)) / KERNEL_TASK_STRUCTURE.SIZE
kernel_task_active_list dq STATIC_EMPTY

kernel_task_pid_semaphore db STATIC_FALSE
kernel_task_pid dq STATIC_EMPTY

kernel_task:
	; disable the interrupts and exceptions
	cli

	; save the original registers on the context stack of the process/kernel
	push rax
	push rdi

	; fetch the identifier of the logical processor
	call kernel_apic_id_get

	; save the original registers on the context stack of the process/kernel
	push rbx
	push rcx
	push rdx
	push rsi
	push rbp
	push r8
	push r9
	push r10
	push r11
	push r12
	push r13
	push r14
	push r15

	; clear the DF flag
	cld

	; compute the relative address of the entry in the list of the active tasks
	mov rbx, rax
	shl rbx, STATIC_MULTIPLE_BY_8_shift

	; fetch the pointer to the active task
	mov rsi, qword [rel kernel_task_active_list]
	mov rdi, qword [rsi + rbx]

	; save the "floating point" registers
	mov rbp, KERNEL_STACK_pointer
	FXSAVE64 [rbp]

	; save the current context stack pointer of the task in the queue
	mov qword [rdi + KERNEL_TASK_STRUCTURE.rsp], rsp

	; save the processor identifier
	push rax

	; save the address of the PML4 table of the task in the queue
	mov rax, cr3
	mov qword [rdi + KERNEL_TASK_STRUCTURE.cr3], rax

	; fetch the unused processor time
	mov rax, qword [rel kernel_apic_base_address]
	mov ecx, dword [rax + KERNEL_APIC_TCCR_register]
	mov dword [rdi + KERNEL_TASK_STRUCTURE.apic], ecx

	; remove the information about the assigned logical processor from the task
	mov qword [rdi + KERNEL_TASK_STRUCTURE.cpu], STATIC_EMPTY

	; release the task (the next logical processor will be able to start it)
	and word [rdi + KERNEL_TASK_STRUCTURE.flags], ~KERNEL_TASK_FLAG_processing

	; convert the indirect address of the task into a task number in the queue
	movzx eax, di
	and ax, ~STATIC_PAGE_mask
	mov rcx, KERNEL_TASK_STRUCTURE.SIZE
	xor edx, edx
	div rcx

	; maximum number of tasks in a queue block
	mov ecx, STATIC_STRUCTURE_BLOCK.link / KERNEL_TASK_STRUCTURE.SIZE

	; compute the number of the records up to the end of the queue block
	sub rcx, rax

	; restore the processor identifier
	pop rax

	; look for the next task to run
	jmp .next

.block:
	; load the next queue block
	and di, STATIC_PAGE_mask
	mov rdi, qword [rdi + STATIC_STRUCTURE_BLOCK.link]

.ap_entry:
	; reset the number of the tasks in the queue
	mov ecx, STATIC_STRUCTURE_BLOCK.link / KERNEL_TASK_STRUCTURE.SIZE

	; check the first task in the queue
	jmp .check

.next:
	; any tasks left in the block?
	dec ecx
	jz .block ; no

	; move the pointer to the next task
 	add rdi, KERNEL_TASK_STRUCTURE.SIZE

.check:
	; is the entry empty?
	test word [rdi + KERNEL_TASK_STRUCTURE.flags], KERNEL_TASK_FLAG_secured
	jz .next ; yes

	; is the entry already handled by another logical processor?
	lock bts word [rdi + KERNEL_TASK_STRUCTURE.flags], KERNEL_TASK_FLAG_processing_bit
	jc .next ; yes, check the next task

	; is the entry active?
	test word [rdi + KERNEL_TASK_STRUCTURE.flags], KERNEL_TASK_FLAG_active
	jnz .active ; yes

	; the process is disabled from circulation

	; release the access to the process
	and word [rdi + KERNEL_TASK_STRUCTURE.flags], ~KERNEL_TASK_FLAG_processing

	; keep looking
	jmp .next

.active:
	; save in the entry the information about the logical processor processing the task
	mov qword [rdi + KERNEL_TASK_STRUCTURE.cpu], rax

	; save the new address of the active task for the given logical processor
	mov qword [rsi + rbx], rdi

	; load the context stack pointer of the restored task and the address of the PML4 table
	mov rsp, qword [rdi + KERNEL_TASK_STRUCTURE.rsp]
	mov rax, qword [rdi + KERNEL_TASK_STRUCTURE.cr3]
	mov cr3, rax

	; restore the "floating point" registers
	mov rbp, KERNEL_STACK_pointer
	FXRSTOR64 [rbp]

	; restore the original registers of the process
	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop rbp
	pop rsi
	pop rdx
	pop rcx
	pop rbx

.leave:
	; invoke the timer interrupt after the elapse of (one time unit) etc.
	mov rdi, qword [rel kernel_apic_base_address]
	mov dword [rdi + KERNEL_APIC_TICR_register], DRIVER_RTC_Hz

	; inform the APIC that the current hardware interrupt has been handled
	mov dword [rdi + KERNEL_APIC_EOI_register], STATIC_EMPTY

	; restore the original registers of the process
	pop rdi
	pop rax

	; enable the interrupts and exceptions
	sti

	; return from the procedure
	iretq

	macro_debug "kernel_task"

; input:
;\trdi - pointer to the parent process
; output:
;\tCF flag - if there are no child processes/threads
;\trdi - pointer to the child process/thread
kernel_task_child:
	; preserve the original registers
	push rax
	push rcx
	push rdi

	; the wanted PID of the parent
	mov rax, qword [rsi + KERNEL_TASK_STRUCTURE.pid]

	; search the queue from the beginning for the child process
	mov rdi, qword [rel kernel_task_address]

.restart:
	; number of the entries in a block of the task queue data
	mov rcx, STATIC_STRUCTURE_BLOCK.link / KERNEL_TASK_STRUCTURE.SIZE

.search:
	; the child process/thread found?
	cmp qword [rdi + KERNEL_TASK_STRUCTURE.parent], rax
	jne .next ; no

	; is the process active?
	test word [rdi + KERNEL_TASK_STRUCTURE.flags], KERNEL_TASK_FLAG_active
	jz .next ; no

	; return the pointer to the child process/thread
	mov qword [rsp], rdi

	; end of the handling
	jmp .end

.next:
	; move the pointer to the next entry
	add rdi, KERNEL_TASK_STRUCTURE.SIZE

	; any entries left in the block?
	dec rcx
	jnz .search

	; fetch the address of the next queue block
	and di, STATIC_PAGE_mask
	mov rdi, qword [rdi + STATIC_STRUCTURE_BLOCK.link]

	; have we returned to the beginning of the queue?
	cmp rdi, qword [rel kernel_task_address]
	jne .restart ; no

	; flag, error
	stc

.end:
	; restore the original registers
	pop rdi
	pop rcx
	pop rax

	; return from the procedure
	ret

	macro_debug "kernel_task_child"

; input:
;\trbx - pointer to the top of the context stack of the task
;\tcl - number of characters in the process name
;\trsi - pointer to the process name
;\tr11 - address of the PML4 table of the task
; output:
;\tCF flag, if there is no free space in the queue
;\trcx - identifier of the new process
;\trdi - pointer to the task
kernel_task_add:
	; preserve the original registers
	push rax
	push rsi
	push rcx
	push rdi

	; find a free entry in the task list
	call kernel_task_queue
	jc .end

	; save the pointer to the position of the task in the queue
	push rdi

	; store the address of the PML4 table of the task
	mov qword [rdi + KERNEL_TASK_STRUCTURE.cr3], r11

	; store the prepared pointer to the top of the context stack of the task
	mov qword [rdi + KERNEL_TASK_STRUCTURE.rsp], rbx

	; fetch the working directory and the PID of the parent
	call kernel_task_active
	mov rax, qword [rdi + KERNEL_TASK_STRUCTURE.knot]
	mov rcx, qword [rdi + KERNEL_TASK_STRUCTURE.pid]

	; restore the pointer to the position of the task in the queue
	pop rdi

	; set the working directory of the process from the parent and its PID
	mov qword [rdi + KERNEL_TASK_STRUCTURE.knot], rax
	mov qword [rdi + KERNEL_TASK_STRUCTURE.parent], rcx

	; fetch a unique PID number
	call kernel_task_pid_get

	; set the PID of the task
	mov qword [rdi + KERNEL_TASK_STRUCTURE.pid], rcx

	; return the PID number to the parent process, fetch the number of characters in the process name
	xchg rcx, qword [rsp + STATIC_QWORD_SIZE_byte]

	; save in the task entry the time of its start
	mov rax, qword [rel driver_rtc_microtime]
	mov qword [rdi + KERNEL_TASK_STRUCTURE.time], rax

	; default stack size
	mov word [rdi + KERNEL_TASK_STRUCTURE.stack], KERNEL_STACK_SIZE_byte >> STATIC_DIVIDE_BY_PAGE_shift

	; return the pointer to the task
	mov qword [rsp], rdi

	; store the number of the characters representing the process name
	mov byte [rdi + KERNEL_TASK_STRUCTURE.length], cl

	; store the process name in the entry
	and ecx, STATIC_BYTE_mask
	add rdi, KERNEL_TASK_STRUCTURE.name
	rep movsb

	; flag, success
	clc

.end:
	; restore the original registers
	pop rdi
	pop rcx
	pop rsi
	pop rax

	; return from the procedure
	ret

	macro_debug "kernel_task_add"

; output:
;\tCF flag - if the queue is full
;\trdi - pointer to the free position in the task queue of the given logical processor
kernel_task_queue:
	; preserve the original registers
	push rax
	push rcx
	push rsi
	push rdi

	; search the queue from the beginning for a free record
	mov rdi, qword [rel kernel_task_address]

.restart:
	; number of the entries in a block of the task queue data
	mov rcx, STATIC_STRUCTURE_BLOCK.link / KERNEL_TASK_STRUCTURE.SIZE

.next:
	; the entry is free?
	lock bts word [rdi + KERNEL_TASK_STRUCTURE.flags], KERNEL_TASK_FLAG_secured_bit
	jnc .found ; yes

	; move the pointer to the next entry
	add rdi, KERNEL_TASK_STRUCTURE.SIZE

	; any entries left in the block?
	dec rcx
	jnz .next

	; save the pointer to the beginning of the last block of the task queue
	and di, STATIC_PAGE_mask
	mov rsi, rdi

	; fetch the address of the next queue block
	mov rdi, qword [rdi + STATIC_STRUCTURE_BLOCK.link]

	; have we returned to the beginning of the queue?
	cmp rdi, qword [rel kernel_task_address]
	jne .restart ; no

	; prepare the next block to extend the queue
	call kernel_memory_alloc_page
	jc .error

	; clear the block and attach it to the end of the queue area
	call kernel_page_drain
	mov qword [rsi + STATIC_STRUCTURE_BLOCK.link], rdi

	; link the end of the queue with the beginning
	mov rsi, qword [rel kernel_task_address]
	mov qword [rdi + STATIC_STRUCTURE_BLOCK.link], rsi

	; the size of the task queue was extended by 1 page
	inc qword [rel kernel_task_size_page]

	; block the new entry
	jmp .next

.error:
	; no free space in the queue

	; flag, error
	stc

	; end of the procedure handling
	jmp .end

.found:
	; number of the available records in the task queue
	dec qword [rel kernel_task_free]

	; number of the tasks in the queue
	inc qword [rel kernel_task_count]

	; return the address of the queue and of the free entry
	mov qword [rsp], rdi

.end:
	; restore the original registers
	pop rdi
	pop rsi
	pop rcx
	pop rax

	; return from the procedure
	ret

	macro_debug "kernel_task_queue"

; output:
;\tecx - unique identifier
kernel_task_pid_get:
	; block the access to the subprocedure
	macro_lock kernel_task_pid_semaphore, 0

.next:
	; fetch a unique PID number
	mov rcx, qword [rel kernel_task_pid]
	inc qword [rel kernel_task_pid]

	; the PID is unique?
	call kernel_task_pid_check
	jnc .next ; no, fetch the next one

	; release the access to the subprocedure
	mov byte [rel kernel_task_pid_semaphore], STATIC_FALSE

	; return from the subprocedure
	ret

	macro_debug "kernel_task_pid_get"

; input:
;\trcx - PID of the searched process
; output:
;\tCF flag - if the process does not exist
kernel_task_pid_check:
	; preserve the original registers
	push rax
	push rcx
	push rdi

	; search the queue from the beginning
	mov rdi, qword [rel kernel_task_address]

.restart:
	; number of the entries in a block of the task queue data
	mov rax, STATIC_STRUCTURE_BLOCK.link / KERNEL_TASK_STRUCTURE.SIZE

.next:
	; the wanted entry found??
	cmp qword [rdi + KERNEL_TASK_STRUCTURE.pid], rcx
	je .found ; yes

.omit:
	; move the pointer to the next entry
	add rdi, KERNEL_TASK_STRUCTURE.SIZE

	; any entries left in the block?
	dec rax
	jnz .next

	; fetch the address of the next queue block
	and di, STATIC_PAGE_mask
	mov rdi, qword [rdi + STATIC_STRUCTURE_BLOCK.link]

	; have we returned to the beginning of the queue?
	cmp rdi, qword [rel kernel_task_address]
	jne .restart ; no

.error:
	; the process is not in the queue

	; flag, error
	stc

	; end of the procedure handling
	jmp .end

.found:
	; the entry is empty?
	cmp word [rdi + KERNEL_TASK_STRUCTURE.flags], STATIC_EMPTY
	je .omit ; yes

	; is the process closed?
	bt word [rdi + KERNEL_TASK_STRUCTURE.flags], KERNEL_TASK_FLAG_closed_bit

.end:
	; restore the original registers
	pop rdi
	pop rcx
	pop rax

	; return from the procedure
	ret

	macro_debug "kernel_task_pid_check"

; output:
;\trax - PID of the active process
kernel_task_active_pid:
	; preserve the original registers
	push rdi

	; fetch the pointer to the active process
	call kernel_task_active

	; return the PID of the process
	mov rax, qword [rdi + KERNEL_TASK_STRUCTURE.pid]

	; restore the original registers
	pop rdi

	; return from the subprocedure
	ret

	macro_debug "kernel_task_active_pid"

; output:
;\tZF flag - if there is no process pointer for the logical processor
;\trdi - pointer to the task position of the logical processor
kernel_task_active:
	; preserve the original registers
	push rax

	; disable the preemption (we reserve the ID of the processor handling the procedure)
	cli

	; fetch the identifier of the logical processor
	call kernel_apic_id_get

	; set the pointer to the task position of the logical processor
	shl rax, STATIC_MULTIPLE_BY_8_shift
	mov rdi, qword [rel kernel_task_active_list]
	mov rdi, qword [rdi + rax]

	; enable the preemption
	sti

	; restore the original registers
	pop rax

	; return the state of the procedure execution
	test rdi, rdi

	; return from the procedure
	ret

	macro_debug "kernel_task_active"

kernel_task_kill:
	; fetch the pointer to the thread in the task queue
	call kernel_task_active

	; mark the thread as finished
	and word [rdi + KERNEL_TASK_STRUCTURE.flags], ~KERNEL_TASK_FLAG_active
	or word [rdi + KERNEL_TASK_STRUCTURE.flags], KERNEL_TASK_FLAG_closed

	; stop any further code execution of the thread
	jmp $

	macro_debug "kernel_task_kill"
