KERNEL_NETWORK_RECEIVE_PUSH_WAIT_limit equ 3

KERNEL_NETWORK_MAC_mask equ 0x0000FFFFFFFFFFFF

KERNEL_NETWORK_PORT_SIZE_page equ 0x01
KERNEL_NETWORK_PORT_FLAG_empty equ 000000001b
KERNEL_NETWORK_PORT_FLAG_received equ 000000010b
KERNEL_NETWORK_PORT_FLAG_send equ 000000100b
KERNEL_NETWORK_PORT_FLAG_BIT_empty equ 0
KERNEL_NETWORK_PORT_FLAG_BIT_received equ 1
KERNEL_NETWORK_PORT_FLAG_BIT_send equ 2

KERNEL_NETWORK_STACK_SIZE_page equ 0x01
KERNEL_NETWORK_STACK_FLAG_busy equ 10000000b

KERNEL_NETWORK_FRAME_ETHERNET_TYPE_arp equ 0x0608
KERNEL_NETWORK_FRAME_ETHERNET_TYPE_ip equ 0x0008

KERNEL_NETWORK_FRAME_ARP_HTYPE_ethernet equ 0x0100
KERNEL_NETWORK_FRAME_ARP_PTYPE_ipv4 equ 0x0008
KERNEL_NETWORK_FRAME_ARP_HAL_mac equ 0x06
KERNEL_NETWORK_FRAME_ARP_PAL_ipv4 equ 0x04
KERNEL_NETWORK_FRAME_ARP_OPCODE_request equ 0x0100
KERNEL_NETWORK_FRAME_ARP_OPCODE_answer equ 0x0200

KERNEL_NETWORK_FRAME_IP_HEADER_LENGTH_default equ 0x05
KERNEL_NETWORK_FRAME_IP_HEADER_LENGTH_mask equ 0x0F
KERNEL_NETWORK_FRAME_IP_VERSION_mask equ 0xF0
KERNEL_NETWORK_FRAME_IP_VERSION_4 equ 0x40
KERNEL_NETWORK_FRAME_IP_PROTOCOL_ICMP equ 0x01
KERNEL_NETWORK_FRAME_IP_PROTOCOL_TCP equ 0x06
KERNEL_NETWORK_FRAME_IP_PROTOCOL_UDP equ 0x11
KERNEL_NETWORK_FRAME_IP_TTL_default equ 0x40
KERNEL_NETWORK_FRAME_IP_F_AND_F_do_not_fragment equ 0x0040

KERNEL_NETWORK_FRAME_ICMP_TYPE_REQUEST equ 0x08
KERNEL_NETWORK_FRAME_ICMP_TYPE_REPLY equ 0x00

KERNEL_NETWORK_FRAME_TCP_HEADER_LENGTH_default equ 0x50
KERNEL_NETWORK_FRAME_TCP_FLAGS_fin equ 0000000000000001b
KERNEL_NETWORK_FRAME_TCP_FLAGS_syn equ 0000000000000010b
KERNEL_NETWORK_FRAME_TCP_FLAGS_rst equ 0000000000000100b
KERNEL_NETWORK_FRAME_TCP_FLAGS_psh equ 0000000000001000b
KERNEL_NETWORK_FRAME_TCP_FLAGS_ack equ 0000000000010000b
KERNEL_NETWORK_FRAME_TCP_FLAGS_urg equ 0000000000100000b
KERNEL_NETWORK_FRAME_TCP_FLAGS_bsy equ 0000100000000000b
KERNEL_NETWORK_FRAME_TCP_FLAGS_bsy_bit equ 11
KERNEL_NETWORK_FRAME_TCP_OPTION_MSS_default equ 0xB4050402
KERNEL_NETWORK_FRAME_TCP_OPTION_KIND_mss equ 0x02
KERNEL_NETWORK_FRAME_TCP_PROTOCOL_default equ 0x06
KERNEL_NETWORK_FRAME_TCP_WINDOW_SIZE_default equ 0x05B4

struc KERNEL_NETWORK_STRUCTURE_MAC
 .0 resb 1
 .1 resb 1
 .2 resb 1
 .3 resb 1
 .4 resb 1
 .5 resb 1
 .SIZE:
endstruc

struc KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET
 .target resb 0x06
 .source resb 0x06
 .type resb 0x02
 .SIZE:
endstruc

struc KERNEL_NETWORK_STRUCTURE_FRAME_ARP
 .htype resb 0x02
 .ptype resb 0x02
 .hal resb 0x01
 .pal resb 0x01
 .opcode resb 0x02
 .source_mac resb 0x06
 .source_ip resb 0x04
 .target_mac resb 0x06
 .target_ip resb 0x04
 .SIZE:
endstruc

struc KERNEL_NETWORK_STRUCTURE_FRAME_IP
 .version_and_ihl resb 0x01
 .dscp_and_ecn resb 0x01
 .total_length resb 0x02
 .identification resb 0x02
 .f_and_f resb 0x02
 .ttl resb 0x01
 .protocol resb 0x01
 .checksum resb 0x02
 .source_address resb 0x04
 .destination_address resb 0x04
 .SIZE:
endstruc

struc KERNEL_NETWORK_STRUCTURE_FRAME_ICMP
 .type resb 0x01
 .code resb 0x01
 .checksum resb 0x02
 .reserved resb 0x04
 .SIZE:
endstruc

struc KERNEL_NETWORK_STRUCTURE_FRAME_UDP
 .port_source resb 0x02
 .port_target resb 0x02
 .length resb 0x02
 .checksum resb 0x02
 .SIZE:
endstruc

struc KERNEL_NETWORK_STRUCTURE_FRAME_TCP
 .port_source resb 0x02
 .port_target resb 0x02
 .sequence resb 0x04
 .acknowledgement resb 0x04
 .header_length resb 0x01
 .flags resb 0x01
 .window_size resb 0x02
 .checksum_and_urgent_pointer:
 .checksum resb 0x02
 .urgent_pointer resb 0x02
 .SIZE:
 .options:
endstruc

struc KERNEL_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER
 .source_ipv4 resb 4
 .target_ipv4 resb 4
 .reserved resb 1
 .protocol resb 1
 .segment_length resb 2
 .SIZE:
endstruc

struc KERNEL_NETWORK_STRUCTURE_TCP_STACK
 .source_mac resb 8
 .source_ipv4 resb 4
 .source_sequence resb 4
 .host_sequence resb 4
 .request_acknowledgement resb 4
 .window_size resb 2
 .source_port resb 2
 .host_port resb 2
 .status resb 2
 .flags resb 2
 .flags_request resb 2
 .identification resb 2
 .SIZE:
endstruc

struc KERNEL_NETWORK_STRUCTURE_PORT
 .cr3_and_flags resb 8
 .tcp_connection resb 8
 .size resb 8
 .address resb 8
 .SIZE:
endstruc

kernel_network_rx_count dq STATIC_EMPTY
kernel_network_tx_count dq STATIC_EMPTY

kernel_network_port_table dq STATIC_EMPTY

kernel_network_stack_address dq STATIC_EMPTY

kernel_network:
 xor ebp, ebp

 cmp word [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.type], KERNEL_NETWORK_FRAME_ETHERNET_TYPE_arp
 je kernel_network_arp

 cmp word [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.type], KERNEL_NETWORK_FRAME_ETHERNET_TYPE_ip
 je kernel_network_ip


.end:
 test rsi, rsi
 jz .empty

 mov rdi, rsi
 call kernel_memory_release_page

.empty:
 jmp kernel_task_kill_me

 macro_debug "kernel_network"

kernel_network_tcp_port_send:
 push rax
 push rbx
 push rcx
 push rsi
 push rdi

 call kernel_memory_alloc_page
 jc .end

 push rcx
 push rdi

 add rdi, KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.SIZE
 rep movsb

 pop rdi
 pop rcx

 inc dword [rbx + KERNEL_NETWORK_STRUCTURE_TCP_STACK.host_sequence]
 mov byte [rbx + KERNEL_NETWORK_STRUCTURE_TCP_STACK.flags], KERNEL_NETWORK_FRAME_TCP_FLAGS_psh | KERNEL_NETWORK_FRAME_TCP_FLAGS_ack

 add rcx, KERNEL_NETWORK_STRUCTURE_FRAME_TCP.SIZE + 0x01
 mov rsi, rbx
 mov bl, KERNEL_NETWORK_FRAME_TCP_HEADER_LENGTH_default
 call kernel_network_tcp_wrap

 mov rax, rcx
 add rax, KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE
 call service_tx_add

.end:
 pop rdi
 pop rsi
 pop rcx
 pop rbx
 pop rax

 ret

kernel_network_ip:
 cmp byte [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.protocol], KERNEL_NETWORK_FRAME_IP_PROTOCOL_ICMP
 je kernel_network_icmp

 cmp byte [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.protocol], KERNEL_NETWORK_FRAME_IP_PROTOCOL_TCP
 je kernel_network_tcp

.end:
 jmp kernel_network.end

 macro_debug "kernel_network_ip"

kernel_network_tcp:
 push rax

 movzx eax, word [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.port_target]
 rol ax, STATIC_REPLACE_AL_WITH_HIGH_shift

 cmp ax, 512
 jnb .end

 shl eax, STATIC_MULTIPLE_BY_32_shift
 add rax, qword [kernel_network_port_table]
 cmp qword [rax], STATIC_EMPTY
 je .end

 cmp byte [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.flags], KERNEL_NETWORK_FRAME_TCP_FLAGS_syn
 je kernel_network_tcp_syn

 call kernel_network_tcp_find
 jc .end

 cmp byte [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.flags], KERNEL_NETWORK_FRAME_TCP_FLAGS_ack
 je kernel_network_tcp_ack

 test byte [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.flags], KERNEL_NETWORK_FRAME_TCP_FLAGS_fin
 jnz kernel_network_tcp_fin

 test byte [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.flags], KERNEL_NETWORK_FRAME_TCP_FLAGS_psh | KERNEL_NETWORK_FRAME_TCP_FLAGS_ack
 jnz kernel_network_tcp_psh_ack

.end:
 pop rax

 add rsp, STATIC_QWORD_SIZE_byte

 jmp kernel_network.end

 macro_debug "kernel_network_tcp"

kernel_network_tcp_psh_ack:
 push rax
 push rcx
 push rdx
 push rdi
 push rsi

 movzx ecx, word [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.total_length]
 rol cx, STATIC_REPLACE_AL_WITH_HIGH_shift
 sub cx, bx

 push rcx

 movzx eax, word [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + rbx + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.port_target]
 rol ax, STATIC_REPLACE_AL_WITH_HIGH_shift
 shl rax, STATIC_MULTIPLE_BY_32_shift

 movzx edx, byte [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + rbx + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.header_length]
 shr dl, STATIC_MOVE_AL_HALF_TO_HIGH_shift
 shl dx, STATIC_MULTIPLE_BY_4_shift

 mov rdi, rsi

 add rsi, KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE
 add rsi, rbx
 add rsi, rdx

 rep movsb

 mov rcx, KERNEL_PAGE_SIZE_byte
 sub rcx, qword [rsp]
 rep stosb

 mov rsi, qword [kernel_network_port_table]
 add rsi, rax

 mov cl, KERNEL_NETWORK_RECEIVE_PUSH_WAIT_limit

.wait:
 bts word [rsi + KERNEL_NETWORK_STRUCTURE_PORT.cr3_and_flags], KERNEL_NETWORK_PORT_FLAG_BIT_empty
 jnc .empty

 hlt

 dec cl
 jnz .wait


 add rsp, STATIC_QWORD_SIZE_byte

 jmp .end

.empty:

 mov rax, qword [rsp + STATIC_QWORD_SIZE_byte * 0x02]
 mov qword [rsi + KERNEL_NETWORK_STRUCTURE_PORT.tcp_connection], rax

 pop qword [rsi + KERNEL_NETWORK_STRUCTURE_PORT.size]

 mov rax, qword [rsp]
 mov qword [rsi + KERNEL_NETWORK_STRUCTURE_PORT.address], rax

 or byte [rsi + KERNEL_NETWORK_STRUCTURE_PORT.cr3_and_flags], KERNEL_NETWORK_PORT_FLAG_received

 mov qword [rsp], STATIC_EMPTY

.end:
 pop rsi
 pop rdi
 pop rdx
 pop rcx
 pop rax

 jmp kernel_network_tcp.end

 macro_debug "kernel_network_tcp_psh_ack"

kernel_network_tcp_fin:
 push rax
 push rbx
 push rcx
 push rsi
 push rdi

 xchg rsi, rdi

 and byte [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.flags_request], ~KERNEL_NETWORK_FRAME_TCP_FLAGS_ack


 mov eax, dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + rbx + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.sequence]
 bswap eax
 inc eax
 mov dword [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.source_sequence], eax


 mov eax, dword [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.request_acknowledgement]
 inc eax
 mov dword [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.host_sequence], eax

 inc eax
 mov dword [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.request_acknowledgement], eax


 mov word [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.flags], KERNEL_NETWORK_FRAME_TCP_FLAGS_ack | KERNEL_NETWORK_FRAME_TCP_FLAGS_fin

 mov word [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.flags_request], KERNEL_NETWORK_FRAME_TCP_FLAGS_ack


 call kernel_memory_alloc_page
 jc .error

 mov bl, (KERNEL_NETWORK_STRUCTURE_FRAME_TCP.SIZE >> STATIC_DIVIDE_BY_4_shift) << STATIC_MOVE_AL_HALF_TO_HIGH_shift
 mov ecx, KERNEL_NETWORK_STRUCTURE_FRAME_TCP.SIZE
 call kernel_network_tcp_wrap

 mov ax, KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.SIZE + STATIC_DWORD_SIZE_byte
 call service_tx_add

 jmp .end

.error:
 mov byte [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.status], STATIC_EMPTY

.end:
 pop rdi
 pop rsi
 pop rcx
 pop rbx
 pop rax

 jmp kernel_network_tcp.end

 macro_debug "kernel_network_tcp_fin"

kernel_network_tcp_ack:
 push rsi
 push rdi

 test word [rdi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.flags_request], KERNEL_NETWORK_FRAME_TCP_FLAGS_ack
 jz .end

 and word [rdi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.flags_request], ~KERNEL_NETWORK_FRAME_TCP_FLAGS_ack

 test word [rdi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.flags], KERNEL_NETWORK_FRAME_TCP_FLAGS_fin | KERNEL_NETWORK_FRAME_TCP_FLAGS_ack
 jz .end

 mov word [rdi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.flags], STATIC_EMPTY

.end:
 pop rdi
 pop rsi

 jmp kernel_network_tcp.end

 macro_debug "kernel_network_tcp_ack"

kernel_network_tcp_find:
 push rax
 push rcx
 push rbx
 push rdi

 movzx ebx, byte [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.version_and_ihl]
 and bl, KERNEL_NETWORK_FRAME_IP_HEADER_LENGTH_mask
 shl bl, STATIC_MULTIPLE_BY_4_shift

 mov rcx, (KERNEL_NETWORK_STACK_SIZE_page << KERNEL_PAGE_SIZE_shift) / KERNEL_NETWORK_STRUCTURE_TCP_STACK.SIZE
 mov rdi, qword [kernel_network_stack_address]

.loop:
 mov eax, dword [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.source]
 rol rax, STATIC_REPLACE_EAX_WITH_HIGH_shift
 mov ax, word [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.source + KERNEL_NETWORK_STRUCTURE_MAC.4]
 ror rax, STATIC_REPLACE_EAX_WITH_HIGH_shift
 cmp qword [rdi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.source_mac], rax
 jne .next

 mov eax, dword [rdi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.source_ipv4]
 cmp dword [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.source_address], eax
 jne .next

 mov ax, word [rdi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.host_port]
 cmp word [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + rbx + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.port_target], ax
 jne .next

 mov ax, word [rdi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.source_port]
 cmp word [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + rbx + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.port_source], ax
 je .found

.next:
 add rdi, KERNEL_NETWORK_STRUCTURE_TCP_STACK.SIZE

 dec rcx
 jnz .loop

 stc

 jmp .end

.found:
 mov qword [rsp + STATIC_QWORD_SIZE_byte], rbx

 mov qword [rsp], rdi

.end:
 pop rdi
 pop rbx
 pop rcx
 pop rax

 ret

 macro_debug "kernel_network_tcp_find"

kernel_network_tcp_syn:
 push rax
 push rbx
 push rcx
 push rsi
 push rdi

 mov rcx, (KERNEL_NETWORK_STACK_SIZE_page << KERNEL_PAGE_SIZE_shift) / KERNEL_NETWORK_STRUCTURE_TCP_STACK.SIZE
 mov rdi, qword [kernel_network_stack_address]

.search:
 lock bts word [rdi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.status], KERNEL_NETWORK_STACK_FLAG_busy
 jnc .found

 add rdi, KERNEL_NETWORK_STRUCTURE_TCP_STACK.SIZE

 dec rcx
 jnz .search

 jmp .end

.found:

 movzx ecx, byte [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.version_and_ihl]
 and cl, KERNEL_NETWORK_FRAME_IP_HEADER_LENGTH_mask
 shl cl, STATIC_MULTIPLE_BY_4_shift

 add ecx, KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE


 mov ax, word [rsi + rcx + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.port_target]
 mov word [rdi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.host_port], ax

 mov ax, word [rsi + rcx + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.port_source]
 mov word [rdi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.source_port], ax

 mov eax, dword [rsi + rcx + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.sequence]
 bswap eax
 inc eax
 mov dword [rdi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.source_sequence], eax

 mov rcx, qword [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.source]
 shl rcx, STATIC_MOVE_AX_TO_HIGH_shift
 shr rcx, STATIC_MOVE_HIGH_TO_AX_shift
 mov qword [rdi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.source_mac], rcx

 mov ecx, dword [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.source_address]
 mov dword [rdi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.source_ipv4], ecx


 mov word [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.request_acknowledgement], STATIC_EMPTY + 0x01

 mov dword [rdi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.host_sequence], STATIC_EMPTY

 mov word [rdi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.window_size], KERNEL_NETWORK_FRAME_TCP_WINDOW_SIZE_default


 mov word [rdi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.flags], KERNEL_NETWORK_FRAME_TCP_FLAGS_syn | KERNEL_NETWORK_FRAME_TCP_FLAGS_ack

 mov word [rdi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.flags_request], KERNEL_NETWORK_FRAME_TCP_FLAGS_ack

 mov rsi, rdi


 call kernel_memory_alloc_page
 jc .error

 mov bl, (KERNEL_NETWORK_STRUCTURE_FRAME_TCP.SIZE >> STATIC_DIVIDE_BY_4_shift) << STATIC_MOVE_AL_HALF_TO_HIGH_shift
 mov ecx, KERNEL_NETWORK_STRUCTURE_FRAME_TCP.SIZE
 call kernel_network_tcp_wrap

 mov ax, KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.SIZE + STATIC_DWORD_SIZE_byte
 call service_tx_add

 jmp .end

.error:
 mov byte [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.status], STATIC_EMPTY

.end:
 pop rdi
 pop rsi
 pop rcx
 pop rbx
 pop rax

 jmp kernel_network_tcp.end

 macro_debug "kernel_network_tcp_syn"

kernel_network_tcp_wrap:
 push rax
 push rbx
 push rcx
 push rdi

 mov ax, word [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.host_port]
 mov word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.port_source], ax
 mov ax, word [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.source_port]
 mov word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.port_target], ax

 mov eax, dword [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.host_sequence]
 bswap eax
 mov dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.sequence], eax

 mov eax, dword [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.source_sequence]
 bswap eax
 mov dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.acknowledgement], eax

 mov byte [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.header_length], bl

 mov al, byte [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.flags]
 mov byte [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.flags], al

 mov ax, word [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.window_size]
 rol ax, STATIC_REPLACE_AL_WITH_HIGH_shift
 mov word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.window_size], ax

 mov dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.checksum_and_urgent_pointer], STATIC_EMPTY

 call kernel_network_tcp_pseudo_header

 shr ecx, STATIC_DIVIDE_BY_2_shift
 add rdi, KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE
 call kernel_network_checksum
 rol ax, STATIC_REPLACE_AL_WITH_HIGH_shift
 mov word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.checksum], ax

 mov rax, qword [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.source_mac]
 mov bl, KERNEL_NETWORK_FRAME_IP_PROTOCOL_TCP
 shl ecx, STATIC_MULTIPLE_BY_2_shift
 sub rdi, KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE
 call kernel_network_ip_wrap

 pop rdi
 pop rcx
 pop rbx
 pop rax

 ret

 macro_debug "kernel_network_tcp_wrap"

kernel_network_ip_wrap:
 push rcx
 push rax

 mov byte [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.version_and_ihl], KERNEL_NETWORK_FRAME_IP_VERSION_4 | KERNEL_NETWORK_FRAME_IP_HEADER_LENGTH_default

 mov byte [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.dscp_and_ecn], STATIC_EMPTY

 add cx, KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE
 rol cx, STATIC_REPLACE_AL_WITH_HIGH_shift
 mov word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.total_length], cx

 inc word [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.identification]
 mov ax, word [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.identification]
 mov word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.identification], ax

 mov word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.f_and_f], KERNEL_NETWORK_FRAME_IP_F_AND_F_do_not_fragment

 mov byte [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.ttl], KERNEL_NETWORK_FRAME_IP_TTL_default

 mov byte [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.protocol], bl

 mov word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.checksum], STATIC_EMPTY

 mov eax, dword [driver_nic_i82540em_ipv4_address]
 mov dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.source_address], eax

 mov eax, dword [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.source_ipv4]
 mov dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.destination_address], eax

 xor eax, eax
 mov ecx, KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE >> STATIC_DIVIDE_BY_2_shift
 add rdi, KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE
 call kernel_network_checksum
 rol ax, STATIC_REPLACE_AL_WITH_HIGH_shift
 sub rdi, KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE
 mov word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.checksum], ax

 pop rax
 mov cx, KERNEL_NETWORK_FRAME_ETHERNET_TYPE_ip
 call kernel_network_ethernet_wrap

 pop rcx

 ret

 macro_debug "kernel_network_ip_wrap"

kernel_network_tcp_pseudo_header:
 push rcx
 push rdi


 mov eax, dword [driver_nic_i82540em_ipv4_address]
 mov dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE - KERNEL_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.source_ipv4], eax

 mov eax, dword [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.source_ipv4]
 mov dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE - KERNEL_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.target_ipv4], eax

 mov byte [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE - KERNEL_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.reserved], STATIC_EMPTY

 mov byte [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE - KERNEL_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.protocol], KERNEL_NETWORK_FRAME_TCP_PROTOCOL_default

 rol cx, STATIC_REPLACE_AL_WITH_HIGH_shift
 mov word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE - KERNEL_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.segment_length], cx

 xor eax, eax
 mov ecx, KERNEL_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE >> STATIC_DIVIDE_BY_2_shift
 add rdi, KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE - KERNEL_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE
 call kernel_network_checksum_part

 pop rdi
 pop rcx

 ret

 macro_debug "kernel_network_tcp_pseudo_header"

kernel_network_tcp_port_assign:
 push rax
 push rcx
 push rdi

 cmp cx, 512
 jnb .error

 and ecx, STATIC_WORD_mask
 shl cx, STATIC_MULTIPLE_BY_32_shift

 mov rax, cr3

 mov rdi, qword [kernel_network_port_table]
 mov qword [rdi + rcx], rax

 jmp .end

.error:
 stc

.end:
 pop rdi
 pop rcx
 pop rax

 ret

 macro_debug "kernel_network_tcp_port_assign"

kernel_network_tcp_port_receive:
 push rax
 push rcx
 push rsi

 and ecx, STATIC_WORD_mask
 shl cx, STATIC_MULTIPLE_BY_32_shift

 mov rsi, qword [kernel_network_port_table]
 add rsi, rcx

 mov rax, cr3

 mov rcx, qword [rsi + KERNEL_NETWORK_STRUCTURE_PORT.cr3_and_flags]
 and cx, KERNEL_PAGE_mask
 cmp rcx, rax
 jne .error

 test word [rsi + KERNEL_NETWORK_STRUCTURE_PORT.cr3_and_flags], KERNEL_NETWORK_PORT_FLAG_empty | KERNEL_NETWORK_PORT_FLAG_received
 jz .error

 and word [rsi + KERNEL_NETWORK_STRUCTURE_PORT.cr3_and_flags], ~KERNEL_NETWORK_PORT_FLAG_BIT_received

 mov rbx, qword [rsi + KERNEL_NETWORK_STRUCTURE_PORT.tcp_connection]

 mov rcx, qword [rsi + KERNEL_NETWORK_STRUCTURE_PORT.size]
 mov qword [rsp + STATIC_QWORD_SIZE_byte], rcx

 mov rsi, qword [rsi + KERNEL_NETWORK_STRUCTURE_PORT.address]
 mov qword [rsp], rsi

 jmp .end

.error:
 stc

.end:
 pop rsi
 pop rcx
 pop rax

 ret

 macro_debug "kernel_network_tcp_port_receive"

kernel_network_arp:
 push rax

 cmp word [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.htype], KERNEL_NETWORK_FRAME_ARP_HTYPE_ethernet
 jne .omit

 cmp word [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.ptype], KERNEL_NETWORK_FRAME_ARP_PTYPE_ipv4
 jne .omit

 cmp byte [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.hal], KERNEL_NETWORK_FRAME_ARP_HAL_mac
 jne .omit

 cmp byte [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.pal], KERNEL_NETWORK_FRAME_ARP_PAL_ipv4
 jne .omit

 mov eax, dword [driver_nic_i82540em_ipv4_address]
 cmp eax, dword [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.target_ip]
 jne .omit

 push rdi

 call kernel_memory_alloc_page
 jc .error

 mov word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.type], KERNEL_NETWORK_FRAME_ETHERNET_TYPE_arp
 mov word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.htype], KERNEL_NETWORK_FRAME_ARP_HTYPE_ethernet
 mov word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.ptype], KERNEL_NETWORK_FRAME_ARP_PTYPE_ipv4
 mov byte [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.hal], KERNEL_NETWORK_FRAME_ARP_HAL_mac
 mov byte [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.pal], KERNEL_NETWORK_FRAME_ARP_PAL_ipv4
 mov word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.opcode], KERNEL_NETWORK_FRAME_ARP_OPCODE_answer

 mov dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.source_ip], eax

 mov eax, dword [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.source_ip]
 mov dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.target_ip], eax

 mov rax, qword [driver_nic_i82540em_mac_address]
 mov dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.source], eax
 mov dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.source_mac], eax
 shr rax, STATIC_MOVE_HIGH_TO_EAX_shift
 mov word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.source + KERNEL_NETWORK_STRUCTURE_MAC.4], ax
 mov word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.source_mac + KERNEL_NETWORK_STRUCTURE_MAC.4], ax

 mov rax, qword [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.source_mac]
 mov dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.target_mac], eax
 shr rax, STATIC_MOVE_HIGH_TO_EAX_shift
 mov word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.target_mac + KERNEL_NETWORK_STRUCTURE_MAC.4], ax

 mov rax, qword [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.source_mac]
 mov cx, KERNEL_NETWORK_FRAME_ETHERNET_TYPE_arp
 call kernel_network_ethernet_wrap

 mov eax, KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.SIZE
 call service_tx_add

.error:
 pop rdi

.omit:
 pop rax

 jmp kernel_network.end

 macro_debug "kernel_network_arp"

kernel_network_icmp:
 push rsi

 cmp byte [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ICMP.type], KERNEL_NETWORK_FRAME_ICMP_TYPE_REQUEST
 jne .end

 call kernel_memory_alloc_page
 jc .end

 mov word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.type], KERNEL_NETWORK_FRAME_ETHERNET_TYPE_ip
 mov byte [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.version_and_ihl], KERNEL_NETWORK_FRAME_IP_HEADER_LENGTH_default | KERNEL_NETWORK_FRAME_IP_VERSION_4
 mov byte [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.dscp_and_ecn], STATIC_EMPTY
 mov word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.total_length], (KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ICMP.SIZE >> STATIC_REPLACE_AL_WITH_HIGH_shift) | (KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ICMP.SIZE << STATIC_REPLACE_AL_WITH_HIGH_shift)
 mov word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.identification], STATIC_EMPTY
 mov word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.f_and_f], STATIC_EMPTY
 mov byte [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.ttl], KERNEL_NETWORK_FRAME_IP_TTL_default
 mov byte [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.protocol], KERNEL_NETWORK_FRAME_IP_PROTOCOL_ICMP
 mov word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ICMP.type], KERNEL_NETWORK_FRAME_ICMP_TYPE_REPLY
 mov byte [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ICMP.code], STATIC_EMPTY
 mov dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ICMP.reserved], STATIC_EMPTY

 add rdi, KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE

 mov eax, dword [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ICMP.reserved]
 mov dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ICMP.reserved], eax

 mov word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ICMP.checksum], STATIC_EMPTY

 xor eax, eax
 mov ecx, KERNEL_NETWORK_STRUCTURE_FRAME_ICMP.SIZE >> STATIC_DIVIDE_BY_2_shift
 call kernel_network_checksum

 rol ax, STATIC_REPLACE_AL_WITH_HIGH_shift
 mov word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ICMP.checksum], ax

 sub rdi, KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE

 mov eax, dword [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.source_address]
 mov dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_IP.destination_address], eax

 mov eax, dword [driver_nic_i82540em_ipv4_address]
 mov dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_IP.source_address], eax

 mov word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_IP.checksum], STATIC_EMPTY

 xor eax, eax
 mov ecx, (KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ICMP.SIZE) >> STATIC_DIVIDE_BY_2_shift
 call kernel_network_checksum
 rol ax, STATIC_REPLACE_AL_WITH_HIGH_shift
 mov word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_IP.checksum], ax

 sub rdi, KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE
 mov rax, qword [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.source]
 mov cx, KERNEL_NETWORK_FRAME_ETHERNET_TYPE_ip
 call kernel_network_ethernet_wrap

 mov eax, KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ICMP.SIZE
 call service_tx_add

.end:
 pop rsi

 jmp kernel_network_ip.end

 macro_debug "kernel_network_icmp"

kernel_network_ethernet_wrap:
 push rax

 mov qword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.target], rax

 mov rax, qword [driver_nic_i82540em_mac_address]
 mov qword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.source], rax

 mov word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.type], cx

 pop rax

 ret

 macro_debug "kernel_network_ethernet_wrap"

kernel_network_checksum:
 push rbx
 push rcx
 push rdi

 xor ebx, ebx
 xchg rbx, rax

.calculate:
 mov ax, word [rdi]
 rol ax, STATIC_REPLACE_AL_WITH_HIGH_shift

 add rbx, rax

 add rdi, STATIC_WORD_SIZE_byte

 loop .calculate

 mov ax, bx
 shr ebx, STATIC_MOVE_HIGH_TO_AX_shift
 add rax, rbx

 not ax

 pop rdi
 pop rcx
 pop rbx

 ret

 macro_debug "kernel_network_checksum"

kernel_network_checksum_part:
 push rbx
 push rcx
 push rdi

 xor ebx, ebx

.calculate:
 mov bx, word [rdi]
 rol bx, STATIC_REPLACE_AL_WITH_HIGH_shift

 add rax, rbx

 add rdi, STATIC_WORD_SIZE_byte

 loop .calculate

 pop rdi
 pop rcx
 pop rbx

 ret

 macro_debug "kernel_network_checksum_part"
