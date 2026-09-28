;===============================================================================

;===============================================================================
kernel_init_network:
	; scan the PCI buses for a network controller
	mov	eax,	DRIVER_PCI_CLASS_SUBCLASS_network
	call	driver_pci_find_class_and_subclass
	jc	.end	; not found

	; fetch the vendor and model
	mov	eax,	DRIVER_PCI_REGISTER_vendor_and_device
	call	driver_pci_read

	; a controller of type i82540EM?
	cmp	eax,	DRIVER_NIC_I82540EM_VENDOR_AND_DEVICE
	jne	.end	; no

	; initialise the controller
	call	driver_nic_i82540em

	; reserve room for the port table
	call	kernel_memory_alloc_page
	jc	kernel_panic	; out of memory

	; clear the table and remember the pointer
	call	kernel_page_drain
	mov	qword [rel service_network_port_table],	rdi

	; reserve room for the TCP/IP stack
	call	kernel_memory_alloc_page
	jc	kernel_panic	; out of memory

	; clear the table and remember the pointer
	call	kernel_page_drain
	mov	qword [rel service_network_stack_address],	rdi

.end:
