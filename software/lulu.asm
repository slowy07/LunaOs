
 %include "software/lulu/config.asm"

lulu:
 ; initialize the working environment of the text editor
 %include "software/lulu/init.asm"

.loop:
 ; fetch the "character from the keyboard buffer" message
 mov ax, KERNEL_SERVICE_PROCESS_ipc_receive
 mov rdi, lulu_ipc_data
 int KERNEL_SERVICE
 jc .loop ; no message

 ; update the document status bar
 call lulu_status

 ; message of the keyboard type?
 cmp byte [rdi + KERNEL_IPC_STRUCTURE.type], KERNEL_IPC_TYPE_KEYBOARD
 jne .loop ; ignore

 ; fetch the key code
 mov ax, word [rdi + KERNEL_IPC_STRUCTURE.data]

 ; was the keyboard shortcut invoked?
 call lulu_shortcut
 jnc .loop ; yes

 ; function key?
 call lulu_key
 jnc .loop ; yes

 ; printable character?
 cmp ax, STATIC_SCANCODE_SPACE
 jb .loop ; no
 cmp ax, STATIC_SCANCODE_TILDE
 ja .loop ; yes

 ; insert a character into the document
 xor bl, bl ; update all the global variables
 call lulu_document_insert

 ; display the current line contents on the screen again
 call lulu_line

 ; return to the main loop
 jmp .loop

.end:
 ; move the cursor to the end of the character space
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, lulu_string_close_end - lulu_string_close
 mov rsi, lulu_string_close
 int KERNEL_SERVICE

 ; terminate the program
 xor ax, ax
 int KERNEL_SERVICE

 macro_debug "software: lulu"

 %include "software/lulu/data.asm"
 %include "software/lulu/document.asm"
 %include "software/lulu/interface.asm"
 %include "software/lulu/key.asm"
 %include "software/lulu/line.asm"
 %include "software/lulu/shortcut.asm"
 %include "software/lulu/ipc.asm"
 %include "software/lulu/status.asm"
