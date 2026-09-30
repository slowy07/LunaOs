
kernel_init_storage:
	; check whether an IDE controller is available
	mov eax, DRIVER_PCI_CLASS_SUBCLASS_ide
	call driver_pci_find_class_and_subclass
	jc .ide_end ; none

	; initialise the available drives on the IDE controller
	call driver_ide_init

	; were any drives found?
	cmp byte [rel driver_ide_devices_count], STATIC_EMPTY
	je .ide_end ; no

	; maximum number of IDE devices
	mov cl, 0x04

	; register all the available drives
	mov rdi, driver_ide_devices

.ide_loop:
	; entry filled in?
	cmp word [rdi + DRIVER_IDE_STRUCTURE_DEVICE.channel], STATIC_EMPTY
	je .ide_next ; no

	; preserve the original registers
	push rax
	push rcx
	push rsi
	push rdi

	; fetch the drive size in bytes
	mov rax, qword [rdi + DRIVER_IDE_STRUCTURE_DEVICE.size_sectors]
	shl rax, STATIC_MULTIPLE_BY_512_shift ; turn it into bytes

	; create the block device in the virtual file system
	mov ecx, kernel_init_string_storage_ide_hd_end - kernel_init_string_storage_ide_hd_path
	mov rsi, kernel_init_string_storage_ide_hd_path
	call kernel_vfs_path_resolve
	mov rbx, qword [rsp]
	mov dl, KERNEL_VFS_FILE_TYPE_block_device
	call kernel_vfs_file_touch

	; update the block device size
	mov qword [rdi + KERNEL_VFS_STRUCTURE_KNOT.size], rax

	; restore the original registers
	pop rdi
	pop rsi
	pop rcx
	pop rax

.ide_next:
	; next drive letter
	inc byte [rel kernel_init_string_storage_ide_hd_letter]

	; move the pointer to the next entry
	add rdi, DRIVER_IDE_STRUCTURE_DEVICE.SIZE

	; end of the entries
	dec cl
	jnz .ide_loop ; no

.ide_end:
