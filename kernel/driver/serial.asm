
DRIVER_SERIAL_PORT_COM1 equ 0x03F8
DRIVER_SERIAL_PORT_COM2 equ 0x02F8

struc DRIVER_SERIAL_STRUCTURE_REGISTERS
	.data_or_divisor_low resb 1
	.interrupt_enable_or_divisor_high resb 1
	.interrupt_identification_or_fifo resb 1
	.line_control_or_dlab resb 1
	.modem_control resb 1
	.line_status resb 1
	.modem_status resb 1
	.scratch resb 1
endstruc

driver_serial:
	; preserve the original registers
	push rax
	push rdx

	; disable interrupt generation
	mov al, 0x00
	mov dx, DRIVER_SERIAL_PORT_COM1 + DRIVER_SERIAL_STRUCTURE_REGISTERS.interrupt_enable_or_divisor_high
	out dx, al

	; enable DLAB (divisor latch)
	mov al, 0x80
	mov dx, DRIVER_SERIAL_PORT_COM1 + DRIVER_SERIAL_STRUCTURE_REGISTERS.line_control_or_dlab
	out dx, al

	; baud rate 115200
	mov al, 0x03
	mov dx, DRIVER_SERIAL_PORT_COM1 + DRIVER_SERIAL_STRUCTURE_REGISTERS.data_or_divisor_low
	out dx, al
	mov al, 0x00
	mov dx, DRIVER_SERIAL_PORT_COM1 + DRIVER_SERIAL_STRUCTURE_REGISTERS.interrupt_enable_or_divisor_high
	out dx, al

	; 8 bits per character, no parity, 1 stop bit
	mov al, 0x03
	mov dx, DRIVER_SERIAL_PORT_COM1 + DRIVER_SERIAL_STRUCTURE_REGISTERS.line_control_or_dlab
	out dx, al

	; enable the FIFO, clear it, 14 byte trigger
	mov al, 0xC7
	mov dx, DRIVER_SERIAL_PORT_COM1 + DRIVER_SERIAL_STRUCTURE_REGISTERS.interrupt_identification_or_fifo
	out dx, al

	; restore the original registers
	pop rdx
	pop rax

	; return from the procedure
	ret

; input:
;	rsi - pointer to the data terminated with a zero byte
driver_serial_send:
	; preserve the original registers
	push rax
	push rdx
	push rsi

	; output port number
	mov dx, DRIVER_SERIAL_PORT_COM1 + DRIVER_SERIAL_STRUCTURE_REGISTERS.data_or_divisor_low

.loop:
	; fetch a character from the string
	lodsb

	; end of the string?
	test al, al
	jz .end ; yes

	; wait for the controller to become ready
	call driver_serial_ready

	; send the character to the port
	out dx, al

	; display the rest of the string data
	jmp .loop

.end:
	; restore the original registers
	pop rsi
	pop rdx
	pop rax

	; return from the procedure
	ret


driver_serial_ready:
	; preserve the original registers
	push rax
	push rdx

	; set the port
	mov dx, DRIVER_SERIAL_PORT_COM1 + DRIVER_SERIAL_STRUCTURE_REGISTERS.line_status

.loop:
	; fetch the controller state
	in al, dx

	; buffer empty?
	test al, 01100000b
	jz .loop ; no

	; restore the original registers
	pop rdx
	pop rax

	; return from the procedure
	ret
