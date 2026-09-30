
KERNEL_VFS_FILE_FLAGS_reserved equ 00000001b

KERNEL_VFS_ERROR_FILE_exists equ 0x01
KERNEL_VFS_ERROR_DIRECTORY_full equ 0x02
KERNEL_VFS_ERROR_FILE_name_long equ 0x04
KERNEL_VFS_ERROR_FILE_name_short equ 0x05
KERNEL_VFS_ERROR_FILE_low_memory equ 0x06
KERNEL_VFS_ERROR_FILE_overflow equ 0x07 ; e.g. a forbidden character sent to the character device

struc KERNEL_VFS_STRUCTURE_META_CHARACTER_DEVICE
	.width resb 8
	.height resb 8
	.start resb 8
	.end resb 8
	.SIZE:
endstruc

kernel_vfs_semaphore db STATIC_FALSE

; bring the spool position to a full address
align STATIC_QWORD_SIZE_byte, db STATIC_NOTHING
kernel_vfs_magicknot: dq STATIC_EMPTY ; data
							dq STATIC_EMPTY ; size
							db KERNEL_VFS_FILE_TYPE_directory
							dw STATIC_EMPTY ; flags
							dq STATIC_EMPTY ; time_modified
							db 0x01 ; length
							db "/" ; name

kernel_vfs_string_directory_local_or_overriding db ".", "."

; input:
;\trsi - pointer to the metadata
kernel_vfs_metadata_update:
	; return from the procedure
	ret

	macro_debug "kernel_vfs_metadata_update"

; input:
;\trsi - pointer to the spool of the parent directory
;\trdi - pointer to the spool of the processed directory
kernel_vfs_dir_symlinks:
	; preserve the original registers
	push rax
	push rcx
	push rdx
	push rsi
	push rdi

	; create a symbolic link to itself "."
	mov ecx, 0x01 ; number of the characters in the file name
	mov dl, KERNEL_VFS_FILE_TYPE_symbolic_link
	mov rsi, kernel_vfs_string_directory_local_or_overriding
	call kernel_vfs_file_touch

	; destination pointer of the symbolic link
	mov rax, qword [rsp]
	mov qword [rdi + KERNEL_VFS_STRUCTURE_KNOT.data], rax

	; the next link refers to itself? /
	cmp qword [rsp + STATIC_QWORD_SIZE_byte], rax
	je .end ; yes, no symbolic link to the parent directory :)

	; create a symbolic link to the parent directory ".."
	mov ecx, 0x02 ; number of the characters in the file name
	mov rdi, rax ; create it in the processed directory
	call kernel_vfs_file_touch

	; destination pointer of the symbolic link
	mov rax, qword [rsp + STATIC_QWORD_SIZE_byte]
	mov qword [rdi + KERNEL_VFS_STRUCTURE_KNOT.data], rax

.end:
	; restore the original registers
	pop rdi
	pop rsi
	pop rdx
	pop rcx
	pop rax

	; return from the procedure
	ret

	; information for Bochs
	macro_debug "kernel_vfs_dir_symlinks"

; input:
;\trcx - size of the path in characters
;\trsi - pointer to the path
; output:
;\tCF flag - if an error
;\trax - error code
;\trcx - number of the characters in the last file of the path
;\trsi - pointer to the last file in the path
;\trdi - identifier of the last directory in the path
kernel_vfs_path_resolve:
	; preserve the original registers
	push rax
	push rbx
	push rdx
	push rsi
	push rcx

	; create a local variable
	push STATIC_EMPTY

	; size of the processed string
	xor ebx, ebx

	; the path empty?
	test rcx, rcx
	jz .empty ; yes

	; start from the root directory by default
	mov rdi, kernel_vfs_magicknot

	; does the path begin with the character "/"?
	cmp byte [rsi], STATIC_SCANCODE_SLASH
	je .prefix ; yes

	; set the pointer to the task position of the logical processor
	call kernel_task_active

	; fetch the identifier/node of the working directory of the parent
	mov rdi, qword [rdi + KERNEL_TASK_STRUCTURE.knot]

	; continue
	jmp .suffix

.prefix:
	; remove the character "/" from the beginning of the path
	dec rcx
	inc rsi

	; end of the path?
	test rcx, rcx
	jz .root ; yes

	; the beginning of the path has the character "/" again
	cmp byte [rsi], STATIC_SCANCODE_SLASH
	je .prefix ; yes

.suffix:
	; the path ends with the character "/"?
	cmp byte [rsi + rcx - 0x01], STATIC_SCANCODE_SLASH
	jne .cut ; no

	; shorten the path by the character "/"
	dec rcx

	; end of the path?
	test rcx, rcx
	jnz .suffix ; no

.cut:
	; look for the character "/" from the end of the path
	cmp byte [rsi + rcx - STATIC_BYTE_SIZE_byte], STATIC_SCANCODE_SLASH
	je .loop

	; shorten the path by the last file
	inc rbx
	dec rcx

	; end of the path?
	test rcx, rcx
	jnz .cut

	; the path contains only a "file"

	; continue
	jmp .ready

.doubled:
	; the "/" or "//" found in the path, skip
	dec rcx
	inc rsi

.loop:
	; the path processed?
	test rcx, rcx
	jz .ready ; yes

	; save the size of the path
	mov qword [rsp], rcx

	; fetch the name of the directory
	mov al, STATIC_SCANCODE_SLASH ; the file separator in the path
	macro_library LIBRARY_STRUCTURE_ENTRY.string_cut
	jc .ready ; the path has been processed

	; an empty string returned?
	test rcx, rcx
	jz .leave ; yes

	; error code, the file was not found
	mov eax, KERNEL_ERROR_vfs_file_not_found

	; does the file exist?
	call kernel_vfs_file_find
	jc .error ; no

	; the file is a symbolic link?
	test byte [rdi + KERNEL_VFS_STRUCTURE_KNOT.type], KERNEL_VFS_FILE_TYPE_symbolic_link
	jz .no_link ; no

	; reload the pointer
	mov rdi, qword [rdi + KERNEL_VFS_STRUCTURE_KNOT.data]

.no_link:
	; error code, this is not a directory
	mov eax, KERNEL_ERROR_vfs_file_not_directory

	; the file is a directory?
	test byte [rdi + KERNEL_VFS_STRUCTURE_KNOT.type], KERNEL_VFS_FILE_TYPE_directory
	jz .error ; no

	; correct the path
	sub qword [rsp], rcx
	add rsi, rcx

.leave:
	; restore the size of the remaining path
	mov rcx, qword [rsp]

	; keep processing
	jmp .doubled

.ready:
	; correct the information about the number of the characters left in the path
	mov rcx, rbx

.prepared:
	; return
	mov qword [rsp + STATIC_QWORD_SIZE_byte], rcx
	mov qword [rsp + STATIC_QWORD_SIZE_byte * 0x02], rsi

	; flag, success
	clc

	; end
	jmp .end

.root:
	; set the pointer to the directory file of the current directory
	mov rcx, 0x01
	mov rsi, kernel_vfs_string_directory_local_or_overriding

	; continue
	jmp .prepared

.empty:
	; error code, path error
	mov eax, KERNEL_ERROR_vfs_file_not_found

.error:
	; return the error code
	mov qword [rsp + STATIC_QWORD_SIZE_byte * 0x05], rax

	; flag, error
	stc

.end:
	; release the local variable
	add rsp, STATIC_QWORD_SIZE_byte

	; restore the original registers
	pop rcx
	pop rsi
	pop rdx
	pop rbx
	pop rax

	; return from the procedure
	ret

	; information for Bochs
	macro_debug "kernel_vfs_path_resolve"

; input:
;\trcx - number of characters in the file name
;\tdl - type of the file
;\trsi - pointer to the file name
;\trdi - spool/identifier of the directory in which to create the new file
; output:
;\tCF flag, if an error
;\trdi - spool/identifier of the created file
kernel_vfs_file_touch:
	; preserve the original registers
	push rcx
	push rsi
	push rdi
	push rax

	; error code: the file name is too long
	mov eax, KERNEL_VFS_ERROR_FILE_name_long

	; check the supported length of the file name
	cmp rcx, KERNEL_VFS_STRUCTURE_KNOT.SIZE - KERNEL_VFS_STRUCTURE_KNOT.name
	ja .error

	; error code: the file name is too short
	mov eax, KERNEL_VFS_ERROR_FILE_name_short

	; check whether any name was given
	cmp rcx, STATIC_EMPTY
	je .error

	; error code: the file exists
	mov eax, KERNEL_VFS_ERROR_FILE_exists

	; check whether a file with the given name exists
	call kernel_vfs_file_find
	jnc .error ; a file with the given name exists

	; error code: no space
	mov rax, KERNEL_VFS_ERROR_DIRECTORY_full

	; look for a free record in the root directory
	call kernel_vfs_knot_prepare
	jc .end ; no free record

	; update the spool entry

	; the file is a directory?
	cmp dl, KERNEL_VFS_FILE_TYPE_directory
	jne .no_directory ; no

	; save the spool pointer
	mov rax, rdi

	; prepare the data block for the new directory
	call kernel_memory_alloc_page
	jnc .assigned ; allocated

	; release the entry in the directory
	mov word [rdi + KERNEL_VFS_STRUCTURE_KNOT.flags], STATIC_EMPTY

	; end of the handling
	jmp .error

.assigned:
	; clear the data block of the directory
	call kernel_page_drain
	mov qword [rax + KERNEL_VFS_STRUCTURE_KNOT.data], rdi

	; restore the spool pointer
	mov rdi, rax

	; save the pointer to the directory name
	push rsi

	; create the basic symbolic links
	mov rsi, qword [rsp + STATIC_QWORD_SIZE_byte * 0x02] ; the spool pointer of the parent directory
	call kernel_vfs_dir_symlinks

	; restore the pointer to the directory name
	pop rsi

.no_directory:
	; number of the characters in the file name
	mov byte [rdi + KERNEL_VFS_STRUCTURE_KNOT.length], cl

	; save the type of the file
	mov byte [rdi + KERNEL_VFS_STRUCTURE_KNOT.type], dl

	; save the spool pointer
	push rdi

	; the name of the file
	add rdi, KERNEL_VFS_STRUCTURE_KNOT.name
	rep movsb

	; restore the spool pointer
	pop rdi
	mov qword [rsp + STATIC_QWORD_SIZE_byte], rdi ; return

	; end of the procedure
	jmp .end

.error:
	; return the error code
	mov qword [rsp], rax

	; flag, error
	stc

.end:
	; restore the original registers
	pop rax
	pop rdi
	pop rsi
	pop rcx

	; return from the procedure
	ret

	; information for Bochs
	macro_debug "kernel_vfs_file_touch"

; input:
;\trcx - number of characters in the file name
;\trsi - pointer to the file name
;\trdi - spool/identifier of the searched directory
; output
;\tCF flag - if an error
;\trax - error code
;\trdi - pointer to the spool describing the file
kernel_vfs_file_find:
	; preserve the original registers
	push rax
	push rcx
	push rsi
	push rdi

	; remember the number of the characters in the file name
	mov rax, rcx

	; set the pointer to the first data block of the directory
	mov rdi, qword [rdi + KERNEL_VFS_STRUCTURE_KNOT.data]

.prepare:
	; number of the spools in a block
	mov rcx, STATIC_STRUCTURE_BLOCK.link / KERNEL_VFS_STRUCTURE_KNOT.SIZE

.loop:
	; do the number of the characters in the name match?
	cmp byte [rdi + KERNEL_VFS_STRUCTURE_KNOT.length], al
	jne .next ; no

	; move the pointer to the string of the file name
	add rdi, KERNEL_VFS_STRUCTURE_KNOT.name

	; set the number of the characters in the file name
	xchg rcx, rax

	; compare the file names
	macro_library LIBRARY_STRUCTURE_ENTRY.string_compare

	; restore the counter
	xchg rcx, rax

	; the file found?
	jnc .found

	; move the pointer back to the beginning of the spool
	sub rdi, KERNEL_VFS_STRUCTURE_KNOT.name

.next:
	; move the pointer to the next spool
	add rdi, KERNEL_VFS_STRUCTURE_KNOT.SIZE

	; check the next spools
	dec rcx
	jnz .loop

	; the records from the given block have run out, fetch the address of the next data block of the root directory
	and di, STATIC_PAGE_mask
	mov rdi, qword [rdi + STATIC_STRUCTURE_BLOCK.link]
	test rdi, rdi ; end of the data blocks?
	jnz .prepare ; search the next data block of the directory

	; the wanted file not found, return the error code
	mov qword [rsp + STATIC_QWORD_SIZE_byte * 0x03], KERNEL_ERROR_vfs_file_not_found

	; flag, error
	stc

	; end of the procedure handling
	jmp .end

.found:
	; move the pointer back to the entry
	sub rdi, KERNEL_VFS_STRUCTURE_KNOT.name

.unload:
	; the file is a symbolic link?
	test byte [rdi + KERNEL_VFS_STRUCTURE_KNOT.type], KERNEL_VFS_FILE_TYPE_symbolic_link
	jz .return ; no

	; load the address of the spool pointed to by the symbolic link
	mov rdi, qword [rdi + KERNEL_VFS_STRUCTURE_KNOT.data]

	; check once more
	jmp .unload

.return:
	; return the address of the spool describing the found file
	mov qword [rsp], rdi

.end:
	; restore the original registers
	pop rdi
	pop rsi
	pop rcx
	pop rax

	; return from the procedure
	ret

	; information for Bochs
	macro_debug "kernel_vfs_file_find"

; input:
;\tdl - type of the file
;\trdi - spool/identifier of the directory
; output:
;\tCF flag, if no free space was found
kernel_vfs_knot_prepare:
	; preserve the original registers
	push rcx
	push rdi

	; block the access to the file system
	macro_lock kernel_vfs_semaphore, 0

	; set the pointer to the first data block of the directory
	mov rdi, qword [rdi + KERNEL_VFS_STRUCTURE_KNOT.data]

.prepare:
	; number of the spools in a block
	mov ecx, STATIC_STRUCTURE_BLOCK.link / KERNEL_VFS_STRUCTURE_KNOT.SIZE

.loop:
	; the spool is free?
	cmp word [rdi + KERNEL_VFS_STRUCTURE_KNOT.flags], STATIC_EMPTY
	je .ready ; yes

	; move the pointer to the next spool
	add rdi, KERNEL_VFS_STRUCTURE_KNOT.SIZE

	; continue with the next records
	loop .loop

	; the records from the given block have run out, fetch the address of the next data block of the root directory
	and di, STATIC_PAGE_mask
	mov rdi, qword [rdi + STATIC_STRUCTURE_BLOCK.link]
	test rdi, rdi ; end of the data blocks?
	jnz .prepare ; search the next data block of the directory

	; no free spools in the current data block of the directory
	mov rcx, rdi ; remember the pointer of the link of the next data block

	; prepare the space for the next data block of the directory
	call kernel_memory_alloc_page
	jnc .ok ; no space in the memory area

	; error, no space
	stc

	; end of the procedure
	jmp .end

.ok:
	; clear the new data block of the root directory
	call kernel_page_drain

	; attach the new data block to the root directory
	mov qword [rcx], rdi

.ready:
	; block the access to the spool
	mov word [rdi + KERNEL_VFS_STRUCTURE_KNOT.flags], KERNEL_VFS_FILE_FLAGS_reserved

	; increase the counter of the spools in the current directory
	mov rcx, qword [rsp]
	inc qword [rcx + KERNEL_VFS_STRUCTURE_KNOT.size]

	; return the pointer to the spool
	mov qword [rsp], rdi

.end:
	; release the access to the file system
	mov byte [rel kernel_vfs_semaphore], STATIC_FALSE

	; restore the original registers
	pop rdi
	pop rcx

	; return from the procedure
	ret

	; information for Bochs
	macro_debug "kernel_vfs_knot_prepare"

; input:
;\trcx - number of the data in Bytes
;\trsi - pointer to the data of the file
;\trdi - spool/identifier of the file to overwrite
; output:
;\tCF flag, if an error
kernel_vfs_file_write:
	; preserve the original registers
	push rax
	push rbx
	push rdx
	push rcx
	push rdi

	; save the identifier/pointer to the spool of the file
	mov rbx, rdi

	; the file holds any data block?
	cmp qword [rbx + KERNEL_VFS_STRUCTURE_KNOT.data], STATIC_EMPTY
	jne .exist ; yes

	; prepare the area for the data block
	call kernel_memory_alloc_page
	jc .end ; no free space in the memory area

	; clear the data block of the file
	call kernel_page_drain

	; attach the data block to the file
	mov qword [rbx + KERNEL_VFS_STRUCTURE_KNOT.data], rdi

.exist:
	; store the first N data of the block into the file
	mov rdx, qword [rsp + STATIC_QWORD_SIZE_byte]

	; fetch the first data block of the file
	mov rdi, qword [rbx + KERNEL_VFS_STRUCTURE_KNOT.data]

	; will all the data fit in the first data block?
	cmp rcx, STATIC_STRUCTURE_BLOCK.link
	jbe .all_in_one ; yes

	; compute the number of the data blocks needed to store the data
	mov rax, STATIC_STRUCTURE_BLOCK.link
	xchg rax, rcx
	xor edx, edx ; remove the upper part of the size
	div rcx

	; the remainder of the division?
	test dx, dx
	jz .no_modulo ; no

	; number of the additional blocks +1
	mov ecx, STATIC_TRUE

.no_modulo:
	; reserve the required number of blocks for the file
	add rcx, rax
	call kernel_page_secure
	jc .end ; not enough memory

	; use the reserved blocks if needed
	mov rbp, rcx

	; store the first N data of the block into the file
	mov rdx, qword [rsp + STATIC_QWORD_SIZE_byte]

.loop:
	; size of the data block in Bytes
	mov ecx, STATIC_STRUCTURE_BLOCK.link
	shr ecx, STATIC_DIVIDE_BY_8_shift
	rep movsq

	; the first batch of the data was stored into the file
	sub rdx, STATIC_STRUCTURE_BLOCK.link

	; does the next data block exist?
	cmp qword [rdi], STATIC_EMPTY
	jne .next_block ; yes

.next_block:
	; fetch the next data block of the file
	mov rdi, qword [rdi]

	; do the remaining data of the file fit in a single block?
	cmp rdx, STATIC_STRUCTURE_BLOCK.link
	ja .loop ; no

.all_in_one:
	; the remaining data to store
	test rdx, rdx
	jz .saved ; no

	; store the end of the data into the block
	mov rcx, rdx
	rep movsb

	; release the remaining data blocks of the file
	and di, STATIC_PAGE_mask
	mov rdi, qword [rdi + STATIC_STRUCTURE_BLOCK.link]

.remove:
	; end of the data blocks?
	test rdi, rdi
	jz .saved ; yes

	; save the next probable data block
	push qword [rdi + STATIC_STRUCTURE_BLOCK.link]

	; release the data block
	call kernel_memory_release_page

	; restore the next probable data block
	pop rdi

	; continue
	jmp .remove

.saved:
	; release the remaining number of the reserved blocks
	sub qword [rel kernel_page_reserved_count], rbp
	add qword [rel kernel_page_free_count], rbp

	; update the information about the new size of the file
	mov rcx, qword [rsp + STATIC_QWORD_SIZE_byte]
	mov qword [rbx + KERNEL_VFS_STRUCTURE_KNOT.size], rcx

	; update the information about the modification time of the file
	mov rcx, qword [rel driver_rtc_microtime]
	mov qword [rbx + KERNEL_VFS_STRUCTURE_KNOT.time_modified], rcx

.end:
	; restore the original registers
	pop rdi
	pop rcx
	pop rdx
	pop rbx
	pop rax

	; return from the procedure
	ret

	; information for Bochs
	macro_debug "kernel_vfs_file_write"

; input:
;\trcx - number of the data in Bytes
;\trsi - pointer to the data of the file
;\trdi - spool/identifier of the file to modify
; output:
;\tCF flag, if an error
;\teax - error code
kernel_vfs_file_append:
	; preserve the original registers
	push rax
	push rbx
	push rcx
	push rdx
	push rdi

	; local variable
	push rcx

	; save the identifier/pointer to the spool of the file
	mov rbx, rdi

	; the file holds any data block?
	cmp qword [rbx + KERNEL_VFS_STRUCTURE_KNOT.data], STATIC_EMPTY
	jne .exist ; yes

	; error code, no free space
	mov eax, KERNEL_VFS_ERROR_FILE_low_memory

	; prepare the area for the data block
	call kernel_memory_alloc_page
	jc .end ; no free space in the memory area

	; clear the data block of the file
	call kernel_page_drain

	; attach the data block to the file
	mov qword [rbx + KERNEL_VFS_STRUCTURE_KNOT.data], rdi

.exist:
	; fetch the last data block of the file
	mov rdi, qword [rbx + KERNEL_VFS_STRUCTURE_KNOT.data]

.last_one:
	; is it the last data block of the file?
	cmp qword [rdi + STATIC_STRUCTURE_BLOCK.link], STATIC_EMPTY
	je .found ; yes

	; fetch the next data block of the file
	mov rdi, qword [rdi + STATIC_STRUCTURE_BLOCK.link]

	; keep searching
	jmp .last_one

.found:
	; compute the amount of the data held in the last data block of the file
	mov rax, qword [rbx + KERNEL_VFS_STRUCTURE_KNOT.size]
	mov rcx, STATIC_STRUCTURE_BLOCK.link
	xor edx, edx
	div rcx

	; move the pointer in the last block to the end of the data
	add rdi, rax

	; convert into the amount of the free space in the last data block of the file
	sub rax, STATIC_STRUCTURE_BLOCK.link
	not rax
	inc rax

	; set the counter to the space
	mov rcx, rax

	; will all the data fit into the last data block of the file?
	cmp rcx, qword [rsp]
	jbe .more ; no

.less:
	; fetch the remaining amount of the data to process
	xor ecx, ecx

	; zero the amount of the data to process
	xchg rcx, qword [rsp]

	; continue
	jmp .write

.more:
	; decrease the amount of the data to process
	sub qword [rsp], rcx

.write:
	; copy the data into the data block of the file
	rep movsb

	; end of the data of the file?
	cmp qword [rsp], STATIC_EMPTY
	je .ready ; yes

	; save the end pointer of the current data block
	mov rdx, rdi

	; error code, no free space
	mov eax, KERNEL_VFS_ERROR_FILE_low_memory

	; prepare the area for the data block
	call kernel_memory_alloc_page
	jc .end ; no free space in the memory area

	; clear the data block of the file
	call kernel_page_drain

	; attach the new data block to the file
	mov qword [rdx], rdi

	; amount of the free space in the new data block
	mov ecx, STATIC_STRUCTURE_BLOCK.link

	; will everything fit into the current data block?
	cmp qword [rsp], rcx
	jbe .less ; yes
	ja .more ; no

.ready:
	; update the information about the size of the file
	mov rcx, qword [rsp + STATIC_QWORD_SIZE_byte * 0x03]
	add qword [rbx + KERNEL_VFS_STRUCTURE_KNOT.size], rcx

	; update the information about the modification time of the file
	mov rcx, qword [rel driver_rtc_microtime]
	mov qword [rbx + KERNEL_VFS_STRUCTURE_KNOT.time_modified], rcx

.end:
	; release the local variable
	add rsp, STATIC_QWORD_SIZE_byte

	; restore the original registers
	pop rdi
	pop rdx
	pop rcx
	pop rbx
	pop rax

	; return from the procedure
	ret

	; information for Bochs
	macro_debug "kernel_vfs_file_append"

; input:
;\trsi - direct pointer to the spool of the file
;\trdi - destination address of the data of the file
; output:
;\tCF flag, if an error
;\trcx - size of the loaded data
kernel_vfs_file_read:
	; preserve the original registers
	push rax
	push rdx
	push rsi
	push rdi

.symbolic_link:
	; the file is a symbolic link?
	test word [rsi + KERNEL_VFS_STRUCTURE_KNOT.type], KERNEL_VFS_FILE_TYPE_symbolic_link
	jz .file ; no

	; fetch the correct spool of the file
	mov rsi, qword [rsi + KERNEL_VFS_STRUCTURE_KNOT.data]

	; check once more
	jmp .symbolic_link

.file:
	; size of the file in Bytes
	mov rax, qword [rsi + KERNEL_VFS_STRUCTURE_KNOT.size]

	; the file is a directory?
	test byte [rsi + KERNEL_VFS_STRUCTURE_KNOT.type], KERNEL_VFS_FILE_TYPE_directory
	jz .regular_file ; no

	; amount of the space used for the data blocks in Bytes
	xor eax, eax

	; fetch the pointer to the first data block
	mov rcx, qword [rsi + KERNEL_VFS_STRUCTURE_KNOT.data]

.block:
	; increase the size of the directory in Bytes
	add rax, STATIC_STRUCTURE_BLOCK.link

	; fetch the pointer to the next data block
	mov rcx, qword [rcx + STATIC_STRUCTURE_BLOCK.link]

	; end of the data blocks?
	test rcx, rcx
	jnz .block ; no

.regular_file:
	; save the size of the loaded data
	push rax

	; fetch the first data block of the file
	mov rsi, qword [rsi + KERNEL_VFS_STRUCTURE_KNOT.data]

.loop:
	; default size of the read block
	mov rcx, STATIC_STRUCTURE_BLOCK.link

	; does the next part of the file fit in a single data block?
	cmp rax, rcx
	ja .next_block ; no

	; yes
	mov rcx, rax

.next_block:
	; the remaining amount of the data to load
	sub rax, rcx

	; copy into the area of the process
	rep movsb

	; fetch the next data block of the file
	and si, STATIC_PAGE_mask
	mov rsi, qword [rsi + STATIC_STRUCTURE_BLOCK.link]

	; end of the data of the file?
	test rax, rax
	jnz .loop ; no

	; return the size of the loaded data
	pop rcx

	; restore the original registers
	pop rdi
	pop rsi
	pop rdx
	pop rax

	; return from the procedure
	ret

	; information for Bochs
	macro_debug "kernel_vfs_file_read"
