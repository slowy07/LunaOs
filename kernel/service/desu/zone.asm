service_desu_zone_insert_by_object:
 push rax
 push rdx
 push rsi
 push rdi
 push rsi

 macro_lock service_desu_zone_semaphore, 0

 cmp qword [service_desu_zone_list_records], SERVICE_DESU_ZONE_LIST_limit
 jb .insert

 xchg bx, bx

 jmp $

.insert:
 mov eax, SERVICE_DESU_STRUCTURE_ZONE.SIZE
 mul qword [service_desu_zone_list_records]
 
 mov rdi, qword [service_desu_zone_list_address]
 add rdi, rax

 movsq
 movsq
 movsq
 movsq

 mov rax, qword [rsp]
 mov qword [rdi], rax

 inc qword [service_desu_zone_list_records]
 
 mov byte [service_desu_zone_semaphore], STATIC_FALSE

 pop rsi
 pop rdi
 pop rdx
 pop rax

 ret

 macro_debug "service_desu_zone_insert_by_object"

service_desu_zone_insert_by_register:
 push rax
 push rdx
 push rsi
 push rdi

 macro_lock service_desu_zone_semaphore, 0

 cmp qword [service_desu_zone_list_records], SERVICE_DESU_ZONE_LIST_limit
 jb .insert

 xchg bx, bx
 jmp $

.insert:
 mov eax, SERVICE_DESU_STRUCTURE_ZONE.SIZE
 mul qword [service_desu_zone_list_records]

 mov rsi, qword [service_desu_zone_list_address]
 add rsi, rax

 mov qword [rsi + SERVICE_DESU_STRUCTURE_ZONE.field + SERVICE_DESU_STRUCTURE_FIELD.x], r8
 mov qword [rsi + SERVICE_DESU_STRUCTURE_ZONE.field + SERVICE_DESU_STRUCTURE_FIELD.y], r9
 mov qword [rsi + SERVICE_DESU_STRUCTURE_ZONE.field + SERVICE_DESU_STRUCTURE_FIELD.width], r10
 mov qword [rsi + SERVICE_DESU_STRUCTURE_ZONE.field + SERVICE_DESU_STRUCTURE_FIELD.height], r11

 mov rax, qword [rdi + SERVICE_DESU_STRUCTURE_ZONE.object]
 mov qword [rsi + SERVICE_DESU_STRUCTURE_ZONE.object], rax

 inc qword [service_desu_zone_list_records]

 mov byte [service_desu_zone_semaphore], STATIC_FALSE

 pop rdi
 pop rsi
 pop rdx
 pop rax

 ret

 macro_debug "service_desu_zone_insert_by_register"

service_desu_zone:
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

 macro_lock service_desu_object_semaphore, 0

 mov rdi, qword [service_desu_zone_list_address]

 jmp .entry

.loop:
 mov qword [rdi + SERVICE_DESU_STRUCTURE_ZONE.object], STATIC_EMPTY
 add rdi, SERVICE_DESU_STRUCTURE_ZONE.SIZE

.entry:
 cmp qword [rdi + SERVICE_DESU_STRUCTURE_ZONE.object], STATIC_EMPTY
 je .end

 mov r8, qword [rdi + SERVICE_DESU_STRUCTURE_ZONE.field + SERVICE_DESU_STRUCTURE_FIELD.x]
 mov r9, qword [rdi + SERVICE_DESU_STRUCTURE_ZONE.field + SERVICE_DESU_STRUCTURE_FIELD.y]
 mov r10, qword [rdi + SERVICE_DESU_STRUCTURE_ZONE.field + SERVICE_DESU_STRUCTURE_FIELD.width]
 add r10, r8
 mov r11, qword [rdi + SERVICE_DESU_STRUCTURE_ZONE.field + SERVICE_DESU_STRUCTURE_FIELD.height]
 add r11, r9

 cmp r8, qword [kernel_video_width_pixel]
 jge .loop
 cmp r9, qword [kernel_video_height_pixel]
 jge .loop
 cmp r10, STATIC_EMPTY
 jle .loop
 cmp r11, STATIC_EMPTY
 jle .loop

 mov eax, SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE
 mul qword [service_desu_object_list_records]

 mov rsi, qword [service_desu_object_list_address]
 add rsi, rax

.object:
 sub rsi, SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE

 cmp rsi, qword [service_desu_object_list_address]
 je .fill

 test qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags], SERVICE_DESU_OBJECT_FLAG_visible
 jz .object

 cmp rsi, qword [rdi + SERVICE_DESU_STRUCTURE_ZONE.object]
 je .fill

 mov r12, qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.x]
 mov r13, qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.y]
 mov r14, qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.width]
 add r14, r12
 mov r15, qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.height]
 add r15, r13

 cmp r12, r10
 jge .object
 cmp r13, r11
 jge .object
 cmp r14, r8
 jle .object
 cmp r15, r9
 jle .object

.left:
 cmp r8, r12
 jge .up

 push r10

 mov r10, r12
 sub r10, r8

 sub r11, r9

 call service_desu_zone_insert_by_register

 pop r10

 add r11, r9

 mov r8, r12

.up:
 cmp r9, r12
 jge .right

 sub r10, r8

 push r11

 mov r11, r13
 sub r11, r9

 call service_desu_zone_insert_by_register

 pop r11

 add r10, r8

 mov r9, r13

.right:
 cmp r10, r14
 jle .down

 sub r10, r14

 push r8

 mov r8, r14

 call service_desu_zone_insert_by_register

 pop r8

 mov r10, r14

.down:
 cmp r11, r15
 jle .cursor

 sub r11, r15

 push r9

 mov r9, r15

 call service_desu_zone_insert_by_register

 pop r9

 mov r11, r15

.cursor:
 cmp qword [rdi + SERVICE_DESU_STRUCTURE_ZONE.object], service_desu_object_cursor
 jne .loop

.fill:
 sub r10, r8
 sub r11, r9
 call service_desu_fill_insert_by_register

 jmp .loop

.end:
 mov qword [service_desu_zone_list_records], STATIC_EMPTY
 mov byte [service_desu_object_semaphore], STATIC_FALSE

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

 macro_debug "service_desu_zone"
