;===============================================================================

;===============================================================================
kernel_init_apic:
	; fetch the address of the Local ACPI table
	mov	rsi,	qword [rel kernel_apic_base_address]

	; disable Task Priority and Priority Sub-Class
	mov	dword [rsi + KERNEL_APIC_TP_register],	STATIC_EMPTY

	; enable Flat Mode
	mov	dword [rsi + KERNEL_APIC_DF_register],	KERNEL_APIC_DF_FLAG_flat_mode

	; all available processors receive the interrupts (physical!)
	mov	dword [rsi + KERNEL_APIC_LD_register],	KERNEL_APIC_LD_FLAG_target_cpu

	; enable the APIC controller on the BSP/logical processor
	mov	eax,	dword [rsi + KERNEL_APIC_SIV_register]
	or	eax,	KERNEL_APIC_SIV_FLAG_enable_apic | KERNEL_APIC_SIV_FLAG_spurious_vector
	mov	dword [rsi + KERNEL_APIC_SIV_register],	eax

	; enable the timer interrupts on the APIC controller of the BSP/logical processor
	mov	eax,	dword [rsi + KERNEL_APIC_LVT_TR_register]
	and	eax,	~KERNEL_APIC_LVT_TR_FLAG_mask_interrupts
	mov	dword [rsi + KERNEL_APIC_LVT_TR_register],	eax

	; interrupt line on timer expiry
	mov	dword [rsi + KERNEL_APIC_LVT_TR_register],	KERNEL_APIC_IRQ_number

	; timer divider
	mov	dword [rsi + KERNEL_APIC_TDC_register],	KERNEL_APIC_TDC_divide_by_16

	; return from the procedure
	ret
