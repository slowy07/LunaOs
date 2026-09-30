
kernel_init_rtc:
	; fetch the state of register A
	mov al, DRIVER_RTC_PORT_STATUS_REGISTER_A
	out DRIVER_RTC_PORT_command, al
	in al, DRIVER_RTC_PORT_data

	; update in progress?
	test al, DRIVER_RTC_PORT_STATUS_REGISTER_A_update_in_progress
	jne kernel_init_rtc ; yes, check once more

	; set the interrupt rate to 1024 Hz
	mov al, DRIVER_RTC_PORT_STATUS_REGISTER_A
	out DRIVER_RTC_PORT_command, al
	mov al, DRIVER_RTC_PORT_STATUS_REGISTER_A_rate | DRIVER_RTC_PORT_STATUS_REGISTER_A_divider
	out DRIVER_RTC_PORT_data, al

	; enable: 24 hour mode, binary time and interrupts
	mov al, DRIVER_RTC_PORT_STATUS_REGISTER_B
	out DRIVER_RTC_PORT_command, al
	mov al, DRIVER_RTC_PORT_STATUS_REGISTER_B_24_hour_mode | DRIVER_RTC_PORT_STATUS_REGISTER_B_binary_mode | DRIVER_RTC_PORT_STATUS_REGISTER_B_periodic_interrupt
	out DRIVER_RTC_PORT_data, al

	; set CMOS to register C
	mov al, DRIVER_RTC_PORT_STATUS_REGISTER_C
	out DRIVER_RTC_PORT_command, al

	; fetch the status
	in al, DRIVER_RTC_PORT_data

	; register the real time clock interrupt handler in the IDT
	mov eax, KERNEL_IDT_IRQ_offset + DRIVER_RTC_IRQ_number
	mov bx, KERNEL_IDT_TYPE_irq
	mov rdi, driver_rtc
	call kernel_idt_mount

	; program the IDT interrupt vector into the I/O APIC
	mov eax, KERNEL_IDT_IRQ_offset + DRIVER_RTC_IRQ_number
	mov ebx, DRIVER_RTC_IO_APIC_register
	call kernel_io_apic_connect

	; enable interrupt handling
	sti
