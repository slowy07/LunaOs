
	; constants, variables, globals, structures, objects
	%include "kernel/service/gui/config.asm"

kernel_gui:
	; initialisation of the graphical interface
	%include "kernel/service/gui/init.asm"

.loop:
	; check incoming messages
	call kernel_gui_ipc

	; check whether the taskbar is up to date
	call kernel_gui_taskbar

	; update the "clock" label
	call kernel_gui_clock

	; release the remaining processor time
	call kernel_sleep

	; return to the main loop
	jmp .loop

	%include "kernel/service/gui/data.asm"
	%include "kernel/service/gui/clock.asm"
	%include "kernel/service/gui/ipc.asm"
	%include "kernel/service/gui/event.asm"
	%include "kernel/service/gui/taskbar.asm"

	macro_debug "kernel_gui"

kernel_gui_end:
