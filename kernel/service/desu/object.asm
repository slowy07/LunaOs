service_desu_object_insert:
 push rax
 push rcx
 push rdx
 push rdi
 push rsi

 cmp qword [service_desu_object_list_records_free], STATIC_EMPTY
 je .end

 mov rdi, qword [service_desu_object_list_address]

 mov rax, SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE
 mul qword [service_desu_object_list_records]

 add rdi, rax

 mov qword [rsp], rdi

 push rsi

 mov rcx, (SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE) >> STATIC_DIVIDE_BY_QWORD_shift
 rep movsq

 inc qword [service_desu_object_list_records]

 pop rsi

.end:
 pop rsi
 pop rdi
 pop rdx
 pop rcx
 pop rax

 ret

 macro_debug "service_desu_object_insert"

service_desu_object:
 push rbx
 push rsi

 mov rbx, qword [service_desu_object_list_records]

 mov rsi, qword [service_desu_object_list_address]

.loop:
 test qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags], SERVICE_DESU_OBJECT_FLAG_visible
 jz .next

 test qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags], SERVICE_DESU_OBJECT_FLAG_flush
 jz .next

 call service_desu_zone_insert_by_object

 and qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags], ~SERVICE_DESU_OBJECT_FLAG_flush

 or qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags], SERVICE_DESU_OBJECT_FLAG_flush

.next:
 add rsi, SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE

 dec rbx
 jnz .loop

 call service_desu_zone

.end:
 pop rsi
 pop rbx

 ret

 macro_debug "service_desu_object"

service_desu_object_id_get:
 macro_lock service_desu_object_id_semaphore, 0

 mov rcx, qword [service_desu_object_id]

 inc qword [service_desu_object_id]

 mov byte [service_desu_object_id_semaphore], STATIC_FALSE

 ret

 macro_debug "service_desu_object_id_get"

service_desu_object_find:
 push rax
 push rcx
 push rdx
 push rsi

 cmp qword [service_desu_object_list_records], STATIC_EMPTY
 je .error

 mov rcx, qword [service_desu_object_list_records]

 mov rax, SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE
 mul rcx

 mov rsi, qword [service_desu_object_list_address]
 add rsi, rax

.next:
 sub rsi, SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE

 test qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags], SERVICE_DESU_OBJECT_FLAG_visible
 jz .fail

 cmp r8, qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.x]
 jl .fail

 cmp r9, qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.y]
 jl .fail

 mov rax, qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.x]
 add rax, qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.width]
 cmp r8, rax
 jge .fail

 mov rax, qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.y]
 add rax, qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.height]
 cmp r9, rax
 jge .fail

 mov qword [rsp], rsi

 clc

 jmp .end

.fail:
 dec rcx
 jnz .next

.error:
 stc

.end:
 pop rsi
 pop rdx
 pop rcx
 pop rax

 ret

 macro_debug "service_desu_object_find"

service_desu_object_up:
 push rsi

 call service_desu_object_insert

 xchg rsi, qword [rsp]

 call service_desu_object_remove

 pop rsi

 sub rsi, SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE

 ret

 macro_debug "service_desu_object_move_top"

service_desu_object_remove:
 push rcx
 push rsi
 push rdi

 mov rdi, rsi
 add rsi, SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE

.loop:
 mov rcx, SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE
 rep movsb

 cmp qword [rdi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.width], STATIC_EMPTY
 jne .loop

 dec qword [service_desu_object_list_records]

 pop rdi
 pop rsi
 pop rcx

 ret

 macro_debug "service_desu_object_remove"

service_desu_object_move:
 push rbx
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

 mov rbx, qword [service_desu_object_list_address]
 mov rsi, qword [service_desu_object_selected_pointer]

 test qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags], SERVICE_DESU_OBJECT_FLAG_fixed_xy
 jnz .end

 mov r8, qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.x]
 mov r9, qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.y]
 mov r10, qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.width]
 mov r11, qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.height]

 mov r12, r8
 mov r13, r10

 test r14, r14
 jz .y

 add qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.x], r14

 cmp r14, STATIC_EMPTY
 jl .to_left

 mov r10, r14
 mov rdi, rbx
 call service_desu_zone_insert_by_register

 add r8, r14

.to_left:
 cmp r14, STATIC_EMPTY
 jnl .x_done

 neg r14

 add r8, r10
 sub r8, r14
 mov r10, r14

 mov rdi, rbx
 call service_desu_zone_insert_by_register

 mov r8, r12

.x_done:
 mov r10, r13
 sub r10, r14

.y:
 mov r12, r9
 mov r13, r11

 test r15, r15
 jz .ready

 add qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.y], r15

 cmp r15, STATIC_EMPTY
 jl .to_up

 mov r11, r15
 mov rdi, rbx
 call service_desu_zone_insert_by_register

 add r9, r15

.to_up:
 cmp r15, STATIC_EMPTY
 jnl .y_done

 neg r15

 add r9, r11
 sub r9, r15
 mov r11, r15
 mov rdi, rax
 call service_desu_zone_insert_by_register

 mov r9, r12

.y_done:
 mov r11, r13
 sub r11, r15

.ready:
 call service_desu_zone

 or qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags], SERVICE_DESU_OBJECT_FLAG_flush

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
 pop rbx
 pop rax

 ret

 macro_debug "service_desu_object_move"

