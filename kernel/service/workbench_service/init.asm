service_workbench_init:
 cmp byte [service_desu_semaphore], STATIC_FALSE
 je service_workbench_init

 mov rsi, service_workbench_window_workbench

 mov rax, qword [kernel_video_width_pixel]
 mov rbx, qword [kernel_video_height_pixel]
 mov rcx, qword [kernel_video_size_byte]
 mov qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.width], rax
 mov qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.height], rbx
 mov qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.size], rcx

 call library_page_from_size
 call kernel_memory_alloc

 mov qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.address], rdi

 mov eax, SERVICE_WORKBENCH_WINDOW_WORKBENCH_BACKGROUND_color
 mov rcx, qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.size]
 shr rcx, STATIC_DIVIDE_BY_DWORD_shift
 rep stosd

 call service_desu_object_insert
