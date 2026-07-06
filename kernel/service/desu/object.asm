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

