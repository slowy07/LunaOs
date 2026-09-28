;===============================================================================

;===============================================================================
kernel_service:
	; preserve the original registers
	push	rbp
	push	rax

	; reset the Direction Flag
	cld

	; a process related service?
	cmp	al,	KERNEL_SERVICE_PROCESS
	je	.process	; yes

	; the virtual file system handler?
	cmp	al,	KERNEL_SERVICE_VFS
	je	.vfs	; yes

	; the system handler?
	cmp	al,	KERNEL_SERVICE_SYSTEM
	je	.system	; yes

.error:
	; flag, error
	stc

.end:
	; fetch the current processor flags
	pushf
	pop	rax

	; return the flags to the process
	mov	qword [rsp + KERNEL_TASK_STRUCTURE_IRETQ.eflags + STATIC_QWORD_SIZE_byte * 0x02],	rax

	; restore the original registers
	pop	rax
	pop	rbp

	; end of the software interrupt handling
	iretq

	macro_debug	"kernel_service"

;===============================================================================
.process:
	; finish the work of the process?
	cmp	ax,	KERNEL_SERVICE_PROCESS_exit
	je	kernel_task_kill	; yes

	; start a new process?
	cmp	ax,	KERNEL_SERVICE_PROCESS_run
	je	.process_run	; yes

	; does the process exist?
	cmp	ax,	KERNEL_SERVICE_PROCESS_check
	je	.process_check	; yes

	; allocate a memory area?
	cmp	ax,	KERNEL_SERVICE_PROCESS_memory_alloc
	je	.process_memory_alloc	; yes

	; receive a message addressed to the process?
	cmp	ax,	KERNEL_SERVICE_PROCESS_ipc_receive
	je	.process_ipc_receive	; yes

	; send a message to another process?
	cmp	ax,	KERNEL_SERVICE_PROCESS_ipc_send
	je	.process_ipc_send	; yes

	; send a message to the parent?
	cmp	ax,	KERNEL_SERVICE_PROCESS_ipc_send_to_parent
	je	.process_ipc_send_parent	; yes

	; return the PID of the process?
	cmp	ax,	KERNEL_SERVICE_PROCESS_pid
	je	.process_pid	; yes

	; return the PID of the parent process?
	cmp	ax,	KERNEL_SERVICE_PROCESS_pid_parent
	je	.process_pid_parent	; yes

	; pass a string to the standard output?
	cmp	ax,	KERNEL_SERVICE_PROCESS_stream_out
	je	.process_stream_out	; yes

	; fetch a string from the standard input?
	cmp	ax,	KERNEL_SERVICE_PROCESS_stream_in
	je	.process_stream_in	; yes

	; pass a single Byte to the standard output?
	cmp	ax,	KERNEL_SERVICE_PROCESS_stream_out_char
	je	.process_stream_out_char	; yes

	; process the metadata of the stream?
	cmp	ax,	KERNEL_SERVICE_PROCESS_stream_meta
	je	.process_stream_meta	; yes

	; return the list of the started processes?
	cmp	ax,	KERNEL_SERVICE_PROCESS_list
	je	.process_list	; yes

	; release the area of the process?
	cmp	ax,	KERNEL_SERVICE_PROCESS_memory_release
	je	.process_memory_release	; yes

	; stop the process for a given time?
	cmp	ax,	KERNEL_SERVICE_PROCESS_sleep
	je	.process_sleep	; yes

	; release the remaining processor time?
	cmp	ax,	KERNEL_SERVICE_PROCESS_release
	je	.process_release	; yes

	; change the working directory of the process?
	cmp	ax,	KERNEL_SERVICE_PROCESS_dir_change
	je	.process_dir_change	; yes

	; end of the subprocedure handling
	jmp	kernel_service.error

;-------------------------------------------------------------------------------
; output:
;\trcx - PID of the parent process
.process_pid_parent:
	; preserve the original registers
	push	rdi

	; return the PID of the parent
	call	kernel_task_active
	mov	rcx,	qword [rdi + KERNEL_TASK_STRUCTURE.parent]

	; restore the original registers
	pop	rdi

	; end of the option handling
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_pid_parent"

;-------------------------------------------------------------------------------
; input:
;\tbl - stream behaviour of the process
;\trcx - number of characters in the path to the file
;\trsi - pointer to the string representing the path to the file
;\tr8 - size of the arguments in Bytes
; output:
;\trcx - PID of the started process
.process_run:
	; preserve the original registers
	push	rsi
	push	rdi
	push	rcx

	; resolve the path to the program
	call	kernel_vfs_path_resolve
	jc	.process_run_end	; error, invalid path

	; look for the program in the given directory
	call	kernel_vfs_file_find
	jc	.process_run_end	; error, the file was not found

	; start the program
	;\trcx - number of characters representing the name of the program to run
	;\trsi - pointer to the program name together with the arguments
	;\trdi - pointer to the file spool
	;\tr8 - size of the arguments in Bytes
	call	kernel_exec
	jc	.process_run_end	; the program added to the task queue

	; return the identifier of the started process
	mov	qword [rsp],	rcx

	; prepare the pipes
	call	kernel_stream_set
	jc	.process_run_end	; the input/output streams could not be attached

	; mark the process as ready to be processed
	or	word [rdi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_active

.process_run_end:
	; restore the original registers
	pop	rcx
	pop	rdi
	pop	rsi

	; end of the option handling
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_run"

;-------------------------------------------------------------------------------
.process_check:
	; look for the process in the task queue
	call	kernel_task_pid_check

	; end of the option handling
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_check"

;-------------------------------------------------------------------------------
; input:
;\trcx - size of the area to allocate
;\trdi - pointer to the kernel address space
; output:
;\tCF flag - if there is no space
;\trdi - pointer to the allocated area
.process_memory_alloc:
	; preserve the original registers
	push	rbx
	push	rcx
	push	r8
	push	r11
	push	rax
	push	rdi

	; convert the size of the area into pages
	call	library_page_from_size

	; allocate the memory area of the given size for the process
	call	kernel_memory_alloc_task

	; return the address of the allocated area
	mov	qword [rsp],	rdi

.process_memory_alloc_end:
	; restore the original registers
	pop	rdi
	pop	rax
	pop	r11
	pop	r8
	pop	rcx
	pop	rbx

	; end of the option handling
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_memory_alloc"

;-------------------------------------------------------------------------------
; input:
;\trdi - pointer to the destination of the message
; output:
;\tCF flag, if there is no message
.process_ipc_receive:
	; fetch the message addressed to the process
	call	kernel_ipc_receive

	; end of the option handling
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_ipc_receive"

;-------------------------------------------------------------------------------
; input:
;\trbx - PID of the target process
;\tecx - size of the data area in Bytes, or if the value is empty, 40 Bytes from the RSI pointer position
;\trsi - pointer to the data area
; output:
;\tCF flag - if the queue has overflowed
.process_ipc_send:
	; send the message to the process
	call	kernel_ipc_insert

	; end of the option handling
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_ipc_send"

;-------------------------------------------------------------------------------
; input:
;\tecx - size of the data area in Bytes, or if the value is empty, 40 Bytes from the RSI pointer position
;\trsi - pointer to the data area
; output:
;\tCF flag - if the queue has overflowed
.process_ipc_send_parent:
	; preserve the original registers
	push	rdi

	; fetch the PID of the parent process
	call	kernel_task_active
	mov	rbx,	qword [rdi + KERNEL_TASK_STRUCTURE.parent]

	; restore the original registers
	pop	rdi

	; send the message to the process
	call	kernel_ipc_insert

	; end of the option handling
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_ipc_send_parent"

;-------------------------------------------------------------------------------
; output:
;\trax - PID of the process
.process_pid:
	; fetch the PID of the process
	call	kernel_task_active_pid

	; return to the process
	mov	qword [rsp],	rax

	; end of the option handling
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_pid"

;-------------------------------------------------------------------------------
; input:
;\trcx - size of the string in Bytes
;\trsi - pointer to the string
.process_stream_out:
	; preserve the original registers
	push	rbx
	push	rdi

	; no string for the stream?
	test	rcx,	rcx
	jz	.process_stream_out_end	 ; yes

	; fetch the identifier of the output stream of the process
	call	kernel_task_active
	mov	rbx,	qword [rdi + KERNEL_TASK_STRUCTURE.out]

	; send the string to the standard output
	call	kernel_stream_insert

.process_stream_out_end:
	; restore the original registers
	pop	rdi
	pop	rbx

	; end of the option handling
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_stream_out"

;-------------------------------------------------------------------------------
; input:
;\trdi - pointer to the buffer area
; output:
;\tZF flag - if there is no data
;\trcx - number of the transferred data
.process_stream_in:
	; preserve the original registers
	push	rbx
	push	rdi

	; fetch the identifier of the input stream of the process
	call	kernel_task_active
	mov	rbx,	qword [rdi + KERNEL_TASK_STRUCTURE.in]

	; send the string to the standard output
	pop	rdi	; restore the destination address of the buffer of the process
	call	kernel_stream_receive

	; no data?
	test	rcx,	rcx

	; restore the original register
	pop	rbx

	; end of the option handling
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_stream_in"

;-------------------------------------------------------------------------------
; input:
;\trcx - how many copies of the character to send
;\tdl - value
.process_stream_out_char:
	; preserve the original registers
	push	rbx
	push	rcx
	push	rsi
	push	rdi
	push	rdx	; leave the character on the stack

	; any characters left to send to the stream?
	test	rcx,	rcx
	jz	.process_stream_out_char_end	; yes

	; fetch the identifier of the output stream of the process
	call	kernel_task_active
	mov	rbx,	qword [rdi + KERNEL_TASK_STRUCTURE.out]

	; display the character N times
	mov	rdx,	rcx
	mov	ecx,	STATIC_BYTE_SIZE_byte
	mov	rsi,	rsp

.process_stream_out_char_loop:
	; send the value to the standard output
	call	kernel_stream_insert

	; were all the copies of the character sent?
	dec	rdx
	jnz	.process_stream_out_char_loop	; no

.process_stream_out_char_end:
	; restore the original registers
	pop	rdx	; restore the character from the stack
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx

	; end of the option handling
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_stream_out_char"

;===============================================================================
; input:
;\tbl - read or write
;\trsi - source pointer of the data
; or
;\trdi - destination pointer of the data
.process_stream_meta:
	; preserve the original registers
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	; size of the metadata area
	mov	rcx,	KERNEL_STREAM_META_SIZE_byte

	; set the pointer to the properties of the process
	call	kernel_task_active

	; default stream: output
	mov	rdx,	qword [rdi + KERNEL_TASK_STRUCTURE.out]

	; the output stream?
	test	bl,	KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_out
	jnz	.process_stream_meta_selected	; yes

	; choose the stream: input
	mov	rdx,	qword [rdi + KERNEL_TASK_STRUCTURE.in]

.process_stream_meta_selected:
	; store the data?
	test	bl,	KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_set
	jz	.process_stream_meta_read	; no

	; store the data into the metadata stream
	mov	rdi,	rdx
	add	rdi,	KERNEL_STREAM_STRUCTURE_ENTRY.meta
	rep	movsb

	; raise the flag, the metadata are up to date
	or	byte [rdx + KERNEL_STREAM_STRUCTURE_ENTRY.flags],	KERNEL_STREAM_FLAG_meta

	; end of the handling
	jmp	.process_stream_meta_end

.process_stream_meta_read:
	; the metadata are up to date?
	test	byte [rdx + KERNEL_STREAM_STRUCTURE_ENTRY.flags],	KERNEL_STREAM_FLAG_meta
	jz	.process_stream_meta_error

	; send the metadata to the process
	mov	rsi,	rdx
	add	rsi,	KERNEL_STREAM_STRUCTURE_ENTRY.meta
	mov	rdi,	qword [rsp]
	rep	movsb

	; end of the procedure handling
	jmp	.process_stream_meta_end

.process_stream_meta_error:
	; flag, error
	stc

.process_stream_meta_end:
	; restore the original registers
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx

	; end of the option handling
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_stream_meta"

;-------------------------------------------------------------------------------
; output:
;\trbx - number of the entries
;\trcx - size of the list in Bytes
;\trsi - pointer to the area of the list
.process_list:
	; preserve the original registers
	push	rax
	push	rdi
	push	rcx

	; allocate the area for the process
	mov	rcx,	qword [rel kernel_task_size_page]
	call	kernel_memory_alloc_task
	jc	.process_list_end	; no available area

	; save the pointer to the beginning and the size of the area
	push	rcx
	push	rdi

	; number of the entries transferred to the process
	xor	ebx,	ebx

	; complete the list with all the processes registered in the serpentine
	mov	rsi,	qword [rel kernel_task_address]

.process_list_reload:
	; number of the entries in a block of the serpentine
	mov	cl,	STATIC_STRUCTURE_BLOCK.link / KERNEL_TASK_STRUCTURE.SIZE

.process_list_loop:
	; the entry is empty?
	cmp	word [rsi + KERNEL_TASK_STRUCTURE.flags],	STATIC_EMPTY
	je	.process_list_next	; yes

	; is the process active?
	test	word [rsi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_active
	jz	.process_list_next	; no, ignore

	; save the pointer and the number of the entries to process in the serpentine block
	push	rcx
	push	rsi

	; send the dedicated information about the process

	; PID of the process
	mov	rax,	qword [rsi + KERNEL_TASK_STRUCTURE.pid]
	stosq

	; PID of the parent
	mov	rax,	qword [rsi + KERNEL_TASK_STRUCTURE.parent]
	stosq

	; number of the logical processor processing the process
	mov	rax,	qword [rsi + KERNEL_TASK_STRUCTURE.cpu]
	stosq

	; start time of the process in the Microtime format
	mov	rax,	qword [rsi + KERNEL_TASK_STRUCTURE.time]
	stosq

	; unused processor time in the APIC format
	mov	eax,	dword [rsi + KERNEL_TASK_STRUCTURE.apic]
	stosd

	; size of the memory area used by the process (without the page tables)
	mov	rax,	qword [rsi + KERNEL_TASK_STRUCTURE.memory]
	stosq

	; spool of the working directory of the process
	mov	rax,	qword [rsi + KERNEL_TASK_STRUCTURE.knot]
	stosq

	; state flags of the process
	mov	ax,	word [rsi + KERNEL_TASK_STRUCTURE.flags]
	stosw

	; number of the characters representing the process name
	movzx	eax,	byte [rsi + KERNEL_TASK_STRUCTURE.length]
	stosb

	; name of the process
	mov	ecx,	eax
	add	rsi,	KERNEL_TASK_STRUCTURE.name
	rep	movsb

	; restore the pointer and the number of the entries to process in the serpentine block
	pop	rsi
	pop	rcx

	; the information about the process has been loaded
	inc	rbx

.process_list_next:
	; next entry from the list
	add	rsi,	KERNEL_TASK_STRUCTURE.SIZE

	; end of the entries in the block?
	dec	cl
	jnz	.process_list_loop	; no

	; fetch the address of the next block of the serpentine
	and	si,	STATIC_PAGE_mask
	mov	rsi,	qword [rsi + STATIC_STRUCTURE_BLOCK.link]

	; end of the serpentine?
	cmp	rsi,	qword [rel kernel_task_address]
	jne	.process_list_reload	; no

	; return the address of the area of the process list
	pop	rsi
	pop	rcx	; and its size in Bytes
	shl	rcx,	STATIC_MULTIPLE_BY_PAGE_shift
	mov	qword [rsp],	rcx

.process_list_end:
	; restore the original registers
	pop	rcx
	pop	rdi
	pop	rax

	; end of the option handling
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_list"

;===============================================================================
; input:
;\trcx - size of the area in Bytes
;\trdi - pointer to the area
.process_memory_release:
	; preserve the original registers
	push	rax
	push	rcx
	push	r11
	push	rdi

	; address of the area to release
	mov	rax,	rdi

	; page table of the process
	mov	r11,	cr3

	; size of the area in pages
	call	library_page_from_size

	; release the area
	call	kernel_memory_release_task

	; release the area in the binary memory map of the process
	mov	rdi,	qword [rsp]
	call	kernel_memory_release_task_secured

	; restore the original registers
	pop	rdi
	pop	r11
	pop	rcx
	pop	rax

	; end of the option handling
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_memory_release"

;-------------------------------------------------------------------------------
; input:
;\trcx - number of the milliseconds
;\t1 second = 1024 microtime ticks
.process_sleep:
	; preserve the original registers
	push	rcx
	push	rdi

	; fetch the process pointer
	call	kernel_task_active

	; mark the process as sleeping
	or	word [rdi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_sleep

	; set the wake up time of the process
	add	rcx,	qword [rel driver_rtc_microtime]

.process_sleep_wait:
	; preemption
	int	KERNEL_APIC_IRQ_number

	; wake the process up?
	cmp	rcx,	qword [rel driver_rtc_microtime]
	ja	.process_sleep_wait	; no

	; remove the information about the sleep of the process
	and	word [rdi + KERNEL_TASK_STRUCTURE.flags],	~KERNEL_TASK_FLAG_sleep

	; restore the original registers
	pop	rdi
	pop	rcx

	; end of the option handling
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_sleep"

;-------------------------------------------------------------------------------
.process_release:
	; preemption
	int	KERNEL_APIC_IRQ_number

	; end of the option handling
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_release"

;-------------------------------------------------------------------------------
; input:
;\trcx - number of characters in the string
;\trsi - pointer to the string
.process_dir_change:
	; preserve the original registers
	push	rax
	push	rcx
	push	rsi
	push	rdi

	; resolve the path to the file
	call	kernel_vfs_path_resolve
	jc	.process_dir_change_end	; the path to the last file could not be resolved

	; look for the file in the target directory
	call	kernel_vfs_file_find
	jc	.process_dir_change_end	; the given directory was not found, or the file is not a directory

.process_dir_change_smybolic_link:
	; the found file is a symbolic link?
	test	byte [rdi + KERNEL_VFS_STRUCTURE_KNOT.type],	KERNEL_VFS_FILE_TYPE_symbolic_link
	jz	.process_dir_change_ok	; no

	; resolve the link
	mov	rdi,	qword [rdi + KERNEL_VFS_STRUCTURE_KNOT.data]

	; check once more
	jmp	.process_dir_change_smybolic_link

.process_dir_change_ok:
	; the file is of the type: directory?
	test	byte [rdi + KERNEL_VFS_STRUCTURE_KNOT.type],	KERNEL_VFS_FILE_TYPE_directory
	jz	.process_dir_change_error	; no

	; save the pointer to the directory spool
	mov	rax,	rdi

	; set the pointer to the task position of the logical processor
	call	kernel_task_active

	; save the information about the new working directory of the process
	mov	qword [rdi + KERNEL_TASK_STRUCTURE.knot],	rax

	; end of the command handling
	jmp	.process_dir_change_end

.process_dir_change_error:
	; flag, error
	stc

.process_dir_change_end:
	; restore the original registers
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rax

	; end of the option handling
	jmp	kernel_service.end

	macro_debug	"kernel_service.process_dir_change"

;===============================================================================
.vfs:
	; check the validity of the path?
	cmp	ax,	KERNEL_SERVICE_VFS_exist
	je	.vfs_exist	; yes

	; create an empty file?
	cmp	ax,	KERNEL_SERVICE_VFS_touch
	je	.vfs_touch	; yes

	; return the list of files from the given path?
	cmp	ax,	KERNEL_SERVICE_VFS_dir
	je	.vfs_dir	; yes

	; read the content of the file?
	cmp	ax,	KERNEL_SERVICE_VFS_read
	je	.vfs_read	; yes

	; store a string of data into the file?
	cmp	ax,	KERNEL_SERVICE_VFS_write
	je	.vfs_write	; yes

	; no handling of the subprocedure
	jmp	kernel_service.error

;-------------------------------------------------------------------------------
; input:
;\trcx - size of the path in Bytes
;\trdx - number of the data in Bytes
;\trsi - pointer to the string representing the path
;\trdi - pointer to the data
.vfs_write:
	; preserve the original registers
	push	rax
	push	rcx
	push	rsi
	push	rdx
	push	rdi

	; local variable
	push	STATIC_FALSE

	; resolve the path to the file
	call	kernel_vfs_path_resolve
	jc	.vfs_write_end	; the path to the last file could not be resolved

	; look for the file in the target directory
	call	kernel_vfs_file_find
	jnc	.vfs_write_ready	; the given file was not found

	; create an empty file with the given name
	mov	dl,	KERNEL_VFS_FILE_TYPE_regular_file
	call	kernel_vfs_file_touch
	jc	.vfs_write_end	; the file could not be created

	; an empty file was created
	mov	qword [rsp],	STATIC_TRUE

.vfs_write_ready:
	; store the data into the file
	mov	rcx,	qword [rsp + STATIC_QWORD_SIZE_byte * 0x02]
	mov	rsi,	qword [rsp + STATIC_QWORD_SIZE_byte]
	call	kernel_vfs_file_write
	jnc	.vfs_write_end	; the data were stored into the file successfully

	; an empty file was created
	cmp	byte [rsp],	STATIC_FALSE
	je	.vfs_write_end	; no

	; debug
	xchg	bx,bx

.vfs_write_end:
	; release the local variable
	add	rsp,	STATIC_QWORD_SIZE_byte

	; restore the original registers
	pop	rdi
	pop	rdx
	pop	rsi
	pop	rcx
	pop	rax

	; end of the option handling
	jmp	kernel_service.end

	macro_debug	"kernel_service.vfs_write"

;-------------------------------------------------------------------------------
; input:
;\trcx - size of the path in Bytes
;\trsi - pointer to the string representing the path
; output:
;\tCF flag - if the file could not be read or was not found
;\trcx - size of the file in Bytes
;\trdi - pointer to the area with the data of the file
.vfs_read:
	; preserve the original registers
	push	rax
	push	rsi
	push	rdi
	push	rcx

	; resolve the path to the file
	call	kernel_vfs_path_resolve
	jc	.vfs_read_end	; the path to the last file could not be resolved

	; look for the file in the target directory
	call	kernel_vfs_file_find
	jc	.vfs_read_end	; the given file was not found

	; set the source pointer to the file spool
	mov	rsi,	rdi

	; fetch the size of the file in Bytes/blocks
	mov	rcx,	qword [rsi + KERNEL_VFS_STRUCTURE_KNOT.size]

	; the file is of the type: regular file?
	test	byte [rsi + KERNEL_VFS_STRUCTURE_KNOT.type],	KERNEL_VFS_FILE_TYPE_regular_file
	jnz	.vfs_read_regular_file	; yes

	; amount of the space used for the data blocks in Bytes
	xor	eax,	eax

	; fetch the pointer to the first data block
	mov	rcx,	qword [rsi + KERNEL_VFS_STRUCTURE_KNOT.data]

.vfs_read_block:
	; increase the size of the directory in Bytes
	add	rax,	STATIC_STRUCTURE_BLOCK.link

	; fetch the pointer to the next data block
	mov	rcx,	qword [rcx + STATIC_STRUCTURE_BLOCK.link]

	; end of the data blocks?
	test	rcx,	rcx
	jnz	.vfs_read_block	; no

	; return the size of the file in Bytes
	mov	rcx,	rax

.vfs_read_regular_file:
	; prepare the area for the loaded file in the area of the process
	call	library_page_from_size
	call	kernel_memory_alloc_task
	jc	.vfs_read_end	; not enough memory

	; load the content of the file into the memory area of the process
	call	kernel_vfs_file_read
	jc	.vfs_read_end	; loaded correctly

	; return the information about the size and the pointer to the data of the file
	mov	qword [rsp],	rcx
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	rdi

	; end of the procedure handling
	jmp	.vfs_read_end

.vfs_read_end:
	; restore the original registers
	pop	rcx
	pop	rdi
	pop	rsi
	pop	rax

	; end of the option handling
	jmp	kernel_service.end

	macro_debug	"kernel_service.vfs_read"

;-------------------------------------------------------------------------------
; input:
;\trcx - size of the path in Bytes
;\trsi - pointer to the string representing the path
; output:
;\trcx - number of the entries
;\trdi - pointer to the area with the entries
.vfs_dir:
	; preserve the original registers
	push	rax
	push	rbx
	push	rdx
	push	rsi
	push	rdi
	push	rcx

	; resolve the path to the file
	call	kernel_vfs_path_resolve
	jc	.vfs_dir_end	; the path to the last file could not be resolved

	; look for the file in the target directory
	call	kernel_vfs_file_find
	jc	.vfs_dir_end	; the given file was not found

	; the type of the file: directory?
	test	byte [rdi + KERNEL_VFS_STRUCTURE_KNOT.type],	KERNEL_VFS_FILE_TYPE_directory
	jz	.vfs_dir_not	; no

	; fetch the number of the entries in the directory and set the source pointer to the first data block
	mov	rsi,	qword [rdi + KERNEL_VFS_STRUCTURE_KNOT.data]

	; compute the size of the area required for all the spools
	mov	eax,	KERNEL_VFS_STRUCTURE_KNOT.SIZE
	mul	qword [rdi + KERNEL_VFS_STRUCTURE_KNOT.size]

	; convert into the number of pages
	mov	rcx,	rax
	call	library_page_from_size

	; reserve the area for the process
	call	kernel_memory_alloc_task
	jc	.vfs_dir_end	; not enough memory

	; number of the entries transferred to the process
	xor	ebx,	ebx

	; save the pointer to the area
	push	rdi

.vfs_dir_reload:
	; number of the entries in a data block
	mov	edx,	STATIC_STRUCTURE_BLOCK.link / KERNEL_VFS_STRUCTURE_KNOT.SIZE

.vfs_dir_loop:
	; the entry is occupied?
	test	word [rsi + KERNEL_VFS_STRUCTURE_KNOT.flags],	KERNEL_VFS_FILE_FLAGS_reserved
	jz	.vfs_dir_next	; no, check the next one

	; copy the information about the spool into the area of the process
	mov	ecx,	KERNEL_VFS_STRUCTURE_KNOT.SIZE
	rep	movsb

	; the entry was transferred
	inc	rbx

	; set the pointer back to the entry
	sub	rsi,	KERNEL_VFS_STRUCTURE_KNOT.SIZE

.vfs_dir_next:
	; move the pointer to the next entry
	add	rsi,	KERNEL_VFS_STRUCTURE_KNOT.SIZE

	; end of the entries in the block?
	dec	edx
	jnz	.vfs_dir_loop	; no

	; load the next data block of the directory
	and	si,	STATIC_PAGE_mask
	mov	rsi,	qword [rsi + STATIC_STRUCTURE_BLOCK.link]

	; end of the data blocks?
	test	rsi,	rsi
	jnz	.vfs_dir_reload	; no

	; restore the pointer to the area
	pop	rdi

	; return the number of the entries transferred to the process
	mov	qword [rsp],	rbx
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	rdi	; and the pointer to the area

	; end of the procedure handling
	jmp	.vfs_dir_end

.vfs_dir_not:
	; set the source pointer
	mov	rsi,	rdi

	; allocate the memory area of the given size for the process
	mov	rcx,	0x01	; 4 KiB for a single spool :/
	call	kernel_memory_alloc_task
	jc	.vfs_dir_end	; not enough memory

	; save the pointer to the data area of the process
	push	rdi

	; copy the information about the spool into the area of the process
	mov	ecx,	KERNEL_VFS_STRUCTURE_KNOT.SIZE
	rep	movsb

	; restore the pointer to the data area of the process
	pop	rdi
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	rdi	; return to the process

	; return the information about the number of the transferred spools
	mov	qword [rsp],	0x01

.vfs_dir_end:
	; restore the original registers
	pop	rcx
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rbx
	pop	rax

	; end of the option handling
	jmp	kernel_service.end

	macro_debug	"kernel_service.vfs_dir"

;-------------------------------------------------------------------------------
; input:
;\trcx - number of characters in the path to the file
;\tdl - type of the file
;\trsi - pointer to the path
.vfs_touch:
	; preserve the original registers
	push	rax
	push	rdi

	; resolve the path to the file
	call	kernel_vfs_path_resolve
	jc	.vfa_touch_end	; error, invalid path

	; create an empty file
	call	kernel_vfs_file_touch

.vfa_touch_end:
	; restore the original registers
	pop	rdi
	pop	rax

	; end of the option handling
	jmp	kernel_service.end

	macro_debug	"kernel_service.vfs_touch"

;-------------------------------------------------------------------------------
; input:
;\trcx - number of characters in the string
;\trsi - pointer to the string representing the name/path of the file
; output:
;\tCF flag - if the file does not exist
;\tbl - type of the file
.vfs_exist:
	; error code, none
	xor	eax,	eax

	; preserve the original registers
	push	rcx
	push	rsi
	push	rdi

	; resolve the path to the program
	call	kernel_vfs_path_resolve
	jc	.vfs_exist_not	; error, invalid path

	; look for the program in the given directory
	call	kernel_vfs_file_find

	; return the information about the type of the file
	mov	bl,	byte [rdi + KERNEL_VFS_STRUCTURE_KNOT.type]

.vfs_exist_not:
	; restore the original registers
	pop	rdi
	pop	rsi
	pop	rcx

	; return the error code
	mov	qword [rsp],	rax

	; end of the option handling
	jmp	kernel_service.end

	macro_debug	"kernel_service.vfs_exist"

;===============================================================================
.system:
	; return the properties of the RAM memory
	cmp	ax,	KERNEL_SERVICE_SYSTEM_memory
	je	.system_memory	; yes

	; return the information about the time?
	cmp	ax,	KERNEL_SERVICE_SYSTEM_time
	je	.system_time

	; no handling of the subprocedure
	jmp	kernel_service.error

;-------------------------------------------------------------------------------
.system_memory:
	; total size
	mov	r8,	qword [rel kernel_page_total_count]
	mov	r9,	qword [rel kernel_page_free_count]
	mov	r10,	qword [rel kernel_page_paged_count]

	; return to the process
	jmp	kernel_service.end

	macro_debug	"kernel_service.system_memory"

;-------------------------------------------------------------------------------
.system_time:
	; return the system uptime (1 second is 1024 ticks)
	mov	rax,	qword [rel driver_rtc_microtime]
	mov	qword [rsp],	rax

	; end of the option handling
	jmp	kernel_service.end

	macro_debug	"kernel_service.system_time"
