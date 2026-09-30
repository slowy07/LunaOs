
tm_task:
	; save the original registers
	push rax
	push rcx
	push rsi
	push rdi

	; set the cursor to the first row of the process list
	mov ax, KERNEL_SERVICE_PROCESS_stream_out
	mov ecx, tm_string_first_row_position_end - tm_string_first_row_position
	mov rsi, tm_string_first_row_position
	int KERNEL_SERVICE

	; fetch the information about the running processes
	mov ax, KERNEL_SERVICE_PROCESS_list
	int KERNEL_SERVICE

	; display the running processes
	call tm_task_show

	; free the space of the running processes
	mov ax, KERNEL_SERVICE_PROCESS_memory_release
	mov rdi, rsi
	int KERNEL_SERVICE

	; restore the original registers
	pop rdi
	pop rsi
	pop rcx
	pop rax

	; return from the procedure
	ret

	macro_debug "software: tm_task"

; entry:
;	rbx - total size of the elements on the list in bytes
;	rcx - size of the list space in bytes
;	rsi - pointer to the beginning of the list space
tm_task_show:
	; save the original registers
	push rax
	push rbx
	push rcx
	push rdx
	push rsi
	push rdi
	push r8
	push r9

	; calculate the number of free rows
	movzx r8, word [tm_stream_meta + CONSOLE_STRUCTURE_STREAM_META.height]
	sub r8w, word [tm_string_first_row_position.y]
	dec r8w ; counted from zero

	; sort the element list by the %CPU column, from the smallest value
	call tm_task_sort

	; rbx - number of processes on the list
	; rsi - pointer to the list

	; save the number of processes on the list
	push rbx

	; save the pointer to the current element of the process list
	mov rdi, rsi

	; number of recognized threads
	xor r9, r9

.loop:
	; a process of the "thread" type?
	test word [rdi + KERNEL_TASK_STRUCTURE_ENTRY.flags], KERNEL_TASK_FLAG_thread
	jz .no_thread ; no

	; count the thread
	inc r9

.no_thread:
	; a process of the "service" type?
	test word [rdi + KERNEL_TASK_STRUCTURE_ENTRY.flags], KERNEL_TASK_FLAG_service
	jnz .next ; yes, skip


	; display the process PID
	mov ax, KERNEL_SERVICE_PROCESS_stream_out
	push qword [rdi + KERNEL_TASK_STRUCTURE_ENTRY.pid]
	pop qword [tm_string_number.value] ; PID
	mov byte [tm_string_number.prefix], TM_TABLE_CELL_pid_width
	mov ecx, tm_string_number_end - tm_string_number
	mov rsi, tm_string_number
	int KERNEL_SERVICE


	; fetch the APIC value of the first process on the list
	mov eax, dword [rdi + KERNEL_TASK_STRUCTURE_ENTRY.apic]

	; convert the value into a percentage without the remainder
	call tm_percent

	; display the processor load of the process
	mov qword [tm_string_number.value], rax
	mov byte [tm_string_number.prefix], TM_TABLE_CELL_cpu_width
	mov ax, KERNEL_SERVICE_PROCESS_stream_out
	int KERNEL_SERVICE


	; fetch the size of the used memory space in pages
	mov eax, dword [rdi + KERNEL_TASK_STRUCTURE_ENTRY.memory]

	; convert the value into a percentage without the remainder
	call tm_percent

	; display the processor load of the process
	mov qword [tm_string_number.value], rax
	mov byte [tm_string_number.prefix], TM_TABLE_CELL_mem_width
	mov ax, KERNEL_SERVICE_PROCESS_stream_out
	int KERNEL_SERVICE


	; fetch the current system clocks
	mov ax, KERNEL_SERVICE_SYSTEM_time
	int KERNEL_SERVICE

	; fetch the Time value of the first process on the list
	sub rax, qword [rdi + KERNEL_TASK_STRUCTURE_ENTRY.time]

	; display the value
	call tm_uptime


	; move the cursor to the "Process" column
	mov ax, KERNEL_SERVICE_PROCESS_stream_out_char
	mov ecx, 0x1
	int KERNEL_SERVICE

	; number of characters available for the process name
	movzx ecx, word [tm_stream_meta + CONSOLE_STRUCTURE_STREAM_META.width]
	sub ecx, TM_TABLE_CELL_process_x + 0x01 ; position of the "Process" column on the X axis (do not display the last character in the column)

	; is the process name greater?
	movzx eax, byte [rdi + KERNEL_TASK_STRUCTURE_ENTRY.length]
	cmp eax, ecx
	ja .yes ; yes, display the maximum possible

	; no, display as many as there are
	mov ecx, eax

.yes:
	; display the process name
	mov ax, KERNEL_SERVICE_PROCESS_stream_out
	mov rsi, rdi
	add rsi, KERNEL_TASK_STRUCTURE_ENTRY.name
	int KERNEL_SERVICE

	; are there free rows left in the table?
	dec r8
	jz .end ; no

	; move the cursor to the next row of the list
	mov ecx, tm_string_table_row_next_end - tm_string_table_row_next
	mov rsi, tm_string_table_row_next
	int KERNEL_SERVICE

.next:
	; move the pointer to the next entry
	movzx eax, byte [rdi + KERNEL_TASK_STRUCTURE_ENTRY.length]
	add rax, KERNEL_TASK_STRUCTURE_ENTRY.name
	add rdi, rax

	; end of the process list?
	dec rbx
	jnz .loop ; no

	; clear the remaining rows
	mov ax, KERNEL_SERVICE_PROCESS_stream_out
	mov ecx, tm_string_table_row_next_end - tm_string_table_row_next
	mov rsi, tm_string_table_row_next

.clear:
	; clear the remaining rows?
	dec r8
	jz .end ; no

	; move the cursor to the next empty row of the table
	int KERNEL_SERVICE

	; continue
	jmp .clear

.end:
	; display the number of running processes

	; set the cursor to the position
	mov ax, KERNEL_SERVICE_PROCESS_stream_out
	mov ecx, tm_string_tasks_position_and_color_end - tm_string_tasks_position_and_color
	mov rsi, tm_string_tasks_position_and_color
	int KERNEL_SERVICE

	; display the number of processes
	pop qword [tm_string_number.value] ; PID
	mov ecx, tm_string_number_end - tm_string_number
	mov rsi, tm_string_number
	mov byte [tm_string_number.prefix], STATIC_EMPTY
	int KERNEL_SERVICE

	; display the number of threads

	; set the cursor to the position
	mov rsi, tm_string_tasks_total
	mov ecx, tm_string_tasks_total_end - tm_string_tasks_total
	int KERNEL_SERVICE

	; display the number of threads
	mov qword [tm_string_number.value], r9
	mov ecx, tm_string_number_end - tm_string_number
	mov rsi, tm_string_number
	int KERNEL_SERVICE

	; mark as "threads"
	mov ecx, tm_string_tasks_threads_end - tm_string_tasks_threads
	mov rsi, tm_string_tasks_threads
	int KERNEL_SERVICE

	; restore the original registers
	pop r9
	pop r8
	pop rdi
	pop rsi
	pop rdx
	pop rcx
	pop rbx
	pop rax

	; return from the procedure
	ret

	macro_debug "software: tm_task_show"

; entry:
;	rbx - size of all the elements on the list in bytes
;	rsi - pointer to the list
tm_task_sort:
	; save the original registers
	push rax
	push rcx
	push rdx

.next:
	; save the number of entries on the list and the local variable
	push rbx
	push STATIC_TRUE ; the list has not been modified

	; relative position of the current element
	xor ecx, ecx

.loop:
	; end of the element list?
	dec rbx
	jz .terminated ; no

	; relative position of the next element
	movzx edx, byte [rsi + rcx + KERNEL_TASK_STRUCTURE_ENTRY.length]
	add rdx, rcx
	add rdx, KERNEL_TASK_STRUCTURE_ENTRY.name

	; is the value of element[rcx] greater than element[rdx]?
	mov rax, qword [rsi + rcx + KERNEL_TASK_STRUCTURE_ENTRY.pid]
	cmp rax, qword [rsi + rdx + KERNEL_TASK_STRUCTURE_ENTRY.pid]
	jbe .no ; no

	; swap the elements
	call tm_task_replace

	; correct the position of the next list element
	movzx edx, byte [rsi + rcx + KERNEL_TASK_STRUCTURE_ENTRY.length]
	add rdx, rcx
	add rdx, KERNEL_TASK_STRUCTURE_ENTRY.name

	; the list has been modified
	mov byte [rsp], STATIC_FALSE

.no:
	; next element from the list
	xchg rcx, rdx

	; continue the sorting
	jmp .loop

.terminated:
	; restore the local variable and the number of entries on the list
	pop rax
	pop rbx

	; is the list sorted?
	test al, al
	jnz .next ; yes

.end:
	; restore the original registers
	pop rdx
	pop rcx
	pop rax

	; return from the procedure
	ret

	macro_debug "software: tm_task_sort"

; entry:
;	rcx - index of the first element
;	rdx - index of the second element
;	rsi - pointer to the beginning of the data space
tm_task_replace:
	; save the original registers
	push rax
	push rbx
	push rcx
	push rdx
	push rsi
	push rbp
	push r8

	; remember the index of the first element
	mov r8, rcx

	; size of the first element
	movzx ebx, byte [rsi + r8 + KERNEL_TASK_STRUCTURE_ENTRY.length]
	add rbx, KERNEL_TASK_STRUCTURE_ENTRY.SIZE

	; temporary space under the first element
	sub rsp, rbx
	mov rbp, rsp

.save:
	; put the first element on the stack
	mov al, byte [rsi + rcx]
	mov byte [rbp], al

	; next element value
	inc rcx
	inc rbp

	; preserved?
	dec rbx
	jnz .save ; no

	; size of the second element
	movzx ebx, byte [rsi + rdx + KERNEL_TASK_STRUCTURE_ENTRY.length]
	add rbx, KERNEL_TASK_STRUCTURE_ENTRY.SIZE

	; return the index of the first element
	mov rcx, r8

.element_two:
	; move the second element into the place of the first one
	mov al, byte [rsi + rdx]
	mov byte [rsi + rcx], al

	; next element value
	inc rcx
	inc rdx

	; moved?
	dec rbx
	jnz .element_two

	; beginning of the temporary space
	mov rbp, rsp

	; size of the first element
	movzx ebx, byte [rsp + KERNEL_TASK_STRUCTURE_ENTRY.length]
	add rbx, KERNEL_TASK_STRUCTURE_ENTRY.SIZE

.restore:
	; restore the first element to the "position" of the second element
	mov al, byte [rbp]
	mov byte [rsi + rcx], al

	; next element value
	inc rcx
	inc rbp

	; moved?
	dec rbx
	jnz .restore ; no

	; free the temporary space
	mov rsp, rbp

	; restore the original registers
	pop r8
	pop rbp
	pop rsi
	pop rdx
	pop rcx
	pop rbx
	pop rax

	; return from the procedure
	ret

	macro_debug "software: tm_task_replace"
