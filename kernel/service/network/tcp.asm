
 %include "kernel/service/network/wrap.asm"

; input:
;	rsi - pointer to the incoming packet
service_network_tcp:
 ; preserve the original registers
 push rax
 push rcx
 push rdx

 ; fetch the destination port number
 movzx eax, word [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.port_target]
 rol ax, STATIC_REPLACE_AL_WITH_HIGH_shift

 ; is the port supported?
 cmp ax, 512
 jnb .end ; no, ignore the packet

 ; is the destination port empty?
 mov ecx, SERVICE_NETWORK_STRUCTURE_PORT.SIZE
 mul ecx
 add rax, qword [rel service_network_port_table]
 cmp qword [rax], STATIC_EMPTY
 je .end ; yes, ignore the packet

 ; a request to establish a connection?
 cmp byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.flags], SERVICE_NETWORK_FRAME_TCP_FLAGS_syn
 je service_network_tcp_syn ; yes

 ; find the connection related to the packet
 call service_network_tcp_find
 jc .end ; no established connection for the given packet

 ; acceptance of the sent data?
 cmp byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.flags], SERVICE_NETWORK_FRAME_TCP_FLAGS_ack
 je service_network_tcp_ack ; yes

 ; end of the connection?
 test byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.flags], SERVICE_NETWORK_FRAME_TCP_FLAGS_fin
 jnz service_network_tcp_fin ; yes

 ; sending data to the port owner?
 test byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.flags], SERVICE_NETWORK_FRAME_TCP_FLAGS_psh
 jnz service_network_tcp_psh ; yes

.end:
 ; restore the original registers
 pop rdx
 pop rcx
 pop rax

 ; return from the procedure
 jmp service_network.end

 macro_debug "service_network_tcp"

; input:
;	rbx - IP header size
;	rsi - pointer to the incoming packet
;	rdi - pointer to the connection on the stack
service_network_tcp_psh:
 ; preserve the original registers
 push rax
 push rbx
 push rcx
 push rdx
 push rdi
 push rsi

 ; fetch the destination port number
 movzx eax, word [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + rbx + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.port_target]
 rol ax, STATIC_REPLACE_AL_WITH_HIGH_shift ; Little-Endian
 mov ecx, SERVICE_NETWORK_STRUCTURE_PORT.SIZE
 mul ecx ; convert to an offset inside the port table

 ; fetch the data size in the TCP frame
 movzx ecx, word [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.total_length]
 rol cx, STATIC_REPLACE_AL_WITH_HIGH_shift ; Little-Endian
 sub cx, bx ; correct the size by the IP header

 ; save the data size of the TCP frame in a local variable
 push rcx

 ; compute the size of the TCP header
 movzx edx, byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + rbx + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.header_length]
 shr dl, STATIC_MOVE_AL_HALF_TO_HIGH_shift ; move the number of double words to the lower position
 shl dx, STATIC_MULTIPLE_BY_4_shift ; convert the number of double words to Bytes

 ; move to the beginning of the packet space
 mov rdi, rsi

 ; content of the TCP frame data
 add rsi, SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE
 add rsi, rbx
 add rsi, rdx

 ; execute
 rep movsb

 ; clear the remaining frame space
 mov rcx, STATIC_PAGE_SIZE_byte
 sub rcx, qword [rsp]
 rep stosb

 ; fetch the PID of the destination process
 mov rbx, qword [rel service_network_port_table]
 mov rbx, qword [rbx + rax]

 ; send a message to the process
 xor ecx, ecx
 mov rsi, rsp
 call kernel_ipc_insert

 ; release the local variable
 add rsp, STATIC_QWORD_SIZE_byte

 ; the space handed over to the process
 mov qword [rsp], STATIC_EMPTY

.end:
 ; restore the original registers
 pop rsi
 pop rdi
 pop rdx
 pop rcx
 pop rbx
 pop rax

 ; return from the procedure
 jmp service_network_tcp.end

 macro_debug "service_network_tcp_psh_ack"

; input:
;	rbx - IP header size
;	rsi - pointer to the incoming packet
;	rdi - pointer to the connection on the stack
service_network_tcp_fin:
 ; preserve the original registers
 push rax
 push rbx
 push rcx
 push rsi
 push rdi

 ; set the pointer to the connection in the source register
 xchg rsi, rdi

 ; remove the ACK flag even if it was not expected
 and byte [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags_request], ~SERVICE_NETWORK_FRAME_TCP_FLAGS_ack


 ; save the sender sequence number
 mov eax, dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + rbx + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.sequence]
 bswap eax ; save in the Little-Endian format
 inc eax ; acknowledge the receipt of the wish to end the connection
 mov dword [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_sequence], eax


 ; our sequence number
 mov eax, dword [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.request_acknowledgement]
 inc eax
 mov dword [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.host_sequence], eax

 ; our identifier
 inc eax
 mov dword [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.request_acknowledgement], eax


 ; closing the connection
 mov word [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags], SERVICE_NETWORK_FRAME_TCP_FLAGS_ack | SERVICE_NETWORK_FRAME_TCP_FLAGS_fin

 ; expect the ACK flag in the response
 mov word [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags_request], SERVICE_NETWORK_FRAME_TCP_FLAGS_ack

 ; send the response

 ; prepare space for the response
 call kernel_memory_alloc_page
 jc .error

 ; wrap the TCP frame data
 mov bl, (SERVICE_NETWORK_STRUCTURE_FRAME_TCP.SIZE >> STATIC_DIVIDE_BY_4_shift) << STATIC_MOVE_AL_HALF_TO_HIGH_shift
 mov ecx, SERVICE_NETWORK_STRUCTURE_FRAME_TCP.SIZE
 call service_network_tcp_wrap

 ; send the packet
 mov eax, SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.SIZE + STATIC_DWORD_SIZE_byte
 call service_network_transfer

 ; the connection was confirmed
 jmp .end

.error:
 ; unregister the connection
 mov byte [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.status], STATIC_EMPTY

.end:
 ; restore the original registers
 pop rdi
 pop rsi
 pop rcx
 pop rbx
 pop rax

 ; return from the procedure
 jmp service_network_tcp.end

 macro_debug "service_network_tcp_fin"

; input:
;	rsi - pointer to the incoming packet
;	rdi - pointer to the connection on the stack
service_network_tcp_ack:
 ; preserve the original registers
 push rsi
 push rdi

 ; did we expect an acknowledgement?
 test word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags_request], SERVICE_NETWORK_FRAME_TCP_FLAGS_ack
 jz .end ; no

 ; remove the expected flag from the stack
 and word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags_request], ~SERVICE_NETWORK_FRAME_TCP_FLAGS_ack

 ; has the connection been ended?
 test word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags], SERVICE_NETWORK_FRAME_TCP_FLAGS_fin | SERVICE_NETWORK_FRAME_TCP_FLAGS_ack
 jz .end ; no

 ; free the stack entry related to the connection
 mov word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags], STATIC_EMPTY

.end:
 ; restore the original registers
 pop rdi
 pop rsi

 ; return from the procedure
 jmp service_network_tcp.end

 macro_debug "service_network_tcp_ack"

; input:
;	rsi - pointer to the incoming packet
; output:
;	rbx - size of the IP frame header
;	rdi - pointer to the connection
service_network_tcp_find:
 ; preserve the original registers
 push rax
 push rcx
 push rbx
 push rdi

 ; size of the IP frame header
 movzx ebx, byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.version_and_ihl]
 and bl, SERVICE_NETWORK_FRAME_IP_HEADER_LENGTH_mask
 shl bl, STATIC_MULTIPLE_BY_4_shift

 ; search the TCP stack
 mov rcx, (SERVICE_NETWORK_STACK_SIZE_page << STATIC_PAGE_SIZE_shift) / SERVICE_NETWORK_STRUCTURE_TCP_STACK.SIZE
 mov rdi, qword [rel service_network_stack_address]

.loop:
 ; is the client MAC address correct?
 mov eax, dword [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.source]
 rol rax, STATIC_REPLACE_EAX_WITH_HIGH_shift
 mov ax, word [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.source + SERVICE_NETWORK_STRUCTURE_MAC.4]
 ror rax, STATIC_REPLACE_EAX_WITH_HIGH_shift
 cmp qword [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_mac], rax
 jne .next ; no, next entry

 ; is the client IPv4 address correct?
 mov eax, dword [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_ipv4]
 cmp dword [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.source_address], eax
 jne .next ; no, next entry

 ; is the destination port correct?
 mov ax, word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.host_port]
 cmp word [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + rbx + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.port_target], ax
 jne .next ; no, next entry

 ; is the source port correct?
 mov ax, word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_port]
 cmp word [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + rbx + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.port_source], ax
 je .found ; no, next entry

.next:
 ; move the pointer to the next entry
 add rdi, SERVICE_NETWORK_STRUCTURE_TCP_STACK.SIZE

 ; end of the stack?
 dec rcx
 jnz .loop ; no

 ; no registered connection for the incoming packet
 stc

 ; end of the procedure
 jmp .end

.found:
 ; return the size of the IPv4 header
 mov qword [rsp + STATIC_QWORD_SIZE_byte], rbx

 ; return the pointer to the connection
 mov qword [rsp], rdi

.end:
 ; restore the original registers
 pop rdi
 pop rbx
 pop rcx
 pop rax

 ; return from the procedure
 ret

 macro_debug "service_network_tcp_find"

; input:
;	rsi - pointer to the incoming packet
service_network_tcp_syn:
 ; preserve the original registers
 push rax
 push rbx
 push rcx
 push rsi
 push rdi

 ; search the TCP stack
 mov rcx, (SERVICE_NETWORK_STACK_SIZE_page << STATIC_PAGE_SIZE_shift) / SERVICE_NETWORK_STRUCTURE_TCP_STACK.SIZE
 mov rdi, qword [rel service_network_stack_address]

.search:
 ; for a free slot
 lock bts word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.status], SERVICE_NETWORK_STACK_FLAG_busy
 jnc .found ; found

 ; move the pointer to the next connection entry
 add rdi, SERVICE_NETWORK_STRUCTURE_TCP_STACK.SIZE

 ; has the whole TCP stack been searched?
 dec rcx
 jnz .search ; no, keep searching

 ; no space to register a new connection
 jmp .end

.found:
 ; register the connection on the stack

 ; compute the size of the IP frame
 movzx ecx, byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.version_and_ihl]
 and cl, SERVICE_NETWORK_FRAME_IP_HEADER_LENGTH_mask
 shl cl, STATIC_MULTIPLE_BY_4_shift

 ; convert to the absolute position of the TCP frame
 add ecx, SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE


 ; save the service port number
 mov ax, word [rsi + rcx + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.port_target]
 mov word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.host_port], ax

 ; save the sender port number
 mov ax, word [rsi + rcx + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.port_source]
 mov word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_port], ax

 ; save the sender sequence number
 mov eax, dword [rsi + rcx + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.sequence]
 bswap eax ; in the Little-Endian format
 mov dword [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_sequence], eax

 ; save the sender MAC address
 mov rcx, qword [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.source]
 shl rcx, STATIC_MOVE_AX_TO_HIGH_shift
 shr rcx, STATIC_MOVE_HIGH_TO_AX_shift
 mov qword [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_mac], rcx

 ; save the sender IPv4 address
 mov ecx, dword [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.source_address]
 mov dword [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_ipv4], ecx


 ; our sequence number
 mov dword [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.host_sequence], STATIC_EMPTY

 ; default window size
 mov word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.window_size], SERVICE_NETWORK_FRAME_TCP_WINDOW_SIZE_default


 ; current flags of the connection
 mov word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags], SERVICE_NETWORK_FRAME_TCP_FLAGS_syn | SERVICE_NETWORK_FRAME_TCP_FLAGS_ack

 ; expect the ACK flag in the response
 mov word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags_request], SERVICE_NETWORK_FRAME_TCP_FLAGS_ack

 ; connection registered
 mov rsi, rdi

 ; send the response
 call service_network_tcp_reply

.end:
 ; restore the original registers
 pop rdi
 pop rsi
 pop rcx
 pop rbx
 pop rax

 ; return from the procedure
 jmp service_network_tcp.end

 macro_debug "service_network_tcp_syn"

; input:
;	rsi - pointer to the connection on the stack
service_network_tcp_reply:
 ; preserve the original registers
 push rax
 push rbx
 push rcx
 push rdi

 ; prepare space for the response
 call kernel_memory_alloc_page

 ; wrap the TCP frame data
 mov bl, (SERVICE_NETWORK_STRUCTURE_FRAME_TCP.SIZE >> STATIC_DIVIDE_BY_4_shift) << STATIC_MOVE_AL_HALF_TO_HIGH_shift
 mov ecx, SERVICE_NETWORK_STRUCTURE_FRAME_TCP.SIZE
 call service_network_tcp_wrap

 ; send the packet
 mov eax, SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.SIZE + STATIC_DWORD_SIZE_byte
 call service_network_transfer

 ; restore the original registers
 pop rdi
 pop rcx
 pop rbx
 pop rax

 ; return from the procedure
 ret

; input:
;	ecx - TCP frame size in Bytes
;	rsi - pointer to the connection properties
;	rdi - pointer to the space of the packet to send
; output:
;	eax - checksum of the pseudo header
service_network_tcp_pseudo_header:
 ; preserve the original registers
 push rcx
 push rdi

 ; configure the pseudo header

 ; sender
 mov eax, dword [rel driver_nic_i82540em_ipv4_address]
 mov dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE - SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.source_ipv4], eax

 ; recipient
 mov eax, dword [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_ipv4]
 mov dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE - SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.target_ipv4], eax

 ; clear the reserved value
 mov byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE - SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.reserved], STATIC_EMPTY

 ; protocol
 mov byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE - SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.protocol], SERVICE_NETWORK_FRAME_TCP_PROTOCOL_default

 ; size of the TCP frame
 rol cx, STATIC_REPLACE_AL_WITH_HIGH_shift ; convert to Big-Endian
 mov word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE - SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.segment_length], cx

 ; compute the checksum of the pseudo header
 xor eax, eax
 mov ecx, SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE >> STATIC_DIVIDE_BY_2_shift
 add rdi, SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE - SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE
 call service_network_checksum_part

 ; restore the original registers
 pop rdi
 pop rcx

 ; return from the subprocedure
 ret

 macro_debug "service_network_tcp_pseudo_header"

; input:
;	cx - port number
; output:
;	CF flag, if busy
service_network_tcp_port_assign:
 ; preserve the original registers
 push rax
 push rcx
 push rdx
 push rdi

 ; lock access to the port table
 macro_lock service_network_port_semaphore, 0

 ; is the port number supported?
 cmp cx, 512
 jnb .error ; no

 ; convert the port number to an indirect pointer
 mov eax, SERVICE_NETWORK_STRUCTURE_PORT.SIZE
 and ecx, STATIC_WORD_mask
 mul ecx

 ; fetch the PID of the calling process
 call kernel_task_active
 mov rcx, qword [rdi + KERNEL_TASK_STRUCTURE.pid]

 ; load the owner identifier into the port table (at the same time clear the flags)
 mov rdi, qword [rel service_network_port_table]
 test rdi, rdi
 jz .error ; the network service is not initialised

 ; is the port busy?
 cmp qword [rdi + rcx + SERVICE_NETWORK_STRUCTURE_PORT.pid], STATIC_EMPTY
 jne .error ; yes

 ; reserve the port for the process with the given PID
 mov qword [rdi + rax + SERVICE_NETWORK_STRUCTURE_PORT.pid], rcx

 ; registered
 jmp .end

.error:
 ; the port is unavailable
 stc

.end:
 ; release access to the port table
 mov byte [rel service_network_port_semaphore], STATIC_FALSE

 ; restore the original registers
 pop rdi
 pop rdx
 pop rcx
 pop rax

 ; return from the procedure
 ret

 macro_debug "service_network_tcp_port_assign"

; input:
;	rbx - connection identifier
;	rcx - data size in Bytes
;	rsi - pointer to the data space
service_network_tcp_port_send:
 ; preserve the original registers
 push rax
 push rbx
 push rcx
 push rsi
 push rdi

 ; prepare space for the response
 call kernel_memory_alloc_page
 jc .end ; no space

 ; save the size and the pointer to the data space
 push rcx
 push rdi

 ; attach the response data
 add rdi, SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.SIZE
 rep movsb

 ; restore the size and the pointer to the data space
 pop rdi
 pop rcx

 inc dword [rbx + SERVICE_NETWORK_STRUCTURE_TCP_STACK.host_sequence]
 mov byte [rbx + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags], SERVICE_NETWORK_FRAME_TCP_FLAGS_psh | SERVICE_NETWORK_FRAME_TCP_FLAGS_ack

 ; fill the packet frames
 add rcx, SERVICE_NETWORK_STRUCTURE_FRAME_TCP.SIZE + 0x01
 mov rsi, rbx
 mov bl, SERVICE_NETWORK_FRAME_TCP_HEADER_LENGTH_default
 call service_network_tcp_wrap

 ; send the packet
 mov rax, rcx
 add rax, SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE
 call service_network_transfer

.end:
 ; restore the original registers
 pop rdi
 pop rsi
 pop rcx
 pop rbx
 pop rax

 ; return from the procedure
 ret

 macro_debug "service_network_tcp_port_send"
