;===============================================================================

DRIVER_RTC_IRQ_number					equ	0x08
DRIVER_RTC_IO_APIC_register				equ	KERNEL_IO_APIC_iowin + (DRIVER_RTC_IRQ_number * 0x02)

DRIVER_RTC_PORT_command					equ	0x0070
DRIVER_RTC_PORT_data					equ	0x0071

DRIVER_RTC_PORT_second					equ	0x00
DRIVER_RTC_PORT_minute					equ	0x02
DRIVER_RTC_PORT_hour					equ	0x04
DRIVER_RTC_PORT_weekday					equ	0x06
DRIVER_RTC_PORT_day_of_month				equ	0x07
DRIVER_RTC_PORT_month					equ	0x08
DRIVER_RTC_PORT_year					equ	0x09
DRIVER_RTC_PORT_STATUS_REGISTER_A			equ	0x0A
DRIVER_RTC_PORT_STATUS_REGISTER_B			equ	0x0B

DRIVER_RTC_PORT_STATUS_REGISTER_A_rate			equ	00000110b	; 1024 Hz
DRIVER_RTC_PORT_STATUS_REGISTER_A_divider		equ	00100000b	; 32768 kHz
DRIVER_RTC_PORT_STATUS_REGISTER_A_update_in_progress	equ	10000000b

DRIVER_RTC_PORT_STATUS_REGISTER_B_daylight_savings	equ	00000001b
DRIVER_RTC_PORT_STATUS_REGISTER_B_24_hour_mode		equ	00000010b
DRIVER_RTC_PORT_STATUS_REGISTER_B_binary_mode		equ	00000100b
DRIVER_RTC_PORT_STATUS_REGISTER_B_periodic_interrupt	equ	01000000b
DRIVER_RTC_PORT_STATUS_REGISTER_C			equ	0x0C

DRIVER_RTC_Hz						equ	1024

struc	DRIVER_RTC_STRUCTURE
	.second						resb	1
	.minute						resb	1
	.hour						resb	1
	.day						resb	1
	.month						resb	1
	.year						resb	1
	.day_of_week					resb	1
endstruc

driver_rtc_semaphore					db	STATIC_FALSE

driver_rtc_microtime					dq	STATIC_EMPTY

driver_rtc_date_and_time				dq	STATIC_EMPTY

;===============================================================================
; default real time clock interrupt handler
driver_rtc:
	; preserve the original registers
	push	rax

	; increment the tick counter
	inc	qword [rel driver_rtc_microtime]

	; fetch the contents of register C
	in	al,	DRIVER_RTC_PORT_data

	; tell the LAPIC that the hardware interrupt has been handled
	mov	rax,	qword [rel kernel_apic_base_address]
	mov	dword [rax + KERNEL_APIC_EOI_register],	STATIC_EMPTY

	; restore the original registers
	pop	rax

	; return from the hardware interrupt
	iretq

;===============================================================================
; output:
;	driver_rtc_date_and_time
driver_rtc_get_date_and_time:
	; preserve the original register
	push	rax

	; fetch the number of seconds
	mov	al,	DRIVER_RTC_PORT_second
	out	DRIVER_RTC_PORT_command,	al
	in	al,	DRIVER_RTC_PORT_data

	; store
	mov	byte [rel driver_rtc_date_and_time + DRIVER_RTC_STRUCTURE.second],	al

	; fetch the number of minutes
	mov	al,	DRIVER_RTC_PORT_minute
	out	DRIVER_RTC_PORT_command,	al
	in	al,	DRIVER_RTC_PORT_data

	; store
	mov	byte [rel driver_rtc_date_and_time + DRIVER_RTC_STRUCTURE.minute],	al

	; fetch the number of hours
	mov	al,	DRIVER_RTC_PORT_hour
	out	DRIVER_RTC_PORT_command,	al
	in	al,	DRIVER_RTC_PORT_data

	; store
	mov	byte [rel driver_rtc_date_and_time + DRIVER_RTC_STRUCTURE.hour],	al

	; fetch the contents of register C
	mov	al,	DRIVER_RTC_PORT_STATUS_REGISTER_C
	out	DRIVER_RTC_PORT_command,	al
	in	al,	DRIVER_RTC_PORT_data

	; restore the original register
	pop	rax

	; return from the procedure
	ret
