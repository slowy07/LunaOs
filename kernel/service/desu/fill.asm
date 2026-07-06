service_desu_fill_insert_by_register:
 push rax
 push rdx
 push rdi

 cmp qword [service_desu_fill_list_records], SERVICE_DESU_FILL_LIST_limit
 jne .insert

 xchg bx, bx
 jmp $

.insert:
 mov rax, SERVICE_DESU_STRUCTURE_FILL.SIZE
 mul qword [service_desu_fill_list_records]

 mov rdi, qword [service_desu_fill_list_address]
 add rdi, rax

 mov qword [rdi + SERVICE_DESU_STRUCTURE_FILL.field + SERVICE_DESU_STRUCTURE_FIELD.x], r8
 mov qword [rdi + SERVICE_DESU_STRUCTURE_FILL.field + SERVICE_DESU_STRUCTURE_FIELD.y], r9
 mov qword [rdi + SERVICE_DESU_STRUCTURE_FILL.field + SERVICE_DESU_STRUCTURE_FIELD.width], r10
 mov qword [rdi + SERVICE_DESU_STRUCTURE_FILL.field + SERVICE_DESU_STRUCTURE_FIELD.height], r11

 mov qword [rdi + SERVICE_DESU_STRUCTURE_FILL.object], rsi

 inc qword [service_desu_fill_list_records]
 
 pop rdi
 pop rdx
 pop rax

 ret

 macro_debug "service_desu_fill_insert_by_register"

service_desu_fill_insert_by_object:
 push rax
 push rcx
 push rdx
 push rdi
 push rsi

 cmp qword [service_desu_fill_list_records], SERVICE_DESU_FILL_LIST_limit
 jne .insert

 xchg bx, bx
 jmp $

.insert:
 mov rax, SERVICE_DESU_STRUCTURE_FILL.SIZE
 mul qword [service_desu_fill_list_records]

 mov rdi, qword [service_desu_fill_list_address]
 add rdi, rax

 movsq
 movsq
 movsq
 movsq

 mov rax, qword [rsp]
 mov qword [rdi], rax

 inc qword [service_desu_fill_list_records]

.end:
 pop rsi
 pop rdi
 pop rdx
 pop rcx
 pop rax

 ret

 macro_debug "service desu fill insert"

service_desu_fill:
 push rax
 push rcx
 push rdx
 push rsi
 push rdi
 push r8
 push r9
 push r10
 push r11
 push r12
 push r13
 push r14
 push r15

 mov rcx, qword [service_desu_fill_list_records]

 test rcx, rcx
 jz .end

 mov rsi, qword [service_desu_fill_list_address]

.loop:
 push rcx
 push rsi

 mov r8, qword [rsi + SERVICE_DESU_STRUCTURE_FILL.field + SERVICE_DESU_STRUCTURE_FIELD.x]
 mov r9, qword [rsi + SERVICE_DESU_STRUCTURE_FILL.field + SERVICE_DESU_STRUCTURE_FIELD.y]
 mov r10, qword [rsi + SERVICE_DESU_STRUCTURE_FILL.field + SERVICE_DESU_STRUCTURE_FIELD.width]
 mov r11, qword [rsi + SERVICE_DESU_STRUCTURE_FILL.field + SERVICE_DESU_STRUCTURE_FIELD.height]

.left:
 bt r8, STATIC_WORD_BIT_sign
 jnc .top

 add r10, r8

 xor r8, r8

.top:
 bt r9, STATIC_WORD_BIT_sign
 jnc .right

 add r11, r9

 xor r9, r9

.right:
 mov rax, r8
 add rax, r10
 cmp rax, qword [kernel_video_width_pixel]
 jb .down

 sub rax, qword [kernel_video_width_pixel]
 sub r10, rax

.down:
 mov rax, r9
 add rax, r11
 cmp rax, qword [kernel_video_height_pixel]
 jb .ready

 sub rax, qword [kernel_video_height_pixel]
 sub r11, rax

.ready:
 mov rsi, qword [rsi + SERVICE_DESU_STRUCTURE_FILL.object]

 mov r12, r10
 shl r12, KERNEL_VIDEO_DEPTH_shift

 mov r13, qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.width]
 shl r13, KERNEL_VIDEO_DEPTH_shift

 mov r14, qword [kernel_video_scanline_byte]

 mov rax, r9
 sub rax, qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.y]
 mul qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.width]
 shl rax, KERNEL_VIDEO_DEPTH_shift
 mov r15, rax

 mov rax, r8
 sub rax, qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.x]
 shl rax, KERNEL_VIDEO_DEPTH_shift
 add r15, rax
 add r15, qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.address]

 mov rax, r9
 mul qword [kernel_video_scanline_byte]
 mov rdi, rax
 shl r8, KERNEL_VIDEO_DEPTH_shift
 add rdi, r8
 add rdi, qword [service_desu_object_framebuffer + SERVICE_DESU_STRUCTURE_OBJECT.address]

 mov rsi, r15

.row:
 mov rcx, r10

.print:
 cmp byte [rsi + 0x03], STATIC_MAX_unsigned
 je .transparent_max

 movsd

 jmp .continue

.transparent_max:
 add rsi, STATIC_DWORD_SIZE_byte
 add rdi, STATIC_DWORD_SIZE_byte

.continue:
 dec rcx
 jnz .print

 sub rdi, r12
 add rdi, r14
 sub rsi, r12
 add rsi, r13

 dec r11
 jnz .row

 or qword [service_desu_object_framebuffer + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags], SERVICE_DESU_OBJECT_FLAG_flush

.leave:
 pop rsi
 pop rcx

 add rsi, SERVICE_DESU_STRUCTURE_OBJECT.SIZE

 dec rcx
 jnz .loop

.end:
 mov qword [service_desu_fill_list_records], STATIC_EMPTY

 pop r15
 pop r14
 pop r13
 pop r12
 pop r11
 pop r10
 pop r9
 pop r8
 pop rdi
 pop rsi
 pop rdx
 pop rcx
 pop rax

 ret

 macro_debug "service_desu_fill"
