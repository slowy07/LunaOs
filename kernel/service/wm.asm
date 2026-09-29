;===============================================================================

	;-----------------------------------------------------------------------
	; constants, variables, globals, structures, objects
	;-----------------------------------------------------------------------
	%include	"kernel/service/wm/config.asm"
	;-----------------------------------------------------------------------

;===============================================================================
kernel_wm:
	;-----------------------------------------------------------------------
	; initialisation of the production environment
	;-----------------------------------------------------------------------
	%include	"kernel/service/wm/init.asm"

.loop:
	;-----------------------------------------------------------------------
	; check the mouse and keyboard events
	;-----------------------------------------------------------------------
	call	kernel_wm_event

	;-----------------------------------------------------------------------
	; check which objects have recently updated their content
	;-----------------------------------------------------------------------
	call	kernel_wm_object

	;-----------------------------------------------------------------------
	; process all registered zones
	;-----------------------------------------------------------------------
	call	kernel_wm_zone

	;-----------------------------------------------------------------------
	; fill all registered fragments
	;-----------------------------------------------------------------------
	call	kernel_wm_fill

	;-----------------------------------------------------------------------
	; check the position and state of the cursor
	;-----------------------------------------------------------------------
	call	kernel_wm_cursor

	;-----------------------------------------------------------------------
	; release the remaining processor time
	;-----------------------------------------------------------------------
	call	kernel_sleep

	; return to the main loop
	jmp	.loop

	;-----------------------------------------------------------------------
	%include	"kernel/service/wm/data.asm"
	%include	"kernel/service/wm/zone.asm"
	%include	"kernel/service/wm/cursor.asm"
	%include	"kernel/service/wm/object.asm"
	%include	"kernel/service/wm/fill.asm"
	%include	"kernel/service/wm/event.asm"
	%include	"kernel/service/wm/service.asm"
	%include	"kernel/service/wm/ipc.asm"
	%include	"kernel/service/wm/keyboard.asm"
	;-----------------------------------------------------------------------

kernel_wm_end:
;===============================================================================
