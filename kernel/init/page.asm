
kernel_init_page:
	; prepare room for the kernel PML4 table
	call kernel_memory_alloc_page
	jc kernel_panic_memory

	; clear all the entries in the PML4 table and remember its address
	call kernel_page_drain
	mov qword [rel kernel_page_pml4_address], rdi

	; page used in the page tables
	inc qword [rel kernel_page_paged_count]

	; map the physical RAM described in the binary memory map into the page tables
	mov eax, KERNEL_BASE_address ; start of the area
	; mark the area as available and writable by the kernel
	mov bx, KERNEL_PAGE_FLAG_available | KERNEL_PAGE_FLAG_write
	mov rcx, qword [rel kernel_page_total_count] ; size of the area in pages
	mov r11, rdi ; target location in the kernel PML4 table
	call kernel_page_map_physical ; describe 1:1
	jc kernel_panic_memory

	; create the kernel stack/"context stack"
	; the kernel gets the first half of the logical memory area
	mov rax, KERNEL_STACK_address
	mov ecx, KERNEL_STACK_SIZE_byte >> STATIC_DIVIDE_BY_PAGE_shift
	call kernel_page_map_logical
	jc kernel_panic_memory

	; https://forum.osdev.org/viewtopic.php?f=1&t=29034
	; https://wiki.osdev.org/Paging
	; https://forum.osdev.org/viewtopic.php?f=1&t=23223
	; https://forums.freebsd.org/threads/xorg-vesa-driver-massive-speedup-using-mtrr-write-combine.46723/
	; https://stackoverflow.com/questions/13297178/how-mtrr-registers-implemented
	; cont.
	;
	; map the physical memory area of the graphics card
	mov rax, qword [rel kernel_video_base_address]
	or bx, KERNEL_PAGE_FLAG_write_through | KERNEL_PAGE_FLAG_cache_disable
	mov rcx, qword [rel kernel_video_size_byte]
	call library_page_from_size
	call kernel_page_map_physical
	jc kernel_panic_memory

	; map the physical memory area of the APIC table
	mov rax, qword [rel kernel_apic_base_address]
	mov bx, KERNEL_PAGE_FLAG_available | KERNEL_PAGE_FLAG_write
	mov ecx, dword [rel kernel_apic_size] ; size of the area in bytes
	call library_page_from_size
	call kernel_page_map_physical
	jc kernel_panic_memory

	; map the physical memory area of the I/O APIC table
	mov eax, dword [rel kernel_io_apic_base_address]
	mov ecx, STATIC_PAGE_SIZE_byte >> STATIC_PAGE_SIZE_shift
	call kernel_page_map_physical
	jc kernel_panic_memory

	; reload the paging onto our own/newly created tables
	mov rax, rdi
	mov cr3, rax

	; we set the stack top pointer to the end of the new kernel stack
	mov rsp, KERNEL_STACK_pointer
