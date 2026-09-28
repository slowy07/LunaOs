;===============================================================================

zero_microtime				dq	0x0000000000000000

zero_memory_map_address			dd	0x00000000
zero_graphics_mode_info_block_address	dd	0x00000000

; bring the header position to a full address
align	0x08,				db	0x90
zero_idt_header:
					dw	0x1000
					dq	ZERO_IDT_address

; pad the boot program size to a full sector size
align	0x0200
