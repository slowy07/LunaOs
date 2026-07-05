service_desu_cursor_flush:
 push rax
 push rsi

 test qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags], SERVICE_DESU_OBJECT_FLAG_flush
 jz .no

 mov rax, service_desu_object_cursor
 xchg rax, qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.address]

 mov rsi, service_desu_object_cursor
 call service_desu_fill_register

 xchg rax, qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.address]

 call service_desu_fill

 and qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags], ~SERVICE_DESU_OBJECT_FLAG_flush

.no:
 pop rsi
 pop rax

 ret

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

 bt word [driver_ps2_mouse_state], DRIVER_PS2_DEVICE_MOUSE_PACKET_LMB_bit
 jnc .no_mouse_button_left_action

 cmp byte [service_desu_mouse_button_left_semaphore], STATIC_TRUE
 je .no_mouse_button_left_action

 mov byte [service_desu_mouse_button_left_semaphore], STATIC_TRUE

 cmp qword [service_desu_object_selected_pointer], STATIC_EMPTY
 jne .no_mouse_button_left_action

  call service_desu_object_find
 jc .no_mouse_button_left_action

 mov qword [service_desu_object_selected_pointer], rsi

 call service_desu_object_hide

 cmp rsi, qword [service_desu_object_list_address]
 je .privileged

 test qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags], SERVICE_DESU_OBJECT_FLAG_fixed_z
 jnz .fixed_z

 mov qword [service_desu_object_selected_pointer], rsi

.fixed_z:
 or qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags], SERVICE_DESU_OBJECT_FLAG_flush

 or qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags], SERVICE_DESU_OBJECT_FLAG_flush

.privileged:

.no_mouse_button_left_action:
 bt word [driver_ps2_mouse_state], DRIVER_PS2_DEVICE_MOUSE_PACKET_LMB_bit
 jc .no_mouse_button_left_release

.no_mouse_button_left_action_release:
 mov byte [service_desu_mouse_button_left_semaphore], STATIC_FALSE

.no_mouse_button_left_action_release_selected:
 mov qword [service_desu_object_selected_pointer], STATIC_EMPTY

.no_mouse_button_left_release:
 bt word [driver_ps2_mouse_state], DRIVER_PS2_DEVICE_MOUSE_PACKET_RMB_bit
 jnc .no_mouse_button_right_action

 cmp byte [service_desu_mouse_button_right_semaphore], STATIC_TRUE
 je .no_mouse_button_right_action

 mov byte [service_desu_mouse_button_right_semaphore], STATIC_TRUE

  call service_desu_object_find
 jc .no_mouse_button_right_action

 call service_desu_object_hide

.no_mouse_button_right_action:
 bt word [driver_ps2_mouse_state], DRIVER_PS2_DEVICE_MOUSE_PACKET_RMB_bit
 jc .no_mouse_button_right_release

 mov byte [service_desu_mouse_button_right_semaphore], STATIC_FALSE

.no_mouse_button_right_release:
 test r10, r10
 jnz .moved
 test r11, r11
 jz .end 

.moved:
 mov bl, STATIC_FALSE
 mov rsi, service_desu_object_cursor
 call service_desu_zone_insert_by_object
 call service_desu_zone

 mov qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.x], r8
 mov qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.y], r9

 or qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags], SERVICE_DESU_OBJECT_FLAG_flush

 cmp byte [service_desu_mouse_button_left_semaphore], STATIC_FALSE
 je .end

 cmp qword [service_desu_object_selected_pointer], STATIC_EMPTY
 je .end

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
