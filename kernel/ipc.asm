KERNEL_IPC_SIZE_page_default equ 1
KERNEL_IPC_ENTRY_limit equ (KERNEL_IPC_SIZE_page_default << KERNEL_PAGE_SIZE_shift) / KERNEL_IPC_STRUCTURE_LIST.SIZE

KERNEL_IPC_TTL_default equ DRIVER_RTC_Hz / 100

struc KERNEL_IPC_STRUCTURE_LIST
 .ttl resb 8
 .pid_source resb 8
 .pid_destination resb 8
 .size resb 8
 .pointer resb 8
 .data resb 32
 .SIZE:
endstruc

kernel_ipc_semaphore db STATIC_FALSE
kernel_ipc_base_address dq STATIC_EMPTY
kernel_ipc_entry_count dw STATIC_EMPTY

kernel_ipc_insert:
 push rax
 push rdx
 push rsi
 push rdi
 push rcx

 macro_close kernel_ipc_semaphore, 0

 call kernel_task_active
 mov rdx, qword [rdi + KERNEL_STRUCTURE_TASK.pid]

 mov rdi, qword [kernel_ipc_base_address]

.reload:
 mov ecx, KERNEL_IPC_ENTRY_limit

.search:
 mov rax, qword [driver_rtc_microtime]
 cmp qword [rdi + KERNEL_IPC_STRUCTURE_LIST.ttl], rax
 jb .found

 cmp qword [rdi + KERNEL_IPC_STRUCTURE_LIST.ttl], STATIC_EMPTY
 je .found

 add rdi, KERNEL_IPC_STRUCTURE_LIST.SIZE

 dec rcx
 jnz .search

 and di, KERNEL_PAGE_mask
 mov rdi, qword [rdi + STATIC_STRUCTURE_BLOCK.link]

 jmp .reload

.found:
 add rax, KERNEL_IPC_TTL_default
 mov qword [rdi + KERNEL_IPC_STRUCTURE_LIST.ttl], rax

 mov qword [rdi + KERNEL_IPC_STRUCTURE_LIST.pid_source], rdx

 mov qword [rdi + KERNEL_IPC_STRUCTURE_LIST.pid_destination], rbx

 mov rcx, qword [rsp]
 test rcx, rcx
 jz .only_data

 mov qword [rdi + KERNEL_IPC_STRUCTURE_LIST.size], rcx
 mov qword [rdi + KERNEL_IPC_STRUCTURE_LIST.pointer], rsi

 jmp .end

.only_data:
 mov ecx, KERNEL_IPC_STRUCTURE_LIST.SIZE - KERNEL_IPC_STRUCTURE_LIST.data
 add rdi, KERNEL_IPC_STRUCTURE_LIST.data
 rep movsb

.end:
 inc qword [kernel_ipc_entry_count]

 mov byte [kernel_ipc_semaphore], STATIC_FALSE

 pop rcx
 pop rdi
 pop rsi
 pop rdx
 pop rax

 ret

 macro_debug "kernel_ipc_insert"

kernel_ipc_receive:
 push rax
 push rdi
 push rsi
 push rcx

 call kernel_task_active
 mov rax, qword [rdi + KERNEL_STRUCTURE_TASK.pid]

 mov rsi, qword [kernel_ipc_base_address]

.reload:
 mov ecx, KERNEL_IPC_ENTRY_limit

.search:
 cmp qword [rsi + KERNEL_IPC_STRUCTURE_LIST.pid_destination], rax
 je .found

.next:
 add rsi, KERNEL_IPC_STRUCTURE_LIST.SIZE

 dec rcx
 jnz .search


 stc

 jmp .error

.found:
 mov rax, qword [driver_rtc_microtime]
 cmp qword [rsi + KERNEL_IPC_STRUCTURE_LIST.ttl], rax
 jb .next

 cmp qword [rsi + KERNEL_IPC_STRUCTURE_LIST.size], STATIC_EMPTY
 je .only_data

 mov rax, qword [rsi + KERNEL_IPC_STRUCTURE_LIST.size]
 mov qword [rsp], rax
 mov rax, qword [rsi + KERNEL_IPC_STRUCTURE_LIST.pointer]
 mov qword [rsp + STATIC_QWORD_SIZE_byte], rax

 jmp .end

.only_data:
 push rsi

 mov ecx, KERNEL_IPC_STRUCTURE_LIST.SIZE
 rep movsb

 pop rsi

.end:
 mov qword [rsi + KERNEL_IPC_STRUCTURE_LIST.ttl], STATIC_EMPTY

 dec qword [kernel_ipc_entry_count]

 clc

.error:
 pop rcx
 pop rsi
 pop rdi
 pop rax

 ret

 macro_debug "kernel_ipc_receive"
