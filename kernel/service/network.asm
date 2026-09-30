
	%include "kernel/service/network/config.asm"
	%include "kernel/service/network/data.asm"
	%include "kernel/service/network/checksum.asm"
	%include "kernel/service/network/arp.asm"
	%include "kernel/service/network/icmp.asm"
	%include "kernel/service/network/tcp.asm"

service_network:
	; make sure not to use reserved pages
	xor ebp, ebp

	; fetch own PID
	call kernel_task_active
	mov rax, qword [rdi + KERNEL_TASK_STRUCTURE.pid]

	; save the information about own PID for the other processes
	mov qword [rel service_network_pid], rax

.loop:
	; fetch a message addressed to us
	mov rdi, service_network_ipc_message
	call kernel_ipc_receive
	jc .loop ; none, check once again

	; fetch the size and the pointer to the space
	mov rcx, qword [rdi + KERNEL_IPC_STRUCTURE.size]
	mov rsi, qword [rdi + KERNEL_IPC_STRUCTURE.pointer]

	; the ARP protocol?
	cmp word [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.type], SERVICE_NETWORK_FRAME_ETHERNET_TYPE_arp
	je service_network_arp ; yes

	; the IP protocol?
	cmp word [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.type], SERVICE_NETWORK_FRAME_ETHERNET_TYPE_ip
	je service_network_ip ; yes

	; unsupported protocol
	xchg bx,bx

.end:
	; has the packet space been handed over to another process?
	test rsi, rsi
	jz .loop ; yes

	; release the packet data space
	mov rdi, rsi
	call kernel_memory_release_page

	; return to the main loop
	jmp .loop

	macro_debug "service_network"

; input:
;	rsi - pointer to the incoming packet
service_network_ip:
	; the ICMP protocol?
	cmp byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.protocol], SERVICE_NETWORK_FRAME_IP_PROTOCOL_ICMP
	je service_network_icmp ; yes

	; the TCP protocol?
	cmp byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.protocol], SERVICE_NETWORK_FRAME_IP_PROTOCOL_TCP
	je service_network_tcp ; yes

.end:
	; return from the procedure
	jmp service_network.end

	macro_debug "service_network_ip"

; input:
;	rax - packet size in Bytes
;	rdi - pointer to the packet data space
; output:
;	CF flag, if the send failed
service_network_transfer:
	; preserve the original registers
	push rbx
	push rcx
	push rsi

	; is the data sending service via the network interface ready?
	mov rbx, qword [rel service_tx_pid]
	test rbx, rbx
	jz .error ; the service is not ready

	; registers to their places
	mov rcx, rax
	mov rsi, rdi
	call kernel_ipc_insert
	jnc .end ; the message was sent

.error:
	; the flag, error
	stc

.end:
	; restore the original registers
	pop rsi
	pop rcx
	pop rbx

	; return from the procedure
	ret
