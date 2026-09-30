
; output:
;	ZF flag - if no key (or the window was not entitled to it)
;	ax - ASCII code of the key or its sequence
kernel_wm_keyboard:
 ; fetch the key code from the buffer
 call driver_ps2_keyboard_read
 jz .end ; none

 ; fetch the pointer to the active object which will receive the message
 mov rsi, qword [rel kernel_wm_object_active_pointer]

 ; no selected object?
 test rsi, rsi
 jz .end ; yes, ignore the key

 ; send the keyboard information to the process owning the object
 call kernel_wm_ipc_keyboard

.end:
 ; return from the procedure
 ret

 ; information for Bochs
 macro_debug "kernel_wm_keyboard"
