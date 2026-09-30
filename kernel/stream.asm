
KERNEL_STREAM_FLAG_active equ 00000001b ; the stream is in use
KERNEL_STREAM_FLAG_meta equ 00000010b ; the metadata are up to date

struc KERNEL_STREAM_STRUCTURE_ENTRY
	.address resb 8
	.data:
	.start resb 2
	.end resb 2
	.free resb 2
	.flags resb 1
	.semaphore resb 1
	.lock resb 8
	.meta resb KERNEL_STREAM_META_SIZE_byte
	.SIZE:
endstruc

kernel_stream_semaphore db STATIC_FALSE

kernel_stream_address dq STATIC_EMPTY

kernel_stream_out_default dq STATIC_EMPTY

; input:
;\tCF flag - if an error occurred
;\tbl - the stream configuration flag
;\trdi - pointer to the task in the queue
kernel_stream_set:
	; preserve the original registers
	push rsi
	push rdi

	; create the input pipe of the process
	call kernel_stream
	jc .end ; not enough memory

	; save the pointer to the input stream of the process
	mov qword [rdi + KERNEL_TASK_STRUCTURE.in], rsi

	; number of the processes using the stream
	inc qword [rsi + KERNEL_STREAM_STRUCTURE_ENTRY.lock]

	; use the same output stream as the parent?
	test bl, KERNEL_SERVICE_PROCESS_RUN_FLAG_out_default
	jz .own ; no

	; save the pointer to the process structure
	push rdi

	; fetch the identifier of the output stream of the parent
	call kernel_task_active
	mov rsi, qword [rdi + KERNEL_TASK_STRUCTURE.out]

	; restore the pointer to the process structure
	pop rdi

	; continue
	jmp .ready

.no_memory:
	; number of the processes using the input stream
	dec qword [rsi + KERNEL_STREAM_STRUCTURE_ENTRY.lock]

	; release the stream
	mov rdi, rsi
	call kernel_stream_release

	; end of the procedure handling
	jmp .end

.own:
	; prepare the output stream of the process
	call kernel_stream
	jc .no_memory ; not enough memory

	; redirect the output of the child to the input of the parent?
	test bl, KERNEL_SERVICE_PROCESS_RUN_FLAG_out_to_in_parent
	jz .ready ; no

	; release the prepared pipe
	xchg rsi, rdi
	call kernel_stream_release
	xchg rdi, rsi

	; save the pointer to the process structure
	push rdi

	; fetch the identifier of the input stream of the parent
	call kernel_task_active
	mov rsi, qword [rdi + KERNEL_TASK_STRUCTURE.in]

	; restore the pointer to the process structure
	pop rdi

.ready:
	; load the identifier of the output stream
	mov qword [rdi + KERNEL_TASK_STRUCTURE.out], rsi

	; number of the processes using the stream
	inc qword [rsi + KERNEL_STREAM_STRUCTURE_ENTRY.lock]

.end:
	; restore the original registers
	pop rdi
	pop rsi

	; return from the procedure
	ret

	macro_debug "kernel_stream_set"

; output:
;\tCF flag, if there is no space
;\trsi - identifier of the stream
kernel_stream:
	; preserve the original registers
	push rcx
	push rdi
	push rsi

	; beginning of the stream table
	mov rsi, qword [rel kernel_stream_address]

	; block the access to the modifications of the stream table
	macro_lock kernel_stream_semaphore, 0

.reload:
	; number of the streams in the table
	mov rcx, ( STATIC_PAGE_SIZE_byte / KERNEL_STREAM_STRUCTURE_ENTRY.SIZE) - 0x01

.search:
	; the stream is free?
	test qword [rsi + KERNEL_STREAM_STRUCTURE_ENTRY.flags], KERNEL_STREAM_FLAG_active
	jz .found ; yes, no processes are using it

	; move the pointer to the next stream in the table
	add rsi, KERNEL_STREAM_STRUCTURE_ENTRY.SIZE

	; end of the streams in the table?
	dec rcx
	jnz .search ; no

	; save the address of the current part of the stream table
	and si, STATIC_PAGE_mask
	mov rcx, rsi

	; fetch the address of the next part of the table
	mov rsi, qword [rsi + STATIC_STRUCTURE_BLOCK.link]

	; the complete end of the stream table?
	cmp rsi, qword [rel kernel_stream_address]
	jne .search ; no

	; prepare the extension of the table
	call kernel_memory_alloc_page
	jc .error ; no free space

	; clear the area
	call kernel_page_drain

	; attach the area to the stream table
	mov qword [rcx + STATIC_STRUCTURE_BLOCK.link], rdi

	; set the pointer to the next part of the table to the beginning
	mov qword [rdi + STATIC_STRUCTURE_BLOCK.link], rsi

	; continue in the new part of the table
	mov rsi, rdi
	jmp .reload

.error:
	; flag, no free stream found
	stc

	; end of the procedure
	jmp .end

.found:
	; prepare the area for the stream
	mov ecx, KERNEL_STREAM_SIZE_byte >> STATIC_DIVIDE_BY_PAGE_shift
	call kernel_memory_alloc
	jc .error ; no free area

	; clear the area of the stream
	call kernel_page_drain_few

	; save the address of the stream area
	mov qword [rsi + KERNEL_STREAM_STRUCTURE_ENTRY.address], rdi

	; clear the pointers of the beginning and the end of the data in the stream
	mov dword [rsi + KERNEL_STREAM_STRUCTURE_ENTRY.data], STATIC_EMPTY

	; the stream holds no data
	mov word [rsi + KERNEL_STREAM_STRUCTURE_ENTRY.free], KERNEL_STREAM_SIZE_byte

	; unblock the access to the stream
	mov byte [rsi + KERNEL_STREAM_STRUCTURE_ENTRY.semaphore], STATIC_FALSE

	; number of the processes using the stream
	mov qword [rsi + KERNEL_STREAM_STRUCTURE_ENTRY.lock], STATIC_EMPTY

	; the stream is registered
	mov byte [rsi + KERNEL_STREAM_STRUCTURE_ENTRY.flags], KERNEL_STREAM_FLAG_active

	; return the "identifier" of the stream
	mov qword [rsp], rsi

.end:
	; unblock the access to the modifications of the stream table
	mov byte [rel kernel_stream_semaphore], STATIC_FALSE

	; restore the original registers
	pop rsi
	pop rdi
	pop rcx

	; return from the procedure
	ret

	macro_debug "kernel_stream"

; input:
;\trdi - identifier of the stream
kernel_stream_release:
	; preserve the original registers
	push rdi

	; release the area of the stream
	mov rdi, qword [rdi + KERNEL_STREAM_STRUCTURE_ENTRY.address]
	call kernel_memory_release_page

	; release the entry in the stream table
	mov qword [rdi + KERNEL_STREAM_STRUCTURE_ENTRY.flags], STATIC_EMPTY

	; restore the original registers
	pop rdi

	; return from the procedure
	ret

	macro_debug "kernel_stream_release"

; input:
;\trbx - identifier of the stream
;\trcx - size of the destination buffer
;\trdi - destination pointer of the data
; output:
;\trcx - number of the transferred data
kernel_stream_receive:
	; preserve the original registers
	push rax
	push rdx
	push rsi
	push rdi
	push r8
	push rcx

	; block the access to the stream
	macro_lock rbx, KERNEL_STREAM_STRUCTURE_ENTRY.semaphore

	; is there any data in the stream?
	cmp word [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.free], KERNEL_STREAM_SIZE_byte
	je .end ; no

	; reset the accumulator
	xor al, al

	; fetch the current pointer to the beginning of the data of the stream
	movzx edx, word [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.start]

	; set the destination pointer in the area of the stream
	mov rsi, qword [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.address]

	; reset the number of the data transferred to the process
	xor r8, r8

.load:
	; fetch a value from the stream
	mov al, byte [rsi + rdx]

	; load it into the buffer of the process
	stosb

	; move the pointer to the beginning of the data of the stream to the next position
	inc dx

	; end of the area of the stream?
	cmp dx, KERNEL_STREAM_SIZE_byte
	jne .continue ; no

	; reset the pointer to the beginning of the data area of the stream
	xor dx, dx

.continue:
	; number of the data transferred into the buffer of the process
	inc r8

	; was the required number transferred?
	dec rcx
	jz .close ; yes

	; end of the data in the stream?
	cmp dx, word [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.end]
	jne .load ; no

.close:
	; save the current position of the beginning of the stream
	mov word [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.start], dx

	; return the number of the transferred data
	mov qword [rsp], r8

	; current amount of the free space in the stream
	add word [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.free], r8w

.end:
	; unblock the access to the pipe
	mov byte [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.semaphore], STATIC_FALSE

	; restore the original registers
	pop rcx
	pop r8
	pop rdi
	pop rsi
	pop rdx
	pop rax

	; return from the procedure
	ret

	macro_debug "kernel_stream_receive"

; input:
;\trbx - identifier of the pipe
;\tcx - number of the data to transfer
;\trsi - source pointer of the data
kernel_stream_insert:
	; preserve the original registers
	push rax
	push rdx
	push rsi
	push rdi
	push rcx

.retry:
	; block the access to the pipe
	macro_lock rbx, KERNEL_STREAM_STRUCTURE_ENTRY.semaphore

	; fetch the current pointer to the end of the data of the stream
	movzx edx, word [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.end]

	; set the destination pointer in the area of the stream
	mov rdi, qword [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.address]

.next:
	; is there enough free space in the stream?
	cmp cx, word [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.free]
	jbe .insert ; yes

	; unblock the access to the stream
	mov byte [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.semaphore], STATIC_FALSE

	; try once more
	jmp .retry

.insert:
	; fetch a value from the string
	lodsb

	; save it in the stream
	mov byte [rdi + rdx], al

	; move the pointer to the end of the data of the stream to the next position
	inc dx

	; end of the area of the stream?
	cmp dx, KERNEL_STREAM_SIZE_byte
	jne .continue ; no

	; set the pointer to the end of the data area of the stream to the beginning
	xor dx, dx

.continue:
	; end of the string of the data?
	dec rcx
	jnz .next ; no, continue

	; save the current pointer to the end of the data of the stream
	mov word [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.end], dx

	; remaining amount of the free space in the stream
	pop rcx
	sub word [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.free], cx

	; clear the flag: meta
	and byte [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.flags], ~KERNEL_STREAM_FLAG_meta

.end:
	; unblock the access to the pipe
	mov byte [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.semaphore], STATIC_FALSE

	; restore the original registers
	pop rdi
	pop rsi
	pop rdx
	pop rax

	; return from the procedure
	ret

	macro_debug "kernel_stream_insert"
