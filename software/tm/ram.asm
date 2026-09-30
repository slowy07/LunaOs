
tm_ram:
	; save the original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r8
	push	r9
	push	r10

	; fetch the RAM space information
	mov	ax,	KERNEL_SERVICE_SYSTEM_memory
	int	KERNEL_SERVICE

	; set the cursor to the "total" position
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_memory_total_position_and_color_end - tm_string_memory_total_position_and_color
	mov	rsi,	tm_string_memory_total_position_and_color
	int	KERNEL_SERVICE

	; display the value in KiB
	mov	rax,	r8
	call	.show

	; set the cursor to the "free" position
	mov	ecx,	tm_string_memory_total_end - tm_string_memory_total
	mov	rsi,	tm_string_memory_total
	int	KERNEL_SERVICE

	; display the value in KiB
	mov	rax,	r9
	call	.show

	; set the cursor to the "used" position
	mov	ecx,	tm_string_memory_free_end - tm_string_memory_free
	mov	rsi,	tm_string_memory_free
	int	KERNEL_SERVICE

	; display the value in KiB
	mov	rax,	r8
	sub	rax,	r9
	call	.show

	; terminate
	mov	ecx,	tm_string_memory_used_end - tm_string_memory_used
	mov	rsi,	tm_string_memory_used
	int	KERNEL_SERVICE

	; restore the original registers
	pop	r10
	pop	r9
	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; return from the procedure
	ret

	macro_debug	"software: tm_ram"

; entry:
;	rax - value to display in KiB
.show:
	; convert the total size of the space into KiB
	shl	rax,	STATIC_MULTIPLE_BY_PAGE_shift	; convert pages into bytes
	mov	ecx,	1024
	xor	edx,	edx
	div	rcx	; convert the KiB

	; display the value
	mov	qword [tm_string_number.value],	rax
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	byte [tm_string_number.prefix],	STATIC_EMPTY
	mov	ecx,	tm_string_number_end - tm_string_number
	mov	rsi,	tm_string_number
	int	KERNEL_SERVICE

	; return from the subprocedure
	ret

	macro_debug	"software: tm_ram.show"
