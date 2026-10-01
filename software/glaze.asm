%include "software/glaze/config.asm"

glaze:
 ; create the window
 mov rsi, glaze_window
 macro_library LIBRARY_STRUCTURE_ENTRY.bosu
 jc glaze.close ; not enough memory space

 ; display the contents of the window
 mov al, KERNEL_WM_WINDOW_update
 mov rsi, glaze_window
 or qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags], LIBRARY_BOSU_WINDOW_FLAG_flush
 int KERNEL_WM_IRQ

.loop:
 ; free the remaining processor time
 mov ax, KERNEL_SERVICE_PROCESS_sleep
 xor ecx, ecx ; no waiting in time
 int KERNEL_SERVICE

 ; debug marker of the main loop
 jmp .loop

.close:
 ; terminate the program
 xor ax, ax
 int KERNEL_SERVICE

 macro_debug "software: glaze"

 %include "software/glaze/data.asm"