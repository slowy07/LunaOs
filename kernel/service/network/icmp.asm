
; input:
;	rsi - pointer to the incoming packet
service_network_icmp:
 ; preserve the original registers
 push rax
 push rbx
 push rcx
 push rsi
 push rdi

 ; a request?
 cmp byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.type], SERVICE_NETWORK_FRAME_ICMP_TYPE_REQUEST
 jne .end ; no, no handling

 ; size of the IP frame header
 movzx ebx, byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.version_and_ihl]
 and bl, SERVICE_NETWORK_FRAME_IP_HEADER_LENGTH_mask
 shl bl, STATIC_MULTIPLE_BY_4_shift

 ; prepare space for the answer
 call kernel_memory_alloc_page
 jc .end ; no free space, do not answer

 ; fill the frames with default values
 mov word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.type], SERVICE_NETWORK_FRAME_ETHERNET_TYPE_ip
 mov byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.version_and_ihl], SERVICE_NETWORK_FRAME_IP_HEADER_LENGTH_default | SERVICE_NETWORK_FRAME_IP_VERSION_4
 mov byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.dscp_and_ecn], STATIC_EMPTY
 mov word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.total_length], (SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.SIZE >> STATIC_REPLACE_AL_WITH_HIGH_shift) | (SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.SIZE << STATIC_REPLACE_AL_WITH_HIGH_shift)
 mov word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.identification], STATIC_EMPTY
 mov word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.f_and_f], STATIC_EMPTY
 mov byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.ttl], SERVICE_NETWORK_FRAME_IP_TTL_default
 mov byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.protocol], SERVICE_NETWORK_FRAME_IP_PROTOCOL_ICMP
 mov word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.type], SERVICE_NETWORK_FRAME_ICMP_TYPE_REPLY
 mov byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.code], STATIC_EMPTY
 mov dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.reserved], STATIC_EMPTY

 ; move the pointer to the ICMP frame
 add rdi, SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE

 ; return the identifier and the sequence
 mov eax, dword [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.reserved]
 mov dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.reserved], eax

 ; clear the old checksum of the ICMP frame
 mov word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.checksum], STATIC_EMPTY

 ; save the pointers
 push rsi
 push rdi

 ; return the ICMP frame data of the client
 mov ecx, SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.SIZE - SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.data
 add rsi, SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.data
 add rdi, SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.data
 rep movsb

 ; restore the pointers
 pop rdi
 pop rsi

 ; compute the checksum
 xor eax, eax
 mov ecx, SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.SIZE >> STATIC_DIVIDE_BY_2_shift
 call service_network_checksum

 ; set the checksum of the ICMP frame
 rol ax, STATIC_REPLACE_AL_WITH_HIGH_shift ; Big-Endian
 mov word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.checksum], ax

 ; move the pointer to the IPv4 frame
 sub rdi, SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE

 ; set the destination IPv4 address
 mov eax, dword [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.source_address]
 mov dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_IP.destination_address], eax

 ; return our IPv4 address
 mov eax, dword [rel driver_nic_i82540em_ipv4_address]
 mov dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_IP.source_address], eax

 ; clear the old checksum of the IPv4 frame
 mov word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_IP.checksum], STATIC_EMPTY

 ; compute the checksum ------------------------------------------------
 xor eax, eax
 mov ecx, (SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.SIZE) >> STATIC_DIVIDE_BY_2_shift
 call service_network_checksum
 rol ax, STATIC_REPLACE_AL_WITH_HIGH_shift ; Big-Endian
 mov word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_IP.checksum], ax

 ; wrap the IP frame
 sub rdi, SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE
 mov rax, qword [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.source]
 mov cx, SERVICE_NETWORK_FRAME_ETHERNET_TYPE_ip
 call service_network_ethernet_wrap

 ; send the answer -----------------------------------------------------
 mov eax, SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.SIZE
 call service_network_transfer

.end:
 ; restore the original registers
 pop rdi
 pop rsi
 pop rcx
 pop rbx
 pop rax

 ; return from the procedure
 jmp service_network_ip.end

 macro_debug "service_network_icmp"
