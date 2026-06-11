kernel_init_smp:
 xchg bx, bx
 jbe .finish

 mov ecx, kernel_init_boot_file_end - kernel_init_boot_file
 mov rsi, kernel_init_boot_file
 mov rdi, 0x8000
 rep movsb

 mov byte [kernel_init_smp_semaphore], STATIC_TRUE

 mov rdi, qword [kernel_apic_base_address]
 mov eax, dword [rdi + KERNEL_APIC_ID_register]
 shr eax, 24

 mov dl, al

 mov rsi, kernel_apic_id_table

 mov cx, word [kernel_init_ap_count]

.finish:
 
