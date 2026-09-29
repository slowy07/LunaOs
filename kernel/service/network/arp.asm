;===============================================================================

;===============================================================================
; input:
;	rsi - pointer to the incoming packet
service_network_arp:
	; preserve the original register
	push	rax

	; Ethernet hardware addressing?
	cmp	word [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.htype],	SERVICE_NETWORK_FRAME_ARP_HTYPE_ethernet
	jne	.omit	; no

	; the IPv4 protocol?
	cmp	word [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.ptype],	SERVICE_NETWORK_FRAME_ARP_PTYPE_ipv4
	jne	.omit	; no

	; is the MAC address size correct?
	cmp	byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.hal],	SERVICE_NETWORK_FRAME_ARP_HAL_mac
	jne	.omit	; no

	; is the IPv4 address size correct?
	cmp	byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.pal],	SERVICE_NETWORK_FRAME_ARP_PAL_ipv4
	jne	.omit	; no

	; does the query concern our IP address?
	mov	eax,	dword [rel driver_nic_i82540em_ipv4_address]
	cmp	eax,	dword [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.target_ip]
	jne	.omit	; no

	; preserve the original registers
	push	rdi

	; prepare space for the answer
	call	kernel_memory_alloc_page
	jc	.error	; no free space, do not answer

	;-----------------------------------------------------------------------
	; fill the frames with default values
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.type],	SERVICE_NETWORK_FRAME_ETHERNET_TYPE_arp
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.htype],	SERVICE_NETWORK_FRAME_ARP_HTYPE_ethernet
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.ptype],	SERVICE_NETWORK_FRAME_ARP_PTYPE_ipv4
	mov	byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.hal],	SERVICE_NETWORK_FRAME_ARP_HAL_mac
	mov	byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.pal],	SERVICE_NETWORK_FRAME_ARP_PAL_ipv4
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.opcode],	SERVICE_NETWORK_FRAME_ARP_OPCODE_answer

	; return the IPv4 of the network controller in the answer
	mov	dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.source_ip],	eax

	; return the IPv4 of the sender in the answer
	mov	eax,	dword [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.source_ip]
	mov	dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.target_ip],	eax

	; complete the ARP and Ethernet frames with the MAC address of the network controller
	mov	rax,	qword [rel driver_nic_i82540em_mac_address]
	mov	dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.source],	eax
	mov	dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.source_mac],	eax
	shr	rax,	STATIC_MOVE_HIGH_TO_EAX_shift
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.source + SERVICE_NETWORK_STRUCTURE_MAC.4],	ax
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.source_mac + SERVICE_NETWORK_STRUCTURE_MAC.4],	ax

	; complete the ARP frame with the MAC address of the destination
	mov	rax,	qword [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.source_mac]
	mov	dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.target_mac],	eax
	shr	rax,	STATIC_MOVE_HIGH_TO_EAX_shift
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.target_mac + SERVICE_NETWORK_STRUCTURE_MAC.4],	ax

	; wrap the ARP frame
	mov	rax,	qword [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.source_mac]
	mov	cx,	SERVICE_NETWORK_FRAME_ETHERNET_TYPE_arp
	call	service_network_ethernet_wrap

	; send the answer
	mov	eax,	SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.SIZE
	call	service_network_transfer

.error:
	; restore the original registers
	pop	rdi

.omit:
	; restore the original register
	pop	rax

	; return from the procedure
	jmp	service_network.end

	macro_debug	"service_network_arp"
