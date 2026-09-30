
kernel_wm_event:
 ; preserve the original registers
 push rax
 push rbx
 push rcx
 push rsi
 push r8
 push r9
 push r10
 push r11

 ; check the state of the keyboard buffer
 call kernel_wm_keyboard

 ; fetch the positions of the mouse pointer
 mov r8w, word [rel driver_ps2_mouse_x]
 mov r9w, word [rel driver_ps2_mouse_y]

 ; delta of the X axis
 mov r14w, r8w
 sub r14w, word [rel kernel_wm_object_cursor + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.x]

 ; delta of the Y axis
 mov r15w, r9w
 sub r15w, word [rel kernel_wm_object_cursor + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.y]

 ; has the left mouse button been pressed?
 bt word [rel driver_ps2_mouse_state], DRIVER_PS2_DEVICE_MOUSE_PACKET_LMB_bit
 jnc .no_mouse_button_left_action ; no

 ; was the left mouse button already pressed?
 cmp byte [rel kernel_wm_mouse_button_left_semaphore], STATIC_TRUE
 je .no_mouse_button_left_action ; yes, ignore

 ; remember this state
 mov byte [rel kernel_wm_mouse_button_left_semaphore], STATIC_TRUE

 ; check which object is under the cursor pointer
 call kernel_wm_object_find
 jc .no_mouse_button_left_action ; no element describing the record in the object table

 ; remember the pointer to the selected object
 mov qword [rel kernel_wm_object_selected_pointer], rsi
 mov qword [rel kernel_wm_object_active_pointer], rsi

 ; send a message to the process "left mouse button pressed"
 mov cl, KERNEL_IPC_MOUSE_EVENT_left_press
 call kernel_wm_ipc_mouse

 ; should the object keep its layer?
 test word [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags], KERNEL_WM_OBJECT_FLAG_fixed_z
 jnz .fixed_z ; yes

 ; move the object to the end of the list
 call kernel_wm_object_up

 ; one could try to check which fragment of the object is not visible
 ; instead of redrawing the whole... todo
 ;
 ; one can assume that some objects will be small enough...
 ; redrawing the whole will be faster than finding the invisible fragments

 ; display the content of the object once again
 or word [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags], KERNEL_WM_OBJECT_FLAG_flush

 ; display the content of the cursor object once again (covered by the object)
 or word [rel kernel_wm_object_cursor + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags], KERNEL_WM_OBJECT_FLAG_flush

.fixed_z:
 ; hide the objects marked with the FRAGILE flag
 call kernel_wm_object_hide_fragile

.no_mouse_button_left_action:
 ; has the left mouse button been released?
 bt word [rel driver_ps2_mouse_state], DRIVER_PS2_DEVICE_MOUSE_PACKET_LMB_bit
 jc .no_mouse_button_left_release ; no

.no_mouse_button_left_action_release:
 ; remove the state
 mov byte [rel kernel_wm_mouse_button_left_semaphore], STATIC_FALSE

.no_mouse_button_left_action_release_selected:

.no_mouse_button_left_release:
 ; has the right mouse button been pressed?
 bt word [rel driver_ps2_mouse_state], DRIVER_PS2_DEVICE_MOUSE_PACKET_RMB_bit
 jnc .no_mouse_button_right_action ; no

 ; was the right mouse button already pressed?
 cmp byte [rel kernel_wm_mouse_button_right_semaphore], STATIC_TRUE
 je .no_mouse_button_right_action ; yes, ignore

 ; remember this state
 mov byte [rel kernel_wm_mouse_button_right_semaphore], STATIC_TRUE

 ; check which object is under the cursor pointer
 call kernel_wm_object_find
 jc .no_mouse_button_right_action ; no object under the pointer

 ; hide the objects marked with the FRAGILE flag
 call kernel_wm_object_hide_fragile

 ; send a message to the process "right mouse button pressed"
 mov cl, KERNEL_IPC_MOUSE_EVENT_right_press
 call kernel_wm_ipc_mouse

.no_mouse_button_right_action:
 ; has the right mouse button been released?
 bt word [rel driver_ps2_mouse_state], DRIVER_PS2_DEVICE_MOUSE_PACKET_RMB_bit
 jc .no_mouse_button_right_release ; no

 ; remove this state
 mov byte [rel kernel_wm_mouse_button_right_semaphore], STATIC_FALSE

.no_mouse_button_right_release:
 ; movement of the cursor pointer on the X axis
 test r14w, r14w
 jnz .move ; yes

 ; movement of the cursor pointer on the Y axis
 test r15w, r15w
 jz .end ; no

.move:
 ; process the zone occupied by the cursor object
 mov rax, kernel_wm_object_cursor
 call kernel_wm_zone_insert_by_object

 ; update the specification of the cursor object
 add word [rel kernel_wm_object_cursor + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.x], r14w
 add word [rel kernel_wm_object_cursor + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.y], r15w

 ; the cursor object has been updated
 or word [rel kernel_wm_object_cursor + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags], KERNEL_WM_OBJECT_FLAG_flush


 ; if along with the pressed left mouse button
 cmp byte [rel kernel_wm_mouse_button_left_semaphore], STATIC_FALSE
 je .end ; unfortunately, no

 ; the active/visible object was selected
 cmp qword [rel kernel_wm_object_selected_pointer], STATIC_EMPTY
 je .end ; not this either

 ; move the object together with the cursor pointer
 call kernel_wm_object_move

.end:
 ; restore the original registers
 pop r11
 pop r10
 pop r9
 pop r8
 pop rsi
 pop rcx
 pop rbx
 pop rax

 ; return from the procedure
 ret

 macro_debug "kernel_wm_event"
