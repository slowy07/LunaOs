SERVICE_TX_CACHE_SIZE_page equ 1

service_tx_semaphore db STATIC_TRUE

service_tx_cache_address dq STATIC_EMPTY
service_tx_cache_pointer dq ((SERVICE_TX_CACHE_SIZE_page << STATIC_MULTIPLE_BY_PAGE_shift) / SERVICE_TX_STRUCTURE_CACHE.SIZE) - 0x01

struc SERVICE_TX_STRUCTURE_CACHE
 .size resb 8
 .address resb 8
 .SIZE:
endstruc

service_tx:
 mov rcx, SERVICE_TX_CACHE_SIZE_page
 call kernel_memory_alloc
 jc service_tx

 call kernel_page_drain_few

 mov qword [service_tx_cache_address], rdi

.reload:
 mov byte [service_tx_semaphore], STATIC_FALSE

 mov rsi, qword [service_tx_cache_address]

.loop:
 cmp byte [service_tx_semaphore], STATIC_TRUE
 je .loop

 cmp qword [rsi], STATIC_EMPTY
 je .loop

 mov ax, word [rsi + SERVICE_TX_STRUCTURE_CACHE.size]
 mov rdi, qword [rsi + SERVICE_TX_STRUCTURE_CACHE.address]
 call driver_nic_i82540em_transfer

 macro_close service_tx_semaphore, 0


 call kernel_memory_release_page

 mov rdi, rsi
 add rsi, SERVICE_TX_STRUCTURE_CACHE.SIZE

 mov rcx, ((SERVICE_TX_CACHE_SIZE_page << STATIC_MULTIPLE_BY_PAGE_shift) / SERVICE_TX_STRUCTURE_CACHE.SIZE) - 0x01
 sub rcx, qword [service_tx_cache_pointer]

.move:
 movsq
 movsq

 dec rcx
 jnz .move

 inc qword [service_tx_cache_pointer]

 jmp .reload

 macro_debug "service_tx"

service_tx_add:
 push rsi

 macro_close service_tx_semaphore, 0

 cmp qword [service_tx_cache_pointer], STATIC_EMPTY
 je .error

 mov rsi, ((SERVICE_TX_CACHE_SIZE_page << STATIC_MULTIPLE_BY_PAGE_shift) / SERVICE_TX_STRUCTURE_CACHE.SIZE) - 0x01
 sub rsi, qword [service_tx_cache_pointer]
 shl rsi, STATIC_MULTIPLE_BY_16_shift
 add rsi, qword [service_tx_cache_address]

 mov dword [rsi + SERVICE_TX_STRUCTURE_CACHE.size], eax
 mov qword [rsi + SERVICE_TX_STRUCTURE_CACHE.address], rdi

 dec qword [service_tx_cache_pointer]

 jmp .end

.error:
 stc

.end:
 mov byte [service_tx_semaphore], STATIC_FALSE

 pop rsi

 ret

 macro_debug "service_tx_add"
