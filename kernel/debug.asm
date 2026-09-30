
struc KERNEL_DEBUG_STRUCTURE_PRESERVED
	.rax resb 8
	.rbx resb 8
	.rcx resb 8
	.rdx resb 8
	.rsi resb 8
	.rdi resb 8
	.rbp resb 8
	.r8 resb 8
	.r9 resb 8
	.r10 resb 8
	.r11 resb 8
	.r12 resb 8
	.r13 resb 8
	.r14 resb 8
	.r15 resb 8
	.eflags resb 8
	.SIZE:
endstruc

kernel_debug_string_welcome db "kernel debug dump", 13, 10
kernel_debug_string_welcome_end:
kernel_debug_string_process_name db "process name (pid): "
kernel_debug_string_process_name_end:
kernel_debug_string_pid db " ("
kernel_debug_string_pid_end:
kernel_debug_string_pid_close db ")", 13, 10
kernel_debug_string_pid_close_end:
kernel_debug_string_eflags db "eflags ", 13, 10, "    "
kernel_debug_string_eflags_end:
kernel_debug_string_rip db "rip ", 13, 10, "    "
kernel_debug_string_rip_end:
kernel_debug_string_rax db "rax "
kernel_debug_string_rax_end:
kernel_debug_string_rbx db 13, 10, "rbx "
kernel_debug_string_rbx_end:
kernel_debug_string_rcx db 13, 10, "rcx "
kernel_debug_string_rcx_end:
kernel_debug_string_rdx db 13, 10, "rdx "
kernel_debug_string_rdx_end:
kernel_debug_string_rsi db 13, 10, "rsi "
kernel_debug_string_rsi_end:
kernel_debug_string_rdi db 13, 10, "rdi "
kernel_debug_string_rdi_end:
kernel_debug_string_rbp db 13, 10, "rbp "
kernel_debug_string_rbp_end:
kernel_debug_string_r8 db 13, 10, "r8  "
kernel_debug_string_r8_end:
kernel_debug_string_r9 db 13, 10, "r9  "
kernel_debug_string_r9_end:
kernel_debug_string_r10 db 13, 10, "r10 "
kernel_debug_string_r10_end:
kernel_debug_string_r11 db 13, 10, "r11 "
kernel_debug_string_r11_end:
kernel_debug_string_r12 db 13, 10, "r12 "
kernel_debug_string_r12_end:
kernel_debug_string_r13 db 13, 10, "r13 "
kernel_debug_string_r13_end:
kernel_debug_string_r14 db 13, 10, "r14 "
kernel_debug_string_r14_end:
kernel_debug_string_r15 db 13, 10, "r15 "
kernel_debug_string_r15_end:

; input:
;	al - character to output
;	COM1 port must be initialised and the interrupts disabled
kernel_debug_serial_char:
	; preserve the original registers
	push rax
	push rdx

	; wait for the controller to become ready
	call driver_serial_ready

	; send the character to the port
	mov dx, DRIVER_SERIAL_PORT_COM1 + DRIVER_SERIAL_STRUCTURE_REGISTERS.data_or_divisor_low
	out dx, al

	; restore the original registers
	pop rdx
	pop rax

	; return from the procedure
	ret

; input:
;	rsi - pointer to the output data
;	ecx - number of characters to output
;	COM1 port must be initialised and the interrupts disabled
kernel_debug_serial_string:
	; preserve the original registers
	push rax
	push rcx
	push rsi

.loop:
	; fetch the character
	lodsb

	; send it to the port
	call kernel_debug_serial_char

	; output the rest of the data
	loop .loop

	; restore the original registers
	pop rsi
	pop rcx
	pop rax

	; return from the procedure
	ret

; input:
;	rax - value to output as hexadecimal digits
;	COM1 port must be initialised and the interrupts disabled
kernel_debug_serial_hex:
	; preserve the original registers
	push rax
	push rcx
	push rdx
	push rsi

	; keep the value in rsi so that al is free to carry the ASCII digit
	mov rsi, rax

	; all hexadecimal digits
	mov rcx, 16

.loop:
	; rotate the highest digit into the lowest position
	rol rsi, 4

	; extract the digit
	mov dl, sil
	and dl, 0x0F

	; convert to the ASCII code
	cmp dl, 10
	jb .digit
	add dl, 'A' - '0' - 10
.digit:
	add dl, '0'

	; output the digit
	mov al, dl
	call kernel_debug_serial_char

	; output the rest of the digits
	dec rcx
	jnz .loop

	; restore the original registers
	pop rsi
	pop rdx
	pop rcx
	pop rax

	; return from the procedure
	ret

; dump of the faulting context on the COM1 port
; input:
;	the CPU-pushed exception frame on the stack (an error code may precede it)
; the procedure preserves every register
kernel_debug_dump:
	; break into the Bochs debugger
	xchg bx, bx

	; preserve the faulting state
	pushf
	push r15
	push r14
	push r13
	push r12
	push r11
	push r10
	push r9
	push r8
	push rbp
	push rdi
	push rsi
	push rdx
	push rcx
	push rbx
	push rax

	; disable the interrupts and exceptions for the duration of the dump
	cli

	; locate the exception frame (the return address of the call separates it from the preserved area)
	lea rbp, [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.SIZE + STATIC_QWORD_SIZE_byte]

	; a code selector at the .cs position means the frame has no error code
	cmp qword [rbp + KERNEL_TASK_STRUCTURE_IRETQ.cs], KERNEL_STRUCTURE_GDT.cs_ring0
	je .frame
	cmp qword [rbp + KERNEL_TASK_STRUCTURE_IRETQ.cs], KERNEL_STRUCTURE_GDT.cs_ring3
	je .frame

	; shift the frame pointer over the error code
	add rbp, STATIC_QWORD_SIZE_byte
.frame:

	; header
	mov ecx, kernel_debug_string_welcome_end - kernel_debug_string_welcome
	mov rsi, kernel_debug_string_welcome
	call kernel_debug_serial_string

	; name and identifier of the faulting process
	call kernel_task_active

	; the procedure ends by re-enabling the interrupts - disable them again
	; for the duration of the dump
	cli

	test rdi, rdi
	jz .process_done

	mov ecx, kernel_debug_string_process_name_end - kernel_debug_string_process_name
	mov rsi, kernel_debug_string_process_name
	call kernel_debug_serial_string

	movzx ecx, byte [rdi + KERNEL_TASK_STRUCTURE.length]
	lea rsi, [rdi + KERNEL_TASK_STRUCTURE.name]
	call kernel_debug_serial_string

	mov ecx, kernel_debug_string_pid_end - kernel_debug_string_pid
	mov rsi, kernel_debug_string_pid
	call kernel_debug_serial_string

	mov rax, qword [rdi + KERNEL_TASK_STRUCTURE.pid]
	call kernel_debug_serial_hex

	mov ecx, kernel_debug_string_pid_close_end - kernel_debug_string_pid_close
	mov rsi, kernel_debug_string_pid_close
	call kernel_debug_serial_string
.process_done:

	; flags and the instruction pointer of the faulting context
	mov ecx, kernel_debug_string_eflags_end - kernel_debug_string_eflags
	mov rsi, kernel_debug_string_eflags
	call kernel_debug_serial_string
	mov rax, qword [rbp + KERNEL_TASK_STRUCTURE_IRETQ.eflags]
	call kernel_debug_serial_hex

	mov ecx, kernel_debug_string_rip_end - kernel_debug_string_rip
	mov rsi, kernel_debug_string_rip
	call kernel_debug_serial_string
	mov rax, qword [rbp + KERNEL_TASK_STRUCTURE_IRETQ.rip]
	call kernel_debug_serial_hex

	; general purpose registers
	mov ecx, kernel_debug_string_rax_end - kernel_debug_string_rax
	mov rsi, kernel_debug_string_rax
	call kernel_debug_serial_string
	mov rax, qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.rax]
	call kernel_debug_serial_hex

	mov ecx, kernel_debug_string_rbx_end - kernel_debug_string_rbx
	mov rsi, kernel_debug_string_rbx
	call kernel_debug_serial_string
	mov rax, qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.rbx]
	call kernel_debug_serial_hex

	mov ecx, kernel_debug_string_rcx_end - kernel_debug_string_rcx
	mov rsi, kernel_debug_string_rcx
	call kernel_debug_serial_string
	mov rax, qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.rcx]
	call kernel_debug_serial_hex

	mov ecx, kernel_debug_string_rdx_end - kernel_debug_string_rdx
	mov rsi, kernel_debug_string_rdx
	call kernel_debug_serial_string
	mov rax, qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.rdx]
	call kernel_debug_serial_hex

	mov ecx, kernel_debug_string_rsi_end - kernel_debug_string_rsi
	mov rsi, kernel_debug_string_rsi
	call kernel_debug_serial_string
	mov rax, qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.rsi]
	call kernel_debug_serial_hex

	mov ecx, kernel_debug_string_rdi_end - kernel_debug_string_rdi
	mov rsi, kernel_debug_string_rdi
	call kernel_debug_serial_string
	mov rax, qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.rdi]
	call kernel_debug_serial_hex

	mov ecx, kernel_debug_string_rbp_end - kernel_debug_string_rbp
	mov rsi, kernel_debug_string_rbp
	call kernel_debug_serial_string
	mov rax, qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.rbp]
	call kernel_debug_serial_hex

	mov ecx, kernel_debug_string_r8_end - kernel_debug_string_r8
	mov rsi, kernel_debug_string_r8
	call kernel_debug_serial_string
	mov rax, qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.r8]
	call kernel_debug_serial_hex

	mov ecx, kernel_debug_string_r9_end - kernel_debug_string_r9
	mov rsi, kernel_debug_string_r9
	call kernel_debug_serial_string
	mov rax, qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.r9]
	call kernel_debug_serial_hex

	mov ecx, kernel_debug_string_r10_end - kernel_debug_string_r10
	mov rsi, kernel_debug_string_r10
	call kernel_debug_serial_string
	mov rax, qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.r10]
	call kernel_debug_serial_hex

	mov ecx, kernel_debug_string_r11_end - kernel_debug_string_r11
	mov rsi, kernel_debug_string_r11
	call kernel_debug_serial_string
	mov rax, qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.r11]
	call kernel_debug_serial_hex

	mov ecx, kernel_debug_string_r12_end - kernel_debug_string_r12
	mov rsi, kernel_debug_string_r12
	call kernel_debug_serial_string
	mov rax, qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.r12]
	call kernel_debug_serial_hex

	mov ecx, kernel_debug_string_r13_end - kernel_debug_string_r13
	mov rsi, kernel_debug_string_r13
	call kernel_debug_serial_string
	mov rax, qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.r13]
	call kernel_debug_serial_hex

	mov ecx, kernel_debug_string_r14_end - kernel_debug_string_r14
	mov rsi, kernel_debug_string_r14
	call kernel_debug_serial_string
	mov rax, qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.r14]
	call kernel_debug_serial_hex

	mov ecx, kernel_debug_string_r15_end - kernel_debug_string_r15
	mov rsi, kernel_debug_string_r15
	call kernel_debug_serial_string
	mov rax, qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.r15]
	call kernel_debug_serial_hex

	; end of the dump
	mov al, 13
	call kernel_debug_serial_char
	mov al, 10
	call kernel_debug_serial_char

	; restore the faulting state
	pop rax
	pop rbx
	pop rcx
	pop rdx
	pop rsi
	pop rdi
	pop rbp
	pop r8
	pop r9
	pop r10
	pop r11
	pop r12
	pop r13
	pop r14
	pop r15
	popf

	; return from the procedure
	ret

	macro_debug "kernel_debug_dump"