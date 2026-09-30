;===============================================================================

DRIVER_PS2_KEYBOARD_IRQ_number					equ	0x01	; 1
DRIVER_PS2_KEYBOARD_IO_APIC_register				equ	KERNEL_IO_APIC_iowin + (DRIVER_PS2_KEYBOARD_IRQ_number * 0x02)

DRIVER_PS2_MOUSE_IRQ_number					equ	0x0C	; 12
DRIVER_PS2_MOUSE_IO_APIC_register				equ	KERNEL_IO_APIC_iowin + (DRIVER_PS2_MOUSE_IRQ_number * 0x02)

DRIVER_PS2_PORT_DATA						equ	0x60
DRIVER_PS2_PORT_COMMAND_OR_STATUS				equ	0x64

DRIVER_PS2_DEVICE_ID_GET					equ	0xF2
DRIVER_PS2_DEVICE_SET_SAMPLE_RATE				equ	0xF3
DRIVER_PS2_DEVICE_PACKETS_ENABLE				equ	0xF4
DRIVER_PS2_DEVICE_PACKETS_DISABLE				equ	0xF5
DRIVER_PS2_DEVICE_SET_DEFAULT					equ	0xF6
DRIVER_PS2_DEVICE_RESET						equ	0xFF

DRIVER_PS2_DEVICE_MOUSE_TYPE_STANDARD				equ	0x00
DRIVER_PS2_DEVICE_MOUSE_TYPE_WHEEL				equ	0x03
DRIVER_PS2_DEVICE_MOUSE_TYPE_BUTTONS_ADDITIONAL			equ	0x04
DRIVER_PS2_DEVICE_MOUSE_PACKET_LMB_bit				equ	0
DRIVER_PS2_DEVICE_MOUSE_PACKET_RMB_bit				equ	1
DRIVER_PS2_DEVICE_MOUSE_PACKET_MMB_bit				equ	2
DRIVER_PS2_DEVICE_MOUSE_PACKET_ALWAYS_ONE_bit			equ	3
DRIVER_PS2_DEVICE_MOUSE_PACKET_X_SIGNED_bit			equ	4
DRIVER_PS2_DEVICE_MOUSE_PACKET_Y_SIGNED_bit			equ	5
DRIVER_PS2_DEVICE_MOUSE_PACKET_OVERFLOW_x			equ	6
DRIVER_PS2_DEVICE_MOUSE_PACKET_OVERFLOW_y			equ	7
DRIVER_PS2_DEVICE_MOUSE_mask					equ	0xFFFFFFFFFFFFFF00

DRIVER_PS2_STATUS_output					equ	00000001b
DRIVER_PS2_STATUS_input						equ	00000010b
DRIVER_PS2_STATUS_system_flag					equ	00000100b
DRIVER_PS2_STATUS_command_data					equ	00001000b
DRIVER_PS2_STATUS_output_second					equ	00100000b
DRIVER_PS2_STATUS_timeout					equ	01000000b
DRIVER_PS2_STATUS_parity					equ	10000000b

DRIVER_PS2_COMMAND_CONFIGURATION_GET				equ	0x20
DRIVER_PS2_COMMAND_CONFIGURATION_SET				equ	0x60
DRIVER_PS2_COMMAND_DISABLE_SECOND_PORT				equ	0xA7
DRIVER_PS2_COMMAND_ENABLE_SECOND_PORT				equ	0xA8
DRIVER_PS2_COMMAND_TEST_PORT_SECOND				equ	0xA9
DRIVER_PS2_COMMAND_TEST_CONTROLLER				equ	0xAA
DRIVER_PS2_COMMAND_TEST_PORT_FIRST				equ	0xAB
DRIVER_PS2_COMMAND_DISABLE_FIRST_PORT				equ	0xAD
DRIVER_PS2_COMMAND_ENABLE_FIRST_PORT				equ	0xAE
DRIVER_PS2_COMMAND_CONTROLLER_INPUT_READ			equ	0xC0
DRIVER_PS2_COMMAND_CONTROLLER_OUTPUT_READ			equ	0xD0
DRIVER_PS2_COMMAND_PORT_SECOND_BYTE_SEND			equ	0xD4

DRIVER_PS2_ANSWER_SELF_TEST_SUCCESS				equ	0xAA
DRIVER_PS2_ANSWER_COMMAND_ACKNOWLEDGED				equ	0xFA
DRIVER_PS2_ANSWER_FAIL						equ	0xFC
DRIVER_PS2_ANSWER_COMMAND_RESEND				equ	0xFE

DRIVER_PS2_CONTROLLER_CONFIGURATION_BIT_FIRST_PORT_INTERRUPT	equ	0
DRIVER_PS2_CONTROLLER_CONFIGURATION_BIT_SECOND_PORT_INTERRUPT	equ	1
DRIVER_PS2_CONTROLLER_CONFIGURATION_BIT_SYSTEM_FLAG		equ	2
DRIVER_PS2_CONTROLLER_CONFIGURATION_BIT_FIRST_PORT_CLOCK	equ	4
DRIVER_PS2_CONTROLLER_CONFIGURATION_BIT_SECOND_PORT_CLOCK	equ	5
DRIVER_PS2_CONTROLLER_CONFIGURATION_BIT_FIRST_PORT_TRANSLATION	equ	6

DRIVER_PS2_KEYBOARD_sequence					equ	0xE0
DRIVER_PS2_KEYBOARD_sequence_alternative			equ	0xE1

DRIVER_PS2_KEYBOARD_key_release					equ	0x0080

DRIVER_PS2_KEYBOARD_PRESS_BACKSPACE				equ	0x0008
DRIVER_PS2_KEYBOARD_PRESS_TAB					equ	0x0009
DRIVER_PS2_KEYBOARD_PRESS_ENTER					equ	0x000D
DRIVER_PS2_KEYBOARD_PRESS_ESC					equ	0x001B
DRIVER_PS2_KEYBOARD_PRESS_CTRL_LEFT				equ	0x001D
DRIVER_PS2_KEYBOARD_PRESS_SHIFT_LEFT				equ	0xE02A
DRIVER_PS2_KEYBOARD_PRESS_SHIFT_RIGHT				equ	0xE036
DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_MULTIPLY			equ	0xE037
DRIVER_PS2_KEYBOARD_PRESS_ALT_LEFT				equ	0xE038
DRIVER_PS2_KEYBOARD_PRESS_CAPSLOCK				equ	0xE03A
DRIVER_PS2_KEYBOARD_PRESS_F1					equ	0xE03B
DRIVER_PS2_KEYBOARD_PRESS_F2					equ	0xE03C
DRIVER_PS2_KEYBOARD_PRESS_F3					equ	0xE03D
DRIVER_PS2_KEYBOARD_PRESS_F4					equ	0xE03E
DRIVER_PS2_KEYBOARD_PRESS_F5					equ	0xE03F
DRIVER_PS2_KEYBOARD_PRESS_F6					equ	0xE040
DRIVER_PS2_KEYBOARD_PRESS_F7					equ	0xE041
DRIVER_PS2_KEYBOARD_PRESS_F8					equ	0xE042
DRIVER_PS2_KEYBOARD_PRESS_F9					equ	0xE043
DRIVER_PS2_KEYBOARD_PRESS_F10					equ	0xE044
DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK				equ	0xE045
DRIVER_PS2_KEYBOARD_PRESS_SCROLL_LOCK				equ	0xE046
DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_MINUS				equ	0xE04A
DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_4				equ	0xE14B
DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_5				equ	0xE04C
DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_6				equ	0xE14D
DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_PLUS				equ	0xE04E
DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_7				equ	0xE047
DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_8				equ	0xE048
DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_9				equ	0xE049
DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_1				equ	0xE14F
DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_2				equ	0xE150
DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_3				equ	0xE151
DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_0				equ	0xE152
DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_DOT				equ	0xE153
DRIVER_PS2_KEYBOARD_PRESS_F11					equ	0xE057
DRIVER_PS2_KEYBOARD_PRESS_F12					equ	0xE158
DRIVER_PS2_KEYBOARD_PRESS_CTRL_RIGHT				equ	0xE01D
DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_DIVIDE			equ	0xE035
DRIVER_PS2_KEYBOARD_PRESS_ALT_RIGHT				equ	0xE038
DRIVER_PS2_KEYBOARD_PRESS_HOME					equ	0xE047
DRIVER_PS2_KEYBOARD_PRESS_ARROW_UP				equ	0xE048
DRIVER_PS2_KEYBOARD_PRESS_PAGE_UP				equ	0xE049
DRIVER_PS2_KEYBOARD_PRESS_ARROW_LEFT				equ	0xE04B
DRIVER_PS2_KEYBOARD_PRESS_ARROW_RIGHT				equ	0xE04D
DRIVER_PS2_KEYBOARD_PRESS_END					equ	0xE04F
DRIVER_PS2_KEYBOARD_PRESS_ARROW_DOWN				equ	0xE050
DRIVER_PS2_KEYBOARD_PRESS_PAGE_DOWN				equ	0xE051
DRIVER_PS2_KEYBOARD_PRESS_INSERT				equ	0xE052
DRIVER_PS2_KEYBOARD_PRESS_DELETE				equ	0xE053
DRIVER_PS2_KEYBOARD_PRESS_WIN_LEFT				equ	0xE058
DRIVER_PS2_KEYBOARD_PRESS_MOUSE_RIGHT				equ	0xE05D

DRIVER_PS2_KEYBOARD_RELEASE_BACKSPACE				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_BACKSPACE
DRIVER_PS2_KEYBOARD_RELEASE_TAB					equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_TAB
DRIVER_PS2_KEYBOARD_RELEASE_ENTER				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_ENTER
DRIVER_PS2_KEYBOARD_RELEASE_ESC					equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_ESC
DRIVER_PS2_KEYBOARD_RELEASE_CTRL_LEFT				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_CTRL_LEFT
DRIVER_PS2_KEYBOARD_RELEASE_SHIFT_LEFT				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_SHIFT_LEFT
DRIVER_PS2_KEYBOARD_RELEASE_SHIFT_RIGHT				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_SHIFT_RIGHT
DRIVER_PS2_KEYBOARD_RELEASE_NUMLOCK_MULTIPLY			equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_MULTIPLY
DRIVER_PS2_KEYBOARD_RELEASE_ALT_LEFT				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_ALT_LEFT
DRIVER_PS2_KEYBOARD_RELEASE_CAPSLOCK				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_CAPSLOCK
DRIVER_PS2_KEYBOARD_RELEASE_F1					equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_F1
DRIVER_PS2_KEYBOARD_RELEASE_F2					equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_F2
DRIVER_PS2_KEYBOARD_RELEASE_F3					equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_F3
DRIVER_PS2_KEYBOARD_RELEASE_F4					equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_F4
DRIVER_PS2_KEYBOARD_RELEASE_F5					equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_F5
DRIVER_PS2_KEYBOARD_RELEASE_F6					equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_F6
DRIVER_PS2_KEYBOARD_RELEASE_F7					equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_F7
DRIVER_PS2_KEYBOARD_RELEASE_F8					equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_F8
DRIVER_PS2_KEYBOARD_RELEASE_F9					equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_F9
DRIVER_PS2_KEYBOARD_RELEASE_F10					equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_F10
DRIVER_PS2_KEYBOARD_RELEASE_NUMLOCK				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK
DRIVER_PS2_KEYBOARD_RELEASE_SCROLL_LOCK				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_SCROLL_LOCK
DRIVER_PS2_KEYBOARD_RELEASE_NUMLOCK_MINUS			equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_MINUS
DRIVER_PS2_KEYBOARD_RELEASE_NUMLOCK_4				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_4
DRIVER_PS2_KEYBOARD_RELEASE_NUMLOCK_5				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_5
DRIVER_PS2_KEYBOARD_RELEASE_NUMLOCK_6				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_6
DRIVER_PS2_KEYBOARD_RELEASE_NUMLOCK_PLUS			equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_PLUS
DRIVER_PS2_KEYBOARD_RELEASE_NUMLOCK_1				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_1
DRIVER_PS2_KEYBOARD_RELEASE_NUMLOCK_2				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_2
DRIVER_PS2_KEYBOARD_RELEASE_NUMLOCK_3				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_3
DRIVER_PS2_KEYBOARD_RELEASE_NUMLOCK_0				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_0
DRIVER_PS2_KEYBOARD_RELEASE_NUMLOCK_DOT				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_DOT
DRIVER_PS2_KEYBOARD_RELEASE_F11					equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_F11
DRIVER_PS2_KEYBOARD_RELEASE_F12					equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_F12
DRIVER_PS2_KEYBOARD_RELEASE_CTRL_RIGHT				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_CTRL_RIGHT
DRIVER_PS2_KEYBOARD_RELEASE_NUMLOCK_DIVIDE			equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_DIVIDE
DRIVER_PS2_KEYBOARD_RELEASE_ALT_RIGHT				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_ALT_RIGHT
DRIVER_PS2_KEYBOARD_RELEASE_HOME				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_HOME
DRIVER_PS2_KEYBOARD_RELEASE_ARROW_UP				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_ARROW_UP
DRIVER_PS2_KEYBOARD_RELEASE_PAGE_UP				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_PAGE_UP
DRIVER_PS2_KEYBOARD_RELEASE_ARROW_LEFT				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_ARROW_LEFT
DRIVER_PS2_KEYBOARD_RELEASE_ARROW_RIGHT				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_ARROW_RIGHT
DRIVER_PS2_KEYBOARD_RELEASE_END					equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_END
DRIVER_PS2_KEYBOARD_RELEASE_ARROW_DOWN				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_ARROW_DOWN
DRIVER_PS2_KEYBOARD_RELEASE_PAGE_DOWN				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_PAGE_DOWN
DRIVER_PS2_KEYBOARD_RELEASE_INSERT				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_INSERT
DRIVER_PS2_KEYBOARD_RELEASE_DELETE				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_DELETE
DRIVER_PS2_KEYBOARD_RELEASE_WIN_LEFT				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_WIN_LEFT
DRIVER_PS2_KEYBOARD_RELEASE_MOUSE_RIGHT				equ	DRIVER_PS2_KEYBOARD_key_release + DRIVER_PS2_KEYBOARD_PRESS_MOUSE_RIGHT

align	STATIC_QWORD_SIZE_byte,					db	STATIC_EMPTY
driver_ps2_mouse_position:
driver_ps2_mouse_x						dw	STATIC_EMPTY
driver_ps2_mouse_y						dw	STATIC_EMPTY
driver_ps2_mouse_type						db	STATIC_EMPTY
driver_ps2_mouse_packet						db	STATIC_EMPTY
driver_ps2_mouse_state						dw	STATIC_EMPTY

driver_ps2_keyboard_sequence					db	STATIC_EMPTY

align	STATIC_QWORD_SIZE_byte,					db	STATIC_NOTHING
driver_ps2_keyboard_cache					dw	STATIC_EMPTY, STATIC_EMPTY, STATIC_EMPTY, STATIC_EMPTY

align	STATIC_QWORD_SIZE_byte,					db	STATIC_NOTHING
driver_ps2_keyboard_matrix					dq	driver_ps2_keyboard_matrix_low
driver_ps2_keyboard_matrix_low					dw	STATIC_EMPTY
								dw	DRIVER_PS2_KEYBOARD_PRESS_ESC
								db	"1",	0x00				; 0x02
								db	"2",	0x00				; 0x03
								db	"3",	0x00				; 0x04
								db	"4",	0x00				; 0x05
								db	"5",	0x00				; 0x06
								db	"6",	0x00				; 0x07
								db	"7",	0x00				; 0x08
								db	"8",	0x00				; 0x09
								db	"9",	0x00				; 0x0A
								db	"0",	0x00				; 0x0B
								db	"-",	0x00				; 0x0C
								db	"=",	0x00				; 0x0D
								dw	DRIVER_PS2_KEYBOARD_PRESS_BACKSPACE
								dw	DRIVER_PS2_KEYBOARD_PRESS_TAB
								db	"q",	0x00				; 0x10
								db	"w",	0x00				; 0x11
								db	"e",	0x00				; 0x12
								db	"r",	0x00				; 0x13
								db	"t",	0x00				; 0x14
								db	"y",	0x00				; 0x15
								db	"u",	0x00				; 0x16
								db	"i",	0x00				; 0x17
								db	"o",	0x00				; 0x18
								db	"p",	0x00				; 0x19
								db	"[",	0x00				; 0x1A
								db	"]",	0x00				; 0x1B
								dw	DRIVER_PS2_KEYBOARD_PRESS_ENTER
								dw	DRIVER_PS2_KEYBOARD_PRESS_CTRL_LEFT
								db	"a",	0x00				; 0x1E
								db	"s",	0x00				; 0x1F
								db	"d",	0x00				; 0x20
								db	"f",	0x00				; 0x21
								db	"g",	0x00				; 0x22
								db	"h",	0x00				; 0x23
								db	"j",	0x00				; 0x24
								db	"k",	0x00				; 0x25
								db	"l",	0x00				; 0x26
								db	";",	0x00				; 0x27
								db	"'",	0x00				; 0x28
								db	"`",	0x00				; 0x29
								dw	DRIVER_PS2_KEYBOARD_PRESS_SHIFT_LEFT
								db	"\",	0x00				; 0x2B
								db	"z",	0x00				; 0x2C
								db	"x",	0x00				; 0x2D
								db	"c",	0x00				; 0x2E
								db	"v",	0x00				; 0x2F
								db	"b",	0x00				; 0x30
								db	"n",	0x00				; 0x31
								db	"m",	0x00				; 0x32
								db	",",	0x00				; 0x33
								db	".",	0x00				; 0x34
								db	"/",	0x00				; 0x35
								dw	DRIVER_PS2_KEYBOARD_PRESS_SHIFT_RIGHT	; 0x36
								dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_MULTIPLY
								dw	DRIVER_PS2_KEYBOARD_PRESS_ALT_LEFT	; 0x38
								dw	" ",	0x00				; 0x39
								dw	DRIVER_PS2_KEYBOARD_PRESS_CAPSLOCK	; 0x3A
								dw	DRIVER_PS2_KEYBOARD_PRESS_F1
								dw	DRIVER_PS2_KEYBOARD_PRESS_F2
								dw	DRIVER_PS2_KEYBOARD_PRESS_F3
								dw	DRIVER_PS2_KEYBOARD_PRESS_F4
								dw	DRIVER_PS2_KEYBOARD_PRESS_F5
								dw	DRIVER_PS2_KEYBOARD_PRESS_F6		; 0x40
								dw	DRIVER_PS2_KEYBOARD_PRESS_F7
								dw	DRIVER_PS2_KEYBOARD_PRESS_F8
								dw	DRIVER_PS2_KEYBOARD_PRESS_F9
								dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK
								dw	STATIC_EMPTY
								dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_7	; 0x47
								dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_8	; 0x48
								dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_9	; 0x49
								dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_MINUS	; 0x4A
								dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_4	; 0x4B
								dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_5	; 0x4C
								dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_6	; 0x4D
								dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_PLUS	; 0x4E
								dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_1	; 0x4F
								dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_2	; 0x50
								dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_3	; 0x51
								dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_0	; 0x52
								dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_DOT	; 0x53
								dw	STATIC_EMPTY
								dw	STATIC_EMPTY
								dw	STATIC_EMPTY
								dw	STATIC_EMPTY
								dw	DRIVER_PS2_KEYBOARD_PRESS_F11
								dw	DRIVER_PS2_KEYBOARD_PRESS_F12
driver_ps2_keyboard_matrix_high					dw	STATIC_EMPTY
								dw	DRIVER_PS2_KEYBOARD_PRESS_ESC
								db	"!",	0x00				; 0x02
								db	"@",	0x00				; 0x03
								db	"#",	0x00				; 0x04
								db	"$",	0x00				; 0x05
								db	"%",	0x00				; 0x06
								db	"^",	0x00				; 0x07
								db	"&",	0x00				; 0x08
								db	"*",	0x00				; 0x09
								db	"(",	0x00				; 0x0A
								db	")",	0x00				; 0x0B
								db	"_",	0x00				; 0x0C
								db	"+",	0x00				; 0x0D
								dw	DRIVER_PS2_KEYBOARD_PRESS_BACKSPACE
								dw	DRIVER_PS2_KEYBOARD_PRESS_TAB
								db	"Q",	0x00				; 0x10
								db	"W",	0x00				; 0x11
								db	"E",	0x00				; 0x12
								db	"R",	0x00				; 0x13
								db	"T",	0x00				; 0x14
								db	"Y",	0x00				; 0x15
								db	"U",	0x00				; 0x16
								db	"I",	0x00				; 0x17
								db	"O",	0x00				; 0x18
								db	"P",	0x00				; 0x19
								db	"{",	0x00				; 0x1A
								db	"}",	0x00				; 0x1B
								dw	DRIVER_PS2_KEYBOARD_PRESS_ENTER
								dw	DRIVER_PS2_KEYBOARD_PRESS_CTRL_LEFT
								db	"A",	0x00				; 0x1E
								db	"S",	0x00				; 0x1F
								db	"D",	0x00				; 0x20
								db	"F",	0x00				; 0x21
								db	"G",	0x00				; 0x22
								db	"H",	0x00				; 0x23
								db	"J",	0x00				; 0x24
								db	"K",	0x00				; 0x25
								db	"L",	0x00				; 0x26
								db	":",	0x00				; 0x27
								db	'"',	0x00				; 0x28	"
								db	"~",	0x00				; 0x29
								dw	DRIVER_PS2_KEYBOARD_PRESS_SHIFT_LEFT
								db	"|",	0x00				; 0x2B
								db	"Z",	0x00				; 0x2C
								db	"X",	0x00				; 0x2D
								db	"C",	0x00				; 0x2E
								db	"V",	0x00				; 0x2F
								db	"B",	0x00				; 0x30
								db	"N",	0x00				; 0x31
								db	"M",	0x00				; 0x32
								db	"<",	0x00				; 0x33
								db	">",	0x00				; 0x34
								db	"?",	0x00				; 0x35
								dw	DRIVER_PS2_KEYBOARD_PRESS_SHIFT_RIGHT
								dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_MULTIPLY
								dw	DRIVER_PS2_KEYBOARD_PRESS_ALT_LEFT
								dw	STATIC_EMPTY
								dw	DRIVER_PS2_KEYBOARD_PRESS_CAPSLOCK
								dw	DRIVER_PS2_KEYBOARD_PRESS_F1
								dw	DRIVER_PS2_KEYBOARD_PRESS_F2
								dw	DRIVER_PS2_KEYBOARD_PRESS_F3
								dw	DRIVER_PS2_KEYBOARD_PRESS_F4
								dw	DRIVER_PS2_KEYBOARD_PRESS_F5
								dw	DRIVER_PS2_KEYBOARD_PRESS_F6
								dw	DRIVER_PS2_KEYBOARD_PRESS_F7
								dw	DRIVER_PS2_KEYBOARD_PRESS_F8
								dw	DRIVER_PS2_KEYBOARD_PRESS_F9
								dw	DRIVER_PS2_KEYBOARD_PRESS_F10
								dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK
								dw	DRIVER_PS2_KEYBOARD_PRESS_SCROLL_LOCK
								dw	STATIC_EMPTY
								dw	STATIC_EMPTY
								dw	STATIC_EMPTY
								dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_MINUS
								dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_4
								dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_5
								dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_6
								dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_PLUS
								dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_1
								dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_2
								dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_3
								dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_0
								dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_DOT
								dw	STATIC_EMPTY
								dw	STATIC_EMPTY
								dw	STATIC_EMPTY
								dw	DRIVER_PS2_KEYBOARD_PRESS_F11
								dw	DRIVER_PS2_KEYBOARD_PRESS_F12

driver_ps2_keyboard_ctrl_semaphore				db	STATIC_FALSE
driver_ps2_keyboard_shift_left_semaphore			db	STATIC_FALSE
driver_ps2_keyboard_shift_right_semaphore			db	STATIC_FALSE
driver_ps2_keyboard_alt_semaphore				db	STATIC_FALSE
driver_ps2_keyboard_capslock_semaphore				db	STATIC_FALSE

driver_ps2_string_debug						db	"Driver PS2: key 0x"
driver_ps2_string_scancode					dd	STATIC_EMPTY
								db	STATIC_SCANCODE_RETURN, STATIC_SCANCODE_NEW_LINE, STATIC_SCANCODE_TERMINATOR
driver_ps2_string_debug_end:

;===============================================================================
driver_ps2_mouse:
	; preserve the original registers
	push	rax
	push	rbx
	push	rdx

	; check whether the data belongs to the pointing device (mouse)
	in	al,	DRIVER_PS2_PORT_COMMAND_OR_STATUS
	test	al,	DRIVER_PS2_STATUS_output_second
	jz	.end	; no

	; fetch a message from the PS2 controller
	xor	eax,	eax
	in	al,	DRIVER_PS2_PORT_DATA

	; fetch the current position on the X and Y axes
	mov	bx,	word [rel driver_ps2_mouse_x]
	mov	dx,	word [rel driver_ps2_mouse_y]

	; status?
	cmp	byte [rel driver_ps2_mouse_packet],	STATIC_TRUE
	jne	.no_status	; no

	; does the status packet carry the "always on" bit?
	bt	ax,	DRIVER_PS2_DEVICE_MOUSE_PACKET_ALWAYS_ONE_bit
	jnc	.end	; error, drop the packet

	; overflow on the X axis
	bt	ax,	DRIVER_PS2_DEVICE_MOUSE_PACKET_OVERFLOW_x
	jc	.end	; yes, drop the packet

	; overflow on the X axis
	bt	ax,	DRIVER_PS2_DEVICE_MOUSE_PACKET_OVERFLOW_y
	jc	.end	; yes, drop the packet

	; keep the controller status
	mov	byte [rel driver_ps2_mouse_state],	al

	; the next packet is an X axis displacement
	inc	byte [rel driver_ps2_mouse_packet]

	; end of interrupt handling
	jmp	.end

.no_status:

	; X axis displacement?
	cmp	byte [rel driver_ps2_mouse_packet],	STATIC_FALSE
	jne	.no_x	; no

	; the next packet is a Y axis displacement
	inc	byte [rel driver_ps2_mouse_packet]

	; signed value?
	bt	word [rel driver_ps2_mouse_state],	DRIVER_PS2_DEVICE_MOUSE_PACKET_X_SIGNED_bit
	jnc	.x_unsigned	; no

	; correct the sign
	neg	al

	; move the pointer left
	sub	bx,	ax
	jns	.ready	; end of packet handling

	; correct the position on the X axis
	xor	bx,	bx

	; end of packet handling
	jmp	.ready

.x_unsigned:
	; move the pointer right
	add	bx,	ax

	; pointer off the screen on the X axis?
	cmp	bx,	word [rel kernel_video_width_pixel]
	jb	.ready	; no, end of packet handling

	; correct the position
	mov	bx,	word [rel kernel_video_width_pixel]
	dec	bx

	; end of packet handling
	jmp	.ready

.no_x:

	; the next packet is the status
	mov	byte [rel driver_ps2_mouse_packet],	STATIC_TRUE

	; signed value?
	bt	word [rel driver_ps2_mouse_state],	DRIVER_PS2_DEVICE_MOUSE_PACKET_Y_SIGNED_bit
	jnc	.y_unsigned	; no

	; correct the sign
	neg	al

	; move the pointer left
	add	dx,	ax

	; pointer below the screen on the X axis?
	cmp	dx,	word [rel kernel_video_height_pixel]
	jb	.ready	; no, end of packet handling

	; correct the position
	mov	dx,	word [rel kernel_video_height_pixel]
	dec	dx

	; end of packet handling
	jmp	.ready

.y_unsigned:
	; move the pointer right
	sub	dx,	ax
	jns	.ready	; end of packet handling

	; correct the position on the X axis
	xor	dx,	dx

.ready:
	; keep the new pointer position
	mov	word [rel driver_ps2_mouse_x],	bx
	mov	word [rel driver_ps2_mouse_y],	dx

.end:
	; tell the LAPIC that the hardware interrupt has been handled
	mov	rax,	qword [rel kernel_apic_base_address]
	mov	dword [rax + KERNEL_APIC_EOI_register],	STATIC_EMPTY

	; restore the original registers
	pop	rdx
	pop	rbx
	pop	rax

	; return from the hardware interrupt
	iretq

;===============================================================================
; output:
;	ZF flag, set if there is no key
;	ax - ASCII code of the key
driver_ps2_keyboard_pull:
	; preserve the original registers
	push	rsi

	; fetch the controller state
	in	al,	DRIVER_PS2_PORT_COMMAND_OR_STATUS

	; data ready?
	test	al,	DRIVER_PS2_STATUS_output
	jz	.end

	; fetch the key code from the keyboard hardware buffer
	xor	eax,	eax	; clear the accumulator
	in	al,	DRIVER_PS2_PORT_DATA

	; sequence to start?
	cmp	al,	DRIVER_PS2_KEYBOARD_sequence
	je	.sequence	; yes

	; sequence to start?
	cmp	al,	DRIVER_PS2_KEYBOARD_sequence_alternative
	je	.sequence	; yes

	; sequence started?
	cmp	byte [rel driver_ps2_keyboard_sequence],	STATIC_EMPTY
	je	.no_sequence	; no

	; combine the key code
	xor	ah,	ah
	xchg	ah,	byte [rel driver_ps2_keyboard_sequence]

	; store the key code in the keyboard buffer
	jmp	.save

.sequence:
	; keep the type of the sequence that has started
	mov	byte [rel driver_ps2_keyboard_sequence],	al

	; end of interrupt handling
	jmp	.end

.no_sequence:
	; point at the scancode table
	mov	rsi,	qword [rel driver_ps2_keyboard_matrix]

	; key code outside the table?
	cmp	al,	DRIVER_PS2_KEYBOARD_key_release
	jb	.inside	; no

	; correct the scancode
	sub	al,	DRIVER_PS2_KEYBOARD_key_release

	; fetch the key code from the scancode
	mov	ax,	word [rsi + rax * STATIC_WORD_SIZE_byte]

	; correct the key code
	add	al,	DRIVER_PS2_KEYBOARD_key_release

	; store the key code
	jmp	.save

.inside:
	; fetch the key code from the scancode
	mov	ax,	word [rsi + rax * STATIC_WORD_SIZE_byte]

.save:
	; preserve the original registers
	push	rbx
	push	rcx
	push	rdx
	push	rdi

	; turn the value into a string
	mov	bl,	STATIC_NUMBER_SYSTEM_hexadecimal
	mov	ecx,	4	; prefix
	mov	dl,	STATIC_SCANCODE_DIGIT_0	; fill up with ZERO values
	mov	rdi,	driver_ps2_string_scancode
	macro_library	LIBRARY_STRUCTURE_ENTRY.integer_to_string

	; send the string to the COM1 serial port
	mov	rsi,	driver_ps2_string_debug
	call	driver_serial_send

	; restore the original registers
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rbx

	; switch the keyboard table if the matching sequence occurred
	call	driver_ps2_keyboard_shift

.end:
	; restore the original registers
	pop	rsi

	; return from the procedure
	ret

;===============================================================================
driver_ps2_keyboard:
	; preserve the original registers
	push	rax

	; fetch the ASCII code of the key
	call	driver_ps2_keyboard_pull
	jz	.end	; no key

	; keep the ASCII code of the key in the buffer
	call	driver_ps2_keyboard_save

.end:
	; tell the LAPIC that the hardware interrupt has been handled
	mov	rax,	qword [rel kernel_apic_base_address]
	mov	dword [rax + KERNEL_APIC_EOI_register],	STATIC_EMPTY

	; restore the original registers
	pop	rax

	; return from the hardware interrupt
	iretq

;===============================================================================
; input:
;	ax - scancode of the key
; output:
;	CF flag - not recognised
driver_ps2_keyboard_shift:
	; left pressed
	cmp	ax,	DRIVER_PS2_KEYBOARD_PRESS_SHIFT_LEFT
	je	.press_left

	; right pressed
	cmp	ax,	DRIVER_PS2_KEYBOARD_PRESS_SHIFT_RIGHT
	je	.press_right

	; left released
	cmp	ax,	DRIVER_PS2_KEYBOARD_RELEASE_SHIFT_LEFT
	je	.release_left

	; right released
	cmp	ax,	DRIVER_PS2_KEYBOARD_RELEASE_SHIFT_RIGHT
	je	.release_right

	; caps lock pressed
	cmp	ax,	DRIVER_PS2_KEYBOARD_PRESS_CAPSLOCK
	je	.capslock

	; caps lock released?
	cmp	ax,	DRIVER_PS2_KEYBOARD_RELEASE_CAPSLOCK
	jne	.end	; no

	; release the semaphore
	mov	byte [rel driver_ps2_keyboard_capslock_semaphore],	STATIC_FALSE

.end:
	; return from the procedure
	ret

.press_left:
	; key held down?
	cmp	byte [rel driver_ps2_keyboard_shift_left_semaphore],	STATIC_TRUE
	je	.end	; yes

	; set the semaphore
	mov	byte [rel driver_ps2_keyboard_shift_left_semaphore],	STATIC_TRUE

	; switch the table
	jmp	.change

.press_right:
	; key held down?
	cmp	byte [rel driver_ps2_keyboard_shift_right_semaphore],	STATIC_TRUE
	je	.end	; yes

	; set the semaphore
	mov	byte [rel driver_ps2_keyboard_shift_right_semaphore],	STATIC_TRUE

	; return from the procedure
	jmp	.change

.release_left:
	; release the semaphore
	mov	byte [rel driver_ps2_keyboard_shift_left_semaphore],	STATIC_FALSE

	; switch the table
	jmp	.change

.release_right:
	; release the semaphore
	mov	byte [rel driver_ps2_keyboard_shift_right_semaphore],	STATIC_FALSE

	; switch the table
	jmp	.change

.capslock:
	; caps lock key held down?
	cmp	byte [rel driver_ps2_keyboard_capslock_semaphore],	STATIC_TRUE
	je	.end	; yes

	; set the semaphore
	mov	byte [rel driver_ps2_keyboard_capslock_semaphore],	STATIC_TRUE

.change:
	; switch the key table
	call	driver_ps2_keyboard_matrix_change

	; return from the procedure
	ret

;===============================================================================
driver_ps2_keyboard_save:
	; keep the ASCII value of the key in the software buffer
	shl	qword [rel driver_ps2_keyboard_cache],	STATIC_MOVE_AX_TO_HIGH_shift
	mov	word [rel driver_ps2_keyboard_cache],	ax

	; return from the procedure
	ret

;===============================================================================
driver_ps2_keyboard_matrix_change:
	; preserve the original keys
	push	rax

	; insert the suggested table type
	mov	rax,	driver_ps2_keyboard_matrix_high
	xchg	qword [rel driver_ps2_keyboard_matrix],	rax

	; switch successful?
	cmp	rax,	driver_ps2_keyboard_matrix_low
	je	.end	; yes

	; no, correct it
	mov	qword [rel driver_ps2_keyboard_matrix],	driver_ps2_keyboard_matrix_low

.end:
	; restore the original register
	pop	rax

	; return from the procedure
	ret

;===============================================================================
; output:
;	ZF flag - set if there is no key
;	ax - ASCII code of the key or its sequence
driver_ps2_keyboard_read:
	; fetch the ASCII code and remove it from the buffer
	mov	ax,	word [rel driver_ps2_keyboard_cache + STATIC_DWORD_SIZE_byte + STATIC_WORD_SIZE_byte]
	shl	qword [rel driver_ps2_keyboard_cache],	STATIC_MOVE_AX_TO_HIGH_shift

	; key code fetched?
	test	ax,	ax

	; return from the procedure
	ret

;===============================================================================
driver_ps2_check_dummy_answer_or_dump:
	; preserve the original registers
	push	rax

.again:
	; fetch the controller status
	in	al,	DRIVER_PS2_PORT_COMMAND_OR_STATUS
	bt	ax,	1	; check whether the first bit equals zero
	jnc	.nothing

	; fetch the unknown response from the controller buffer
	in	al,	DRIVER_PS2_PORT_DATA
	jmp	.again

.nothing:
	; restore the original registers
	pop	rax

	; return from the procedure
	ret

;===============================================================================
driver_ps2_send_command_receive_answer:
	; wait until a command can be sent
	call	driver_ps2_check_write

	; send the command
	out	DRIVER_PS2_PORT_COMMAND_OR_STATUS,	al

	; receive the response
	call	driver_ps2_receive_answer

	; return from the procedure
	ret

;===============================================================================
driver_ps2_check_write:
	; preserve the original registers
	push	rax

.loop:
	; fetch the controller status
	in	al,	DRIVER_PS2_PORT_COMMAND_OR_STATUS
	test	al,	2	; check whether the second bit equals zero
	jnz	.loop	; if not, repeat the operation

	; restore the original registers
	pop	rax

	; return from the procedure
	ret

;===============================================================================
; output:
;	al - response from the controller
driver_ps2_receive_answer:
	; wait until a response can be received
	call	driver_ps2_check_read

	; receive the response
	in	al,	DRIVER_PS2_PORT_DATA

	; return from the procedure
	ret

;===============================================================================
driver_ps2_check_read:
	; preserve the original registers
	push	rax

.loop:
	; fetch the controller status
	in	al,	DRIVER_PS2_PORT_COMMAND_OR_STATUS
	test	al,	1	; check whether the first bit equals zero
	jz	.loop	; if not, repeat the operation

	; restore the original registers
	pop	rax

	; return from the procedure
	ret

;===============================================================================
driver_ps2_send_command:
	; wait until a command can be sent
	call	driver_ps2_check_write

	; send the command
	out	DRIVER_PS2_PORT_COMMAND_OR_STATUS,	al

	; return from the procedure
	ret

;===============================================================================
; input:
;	al - query to the controller
driver_ps2_send_answer_or_ask_device:
	; wait until a command can be sent
	call	driver_ps2_check_write

	; send the command
	out	DRIVER_PS2_PORT_DATA,	al

	; return from the procedure
	ret
