
kernel_gui_init:
 ; is the window manager ready?
 cmp byte [rel kernel_wm_semaphore], STATIC_FALSE
 je kernel_gui_init ; no, wait

 ; preserve own PID number
 call kernel_task_active_pid
 mov qword [rel kernel_gui_pid], rax

 ; configure the workbench space
 mov rsi, kernel_gui_window_workbench

 ; set the width, height and size of the workbench space
 mov ax, word [rel kernel_video_width_pixel]
 mov bx, word [rel kernel_video_height_pixel]
 mov ecx, dword [rel kernel_video_size_byte]
 mov word [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.width], ax
 mov word [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.height], bx
 mov dword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.size], ecx

 ; prepare space for the workbench
 call library_page_from_size
 call kernel_memory_alloc

 ; save the address of the space
 mov qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.address], rdi


 ; fetch the color mix
 mov rax, qword [rel kernel_gui_background_mixer]

 ; width and height of the space
 mov bx, word [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.width]
 mov dx, word [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.height]

 ; offset of the vertical lines
 xor r9w, r9w

 ; fragment width based on the resolution
 mov r10w, word [rel kernel_video_width_pixel]
 shr r10w, STATIC_DIVIDE_BY_16_shift

.background_reload:
 ; start with a fragment of 64 pixels
 movzx ecx, r10w

.background_loop:
 ; width smaller than the fragment?
 cmp bx, r10w
 jb .fill ; yes, correct

 ; fill the fragment with color
 rol rax, STATIC_REPLACE_EAX_WITH_HIGH_shift ; swap the color scheme
 rep stosd

 ; remaining width of the space
 sub bx, r10w
 jz .offset ; first row ready
 jns .background_reload ; no overflow, continue

.fill:
 ; remaining width to fill
 movzx ecx, bx
 rol rax, STATIC_REPLACE_EAX_WITH_HIGH_shift ; swap the color scheme
 rep stosd

.offset:
 ; next row shifted by the next pixel
 inc r9w

 ; offset greater than the fragment width?
 cmp r9w, r10w
 jb .offset_ok ; no

 ; reset the offset position
 xor r9w, r9w

 ; swap the color scheme
 rol rax, STATIC_REPLACE_EAX_WITH_HIGH_shift

 ; continue
 jmp .offset_end

.offset_ok:
 ; fill the offset fragment
 movzx ecx, r9w
 rep stosd

.offset_end:
 ; width of the space
 mov bx, word [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.width]

 ; correct the space width by the fragment offset
 sub bx, r9w

 ; end of the space on the height
 dec dx
 jnz .background_reload ; no


 ; allocate an identifier for the window
 call kernel_wm_object_id_new
 mov qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.id], rcx

 ; register the window
 call kernel_wm_object_insert

 ; configure the taskbar space
 mov rsi, kernel_gui_window_taskbar

 ; put the taskbar at the bottom of the screen
 mov bx, word [rel kernel_video_height_pixel]
 sub bx, KERNEL_GUI_WINDOW_TASKBAR_HEIGHT_pixel
 mov word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.y], bx

 ; stretch the taskbar across the whole screen
 mov ax, word [rel kernel_video_width_pixel]
 mov word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width], ax

 ; put the "clock" label at the end of the taskbar
 sub ax, word [rel kernel_gui_window_taskbar.element_label_clock + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
 mov word [rel kernel_gui_window_taskbar.element_label_clock + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x], ax

 ; compute the size of the window data space in Bytes
 movzx eax, word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
 shl eax, KERNEL_VIDEO_DEPTH_shift
 movzx ebx, word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
 mul ebx

 ; prepare space for the window
 mov ecx, eax
 call library_page_from_size
 call kernel_memory_alloc

 ; save the address of the space
 mov qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.address], rdi

 ; create the taskbar window
 macro_library LIBRARY_STRUCTURE_ENTRY.bosu

 ; allocate an identifier for the window
 call kernel_wm_object_id_new
 mov qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.id], rcx

 ; register the window in the window manager
 call kernel_wm_object_insert

 ; create the context menu
 mov rsi, kernel_gui_window_menu

 ; the number of elements of the menu and their total height relative to each other
 macro_library LIBRARY_STRUCTURE_ENTRY.bosu_elements_specification

 ; set the width and height of the menu window
 mov word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width], r8w
 mov word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height], r9w

 ; compute the size of the window data space in Bytes
 movzx eax, word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
 shl rax, KERNEL_VIDEO_DEPTH_shift
 movzx ebx, word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
 mul ebx

 ; prepare space for the window
 mov ecx, eax
 call library_page_from_size
 call kernel_memory_alloc

 ; save the address of the space
 mov qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.address], rdi

 ; create the taskbar window
 macro_library LIBRARY_STRUCTURE_ENTRY.bosu

 ; allocate an identifier for the window
 call kernel_wm_object_id_new
 mov qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.id], rcx

 ; register the window in the window manager
 call kernel_wm_object_insert

 ; save the information about the last modification of the window list
 mov rax, qword [rel kernel_wm_object_list_modify_time]
 mov qword [rel kernel_gui_window_taskbar_modify_time], rax

 ; prepare the window order list
 call kernel_memory_alloc_page
 call kernel_page_drain
 mov qword [rel kernel_gui_taskbar_list_address], rdi ; save the pointer

 ; run the Console program by default
 call kernel_gui_event_console

 macro_debug "kernel_gui_init"
