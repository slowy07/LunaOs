
kernel_init_smp:
 ; is only one logical processor available?
 cmp word [rel kernel_apic_count], STATIC_TRUE
 jbe .finish ; yes, skip initialising the rest

 ; map the memory area holding the logical processor init code
 mov eax, 0x7000 ; 0x0000:0x7000
 mov bx, KERNEL_PAGE_FLAG_available | KERNEL_PAGE_FLAG_write
 mov ecx, kernel_init_boot_file_end - kernel_init_boot_file
 mov r11, qword [rel kernel_page_pml4_address]
 call library_page_from_size
 call kernel_page_map_physical

 ; load the boot code for the logical processors
 mov ecx, kernel_init_boot_file_end - kernel_init_boot_file
 mov rsi, kernel_init_boot_file
 mov rdi, 0x7000 ; 0x0000:0x7000
 rep movsb

 ; open the target path for the logical processors in the init routines
 mov byte [rel kernel_init_smp_semaphore], STATIC_TRUE

 ; fetch the identifier of the BSP
 mov rdi, qword [rel kernel_apic_base_address]
 mov eax, dword [rdi + KERNEL_APIC_ID_register]
 shr eax, 24 ; shift the bits from 24..31 to 0..7

 ; save the identifier
 mov dl, al

 ; initialise the following logical processors
 mov rsi, kernel_apic_id_table

 ; number of logical processors
 mov cx, word [rel kernel_apic_count]

.init:
 ; end of the logical processors to wake up?
 dec cx
 js .init_done ; yes

 ; fetch the logical processor identifier
 lodsb

 ; the BSP?
 cmp al, dl
 je .init ; yes, skip

 ; send the INIT command to the logical processor
 shl eax, 24 ; shift the bits from 0..7 to 24..31
 mov dword [rdi + KERNEL_APIC_ICH_register], eax
 mov eax, 0x00004500
 mov dword [rdi + KERNEL_APIC_ICL_register], eax

.init_wait:
 ; has the command completed?
 bt dword [rdi + KERNEL_APIC_ICL_register], KERNEL_APIC_ICL_COMMAND_COMPLETE_bit
 jc .init_wait ; wait

 ; next logical processor
 jmp .init

.init_done:
 ; wait about 10ms
 mov rax, qword [rel driver_rtc_microtime]
 add rax, 10

.init_wait_for_ipi:
 ; has the time elapsed?
 cmp rax, qword [rel driver_rtc_microtime]
 ja .init_wait_for_ipi ; no

 ; tell every logical processor the address to start at

 ; start the following logical processors
 mov rsi, kernel_apic_id_table

 ; number of logical processors
 mov cx, word [rel kernel_apic_count]

.start:
 ; end of the logical processors?
 dec cx
 js .finish ; yes

 ; fetch the logical processor identifier
 lodsb

 ; the BSP?
 cmp al, dl
 je .start ; yes, skip

 ; send the START command to the logical processor (vector 0x07 > 0x7000)
 shl eax, 24 ; shift the bits from 0..7 to 24..31
 mov dword [rdi + KERNEL_APIC_ICH_register], eax
 mov eax, 0x00004607
 mov dword [rdi + KERNEL_APIC_ICL_register], eax

.start_wait:
 ; has the command completed?
 bt dword [rdi + KERNEL_APIC_ICL_register], KERNEL_APIC_ICL_COMMAND_COMPLETE_bit
 jc .start_wait ; wait

 ; next logical processor
 jmp .start

.finish:
