
kernel_gui_taskbar_reload:
 ; preserve the original registers
 push rax
 push rcx
 push rsi
 push rdi

 ; has the object list been modified?
 mov rax, qword [rel kernel_wm_object_list_modify_time]
 cmp qword [rel kernel_gui_window_taskbar_modify_time], rax
 je .end ; no

 ; lock access to modifying the object list
 macro_lock kernel_wm_object_semaphore, 0

 ; our PID number
 mov rcx, qword [rel kernel_gui_pid]

 ; register the windows on the list in the order of their appearance
 mov rsi, qword [rel kernel_wm_object_list_address]
 mov rdi, qword [rel kernel_gui_taskbar_list_address]

.loop:
 ; fetch the pointer of the object table record
 lodsq

 ; end of the window list?
 test rax, rax
 jz .registered ; yes

 ; does the registered window belong to us?
 cmp qword [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.pid], rcx
 je .loop ; yes, skip the window

 ; put the entry on the list
 call .insert

 ; continue
 jmp .loop

.insert:
 ; preserve the original registers
 push rcx
 push rdi

 ; window identifier
 mov rax, qword [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.id]

 ; number of window identifiers on the list
 mov rcx, qword [rel kernel_gui_taskbar_list_count]

 ; is the list empty?
 test rcx, rcx
 jz .insert_new ; yes

.insert_loop:
 ; is the identifier on the list?
 cmp rax, qword [rdi]
 je .insert_end ; yes

 ; next entry
 add rdi, STATIC_QWORD_SIZE_byte

 ; end of the list?
 dec rcx
 jnz .insert_loop ; no

.insert_new:
 ; put the window identifier on the list
 stosq

 ; number of registered windows
 inc qword [rel kernel_gui_taskbar_list_count]

.insert_end:
 ; restore the original registers
 pop rdi
 pop rcx

 ; return from the subprocedure
 ret

.remove:
 ; preserve the original registers
 push rbx

 ; search the whole identifier list for non-existent windows
 mov rcx, qword [rel kernel_gui_taskbar_list_count]
 mov rdi, qword [rel kernel_gui_taskbar_list_address]

.remove_loop:
 ; is the identifier list empty?
 test rcx, rcx
 jz .remove_end

 ; check whether the window identifier exists
 mov rbx, qword [rdi]
 call kernel_wm_object_by_id
 jnc .remove_next ; it exists

 ; preserve the original registers
 push rcx
 push rdi

 ; remove the identifier from the list
 mov rsi, rdi
 add rsi, STATIC_QWORD_SIZE_byte
 rep movsq

 ; restore the original registers
 pop rdi
 pop rcx

 ; number of registered identifiers
 dec qword [rel kernel_gui_taskbar_list_count]

 ; continue
 jmp .remove_step_by

.remove_next:
 ; move the pointer to the next position
 add rdi, STATIC_QWORD_SIZE_byte

.remove_step_by:
 ; end of the list?
 dec rcx
 jnz .remove_loop ; no

.remove_end:
 ; restore the original registers
 pop rbx

 ; return from the subprocedure
 ret

.registered:
 ; remove all entries with non-existent identifiers
 call .remove

 ; release access to modifying the object list
 mov byte [rel kernel_wm_object_semaphore], STATIC_FALSE

.end:
 ; restore the original registers
 pop rdi
 pop rsi
 pop rcx
 pop rax

 ; return from the procedure
 ret

 macro_debug "kernel_gui_taskbar_reload"

; input:
;	rdi - pointer to the IPC message
kernel_gui_taskbar_event:
 ; preserve the original registers
 push rbx
 push rsi

 ; left mouse button?
 cmp byte [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_IPC_STRUCTURE_DATA_MOUSE.event], KERNEL_IPC_MOUSE_EVENT_left_press
 jne .end ; no

 ; check which window element the action concerns
 mov rsi, kernel_gui_window_taskbar
 macro_library LIBRARY_STRUCTURE_ENTRY.bosu_element
 jc .end ; no action

 ; does the action concern the clock element?
 cmp rsi, kernel_gui_window_taskbar.element_label_clock
 je .end ; yes, no action

 ; fetch the pointer to the object based on the window identifier
 mov rbx, qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.event]
 call kernel_wm_object_by_id

 ; change the visibility of the object
 xor word [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags], KERNEL_WM_OBJECT_FLAG_visible

 ; notify the window manager
 or word [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags], KERNEL_WM_OBJECT_FLAG_undraw

 ; process the taskbar once again
 mov qword [rel kernel_gui_window_taskbar_modify_time], STATIC_EMPTY

.end:
 ; restore the original registers
 pop rsi
 pop rbx

 ; return from the procedure
 ret

 macro_debug "kernel_gui_taskbar_event"

kernel_gui_taskbar:
 ; preserve the original registers
 push rax
 push rbx
 push rcx
 push rdx
 push rsi
 push rdi
 push r8

 ; prepare the current list of window identifiers
 call kernel_gui_taskbar_reload

 ; has the object list been modified?
 mov rax, qword [rel kernel_wm_object_list_modify_time]
 cmp qword [rel kernel_gui_window_taskbar_modify_time], rax
 je .end ; no

 ; lock access to modifying the object list
 macro_lock kernel_wm_object_semaphore, 0

 ; compute the required size of the chain space to write out all taskbar elements
 mov eax, LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.SIZE + LIBRARY_BOSU_WINDOW_NAME_length
 mov rcx, qword [rel kernel_gui_taskbar_list_count]
 inc rcx ; the element clearing the space
 mul rcx

 ; save the size of the space in pages
 push rax

 ; fetch the current size of the chain space in pages
 mov rcx, qword [rel kernel_gui_window_taskbar.element_chain_0 + LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.size]

 ; is the current chain size sufficient?
 shl rcx, STATIC_PAGE_SIZE_shift
 cmp rax, rcx
 jbe .enough ; yes

 ; no space
 test rcx, rcx
 jz .new ; yes, register a new one

 ; release the current chain space
 mov rdi, qword [rel kernel_gui_window_taskbar.element_chain_0 + LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.address]
 call kernel_memory_release

.new:
 ; allocate space for the generated elements
 mov rcx, rax
 call library_page_from_size
 call kernel_memory_alloc

 ; save the new chain space pointer
 mov qword [rel kernel_gui_window_taskbar.element_chain_0 + LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.address], rdi

.enough:
 ; fetch the current chain space pointer
 mov rdi, qword [rel kernel_gui_window_taskbar.element_chain_0 + LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.address]


 ; compute the default width of one element taking the available taskbar space into account
 movzx eax, word [rel kernel_gui_window_taskbar + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
 sub ax, word [rel kernel_gui_window_taskbar.element_label_clock + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
 mov rcx, qword [rel kernel_gui_taskbar_list_count]
 xor edx, edx

 ; no open windows?
 test rcx, rcx
 jz .max ; yes

 ; compute the width of one element
 div rcx

.max:
 ; save the element width
 mov bx, ax
 sub bx, KERNEL_GUI_WINDOW_TASKBAR_MARGIN_right

 ; position of the first element on the X axis
 xor edx, edx

 ; check all windows from the beginning of the list
 mov r8, qword [rel kernel_gui_taskbar_list_address]

 ; no elements to generate?
 test rcx, rcx
 jz .empty ; yes

.loop:
 ; end of the window list?
 cmp qword [r8], STATIC_EMPTY
 je .ready ; yes

 ; fetch the pointer to the object
 push rbx
 mov rbx, qword [r8]
 call kernel_wm_object_by_id
 pop rbx

 ; preserve the original registers
 push rdi

 ; create the first element describing the window at the beginning of the taskbar
 mov byte [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.type + LIBRARY_BOSU_STRUCTURE_TYPE.set], LIBRARY_BOSU_ELEMENT_TYPE_taskbar
 mov word [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.size], LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.SIZE
 mov word [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x], dx
 mov word [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y], STATIC_EMPTY
 mov word [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.width], bx
 mov word [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.height], KERNEL_GUI_WINDOW_TASKBAR_HEIGHT_pixel
 ; fetch the window identifier for the element
 mov rax, qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.id]
 mov qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.event], rax ; window identifier
 movzx ecx, byte [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.length]
 mov byte [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.length], cl
 add word [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.size], cx
 mov dword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.background], LIBRARY_BOSU_ELEMENT_TASKBAR_BG_color
 ; is the window visible?
 test word [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags], KERNEL_WM_OBJECT_FLAG_visible
 jnz .visible ; yes

 ; mark the window on the taskbar as visible
 mov dword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.background], LIBRARY_BOSU_ELEMENT_TASKBAR_BG_HIDDEN_color

.visible:
 ; insert the element name based on the window name
 add rsi, KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.name
 add rdi, LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.string
 rep movsb

 ; restore the original registers
 pop rdi

 ; move the chain space pointer past the created element
 movzx eax, word [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.size]
 add rdi, rax

 ; next element to the right of the current one
 add rdx, rbx

 ; save the element width
 push rbx

 ; insert the margin
 mov rbx, KERNEL_GUI_WINDOW_TASKBAR_MARGIN_right
 call kernel_gui_taskbar_margin

 ; restore the element width
 pop rbx

.next:
 ; move the pointer to the next window list entry
 add r8, STATIC_QWORD_SIZE_byte

 ; continue
 jmp .loop

.empty:
 ; clear the space with an empty label
 add rbx, KERNEL_GUI_WINDOW_TASKBAR_MARGIN_right ; together with the right margin
 call kernel_gui_taskbar_margin

.ready:
 ; update the size of the chain space
 pop rax
 mov word [rel kernel_gui_window_taskbar.element_chain_0 + LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.size], ax

 ; end the chain element list with an empty record
 mov byte [rdi + LIBRARY_BOSU_STRUCTURE_TYPE.set], LIBRARY_BOSU_ELEMENT_TYPE_none

 ; release access to modifying the object list
 mov byte [rel kernel_wm_object_semaphore], STATIC_FALSE

 ; process all elements in the chain
 mov rsi, kernel_gui_window_taskbar.element_chain_0
 mov rdi, kernel_gui_window_taskbar
 macro_library LIBRARY_STRUCTURE_ENTRY.bosu_element_chain

 ; set the window flag: new content
 mov al, KERNEL_WM_WINDOW_update
 mov rsi, kernel_gui_window_taskbar
 int KERNEL_WM_IRQ

 ; confirm the time of the last modification of the window list
 mov rax, qword [rel kernel_wm_object_list_modify_time]
 mov qword [rel kernel_gui_window_taskbar_modify_time], rax

.end:
 ; restore the original registers
 pop r8
 pop rdi
 pop rsi
 pop rdx
 pop rcx
 pop rbx
 pop rax

 ; return from the procedure
 ret

 macro_debug "kernel_gui_taskbar"

; input:
;	rdx - element position on the X axis
;	rdi - pointer to the position on the element list
; output:
;	rdx - position of the next element on the X axis
;	rdi - pointer to the next position on the element list
kernel_gui_taskbar_margin:
 ; clear the space with an empty label
 mov byte [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.type + LIBRARY_BOSU_STRUCTURE_TYPE.set], LIBRARY_BOSU_ELEMENT_TYPE_label
 mov word [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.size], LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.SIZE
 mov word [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x], dx
 mov word [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y], STATIC_EMPTY
 mov word [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.width], bx
 mov word [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.height], KERNEL_GUI_WINDOW_TASKBAR_HEIGHT_pixel
 mov qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.event], STATIC_EMPTY ; no action
 mov byte [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.length], 0x01
 mov byte [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.string], STATIC_SCANCODE_SPACE
 add word [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.size], 0x01

 ; move the X axis pointer
 add dx, bx

 ; move the chain space pointer past the created element
 movzx eax, word [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.size]
 add rdi, rax

 ; return from the procedure
 ret
