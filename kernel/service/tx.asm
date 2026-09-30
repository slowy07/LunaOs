
service_tx_pid dq STATIC_EMPTY

service_tx_ipc_message:
	times KERNEL_IPC_STRUCTURE.SIZE db STATIC_EMPTY

service_tx:
	; fetch own PID
	call kernel_task_active
	mov rax, qword [rdi + KERNEL_TASK_STRUCTURE.pid]

	; share own PID with the other processes
	mov qword [rel service_tx_pid], rax

.loop:
	; fetch a message
	mov rdi, service_tx_ipc_message
	call kernel_ipc_receive
	jc .loop ; none, check once again

	; fetch the packet data size
	mov rcx, qword [rdi + KERNEL_IPC_STRUCTURE.size]

	; no data?
	test rcx, rcx
	jz .loop ; yes, ignore

 	; send
 	mov rax, rcx
 	mov rdi, qword [rdi + KERNEL_IPC_STRUCTURE.pointer]
 	call driver_nic_i82540em_transfer

	; release the space
	call library_page_from_size
	call kernel_memory_release

	; return to the main loop
	jmp .loop

	macro_debug "service_tx"
