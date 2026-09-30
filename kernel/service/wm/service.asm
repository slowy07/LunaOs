
; input:
;	ax - number of the procedure to execute
;	rsi - pointer to the object properties
kernel_wm_irq:
	; is the manager ready to process the reports?
	cmp byte [rel kernel_wm_semaphore], STATIC_FALSE
	je kernel_wm_irq ; no, wait

	; preserve the original registers
	push rax

	; disable the Direction Flag
	cld

	; destroy the object?
	cmp al, KERNEL_WM_WINDOW_close
	je .window_close ; yes

	; register a new object?
	cmp al, KERNEL_WM_WINDOW_create
	je .window_create ; yes

	; update the object properties?
	cmp al, KERNEL_WM_WINDOW_update
	je .window_update ; yes

.error:
	; flag, error
	stc

.end:
	; fetch the current processor flags
	pushf
	pop rax

	; return the flags to the process (remove those not taking part in the communication)
	and ax, KERNEL_TASK_EFLAGS_cf | KERNEL_TASK_EFLAGS_zf
	or word [rsp + KERNEL_TASK_STRUCTURE_IRETQ.eflags + STATIC_QWORD_SIZE_byte], ax

	; restore the original register
	pop rax

	; end of the software interrupt handling
	iretq

	macro_debug "kernel_wm_irq"

; input:
;	rsi - pointer to the window structure
.window_close:
	; preserve the original registers
	push rax
	push rbx
	push rsi

	; look for the object with the given identifier
	mov rbx, qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.id]
	call kernel_wm_object_by_id

	; fetch the process PID
	call kernel_task_active_pid

	; does the object belong to the process?
	cmp rax, qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.pid]
	jne .window_close_error ; no

	; remove the object from the list
	call kernel_wm_object_delete

	; end of the procedure
	jmp .window_close_end

.window_close_error:
	; flag, error
	stc

.window_close_end:
	; restore the original registers
	pop rsi
	pop rbx
	pop rax

	; end of the option handling
	jmp kernel_wm_irq.end

	macro_debug "kernel_wm_irq.window_close"


; input:
;	rsi - pointer to the object structure
; output:
;	CF flag - if there is not enough memory
;	rcx - object identifier
.window_create:
	; preserve the original registers
	push rax
	push rbx
	push rdx
	push rdi
	push rcx
	push rsi

	; prepare space for the object data
	mov ecx, dword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.size]
	call library_page_from_size
	call kernel_memory_alloc
	jc .window_create_end ; not enough memory

	; preserve the pointer to the kernel space
	push rdi

	; prepare space for the object data in the process
	call kernel_memory_alloc_task_secure
	jnc .window_create_allocated ; allocated

.window_create_failover:
	; release the local variable
	pop rdi

	; release the kernel space
	call kernel_memory_release

	; flag, error
	stc

	; end of the procedure handling
	jmp .window_create_end

.window_create_allocated:
	; map the kernel space into the process
	mov bx, KERNEL_PAGE_FLAG_user | KERNEL_PAGE_FLAG_write | KERNEL_PAGE_FLAG_available ; flags of the shared memory space
	mov rsi, qword [rsp]
	call kernel_page_map_virtual
	jc .window_create_failover ; no space for paging

	; remove the local variable
	add rsp, STATIC_QWORD_SIZE_byte

	; restore the pointer to the object properties
	mov rdx, qword [rsp]

	; return the address of the object space in the kernel
	mov qword [rdx + KERNEL_WM_STRUCTURE_OBJECT.address], rsi

	; allocate an identifier for the window
	call kernel_wm_object_id_new
	mov qword [rdx + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.id], rcx

	; place the window in the middle of the workbench space
	call .window_create_position

	; register the object
	mov rsi, rdx
	call kernel_wm_object_insert

	; mark the object as active
	mov qword [rel kernel_wm_object_active_pointer], rsi

	; preserve the pointer to the process space
	mov rsi, rdi

	; is the process a service?
	call kernel_task_active
	test word [rdi + KERNEL_TASK_STRUCTURE.flags], KERNEL_TASK_FLAG_service
	jnz .window_create_service ; yes

	; return the address of the window space in the process to the process
	mov qword [rdx + KERNEL_WM_STRUCTURE_OBJECT.address], rsi

.window_create_service:
	; return the object identifier
	mov qword [rsp + STATIC_QWORD_SIZE_byte], rcx

.window_create_end:
	; restore the original registers
	pop rsi
	pop rcx
	pop rdi
	pop rdx
	pop rbx
	pop rax

	; end of the option handling
	jmp kernel_wm_irq.end

	macro_debug "kernel_wm_irq.window_create"

.window_create_position:
	; position the object by default in the middle of the workbench space

	; X axis
	mov ax, word [rel kernel_video_width_pixel]
	mov bx, word [rdx + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.width]
	shr ax, STATIC_DIVIDE_BY_2_shift
	shr bx, STATIC_DIVIDE_BY_2_shift
	sub ax, bx
	mov word [rdx + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.x], ax

	; Y axis
	mov ax, word [rel kernel_video_height_pixel]
	mov bx, word [rdx + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.height]
	shr ax, STATIC_DIVIDE_BY_2_shift
	shr bx, STATIC_DIVIDE_BY_2_shift
	sub ax, bx
	mov word [rdx + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.y], ax

	; return from the subprocedure
	ret

; input:
;	rsi - pointer to the object structure
.window_update:
	; preserve the original registers
	push rax
	push rbx
	push rcx
	push rdi
	push rsi

	; look for the object with the given identifier
	mov rbx, qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.id]
	call kernel_wm_object_by_id

	; fetch the process PID
	call kernel_task_active_pid

	; does the object belong to the process?
	cmp rax, qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.pid]
	jne .window_flags_error ; no

	; update the window properties
	mov rbx, qword [rsp]

	; has the object data content changed?
	test word [rbx + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags], KERNEL_WM_OBJECT_FLAG_flush
	jz .unchanged ; no

	; preserve the information
	or word [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags], KERNEL_WM_OBJECT_FLAG_flush

.unchanged:
	; number of characters representing the window name
	mov cl, byte [rbx + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.length]
	mov byte [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.length], cl

	; object name
	mov ecx, KERNEL_WM_OBJECT_NAME_length
	mov rdi, rsi
	add rdi, KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.name
	mov rsi, rbx
	add rsi, KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.name
	rep movsb

	; preserve the time of the last modification of the list
	mov rax, qword [rel driver_rtc_microtime]
	mov qword [rel kernel_wm_object_list_modify_time], rax

	; end of the procedure
	jmp .window_flags_end

.window_flags_error:
	; flag, error
	stc

.window_flags_end:
	; restore the original registers
	pop rsi
	pop rdi
	pop rcx
	pop rbx
	pop rax

	; end of the option handling
	jmp kernel_wm_irq.end

	macro_debug "kernel_wm_irq.window_update"
