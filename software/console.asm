
 %include "software/console/config.asm"

console:
 ; initialization of the console space
 %include "software/console/init.asm"

.loop:
 ; complete the process input stream with the window meta data
 call console_meta

 ; free the remaining processor time
 mov ax, KERNEL_SERVICE_PROCESS_release
 int KERNEL_SERVICE

 ; is the shell process running?
 mov ax, KERNEL_SERVICE_PROCESS_check
 mov rcx, qword [console_shell_pid]
 int KERNEL_SERVICE
 jnc .exist ; yes

.close:
 ; terminate the console
 xor ax, ax
 int KERNEL_SERVICE

.exist:
 ; check the incoming events
 mov rsi, console_window
 macro_library LIBRARY_STRUCTURE_ENTRY.bosu_event
 jc .input ; no keyboard related exception

 ; pass the key code to the shell
 call console_transfer

.input:
 ; fetch a string from the stream
 mov ax, KERNEL_SERVICE_PROCESS_stream_in
 mov ecx, STATIC_EMPTY ; fetch the whole contents
 mov rdi, qword [console_cache_address]
 int KERNEL_SERVICE
 jz .loop ; no data

 ; display the contents
 xor eax, eax
 mov rsi, rdi

 ; restore the pointer to the terminal structure
 mov r8, console_terminal_table

 ; disable the cursor in the terminal
 macro_library LIBRARY_STRUCTURE_ENTRY.terminal_cursor_disable

.parse:
 ; end of the string?
 test rcx, rcx
 jz .flush ; yes

 ; has the sequence been processed?
 call console_sequence
 jnc .parse ; yes

 ; fetch a character from the string
 lodsb

 ; no character?
 test al, al
 jz .next ; yes

 ; save the counter
 push rcx

 ; display the character
 mov ecx, 1
 macro_library LIBRARY_STRUCTURE_ENTRY.terminal_char

 ; restore the counter
 pop rcx

.next:
 ; display the remaining characters from the string?
 dec rcx
 jnz .parse ; yes

.flush:
 ; enable the cursor in the terminal
 macro_library LIBRARY_STRUCTURE_ENTRY.terminal_cursor_enable

 ; update the window contents
 mov al, KERNEL_WM_WINDOW_update
 mov rsi, console_window
 or qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags], LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush
 int KERNEL_WM_IRQ

 ; stop the further execution of the code
 jmp .loop

 macro_debug "software: console"

 %include "software/console/data.asm"
 %include "software/console/transfer.asm"
 %include "software/console/sequence.asm"
 %include "software/console/meta.asm"
