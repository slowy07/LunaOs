
ACPI_MADT_ENTRY_lapic equ 0x00
ACPI_MADT_ENTRY_ioapic equ 0x01
ACPI_MADT_ENTRY_iso equ 0x02
ACPI_MADT_ENTRY_x2apic equ 0x09

ACPI_MADT_APIC_FLAG_ENABLED_bit equ 0

 struc ACPI_STRUCTURE_RSDP
.signature resb 8
.checksum resb 1
.oem_id resb 6
.revision resb 1
.rsdt_address resb 4
.SIZE:
 endstruc

 struc ACPI_STRUCTURE_XSDP
.rsdp resb ACPI_STRUCTURE_RSDP.SIZE
.length resb 4
.xsdt_address resb 8
.checksum resb 1
.reserved resb 3
.SIZE:
 endstruc

 struc ACPI_STRUCTURE_RSDT_or_XSDT
.signature resb 4
.length resb 4
.revision resb 1
.checksum resb 1
.oem_id resb 6
.oem_table_id resb 8
.oem_revision resb 4
.creator_id resb 4
.creator_revision resb 4
.SIZE:
 endstruc

 struc ACPI_STRUCTURE_MADT
.signature resb 4
.length resb 4
.revision resb 1
.checksum resb 1
.oem_id resb 6
.oem_table_id resb 8
.oem_revision resb 4
.creator_id resb 4
.creator_revision resb 4
.apic_address resb 4
.flags resb 4
.SIZE:
 endstruc

 struc ACPI_STRUCTURE_MADT_entry
.type resb 1
.length resb 1
 endstruc

 struc ACPI_STRUCTURE_MADT_APIC
.type resb 1
.length resb 1
.cpu_id resb 1
.apic_id resb 1
.flags resb 4
.SIZE:
 endstruc

 struc ACPI_STRUCTURE_MADT_IOAPIC
.type resb 1
.length resb 1
.ioapic_id resb 1
.reserved resb 1
.base_address resb 4
.gsib resb 4 ; Global System Interrupt Base
.SIZE:
 endstruc

 struc ACPI_STRUCTURE_MADT_ISO ; Interrupt Source Override
.type resb 1
.length resb 1
.bus_source resb 1
.irq_source resb 1
.gsi resb 4 ; Global System Interrupt
.flags resb 2
.SIZE:
 endstruc

 struc ACPI_STRUCTURE_MADT_NMI ; Non-maskable Interrupts
.type resb 1
.length resb 1
.acpi_id resb 1
.flags resb 2
.lint resb 1
.SIZE:
 endstruc

kernel_init_acpi:
 ; look for the Root/Extended System Description Pointer header
 mov rbx, "RSD PTR "

 ; fetch the EBDA segment pointer
 movzx esi, word [abs 0x040E]

 ; turn the segment pointer into an absolute address
 shl esi, STATIC_MULTIPLE_BY_16_shift

 ;  by default we expect ACPI version 1.0
 mov r8b, STATIC_TRUE

.rsdp_search:
 ; fetch 8 bytes
 lodsq

 ; found the RSDP/XSDP header?
 cmp rax, rbx
 je .rsdp_found ; yes

 ; end of the area being searched?
 cmp esi, 0x000FFFFF
 jb .rsdp_search ; no

 ; error message
 mov rsi, kernel_init_string_error_acpi_header

.error:
 ; display the message
 jmp kernel_panic

.rsdp_found:
 ; save the pointer to the RSDP or XSDP header
 push rsi

 ; sum all the bytes of the RSDP header
 xor al, al
 mov ecx, ACPI_STRUCTURE_RSDP.SIZE

 ; move the pointer back to the start of the header
 sub rsi, ACPI_STRUCTURE_RSDP.checksum

.checksum:
 ; build the checksum
 add al, byte [rsi]

 ; move the pointer to the next value
 inc rsi

 ; carry on with the remaining values
 loop .checksum

 ; restore the pointer to the RSDP header
 pop rsi

 ; is the checksum ZERO?
 test al, al
 jnz .rsdp_search ; no, this is not a valid RSDP header, keep searching

.rsdp_or_xsdp:
 ; point at the start of the header
 sub rsi, ACPI_STRUCTURE_RSDP.checksum

 ; check which version of the ACPI table the RSDP header is in
 cmp byte [rsi + ACPI_STRUCTURE_RSDP.revision], 0x00
 jne .extended ; version 1.0

 ; fetch the address of the RSDT table from the pointer in the header
 mov edi, dword [rsi + ACPI_STRUCTURE_RSDP.rsdt_address]

 ; continue
 jmp .standard

.extended:
 ; fetch the address of the XSDT table from the pointer in the header
 mov rdi, qword [rsi + ACPI_STRUCTURE_XSDP.xsdt_address]

 ; ACPI 2.0+
 mov r8b, STATIC_FALSE

.standard:
 ; error message
 mov rsi, kernel_init_string_error_acpi

 ; check the signature of the RSDT table
 cmp dword [rdi + ACPI_STRUCTURE_RSDT_or_XSDT.signature], "RSDT"
 je .found ; recognised

 ; check the signature of the XSDT table
 cmp dword [rdi + ACPI_STRUCTURE_RSDT_or_XSDT.signature], "XSDT"
 jne .error ; not recognised


.found:
 ; fetch the size of the RSDT/XSDT pointer table
 mov ecx, dword [rdi + ACPI_STRUCTURE_RSDT_or_XSDT.length]
 sub ecx, ACPI_STRUCTURE_RSDT_or_XSDT.SIZE

 ; move the pointer to the first table entry
 add rdi, ACPI_STRUCTURE_RSDT_or_XSDT.SIZE

 ; standard version?
 cmp r8b, STATIC_TRUE
 je .rsdt_pointers ; yes

.xsdt_pointers:
 ; turn it into the number of entries
 shr ecx, STATIC_DIVIDE_BY_QWORD_shift

.xsdt_pointers_loop:
 ; fetch the address of the entry header
 mov rsi, qword [rdi]

 ; check the header type
 call .header

 ; move the pointer to the next entry in the XSDT table
 add rdi, STATIC_QWORD_SIZE_byte

 ; end of the pointers?
 dec ecx
 jnz .xsdt_pointers_loop ; no

 ; end of the table processing
 jmp .summary

.rsdt_pointers:
 ; turn it into the number of entries
 shr ecx, STATIC_DIVIDE_BY_DWORD_shift

.rsdt_pointers_loop:
 ; fetch the address of the entry header
 mov esi, dword [rdi]

 ; check the header type
 call .header

 ; move the pointer to the next entry in the RSDT table
 add rdi, STATIC_DWORD_SIZE_byte

 ; end of the pointers?
 dec ecx
 jnz .rsdt_pointers_loop ; no

 ; end of the table processing

.summary:
 ; error message
 mov rsi, kernel_init_string_error_apic

 ; was at least one APIC table processed?
 cmp byte [rel kernel_apic_count], STATIC_EMPTY
 je .error ; no, display the error message

 ; error message
 mov rsi, kernel_init_string_error_ioapic

 ; was at least one I/O APIC table processed?
 cmp byte [rel kernel_init_ioapic_semaphore], STATIC_FALSE
 je .error ; no, display the error message

 ; continue initialising the kernel environment
 jmp .end

.header:
 ; MADT (Multiple APIC Description Table) header?
 cmp dword [rsi + ACPI_STRUCTURE_MADT.signature], "APIC"
 je .madt ; yes, process it

 ; header not recognised, skip it
 ret

.madt:
 ; preserve the original registers
 push rcx
 push rsi
 push rdi

 ; save the address of the APIC table
 mov eax, dword [rsi + ACPI_STRUCTURE_MADT.apic_address]
 mov dword [rel kernel_apic_base_address], eax

 ; save the size of the APIC table
 mov ecx, dword [rsi + ACPI_STRUCTURE_MADT.length]
 mov dword [rel kernel_apic_size], ecx

 ; search the MADT table for the available logical processors (a.k.a. LAPIC)
 sub ecx, ACPI_STRUCTURE_MADT.SIZE ; adjust the size of the MADT table by the header
 add rsi, ACPI_STRUCTURE_MADT.SIZE ; move the pointer to the first entry of the MADT table

 ; store the information about the available logical processors in the table
 mov rdi, kernel_apic_id_table

.madt_loop:
 ; found a logical processor?
 cmp byte [rsi + ACPI_STRUCTURE_MADT_entry.type], ACPI_MADT_ENTRY_lapic
 je .madt_apic ; yes, process it

 ; found an I/O APIC?
 cmp byte [rsi + ACPI_STRUCTURE_MADT_entry.type], ACPI_MADT_ENTRY_ioapic
 je .madt_ioapic ; yes, process it

 ; not recognised or not supported

.madt_next_entry:
 ; move the pointer to the next entry in the MADT table
 movzx eax, byte [rsi + ACPI_STRUCTURE_MADT_entry.length]
 add rsi, rax

 ; end of the entries?
 sub rcx, rax
 jnz .madt_loop ; no, carry on

 ; restore the original registers
 pop rdi
 pop rsi
 pop rcx

 ; end of the subprocedure
 ret

.madt_apic:
 ; logical processor active?
 bt word [rsi + ACPI_STRUCTURE_MADT_APIC.flags], ACPI_MADT_APIC_FLAG_ENABLED_bit
 jnc .madt_next_entry ; no, skip the registration

 ; logical processor available
 inc word [rel kernel_apic_count]

 ; fetch and save the logical processor identifier
 mov al, byte [rsi + ACPI_STRUCTURE_MADT_APIC.cpu_id]
 stosb

 ; is the logical processor identifier higher?
 cmp al, byte [rel kernel_init_apic_id_highest]
 jbe .madt_next_entry ; no

 ; remember it
 mov byte [rel kernel_init_apic_id_highest], al

 ; continue
 jmp .madt_next_entry

.madt_ioapic:
 ; has an IO APIC already been processed?
 cmp byte [rel kernel_init_ioapic_semaphore], STATIC_TRUE
 je .madt_next_entry ; yes, we do not support the remaining I/O APIC controllers

 ; fetch the identifier of the first interrupt served by this controller
 mov eax, dword [rsi + ACPI_STRUCTURE_MADT_IOAPIC.gsib]

 ; does the controller serve interrupt vectors 0 and up?
 test al, al
 jnz .madt_next_entry ; no, skip this controller

 ; save the address of the I/O APIC controller
 mov eax, dword [rsi + ACPI_STRUCTURE_MADT_IOAPIC.base_address]
 mov dword [rel kernel_io_apic_base_address], eax

 ; processed an I/O APIC controller entry
 mov byte [rel kernel_init_ioapic_semaphore], STATIC_TRUE

 ; continue
 jmp .madt_next_entry

.end:
