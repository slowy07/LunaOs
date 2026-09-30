
zero_storage:
	; initialise the available drives
	call driver_ide_init

	; TODO: file systems, more sectors at a time

	; load the kernel file

	; first sector holding the kernel file data
	mov eax, ((zero_end - zero) + 0x200) / 0x200

	; Master drive on the IDE0 controller
	xor ebx, ebx

	; we read the file one sector at a time
	mov ecx, 1

	; kernel file size in sectors
	mov edx, (KERNEL_FILE_SIZE_bytes / 0x200)

	; destination pointer in physical/logical memory space
	mov edi, 0x00100000

.loop:
	; load the sector
	call driver_ide_read

	; next sector
	inc eax

	; advance the destination pointer
	add edi, 0x0200

	; end of the sectors belonging to the file?
	dec edx
	jnz .loop ; no
