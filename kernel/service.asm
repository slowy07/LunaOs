kernel_service:

 push rax

 cmp al, KERNEL_SERVICE_PROCESS
 je .process

 cmp al, KERNEL_SERVICE_VIDEO
 je .video

 cmp al, KERNEL_SERVICE_KEYBOARD
 je .keyboard

 cmp al, KERNEL_SERVICE_VFS
 je .vfs

.error:

 stc

.end:

 pushf
 pop rax

 and ax, KERNEL_TASK_EFLAGS_cf | KERNEL_TASK_EFLAGS_zf

 and word [rsp + KERNEL_TASK_STRUCTURE_IRETQ.eflags + STATIC_QWORD_SIZE_byte], ~KERNEL_TASK_EFLAGS_cf
 and word [rsp + KERNEL_TASK_STRUCTURE_IRETQ.eflags + STATIC_QWORD_SIZE_byte], ~KERNEL_TASK_EFLAGS_zf
 or word [rsp + KERNEL_TASK_STRUCTURE_IRETQ.eflags + STATIC_QWORD_SIZE_byte], ax

 pop rax

 iretq

.process:

 cmp ax, KERNEL_SERVICE_PROCESS_exit
 je kernel_task_kill

 cmp ax, KERNEL_SERVICE_PROCESS_run
 je .process_run

 cmp ax, KERNEL_SERVICE_PROCESS_check
 je .process_check

 jmp kernel_service.error

.process_run:
 push rsi
 push rdi
 push rcx

 xor eax, eax
 call kernel_vfs_path_resolve
 jc .process_run_end

 call kernel_vfs_file_find
 jc .process_run_end

 call kernel_exec

 mov qword [rsp], rcx

.process_run_end:
 pop rcx
 pop rdi
 pop rsi

 mov qword [rsp], rax

 jmp kernel_service.end

.process_check:

 call kernel_task_pid_check

 jmp kernel_service.end

.video:

 cmp ax, KERNEL_SERVICE_VIDEO_string
 je .video_string

 cmp ax, KERNEL_SERVICE_VIDEO_cursor
 je .video_cursor

 cmp ax, KERNEL_SERVICE_VIDEO_char
 je .video_char

 cmp ax, KERNEL_SERVICE_VIDEO_clean
 je .video_clean

 cmp ax, KERNEL_SERVICE_VIDEO_number
 je .video_number

 jmp kernel_service.error

.video_string:

 call kernel_video_string

 jmp kernel_service.end

.video_cursor:

 mov rbx, qword [kernel_video_cursor]

 jmp kernel_service.end

.video_char:

 mov ax, dx
 call kernel_video_char

 jmp kernel_service.end

.video_clean:

 call kernel_video_drain

 jmp kernel_service.end

.video_number:

 mov rax, r8
 call kernel_video_number

 jmp kernel_service.end

.keyboard:

 cmp ax, KERNEL_SERVICE_KEYBOARD_key
 jne kernel_service.error

 call driver_ps2_keyboard_read

 mov word [rsp], ax

 jmp kernel_service.end

 macro_debug "kernel_service"

.vfs:
 cmp ax, KERNEL_SERVICE_VFS_exist
 jne kernel_service.error

 xor eax, eax

 push rcx
 push rsi
 push rdi

 call kernel_vfs_path_resolve
 je .vfs_exits_not

 call kernel_vfs_file_find

.vfs_exits_not:
 pop rdi
 pop rsi
 pop rcx

 mov qword [rsp], rax

 jmp kernel_service.end
