service_desu_cursor:
 push rax
 push rbx
 push rcx
 push rsi
 push r8
 push r9
 push r10
 push r11

 mov r8d, dword [driver_ps2_mouse_x]
 mov r9d, dword [driver_ps2_mouse_y]

 mov r10, r8
 sub r10, qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.x]

 mov r11, r9
 sub r11, qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.y]

 test r10, r10
 jnz .moved
 test r11, r11
 jz .end 

.moved:
 mov rsi, service_desu_object_cursor
 call service_desu_zone_insert_by_object
 call service_desu_zone

 mov qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.x], r8
 mov qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.y], r9

 call service_desu_fill_insert_by_object
 call service_desu_fill

.end:
 pop r11
 pop r10
 pop r9
 pop r8
 pop rsi
 pop rcx
 pop rbx
 pop rax

 ret

 macro_debug "service desu cursor"
