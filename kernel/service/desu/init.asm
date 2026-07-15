mov ecx, service_desu_object_cursor.end - service_desu_object_cursor.data
mov rsi, service_desu_object_cursor.data
call library_color_alpha_invert

mov rbx, qword [kernel_video_width_pixel]
mov rcx, qword [kernel_video_size_byte]
mov rdx, qword [kernel_video_height_pixel]

mov qword [service_desu_object_framebuffer + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.size], rcx
mov qword [service_desu_object_framebuffer + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.width], rbx
mov qword [service_desu_object_framebuffer + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.height], rdx

mov rdi, qword [kernel_video_base_address]

mov qword [service_desu_object_framebuffer + SERVICE_DESU_STRUCTURE_OBJECT.address], rdi

call kernel_memory_alloc_page
call kernel_page_drain
mov qword [service_desu_object_list_address], rdi

call kernel_memory_alloc_page
call kernel_page_drain
mov qword [service_desu_fill_list_address], rdi

call kernel_memory_alloc_page
call kernel_page_drain
mov qword [service_desu_zone_list_address], rdi

mov byte [service_desu_semaphore], STATIC_TRUE

.wait:
cmp qword [service_desu_object_list_records], STATIC_EMPTY
je .wait
