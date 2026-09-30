
kernel_init_ps2:
	; the mouse controller is the most involved, and it has to be configured first

	; drain the PS2 controller buffer
	call	driver_ps2_check_dummy_answer_or_dump

	; fetch the PS2 controller configuration
	mov	al,	DRIVER_PS2_COMMAND_CONFIGURATION_GET
	call	driver_ps2_send_command_receive_answer

	; save the answer
	push	rax

	; tell it we want the answer back
	mov	al,	DRIVER_PS2_COMMAND_CONFIGURATION_SET
	call	driver_ps2_send_command

	; enable the interrupt and the clock on port 1
	bts	word [rsp],	DRIVER_PS2_CONTROLLER_CONFIGURATION_BIT_SECOND_PORT_INTERRUPT
	btr	word [rsp],	DRIVER_PS2_CONTROLLER_CONFIGURATION_BIT_SECOND_PORT_CLOCK

	; restore the modified answer
	pop	rax

	; send the answer
	call	driver_ps2_send_answer_or_ask_device

	; send a reset command to the device on port 1 (pointing device - mouse)
	mov	al,	DRIVER_PS2_COMMAND_PORT_SECOND_BYTE_SEND
	call	driver_ps2_send_command
	mov	al,	DRIVER_PS2_DEVICE_RESET
	call	driver_ps2_send_answer_or_ask_device

	; was the command processed correctly?
	call	driver_ps2_receive_answer
	cmp	al,	DRIVER_PS2_ANSWER_COMMAND_ACKNOWLEDGED
	jne	.error	; no

	; fetch the answer from the device
	call	driver_ps2_receive_answer

	; was the command processed correctly?
	cmp	al,	DRIVER_PS2_ANSWER_SELF_TEST_SUCCESS
	jne	.error	; no

	; fetch the device identifier
	call	driver_ps2_receive_answer
	mov	byte [rel driver_ps2_mouse_type],	al

	; set the device to its default values
	mov	al,	DRIVER_PS2_COMMAND_PORT_SECOND_BYTE_SEND
	call	driver_ps2_send_command
	mov	al,	DRIVER_PS2_DEVICE_SET_DEFAULT
	call	driver_ps2_send_answer_or_ask_device
	call	driver_ps2_receive_answer

	; was the command processed correctly?
	cmp	al,	DRIVER_PS2_ANSWER_COMMAND_ACKNOWLEDGED
	jne	.error	; no

	; enable packet transmission from the device to the controller
	mov	al,	DRIVER_PS2_COMMAND_PORT_SECOND_BYTE_SEND
	call	driver_ps2_send_command
	mov	al,	DRIVER_PS2_DEVICE_PACKETS_ENABLE
	call	driver_ps2_send_answer_or_ask_device
	call	driver_ps2_receive_answer

	; was the command processed correctly?
	cmp	al,	DRIVER_PS2_ANSWER_COMMAND_ACKNOWLEDGED
	je	.done	; yes

.error:
	; stop any further execution of the initialisation code
	jmp	$

.done:
	; hook up the mouse handlers
	mov	eax,	KERNEL_IDT_IRQ_offset + DRIVER_PS2_MOUSE_IRQ_number
	mov	bx,	KERNEL_IDT_TYPE_irq
	mov	rdi,	driver_ps2_mouse
	call	kernel_idt_mount

	; program the IDT interrupt vector into the I/O APIC
	mov	eax,	KERNEL_IDT_IRQ_offset + DRIVER_PS2_MOUSE_IRQ_number
	mov	ebx,	DRIVER_PS2_MOUSE_IO_APIC_register
	call	kernel_io_apic_connect

	; hook up the keyboard handler
	mov	eax,	KERNEL_IDT_IRQ_offset + DRIVER_PS2_KEYBOARD_IRQ_number
	mov	bx,	KERNEL_IDT_TYPE_irq
	mov	rdi,	driver_ps2_keyboard
	call	kernel_idt_mount

	; program the IDT interrupt vector into the I/O APIC
	mov	eax,	KERNEL_IDT_IRQ_offset + DRIVER_PS2_KEYBOARD_IRQ_number
	mov	ebx,	DRIVER_PS2_KEYBOARD_IO_APIC_register
	call	kernel_io_apic_connect
