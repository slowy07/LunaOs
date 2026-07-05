service_desu_object_hide:
 push rbx
 push rcx
 push rsi

 mov rcx, qword [service_desu_object_list_records]

 mov rsi, qword [service_desu_object_list_address]

.loop:
 test qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags], SERVICE_DESU_OBJECT_FLAG_visible
 jz .next 

 test qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags], SERVICE_DESU_OBJECT_FLAG_fragile
 jz .next 

 and qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags], ~SERVICE_DESU_OBJECT_FLAG_visible

 call service_desu_zone_insert_by_object

.next:
 add rsi, SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE

 dec rcx
 jnz .loop

 mov bl, STATIC_FALSE
 call service_desu_zone

.end:
 pop rsi
 pop rcx
 pop rbx

 ret

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

 cmp qword [service_desu_object_arbiter_pointer], STATIC_EMPTY
 je .no

 call kernel_task_active_pid

 cmp rax, qword [service_desu_object_privileged_pid]
 je .privileged

 mov rsi, rdi
 sub rsi, STATIC_QWORD_SIZE_byte

 add rdi, (SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE) - STATIC_QWORD_SIZE_byte

 std

.replace:
 mov ecx, (SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE) >> STATIC_DIVIDE_BY_8_shift
 rep movsq

 test qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags + STATIC_QWORD_SIZE_byte], SERVICE_DESU_OBJECT_FLAG_arbiter
 jz .replace

 cld

 mov rdi, rsi
 add rdi, STATIC_QWORD_SIZE_byte

.privileged:
 mov rsi, qword [rsp]

.no:
 mov qword [rsp], rdi

 call service_desu_object_id_get
 mov qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.id], rcx

 mov qword [rsp + STATIC_QWORD_SIZE_byte * 0x03], rcx

 test qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags], SERVICE_DESU_OBJECT_FLAG_arbiter
 jz .insert

 cmp qword [service_desu_object_arbiter_pointer], STATIC_EMPTY
 jne .insert 

 mov qword [service_desu_object_arbiter_pointer], rsi

.insert:
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

 macro_debug "service desu object insert"

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

 macro_debug "service desu object remove"

service_desu_object_lock:
 macro_lock service_desu_object_semaphore, 0

.wait:
 test byte [service_desu_object_lock_level], STATIC_EMPTY
 jnz .wait

 ret

 macro_debug "service desu object list lock"

service_desu_object_move_top:
 push rsi

 call service_desu_object_insert

 xchg rsi, qword [rsp]

 call service_desu_object_remove

 pop rsi

 sub rsi, SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE

 ret

 macro_debug "service desu object move top"

service_desu_object_flush:
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

 mov bl, STATIC_FALSE 
 call service_desu_zone

.end:
 pop rsi
 pop rbx

 ret

 macro_debug "service desu object flush"

service_desu_object_id_get:
 macro_lock service_desu_object_id_semaphore, 0

 mov rcx, qword [service_desu_object_id]

 inc qword [service_desu_object_id]

 mov byte [service_desu_object_id_semaphore], STATIC_FALSE

 ret

 macro_debug "service DESU object id get"

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
 dec rax
 cmp r8, rax
 jg .fail

 mov rax, qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.y]
 add rax, qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.height]
 dec rax
 cmp r9, rax
 jg .fail 

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

 macro_debug "service DESU object find"

service_desu_object_find_by_id:
 push rcx
 push rdi

 cmp qword [service_desu_object_list_records], STATIC_EMPTY
 je .error 

 mov rcx, qword [service_desu_object_list_records]

 mov rdi, qword [service_desu_object_list_address]

.loop:
 cmp qword [rdi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.id], rbx
 je .found 

 add rdi, SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE

 dec rcx
 jnz .loop

.error:
 stc

 jmp .end

.found:
 mov qword [rsp], rdi

.end:
 pop rdi
 pop rcx

 ret

 macro_debug "service desu object find by id"


 macro_debug "service desu object delete"
