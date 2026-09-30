
kernel_gui_pid				dq	STATIC_EMPTY

kernel_gui_clock_last_state		dq	STATIC_EMPTY
kernel_gui_clock_colon			db	STATIC_SCANCODE_SPACE

kernel_gui_background_mixer		dd	0x001B1B1B, 0x00212121

kernel_gui_event_console_file		db	"/bin/console"
kernel_gui_event_console_file_end:
kernel_gui_event_calculator_file		db	"/bin/calculator"
kernel_gui_event_calculator_file_end:
kernel_gui_event_tetris_file		db	"/bin/tetris"
kernel_gui_event_tetris_file_end:

align	STATIC_QWORD_SIZE_byte,		db	STATIC_NOTHING

kernel_gui_ipc_data:
	times KERNEL_IPC_STRUCTURE.SIZE	db	STATIC_EMPTY

align	STATIC_QWORD_SIZE_byte,		db	STATIC_NOTHING

kernel_gui_taskbar_list_address		dq	STATIC_EMPTY
kernel_gui_taskbar_list_count		dq	STATIC_EMPTY

kernel_gui_window_workbench		dw	0	; position on the X axis
					dw	0	; position on the Y axis
					dw	STATIC_EMPTY	; window width
					dw	STATIC_EMPTY	; window height
					dq	STATIC_EMPTY	; pointer to the window data space
.extra:					dd	STATIC_EMPTY	; size of the window data space in Bytes
					dw	LIBRARY_BOSU_WINDOW_FLAG_fixed_xy | LIBRARY_BOSU_WINDOW_FLAG_fixed_z | LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush
					dq	STATIC_EMPTY	; window identifier assigned by the window manager
					db	9
					db	"Workbench                      "	; pad to 31 Bytes with STATIC_SCANCODE_SPACE characters
					dq	STATIC_EMPTY

align	STATIC_QWORD_SIZE_byte,		db	STATIC_NOTHING

kernel_gui_window_taskbar_modify_time	dq	STATIC_EMPTY

kernel_gui_window_taskbar		dw	0	; position on the X axis
					dw	STATIC_EMPTY	; position on the Y axis
					dw	STATIC_EMPTY	; window width
					dw	KERNEL_GUI_WINDOW_TASKBAR_HEIGHT_pixel	; window height
					dq	STATIC_EMPTY	; pointer to the window data space
.extra:					dd	STATIC_EMPTY	; size of the window data space in Bytes
					dw	LIBRARY_BOSU_WINDOW_FLAG_fixed_xy | LIBRARY_BOSU_WINDOW_FLAG_fixed_z | LIBRARY_BOSU_WINDOW_FLAG_arbiter | LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush | LIBRARY_BOSU_WINDOW_FLAG_unregistered
					dq	STATIC_EMPTY	; window identifier assigned by the window manager
					db	7
					db	"Taskbar                        "	; pad to 31 Bytes with STATIC_SCANCODE_SPACE characters
					dq	STATIC_EMPTY	; window width in Bytes
.elements:				;---------------------------------------
					; element "chain 0"
.element_chain_0:			db	LIBRARY_BOSU_ELEMENT_TYPE_chain
					dw	STATIC_EMPTY	; size of the chain space in Bytes
					dq	STATIC_EMPTY	; address of the chain space
					; element "clock label"
.element_label_clock:			db	LIBRARY_BOSU_ELEMENT_TYPE_label
					dw	.element_label_clock_end - .element_label_clock ; element size in Bytes
					dw	0	; position on the X axis relative to the window
					dw	0	; position on the Y axis relative to the window
					dw	LIBRARY_FONT_WIDTH_pixel * (.element_label_clock_end - .element_label_clock_string_hour)	; element width in pixels
					dw	18	; element height in pixels
					dq	STATIC_EMPTY	; pointer to the event handler procedure
					db	LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_center
					db	.element_label_clock_end - .element_label_clock_string   ; string size in characters
.element_label_clock_string:		db	" "
.element_label_clock_string_hour:	db	"00"
.element_label_clock_char_colon:	db	":"
.element_label_clock_string_minute:	db	"00  "	; why two spaces?
.element_label_clock_end:		;---------------------------------------
					; end of the window elements
					db	LIBRARY_BOSU_ELEMENT_TYPE_none
kernel_gui_window_taskbar_end:

align	STATIC_QWORD_SIZE_byte,		db	STATIC_NOTHING

kernel_gui_window_menu			dw	160	; position on the X axis relative to the cursor pointer
					dw	80	; position on the Y axis relative to the cursor pointer
					dw	STATIC_EMPTY	; window width relative to the element content
					dw	STATIC_EMPTY	; window height relative to the element content
					dq	STATIC_EMPTY	; pointer to the window data space
.extra:					dd	STATIC_EMPTY	; size of the window data space in Bytes
					dw	LIBRARY_BOSU_WINDOW_FLAG_fragile | LIBRARY_BOSU_WINDOW_FLAG_unregistered | LIBRARY_BOSU_WINDOW_FLAG_border
					dq	STATIC_EMPTY	; window identifier assigned by the window manager
					db	4
					db	"Menu                           "	; pad to 31 Bytes with STATIC_SCANCODE_SPACE characters
					dq	STATIC_EMPTY	; window width in Bytes
.elements:				;---------------------------------------
					; element "label 0"
.element_label_0:			db	LIBRARY_BOSU_ELEMENT_TYPE_label
					dw	.element_label_0_end - .element_label_0 ; element size in Bytes
					dw	1	; position on the X axis relative to the window data space
					dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel	; position on the Y axis relative to the window data space
					dw	((.element_label_0_end - .element_label_0_string) * LIBRARY_FONT_WIDTH_pixel)	; element width
					dw	0x10	; element height
					dq	kernel_gui_event_console
					db	LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_default
					db	.element_label_0_end - .element_label_0_string
.element_label_0_string:		db	"Console"
.element_label_0_end:			;---------------------------------------
					; element "label 1"
.element_label_1:			db	LIBRARY_BOSU_ELEMENT_TYPE_label
					dw	.element_label_1_end - .element_label_1 ; element size in Bytes
					dw	1	; position on the X axis relative to the window data space
					dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + 0x10	; position on the Y axis relative to the window data space
					dw	((.element_label_1_end - .element_label_1_string) * LIBRARY_FONT_WIDTH_pixel)	; element width
					dw	0x10	; element height
					dq	kernel_gui_event_calculator
					db	LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_default
					db	.element_label_1_end - .element_label_1_string
.element_label_1_string:		db	"Calculator"
.element_label_1_end:			;---------------------------------------
					; element "label 2"
.element_label_2:			db	LIBRARY_BOSU_ELEMENT_TYPE_label
					dw	.element_label_2_end - .element_label_2 ; element size in Bytes
					dw	1	; position on the X axis relative to the window data space
					dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel + 0x10 * 0x02	; position on the Y axis relative to the window data space
					dw	((.element_label_2_end - .element_label_2_string) * LIBRARY_FONT_WIDTH_pixel)	; element width
					dw	0x10	; element height
					dq	kernel_gui_event_tetris
					db	LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_default
					db	.element_label_2_end - .element_label_2_string
.element_label_2_string:		db	"Tetris"
.element_label_2_end:			;---------------------------------------
					; end of the window elements
					db	LIBRARY_BOSU_ELEMENT_TYPE_none
kernel_gui_window_menu_end:
