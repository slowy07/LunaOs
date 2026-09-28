;===============================================================================

KERNEL_IPC_SIZE_page_default	equ	1
KERNEL_IPC_ENTRY_limit		equ	(KERNEL_IPC_SIZE_page_default << STATIC_PAGE_SIZE_shift) / KERNEL_IPC_STRUCTURE.SIZE

KERNEL_IPC_TTL_default		equ	DRIVER_RTC_Hz / 10	; ~100ms

kernel_ipc_semaphore		db	STATIC_FALSE
kernel_ipc_base_address		dq	STATIC_EMPTY
kernel_ipc_entry_count		dq	STATIC_EMPTY

;===============================================================================
; input:
;\trbx - PID of the target process
;\tecx - size of the data area in Bytes, or if the value is empty, 40 Bytes from the RSI pointer position
;\trsi - pointer to the data area
kernel_ipc_insert:
	; preserve the original registers
	push	rax
	push	rdx
	push	rsi
	push	rdi
	push	rcx

	; fetch the PID of the calling process
	call	kernel_task_active
	mov	rdx,	qword [rdi + KERNEL_TASK_STRUCTURE.pid]

.retry:
	; get the access to the message list
	macro_lock	kernel_ipc_semaphore, 0

	; fetch the current system time
	mov	rax,	qword [rel driver_rtc_microtime]

	; number of the available entries on the list
	mov	rcx,	KERNEL_IPC_ENTRY_limit

	; set the pointer to the beginning of the list
	mov	rdi,	qword [rel kernel_ipc_base_address]

.loop:
	; the entry has expired?
	cmp	rax,	qword [rdi + KERNEL_IPC_STRUCTURE.ttl]
	ja	.found	; yes

	; move the pointer to the next entry
	add	rdi,	KERNEL_IPC_STRUCTURE.SIZE

	; check the next entry?
	dec	rcx
	jnz	.loop	; yes

	; release the access to the message list
	mov	byte [rel kernel_ipc_semaphore],	STATIC_FALSE

	; check once more
	jmp	.retry

.found:
	; set the PID of the sender
	mov	qword [rdi + KERNEL_IPC_STRUCTURE.pid_source],	rdx

	; set the PID of the receiver
	mov	qword [rdi + KERNEL_IPC_STRUCTURE.pid_destination],	rbx

	; message type
	mov	bl,	byte [rsi + KERNEL_IPC_STRUCTURE.type]
	mov	byte [rdi + KERNEL_IPC_STRUCTURE.type],	bl

	; restore the original register
	mov	rcx,	qword [rsp]

	; the data area size is empty?
	test	rcx,	rcx
	jz	.load	; yes, fill the message with the data from the RSI pointer

	; set the data area size
	mov	qword [rdi + KERNEL_IPC_STRUCTURE.size],	rcx

	; set the pointer to the data area
	mov	qword [rdi + KERNEL_IPC_STRUCTURE.pointer],	rsi

	; end of creating the message for the process
	jmp	.end

.load:
	; save the pointer to the beginning of the entry
	push	rdi

	; load the content of the message
	mov	ecx,	KERNEL_IPC_STRUCTURE.SIZE - KERNEL_IPC_STRUCTURE.data
	add	rsi,	KERNEL_IPC_STRUCTURE.data
	add	rdi,	KERNEL_IPC_STRUCTURE.data
	rep	movsb

	; restore the pointer to the beginning of the entry
	pop	rdi

.end:
	; number of the messages on the list
	inc	qword [rel kernel_ipc_entry_count]

	; set the expiry time of the message
	add	rax,	KERNEL_IPC_TTL_default
	mov	qword [rdi + KERNEL_IPC_STRUCTURE.ttl],	rax

	; release the access
	mov	byte [rel kernel_ipc_semaphore],	STATIC_FALSE

	; restore the original registers
	pop	rcx
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rax

	; return from the procedure
	ret

	; information for Bochs
	macro_debug	"kernel_ipc_insert"

;===============================================================================
; input:
;\trdi - pointer to the destination location
; output:
;\tCF flag if there is no message
kernel_ipc_receive:
	; preserve the original registers
	push	rax
	push	rcx
	push	rsi
	push	rdi

	; are there any messages on the list?
	cmp	qword [rel kernel_ipc_entry_count],	STATIC_EMPTY
	je	.empty	; no

	; fetch the PID of the calling process
	call	kernel_task_active_pid

	; number of the available entries on the list
	mov	rcx,	KERNEL_IPC_ENTRY_limit

	; set the pointer to the beginning of the list
	mov	rsi,	qword [rel kernel_ipc_base_address]

	; fetch the current system time
	mov	rdi,	qword [rel driver_rtc_microtime]

.loop:
	; an entry for the process?
	cmp	qword [rsi + KERNEL_IPC_STRUCTURE.pid_destination],	rax
	jne	.next	; no

	; the message has expired?
	cmp	rdi,	qword [rsi + KERNEL_IPC_STRUCTURE.ttl]
	jbe	.found	; no

.next:
	; move the pointer to the next entry
	add	rsi,	KERNEL_IPC_STRUCTURE.SIZE

	; any entries left to review?
	dec	rcx
	jnz	.loop	; yes

	; no message for the process

.empty:
	; flag, error
	stc

	; end of the procedure
	jmp	.error

.found:
	; pass the message into the area of the process
	mov	ecx,	KERNEL_IPC_STRUCTURE.SIZE
	mov	rdi,	qword [rsp]
	rep	movsb

	; release the entry on the list
	mov	qword [rsi - KERNEL_IPC_STRUCTURE.SIZE],	STATIC_EMPTY

	; number of the messages on the list
	dec	qword [rel kernel_ipc_entry_count]

	; flag, success
	clc

.error:
	; restore the original registers
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rax

	; return from the procedure
	ret

	; information for Bochs
	macro_debug	"kernel_ipc_receive"
