
KERNEL_TASK_FLAG_active equ 0000000000000001b ; marks an entry ready to run
KERNEL_TASK_FLAG_closed equ 0000000000000010b ; marks an entry ready to close
KERNEL_TASK_FLAG_service equ 0000000000000100b
KERNEL_TASK_FLAG_processing equ 0000000000001000b ; marks an entry currently being processed (handled by one of the processors)
KERNEL_TASK_FLAG_secured equ 0000000000010000b ; marks an entry that is busy
KERNEL_TASK_FLAG_thread equ 0000000000100000b
KERNEL_TASK_FLAG_stream_in equ 0000000001000000b ; the input stream has been redirected or inherited
KERNEL_TASK_FLAG_stream_out equ 0000000010000000b ; the output stream has been redirected or inherited
KERNEL_TASK_FLAG_sleep equ 0000000100000000b ; the process is asleep

KERNEL_TASK_FLAG_active_bit equ 0
KERNEL_TASK_FLAG_closed_bit equ 1
KERNEL_TASK_FLAG_service_bit equ 2
KERNEL_TASK_FLAG_processing_bit equ 3
KERNEL_TASK_FLAG_secured_bit equ 4
KERNEL_TASK_FLAG_thread_bit equ 5
KERNEL_TASK_FLAG_stream_in_bit equ 6
KERNEL_TASK_FLAG_stream_out_bit equ 7
KERNEL_TASK_FLAG_sleep_bit equ 8

 struc KERNEL_TASK_STRUCTURE_ENTRY
.pid resb 8 ; process identifier
.parent resb 8 ; parent process identifier
.cpu resb 8 ; identifier of the logical processor handling the process at a given time
.time resb 8 ; process run time relative to the uptime of the kernel
.apic resb 4 ; unused processor time
.memory resb 8 ; size of the occupied RAM space in pages (excluding the page tables)
.knot resb 8 ; pointer to the knot of the process working directory
.flags resb 2 ; process state flags
.length resb 1 ; number of characters in the process name
.name:
.SIZE:
 endstruc
