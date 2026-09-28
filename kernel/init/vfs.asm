;===============================================================================

struc	KERNEL_INIT_STRUCTURE_VFS_FILE
	.data_pointer	resb	8
	.size		resb	8
	.mode		resb	2
	.length		resb	1
	.path:
	.SIZE:
endstruc

;===============================================================================
kernel_init_vfs:
	; prepare room for the volume tables
	call	kernel_memory_alloc_page
	jc	kernel_panic_memory

	; clear the area and save the root directory pointer
	call	kernel_page_drain
	mov	qword [rel kernel_vfs_magicknot + KERNEL_VFS_STRUCTURE_KNOT.data],	rdi

	; point at the Super Node
	mov	rdi,	kernel_vfs_magicknot

	; fill the root directory with the basic links
	mov	rsi,	rdi
	call	kernel_vfs_dir_symlinks

	;-----------------------------------------------------------------------
	; create the directory structure
	;-----------------------------------------------------------------------
	mov	rsi,	kernel_init_vfs_directory_structure

.dir:
	; fetch the path size
	movzx	ecx,	byte [rsi]

	; end of the structure?
	test	cl,	cl
	jz	.next	; yes

	; move the pointer to the path
	inc	rsi

	; preserve the original registers
	push	rcx
	push	rsi

	; resolve the path
	call	kernel_vfs_path_resolve

	; file type: directory
	mov	dl,	KERNEL_VFS_FILE_TYPE_directory
	call	kernel_vfs_file_touch	; create it

	; restore the original registers
	pop	rsi
	pop	rcx

	; move the pointer to the next entry
	add	rsi,	rcx

	; process the next entry
	jmp	.dir

.next:
	;-----------------------------------------------------------------------
	; load the built-in software set into the file system
	;-----------------------------------------------------------------------
	mov	rsi,	kernel_init_vfs_files

.file:
	; end of the file list?
	cmp	qword [rsi],	STATIC_EMPTY
	je	.end	; yes

	; save the pointer to the file being processed
	push	rsi

	; create an "empty" file in the file system
	movzx	ecx,	byte [rsi + KERNEL_INIT_STRUCTURE_VFS_FILE.length]
	mov	dl,	KERNEL_VFS_FILE_TYPE_regular_file
	add	rsi,	KERNEL_INIT_STRUCTURE_VFS_FILE.path
	call	kernel_vfs_path_resolve
	call	kernel_vfs_file_touch

	; load the contents into the created file
	mov	rsi,	qword [rsp]	; fetch the pointer to the file being processed
	mov	rcx,	qword [rsi + KERNEL_INIT_STRUCTURE_VFS_FILE.size]
	mov	rsi,	qword [rsi + KERNEL_INIT_STRUCTURE_VFS_FILE.data_pointer]
	call	kernel_vfs_file_append

	; restore the pointer to the file being processed
	pop	rsi

	; move the pointer to the next entry
	movzx	ecx,	byte [rsi + KERNEL_INIT_STRUCTURE_VFS_FILE.length]
	add	rsi,	rcx
	add	rsi,	KERNEL_INIT_STRUCTURE_VFS_FILE.SIZE

	; continue
	jmp	.file

.end:
