kernel_service:

push rax

cmp al, KERNEL_SERVICE_PROCESS
je .process

cmp al, KERNEL_SERVICE_VIDEO
je .video

cmp al, KERNEL_SERVICE_KEYBOARD
je .keyboard

.error:

stc

.end:

pushf
pop rax

and ax, KERNEL_TASK_EFLAGS_cf | KERNEL_TASK_EFLAGS_zf

and word [rsp + KERNEL_STRUCTURE_TASK_IRETQ.eflags + STATIC_QWORD_SIZE_byte], ~KERNEL_TASK_EFLAGS_cf
and word [rsp + KERNEL_STRUCTURE_TASK_IRETQ.eflags + STATIC_QWORD_SIZE_byte], ~KERNEL_TASK_EFLAGS_zf
or word [rsp + KERNEL_STRUCTURE_TASK_IRETQ.eflags + STATIC_QWORD_SIZE_byte], ax

pop rax

iretq

.process:

cmp ax, KERNEL_SERVICE_PROCESS_exit
je kernel_task_kill

cmp ax, KERNEL_SERVICE_PROCESS_run
je .process_run

jmp kernel_service.error

.process_run:

call kernel_vfs_path_resolve
jc kernel_service.end

call kernel_vfs_file_find
jc kernel_service.end

call kernel_exec

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

.keyboard:

cmp ax, KERNEL_SERVICE_KEYBOARD_key
jne kernel_service.error

call driver_ps2_keyboard_read

mov word [rsp], ax

jmp kernel_service.end

