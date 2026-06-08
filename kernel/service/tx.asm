service_tx_pid dq STATIC_EMPTY

service_tx_ipc_message:
 times KERNEL_IPC_STRUCTURE_LIST.SIZE db STATIC_EMPTY

service_tx:
 call kernel_task_active
 mov rax, qword [rdi + KERNEL_STRUCTURE_TASK.pid]

 mov qword [service_tx_pid], rax

.loop:
 mov rdi, service_tx_pid
 call kernel_ipc_receive
 jc .loop

 mov rcx, qword [rdi + KERNEL_IPC_STRUCTURE_LIST.size]
 
 test rcx, rcx
 jz .loop

 jmp .send

 mov rbx, qword [rdi + KERNEL_IPC_STRUCTURE_LIST.pid_source]
 cmp rbx, qword [service_network_pid]
 je .send

 call library_page_from_size
 mov rdi, qword [rdi + KERNEL_IPC_STRUCTURE_LIST.pointer]
 call kernel_memory_release

 jmp .loop

.send:
 mov rax, rcx
 mov rdi, qword [rdi + KERNEL_IPC_STRUCTURE_LIST.pointer]
 call driver_nic_i82540em_transfer
 
 call library_page_from_size
 call kernel_memory_release

 jmp .loop

 macro_debug "service_tx"
