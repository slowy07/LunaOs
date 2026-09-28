;===============================================================================

%macro	macro_apic_id_get	0
	; fetch the ID of the logical processor
	mov	rax,	qword [rel kernel_apic_base_address]
	mov	dword [rax + KERNEL_APIC_TP_register],	STATIC_EMPTY
	mov	eax,	dword [rax + KERNEL_APIC_ID_register]
	shr	eax,	24	; shift bits 24..31 into 0..7
%endmacro
