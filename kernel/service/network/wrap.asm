
; input:
;	rax - MAC address of the recipient
;	cx - protocol type
;	rdi - pointer to the space of the packet to send
service_network_ethernet_wrap:
	; preserve the original registers
	push rax

	; MAC address of the recipient
	mov qword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.target], rax

	; MAC address of the sender
	mov rax, qword [rel driver_nic_i82540em_mac_address]
	mov qword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.source], rax

	; protocol type
	mov word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.type], cx

	; restore the original registers
	pop rax

	; return from the procedure
	ret

	macro_debug "service_network_ethernet_wrap"

; input:
;	rax - MAC address of the recipient
;	bl - protocol type
;	cx - data size in Bytes
;	rsi - pointer to the connection properties
;	rdi - pointer to the space of the packet to send
service_network_ip_wrap:
	; preserve the original registers
	push rcx
	push rax

	; IP version
	mov byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.version_and_ihl], SERVICE_NETWORK_FRAME_IP_VERSION_4 | SERVICE_NETWORK_FRAME_IP_HEADER_LENGTH_default

	; clear the unused options
	mov byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.dscp_and_ecn], STATIC_EMPTY

	; set the size of the IP frame
	add cx, SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE
	rol cx, STATIC_REPLACE_AL_WITH_HIGH_shift
	mov word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.total_length], cx

	; set the identifier
	inc word [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.identification]
	mov ax, word [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.identification]
	mov word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.identification], ax

	; set the default flags
	mov word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.f_and_f], SERVICE_NETWORK_FRAME_IP_F_AND_F_do_not_fragment

	; standard TTL size
	mov byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.ttl], SERVICE_NETWORK_FRAME_IP_TTL_default

	; protocol type
	mov byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.protocol], bl

	; clear the checksum
	mov word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.checksum], STATIC_EMPTY

	; set the sender (me)
	mov eax, dword [rel driver_nic_i82540em_ipv4_address]
	mov dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.source_address], eax

	; set the recipient
	mov eax, dword [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_ipv4]
	mov dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.destination_address], eax

	; set the checksum of the IP frame
	xor eax, eax
	mov ecx, SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE >> STATIC_DIVIDE_BY_2_shift
	add rdi, SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE
	call service_network_checksum
	rol ax, STATIC_REPLACE_AL_WITH_HIGH_shift ; convert to Big-Endian
	sub rdi, SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE
	mov word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.checksum], ax

	; wrap the IP frame
	pop rax
	mov cx, SERVICE_NETWORK_FRAME_ETHERNET_TYPE_ip
	call service_network_ethernet_wrap

	; restore the original registers
	pop rcx

	; return from the procedure
	ret

	macro_debug "service_network_ip_wrap"

; input:
;	bl - TCP header size
;	ecx - TCP frame size in Bytes
;	rsi - pointer to the connection properties
;	rdi - pointer to the space of the packet to send
service_network_tcp_wrap:
	; preserve the original registers
	push rax
	push rbx
	push rcx
	push rdi

	; set the source (service) and destination port
	mov ax, word [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.host_port]
	mov word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.port_source], ax
	mov ax, word [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_port]
	mov word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.port_target], ax

	; our sequence number
	mov eax, dword [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.host_sequence]
	bswap eax ; convert to Big-Endian
	mov dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.sequence], eax

	; the sequence number expected by the recipient
	mov eax, dword [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_sequence]
	bswap eax ; convert to Big-Endian
	mov dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.acknowledgement], eax

	; size of the TCP frame header
	mov byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.header_length], bl

	; return the current state of the flags
	mov al, byte [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags]
	mov byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.flags], al

	; window size
	mov ax, word [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.window_size]
	rol ax, STATIC_REPLACE_AL_WITH_HIGH_shift ; convert to Big-Endian
	mov word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.window_size], ax

	; clear the checksum and the urgent pointer field
	mov dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.checksum_and_urgent_pointer], STATIC_EMPTY

	; configure the TCP pseudo header
	call service_network_tcp_pseudo_header

	; checksum of the TCP frame
	shr ecx, STATIC_DIVIDE_BY_2_shift ; convert to words
	add rdi, SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE
	call service_network_checksum
	rol ax, STATIC_REPLACE_AL_WITH_HIGH_shift ; convert to Big-Endian
	mov word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.checksum], ax

	; wrap the IP frame data
	mov rax, qword [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_mac]
	mov bl, SERVICE_NETWORK_FRAME_IP_PROTOCOL_TCP
	shl ecx, STATIC_MULTIPLE_BY_2_shift ; convert to Bytes
	sub rdi, SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE ; move the pointer back to the space of the packet to send
	call service_network_ip_wrap

	; restore the original registers
	pop rdi
	pop rcx
	pop rbx
	pop rax

	; return from the procedure
	ret

	macro_debug "service_network_tcp_wrap"
