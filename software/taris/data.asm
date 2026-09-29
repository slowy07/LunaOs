;===============================================================================

align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
taris_ipc_data:
	times KERNEL_IPC_STRUCTURE.SIZE		db	STATIC_EMPTY

taris_limit					dq	(taris_bricks_end - taris_bricks) / STATIC_QWORD_SIZE_byte
taris_limit_model				dq	STATIC_QWORD_SIZE_byte / STATIC_WORD_SIZE_byte
taris_seed					dd	0x681560BA

align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
;===============================================================================
taris_window					dw	STATIC_EMPTY	; position on the X axis
						dw	STATIC_EMPTY	; position on the Y axis
						dw	TARIS_WINDOW_WIDTH_pixel	; window width
						dw	TARIS_WINDOW_HEIGHT_pixel	; window height
						dq	STATIC_EMPTY	; pointer to the window data space (filled in by Bosu)
.extra:						dd	STATIC_EMPTY	; size of the window data space in bytes (filled in by Bosu)
						dw	LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_header | LIBRARY_BOSU_WINDOW_FLAG_border | LIBRARY_BOSU_WINDOW_FLAG_BUTTON_close
						dq	STATIC_EMPTY	; window identifier (filled in by Bosu)
						db	5
						db	"Taris                          "	; fill up to 31 bytes with STATIC_SCANCODE_SPACE characters
						dq	STATIC_EMPTY	; window width in bytes (filled in by Bosu)
.elements:					;-------------------------------
.element_button_close:				; element "window close"
						;-------------------------------
						db	LIBRARY_BOSU_ELEMENT_TYPE_button_close
						dw	.element_button_close_end - .element_button_close
						dq	taris.close
.element_button_close_end:			;-------------------------------
						; element "playground"
						;-------------------------------
.element_playground:				db	LIBRARY_BOSU_ELEMENT_TYPE_draw
						dw	.element_playground_end - .element_playground
						dw	0	; position on the X axis relative to the window data space
						dw	LIBRARY_BOSU_HEADER_HEIGHT_pixel
						dw	TARIS_PLAYGROUND_WIDTH_pixel
						dw	TARIS_WINDOW_HEIGHT_pixel
						dq	STATIC_EMPTY	; data space pointer (filled in by Bosu)
.element_playground_end:			;-------------------------------
						; end of the window elements
						;-------------------------------
						db	STATIC_EMPTY
taris_window_end:

align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
taris_bricks					dq	0x0720232027002620
						dq	0x6220074022301700
						dq	0x2310360023103600
						dq	0x6600660066006600
						dq	0x1320630013206300
						dq	0x0710226047003220
						dq	0x0F0022220F002222
taris_bricks_end:

taris_brick_position_x				dq	STATIC_EMPTY
taris_brick_position_y				dq	STATIC_EMPTY

taris_brick_platform:
	TIMES TARIS_PLAYGROUND_HEIGHT_brick	dw	0000100000000001b
						dw	0000111111111111b
