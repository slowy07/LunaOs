service_desu_fill_insert_by_register:
 push rcx
 push rdi

 mov ecx, SERVICE_DESU_FILL_LIST_limit

 mov rdi, qword [service_desu_fill_list_address]

.loop:
 cmp qword [rdi + SERVICE_DESU_STRUCTURE_FILL.object], STATIC_EMPTY
 jne .next

 mov qword [rdi + SERVICE_DESU_STRUCTURE_FILL.field + SERVICE_DESU_STRUCTURE_FIELD.x], r8
 mov qword [rdi + SERVICE_DESU_STRUCTURE_FILL.field + SERVICE_DESU_STRUCTURE_FIELD.y], r9
 mov qword [rdi + SERVICE_DESU_STRUCTURE_FILL.field + SERVICE_DESU_STRUCTURE_FIELD.width], r10
 mov qword [rdi + SERVICE_DESU_STRUCTURE_FILL.field + SERVICE_DESU_STRUCTURE_FIELD.height], r11

 mov qword [rdi + SERVICE_DESU_STRUCTURE_FILL.object], rsi

 jmp .end

.next:
 add rdi, SERVICE_DESU_STRUCTURE_FILL.SIZE

 dec rcx
 jnz .loop

 xchg bx, bx
 jmp $

.end:
 pop rdi
 pop rcx

 ret

 macro_debug "service_desu_fill_insert_by_register"

service_desu_fill_insert_by_object:
 push rax
 push rcx
 push rdi
 push rsi

 mov ecx, SERVICE_DESU_FILL_LIST_limit

.loop:
 cmp qword [rdi + SERVICE_DESU_STRUCTURE_FILL.object], STATIC_EMPTY
 jne .next

 mov rdi, qword [service_desu_fill_list_address]
 add rdi, rax

 movsq
 movsq
 movsq
 movsq

 mov rax, qword [rsp]
 mov qword [rdi], rax

 jmp .end

.next:
 add rdi, SERVICE_DESU_STRUCTURE_FILL.SIZE

 dec rcx
 jnz .loop

 xchg bx, bx
 jmp $

.end:
 pop rsi
 pop rdi
 pop rcx
 pop rax

 ret

 macro_debug "service_desu_fill_insert"

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

 mov ecx, SERVICE_DESU_FILL_LIST_limit

 mov rsi, qword [service_desu_fill_list_address]

.loop:
 cmp qword [rsi + SERVICE_DESU_STRUCTURE_FILL.object], STATIC_EMPTY
 je .next

 push rcx
 push rsi

 mov r8, qword [rsi + SERVICE_DESU_STRUCTURE_FILL.field + SERVICE_DESU_STRUCTURE_FIELD.x]
 mov r9, qword [rsi + SERVICE_DESU_STRUCTURE_FILL.field + SERVICE_DESU_STRUCTURE_FIELD.y]
 mov r10, qword [rsi + SERVICE_DESU_STRUCTURE_FILL.field + SERVICE_DESU_STRUCTURE_FIELD.width]
 mov r11, qword [rsi + SERVICE_DESU_STRUCTURE_FILL.field + SERVICE_DESU_STRUCTURE_FIELD.height]

 mov rsi, qword [rsi + SERVICE_DESU_STRUCTURE_FILL.object]

 mov r12, r10
 shl r12, KERNEL_VIDEO_DEPTH_shift

 mov r13, qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.width]
 shl r13, KERNEL_VIDEO_DEPTH_shift
 mov r14, qword [service_desu_object_framebuffer + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.width]
 shl r14, KERNEL_VIDEO_DEPTH_shift


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

.next:
 mov qword [rsi + SERVICE_DESU_STRUCTURE_FILL.object], STATIC_EMPTY

 add rsi, SERVICE_DESU_STRUCTURE_FILL.SIZE

 dec rcx
 jnz .loop

.end:
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
