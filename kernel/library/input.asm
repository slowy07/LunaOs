
; input:
;	rbx - buffer size
;	rcx - number of characters in the buffer
;	rdx - exception handler procedure
;	rsi - pointer to the buffer area
;	rdi - pointer to the IPC area
; output:
;	CF flag - the user aborted the input (e.g. the ESC key) or the buffer is empty
;	rcx - number of characters in the string
;	rsi - pointer to the buffer
library_input:
	; preserve the original registers
	push rax
	push rbx
	push rdx
	push rcx

	; display the buffer content?
	test rcx, rcx
	jz .entry ; no

	; display the buffer content
	mov ax, KERNEL_SERVICE_PROCESS_stream_out
	int KERNEL_SERVICE

.entry:
	; clear the accumulator
	xor eax, eax

	; amount of free space in the buffer
	sub rbx, rcx

.loop:
	; release the remaining processor time
	mov ax, KERNEL_SERVICE_PROCESS_release
	int KERNEL_SERVICE

	; fetch the "character from the keyboard buffer" message
	mov ax, KERNEL_SERVICE_PROCESS_ipc_receive
	int KERNEL_SERVICE
	jc .loop ; no message

	; message of type: keyboard?
	cmp byte [rdi + KERNEL_IPC_STRUCTURE.type], KERNEL_IPC_TYPE_KEYBOARD
	je .keyboard ; yes

	; handle the message
	call qword [rsp + STATIC_QWORD_SIZE_byte]

	; continue
	jmp .loop

.keyboard:
	; fetch the key code
	mov dx, word [rdi + KERNEL_IPC_STRUCTURE.data]

	; key of type Backspace?
	cmp dx, STATIC_SCANCODE_BACKSPACE
	je .key_backspace

	; key of type Enter?
	cmp dx, STATIC_SCANCODE_RETURN
	je .key_enter

	; key of type ESC?
	cmp dx, STATIC_SCANCODE_ESCAPE
	je .empty ; finish the library

	; character allowed?

	; check whether the fetched character can be displayed
	cmp dx, STATIC_SCANCODE_SPACE
	jb .loop ; no, ignore
	cmp dx, STATIC_SCANCODE_TILDE
	ja .loop ; no, ignore

	; buffer full?
	test rbx, rbx
	jz .loop ; yes

	; store the character in the buffer
	mov byte [rsi + rcx], dl

	; remaining space in the buffer
	dec rbx

	; number of characters in the buffer
	inc rcx

.print:
	; preserve the character count in the buffer
	push rcx

	; display the character on the terminal
	mov ax, KERNEL_SERVICE_PROCESS_stream_out_char
	mov ecx, 0x01 ; once
	int KERNEL_SERVICE

	; restore the character count in the buffer
	pop rcx

	; continue
	jmp .loop

.key_backspace:
	; buffer empty?
	test rcx, rcx
	jz .loop ; yes

	; number of characters in the buffer
	dec rcx

	; size of the available buffer
	inc rbx

	; display the backspace key
	jmp .print

.key_enter:
	; buffer empty?
	test rcx, rcx
	jz .empty ; yes

	; return the number of characters in the buffer
	mov qword [rsp], rcx

	; flag, success
	clc

	; end of library
	jmp .end

.empty:
	; flag, error
	stc

.end:
	; restore the original registers
	pop rcx
	pop rdx
	pop rbx
	pop rax

	; return from the library
	ret

	macro_debug "library_input"
